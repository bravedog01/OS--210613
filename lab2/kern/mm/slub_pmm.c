#include <defs.h>
#include <list.h>
#include <memlayout.h>
#include <assert.h>
#include <slub_pmm.h>
#include <pmm.h>
#include <stdio.h>

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


#define SLUB_SIZE sizeof(slub_t)
#define SLUB_NUM(size) (((size) + SLUB_SIZE - 1)/SLUB_SIZE)
static slub_t slub1st = { .next = &slub1st, .num = 1 };
static slub_t *slubs_free = &slub1st;
static kmem_cache_t *caches;
static void slub_free(void *object, int size);

void slub_init(void) {
    cprintf("slub_init() succeeded!\n");
}

int slubs_free_len()
{
    int len = 0;
    for(slub_t* curr = slubs_free->next; curr != slubs_free; curr = curr->next)
        len ++;
    return len;
}


// 从SLUB中分配内存
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

// 释放由SLUB分配器分配的内存  
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
  
// 获取由kmem_cache_alloc分配的内存块的大小  
unsigned int kmem_cache_size(const void *slub)  
{  
	kmem_cache_t *cachep; 
  
	if (!slub) 
		return 0;  
  
	// 检查传入的指针是否按页面对齐
	if (!((unsigned long)slub & (PGSIZE-1))) {  
		// 遍历caches链表，查找包含待查询内存的cachep  
		for (cachep = caches; cachep; cachep = cachep->next)  
			if (cachep->slubs == slub) { // 如果找到匹配的cachep  
				return cachep->order << PGSHIFT; // 返回cachep管理的页面大小（以字节为单位）  
			}  
	}  
  
	// 如果传入的指针不是按页面对齐的
	return ((slub_t *)slub - 1)->num * SLUB_SIZE; // 返回小内存块的大小
}


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

