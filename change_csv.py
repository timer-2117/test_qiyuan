import dask.dataframe as dd

read_path = './edge.csv'
write_path = './edge_neo4j.csv'

# 使用Dask读取csv文件，你可以指定chunksize参数来设置每个分块的大小
ddf = dd.read_csv(read_path)

# Dask Dataframe的操作是惰性的，这意味着计算不会立即执行，只有在你调用.compute()方法时才会执行
# 这让Dask能够更智能地优化整个计算过程
ddf['knows'] = 'knows'

# 将结果写入csv文件，注意这将会触发实际的计算
ddf.to_csv(write_path, single_file=True, index=False)

print("done\n")
