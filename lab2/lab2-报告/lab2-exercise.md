# 实验报告

## 练习 1：理解 First-Fit 连续物理内存分配算法

在First-Fit分配算法中，分配器维护一个自由块列表。当有内存请求时，分配器会从列表中找到第一个足够大的块来满足请求。如果所选的块比请求的大得多，通常会分割该块，并将剩余部分重新放入列表。

### 函数分析
代码分为四个主要部分，分别为：初始化空闲内存、初始化内存块、分配页面、释放页面。
1. **初始化空闲内存**:
   ```c
   free_area_t free_area;

   #define free_list (free_area.free_list)
   #define nr_free (free_area.nr_free)

   static void default_init(void) {
    list_init(&free_list);
    nr_free = 0;
   }
   ```
   default_init 函数用于初始化自由块列表 free_list，并将空闲页数 nr_free 设为 0。free_area_t 数据结构管理自由块列表，包含一个链表 free_list 来存储所有空闲内存块，以及空闲页的数量 nr_free。

2. **初始化内存块**：
   ```c
   static void default_init_memmap(struct Page *base, size_t n) {
    assert(n > 0);
    struct Page *p = base;
    for (; p != base + n; p++) {
        assert(PageReserved(p));
        p->flags = p->property = 0;
        set_page_ref(p, 0);
    }
    base->property = n;
    SetPageProperty(base);
    nr_free += n;
    if (list_empty(&free_list)) {
        list_add(&free_list, &(base->page_link));
    } else {
        list_entry_t* le = &free_list;
        while ((le = list_next(le)) != &free_list) {
            struct Page* page = le2page(le, page_link);
            if (base < page) {
                list_add_before(le, &(base->page_link));
                break;
            } else if (list_next(le) == &free_list) {
                list_add(le, &(base->page_link));
            }
        }
    }
   }

   ```
   default_init_memmap 函数将一段内存初始化为空闲块，并将这些块加入空闲链表。该函数循环遍历所指定的内存块范围，设置每一块的属性，并根据地址排序插入到 free_list 中。nr_free 记录当前空闲的页面数。这样就初始化一个连续的空闲内存块。每个页框的属性都需要进行设置：
   - 第一个页框的 `property` 字段记录了整个块的大小。
   - 其他页框的 `property` 设为 0，并将它们链接到空闲列表中。

3. **分配页面**：
   ```c
   static struct Page *default_alloc_pages(size_t n) {
    assert(n > 0);
    if (n > nr_free) {
        return NULL;
    }
    struct Page *page = NULL;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
        struct Page *p = le2page(le, page_link);
        if (p->property >= n) {
            page = p;
            break;
        }
    }
    if (page != NULL) {
        list_entry_t* prev = list_prev(&(page->page_link));
        list_del(&(page->page_link));
        if (page->property > n) {
            struct Page *p = page + n;
            p->property = page->property - n;
            SetPageProperty(p);
            list_add(prev, &(p->page_link));
        }
        nr_free -= n;
        ClearPageProperty(page);
    }
    return page;
   }

   ```
   default_alloc_pages函数负责根据请求分配页面。它遍历自由块列表，找到第一个足够大的块就使用。找到合适的块后，如果该块比请求的大小大，则将其分割并将剩余部分重新加入自由列表。更新空闲页面的数量nr_free。

4. **default_free_pages**：
   ```c
   static void default_free_pages(struct Page *base, size_t n) {
    assert(n > 0);
    struct Page *p = base;
    for (; p != base + n; p++) {
        assert(!PageReserved(p) && !PageProperty(p));
        p->flags = p->property = 0;
        set_page_ref(p, 0);
    }
    base->property = n;
    SetPageProperty(base);
    nr_free += n;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
        struct Page *p = le2page(le, page_link);
        if (base + n == p) {
            base->property += p->property;
            list_del(le);
        }
        else if (p + p->property == base) {
            p->property += base->property;
            base = p;
        }
    }
    list_add_before(&free_list, &(base->page_link));
   }
   ```
   default_free_pages 函数将指定的页面释放回空闲块列表。函数通过合并相邻的空闲块来减少碎片，并将释放后的块添加到自由列表中。主要步骤包括，清除被释放内存块中所有页框的标志和属性信息，将引用计数置零。将释放的内存块插入 free_list，保持地址顺序。检查并合并相邻的连续空闲内存块。更新nr_free，增加释放的页数。

