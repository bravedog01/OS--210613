#include <pmm.h> 
#include <list.h>
#include <string.h>
#include <buddy.h>
#include <error.h>
#include <sbi.h>
#include <stdio.h>
#include <riscv.h>

#define buddy_array (buddy_s.free_array)
#define max_order (buddy_s.max_order)
#define nr_free (buddy_s.nr_free)
#define is_power_of_2(n) (n & (n - 1)) == 0

free_buddy_t buddy_s; // 全局buddy结构体实例

static inline get_order_of_2(size_t n) {
unsigned int order = 0;
while (n >>= 1) order++;
return order;
}

/* 获取数值n对应的2的幂次 */
static inline unsigned int get_order_of_2(size_t n) {
    unsigned int order = 0;
    while (n >>= 1) order++;
    return order;
}

/* 将数值n向下取整为2的幂 */
static size_t round_down_to_2(size_t n) {
    if (is_power_of_2(n)) return n;
    size_t res = 1;
    while (n >>= 1) res <<= 1;
    return res;
}

/* 将数值n向上取整为2的幂 */
static size_t round_up_to_2(size_t n) {
    if (is_power_of_2(n)) return n;
    size_t res = 1;
    while (n >>= 1) res <<= 1;
    return res << 1;
}

/* 打印buddy链表结构 */
static void show_buddy_array(void) {
    cprintf("[!] Buddy array status:\n");
    for (int i = 0; i <= max_order; i++) {
        cprintf("%d layer: ", i);
        list_entry_t *le = &buddy_array[i];
        while ((le = list_next(le)) != &buddy_array[i]) {
            struct Page *p = le2page(le, page_link);
            cprintf("%d ", 1 << p->property);
        }
        cprintf("\n");
    }
    cprintf("---------------------------\n");
}

/* 初始化buddy系统 */
static void buddy_init(void) {
    for (int i = 0; i < MAX_BUDDY_ORDER; i++) {
        list_init(&buddy_array[i]);
    }
    max_order = 0;
    nr_free = 0;
}

/* 获取页块的伙伴块 */
static struct Page* buddy_get_buddy(struct Page *page) {
    unsigned int order = page->property;
    unsigned int buddy_ppn = first_ppn + ((1 << order) ^ (page2ppn(page) - first_ppn));
    cprintf("[!] Page NO.%d's buddy page (order %d) is: %d\n", page2ppn(page), order, buddy_ppn);
    return (buddy_ppn > page2ppn(page)) ? page + (buddy_ppn - page2ppn(page)) : page - (page2ppn(page) - buddy_ppn);
}

/* 初始化物理页块 */
static void buddy_init_memmap(struct Page *base, size_t n) {
    assert(n > 0);
    size_t pnum = round_down_to_2(n); // 向下取整为2的幂
    unsigned int order = get_order_of_2(pnum); // 获取对应的幂次
    cprintf("[!] Available Page num (rounded down): %d = 2^%d\n", pnum, order);

    // 初始化指定范围内的页块
    struct Page *p = base;
    for (; p != base + pnum; p++) {
        assert(PageReserved(p));
        p->flags = 0;
        p->property = -1; // 非头页
        set_page_ref(p, 0);
    }

    max_order = order;
    nr_free = pnum;
    list_add(&buddy_array[max_order], &base->page_link); // 将头页加入到对应的链表中
    base->property = max_order; // 设为最大块的头页
}

/* 分裂较大的块 */
static void buddy_split(size_t n) {
    assert(n > 0 && n <= max_order);
    assert(!list_empty(&buddy_array[n]));
    cprintf("[!] Splitting block...\n");

    struct Page *page_a = le2page(list_next(&buddy_array[n]), page_link);
    struct Page *page_b = page_a + (1 << (n - 1)); // 分裂

    page_a->property = n - 1;
    page_b->property = n - 1;

    list_del(list_next(&buddy_array[n]));
    list_add(&buddy_array[n-1], &page_a->page_link);
    list_add(&buddy_array[n-1], &page_b->page_link);
}

/* 分配n页大小的块 */
static struct Page* buddy_alloc_pages(size_t n) {
    assert(n > 0);
    if (n > nr_free) return NULL;

    size_t pnum = round_up_to_2(n); // 向上取整
    unsigned int order = get_order_of_2(pnum);

    cprintf("[!] Allocating %d pages (rounded to %d = 2^%d)\n", n, pnum, order);
    show_buddy_array();

find_block:
    if (!list_empty(&buddy_array[order])) {
        struct Page *page = le2page(list_next(&buddy_array[order]), page_link);
        list_del(list_next(&buddy_array[order]));
        SetPageProperty(page); // 标记已分配
        nr_free -= pnum;
        cprintf("[!] Allocated page NO.%d\n", page2ppn(page));
        show_buddy_array();
        return page;
    }

    // 找到更大块并进行分裂
    for (int i = order; i <= max_order; i++) {
        if (!list_empty(&buddy_array[i])) {
            buddy_split(i);
            goto find_block;
        }
    }

    return NULL;
}

/* 释放指定大小的块 */
static void buddy_free_pages(struct Page *base, size_t n) {
    assert(n > 0);
    unsigned int pnum = 1 << base->property;
    assert(round_up_to_2(n) == pnum);

    cprintf("[!] Freeing page NO.%d leading %d pages\n", page2ppn(base), pnum);
    struct Page *buddy = buddy_get_buddy(base);

    list_add(&buddy_array[base->property], &base->page_link);
    show_buddy_array();

    // 合并空闲块
    while (!PageProperty(buddy) && base->property < max_order) {
        if (base > buddy) {
            struct Page *tmp = base;
            base = buddy;
            buddy = tmp;
        }
        list_del(&base->page_link);
        list_del(&buddy->page_link);
        base->property++;
        list_add(&buddy_array[base->property], &base->page_link);
        show_buddy_array();
        buddy = buddy_get_buddy(base);
    }

    ClearPageProperty(base); // 标记为空闲
    nr_free += pnum;
    show_buddy_array();
}

/* 获取空闲页数 */
static size_t buddy_nr_free_pages(void) {
    return nr_free;
}

/* 基础检查函数 */
static void basic_check(void) {
    struct Page *p0, *p1, *p2;
    assert((p0 = alloc_pages(1)) && (p1 = alloc_pages(3)) && (p2 = alloc_pages(5)));
    free_pages(p0,1);
    free_pages(p2,5);
    show_buddy_array();

    assert((p0 = alloc_pages(4)) && (p2 = alloc_pages(3)));
    free_pages(p0, 4);
    free_pages(p1, 3);
    show_buddy_array();

    assert((p0 = alloc_pages(9)));
    free_pages(p0, 9);
    free_pages(p2, 3);
    show_buddy_array();
}

/* 完整检查函数 */
static void buddy_check(void) {
    basic_check();
}
const struct pmm_manager buddy_pmm_manager = {
    .name = "buddy_pmm_manager",
    .init = buddy_init,
    .init_memmap = buddy_init_memmap,
    .alloc_pages = buddy_alloc_pages,
    .free_pages = buddy_free_pages,
    .nr_free_pages = buddy_nr_free_pages,
    .check = buddy_check,
};
