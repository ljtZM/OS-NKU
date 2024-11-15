//杨峥芃2211819 设计buddysys.c
#include <buddy_sys_pmm.h>
#include <list.h>
#include <string.h>
#include <pmm.h>
#include <stdio.h>

buddy_system_free_t free_buddy; // 定义一个 `buddy_system_free_t` 类型的结构体实例，用于管理伙伴系统的空闲内存块

#define free_block_lists (free_buddy.free_block_lists) // 访问 `free_buddy` 中的 `free_block_lists` 数组
#define depth (free_buddy.depth) // 访问 `free_buddy` 中的 `depth` 表示二叉树深度
#define free_blocks_count (free_buddy.free_blocks_count) // 访问 `free_buddy` 中的 `free_blocks_count` 表示空闲块的总数
extern ppn_t fppn; // 定义起始物理页号 `fppn`，用作物理页分配的基准

// 判断x是否为2的幂
#define IS_POWER_OF_2(n) (!((n) & ((n) - 1)))

// 获取 n 向下的 2 的幂次
static uint32_t GET_POWER_OF_2(size_t n) {
    uint32_t power = 0;
    while (n >> 1) { // 当 `n` 右移一位时不为0
        n >>= 1;
        power++; // 每次右移表示 `power` 加1
    }
    return power; // 返回 2 的幂次值
}

// 获取指定页面的伙伴块
static struct Page* GET_BUDDY(struct Page *page) {
    uint32_t power = page->property; // 获取页面的 `property`（当前块的 2 的幂次）
    size_t ppn = fppn + ((1 << power) ^ (page2ppn(page) - fppn)); // 计算伙伴块的物理页号，使用异或
    return page + (ppn - page2ppn(page)); // 根据 `ppn` 返回伙伴块页面地址
}

// 初始化空闲链表数组
static void buddy_initialize(void) {
    for (int i = 0; i < 15; i++) { // 初始化 0~14 层
        list_init(free_block_lists + i); // 对 `free_block_lists` 中的每一层进行初始化
    }
    depth = 0; // 初始深度设为 0
    free_blocks_count = 0; // 初始空闲块总数设为 0
    return;
}

// 初始化物理页
static void buddy_initialize_memory(struct Page *base, size_t real_n) {
    assert(real_n > 0); // 确保 `real_n` 大于 0
    struct Page *p = base;
    depth = GET_POWER_OF_2(real_n); // 设置二叉树深度
    size_t n = 1 << depth; // 根据深度计算出可用页面总数
    free_blocks_count = n; // 初始化空闲块总数
    for (; p != base + n; p += 1) { // 遍历每个物理页
        assert(PageReserved(p)); // 确保每个页面保留
        p->flags = 0; // 将页面标记为空闲
        p->property = 0; // 设置页面大小为2^0 = 1
        set_page_ref(p, 0); // 设置页面引用计数为 0
    }
    list_add(&(free_block_lists[depth]), &(base->page_link)); // 将整个空闲块加入到对应层的空闲链表
    base->property = depth; // 设置页面的属性为深度
    return;
}

// 分配一个内存块
static struct Page * allocate_buddy_pages(size_t real_n) {
    assert(real_n > 0); // 确保请求的块大小大于 0
    if (real_n > free_blocks_count) return NULL; // 若请求大小大于可用空闲块，返回 NULL
    struct Page *page = NULL;
    depth = IS_POWER_OF_2(real_n) ? GET_POWER_OF_2(real_n) : GET_POWER_OF_2(real_n) + 1; // 计算分配块的深度
    size_t n = 1 << depth; // 计算所需的页面数

    while (1) {
        if (!list_empty(&(free_block_lists[depth]))) { // 当前层有空闲块
            page = le2page(list_next(&(free_block_lists[depth])), page_link); // 获取空闲块页面
            list_del(list_next(&(free_block_lists[depth]))); // 将该空闲块从链表中删除
            SetPageProperty(page); // 设置页面为已用
            free_blocks_count -= n; // 更新空闲块数量
            break;
        }
        for (int i = depth; i < 15; i++) { // 否则从更高层分割空闲块
            if (!list_empty(&(free_block_lists[i]))) { // 检查高层是否有空闲块
                struct Page *page1 = le2page(list_next(&(free_block_lists[i])), page_link);
                struct Page *page2 = page1 + (1 << (i - 1)); // 分割出两个块
                page1->property = i - 1; // 更新分块后的属性
                page2->property = i - 1;
                list_del(list_next(&(free_block_lists[i]))); // 删除原块
                list_add(&(free_block_lists[i - 1]), &(page2->page_link)); // 添加分割后的两个块
                list_add(&(free_block_lists[i - 1]), &(page1->page_link));
                break;
            }
        }
    }
    return page; // 返回分配的内存块
}

