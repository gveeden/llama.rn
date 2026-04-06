#pragma once

#include "ggml.h"
#include "ggml-backend.h"

#ifdef __cplusplus
extern "C" {
#endif

// device buffer
LM_GGML_BACKEND_API lm_ggml_backend_buffer_type_t lm_ggml_backend_zdnn_buffer_type(void);

LM_GGML_BACKEND_API lm_ggml_backend_reg_t lm_ggml_backend_zdnn_reg(void);

#ifdef __cplusplus
}
#endif
