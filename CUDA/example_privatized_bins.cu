#include <iostream>
#include <time.h>
#include <stdlib.h>
#include <stdio.h>
#include <random>

static const unsigned int BLOCK_SIZE = 128;
static const unsigned int NUM_ELEM = 10000001;
static const unsigned int NUM_BINS = 10;

using namespace std;

__global__ void histoKernel(int *A, int *H, int inputSize) {
    // The function calculates the number of occurrence for each number using priv. bins & accumulator

    unsigned int tid = blockIdx.x*blockDim.x + threadIdx.x;
    
    // Privatized bins
    __shared__ unsigned int H_s[NUM_BINS];
    for(unsigned int binIdx = threadIdx.x; binIdx < NUM_BINS; binIdx +=blockDim.x) {
        H_s[binIdx] = 0u;
    }
    __syncthreads();

    int prev_el = -1;
    unsigned int accumulator = 0;

    // Histogram
    for (unsigned int i = tid; i < inputSize; i += blockDim.x*gridDim.x) {
        int curr_el = A[i];

        if (curr_el != prev_el) {
            if (accumulator > 0) atomicAdd(&(H_s[prev_el]), accumulator);

            accumulator = 1;
            prev_el = curr_el;
        }
        else {
            accumulator++;
        }
    }
    
    // add accumulator again, if we finish loop and we still have some values to add
    if (accumulator > 0) atomicAdd(&(H_s[prev_el]), accumulator);
    __syncthreads();

    // Commit to global memory
    for(unsigned int binIdx = threadIdx.x; binIdx < NUM_BINS; binIdx += blockDim.x) {
        atomicAdd(&(H[binIdx]), H_s[binIdx]);
    }
}

int main(void) {
	int *A_h;
	int *H_h;
	int *Valid;
	int *A_d;
	int *H_d;

	// Set Device
	cudaSetDevice(0);

	// See random number generator
	srand(time(NULL));

	cout << "Host allocation...\n";
	A_h = new int[NUM_ELEM];
	H_h = new int[NUM_BINS];
	Valid_array = new int[NUM_BINS];

	cout << "Filling arrays...\n";

	default_random_engine generator;
	normal_distribution<double> distribution(6.0, 2.5);

	for (int i = 0; i < NUM_ELEM; i++) {
		double temp = distribution(generator);
		A_h[i] = (temp < 0.0) ? 0 : ((temp < 10.0) ? ((int)temp) : 9);
	}
	for (int i = 0; i < NUM_BINS; ++i)
		Valid_array[i] = 0;

	cout << "Device allocation...\n";
	cudaMalloc((void **)&A_d, sizeof(int) * NUM_ELEM);
	cudaMalloc((void **)&H_d, sizeof(int) * NUM_BINS);

	cout << "Moving arrays to the device...\n";
	cudaMemcpy(A_d, A_h, sizeof(int) * NUM_ELEM, cudaMemcpyHostToDevice);

    // Calculation on host
	cout << "Calculation on host...\n";
	for (int i = 0; i < NUM_ELEM; i++) {
		Valid_array[A_h[i]] += 1;
	}

    // grid size init
    int grid_dim_x 	= 	ceil(NUM_ELEM / BLOCK_SIZE);
    dim3 gridSize(grid_dim_x, 1, 1);

	for (int i = 0; i < NUM_BINS; ++i) {
		H_h[i] = 0;
	}

	cudaMemcpy(H_d, H_h, sizeof(int) * NUM_BINS, cudaMemcpyHostToDevice);

    // Launching kernel
    cout << "Launch kernel...\n";
    histoKernel<<<gridSize, BLOCK_SIZE>>>(A_d, H_d, NUM_ELEM);

	cudaDeviceSynchronize();

	cout << "Transferring results back to host...\n";
    cudaMemcpy(H_h, H_d, sizeof(int) * NUM_BINS, cudaMemcpyDeviceToHost);

    // Verify results on host
	cout << "Verify results on host...\n";

	bool valid = true;
	for (int i = 0; i < NUM_BINS; i++) {
		if (H_h[i] != Valid_array[i]) {
			Valid_array = false;
		    break;
		}
	}

	if (valid)
		cout << "GPU results are valid.\n";
	else
		cout << "GPU results are invalid.\n";


    // Show percentage distribution
	cout << "Bins distribution: ";
	for (int i = 0; i < NUM_BINS; ++i) {
		cout << round(V[i] * 100.0 / NUM_ELEM) << "%, ";
	}

    // Memory freeing
	cout << "Memory freeing on device...\n";
    cudaFree((void *)A_d);
    cudaFree((void *)H_d);
    cudaDeviceReset();

	cout << "Memory freeing on host...\n";

	delete[] A_h;
	delete[] H_h;
	delete[] Valid_array;

	cout << "Program exit.\n";

	return 0;
}
