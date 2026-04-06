#include "ggml-backend-impl.h"

#if defined(__riscv) && __riscv_xlen == 64
#include <asm/hwprobe.h>
#include <asm/unistd.h>
#include <unistd.h>

struct riscv64_features {
    bool has_rvv = false;

    riscv64_features() {
        struct riscv_hwprobe probe;
        probe.key = RISCV_HWPROBE_KEY_IMA_EXT_0;
        probe.value = 0;

        int ret = syscall(__NR_riscv_hwprobe, &probe, 1, 0, NULL, 0);

        if (0 == ret) {
            has_rvv = !!(probe.value & RISCV_HWPROBE_IMA_V);
        }
    }
};

static int lm_ggml_backend_cpu_riscv64_score() {
    int score = 1;
    riscv64_features rf;

#ifdef LM_GGML_USE_RVV
    if (!rf.has_rvv) { return 0; }
    score += 1 << 1;
#endif

    return score;
}

LM_GGML_BACKEND_DL_SCORE_IMPL(lm_ggml_backend_cpu_riscv64_score)

#endif  // __riscv && __riscv_xlen == 64
