#ifndef __KERN_MM_SLUB_PMM_H__
#define __KERN_MM_SLUB_PMM_H__

//#include <defs.h>
#include <pmm.h>

extern const struct pmm_manager slub_pmm_manager;

void slub_init(void);

void *kmem_cache_alloc(size_t size);
void kmem_cache_free(void *objp);
void slub_check();

#endif /* !__KERN_MM_SLUB_MM_H__ */
