#include <kernels/gpu/div.h>
#include <core/tensor_builder.h>
#include <backend/name.h>
#include <utils/assert.h>
#include <global/operator_factory.h>
#include <core/device.h>

#include <numeric>
#include "device_launch_parameters.h"
#include <cuda_runtime.h>



namespace ts {
    namespace gpu {

        template<typename T>
        static __global__ void reduce_operator_scalar_kernel(T* data, int size, const T *scalar, T maxvalue, T minvalue) {
            int index = blockDim.x * blockIdx.x + threadIdx.x;
            if (index < size) {
                data[index] = (*scalar) == T(0)
                ? (data[index] > 0 ? maxvalue : minvalue)
                : data[index] / (*scalar);
            }
        }

        template<typename T>
        static __global__ void reduce_operator_same_shape_kernel(T* data, const T*bias, int size, T maxvalue, T minvalue) {
            int index = blockDim.x * blockIdx.x + threadIdx.x;
            if (index < size) {
                data[index] = (bias[index]) == T(0)
                ? (data[index] > 0 ? maxvalue : minvalue)
                : data[index] / (bias[index]);
            }
        }

        template<typename T>
        static __global__ void reduce_operator_bias_kernel(T* data, int size, int step, int slice,
                                        const T* bias, int biaslen, T maxvalue, T minvalue ) {
            int index = blockDim.x * blockIdx.x + threadIdx.x;
            if (index < size) {
                int dim = index % ( step * slice ) / (step);
                data[index] = (bias[dim]) == T(0)
                ? (data[index] > 0 ? maxvalue: minvalue)
                : data[index] / (bias[dim]);
            }
        }


        template<typename T>
        static __global__ void reduce_operator_kernel(T* out, int size, const T* lhs,  const T* rhs,
                                               int *lhsshape, int *lhsweight,
                                               int *rhsshape, int *rhsweight,
                                               int *outweight, int shapelen, T maxvalue, T minvalue) {
            int index = blockDim.x * blockIdx.x + threadIdx.x;
            if (index >= size)
                return;

            int *buffer1 = new int[shapelen];
            int *buffer2 = new int[shapelen];
            int i = 0;
            int k= 0;
            int *  ptmp;
            int *  ptr;

            ptr = buffer1;
            ptmp = outweight + 1;
            int ntmp = index;
            for(i= shapelen - 1; i; --i) {
                *ptr = ntmp / *ptmp;
                ntmp %= *ptmp;
                ++ptmp;
                ++ptr;
            }

            *ptr = ntmp;

            int lhsindex = 0;
            for(i=0; i<shapelen; ++i) {
                buffer2[i] = buffer1[i] % lhsshape[i];
            }

            for(k=0, i=1; i < shapelen; ++k,++i) {
                lhsindex += buffer2[k] * lhsweight[i];
            }
            lhsindex += buffer2[k];

            int rhsindex = 0;
            for(i=0; i<shapelen; ++i) {
                buffer2[i] = buffer1[i] % rhsshape[i];
            }

            for(k=0, i=1; i < shapelen; ++k,++i) {
                rhsindex += buffer2[k] * rhsweight[i];
            }
            rhsindex += buffer2[k];

            out[index] = (rhs[rhsindex]) == T(0)
                ? (lhs[lhsindex] > 0 ? maxvalue : minvalue)
                : lhs[lhsindex] / (rhs[rhsindex]);
            delete [] buffer1;
            delete [] buffer2;
        }