### 物理内存分配过程
当系统需要分配物理内存时，`default_alloc_pages` 函数会按照 First-Fit 策略查找第一个满足条件的内存块。找到后进行分配，若剩余空间足够大则拆分。释放内存时，`default_free_pages` 会尝试合并相邻的空闲块，减少内存碎片。

|0x80000000|--openSBI --|0x80200000|--kernel--|0x80200000|--VPT--|0x80347000|--可分配的页资源--|0x88000000|


### 改进空间
First-Fit 算法容易导致内存碎片问题，随着时间推移，空闲内存块分布越来越不连续，可能导致内存利用率下降。可以尝试引入内存压缩或更复杂的内存分配算法（如 Best-Fit 或 Worst-Fit）来优化碎片问题。


##  练习2：Best-Fit连续物理内存分配算法实现及深入分析

在本练习中，任务是基于 `kern/mm/default_pmm.c` 中 First-Fit 算法的实现，设计并实现 Best-Fit 连续物理内存分配算法。Best-Fit 算法需要找到**最小且满足需求的连续内存块**，这与First-Fit 算法（从链表头部开始，找到第一个满足条件的内存块）不同。

Best-Fit 算法的核心思想是，在空闲内存块链表中找到最接近所需大小的内存块，以减少内存碎片的产生。下面我们对代码进行详细分析。

### 1. Best-Fit 算法流程概述

#### (1) 内存块初始化：`best_fit_init_memmap`

内存分配首先需要初始化内存块 (`Page` 结构体)，函数 `best_fit_init_memmap` 用于将连续的物理内存页面初始化为空闲状态，并加入到空闲链表中。这是分配算法的基础。

##### 关键步骤：

* **属性设置**：每个页面都被标记为空闲，且 `property` 字段表示该内存块包含的连续空闲页面的数量。
* **空闲链表管理**：空闲链表的维护是核心，Best-Fit 需要保证链表中每个空闲内存块按照地址从低到高排序。在加入空闲链表时，函数会查找链表中第一个地址大于 `base` 的页面，并将新页块插入该位置。

**代码片段：**

```c
if (base < page) {
    list_add_before(le, &(base->page_link));
    break;
} else if (list_next(le) == &free_list) {
    list_add(le, &(base->page_link));
}
```

**分析**：此段代码负责将 `base`（新的空闲块）按地址顺序插入空闲链表，保证链表顺序正确，为后续的 Best-Fit 搜索提供便利。

#### (2) 分配内存页面：`best_fit_alloc_pages`

该函数实现了 Best-Fit 算法的核心逻辑，即在空闲链表中寻找最适合的内存块来满足分配请求。

##### 关键步骤：

* **遍历空闲链表**：通过 `list_next(le)` 遍历空闲内存块链表，找到最小且大于等于 `n` 个页面的空闲块。
* **最小块查找**：在遍历过程中记录满足条件的最小块，避免直接分配第一个符合条件的块，从而减少内存碎片。

**代码片段：**

```c
while ((le = list_next(le)) != &free_list) {
    struct Page *p = le2page(le, page_link);
    if (p->property >= n && p->property < min_size) {
        t = p;
        min_size = p->property;
    }
}
```

**分析**：该循环遍历整个链表，寻找能满足请求的最小块。`min_size` 初始设置为 `nr_free + 1`，表示尚未找到合适的块。每次找到符合条件的块时，将 `min_size` 更新为该块大小，并将 `t` 指向该块。

* **分配页面**：一旦找到最合适的块，将其从链表中移除。如果空闲块比请求的页数多，则需要将剩余的部分重新插入空闲链表。

**代码片段：**

```c
if (page->property > n) {
    struct Page *p = page + n;
    p->property = page->property - n;
    SetPageProperty(p);
    list_add(prev, &(p->page_link));
}
```

