## lab1
#### **Exercise01**：指令 la sp, bootstacktop 完成了什么操作，目的是什么？ tail kern_init 完成了什么操作，目的是什么？

   1.   la sp, bootstacktop 标签 bootstacktop 的地址加载到栈指针寄存器 sp 中；
   2. tail kern_init 是一个尾调用，表示在 kern_entry 函数执行完后直接跳转到 kern_init 函数，而不保留当前函数的调用栈。这种优化可以减少栈的使用。
   3. la sp, bootstacktop 指令的作用是将栈指针设置为内核栈的顶部地址 bootstacktop。这样，内核在执行 kern_init 及后续操作时，就可以在这个栈空间中使用局部变量和处理函数调用。


#### **Exercise02**：完善中断处理（编程）

在该练习中，我们需要编写中断处理程序，处理时钟中断并打印消息。我们的任务是让系统每收到 100 次时钟中断后输出 “100 ticks” 信息，并在输出 10 行后自动关机。

- ##### 修改后的代码：

   1. **中断处理函数：`interrupt_handler`**
   ```
   void interrupt_handler(struct trapframe *tf) {
    intptr_t cause = (tf->cause << 1) >> 1;
    switch (cause) {
        case IRQ_U_SOFT:
            cprintf("User software interrupt\n");
            break;
        case IRQ_S_SOFT:
            cprintf("Supervisor software interrupt\n");
            break;
        case IRQ_H_SOFT:
            cprintf("Hypervisor software interrupt\n");
            break;
        case IRQ_M_SOFT:
            cprintf("Machine software interrupt\n");
            break;
        case IRQ_U_TIMER:
            cprintf("User software interrupt\n");
            break;
        case IRQ_S_TIMER:
            // "All bits besides SSIP and USIP in the sip register are
            // read-only." -- privileged spec1.9.1, 4.1.4, p59
            // In fact, Call sbi_set_timer will clear STIP, or you can clear it
            // directly.
            // cprintf("Supervisor timer interrupt\n");
             /* LAB1 EXERCISE2   2212777 :  */
            /*(1)设置下次时钟中断- clock_set_next_event()
             *(2)计数器（ticks）加一
             *(3)当计数器加到100的时候，我们会输出一个`100ticks`表示我们触发了100次时钟中断，同时打印次数（num）加一
            * (4)判断打印次数，当打印次数为10时，调用<sbi.h>中的关机函数关机
            */
            clock_set_next_event(); // 设置下次时钟中断
            ticks++; // 增加中断次数
            // 检查是否达到100次时钟中断
            if (ticks==100) {
                print_ticks();
                num++;
                ticks= 0; // 重置中断计数
                // 检查是否已经打印了10行
                if (num >= 10) {
                    // 调用关机函数
                    cprintf("line counters = 10\n");
                    sbi_shutdown();
                }
            }
            break;
            ......
    }
   }
   ```
   2. **`print_ticks` 函数**
   ```
   static void print_ticks() {
    cprintf("%d ticks\n", TICK_NUM);
   #ifdef DEBUG_GRADE
    cprintf("End of Test.\n");
    panic("EOT: kernel seems ok.");
   #endif
   }
   ```

- ##### 实现过程：
- 首先，修改了中断处理函数，在处理时钟中断时增加计数器，记录中断的次数。
- 每当中断次数达到 100 次时，调用 `cprintf` 输出 “100 ticks” 信息，并且在输出 10 次后调用 `sbi_shutdown()` 函数关机。
- 通过运行系统，可以观察到每秒钟输出一次 "100 ticks"，最终输出 10 次后系统自动关机。

- ##### 实验运行结果：
通过执行 `make qemu` 命令，系统启动并输出了预期的结果——每秒钟输出一行 "100 ticks"，连续输出 10 行后，系统自动关机。



#### **Challenge01**：描述ucore中处理中断异常的流程（从异常的产生开始），其中mov a0，sp的目的是什么？SAVE_ALL中寄寄存器保存在栈中的位置是什么确定的？对于任何中断，__alltraps 中都需要保存所有寄存器吗？请说明理由。

   1. 当异常产生时，处理器会跳转到由 `stvec` 寄存器指定的异常处理入口函数 `__alltraps`，在`__alltraps`中首先将执行时所有寄存器的状态保存下来。
   2. 在 `__alltraps` 中，`mov a0, sp` 的目的是将当前栈指针 `sp` 赋值给 `a0` 寄存器。通常在 RISC-V 中，`a0` 是第一个函数参数寄存器，这个操作实际上是为了将当前的 trapframe（即保存了寄存器状态的栈地址）传递给后续的异常处理函数，使得操作系统可以继续执行中断前的操作。
   3.  通过`sp`指针在栈中开辟了36个寄存器的位置 ，按照t0-t6`、`s0-s11顺序存储寄存器情况，在恢复的时候也根据相应顺序读取。
   4. 对于任何中断，__alltraps 中都需要保存所有寄存器，因为寄存器在中断处理过程中都有可能会发生改变，所以必须把所有寄存器的值都保存下来才能恢复到中断之前的状态。