        template<typename T>
        static inline void div_gpu_compute_run(const Tensor &lhs, const Tensor &rhs, Tensor &out) {
            HypeShape lhs_hype(lhs.sizes());
            HypeShape rhs_hype(rhs.sizes());
            HypeShape out_hype(out.sizes());

            auto plhs = lhs.data<T>();
            auto prhs = rhs.data<T>();
            auto pout = out.data<T>();

            auto ncount = out.count();

            int *lhsshape = nullptr;
            int *rhsshape = nullptr;
            int *lhsweight = nullptr;
            int *rhsweight = nullptr;
            int *outweight = nullptr;

            /////////////////////////////////////
            Shape tmpshape;
            tmpshape.resize(1);
            tmpshape[0] = lhs.sizes().size();
            Tensor lhs_tensor(out.device(), INT32, tmpshape);
            lhsshape = lhs_tensor.data<int32_t>();

            tmpshape[0] = rhs.sizes().size();
            Tensor rhs_tensor(out.device(), INT32, tmpshape);
            rhsshape = rhs_tensor.data<int32_t>();

            tmpshape[0] = lhs.sizes().size();
            Tensor lhs_weight_tensor(out.device(), INT32, tmpshape);
            lhsweight = lhs_weight_tensor.data<int32_t>();

            tmpshape[0] = rhs.sizes().size();
            Tensor rhs_weight_tensor(out.device(), INT32, tmpshape);
            rhsweight = rhs_weight_tensor.data<int32_t>();

            tmpshape[0] = out.sizes().size();
            Tensor out_weight_tensor(out.device(), INT32, tmpshape);
            outweight = out_weight_tensor.data<int32_t>();


            memcpy((void*)lhsshape, out.device(), lhs.sizes().size() * sizeof(int32_t),
                   (void*)lhs.sizes().data(), MemoryDevice(CPU), lhs.sizes().size() * sizeof(int32_t));

            memcpy((void*)rhsshape, out.device(), rhs.sizes().size() * sizeof(int32_t),
                   (void*)rhs.sizes().data(), MemoryDevice(CPU), rhs.sizes().size() * sizeof(int32_t));

            memcpy((void*)lhsweight, out.device(), lhs_hype.weight().size() * sizeof(int32_t),
                   (void*)lhs_hype.weight().data(), MemoryDevice(CPU), lhs_hype.weight().size() * sizeof(int32_t));

            memcpy((void*)rhsweight, out.device(), rhs_hype.weight().size() * sizeof(int32_t),
                   (void*)rhs_hype.weight().data(), MemoryDevice(CPU), rhs_hype.weight().size() * sizeof(int32_t));
            memcpy((void*)outweight, out.device(), out_hype.weight().size() * sizeof(int32_t),
                   (void*)out_hype.weight().data(), MemoryDevice(CPU), out_hype.weight().size() * sizeof(int32_t));
            /////////////////////////////////////

            T maxvalue = std::numeric_limits<T>::max();
            T minvalue = std::numeric_limits<T>::lowest();

            reduce_operator_kernel<T> <<< CUDA_BLOCK(ncount, CUDA_THREAD_NUM), CUDA_THREAD_NUM >>> (pout, ncount,
                        plhs, prhs, lhsshape, lhsweight, rhsshape, rhsweight, outweight, out.sizes().size(),maxvalue, minvalue);

        }


        template<typename T>
        static inline void div_gpu_compute_run_scalar(const Tensor &lhs, const Tensor &rhs, Tensor &out) {
            auto plhs = lhs.data<T>();
            auto prhs = rhs.data<T>();
            auto pout = out.data<T>();

            T maxvalue = std::numeric_limits<T>::max();
            T minvalue = std::numeric_limits<T>::lowest();
            memcpy((void*)pout, out.device(), out.count() * sizeof(T),
                   (void*)plhs, lhs.device(), out.count() * sizeof(T));

            reduce_operator_scalar_kernel<T> <<< CUDA_BLOCK(out.count(), CUDA_THREAD_NUM), CUDA_THREAD_NUM >>> (pout, out.count(), prhs,maxvalue, minvalue);

        }


        template<typename T>
        static inline void div_gpu_compute_run_same_shape(const Tensor &lhs, const Tensor &rhs, Tensor &out) {
            auto plhs = lhs.data<T>();
            auto prhs = rhs.data<T>();
            auto pout = out.data<T>();

            T maxvalue = std::numeric_limits<T>::max();
            T minvalue = std::numeric_limits<T>::lowest();

            memcpy((void*)pout, out.device(), out.count() * sizeof(T),
                   (void*)plhs, lhs.device(), out.count() * sizeof(T));

            reduce_operator_same_shape_kernel<T> <<< CUDA_BLOCK(out.count(), CUDA_THREAD_NUM), CUDA_THREAD_NUM >>> (pout, prhs, out.count(),maxvalue,minvalue);

        }


        template<typename T>
        static inline void div_gpu_compute_run_bias(const Tensor &lhs, const Tensor &rhs, Tensor &out, int dim) {
            auto plhs = lhs.data<T>();
            auto prhs = rhs.data<T>();
            auto pout = out.data<T>();

            auto &out_shape = out.sizes();
            auto number = std::accumulate(out_shape.begin(), out_shape.begin() + dim, 1, std::multiplies<int>());
            auto count = std::accumulate(out_shape.begin() + dim + 1, out_shape.end(), 1, std::multiplies<int>());

            auto channels = out_shape[dim];

            memcpy((void*)pout, out.device(), out.count() * sizeof(T),
                   (void*)plhs, lhs.device(), out.count() * sizeof(T));

            T maxvalue = std::numeric_limits<T>::max();
            T minvalue = std::numeric_limits<T>::lowest();
            reduce_operator_bias_kernel<T> <<< CUDA_BLOCK(out.count(), CUDA_THREAD_NUM), CUDA_THREAD_NUM >>> (pout, out.count(),
                 count, channels, prhs, rhs.count(), maxvalue, minvalue);

        }


