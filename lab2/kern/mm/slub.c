#include <defs.h>
#include <list.h>
#include <memlayout.h>
#include <assert.h>
#include <slub.h>
#include <pmm.h>
#include <stdio.h>

typedef struct small_block {
    int size_units; // 块的大小，以单位表示
    struct small_block *next; // 下一个空闲块
} small_block_t;

#define SMALL_UNIT sizeof(small_block_t)
#define SIZE_TO_UNITS(size) (((size) + SMALL_UNIT - 1) / SMALL_UNIT)

typedef struct big_block {
    int order; // 内存页的数量
    void *pages; // 指向实际内存的指针
    struct big_block *next; // 下一个大块的指针
} big_block_t;

static small_block_t arena = { .next = &arena, .size_units = 1 };
static small_block_t *free_list_head = &arena; // 空闲链表的头
static big_block_t *big_block_list; // 大块内存链表

static void free_small_block(void *block, int size);

static void *allocate_small_block(size_t size) {
    assert(size < PGSIZE); // 确保请求的大小小于页面大小

    small_block_t *prev = free_list_head;
    small_block_t *curr;

    int required_units = SIZE_TO_UNITS(size); // 计算所需的单位数

    cprintf("Required units: %d\n", required_units);

    // 使用一个指向当前块的指针进行遍历
    for (curr = prev->next; ; prev = curr, curr = curr->next) {
        cprintf("Current block size: %d\n", curr->size_units);
        
        // 检查是否找到足够大的块
        if (curr->size_units >= required_units) {
            if (curr->size_units == required_units) {
                prev->next = curr->next; // 完全匹配，移除当前块
                cprintf("Allocated a perfect match!\n");
            } else {
                // 更新当前块为所需大小，更新剩余块信息
                prev->next = (small_block_t *)((char *)curr + required_units * SMALL_UNIT);

                prev->next->size_units = curr->size_units - required_units;
                prev->next->next = curr->next;
                curr->size_units = required_units; // 更新当前块大小
                cprintf("Allocated smaller block, cutting!\n");
            }
            free_list_head = prev; // 更新空闲链表头
            return curr; // 返回分配的内存块
        }

        // 如果没有足够的块，尝试分配新页面
        if (curr->next == free_list_head) { // 遍历回到链表头
            if (size == PGSIZE) return NULL; // 如果请求的大小为页面大小，返回 NULL
            
            // 分配一个新页面
            curr = (small_block_t *)alloc_pages(1); 
            if (!curr) return NULL; // 分配失败
            
            free_small_block(curr, PGSIZE); // 初始化新页面
            curr = free_list_head; // 更新当前块
        }
    }
}


static void free_small_block(void *block, int size) {
    small_block_t *current;
    small_block_t *block_to_free = (small_block_t *)block;
    if (!block) return;
    if (size) block_to_free->size_units = SIZE_TO_UNITS(size); // 设置块的大小

    // 查找插入点
    for (current = free_list_head; !(block_to_free > current && block_to_free < current->next); current = current->next) {
        if (current >= current->next && (block_to_free > current || block_to_free < current->next)) {
            break;
        }
    }

    // 合并相邻的空闲块
    if ((char *)block_to_free + block_to_free->size_units * SMALL_UNIT == (char *)current->next) {
        block_to_free->size_units += current->next->size_units; // 合并
        block_to_free->next = current->next->next;
        cprintf("Merge successful! Free list length will decrease by 1.\n");
    } else {
        block_to_free->next = current->next;
        cprintf("No merge, inserting into the list.\n");
    }

    if ((char *)current + current->size_units * SMALL_UNIT == (char *)block_to_free) {
        current->size_units += block_to_free->size_units; // 合并
        current->next = block_to_free->next;
        cprintf("Merge successful with previous block! Free list length will decrease by 1.\n");
    } else {
        current->next = block_to_free; // 插入到当前块后
        cprintf("Inserted block without merging.\n");
    }

    free_list_head = current; // 更新空闲链表头
}

void slub_init(void) {
    cprintf("slub_init() succeeded!\n");
}

void *slub_alloc(size_t size) {
    if (size < PGSIZE - SMALL_UNIT) {
        small_block_t *m = allocate_small_block(size + SMALL_UNIT); // 小块分配
        return m ? (void *)(m + 1) : NULL;
    }

    // 大块分配
    big_block_t *big_block = allocate_small_block(sizeof(big_block_t));
    if (!big_block) return NULL;

    big_block->order = ((size - 1) >> PGSHIFT) + 1; // 计算所需页面数量
    big_block->pages = alloc_pages(big_block->order);

    if (big_block->pages) {
        big_block->next = big_block_list;
        big_block_list = big_block;
        return big_block->pages;
    }

    free_small_block(big_block, sizeof(big_block_t)); // 释放失败的块
    return NULL;
}

void slub_free(void *block) {
    if (!block) return;

    

    free_small_block((small_block_t *)block - 1, 0); // 释放小块
}

unsigned int slub_size(const void *block) {
    if (!block) return 0;

    big_block_t *bb;
    if (!((uintptr_t)block & (PGSIZE - 1))) {
        for (bb = big_block_list; bb; bb = bb->next) {
            if (bb->pages == block) {
                return bb->order << PGSHIFT; // 返回大块大小
            }
        }
    }

    return ((small_block_t *)block - 1)->size_units * SMALL_UNIT; // 返回小块大小
}

int get_free_list_length() {
    int length = 0;
    for (small_block_t *curr = free_list_head->next; curr != free_list_head; curr = curr->next) {
        length++;
    }
    return length;
}

void slub_test() {
    cprintf("SLUB Test Begin\n");
    cprintf("Initial Free list length: %d\n", get_free_list_length());

    // 测试小块分配
    void *block1 = slub_alloc(2);
    cprintf("Allocated block1");
    cprintf("Free list length after allocating block1: %d\n", get_free_list_length());

    // 测试小块释放
    slub_free(block1);
    cprintf("Freed block1\n");
    cprintf("Free list length after freeing block1: %d\n", get_free_list_length());

    // 测试释放后合并
    void *block2 = slub_alloc(2);
    cprintf("Allocated block2");
    cprintf("Free list length after allocating block2: %d\n", get_free_list_length());
    void *block3 = slub_alloc(2);
    cprintf("Allocated block3");
    cprintf("Free list length after allocating block3: %d\n", get_free_list_length());
    void *block4 = slub_alloc(256);
    cprintf("Allocated block4");
    cprintf("Free list length after allocating block4: %d\n", get_free_list_length());
    
    
    slub_free(block3);
    cprintf("Freed block3\n");
    cprintf("Free list length after freeing block3: %d\n", get_free_list_length());
    slub_free(block2);
    slub_free(block4);
    cprintf("Freed block4\n");
    cprintf("Free list length after freeing block2&4: %d\n", get_free_list_length());

    cprintf("SLUB Test End\n");
   
}


