#include <kernels/gpu/dimshuffle.h>
#include <core/tensor_builder.h>
#include <set>
#include <global/operator_factory.h>
#include <backend/name.h>
#include <core/device.h>
#include <utils/assert.h>
#include <cuda_runtime.h>

#include "kernels/gpu/gpu_helper.h"

#include "kernels/gpu/gpu_helper.h"

namespace ts {
    namespace gpu {
        template <typename T>
        static __global__ void gpu_dimshuffle_kernel(int count, const T* in, GpuHypeShape in_shape, T *out, GpuHypeShape out_shape, int dim, int *shuffle) {
            int index = blockDim.x * blockIdx.x + threadIdx.x;
            if (index >= count) return;

            int out_index = index;
            int in_index = 0;

            auto out_weight_it = out_shape.weights + 1;
            auto in_weight_it = in_shape.weights + 1;
            /* ============================================ */
            int running_dim = 0;
            /* -------------------------------------------- */

            for (int times = out_shape.dims - 1; times; --times) {
                auto coord = index / *out_weight_it;
                /* ============================================ */
                if (running_dim == dim) coord = shuffle[coord];
                ++running_dim;
                /* -------------------------------------------- */
                in_index += coord * *in_weight_it;
                index %= *out_weight_it;
                ++out_weight_it;
                ++in_weight_it;
            }
            auto coord = index;
            /* ============================================ */
            if (running_dim == dim) coord = shuffle[coord];
            /* -------------------------------------------- */
            in_index += coord;

            /* ++++++++++++++++++++++++++++++++++++++++++++ */
            out[out_index] = in[in_index];
        }

        template <typename T>
        static void gpu_dimshuffle_comput_run(const Tensor &x, int dim, const std::vector<int> &shuffle, Tensor &out) {
            int *gpu_shuffle = nullptr;
            auto gpu_memory = MakeGPUHypeShape(out.device(), {x.sizes(), out.sizes()},
                                               {{(void *) (shuffle.data()), sizeof(int) * int(shuffle.size())}},
                                               {(void **) (&gpu_shuffle)});
            auto &gpu_in_shape = gpu_memory.second[0];
            auto &gpu_out_shape = gpu_memory.second[1];
            auto in_data = x.data<T>();
            auto out_data = out.data<T>();
            auto count = out.count();

            auto cuda_stream = get_cuda_stream_on_context();

            gpu_dimshuffle_kernel<T> << < CUDA_BLOCK(count, CUDA_THREAD_NUM), CUDA_THREAD_NUM, 0, cuda_stream >> > (count, in_data, gpu_in_shape, out_data, gpu_out_shape, dim, gpu_shuffle);
        }

        void Dimshuffle::dimshuffle(const Tensor &x, int dim, const std::vector<int> &shuffle, Tensor &out) {
            DTYPE dtype = out.dtype();
            switch(dtype) {
#define DECLARE_COMPUTE_RUN(DTYPE, TYPE) \
        case DTYPE: { gpu_dimshuffle_comput_run<TYPE>(x, dim, shuffle, out); break; }
                DECLARE_COMPUTE_RUN(FLOAT32, float);
                DECLARE_COMPUTE_RUN(FLOAT64, double);
#undef DECLARE_COMPUTE_RUN
                default: {
                    TS_LOG_ERROR << this->op() << " not support this data type: " << dtype << eject;
                    break;
                }
            }
        }
    }
}

///////////////////////////////////////////
using namespace ts;
using namespace gpu;
TS_REGISTER_OPERATOR(Dimshuffle, GPU, name::layer::dimshuffle())
