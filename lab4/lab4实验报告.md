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