**分析**：如果当前找到的块比需要的页面多，则将剩余部分重新插入链表。这样做能够防止浪费多余的页面，维持内存利用率。

#### (3) 释放内存页面：`best_fit_free_pages`

该函数实现了内存块的释放逻辑，将被释放的页面重新加入空闲链表，并尝试与相邻的空闲块合并，以减少内存碎片。

##### 关键步骤：

* **链表插入**：和初始化时一样，在释放时需要将内存块按地址顺序插入空闲链表中。
  
* **合并相邻块**：释放页面后，检查释放的块是否与前后相邻的块连续。如果是，则合并它们，以减少链表中小块的碎片化问题。
  

**代码片段：**
```c
static void best_fit_free_pages(struct Page *base, size_t n) {
    struct Page *p = base;
    for (size_t i = 0; i < n; i++, p++) {
        assert(!PageReserved(p) && !p->property);
        p->flags = 0;
        set_page_ref(p, 0);
    }
    base->property = n;
    nr_free += n;
    list_entry_t *le = &free_list;
    list_entry_t *head = le;
    list_entry_t *next;
    while ((next = list_next(le)) != head) {
        if (le2page(next, page_link) > base) {
            break;
        }
        le = next;
    }
    list_add_before(le, &(base->page_link));
}
```

**分析：**

* **遍历释放的页块**：清除页块的标志位，并将其引用计数器重置为 0。
* **更新页块属性**：将该页块的 `property` 设置为所释放页块的数量 `n`。
* **插入空闲链表**：将释放的页块插入到 `free_list` 中，保持链表的物理地址顺序。

释放操作将已分配的页块重新标记为空闲状态，并将其插回到空闲页块链表中。


#### (4) 查看空闲页数：`best_fit_nr_free_pages`

```c
static size_t best_fit_nr_free_pages(void) {
    return nr_free;
}
```

**分析：**

* 返回全局变量 `nr_free`，即当前系统中空闲页块的数量。

该函数简单地返回当前的空闲页块数量，用于监控内存的使用情况。

* * *


### 2. Best-Fit 算法的优缺点分析

#### 优点：

* **减少内存碎片**：与 First-Fit 相比，Best-Fit 能更有效地减少内存碎片，因为它总是选择最小的满足需求的块。
* **较高的内存利用率**：通过合并相邻块并确保分配最小合适块，Best-Fit 能够提高内存的利用率。

#### 缺点：

* **搜索复杂度较高**：Best-Fit 需要遍历整个空闲链表来寻找最合适的块，因此在分配内存时的时间复杂度相对较高，尤其在空闲块较多时表现较差。
* **合并操作的开销**：内存释放时的合并操作也会带来一定的开销，尤其是在频繁分配和释放时。

### 3. 算法改进空间

虽然 Best-Fit 能够减少内存碎片，但它在实际使用中也有改进的空间：

* **链表优化**：可以考虑使用更复杂的数据结构（如平衡二叉树或堆）来管理空闲块，以提高分配和合并操作的效率。这样可以避免遍历链表的开销，从而减少搜索的时间复杂度。
* **快速分配策略**：可以引入快速分配的策略，例如为常见的块大小设置特定的链表，从而减少搜索时间。
* **内存碎片处理**：实现内存压缩算法，定期整理内存，合并小的空闲块。引入分割阈值，当剩余空间大于某个阈值时才进行分割，减少小碎片的产生。


## Challenge：buddy system（伙伴系统）分配算法

Buddy System算法把系统中的可用存储空间划分为存储块(Block)来进行管理（分配和回收）, 每个存储块的大小必须是2的n次幂(Pow(2, n)), 即1, 2, 4, 8, 16, 32, 64, 128...

### 1、Buddy System的设计思想

#### （1）内存块初始化

`buddy_init_memmap()` 函数在系统初始化时，划分内存空间并按 2 的幂次分级存入各自的空闲链表中。具体步骤为：

- **地址获取与初始化**：初始化时，利用 `page2pa` 函数获取内存块的首地址，并根据**内存大小逐级划分**（比如：先对内存取小于内存的最大二次幂，再对剩余的内存进行同样处理，直至处理完所有内存）。

