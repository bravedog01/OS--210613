#include <defs.h>
#include <riscv.h>
#include <stdio.h>
#include <string.h>
#include <swap.h>
#include <swap_lru.h>
#include <list.h>

/*最久未使用(least recently used, LRU)算法：
    利用局部性，通过过去的访问情况预测未来的访问情况，我们可以认为最近还被访问过的页面将来被访问的可能性大，
    而很久没访问过的页面将来不太可能被访问。于是我们比较当前内存里的页面最近一次被访问的时间，
    把上一次访问时间离现在最久的页面置换出去。 */
/*增加一个check函数维护每个页表的访问次数，维护周期为发生page fault；
  每次check都会找到最少访问的page 为least_visited_page*/
extern list_entry_t pra_list_head;
static int _lru_check(struct mm_struct *mm);
static struct Page  *least_visited_page;
static int
_lru_init_mm(struct mm_struct *mm)
{     
     list_init(&pra_list_head);
     mm->sm_priv = &pra_list_head;
     //cprintf(" mm->sm_priv %x in lru_init_mm\n",mm->sm_priv);
     return 0;
}

static int
_lru_map_swappable(struct mm_struct *mm, uintptr_t addr, struct Page *page, int swap_in)
{
    _lru_check(mm);
     list_entry_t *head=(list_entry_t*) mm->sm_priv;
    list_entry_t *entry=&(page->pra_page_link);
 
    assert(entry != NULL && head != NULL);
    page->visited=0;
    list_add(head, entry);
    return 0;
}

static int
_lru_swap_out_victim(struct mm_struct *mm, struct Page ** ptr_page, int in_tick)
{
    _lru_check(mm);
     list_entry_t *head=(list_entry_t*) mm->sm_priv;
        assert(head != NULL);
     assert(in_tick==0);
     list_entry_t *least_page_link=&(least_visited_page->pra_page_link);
    if (least_page_link!= head) {
        list_del(least_page_link);
        *ptr_page =least_visited_page;
    } else {
        *ptr_page = NULL;
    }
    return 0;
}


static int 
_lru_check_swap(void) {
    *(unsigned char *)0x3000 = 0x0c;
    assert(pgfault_num==4);
    *(unsigned char *)0x1000 = 0x0a;
    assert(pgfault_num==4);
   /* *(unsigned char *)0x2000 = 0x0b;
    assert(pgfault_num==4);*/
    *(unsigned char *)0x5000 = 0x0e;
    assert(pgfault_num==5);
     *(unsigned char *)0x4000 = 0x0d;
    assert(pgfault_num==5);
     *(unsigned char *)0x3000 = 0x0c;
    assert(pgfault_num==5);
    *(unsigned char *)0x2000 = 0x0b;
    assert(pgfault_num==6);
  /*  *(unsigned char *)0x1000 = 0x0a;
    assert(pgfault_num==7);
    *(unsigned char *)0x2000 = 0x0b;
    assert(pgfault_num==5);
    *(unsigned char *)0x3000 = 0x0c;
    assert(pgfault_num==5);
    *(unsigned char *)0x4000 = 0x0d;
    assert(pgfault_num==5);
    *(unsigned char *)0x5000 = 0x0e;
    assert(pgfault_num==5);
    assert(*(unsigned char *)0x1000 == 0x0a);
    *(unsigned char *)0x1000 = 0x0a;
    assert(pgfault_num==6);
*/
    return 0;
}




static int
_lru_init(void)
{
    return 0;
}

static int
_lru_set_unswappable(struct mm_struct *mm, uintptr_t addr)
{
    return 0;
}

static int
_lru_tick_event(struct mm_struct *mm)
{ return 0; }


struct swap_manager swap_manager_lru=
{
     .name            = "lru swap manager",
     .init            = &_lru_init,
     .init_mm         = &_lru_init_mm,
     .tick_event      = &_lru_tick_event,
     .map_swappable   = &_lru_map_swappable,
     .set_unswappable = &_lru_set_unswappable,
     .swap_out_victim = &_lru_swap_out_victim,
     .check_swap      = &_lru_check_swap,
};

static int _lru_check(struct mm_struct *mm)
{
    list_entry_t *head = (list_entry_t *)mm->sm_priv;   //头指针
    assert(head != NULL);
    list_entry_t *entry = head;
    struct Page *first_page = le2page(entry, pra_page_link);
    least_visited_page=first_page;
    while ((entry = list_prev(entry)) != head)
    {
        struct Page *entry_page = le2page(entry, pra_page_link);
        pte_t *tmp_pte = get_pte(mm->pgdir, entry_page->pra_vaddr, 0);
        cprintf("the ppn value of the pte of the vaddress is: 0x%x  \n", (*tmp_pte) >> 10);
        if (*tmp_pte & PTE_A)  //如果近期被访问过，visited++
        {
            entry_page->visited ++;
            *tmp_pte = *tmp_pte ^ PTE_A;//清除访问位
        }

        if(entry_page->visited<least_visited_page->visited){
            least_visited_page=entry_page;
        }
       
        cprintf("the visited goes to %d\n", entry_page->visited);
    }
}
