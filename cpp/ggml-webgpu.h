#pragma once

#include "ggml.h"
#include "ggml-backend.h"

#ifdef  __cplusplus
extern "C" {
#endif

#define LM_GGML_WEBGPU_NAME "WebGPU"

// Needed for examples in ggml
LM_GGML_BACKEND_API lm_ggml_backend_t lm_ggml_backend_webgpu_init(void);

LM_GGML_BACKEND_API lm_ggml_backend_reg_t lm_ggml_backend_webgpu_reg(void);

#ifdef  __cplusplus
}
#endif
