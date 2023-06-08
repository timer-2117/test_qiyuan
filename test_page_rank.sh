start_time=$(date +%s%3N)
cat page_rank.txt | ./bin/cypher-shell -u neo4j -p ljx >page_rank.out
end_time=$(date +%s%3N)
echo $(($end_time-$start_time))
