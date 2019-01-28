#ifndef TS_KERNELS_DEPTHWISE_CONV2D_V2_H
#define TS_KERNELS_DEPTHWISE_CONV2D_V2_H
#include <kernels/cpu/conv2d_v2_base.h>
#include <global/operator_factory.h>
#include <core/tensor.h>
#include <runtime/stack.h>

namespace ts {


class Depthwise_Conv2d_V2: public ts::Conv2d_V2_Base {
public:

    using supper = ts::Conv2d_V2_Base;
    Depthwise_Conv2d_V2();

    virtual void init(); 

    virtual int run(ts::Stack &stack); 


    virtual int infer(ts::Stack &stack, std::vector<ts::Tensor::Prototype> &output); 

private:
    int infer_private(ts::Stack &stack, ts::Tensor::Prototype &output); 


private:
    Shape m_padding;
/*
    int m_group;
    int m_padding_value;
    Shape m_padding;
    Shape m_stride;
    Shape m_dialations;
    std::string m_format;
*/
};



}

#endif