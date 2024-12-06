# uCore实验报告—lab4

🎀member:2212777 王舒瑀 2212138 唐苇苇 2210722 安楠🎀

## 练习1：分配并初始化一个进程控制块（需要编码）

alloc_proc函数（位于kern/process/proc.c中）负责分配并返回一个新的struct proc_struct结构，用于存储新建立的内核线程的管理信息。ucore需要对这个结构进行最基本的初始化，你需要完成这个初始化过程。

请简要说明你的设计实现过程并回答如下问题：
请说明proc_struct中`struct context context`和`struct trapframe *tf`成员变量含义和在本实验中的作用是啥？（提示通过看代码和编程调试可以判断出来）

**答：**

##### 1、proc_struct结构的初始化

```c++
proc->state = PROC_UNINIT; //   进程状态                  
proc->pid = -1;            //进程ID
proc->runs = 0;            //进程运行时间                  
proc->kstack = -1; 		   //进程的内核栈
proc->need_resched = 0;    //能否被调度  
proc->parent = NULL;       //线程的父线程        
proc->mm = NULL;            //线程的内存管理     
proc->cr3 = boot_cr3;        //页表项的基地址                 
proc->flags = 0;             //进程标记位                
memset(proc->name, 0, PROC_NAME_LEN + 1);   //进程名 
proc->tf = NULL;             //中断帧                
memset(&proc->context, 0, sizeof(struct context)); //进程状态保存
```

在**alloc_proc**函数中，只是对这个结构体进行初始化，只是找到了一小块内存用以记录进程的必要信息，并没有实际分配这些资源。并未赋予任何有实际意义的值。所以将进程状态设置为未初始化状态，也没有分配进程id，内核栈的位置等。**将cr3寄存器设置成内核的cr3寄存器的值，是因为在内核中的所有内核线程都共享同一块内核内存空间。**

##### 2、proc_struct中`struct context context`和`struct trapframe *tf`成员变量含义

* 在实验中的作用：
  * `struct context context`：储存进程当前状态，==用于进程切换中上下文的保存与恢复。==
    * 与`trapframe`所保存的用户态上下文不同，context保存的是线程的**当前**上下文。这个上下文可能是执行用户代码时的上下文，也可能是执行内核代码时的上下文。 在`switch to`函数中使用。
  * `struct trapframe *tf`：储存进程在用户态运行的状态，==用于回到用户态时的状态切换==。
    * 无论是用户程序在用户态通过系统调用进入内核态，还是线程在内核态中被创建，内核态中的线程返回用户态所加载的上下文就是`struct trapframe* tf`。 所以当一个线程在内核态中建立，则该新线程就必须伪造一个`trapframe`来返回用户态。

* 成员变量含义

  * `struct context context`

    ```c
    struct context {
        uintptr_t ra;
        uintptr_t sp;
        uintptr_t s0;
        uintptr_t s1;
        uintptr_t s2;
        uintptr_t s3;
        uintptr_t s4;
        uintptr_t s5;
        uintptr_t s6;
        uintptr_t s7;
        uintptr_t s8;
        uintptr_t s9;
        uintptr_t s10;
        uintptr_t s11;
    };
    ```

    context中主要是关键寄存器的值。ra是返回地址，sp是栈顶指针。剩余12个寄存器保存的是进程状态，方便进程切换时恢复状态。

  * `struct trapframe *tf`

    ```c
    struct trapframe {
        struct pushregs gpr;//寄存器
        uintptr_t status;//状态寄存器
        uintptr_t epc;//保存发生中断时的指令地址
        uintptr_t badvaddr;//保存引发异常的内存地址
        uintptr_t cause;//保存异常发生的原因，用于识别具体的中断或异常类型
    };
    ```

    存储的是运行在用户态时的状态。

    ## 练习2：为新创建的内核线程分配资源（需要编码）

    创建一个内核线程需要分配和设置好很多资源。kernel_thread函数通过调用**do_fork**函数完成具体内核线程的创建工作。do_kernel函数会调用alloc_proc函数来分配并初始化一个进程控制块，但alloc_proc只是找到了一小块内存用以记录进程的必要信息，并没有实际分配这些资源。ucore一般通过do_fork实际创建新的内核线程。do_fork的作用是，创建当前内核线程的一个副本，它们的执行上下文、代码、数据都一样，但是存储位置不同。因此，我们**实际需要"fork"的东西就是stack和trapframe**。在这个过程中，需要给新内核线程分配资源，并且复制原进程的状态。你需要完成在kern/process/proc.c中的do_fork函数中的处理过程。它的大致执行步骤包括：

    - 调用alloc_proc，首先获得一块用户信息块。
    - 为进程分配一个内核栈。
    - 复制原进程的内存管理信息到新进程（但内核线程不必做此事）
    - 复制原进程上下文到新进程
    - 将新进程添加到进程列表
    - 唤醒新进程
    - 返回新进程号

    请在实验报告中简要说明你的设计实现过程。请回答如下问题：

    * 请说明ucore是否做到给每个新fork的线程一个唯一的id？请说明你的分析和理由

