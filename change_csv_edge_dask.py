import pandas as pd

read_path = '../jiuyuan_twitter_dataset/twitter_edge.csv'
write_path = '../neo4j_twitter_dataset/edge.csv'

chunksize = 1_000_000
first_chunk = True

# 指定三列，名字随意，只要数量匹配即可
# 分批读取 CSV 文件，每次处理一个块，添加新列 'knows'，然后写入新的 CSV 文件
for chunk in pd.read_csv(read_path, chunksize=chunksize, header=None,
                         names=['col1', 'col2', 'col3']):
    chunk['knows'] = 'knows'
    mode = 'w' if first_chunk else 'a'
    chunk.to_csv(write_path, mode=mode, header=False, index=False)
    first_chunk = False

print("处理完成")