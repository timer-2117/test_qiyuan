import pandas as pd

# 文件路径（请根据实际情况修改）
input_path = 'twitter_edge.csv'
output_path = 'twitter_edge_new.csv'

# 分块大小（每块行数，可根据内存调整，例如 1_000_000）
chunksize = 1000000

# 原文件没有表头，指定三列的临时名称
original_columns = ['col1', 'col2', 'col3']

# 表头名称
header = ['start_id', 'start_vertex_type', 'end_id', 'end_vertex_type', 'cost']

first_chunk = True

# 分块读取
for chunk in pd.read_csv(input_path, header=None, names=original_columns, chunksize=chunksize):
    # 转换数据：第一列+1，第二列+1，第三列不变，添加两列固定值 'Person'
    chunk['start_id'] = chunk['col1'] + 1
    chunk['start_vertex_type'] = 'Person'
    chunk['end_id'] = chunk['col2'] + 1
    chunk['end_vertex_type'] = 'Person'
    chunk['cost'] = chunk['col3']
    
    # 只保留需要的五列，并按顺序排列
    result = chunk[['start_id', 'start_vertex_type', 'end_id', 'end_vertex_type', 'cost']]
    
    # 写入 CSV：第一块写入表头，后续追加不写表头
    mode = 'w' if first_chunk else 'a'
    result.to_csv(output_path, mode=mode, header=first_chunk, index=False)
    first_chunk = False

print(f"处理完成，结果保存至 {output_path}")