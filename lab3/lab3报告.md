# uCore 实验报告：lab3

## 练习 3：给未被映射的地址映射上物理页

### 任务概述

本练习的目标是实现 `do_pgfault` 函数，处理页面错误并将未映射的虚拟地址映射到物理页。为了实现这一目标，我们需要根据虚拟内存区域（VMA）设置正确的访问权限，并且根据页表和内存控制结构进行操作。特别需要注意的是，我们必须操作指定的页表，而不是内核的页表。

### 实现过程

1. **查找虚拟内存区域**：
   首先，我们需要根据错误地址查找包含该地址的虚拟内存区域（VMA）。如果无法找到该地址或者该地址无效，返回错误。

2. **确定页面权限**：
   根据 VMA 的标志位（如 `VM_WRITE`），设置页面的访问权限。如果 VMA 是可写的，则该页面需要同时具备读写权限。否则，只需设置为只读权限。

3. **查找页表项**：
   获取页表项（PTE），如果该地址映射的页面不存在，则分配一个新的物理页面并建立映射。如果页面已经存在，则需要处理可能的交换操作，从交换区加载该页面到内存中。

4. **操作页面和页表**：
   - 如果页表项为空（表示该虚拟地址没有映射到物理页面），则需要分配新的物理页面并将其映射到该地址。
   - 如果该页面已经存在于内存中，但需要从交换区恢复，则使用 `swap_in` 将页面加载到内存中，并通过 `page_insert` 函数将其插入到页表。

### `do_pgfault` 实现代码

```c
int do_pgfault(struct mm_struct *mm, uint_t error_code, uintptr_t addr) {
    int ret = -E_INVAL;
    struct vma_struct *vma = find_vma(mm, addr); // 查找包含错误地址的VMA
    pgfault_num++;
    
    if (vma == NULL || vma->vm_start > addr) { // 地址无效
        cprintf("not valid addr %x, and  can not find it in vma\n", addr);
        goto failed;
    }
    
    uint32_t perm = PTE_U;
    if (vma->vm_flags & VM_WRITE) { // 设置页面权限
        perm |= (PTE_R | PTE_W);
    }
    
    addr = ROUNDDOWN(addr, PGSIZE); // 对齐到页面边界
    ret = -E_NO_MEM;
    pte_t *ptep = get_pte(mm->pgdir, addr, 1); // 获取页表项
    
    if (*ptep == 0) { // 页面不存在：分配新的页面
        if (pgdir_alloc_page(mm->pgdir, addr, perm) == NULL) {
            cprintf("pgdir_alloc_page in do_pgfault failed\n");
            goto failed;
        }
    } else { // 页面已存在：可能需要从交换区加载
        if (swap_init_ok) {
            struct Page *page = NULL;
            swap_in(mm, addr, &page); // 从交换区加载页面
            page_insert(mm->pgdir, page, addr, perm); // 在页表中插入映射
            swap_map_swappable(mm, addr, page, 1); // 将该内存页设置为可交换
            page->pra_vaddr = addr; // 保存虚拟地址
        } else {
            cprintf("no swap_init_ok but ptep is %x, failed\n", *ptep);
            goto failed;
        }
    }
    ret = 0;
failed:
    return ret;
}
```

### 设计实现过程

1. **查找虚拟内存区域**：`find_vma` 函数查找包含给定地址的 VMA。通过 VMA，我们可以确定地址的有效性和所需的访问权限。
2. **设置页面权限**：根据 VMA 中的标志位设置页面的访问权限。若是可写（`VM_WRITE`），则权限设置为可读写。
3. **处理页表**：通过 `get_pte` 获取页表项，检查该虚拟地址是否已经映射到物理页。若未映射，则调用 `pgdir_alloc_page` 分配新的物理页。
4. **交换操作**：如果页面已存在但需要从交换区加载，则通过 `swap_in` 将其加载到内存，并更新页表。

### 问题解答

1. **页目录项（PDE）和页表项（PTE）的作用**：
   - **PDE** 和 **PTE** 是管理虚拟地址空间的核心数据结构，分别用于表示虚拟内存区域的页目录和页表的映射。PDE 负责管理更大粒度的内存区域，而 PTE 则直接映射具体的物理页。
   - 对于页替换算法（如 Clock 算法），PDE 和 PTE 的信息（如访问权限、页状态等）可以帮助决定是否需要换出某个页面。

2. **缺页异常时硬件的处理**：
   当执行缺页异常时，硬件首先会产生一个页面访问异常，然后 CPU 会跳转到操作系统提供的缺页处理例程（如 `do_pgfault`）。硬件会提供错误码和错误地址，操作系统根据这些信息决定是否分配新的物理页面或从交换区加载页面。

3. **Page 数据结构与页表项的关系**：
   - `Page` 数据结构是 uCore 管理物理页的基础，通常以数组形式存在，每个 `Page` 代表一个物理页面。
   - 页目录项和页表项指向具体的物理页，它们通过映射关系与 `Page` 数据结构中的项对应。具体来说，页表项（PTE）中的物理页地址指向 `Page` 数据结构中的具体项。

