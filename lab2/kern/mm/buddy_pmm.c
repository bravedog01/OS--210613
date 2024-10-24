#include <pmm.h>
#include <list.h>
#include <string.h>
#include <buddy_pmm.h>
#include <stdio.h>
#include <assert.h>


//extern free_area_t free_area;
#define Max_Order 16
//#define free_list (free_area.free_list)
//#define nr_free (free_area.nr_free)

void print_buddy();


unsigned int round_up(size_t x) {
    if (x <= 1) return 0;
    unsigned int power = 1;
    unsigned int exponent = 0;
    while (power < x) {
        power <<= 1; // 左移相当于乘以2
        exponent++;
    }
    return exponent;
}

unsigned int round_down(size_t x) {
    if (x <= 1) return 0;
    unsigned int power = 1;
    unsigned int exponent = 0;
    while (power <= x) {
        power <<= 1;
        exponent++;
    }
    return exponent - 1; // 因为超出了1次所以减1
}

typedef struct {
    list_entry_t free_list[Max_Order + 1];
    unsigned int nr_free[Max_Order + 1];
} BuddySystem;

BuddySystem buddy;
#define free_list (buddy.free_list)
#define nr_free (buddy.nr_free)

/* 打印buddy链表结构 */
static void show_buddy_array(void) {
    cprintf("[!] Buddy array status:\n");
    for (int i = 0; i <= Max_Order; i++) {
        cprintf("%d layer: ", i);
        list_entry_t *le = &free_list [i];
        while ((le = list_next(le)) != &free_list [i]) {
            struct Page *p = le2page(le, page_link);
            cprintf("%d ", 1 << p->property);
        }
        cprintf("\n");
    }
    cprintf("---------------------------\n");
}
// 初始化空闲块链表
static void buddy_init(void) {
     for (int i = 0; i < Max_Order; i++) {
        list_init(&free_list[i]);
        nr_free[i] = 0;
    }
}