**答：**

##### 1、do_fork函数

```c++
int do_fork(uint32_t clone_flags, uintptr_t stack, struct trapframe *tf) {
    int ret = -E_NO_FREE_PROC;
    struct proc_struct *proc;
    if (nr_process >= MAX_PROCESS) {
        goto fork_out;
    }
    ret = -E_NO_MEM;
 
  //分配一个PCB
    proc = alloc_proc();
    if (proc == NULL) {
        goto fork_out;
    }
    proc->parent=current;//设置父进程
    // // 分配内核栈
    if (setup_kstack(proc) < 0) {
        goto bad_fork_cleanup_proc;
    }

   // 将所有虚拟页数据复制过去
    if (copy_mm(clone_flags, proc) < 0) {
        goto bad_fork_cleanup_kstack;
    }

   // 复制线程的状态，包括寄存器上下文等等
    copy_thread(proc, stack, tf);
    bool intr_flag;
    local_intr_save(intr_flag);
        {
        
             // 将子进程的PCB添加进hash list或者list
            proc->pid = get_pid();  // Get a unique PID
            hash_proc(proc);
            list_add(&proc_list, &(proc->list_link));
            nr_process++;  // Increment the number of processes

        // 恢复中断
        }local_intr_restore(intr_flag);
   
    // 唤醒新进程，设置为runnale
    wakeup_proc(proc);

      // 返回子进程的pid
    ret = proc->pid;

fork_out:
    return ret;

bad_fork_cleanup_kstack:
    put_kstack(proc);
bad_fork_cleanup_proc:
    kfree(proc);
    goto fork_out;
}
```

具体执行步骤已经对应到代码中的相应注释位置。需要注意的是把**该PCB加入hash链表是为了加速该进程的查找**。

`do_fork`函数中的`copy_thread`函数会执行以下操作：

- 将`kernel_thread`中创建的新`trapframe`内容复制已有的`tf`，并压入该进程自身的内核栈。

- 设置`trapframe`的`a0`寄存器值为0，`esp`寄存器值为传入的`esp`，以及`eflags`加上中断标志位。

  > 设置a0寄存器的值为0，是因为子进程的fork函数返回的值为0。

- 最后，设置子进程上下文的`ra`为`forkret`，`sp`为该`trapframe`的地址。

##### 2、请说明ucore是否做到给每个新fork的线程一个唯一的id？请说明你的分析和理由

每个新fork的线程都会有一个唯一的id；线程id由get_pid()函数获取。

```c++
static int
get_pid(void) {
    static_assert(MAX_PID > MAX_PROCESS);
    struct proc_struct *proc;
    list_entry_t *list = &proc_list, *le;
    static int next_safe = MAX_PID, last_pid = MAX_PID;
    if (++ last_pid >= MAX_PID) {
        last_pid = 1;
        goto inside;
    }
    if (last_pid >= next_safe) {
    inside:
        next_safe = MAX_PID;
    repeat:
        le = list;
        while ((le = list_next(le)) != list) {
            proc = le2proc(le, list_link);
            if (proc->pid == last_pid) {
                if (++ last_pid >= next_safe) {
                    if (last_pid >= MAX_PID) {
                        last_pid = 1;
                    }
                    next_safe = MAX_PID;
                    goto repeat;
                }
            }
            else if (proc->pid > last_pid && next_safe > proc->pid) {
                next_safe = proc->pid;
            }
        }
    }
    return last_pid;
}
```

- `next_safe`是大于已分配进程id中大于`last_pid`中最小的。则说明`last_pid`到`next_safe`之间及`last_pid`都是安全可分配的PID。
- 在函数`get_pid`中，如果静态成员`last_pid`小于`next_safe`，则当前分配的`last_pid`一定是安全的，即唯一的PID。
- 但如果`last_pid`大于等于`next_safe`，或者`last_pid`的值超过`MAX_PID`，则当前的`last_pid`就不一定是唯一的PID，此时就需要遍历`proc_list`，重新对`last_pid`和`next_safe`进行设置，为下一次的`get_pid`调用打下基础。
- 之所以在该函数中**维护一个合法的`PID`的区间**，是为了**优化时间效率**。如果简单的暴力搜索，则需要搜索大部分PID和所有的线程，这会使该算法的时间消耗很大，因此使用`PID`区间来优化算法。

