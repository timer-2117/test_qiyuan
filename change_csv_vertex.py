#!/usr/bin/env python3
"""
change_csv_vertex.py
读取 CSV（无表头，每行一个数字），输出原数据 + 新列 'person'
用法：
    python change_csv_vertex.py [input.csv] [output.csv]
如果省略 input.csv，则从标准输入读取；省略 output.csv 则输出到标准输出。
"""

import sys
import csv

def main():
    # 获取输入输出流
    if len(sys.argv) > 1:
        infile = open(sys.argv[1], 'r', newline='')
    else:
        infile = sys.stdin

    if len(sys.argv) > 2:
        outfile = open(sys.argv[2], 'w', newline='')
    else:
        outfile = sys.stdout

    reader = csv.reader(infile)
    writer = csv.writer(outfile)

    for row in reader:
        # 在原行末尾添加 'person'
        new_row = row + ['person']
        writer.writerow(new_row)

    # 关闭文件（仅当打开时）
    if infile is not sys.stdin:
        infile.close()
    if outfile is not sys.stdout:
        outfile.close()

if __name__ == "__main__":
    main()