## 练习 4：Clock 页替换算法

### 任务概述

在本练习中，我们将实现 Clock 页替换算法。Clock 算法是一种基于访问位（即 `visited` 标志位）管理页面替换的算法。与 FIFO 算法相比，Clock 算法具有更好的性能，因为它能够有效地识别未被访问的页面，从而进行替换。

### 实现思路

Clock 页替换算法通过维护一个循环链表，模拟时钟的指针，在页面链表中遍历，查找访问位为 0 的页面进行替换。每次访问页面时，将其访问位设置为 1，表示该页面已被访问。Clock 算法通过指针遍历链表，直到找到一个访问位为 0 的页面，然后将其换出。

### 代码实现

#### 1. 初始化 Clock 算法数据结构

```c
static int _clock_init_mm(struct mm_struct *mm)
{
    list_init(&pra_list_head); // 初始化页面链表
    curr_ptr = &pra_list_head; // 初始化当前指针
    mm->sm_priv = &pra_list_head; // 设置私有成员指针
    return 0;
}
```

#### 2. 将页面插入交换区

```c
static int _clock_map_swappable(struct mm_struct *mm, uintptr_t addr, struct Page *page, int swap_in)
{
    list_entry_t *entry = &(page->pra_page_link); // 获取页面链表项
    list_entry_t *head = (list_entry_t *)mm->sm_priv; // 获取链表头
    list_add_before(head, entry); // 将页面插入链表头
    page->visited = 1; // 设置访问位为 1
    return 0;
}
```

#### 3. 页面换出策略

```c
static int _clock_swap_out_victim(struct mm_struct *mm, struct Page **ptr_page, int in_tick)
{
    list_entry_t *head = (list_entry_t *)mm->sm_priv;
    while (1) {
        curr_ptr = list_next(curr_ptr); // 遍历链表
        if (curr_ptr == head) {
            curr_ptr = list_next(curr_ptr); // 遇到头部时跳过
            if (curr_ptr == head) {
                *ptr_page = NULL; // 链表为空，返回 NULL
                break;
            }
        }
        struct Page *page = le2page(curr_ptr, pra_page_link);
        if (page->visited == 0) { // 找到未访问的页面
            *ptr_page = page;
            list_del(curr_ptr); // 删除该页面
            break;
        } else {
            page->visited = 0; // 重置访问位
        }
    }
    return 0;
}
```
### 设计实现过程

1. **初始化函数 (`_clock_init_mm`)**：
    
    * 初始化一个链表 `pra_list_head` 用于存储页面，`curr_ptr` 指向链表头。
    * 将 `mm->sm_priv` 设置为链表头的地址，供后续的替换算法操作使用。
2. **将页面标记为可交换 (`_clock_map_swappable`)**：
    
    * 将页面插入到链表头部，并将页面的访问位设置为 1，表示该页面已被访问。
3. **选择被替换的页面 (`_clock_swap_out_victim`)**：
    
    * 遍历链表，查找访问位为 0 的页面。如果页面被访问过，则将其访问位重置为 0。直到找到一个未被访问的页面，并将其从链表中删除。

### 问题回答

1. **Clock 与 FIFO 算法的不同**：
    
    * FIFO 算法基于页面进入内存的顺序来替换页面，简单但不考虑页面的使用频率。
    * Clock 算法通过访问位来动态判断哪些页面需要替换，更能反映页面的实际使用情况。相较于 FIFO，Clock 算法能有效减少不必要的页面替换，提高性能。
2. **Clock 算法的核心思想**：
    
    * Clock 算法通过一个指针 (`curr_ptr`) 在双向链表上循环遍历，检查每个页面的访问位。如果页面的访问位为 0，则将其替换，否则将访问位重置为 0，并继续遍历。Clock 算法是一种基于**访问位**的改进型页面替换算法。它是**FIFO**算法的改进，试图在页面替换过程中考虑页面的使用情况，从而降低页面替换的代价。Clock 算法常常被用于操作系统的虚拟内存管理中，尤其是在内存受限的环境下，它通过简化页面替换过程来提高性能。
Clock 算法通常使用一个**循环链表**来管理所有的页面。每个页面都包含一个**访问位**（通常是 1 或 0）和一个指向下一个页面的指针。指针（或叫“时钟指针”）指向链表中的某个页面，类似于时钟的指针不断旋转。访问位（visited）表示页面是否被访问过。访问位为 1 表示该页面最近被访问过，0 表示该页面最近没有被访问。Clock算法通过一个指针（curr_ptr）在循环链表上进行“钟表旋转”。在每一次页面替换时，curr_ptr 会检查指向页面的访问位：如果访问位为 0：该页面是候选页面，可以被替换。将这个页面从链表中移除，并替换为新的页面。如果访问位为 1：该页面在最近的操作中已经被访问过，因此 不进行替换。此时会将页面的访问位重置为 0，并移动指针，继续检查下一个页面。