- **链表管理**：每个空闲块按 `order`（即块的大小等级，也就是内存大小对应2的指数）加入到 `free_list[order]` 链表中，同时更新空闲块数量 `nr_free[order]`。

  划分图示如下：
  
  <img src="image-20241025193924270.png" alt="image-20241025193924270"  />

#### （2）内存分配

在进行内存分配时，通过 `buddy_alloc_pages(size_t n)` 函数完成。该功能的主要思想为：

- **向上取整**：通过 `round_up` 函数获取所需大小的 `order`，并确保分配的内存块大小不小于请求大小。

- **块查找**：在 `free_list` 中查找满足需求的块。若 `free_list[order]` 无法提供足够的块，将检查更大的块，并通过逐步切割获得适当大小。

- **切割**：当找到的块大于所需大小时，将其不断向下切割，直到达到需求大小。每次切割生成的空闲块将重新加入 `free_list`，方便下次分配。

- **属性设置**：分配成功后，设置块属性并标记为已使用。

  划分图示：（着色部分为已分配，图示为已经分配一个13order和12order的块后，再申请一个13order的块，此时需要将order为14的块分割，order13的两个块并连入链表，order14的块从链表中删除）


    <img src="图片3.png" alt="图片3"  />
  
  #### （3）内存释放
  
  当释放内存块时，通过 `buddy_free_pages(struct Page *base, size_t n)` 函数实现。该功能逻辑如下：
  
  - **伙伴查找**：释放内存时，首先通过计算当前块的左、右伙伴地址，判断是否可以与左、右伙伴块合并。
  - **合并检查**：若左、右伙伴块与当前块的大小相同且位于空闲状态，则可进行合并操作，将两个块视为一个更大的块并继续向上合并。该过程一直进行，直到不能继续合并为止。
  - **属性更新**：释放并合并完成后，将最终的内存块重新加入 `free_list` 中，将被合并的块删除并更新空闲块计数。

### 2、Buddy System的具体实现

#### （1）内存管理

```c++
typedef struct {
    list_entry_t free_list[Max_Order + 1];//管理内存块
    unsigned int nr_free[Max_Order + 1];//内存块数量
} BuddySystem;

```



#### （2）内存初始化

```c++
static void buddy_init_memmap(struct Page *base, size_t n) {
  uintptr_t begin_addr = page2pa(base);//获取首地址 page转换地址
  //核心：将非2次幂的数据划分成小块的2的次幂
  cprintf("构建buddy_system前:\n");
  print_buddy();
  while(n){
    
    int order=0;
    size_t order_size;//每一个order有多少页
    order=round_down(n);
    cprintf("order:%d\n",order);
    order_size=1u<<order;
      
    struct Page* p = pa2page(begin_addr);//设置起始地址
    p->property = order;//
    SetPageProperty(p);
  
   cprintf("Adding page at %p to free_list[%d]\n", p, order);
   list_add(&free_list[order],&p->page_link);//这里的free——list编号从下到上编号 8页对应3
   nr_free[order]++;
   begin_addr+=order_size*PGSIZE;
   n-=order_size;
  }
  cprintf("构建buddy_system后:\n");
  print_buddy();
}
```

#### （3）内存分配

```c++
 static struct Page *buddy_alloc_pages(size_t n) {
    size_t need_order = round_up(n); // 向上取整，得到需要的order
    // 找到适合的空闲块
    for (size_t order = need_order; order <= Max_Order; order++) {
      cprintf("order：%d\n",order);
        if (nr_free[order] > 0) {// 如果找到了合适的空闲块，进行分配
            list_entry_t *le = list_next(&free_list[order]);
            list_del(le);
            nr_free[order]--;
            struct Page *allocated_page = le2page(le, page_link);   //链表条目获取page
            allocated_page->property = order; // 设置属性
            SetPageProperty(allocated_page);
            // 如果找到的块比需要的块大，进行切割
            while (order > need_order) {
                order--; // 将order减小，准备切割
                struct Page *remaining_page = allocated_page + (1 << order); 
                // 更新剩余页面的属性
                remaining_page->property = order; 
                SetPageProperty(remaining_page);
                 allocated_page->property = order; // 设置属性
                  SetPageProperty(allocated_page);
                // 将剩余页面添加到链表中
                list_add(&free_list[order], &remaining_page->page_link);
                nr_free[order]++;
            }

            cprintf("buddy_system:\n");
            print_buddy();
            return allocated_page; // 返回分配的页面
        }
    }
    cprintf("No block!\n");
    return NULL; // 没有找到合适的块
}
```

