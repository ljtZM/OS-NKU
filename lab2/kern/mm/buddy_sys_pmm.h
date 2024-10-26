#ifndef __KERN_MM_BUDDY_SYS_PMM_H__
#define __KERN_MM_BUDDY_SYS_PMM_H__

#include <pmm.h>
//#include <stdint.h>
//#define MAX_ORDER 20

extern const struct pmm_manager buddy_pmm_manager;

typedef struct {
    unsigned int depth;                  // b_sys的二叉树深度
    list_entry_t free_block_lists[15];   // 空闲块链表数组（2^14 = 16384个可分配页）
    unsigned int free_blocks_count;      // 系统中剩余的空闲内存块总数
} buddy_system_free_t;

#endif /* ! __KERN_MM_BUDDY_PMM_H__ */
