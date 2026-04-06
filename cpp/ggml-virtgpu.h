#pragma once

#include "ggml.h"
#include "ggml-backend.h"

#ifdef  __cplusplus
extern "C" {
#endif

LM_GGML_BACKEND_API lm_ggml_backend_reg_t lm_ggml_backend_virtgpu_reg();

#ifdef  __cplusplus
}
#endif