static void buddy_init_memmap(struct Page *base, size_t n) {
  uintptr_t begin_addr = page2pa(base);//获取首地址 page转换地址
  //核心：将非2次幂的数据划分成小块的2的次幂
  cprintf("构建buddy_system前:\n");
  print_buddy();
  //show_buddy_array();
  while(n){
    
    int order=0;
    size_t order_size;//每一个order有多少页
   // cprintf("1\n");
    //获取该page大小的order
    order=round_down(n);
    cprintf("order:%d\n",order);
    order_size=1u<<order;
    //设置page属性
  //  cprintf("2\n");
    struct Page* p = pa2page(begin_addr);//设置起始地址
    p->property = order;//
    SetPageProperty(p);
   //加入链表
  //cprintf("3\n");
   cprintf("Adding page at %p to free_list[%d]\n", p, order);
   list_add(&free_list[order],&p->page_link);//这里的free——list编号从下到上编号 8页对应3
   nr_free[order]++;
   //更新n和开始地址
  // cprintf("4\n");
   begin_addr+=order_size*PGSIZE;
   n-=order_size;
   //cprintf("5\n");
  }
  cprintf("构建buddy_system后:\n");
  print_buddy();
  // show_buddy_array();
}



 
 static struct Page *buddy_alloc_pages(size_t n) {
    size_t need_order = round_up(n); // 向上取整，得到需要的order

     cprintf("所要分配大小：%d\n",n);
  cprintf("预计分配大小：%d\n",need_order);
    // 找到适合的空闲块
    for (size_t order = need_order; order <= Max_Order; order++) {
      cprintf("order：%d\n",order);
        if (nr_free[order] > 0) {
            // 如果找到了合适的空闲块，进行分配
            list_entry_t *le = list_next(&free_list[order]);
            list_del(le);
            nr_free[order]--;

            struct Page *allocated_page = le2page(le, page_link); //这里的page_link指的是啥呀
            allocated_page->property = order; // 设置属性
             
            SetPageProperty(allocated_page);

            // 如果找到的块比需要的块大，进行切割
            while (order > need_order) {
               //cprintf("成功切割！");
                order--; // 将order减小，准备切割
                struct Page *remaining_page = allocated_page + (1 << order); // 计算剩余页面数量

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
           // show_buddy_array();
           cprintf("allocated_page; order：%d\n",allocated_page->property);
            return allocated_page; // 返回分配的页面
        }
    }
    cprintf("No block!\n");
    return NULL; // 没有找到合适的块
}



// 释放 n 个页，尝试合并相邻的 buddy 块
static void buddy_free_pages(struct Page *base, size_t n) {
    size_t order = base->property;  // 获取当前块的 order
    uintptr_t base_addr = page2pa(base);  // 获取当前块的物理地址
    struct Page *buddy_page = NULL;  // 伙伴页
    cprintf("所要合并大小：%d\n",n);
    cprintf("合并地址为：%x\n",base_addr);
    cprintf("base order：%d\n",order);
    while (order <= Max_Order) {
        // 计算左侧和右侧伙伴地址
        uintptr_t left_buddy_addr = base_addr - (1 << order);
        uintptr_t right_buddy_addr = base_addr + (1 << order);
        
        cprintf("left_buddy_addr：%x\n",left_buddy_addr);
        cprintf("right_buddy_addr：%x\n",right_buddy_addr);
        
        struct Page *left_buddy_page = pa2page(left_buddy_addr);
        struct Page *right_buddy_page = pa2page(right_buddy_addr);
        
        cprintf("left_buddy_page->property :%d\n",left_buddy_page->property );
        cprintf("PageProperty(left_buddy_page):%d\n",PageProperty(left_buddy_page));
         cprintf("right_buddy_page->property :%d\n",right_buddy_page->property );
        cprintf("PageProperty(right_buddy_page):%d\n",  PageProperty(right_buddy_page));
        int merged = 0;  // 标记是否发生了合并

        // 优先考虑合并左侧伙伴  
        if ( left_buddy_addr >= 0x80200000 && // 确保左侧伙伴在有效内存范围内
            left_buddy_page->property == order && 
           // !PageReserved(left_buddy_page)&&
            PageProperty(left_buddy_page)&&//该页是否自由
            nr_free[order]) {
            cprintf("左侧伙伴块order:%d",left_buddy_page->property );
            // 左侧伙伴块可合并
            list_del(&left_buddy_page->page_link);
            nr_free[order]--;
            base = left_buddy_page;  // 合并后，base 指向较小地址的块
            base_addr = left_buddy_addr;
            merged = 1;
            cprintf("合并左边，首地址为：%d\n",base_addr);  
        }
        // 如果左侧伙伴不可合并，尝试合并右侧伙伴   
        else if ( right_buddy_addr < 0x88000000 && // 确保右侧伙伴在有效内存范围内
                 right_buddy_page->property == order && 
               //  !PageReserved(right_buddy_page)&&
                  PageProperty(right_buddy_page)&&
                  nr_free[order]) {
            cprintf("右侧伙伴块order:%d",left_buddy_page->property );
            // 右侧伙伴块可合并
            list_del(&right_buddy_page->page_link);
            nr_free[order]--;
            // base 不变，仍指向当前块（较小地址的块）
            merged = 1;
            cprintf("合并右边，首地址为：%d\n",base_addr);
        }

        // 如果发生了合并，增加块的 order，继续递归检查合并后的块
        if (merged) {
            base->property++;
            order = base->property;
        } else {
            // 无法再合并，跳出循环
            break;
        }
    }

    // 合并完成后，将块加入对应 order 的 free_list
    SetPageProperty(base);
    list_add(&free_list[base->property], &base->page_link);
    nr_free[base->property]++;
    
    cprintf("buddy_system:\n");
    print_buddy();
     //show_buddy_array();
}



// 获取空闲页数量
static size_t buddy_nr_free_pages(void) {
    size_t total_free = 0;
    for (size_t i = 0; i <= Max_Order; i++) {
        total_free += nr_free[i];
    }
    return total_free;
}

/*
// 检查 buddy system
static void buddy_check(void) {
    cprintf("Buddy system initialized.\n");
    struct Page *p0, *p1, *p2;

    p0 = buddy_alloc_pages(1);
    if(p0 != NULL) {
        cprintf("p0 allocated successfully.\n");
    } else {
        cprintf("p0 allocation failed.\n");
    }
    assert(p0 != NULL);
    
    p1 = buddy_alloc_pages(2);
    if(p1 != NULL) {
        cprintf("p1 allocated 2 pages successfully.\n");
    } else {
        cprintf("p1 allocation of 2 pages failed.\n");
    }
    if(1){getchar();}
    assert(p1 != NULL);

    p2 = buddy_alloc_pages(3);
    if(p2 != NULL) {
        cprintf("p2 allocated 3 pages successfully.\n");
    } else {
        cprintf("p2 allocation of 3 pages failed.\n");
    }
    assert(p2 != NULL);
    
    buddy_free_pages(p0, 1);
    cprintf("p0 freed.\n");

    buddy_free_pages(p1, 2);
    cprintf("p1's 2 pages freed.\n");

    p1 = buddy_alloc_pages(3);
    if(p1 != NULL) {
        cprintf("p1 allocated 3 pages successfully after previous free.\n");
    } else {
        cprintf("p1 allocation of 3 pages failed after previous free.\n");
    }
    //assert(p1 != NULL);
    
    buddy_free_pages(p1, 3);
    cprintf("p1's 3 pages freed.\n");

    buddy_free_pages(p2, 3);
    cprintf("p2's 3 pages freed.\n");

    size_t free_pages = buddy_nr_free_pages();
    cprintf("Total free pages: %zu\n", free_pages);
    //assert(free_pages == 9);
}*/
/* 基础检查函数 */
static void basic_check(void) {
    struct Page *p0, *p1, *p2;
    assert((p0 = alloc_pages(1)) && (p1 = alloc_pages(3)) && (p2 = alloc_pages(5)));
    free_pages(p0,1);
    free_pages(p2,5);
  //  show_buddy_array();

    assert((p0 = alloc_pages(4)) && (p2 = alloc_pages(3)));
    free_pages(p0, 4);
    free_pages(p1, 3);
  //  show_buddy_array();

    assert((p0 = alloc_pages(9)));
    free_pages(p0, 9);
    free_pages(p2, 3);
   // show_buddy_array();
}

/* 完整检查函数 */
static void buddy_check(void) {
    basic_check();
}


const struct pmm_manager buddy_pmm_manager = {
//函数指针绑定buddy中函数
    .name = "buddy_pmm_manager",
    .init = buddy_init,
    .init_memmap = buddy_init_memmap,
    .alloc_pages = buddy_alloc_pages,
    .free_pages = buddy_free_pages,
    .nr_free_pages = buddy_nr_free_pages,
    .check = buddy_check,
};


void print_buddy(){
    for (int i = 0; i <= Max_Order; i++) {
                cprintf("Order %d: %d free blocks\n", i, nr_free[i]);
            }
}
