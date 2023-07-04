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

struct EdgeUnit1
{
	VertexId src;
	VertexId dst;
};

struct EdgeUnit2
{
	VertexId src;
	VertexId dst;
	Weight edge_data;
};

inline long file_size(std::string filename)
{
	struct stat st;
	assert(stat(filename.c_str(), &st) == 0);
	return st.st_size;
}

int main(int argc, char *argv[])
{

	if (argc != 6)
	{
		printf("gen_weight [file_in] [file_out] [vertices] [range_low] [range_high]\n");
		exit(-1);
	}
	std::random_device rd;
	std::mt19937 gen(0);
	// std::uniform_int_distribution<uint64_t> dis(1000000, 10000000);
	std::uniform_real_distribution<> dis(atof(argv[4]), atof(argv[5]));
	VertexId vertices = atol(argv[3]);

	int fin = open(argv[1], O_RDWR);
	assert(fin != -1);
	int fout = open(argv[2], O_CREAT | O_RDWR, 0777);
	assert(fout != -1);

	size_t edge_unit_size_r = sizeof(EdgeUnit1);
	size_t edge_unit_size_w = sizeof(EdgeUnit2);
	long total_bytes = file_size(argv[1]);
	long total_edges = total_bytes / edge_unit_size_r;
	long read_edges = 0;
	EdgeUnit1 *rbuffer = new EdgeUnit1[CHUNKSIZE];
	EdgeUnit2 *wbuffer = new EdgeUnit2[CHUNKSIZE];
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
		current_read_edges = read(fin, rbuffer, edge_unit_size_r * current_read_edges) / edge_unit_size_r;
		for (int i = 0; i < current_read_edges; i++)
		{
			wbuffer[i].src = rbuffer[i].src;
			wbuffer[i].dst = rbuffer[i].dst;
			wbuffer[i].edge_data = dis(gen);
		}
		current_read_edges = write(fout, wbuffer, edge_unit_size_w * current_read_edges) / edge_unit_size_w;
		read_edges += current_read_edges;
	}

	return 0;
}