// 释放内存块
static void release_buddy_pages(struct Page *base, size_t n) {
    assert(n > 0); // 确保释放的块大小大于 0
    free_blocks_count += 1 << base->property; // 更新空闲块总数
    struct Page *free_page = base;
    struct Page *free_page_buddy = GET_BUDDY(free_page); // 获取伙伴块
    list_add(&(free_block_lists[free_page->property]), &(free_page->page_link)); // 将块加入空闲链表

    while (!PageProperty(free_page_buddy) && free_page->property < 14) { // 当伙伴块未使用且深度<14
        if (free_page_buddy < free_page) { // 如果释放块在右边，交换
            struct Page *temp;
            free_page->property = 0;
            ClearPageProperty(free_page);
            temp = free_page;
            free_page = free_page_buddy;
            free_page_buddy = temp;
        }
        list_del(&(free_page->page_link)); // 从链表中移除块
        list_del(&(free_page_buddy->page_link));
        free_page->property += 1; // 合并后属性增加
        list_add(&(free_block_lists[free_page->property]), &(free_page->page_link)); // 将合并后的块加入空闲链表
        free_page_buddy = GET_BUDDY(free_page); // 更新伙伴块
    }
    ClearPageProperty(free_page); // 清除页面属性
    return;
}

// 获取空闲块数量
static size_t buddy_free_block_count(void) {
    return free_blocks_count;
}

// 展示空闲链表数组
static void SHOW_FREE_BLOCKS(void) {
    cprintf("显示空闲链表数组:\n");
    for (int i = 0; i < 15; i++) {
        cprintf("NO. %d 层: ", i);
        list_entry_t *le = &(free_block_lists[i]);
        while ((le = list_next(le)) != &(free_block_lists[i])) { // 遍历当前层空闲链表
            struct Page *p = le2page(le, page_link);
            cprintf("%d ", 1 << (p->property)); // 显示页面块大小
        }
        cprintf("\n");
    }
    return;
}

// 基本功能检查
static void basic_check(void) {
    struct Page *p0, *p1, *p2;
    p0 = p1 = p2 = NULL;
    assert((p0 = alloc_page()) != NULL);
    assert((p1 = alloc_page()) != NULL);
    assert((p2 = alloc_page()) != NULL);
    assert(p0 != p1 && p0 != p2 && p1 != p2);
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
    assert(page2pa(p0) < npage * PGSIZE);
    assert(page2pa(p1) < npage * PGSIZE);
    assert(page2pa(p2) < npage * PGSIZE);
    cprintf("P0,P1,P2_SINGLE PAGES(WITH ORDER):\n");
    SHOW_FREE_BLOCKS(); // 显示空闲块信息

    free_page(p0); // 释放页面
    free_page(p1);
    free_page(p2);
    cprintf("FREE_P0,P1,P2:\n");
    SHOW_FREE_BLOCKS(); // 显示释放后的空闲块信息
    assert(free_blocks_count == 16384);
    
    assert((p0 = alloc_pages(3)) != NULL);
    assert((p1 = alloc_pages(3)) != NULL);
    cprintf("P0,P1_3 PAGES:\n");
    SHOW_FREE_BLOCKS(); // 显示分配 3 页后的空闲块信息
    free_pages(p0, 3);
    free_pages(p1, 3);
    cprintf("FREE_P0,P1:\n");
    SHOW_FREE_BLOCKS(); // 显示释放后的空闲块信息

    assert((p0 = alloc_pages(4)) != NULL);
    cprintf("ALLOC_P0_4 PAGES:\n");
    SHOW_FREE_BLOCKS(); // 显示分配 4 页后的空闲块信息
    assert((p1 = alloc_pages(2)) != NULL);
    cprintf("ALLOC_P1_2 PAGES:\n");
    SHOW_FREE_BLOCKS(); // 显示分配 2 页后的空闲块信息
    assert((p2 = alloc_pages(1)) != NULL);
    cprintf("ALLOC_P1_1 PAGE:\n");
    SHOW_FREE_BLOCKS(); // 显示分配 1 页后的空闲块信息
    free_pages(p0, 4);
    free_pages(p1, 2);
    free_pages(p2, 1);
    cprintf("FREE:\n");
    SHOW_FREE_BLOCKS(); // 显示释放后的空闲块信息

    assert((p0 = alloc_pages(16385)) == NULL);
    assert((p0 = alloc_pages(16384)) != NULL);
    free_pages(p0, 16384); // 释放所有页面
}

// 检查功能
static void buddy_check(void) {
    SHOW_FREE_BLOCKS(); // 显示空闲块信息
    basic_check(); // 运行基本检查功能
}

const struct pmm_manager buddy_pmm_manager = {
    .name = "buddy_pmm_manager",
    .init = buddy_initialize,
    .init_memmap = buddy_initialize_memory,
    .alloc_pages = allocate_buddy_pages,
    .free_pages = release_buddy_pages,
    .nr_free_pages = buddy_free_block_count,
    .check = buddy_check,
};

