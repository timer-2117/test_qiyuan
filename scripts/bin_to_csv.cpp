#include <stdio.h>
#include <stdlib.h>
#include <random>
#include <assert.h>
#include <fcntl.h>
#include <stdint.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/types.h>

#include <vector>
#include <algorithm>
#include <set>

#define CHUNKSIZE (1 << 20)

typedef uint32_t VertexId;
typedef float Weight;

struct EdgeUnit
{
	VertexId src;
	VertexId dst;
	Weight edge_data;
};

bool undirected = false;

//////////////////////////////////////////////////////////////////////////

inline long file_size(std::string filename)
{
	struct stat st;
	assert(stat(filename.c_str(), &st) == 0);
	return st.st_size;
}

int main(int argc, char *argv[])
{

	if (argc != 5)
	{
		printf("bin_to_csv [file_in] [vertices.csv] [edges.csv] [vertices]\n");
		exit(-1);
	}
	VertexId vertices = atol(argv[4]);

	freopen(argv[2], "w", stdout);
	printf("LABEL=vertex\n");
	printf("id:INT32:ID\n");
	for (int i = 0; i < vertices; i++)
	{
		printf("%d\n", i);
	}

	int fin = open(argv[1], O_RDWR);
	assert(fin != -1);
	long total_bytes = file_size(argv[1]);
	size_t edge_unit_size = 2 * sizeof(VertexId) + sizeof(Weight);
	long total_edges = total_bytes / edge_unit_size;
	long read_edges = 0;
	EdgeUnit *rbuffer = new EdgeUnit[CHUNKSIZE];

	freopen(argv[3], "w", stdout);
	printf("LABEL=edge,SRC_LABEL=vertex,DST_LABEL=vertex\n");
	printf("id:INT32:SRC_ID,id:INT32:DST_ID,weight:FLOAT\n");

	while (read_edges < total_edges)
	{
		long current_read_edges;
		if (total_edges - read_edges > CHUNKSIZE)
		{
			current_read_edges = CHUNKSIZE;
		}
		else
		{
			current_read_edges = total_edges - read_edges;
		}
		current_read_edges = read(fin, rbuffer, edge_unit_size * current_read_edges) / edge_unit_size;
		for (int i = 0; i < current_read_edges; i++)
		{
			printf("%d,%d,%f\n", rbuffer[i].src, rbuffer[i].dst, rbuffer[i].edge_data);
			if (undirected)
			{
				printf("%d,%d,%f\n", rbuffer[i].dst, rbuffer[i].dst, rbuffer[i].edge_data);
			}
		}
		read_edges += current_read_edges;
	}

	return 0;
}
