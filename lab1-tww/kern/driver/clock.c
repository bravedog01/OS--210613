#include <clock.h>
#include <defs.h>
#include <sbi.h>
#include <stdio.h>
#include <riscv.h>

volatile size_t ticks;
void trigger_illegal_instruction(void);
void trigger_breakpoint_exception(void);

static inline uint64_t get_cycles(void) {
#if __riscv_xlen == 64
    uint64_t n;
    __asm__ __volatile__("rdtime %0" : "=r"(n));
    return n;
#else
    uint32_t lo, hi, tmp;
    __asm__ __volatile__(
        "1:\n"
        "rdtimeh %0\n"
        "rdtime %1\n"
        "rdtimeh %2\n"
        "bne %0, %2, 1b"
        : "=&r"(hi), "=&r"(lo), "=&r"(tmp));
    return ((uint64_t)hi << 32) | lo;
#endif
}


// Hardcode timebase
static uint64_t timebase = 100000;

/* *
 * clock_init - initialize 8253 clock to interrupt 100 times per second,
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
    // enable timer interrupt in sie
    set_csr(sie, MIP_STIP);
    // divided by 500 when using Spike(2MHz)
    // divided by 100 when using QEMU(10MHz)
    // timebase = sbi_timebase() / 500;
    clock_set_next_event();

    // initialize time counter 'ticks' to zero
    ticks = 0;
    trigger_illegal_instruction();
    trigger_breakpoint_exception(); 
    /*__asm__ __volatile__(
        "mret"  
    );*/
 
    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }

//illegal_instruction_test

void trigger_illegal_instruction(void) {
    // 使用内联汇编触发非法指令
    __asm__ __volatile__(
        ".word 0xFFFFFFFF"  // 插入一个非法指令
    );
}
// 触发断点异常的函数
void trigger_breakpoint_exception(void) {
    __asm__ __volatile__(
        "ebreak"  // 插入断点指令
    );
}

