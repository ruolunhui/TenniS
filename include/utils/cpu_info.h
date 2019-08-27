#ifndef TENSORSTACK_UTILS_CPU_INFO_H
#define TENSORSTACK_UTILS_CPU_INFO_H

#include "platform.h"
#include "api.h"
#if TS_PLATFORM_OS_WINDOWS
#include <intrin.h>
#endif

namespace ts{

    enum CPUFeature {
        MMX = 0,
        SSE = 1,
        SSE2 = 2,
        SSE3 = 3,
        SSSE3 = 4,
        SSE4_1 = 5,
        SSE4_2 = 6,
        AVX = 12,
        AVX2 = 14,
        FMA = 15,
    };

    inline const char *cpu_feauture_str(CPUFeature feature) {
        switch (feature) {
        case ts::SSE: return "SSE";
        case ts::SSE2: return "SSE2";
        case ts::AVX: return "AVX";
        case ts::AVX2: return "AVX2";
        case ts::FMA: return "FMA";
        default:break;
        }
    }

    bool TS_DEBUG_API check_cpu_feature(CPUFeature feature);

}


#endif //TENSORSTACK_UTILS_CPU_INFO_H