#ifdef LM_GGML_USE_CPU_HBM

#include "ggml-backend.h"
#include "ggml-backend-impl.h"
#include "ggml-cpu.h"
#include "ggml-impl.h"

#include "hbm.h"

// buffer type HBM

#include <hbwmalloc.h>

static const char * lm_ggml_backend_cpu_hbm_buffer_type_get_name(lm_ggml_backend_buffer_type_t buft) {
    return "CPU_HBM";

    LM_GGML_UNUSED(buft);
}

static void lm_ggml_backend_cpu_hbm_buffer_free_buffer(lm_ggml_backend_buffer_t buffer) {
    hbw_free(buffer->context);
}

static lm_ggml_backend_buffer_t lm_ggml_backend_cpu_hbm_buffer_type_alloc_buffer(lm_ggml_backend_buffer_type_t buft,
                                                                           size_t                     size) {
    void * ptr;
    int    result = hbw_posix_memalign(&ptr, lm_ggml_backend_cpu_buffer_type_get_alignment(buft), size);
    if (result != 0) {
        LM_GGML_LOG_ERROR("failed to allocate HBM buffer of size %zu\n", size);
        return NULL;
    }

    lm_ggml_backend_buffer_t buffer = lm_ggml_backend_cpu_buffer_from_ptr(ptr, size);
    buffer->buft                 = buft;
    buffer->iface.free_buffer    = lm_ggml_backend_cpu_hbm_buffer_free_buffer;

    return buffer;
}

lm_ggml_backend_buffer_type_t lm_ggml_backend_cpu_hbm_buffer_type(void) {
    static struct lm_ggml_backend_buffer_type lm_ggml_backend_cpu_buffer_type_hbm = {
        /* .iface    = */ {
                           /* .get_name         = */ lm_ggml_backend_cpu_hbm_buffer_type_get_name,
                           /* .alloc_buffer     = */ lm_ggml_backend_cpu_hbm_buffer_type_alloc_buffer,
                           /* .get_alignment    = */ lm_ggml_backend_cpu_buffer_type_get_alignment,
                           /* .get_max_size     = */ nullptr,  // defaults to SIZE_MAX
                           /* .get_alloc_size   = */ nullptr,  // defaults to lm_ggml_nbytes
                           /* .is_host          = */ lm_ggml_backend_cpu_buffer_type_is_host,
                           },
        /* .context  = */ nullptr,
    };

    return &lm_ggml_backend_cpu_buffer_type_hbm;
}
#endif
