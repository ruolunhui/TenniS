//
// Created by kier on 2018/12/21.
//

#ifndef TENSORSTACK_KERNELS_COMMON_SIMD_H
#define TENSORSTACK_KERNELS_COMMON_SIMD_H

#include <stdint.h>
//#include "simd_def.h"
#ifdef TS_USE_AVX
#include "simd_def/simd_avx_def.h"
#elif  TS_USE_SSE
#include "simd_def/simd_sse_def.h"
#elif  TS_USE_NEON
#include "simd_def/simd_neon_def.h"
#else
#include "simd_def/simd_base_def.h"
#endif

namespace ts {
    template<typename T, int M>
    class simd_base {
    public:
        using self = simd_base;
        using base = T;
        static const int width = M;
    };

    template<typename T, int M>
    class simd : public simd_base<T, M> {
    public:
        using self = simd;
        using supper = simd_base<T, M>;

        void store(typename supper::base *p) const;
    };

    using float32x4 = simd<float, 4>;
    using float32x4x2 = simd<float, 8>;

    using int32x4 = simd<int32_t, 4>;
    using int32x4x2 = simd<int32_t, 8>;

    template<typename T, int M>
    inline T sum(const simd<T, M> &value) {
        T a[M];
        value.store(a);
        T sum = 0;
        for (int i = 0; i < M; ++i) sum += a[i];
        return sum;
    }

    template<typename T>
    inline T sum(const simd<T, 4> &value) {
        T a[4];
        value.store(a);
        return a[0] + a[1] + a[2] + a[3];
    }

    template<typename T>
    inline T sum(const simd<T, 4> &value,int index) {
        T a[4];
        value.store(a);
        T sum = 0;
        for (int i = 0; i < index && i < 4; i++){
            sum += a[i];
        }
        return sum;
    }

    template<typename T, int M>
    inline const simd<T, M> &operator+=(simd<T, M> &lhs, const simd<T, M> &rhs) {
        return lhs = lhs + rhs;
    }

    template<>
    class simd<float, 4> : public simd_base<float, 4> {
    public:
        using self = simd;
        using type = _simd_f32x4;

        type value;

        simd() = default;

        simd(type value) : value(value) {}

        simd(base a) : simd(a, a, a, a) {}

        simd(int a) : simd(base(a)) {}

        simd(const base *p) : value(_simd_f32x4_load(p)) {}

        simd(base a, base b, base c, base d) : value(_simd_f32x4_set(a, b, c, d)) {}

        void store(base *p) const { _simd_f32x4_store(p, value); }
    };

    inline simd<float, 4> operator+(const simd<float, 4> &lhs, const simd<float, 4> &rhs) {
        return _simd_f32x4_add(lhs.value, rhs.value);
    }

    inline simd<float, 4> operator-(const simd<float, 4> &lhs, const simd<float, 4> &rhs) {
        return _simd_f32x4_sub(lhs.value, rhs.value);
    }

    inline simd<float, 4> operator*(const simd<float, 4> &lhs, const simd<float, 4> &rhs) {
        return _simd_f32x4_mul(lhs.value, rhs.value);
    }

    inline simd<float, 4> operator/(const simd<float, 4> &lhs, const simd<float, 4> &rhs) {
        return _simd_f32x4_div(lhs.value, rhs.value);
    }

    inline simd<float, 4> max_float32x4(const simd<float, 4> &lhs, const simd<float, 4> &rhs) {
        return _simd_f32x4_max(lhs.value, rhs.value);
    }

    inline simd<float, 4> min_float32x4(const simd<float, 4> &lhs, const simd<float, 4> &rhs) {
        return _simd_f32x4_min(lhs.value, rhs.value);
    }

    inline void transposex4x4(simd<float, 4> &q0, simd<float, 4> &q1, simd<float, 4> &q2, simd<float, 4> &q3) {
        return _simd_f32x4_transpose4x4(q0.value, q1.value, q2.value, q3.value);
    }

    inline simd<float, 4> fmadd(const simd<float, 4> &q0, const simd<float, 4> &q1, const simd<float, 4> &q2) {
        return _simd_f32x4_fmadd(q0.value, q1.value, q2.value);
    }