#### (4)内存释放

```c++
static void buddy_free_pages(struct Page *base, size_t n) {
    size_t order = base->property;  // 获取当前块的 order
    uintptr_t base_addr = page2pa(base);  // 获取当前块的物理地址
    struct Page *buddy_page = NULL;  // 伙伴页
    while (order <= Max_Order) {
        // 计算左侧和右侧伙伴地址
        uintptr_t left_buddy_addr = base_addr - (1 << order);
        uintptr_t right_buddy_addr = base_addr + (1 << order);
        struct Page *left_buddy_page = pa2page(left_buddy_addr);
        struct Page *right_buddy_page = pa2page(right_buddy_addr); 		       
        int merged = 0;  // 标记是否发生了合并
        //合并左侧伙伴  
        if ( left_buddy_addr >= 0x80200000 && // 确保左侧伙伴在有效内存范围内
            left_buddy_page->property == order && 
            PageProperty(left_buddy_page)&&//该页是否自由
            nr_free[order]) {
            // 左侧伙伴块可合并
            list_del(&left_buddy_page->page_link);
            nr_free[order]--;
            base = left_buddy_page;  // 合并后，base 指向较小地址的块
            base_addr = left_buddy_addr;
            merged = 1;
        }
        // 如果左侧伙伴不可合并，尝试合并右侧伙伴   
        else if ( right_buddy_addr < 0x88000000 && // 确保右侧伙伴在有效内存范围内
                 right_buddy_page->property == order && 
                  PageProperty(right_buddy_page)&&
                  nr_free[order]) {
            list_del(&right_buddy_page->page_link);
            nr_free[order]--; // base 不变，仍指向当前块（较小地址的块）
            merged = 1;
        }
        // 如果发生了合并，增加块的 order，继续递归检查合并后的块
        if (merged) {
            base->property++;
            order = base->property;
        } else {
            // 无法再合并，跳出循环
            break;
        }
    }    // 合并完成后，将块加入对应 order 的 free_list
    SetPageProperty(base);
    list_add(&free_list[base->property], &base->page_link);
    nr_free[base->property]++;
}
```



### 3、Buddy System的正确性证明

#### （1）验证函数

```c++
static void basic_check(void) {
    struct Page *p0, *p1, *p2;
    assert((p0 = alloc_pages(1)) && (p1 = alloc_pages(3)) && (p2 = alloc_pages(5)));
    free_pages(p0,1);
    free_pages(p2,5);

    assert((p0 = alloc_pages(4)) && (p2 = alloc_pages(3)));
    free_pages(p0, 4);
    free_pages(p1, 3);

    assert((p0 = alloc_pages(9)));
    free_pages(p0, 9);
    free_pages(p2, 3);
    
}
```

#### （2）正确性

以下操作均为连续

* 初始化内存分配的块有：

  <img src="image-20241025201327888.png" alt="image-20241025201327888" style="zoom:33%;" />

  

* 分配

  首先分配一块order为0的块 ，如下图左，可正常分配；再分配一块order为2的，需要将order为3的分割，如下图右正常分割。

  | 分配一块order为0                                             | 分配一块order为2                                             |
  | ------------------------------------------------------------ | ------------------------------------------------------------ |
  | <img src="image-20241025201508229.png" alt="image-20241025201508229" style="zoom: 45%;" /> | <img src="image-20241025201720849.png" alt="image-2024102521720849" style="zoom: 43%;" /> |

  

  

