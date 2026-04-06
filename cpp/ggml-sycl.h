//
//  MIT license
//  Copyright (C) 2024 Intel Corporation
//  SPDX-License-Identifier: MIT
//

#pragma once

#include "ggml.h"
#include "ggml-backend.h"

#define LM_GGML_SYCL_NAME "SYCL"
#define LM_GGML_SYCL_MAX_DEVICES 48

#ifdef  __cplusplus
extern "C" {
#endif

// backend API
LM_GGML_BACKEND_API lm_ggml_backend_t lm_ggml_backend_sycl_init(int device);

LM_GGML_BACKEND_API bool lm_ggml_backend_is_sycl(lm_ggml_backend_t backend);

// devide buffer
LM_GGML_BACKEND_API lm_ggml_backend_buffer_type_t lm_ggml_backend_sycl_buffer_type(int device);

// split tensor buffer that splits matrices by rows across multiple devices
LM_GGML_BACKEND_API lm_ggml_backend_buffer_type_t lm_ggml_backend_sycl_split_buffer_type(const float * tensor_split);

// pinned host buffer for use with the CPU backend for faster copies between CPU and GPU
LM_GGML_BACKEND_API lm_ggml_backend_buffer_type_t lm_ggml_backend_sycl_host_buffer_type(void);

LM_GGML_BACKEND_API void lm_ggml_backend_sycl_print_sycl_devices(void);
LM_GGML_BACKEND_API void lm_ggml_backend_sycl_get_gpu_list(int *id_list, int max_len);
LM_GGML_BACKEND_API void lm_ggml_backend_sycl_get_device_description(int device,
                                                       char *description,
                                                       size_t description_size);
LM_GGML_BACKEND_API int  lm_ggml_backend_sycl_get_device_count();
LM_GGML_BACKEND_API void lm_ggml_backend_sycl_get_device_memory(int device, size_t *free, size_t *total);

// SYCL doesn't support registering host memory, keep here for reference
// LM_GGML_BACKEND_API bool lm_ggml_backend_sycl_register_host_buffer(void * buffer, size_t size);
// LM_GGML_BACKEND_API void lm_ggml_backend_sycl_unregister_host_buffer(void * buffer);

LM_GGML_BACKEND_API lm_ggml_backend_reg_t lm_ggml_backend_sycl_reg(void);

#ifdef  __cplusplus
}
#endif
