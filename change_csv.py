import pandas as pd                     #pandas是一个强大的分析结构化数据的工具集


read_path='./import/gsh-2015-edge.csv'
write_path='./import/gsh-2015-edge_1.csv'
# 将csv文件内数据读出
ngData=pd.read_csv(read_path,chunksize=1000000)

#添加新列‘名字长度’（length）
for chunk in ngData:                                    #遍历数据表，计算每一位名字的长度
    ngList=[]
    for i in range(len(chunk)):
        ngList.append('knows')
    chunk['knows']=ngList                                     #注明列名，就可以直接添加新列
    chunk.to_csv(write_path,index=False,chunksize=1000000)         #把数据写入数据集，index=False表示不加索引
#注意这里的ngData['length']=ngList是直接在原有数据基础上加了一列新的数据，也就是说现在的ngData已经具备完整的3列数据
#不用再在to_csv中加mode=‘a’这个参数，实现不覆盖添加。

#查看修改后的csv文件
print("done\n")