* 释放

  释放order为1的块时，无可合并，直接并入相应链表。释放order为3的块时，可以合并，最终合并入order为4的块，连入相应链表
  
  | 合并大小为1的块                                              | 合并大小为3的块                                              |
  | ------------------------------------------------------------ | ------------------------------------------------------------ |
  | <img src="image-20241025202214940.png" alt="image-20241025202214940" style="zoom:40%;" /> | <img src="image-20241025202803406.png" alt="image-20241025202803406" style="zoom:40%;" /> |
  

* assert断言

  验证函数中的assert断言全部通过！


## Challenge：任意大小的内存单元slub分配算法

### 1、slub的设计思想

#### （1）内存块管理
SLUB算法通过维护`slub`和`kmem_cache`结构体来管理内存。每个内存块包含以下关键信息：

`slub`包含以下成员：
- **num**：该内存块当前可用于分配的单元数量。
- **next**：指向链表中下一个内存块的指针。

`kmem_cache`包含以下成员：
- **order**：cache所包含的页面数。
- **slubs**：指向实际分配的内存slub的指针。
- **next**：指向下一个kmem_cache结构体的指针。
- **objsize**：指向下一个kmem_cache结构体的指针对应slub的大小。


  指针连接关系图示如下：
  
 <img src="图片1.png" alt="图片1"  />

#### （2）内存分配

当需要分配内存时，SLUB算法通过 `kmem_cache_alloc(size_t size) ` 函数完成。该功能的主要思想为：

- **判断是否为小块**：通过`SULB_SIZE`判断是否为小于一页的小块，如果小于则向下查找；如果大于，则直接调用`buddy_system`分配算法。
- **查找合适的内存块**：遍历空闲内存块链表，找到一个num值大于或等于请求单元数量的内存块。
- **分割内存块**：如果找到的内存块比请求的内存大很多，SLUB会将其分割成两部分：一部分用于满足当前请求，另一部分作为新的空闲内存块放回链表中。
- **更新链表**：将满足请求的内存块从链表中移除，并更新链表的头指针（slubs_free）。
如果现有的空闲内存块无法满足请求，SLUB会尝试从操作系统中分配新的内存页，并将其初始化为一个或多个空闲内存块。

  
#### （3）内存释放
  释放内存时，SLUB算法通过 `kmem_cache_free(void *slub) ` 函数实现。该功能逻辑如下：
  
 - **判断是否为小块**：依然先判断是否为小于一页的小块，如果小于则继续释放；如果大于，则直接调用`buddy_system`释放算法。
 - **检查前向合并**：如果释放的内存块前面有一个空闲内存块，并且它们相邻，则将它们合并成一个更大的空闲内存块。
 - **检查后向合并**：同样地，如果释放的内存块后面有一个空闲内存块，并且它们相邻，则也将它们合并。
 - **更新链表**：将合并后的内存块（或未合并的释放内存块）放回空闲内存块链表中，并更新链表的头指针。


### 2、slub的具体实现

#### （1）内存管理

```c++
struct kmem_cache {
    void *slubs;
    struct kmem_cache *next;
    // list_entry_t slabs_full; 
    // list_entry_t slabs_partial;
    // list_entry_t slabs_free; 
    
    uint16_t objsize; // 对象⼤⼩
    uint16_t order; // 每个Slub保存的对象数⽬
};
typedef struct kmem_cache kmem_cache_t;

struct slub {
    
    //int ref; // ⻚的引⽤次数（保留）
    struct slub *next;//下一个slut块
    uint16_t num; // 对象⼤⼩
    //uint16_t inuse; // 已分配对象的数⽬
    //int16_t free; // 下⼀个空闲对象偏移量，也就是静态链表的头部
};
typedef struct slub slub_t;


```



#### （2）内存分配