        void Div::reduce_with_broadcast(const Tensor &lhs, const Tensor &rhs, Tensor &out) {
            // Notice: the all tensor' memory device are CPU, as given in running_memory_device
            DTYPE dtype = out.dtype();
            switch(dtype) {
#define DECLARE_COMPUTE_RUN(DTYPE, TYPE) \
        case DTYPE: { div_gpu_compute_run<TYPE>(lhs, rhs, out); break; }
                DECLARE_COMPUTE_RUN(INT8, int8_t);
                DECLARE_COMPUTE_RUN(UINT8, uint8_t);
                DECLARE_COMPUTE_RUN(INT16, int16_t);
                DECLARE_COMPUTE_RUN(UINT16, uint16_t);
                DECLARE_COMPUTE_RUN(INT32, int32_t);
                DECLARE_COMPUTE_RUN(UINT32, uint32_t);
                DECLARE_COMPUTE_RUN(INT64, int64_t);
                DECLARE_COMPUTE_RUN(UINT64, uint64_t);
                DECLARE_COMPUTE_RUN(FLOAT32, float);
                DECLARE_COMPUTE_RUN(FLOAT64, double);
#undef DECLARE_COMPUTE_RUN
                default: {
                    TS_LOG_ERROR << "div not support this data type: " << dtype << eject;
                    break;
                }
            }
        }

        void Div::reduce_with_scalar(const Tensor &lhs, const Tensor &rhs, Tensor &out) {
            // Notice: the all tensor' memory device are CPU, as given in running_memory_device
            DTYPE dtype = out.dtype();
            switch(dtype) {
#define DECLARE_COMPUTE_RUN(DTYPE, TYPE) \
        case DTYPE: { div_gpu_compute_run_scalar<TYPE>(lhs, rhs, out); break; }
                DECLARE_COMPUTE_RUN(INT8, int8_t);
                DECLARE_COMPUTE_RUN(UINT8, uint8_t);
                DECLARE_COMPUTE_RUN(INT16, int16_t);
                DECLARE_COMPUTE_RUN(UINT16, uint16_t);
                DECLARE_COMPUTE_RUN(INT32, int32_t);
                DECLARE_COMPUTE_RUN(UINT32, uint32_t);
                DECLARE_COMPUTE_RUN(INT64, int64_t);
                DECLARE_COMPUTE_RUN(UINT64, uint64_t);
                DECLARE_COMPUTE_RUN(FLOAT32, float);
                DECLARE_COMPUTE_RUN(FLOAT64, double);
#undef DECLARE_COMPUTE_RUN
                default: {
                    TS_LOG_ERROR << "div not support this data type: " << dtype << eject;
                    break;
                }
            }
        }

        void Div::reduce_with_bias(const Tensor &lhs, const Tensor &rhs, Tensor &out, int dim) {
            // Notice: the all tensor' memory device are CPU, as given in running_memory_device
            DTYPE dtype = out.dtype();
            switch(dtype) {
#define DECLARE_COMPUTE_RUN(DTYPE, TYPE) \
        case DTYPE: { div_gpu_compute_run_bias<TYPE>(lhs, rhs, out, dim); break; }
                DECLARE_COMPUTE_RUN(INT8, int8_t);
                DECLARE_COMPUTE_RUN(UINT8, uint8_t);
                DECLARE_COMPUTE_RUN(INT16, int16_t);
                DECLARE_COMPUTE_RUN(UINT16, uint16_t);
                DECLARE_COMPUTE_RUN(INT32, int32_t);
                DECLARE_COMPUTE_RUN(UINT32, uint32_t);
                DECLARE_COMPUTE_RUN(INT64, int64_t);
                DECLARE_COMPUTE_RUN(UINT64, uint64_t);
                DECLARE_COMPUTE_RUN(FLOAT32, float);
                DECLARE_COMPUTE_RUN(FLOAT64, double);
#undef DECLARE_COMPUTE_RUN
                default: {
                    TS_LOG_ERROR << "div not support this data type: " << dtype << eject;
                    break;
                }
            }
        }

        void Div::reduce_with_same_shape(const Tensor &lhs, const Tensor &rhs, Tensor &out) {
            // Notice: the all tensor' memory device are CPU, as given in running_memory_device
            DTYPE dtype = out.dtype();
            switch(dtype) {
#define DECLARE_COMPUTE_RUN(DTYPE, TYPE) \
        case DTYPE: { div_gpu_compute_run_same_shape<TYPE>(lhs, rhs, out); break; }
                DECLARE_COMPUTE_RUN(INT8, int8_t);
                DECLARE_COMPUTE_RUN(UINT8, uint8_t);
                DECLARE_COMPUTE_RUN(INT16, int16_t);
                DECLARE_COMPUTE_RUN(UINT16, uint16_t);
                DECLARE_COMPUTE_RUN(INT32, int32_t);
                DECLARE_COMPUTE_RUN(UINT32, uint32_t);
                DECLARE_COMPUTE_RUN(INT64, int64_t);
                DECLARE_COMPUTE_RUN(UINT64, uint64_t);
                DECLARE_COMPUTE_RUN(FLOAT32, float);
                DECLARE_COMPUTE_RUN(FLOAT64, double);
#undef DECLARE_COMPUTE_RUN
                default: {
                    TS_LOG_ERROR << "div not support this data type: " << dtype << eject;
                    break;
                }
            }
        }
    }
}

using namespace ts;
using namespace gpu;
TS_REGISTER_OPERATOR(Div, GPU, name::layer::div())
