//
// Created by kier on 2019/1/12.
//

#include "backend/name.h"

namespace ts {
    namespace name {
        namespace layer {
            const string &field() TS_NOEXCEPT { static string str = "_field"; return str; }
            const string &pack() TS_NOEXCEPT { static string str = "_pack"; return str; }
            const string &dimshuffle() TS_NOEXCEPT { static string str = "_dimshuffle"; return str; }
            const string &transpose() TS_NOEXCEPT { static string str = "_transpose"; return str; }
            const string &reshape() TS_NOEXCEPT { static string str = "_reshape"; return str; }
            const string &conv2d() TS_NOEXCEPT { static string str = "conv2d"; return str; }
            const string &padding_conv2d() TS_NOEXCEPT { static string str = "padding_conv2d"; return str; }
            const string &shape() TS_NOEXCEPT { static string str = "_shape"; return str; }
            const string &pad() TS_NOEXCEPT { static string str = "pad"; return str; }
            const string &depthwise_conv2d() TS_NOEXCEPT { static string str = "depthwise_conv2d"; return str; }
            const string &padding_depthwise_conv2d() TS_NOEXCEPT { static string str = "padding_depthwise_conv2d"; return str; }
            const string &add_bias() TS_NOEXCEPT { static string str = "add_bias"; return str; }
            const string &batch_norm() TS_NOEXCEPT { static string str = "batch_norm"; return str; }
            const string &batch_scale() TS_NOEXCEPT { static string str = "batch_scale"; return str; }
            const string &fused_batch_norm() TS_NOEXCEPT { static string str = "fused_batch_norm"; return str; }
            const string &add() TS_NOEXCEPT { static string str = "add"; return str; }
            const string &sub() TS_NOEXCEPT { static string str = "sub"; return str; }
            const string &mul() TS_NOEXCEPT { static string str = "mul"; return str; }
            const string &div() TS_NOEXCEPT { static string str = "div"; return str; }
            const string &inner_prod() TS_NOEXCEPT { static string str = "inner_prod"; return str; }
            const string &relu() TS_NOEXCEPT { static string str = "relu"; return str; }
            const string &prelu() TS_NOEXCEPT { static string str = "prelu"; return str; }
            const string &relu_max() TS_NOEXCEPT { static string str = "relu_max"; return str; }
            const string &sigmoid() TS_NOEXCEPT { static string str = "sigmoid"; return str; }
            const string &softmax() TS_NOEXCEPT { static string str = "softmax"; return str; }
            const string &concat() TS_NOEXCEPT { static string str = "concat"; return str; }
            const string &flatten() TS_NOEXCEPT { static string str = "flatten"; return str; }
            const string &to_float() TS_NOEXCEPT { static string str = "to_float"; return str; }
            const string &pooling2d() TS_NOEXCEPT { static string str = "pooling2d"; return str; }
            const string &pooling2d_v2() TS_NOEXCEPT { static string str = "pooling2d_v2"; return str; }
            const string &resize2d() TS_NOEXCEPT { static string str = "resize2d"; return str; }
            const string &mx_pooling2d_padding() TS_NOEXCEPT { static string str = "_mx_pooling2d_padding"; return str; }
        }

        string NCHW = "NCHW";
        string NHWC = "NHWC";
        string dim = "dim";
        string shuffle = "shuffle";
        string value = "value";
        string permute = "permute";
        string shape = "shape";
        string format = "format";
        string padding = "padding";
        string padding_value = "padding_value";
        string stride = "stride";
        string dialations = "dialations";
        string epsilon = "epsilon";
        string max = "max";
        string slope = "slope";
        string type = "type";
        string padding_type = "padding_type";
        string ksize = "ksize";
        string valid = "valid";
        string device = "device";
        string offset = "offset";

    }
}