```c++
 static void *slub_alloc(size_t size)  
{  
    assert(size < PGSIZE);
    slub_t *prev, *cur;  
      
    // 根据请求的内存大小计算需要分配的内存块数量
    int num = SLUB_NUM(size);  
  
      
    prev = slubs_free;  
    // 遍历链表
    for (cur = prev->next; ; prev = cur, cur = cur->next) {  
        // 如果当前内存块的大小满足
        if (cur->num >= num) {  
            // 如果当前内存块的大小正好等于请求的大小，则将其从链表中移除
            if (cur->num == num)  
                prev->next = cur->next;  
            else {  
                // 如果当前内存块过大，则将其拆分为两部分：  一部分用于满足当前请求，另一部分放回空闲链表中
                prev->next = cur + num;  
                prev->next->num = cur->num - num;  
                prev->next->next = cur->next;  
                cur->num = num;  
            }  
            // 更新slubs_free指针，使其指向新的链表头
            slubs_free = prev;  
            return cur;  
        }  
        // 如果遍历到了链表的末尾，则从buddy系统分配新的页面
        if (cur == slubs_free) {  
            if (size == PGSIZE)  
                return 0;  
            // 从系统分配一个新的页面
            cur = (slub_t *)alloc_pages(1);  
            if (!cur)  
                return 0;  
                
            // 加入到空闲链表
            slub_free(cur, PGSIZE);  
            // 将cur设置为指向新的空闲链表头
            cur = slubs_free;  
        }  
    }  
}

void *kmem_cache_alloc(size_t size)  
{  
	slub_t *slub; 
	kmem_cache_t *cachep; 
  
	// 如果请求的大小小于一页大小减去SLUB管理信息所需的空间  
	if (size < PGSIZE - SLUB_SIZE) {  
		// 分配一个包含SLUB管理信息的块  
		slub = slub_alloc(size + SLUB_SIZE);  
		// 如果分配成功，返回用户数据部分的指针
		return slub ? (void *)(slub + 1) : 0;  
	}  
  
	// 对于较大的请求，分配一个kmem_cache结构来管理内存  
	cachep = slub_alloc(sizeof(kmem_cache_t));  
	// 如果分配失败，返回NULL  
	if (!cachep)  
		return 0;  
  
	// 计算需要分配的页面数（以2的幂次方表示）  
	cachep->order = ((size-1) >> PGSHIFT) + 1;  
	// 分配所需页面数的连续物理页面  
	cachep->slubs = (void *)alloc_pages(cachep->order);  
  
	// 如果页面分配成功  
	if (cachep->slubs) {  
		// 将新分配的kmem_cache结构加入全局缓存链表的头部  
		cachep->next = caches;  
		caches = cachep;  
		// 返回分配的内存区域的起始地址  
		return cachep->slubs;  
	}  
  
	// 如果页面分配失败，释放之前分配的kmem_cache结构  
	slub_free(cachep, sizeof(kmem_cache_t));  
	// 返回NULL表示分配失败  
	return 0;  
}
```


#### (3)内存释放

```c++
static void slub_free(void *object, int size)  
{  
	slub_t *cur, *obj = (slub_t *)object; // 定义当前遍历指针cur和待释放对象指针obj  
	if (!object) // 如果传入的对象指针为空，则直接返回  
		return;  
	if (size) // 如果传入了非零的大小，则设置obj的num字段为根据大小计算出的SLUB块数量  
		obj->num = SLUB_NUM(size);  
  
	// 遍历空闲SLUB块链表，寻找合适的位置插入待释放的obj  
	for (cur = slubs_free; !(obj > cur && obj < cur->next); cur = cur->next) {  
		// 如果链表出现错误（cur >= cur->next），或者obj在cur和cur->next之外，则跳出循环  
		if (cur >= cur->next && (obj > cur || obj < cur->next))  
			break;  
	}  
  
	// 如果待释放的obj与当前cur的下一个块相邻（且obj在cur之后）  
	if (obj + obj->num == cur->next) {  
		// 则合并这两个块，更新obj的num和next指针  
		obj->num += cur->next->num;  
		obj->next = cur->next->next;  
	} else { // 否则，不合并，只设置obj的next指针为cur的next  
		obj->next = cur->next;  
	}  
  
	// 如果待释放的obj与当前cur块相邻（且obj在cur之前紧挨着）  
	if (cur + cur->num == obj) {  
		// 则合并这两个块，更新cur的num和next指针  
		cur->num += obj->num;  
		cur->next = obj->next;  
	} else { // 否则，不合并，只将obj插入到cur之后  
		cur->next = obj;  
	}  
  
	slubs_free = cur; 
  
}  

void kmem_cache_free(void *slub)  
{  
	kmem_cache_t *cachep, **last = &caches; 
  
	if (!slub) 
		return;  
  
	// 检查传入的指针是否按页面对齐 
	if (!((unsigned long)slub & (PGSIZE-1))) {  
		// 遍历caches链表，查找包含待释放内存的cachep  
		for (cachep = caches; cachep; last = &cachep->next, cachep = cachep->next) {  
			if (cachep->slubs == slub) { // 如果找到匹配的cachep  
				*last = cachep->next; // 从链表中移除cachep  
				free_pages((struct Page *)slub, cachep->order); // 释放cachep管理的页面  
				slub_free(cachep, sizeof(kmem_cache_t)); // 释放cachep结构本身占用的内存  
				return;
			}  
		}  
	}  
  
	// 如果传入的指针不是按页面对齐的，则调用slub_free
	slub_free((slub_t *)slub - 1, 0); // 注意要减去1以找到正确的slub头  
	return; 
} 
```



