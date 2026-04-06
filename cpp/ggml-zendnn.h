#pragma once

#include "ggml-backend.h"
#include "ggml.h"

#ifdef __cplusplus
extern "C" {
#endif

// backend API
LM_GGML_BACKEND_API lm_ggml_backend_t lm_ggml_backend_zendnn_init(void);

LM_GGML_BACKEND_API bool lm_ggml_backend_is_zendnn(lm_ggml_backend_t backend);

// number of threads used for zendnn operations
LM_GGML_BACKEND_API void lm_ggml_backend_zendnn_set_n_threads(lm_ggml_backend_t backend_zendnn, int n_threads);

LM_GGML_BACKEND_API lm_ggml_backend_reg_t lm_ggml_backend_zendnn_reg(void);

#ifdef __cplusplus
}
#endif