    template<>
    class simd<float, 8> : public simd_base<float, 8> {
    public:
        using self = simd;
        using type = _simd_f32x4x2;

        type value;

        simd() = default;

        simd(type value) : value(value) {}

        simd(base a) : simd(a, a, a, a, a, a, a, a) {}

        simd(int a) : simd(base(a)) {}

        simd(const base *p) : value(_simd_f32x4x2_load(p)) {}

        simd(base a, base b, base c, base d, base e, base f, base g, base h) : value(_simd_f32x4x2_set(a, b, c, d, e, f, g, h)) {}

        void store(base *p) const { _simd_f32x4x2_store(p, value); }
    };

    inline simd<float, 8> operator+(const simd<float, 8> &lhs, const simd<float, 8> &rhs) {
        return _simd_f32x4x2_add(lhs.value, rhs.value);
    }

    inline simd<float, 8> operator-(const simd<float, 8> &lhs, const simd<float, 8> &rhs) {
        return _simd_f32x4x2_sub(lhs.value, rhs.value);
    }

    inline simd<float, 8> operator*(const simd<float, 8> &lhs, const simd<float, 8> &rhs) {
        return _simd_f32x4x2_mul(lhs.value, rhs.value);
    }

    inline simd<float, 8> operator/(const simd<float, 8> &lhs, const simd<float, 8> &rhs) {
        return _simd_f32x4x2_div(lhs.value, rhs.value);
    }

    inline simd<float, 8> fmadd(const simd<float, 8> &q0, const simd<float, 8> &q1, const simd<float, 8> &q2) {
        return _simd_f32x4x2_fmadd(q0.value, q1.value, q2.value);
    }

    template<>
    class simd<int32_t, 4> : public simd_base<int32_t, 4> {
    public:
        using self = simd;
        using type = _simd_int32x4;

        type value;

        simd() = default;

        simd(type value) : value(value) {}

        simd(base a) : simd(a, a, a, a) {}

        simd(const base *p) : value(_simd_int32x4_load(p)) {}

        simd(base a, base b, base c, base d) : value(_simd_int32x4_set(a, b, c, d)) {}

        void store(base *p) const { _simd_int32x4_store(p, value); }
    };

    inline simd<int32_t, 4> operator+(const simd<int32_t, 4> &lhs, const simd<int32_t, 4> &rhs) {
        return _simd_int32x4_add(lhs.value, rhs.value);
    }

    inline simd<int32_t, 4> operator-(const simd<int32_t, 4> &lhs, const simd<int32_t, 4> &rhs) {
        return _simd_int32x4_sub(lhs.value, rhs.value);
    }

    template<>
    class simd<int32_t, 8> : public simd_base<int32_t, 8> {
    public:
        using self = simd;
        using type = _simd_int32x4x2;

        type value;

        simd() = default;

        simd(type value) : value(value) {}

        simd(base a) : simd(a, a, a, a, a, a, a, a) {}

        simd(const base *p) : value(_simd_int32x4x2_load(p)) {}

        simd(base a, base b, base c, base d, base e, base f, base g, base h) : 
            value(_simd_int32x4x2_set(a, b, c, d, e, f, g, h)) {}

        void store(base *p) const { _simd_int32x4x2_store(p, value); }
    };

    inline simd<int32_t, 8> operator+(const simd<int32_t, 8> &lhs, const simd<int32_t, 8> &rhs) {
        return _simd_int32x4x2_add(lhs.value, rhs.value);
    }

    inline simd<int32_t, 8> operator-(const simd<int32_t, 8> &lhs, const simd<int32_t, 8> &rhs) {
        return _simd_int32x4x2_sub(lhs.value, rhs.value);
    }

    //cast
    inline int32x4x2 floatx4x2_to_int32x4x2(const float32x4x2 &lhs) {
        return _simd_floatx4x2_to_int32x4x2(lhs.value);
    }

    inline float32x4x2 intx4x2_to_float32x4x2(const int32x4x2 &lhs) {
        return _simd_intx4x2_to_float32x4x2(lhs.value);
    }

    inline float32x4x2 broadcast2float32x4x2(const float* src) {
        return _simd_broadcast2float32x4x2(src);
    }

}

#endif //TENSORSTACK_KERNELS_COMMON_SIMD_H
