start_time=$(date +%s%3N)
cat sssp.txt | ./bin/cypher-shell -u neo4j -p ljx >sssp.out
end_time=$(date +%s%3N)
echo $(($end_time-$start_time))