### 3、slub的正确性证明

#### （1）验证函数

```c++
void slub_check()
{
    cprintf("\nslub check begin\n");
    
    cprintf("check begin————slubs_free_len: %d\n", slubs_free_len());
    
    void* p1, *p2, *p3,*p4;
    
    
    p1 = kmem_cache_alloc(4096);
    cprintf("p1 = kmem_cache_alloc(4096)————slubs_free_len: %d\n", slubs_free_len());
    
    p2 = kmem_cache_alloc(200);
    cprintf("p2 = kmem_cache_alloc(200)————slubs_free_len: %d\n", slubs_free_len());
    
    p3 = kmem_cache_alloc(2);
    cprintf("p3 = kmem_cache_alloc(2)————slubs_free_len: %d\n", slubs_free_len());
    
    p4 = kmem_cache_alloc(2);
    cprintf("p4 = kmem_cache_alloc(2)————slubs_free_len: %d\n", slubs_free_len());
    
    kmem_cache_free(p2);
    cprintf("kmem_cache_free(p2)————slubs_free_len: %d\n", slubs_free_len());
    
    kmem_cache_free(p3);
    cprintf("kmem_cache_free(p3)————slubs_free_len: %d\n", slubs_free_len());
    
    kmem_cache_free(p4);
    cprintf("kmem_cache_free(p4)————slubs_free_len: %d\n", slubs_free_len());
    
    
    cprintf("slub check end\n");
}
```

#### （2）正确性

输出结果如下图所示：

 <img src="图片2.png" alt="图片2"  />

开始时尚未分配，所以`slubs_free`长度为0。

第一次分配的size大于`PGSIZE - SLUB_SIZE`，会通过`buddy_system`分配一页，同时创建了一个`kmem_cache_t`项向slub申请内存，所以申请后`slubs_free`的长度增加。

后续三次分配，从原本的`kmem_cache_t`中取下一部分，所以长度不变。

释放p2/p3时，由于其与后一项中间隔了一个p4，无法合并，所以`slubs_free`的长度变成了2。

释放p4时会合并，最终变为1。



## Challenge3：硬件的可用物理内存范围的获取方法（思考题）
如果 OS 无法提前知道当前硬件的可用物理内存范围，请问你有何办法让OS获取可用物理内存范围？

**1.解析设备树**

在OpenSBI中，可以通过解析设备树来获得可用的内存范围。在设备启动过程中，OpenSBI固件完成对于包括物理内存在内的各外设的扫描，将扫描结果以DTB(Device Tree Blob)的格式保存在物理内存中。随后 OpenSBI 会将其地址保存在a1寄存器中，给我们使用。而设备树中包含了系统的硬件描述，其中包括内存区域。通过解析设备树中的memory节点，可以获得物理内存的起始地址和大小,reg属性定义了物理内存的基地址和大小。

**2.BIOS/UEFI 获取**

在系统启动时，OS可以通过读取BIOS或UEFI提供的内存映射表来获取硬件的物理内存布局。UEFI提供的EFI_MEMORY_DESCRIPTOR结构体可以描述每个内存区段的类型和大小，操作系统可以从这里提取到可用的物理内存范围。
