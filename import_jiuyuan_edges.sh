#!/bin/bash
# ============================================================
# 脚本：分批导入超大 CSV 到 PostgreSQL (AgensGraph)
# 功能：自动拆分 CSV，分批调用 load_edges_from_file 导入，最后创建索引
# ============================================================

# ========== 用户配置区 ==========
DB_NAME="default_db"           # 数据库名
DB_USER="default_user"         # 用户名
DB_HOST="localhost"            # 主机
DB_PORT="5432"                 # 端口
GRAPH_NAME="twitter"           # 图名称（schema）
LABEL_NAME="Knows"             # 边标签（表名）

SOURCE_CSV="/import/twitter_edge_new.csv"   # 原始大 CSV 文件路径
SPLIT_DIR="/import/split"                   # 拆分后文件存放目录
LINES_PER_FILE=10000000                     # 每个文件行数（1000万行）
LOG_FILE="/tmp/import_edges.log"            # 日志文件

# PostgreSQL 连接字符串（ON_ERROR_STOP 保证出错时返回非0）
PSQL_CMD="psql -h $DB_HOST -p $DB_PORT -d $DB_NAME -U $DB_USER -v ON_ERROR_STOP=1"
# ==================================

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

error_exit() {
    log "${RED}ERROR: $1${NC}"
    exit 1
}

# 检查依赖
check_deps() {
    command -v psql >/dev/null 2>&1 || error_exit "psql not found"
    command -v split >/dev/null 2>&1 || error_exit "split not found"
    log "${GREEN}依赖检查通过${NC}"
}

# 准备拆分目录
prepare_split_dir() {
    if [ -d "$SPLIT_DIR" ]; then
        log "清空已有拆分目录: $SPLIT_DIR"
        rm -rf "$SPLIT_DIR"/*
    else
        mkdir -p "$SPLIT_DIR"
    fi
    log "拆分目录准备完毕: $SPLIT_DIR"
}

# 拆分 CSV（保留表头）
split_csv() {
    log "开始拆分 CSV: $SOURCE_CSV"
    # 提取表头
    HEADER=$(head -1 "$SOURCE_CSV")
    if [ -z "$HEADER" ]; then
        error_exit "无法读取 CSV 表头"
    fi
    log "表头: $HEADER"

    # 跳过表头，按行数拆分
    cd "$SPLIT_DIR" || error_exit "无法进入拆分目录"
    tail -n +2 "$SOURCE_CSV" | split -l "$LINES_PER_FILE" - part_ --additional-suffix=.csv

    # 为每个拆分文件加上表头
    for file in part_*.csv; do
        if [ -f "$file" ]; then
            echo "$HEADER" > tmp_file
            cat "$file" >> tmp_file
            mv tmp_file "$file"
        fi
    done

    FILE_COUNT=$(ls -1 part_*.csv 2>/dev/null | wc -l)
    log "${GREEN}拆分完成，共生成 $FILE_COUNT 个文件${NC}"
}

# 执行数据库配置优化
optimize_db() {
    log "临时调整数据库参数（会话级）..."
    $PSQL_CMD <<EOF
SET session_replication_role = 'replica';          -- 绕过触发器
SET maintenance_work_mem = '2GB';
SET work_mem = '256MB';
ALTER SYSTEM SET max_wal_size = '32GB';
ALTER SYSTEM SET checkpoint_timeout = '30min';
ALTER SYSTEM SET wal_buffers = '64MB';
SELECT pg_reload_conf();
EOF
    if [ $? -ne 0 ]; then
        log "${YELLOW}警告：数据库参数调整失败，请手动执行或确认权限${NC}"
    fi
}

# 删除索引（如果存在）
drop_indexes() {
    log "删除已有索引（如果存在）..."
    $PSQL_CMD <<EOF
DROP INDEX IF EXISTS ${GRAPH_NAME}.${LABEL_NAME}_start_id_idx;
DROP INDEX IF EXISTS ${GRAPH_NAME}.${LABEL_NAME}_end_id_idx;
EOF
    if [ $? -eq 0 ]; then
        log "索引删除完成"
    else
        log "${YELLOW}删除索引失败（可能不存在），继续导入${NC}"
    fi
}

# 核心修改：使用 load_edges_from_file 函数批量导入
import_files() {
    cd "$SPLIT_DIR" || error_exit "拆分目录不存在"
    TOTAL_FILES=$(ls -1 part_*.csv 2>/dev/null | wc -l)
    if [ "$TOTAL_FILES" -eq 0 ]; then
        error_exit "拆分目录中没有找到 CSV 文件"
    fi

    CURRENT=0
    for file in part_*.csv; do
        CURRENT=$((CURRENT + 1))
        FULL_PATH="$SPLIT_DIR/$file"
        log "导入 [$CURRENT/$TOTAL_FILES]: $file"
        # 调用 load_edges_from_file 函数（注意表名需双引号保留大小写）
        $PSQL_CMD -c "SELECT load_edges_from_file('$GRAPH_NAME', '$LABEL_NAME', '$FULL_PATH');"
        if [ $? -ne 0 ]; then
            error_exit "导入文件 $file 失败，停止脚本"
        fi
    done
    log "${GREEN}所有文件导入成功！${NC}"
}

# 创建索引并分析
create_indexes() {
    log "开始创建索引（可能耗时较长）..."
    $PSQL_CMD <<EOF
CREATE INDEX ${LABEL_NAME}_start_id_idx ON ${GRAPH_NAME}.${LABEL_NAME} (start_id);
CREATE INDEX ${LABEL_NAME}_end_id_idx ON ${GRAPH_NAME}.${LABEL_NAME} (end_id);
ANALYZE ${GRAPH_NAME}.${LABEL_NAME};
EOF
    if [ $? -eq 0 ]; then
        log "${GREEN}索引创建完成，表已分析${NC}"
    else
        error_exit "索引创建失败"
    fi
}

# 清理临时文件（可选）
cleanup() {
    read -p "是否删除拆分文件？(y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$SPLIT_DIR"
        log "已删除拆分文件"
    fi
}

# 主流程
main() {
    log "========== 开始导入任务 =========="
    check_deps
    prepare_split_dir
    split_csv
    optimize_db
    drop_indexes
    import_files
    create_indexes
    log "${GREEN}========== 全部完成 ==========${NC}"
    cleanup
}

main