使用该函数就可以找到一个独一无二的id辨识进程。
这段代码提供了一种机制来保存和恢复中断状态，通常用于需要临时禁用中断以保护临界区代码的场景。下面是对代码的详细分析：

## 练习3：编写proc_run函数（需要编码）
    proc_run用于将指定的进程切换到CPU上运行。它的大致执行步骤包括：

    - 检查要切换的进程是否与当前正在运行的进程相同，如果相同则不需要切换。
    - 禁用中断。你可以使用/kern/sync/sync.h中定义好的宏local_intr_save(x)和local_intr_restore(x)来实现关、开中断。
    - 切换当前进程为要运行的进程。
    - 切换页表，以便使用新进程的地址空间。/libs/riscv.h中提供了lcr3(unsigned int cr3)函数，可实现修改CR3寄存器值的功能。
    - 实现上下文切换。/kern/process中已经预先编写好了switch.S，其中定义了switch_to()函数。可实现两个进程的context切换。
    - 允许中断。

    请回答如下问题：

    * 在本实验的执行过程中，创建且运行了几个内核线程？

**解答：**

##### 1、proc_run函数

```c++
void proc_run(struct proc_struct *proc) {
    if (proc != current) {
        bool intr_flag; 
        struct proc_struct *prev = current;
        local_intr_save(intr_flag); 
        {
            current = proc;
            lcr3(current->cr3);
            switch_to(&(prev->context), &(current->context));
        }
        local_intr_restore(intr_flag);
    }
}
```

`proc_run`函数中各个步骤的具体操作：

- 将当前正在运行的进程用临时进程控制块对象`prev`保存；

- 调用`local_intr_save(intr_flag)`保持当前中断状态到intr_flag并禁用中断；
    ```c++
    #define local_intr_save(x) \
        do {                   \
            x = __intr_save(); \
        } while (0)
    ```

- 当前进程设为待调度的进程`current = proc`；

- 更新页表，将当前的cr3寄存器改为需要运行进程的页目录表`lcr3(current->cr3)`。页目录表包含了虚拟地址到物理地址的映射关系,将当前进程的虚拟地址空间映射关系切换为新进程的映射关系，因此需要确保指令和数据的地址转换是基于新进程的页目录表进行的。

- 进行上下文切换`switch_to(&(prev->context), &(current->context))`，保存原线程的寄存器，同时恢复待调度线程的寄存器；

- 最后，调用`local_intr_restore(intr_flag)`恢复中断状态。
    ```c++
    #define local_intr_restore(x) __intr_restore(x);
    ```

##### 2、在本实验的执行过程中，创建且运行了几个内核线程？

共创建且运行了两个内核线程`idleproc`和`initproc`。

###### （1）创建内核线程

```c++
void proc_init(void) {
    int i;

    // 初始化进程列表
    list_init(&proc_list);
    // 遍历哈希列表的大小，对哈希列表中的每个元素进行初始化
    for (i = 0; i < HASH_LIST_SIZE; i ++) {
        list_init(hash_list + i);
    }

    // 分配一个进程结构给空闲进程（idle process），如果分配失败则触发panic
    if ((idleproc = alloc_proc()) == NULL) {
        panic("cannot alloc idleproc.\n");
    }

    // 检查idle process的上下文结构是否被正确初始化为零
    int *context_mem = (int*) kmalloc(sizeof(struct context)); // 分配内存用于比较
    memset(context_mem, 0, sizeof(struct context)); // 将分配的内存清零
    int context_init_flag = memcmp(&(idleproc->context), context_mem, sizeof(struct context)); // 比较空闲进程的上下文和清零的内存

    // 检查idle process的名称是否被正确初始化为零
    int *proc_name_mem = (int*) kmalloc(PROC_NAME_LEN);
    memset(proc_name_mem, 0, PROC_NAME_LEN);
    int proc_name_flag = memcmp(&(idleproc->name), proc_name_mem, PROC_NAME_LEN);

    if(idleproc->cr3 == boot_cr3 && idleproc->tf == NULL && !context_init_flag
        && idleproc->state == PROC_UNINIT && idleproc->pid == -1 && idleproc->runs == 0
        && idleproc->kstack == 0 && idleproc->need_resched == 0 && idleproc->parent == NULL
        && idleproc->mm == NULL && idleproc->flags == 0 && !proc_name_flag
    ){
        cprintf("alloc_proc() correct!\n");
    }
    
    // 设置idle process的基本信息，如PID、状态、内核栈、调度需求等
    idleproc->pid = 0;
    idleproc->state = PROC_RUNNABLE;
    idleproc->kstack = (uintptr_t)bootstack;
    idleproc->need_resched = 1;
    set_proc_name(idleproc, "idle"); // 设置进程名称为"idle"
    nr_process ++; // 增加进程计数

    // 将当前进程设置为空闲进程
    current = idleproc;

    // 创建一个内核线程（init process）来运行init_main函数
    int pid = kernel_thread(init_main, "Hello world!!", 0);
    if (pid <= 0) {
        panic("create init_main failed.\n"); // 如果创建失败，则触发panic
    }

    // 查找并设置init进程的指针
    initproc = find_proc(pid);
    set_proc_name(initproc, "init"); // 设置进程名称为"init"

    assert(idleproc != NULL && idleproc->pid == 0);
    assert(initproc != NULL && initproc->pid == 1);
}
```