####  **Challenge02**：在trapentry.S中汇编代码 csrw sscratch, sp；csrrw s0, sscratch, x0实现了什么操作，目的是什么？save all里面保存了stval scause这些csr，而在restore all里面却不还原它们？那这样store的意义何在呢？

  1. ​	实现访问和操作控制状态寄存器。 csrw sscratch, sp将当前的堆栈指针 (`sp`) 的值写入 `sscratch` CSR 寄存器。`sscratch` 是一个临时寄存器，通常用于保存栈指针（`sp`）的值。在进入中断处理程序时保存当前栈指针，以备稍后恢复。`csrrw s0, sscratch, x0`将 `sscratch` CSR 寄存器的值存入寄存器 `s0`，并将寄存器 `x0` 的值（通常为0）写入 `sscratch`，**将 `sscratch` 的值（即中断时保存的栈指针）备份到 `s0` 寄存器中**。同时将 `sscratch` 寄存器清零（因为 `x0` 是零寄存器，包含常数0），以防止在处理中断过程中出现嵌套中断时误用 `sscratch`。
  2. `SAVE_ALL` 宏中保存 `stval`和 `scause` CSR 的目的是为了在异常处理过程中能够访问这些寄存器的值。因为：`stval` (`sbadaddr`) 保存了发生异常时相关的地址（例如非法内存访问的地址）。`scause` 保存了导致异常的原因（如时钟中断、非法指令等）。
  3. 这类寄存器是只读的，在程序恢复正常执行后，恢复它们没有意义。它们的值仅在处理中断和异常时有用，用于确定异常发生的原因。


#### **Challenge03**：完善异常中断（编程）

在该练习中，我们需要编写异常中断程序，完善在触发一条非法指令异常mret和ebreak，在 kern/trap/trap.c的异常处理函数中捕获，并输出异常类型和异常指令触发地址，即“Illegal instruction caught at 0x(地址)”，“ebreak caught at 0x（地址）”与“Exception type:Illegal instruction"，“Exception type: breakpoint”。


- ##### 修改后的代码：

   1. **异常处理函数：`exception_handler`**
   ```
   void exception_handler(struct trapframe *tf) {
    switch (tf->cause) {
        case CAUSE_MISALIGNED_FETCH:
            break;
        case CAUSE_FAULT_FETCH:
            break;
        case CAUSE_ILLEGAL_INSTRUCTION:
             // 非法指令异常处理
             /* LAB1 CHALLENGE3  2210722 :  */
            /*(1)输出指令异常类型（ Illegal instruction）
             *(2)输出异常指令地址
             *(3)更新 tf->epc寄存器
             */
           
            //输出异常类型
            cprintf("Exception type: Illegal instruction\n");
            //输出异常指令触发地址
            cprintf("Illegal instruction caught at 0x%lx\n", tf->epc);  
            // tf->epc 增加4，因为RISC-V指令是32位，以跳过异常指令  
            tf->epc += 4;
            break;
        case CAUSE_BREAKPOINT:
            //断点异常处理
            /* LAB1 CHALLLENGE3   2210722:  */
            /*(1)输出指令异常类型（breakpoint）
             *(2)输出异常指令地址
             *(3)更新 tf->epc寄存器
            */

            cprintf("Exception type: breakpoint\n");  
            cprintf("ebreak caught at 0x%lx\n", tf->epc);
            // tf->epc 增加4，因为ebreak指令是16位
            tf->epc += 2;
            break;
            ......
    }
   }
   ```
   2. **`kern_init` 函数**
   ```
   ......
    clock_init();  // init clock interrupt
    __asm__ ("unimp");
    __asm__ ("ebreak");
    intr_enable();  // enable irq interrupt
   ......
   ```

- ##### 实现过程：
- 首先，修改exception_handler函数以处理非法指令异常（CAUSE_ILLEGAL_INSTRUCTION）和断点异常（CAUSE_BREAKPOINT）并更新 tf->epc寄存器以跳过异常指令；
- 此外，在kern_init函数中插入了__asm__ ("unimp"); 以触发非法指令异常，__asm__ ("ebreak"); 以触发断点异常。
- 最后运行系统，可以观察到两种异常处理的结果输出。

- ##### 实验运行结果：
- 编译：通过执行 `make` 命令使用Makefile编译修改后的代码。
- 运行：通过执行 `qemu-system-riscv64 --machine virt --nographic -kernel bin/ucore.img` 命令在QEMU模拟器中运行。
- 输出：分别输出非法指令异常和断点异常信息：
```
Exception type: Illegal instruction
Illegal instruction caught at 0x8020004a

Exception type: breakpoint
ebreak caught at 0x8020004a
```