`idleproc`的创建步骤：

1. **分配进程结构**：通过`alloc_proc()`函数为空闲进程分配一个进程控制块（PCB）。

2. **初始化进程结构**：将分配的进程结构进行初始化，包括设置一些基本字段（如PID、状态、内核栈等）为默认值。此时，进程通常处于未初始化（`PROC_UNINIT`）状态。

3. **检查初始化状态**：通过比较和验证，确保进程结构中的关键字段（如上下文和名称）已被正确初始化为零或空。

4. **设置特定属性**：为空闲进程设置特定的属性，设置PID为0、状态为可运行（`PROC_RUNNABLE`）、内核栈指向正确的位置、设置调度需求等。

5. **更新进程计数**：增加系统中进程的总数。

6. **设置为当前进程**：将空闲进程设置为当前正在执行的进程。

`initproc`的创建步骤：

1. **创建内核线程**：通过`kernel_thread()`函数创建一个内核线程来运行`init_main()`函数。

2. **获取线程PID**：从`kernel_thread()`函数的返回值中获取新创建的线程的PID（进程标识符）。

3. **查找进程结构**：使用获取到的PID，通过`find_proc()`函数在进程列表中查找对应的进程结构。

4. **设置进程属性**：为新找到的`init`进程设置特定的属性，设置PID为1、状态等。

5. **验证进程结构**：通过断言（`assert`）确保`init`进程的结构已被正确初始化和分配。


###### （2）运行内核线程

1. **运行`idleproc`**：`proc_init`函数在初始化`idleproc`时，`current = idleproc`将其设置为当前进程开始运行。同时将`idleproc->need_resched`置为1，以便马上调用`schedule`函数找其他处于“就绪”态的进程执行。

2. **运行`initproc`**：首先，`cpu_idle`判断当前内核线程`idleproc->need_resched`是否不为0，由于上文将其设置为1，则调用`schedule`函数在`proc_list`队列中查找下一个处于“就绪”态的线程（由于`proc_list`中只有两个内核线程，因此只能找到`initproc`），并通过`proc_run`和进一步的`switch_to`函数完成两个执行现场的切换。至此，就切换到了`initproc`内核进程运行。


## 扩展练习 Challenge：
说明语句local_intr_save(intr_flag);....local_intr_restore(intr_flag);是如何实现开关中断的？

###### 解答：
首先先找到对应代码
```
#define local_intr_save(x)      do {x = __intr_save(); } while (0)
#define local_intr_restore(x)   __intr_restore(x);

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
        intr_disable();
        return 1;
    }
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
        intr_enable();
    }
}
/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
```

local_intr_save宏接受一个参数`x`，这个参数用于存储`__intr_save`函数的返回值。 `do { x = __intr_save(); } while (0)`：宏展开为一个`do-while`循环，这个循环实际上只执行一次。这样写是为了在调用的时候，这一段一定被单独解释为一条语句执行，`__intr_save`函数被调用，其返回值被赋值给变量`x`。数，如果当前 sstatus 寄存器的 SIE 位为 1（启用状态），则执行 intr_disable() 禁用中断，并返回 1 表示中断原本是开启的；否则，返回 0 表示中断原本是关闭的。intr_disable 通过清除SSTATUS_SIE位来禁用中断，而 intr_enable 通过设置SSTATUS_SIE位来启用中断。local_intr_restore(intr_flag)通过宏'_intr_restore '恢复之前保存的中断状态，再启用intr_enable的值来重新启用或禁用中断。

这两对函数和宏提供了一种机制来保存和恢复中断状态。`__intr_save`函数检查是否需要禁用中断，并返回一个标志。`local_intr_save`宏使用这个函数来保存中断状态，并将返回值存储在一个变量中。`__intr_restore`函数根据传入的标志决定是否需要重新使能中断。`local_intr_restore`宏使用这个函数来恢复中断状态。这种机制确保在执行进程切换时时不会被中断打断。
