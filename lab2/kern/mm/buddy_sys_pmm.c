#include <buddy_sys_pmm.h>
#include <list.h>
#include <string.h>
#include <pmm.h>
#include <stdio.h>

// 全局变量，包含了伙伴系统的相关信息
free_buddy_t buddy_sys_data;

// 宏定义，用于简化访问 buddy_sys_data 中的字段
#define free_blocks (buddy_sys_data.free_array) // 空闲链表数组，存储不同大小的空闲块
#define total_free (buddy_sys_data.nr_free) // 空闲页的总数
#define max_level (buddy_sys_data.order) // 最大阶数
#define is_power_of_two(n) (!((n)&((n)-1))) // 判断是否为2的幂次方

// 计算一个数的对数（以2为底），用于确定分配的阶数
static uint32_t calc_log2(size_t n)
{
    uint32_t level = 0;
    while (n > 1)
    {
        level++;
        n >>= 1;
    }
    return level;
}

// 将给定的值向下取整为最近的2的幂次方
static size_t round_down_to_power_of_two(size_t n)
{
    size_t rounded = 1;
    while (n > 1)
    {
        rounded <<= 1;
        n >>= 1;
    }
    return rounded;
}

// 将给定的值向上取整为最近的2的幂次方
static size_t round_up_to_power_of_two(size_t n)
{
    size_t down = round_down_to_power_of_two(n);
    return (n == down) ? down : (down << 1);
}

// 获取页面在物理页数组中的索引
static inline uint32_t get_page_index(struct Page *page)
{
    return page - pages;
}
    
// 初始化伙伴系统，将所有空闲链表置为空
static void buddy_sys_initialize()
{
    max_level = 0; // 初始最大阶数设为0
    total_free = 0; // 初始空闲页数设为0
    for (int i = 0; i < MAX_ORDER; ++i)
        list_init(free_blocks + i); // 初始化每个阶数的空闲链表
}

// 初始化伙伴系统的内存管理，将系统的所有内存块分配到相应的阶数链表中
static void buddy_sys_memmap_init(struct Page *base, size_t n)
{
    assert(n > 0);
    size_t managed_pages = round_down_to_power_of_two(n); // 向下取整为2的幂次方
    max_level = calc_log2(managed_pages); // 计算对应的阶数

    // 初始化内存块，将每页的状态和属性清零
    for (struct Page *p = base; p != base + managed_pages; ++p)
    {
        assert(PageReserved(p)); // 确保页是保留状态
        p->flags = 0;       // 清空标志位
        p->property = 0;    // 设置为无管理的页
        set_page_ref(p, 0); // 引用计数清零
    }

    total_free = managed_pages; // 更新空闲页数
    base->property = max_level; // 设置内存块的阶数
    SetPageProperty(base);      // 将页面设置为伙伴系统头页
    list_add(&(free_blocks[max_level]), &(base->page_link));  // 将块加入相应的空闲链表
}

// 拆分较大的块为较小的块，直到满足请求的大小
static void buddy_split_block(size_t level)
{
    assert(level > 0 && level <= max_level); // 确保阶数有效

    // 如果该阶数没有空闲块，继续向上层拆分
    if (list_empty(&(free_blocks[level])))   
        buddy_split_block(level + 1);
    
    // 获取空闲块并将其拆分为两个较小的块
    struct Page *left_block = le2page(list_next(&(free_blocks[level])), page_link);
    left_block->property -= 1; // 更新左块的阶数
    struct Page *right_block = left_block + (1 << (left_block->property)); // 计算右块的地址
    SetPageProperty(right_block); // 标记右块为头页
    right_block->property = left_block->property; // 设置右块的阶数

    // 将原来的块从链表中移除，加入到下一级的空闲链表中
    list_del(list_next(&(free_blocks[level])));
    list_add(&(free_blocks[level - 1]), &(left_block->page_link));
    list_add(&(left_block->page_link), &(right_block->page_link));
}

// 分配 n 页内存
static struct Page* buddy_sys_alloc_pages(size_t n)
{
    assert(n > 0);
    if (n > total_free) return NULL; // 如果没有足够的空闲页，则返回 NULL

    size_t required_pages = round_up_to_power_of_two(n); // 将需求向上取整为2的幂
    uint32_t level = calc_log2(required_pages); // 计算对应的阶数

    // 如果相应阶数没有空闲块，则拆分更高阶的块
    if (list_empty(&(free_blocks[level])))
        buddy_split_block(level + 1);

    // 分配块并更新空闲页数
    struct Page *allocated_page = le2page(list_next(&(free_blocks[level])), page_link);
    list_del(list_next(&(free_blocks[level])));

    ClearPageProperty(allocated_page); // 清除块的属性
    total_free -= required_pages; // 更新空闲页数
    return allocated_page;
}

// 根据给定页面找到其伙伴块的地址
static struct Page* find_buddy(struct Page *page)
{
    uint32_t level = page->property; // 获取块的阶数
    uint32_t buddy_idx = get_page_index(page) ^ (1 << level); // 通过异或操作计算伙伴块的索引
    return pages + buddy_idx; // 返回伙伴块的地址
}

// 释放 n 页内存并尝试与伙伴块合并
static void buddy_sys_free_pages(struct Page *base, size_t n)
{
    assert(n > 0);
    uint32_t level = base->property; // 获取释放块的阶数
    size_t required_pages = (1 << level); // 计算所释放的页数
    assert(required_pages == round_up_to_power_of_two(n)); // 确保释放页数符合2的幂次方

    struct Page* left_block = base;
    list_add(&(free_blocks[level]), &(left_block->page_link)); // 将块重新加入空闲链表

    // 查找伙伴块并尝试合并
    struct Page* buddy = find_buddy(left_block);
    while (left_block->property < max_level && PageProperty(buddy)) // 如果伙伴块空闲，则合并
    {
        if (left_block > buddy) // 确保较小的块在左边
        {
            struct Page* temp = left_block;
            left_block = buddy;
            buddy = temp;
        }

        list_del(&(left_block->page_link)); // 从链表中删除已释放的块
        list_del(&(buddy->page_link));
        left_block->property += 1; // 更新块的阶数
        buddy->property = 0;
        SetPageProperty(left_block); // 设置合并后的块为头页
        ClearPageProperty(buddy); // 清除伙伴块的属性
    }

    total_free += required_pages; // 更新空闲页数
}

// 返回当前系统中的空闲页数
static size_t buddy_sys_free_pages_count()
{
    return total_free;
}

// 显示当前的空闲链表结构，便于调试和观察内存分配情况
static void display_buddy_structure(void) {
    cprintf("当前空闲的链表数组:\n");
    for (int i = 0; i < MAX_ORDER; i++) {
        if (!list_empty(&(free_blocks[i]))) {
            cprintf("No.%d的空闲链表有", i);
            list_entry_t *le = &(free_blocks[i]);
            while ((le = list_next(le)) != &(free_blocks[i])) {
                struct Page *p = le2page(le, page_link);
                cprintf("%lu页 [地址为%p] ", (1UL << i), page2pa(p)); // 打印页大小和物理地址
            }
            cprintf("\n");
        }
    }
}

// 基本的测试函数，验证内存分配和释放是否正常工作
static void basic_buddy_check(void) {
    struct Page *p0, *p1, *p2;
    p0 = p1 = p2 = NULL;
    
    // 分配并显示当前空闲链表
    assert((p0 = alloc_page()) != NULL);
    cprintf("分配p0:\n");
    display_buddy_structure();
    
    assert((p1 = alloc_page()) != NULL);
    cprintf("分配p0,p1:\n");
    display_buddy_structure();
    
    assert((p2 = alloc_page()) != NULL);
    
    // 确保分配的页面不同，且引用计数为0
    assert(p0 != p1 && p0 != p2 && p1 != p2);
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);

    // 显示分配后的空闲链表
    cprintf("分配p0, p1, p2之后:\n");
    display_buddy_structure();

    // 释放并显示当前空闲链表
    free_page(p0);
    free_page(p1);
    free_page(p2);
    cprintf("释放 p2 之后:\n");
    display_buddy_structure();
    
    // 验证空闲页数
    assert(total_free == 16384);
    
    // 再次分配和释放
    assert((p0 = alloc_pages(4)) != NULL);
    assert((p1 = alloc_pages(2)) != NULL);
    assert((p2 = alloc_pages(1)) != NULL);

    cprintf("再次分配 p0, p1, p2\n");

    free_pages(p0, 4);
    free_pages(p1, 2);
    free_pages(p2, 1);

    cprintf("确保没有空闲页,释放 p0, p1, p2\n");
}

// 定义伙伴系统的内存管理接口
const struct pmm_manager buddy_pmm_manager = {
    .name = "buddy_pmm_manager",
    .init = buddy_sys_initialize, // 初始化
    .init_memmap = buddy_sys_memmap_init, // 内存初始化
    .alloc_pages = buddy_sys_alloc_pages, // 分配内存
    .free_pages = buddy_sys_free_pages, // 释放内存
    .nr_free_pages = buddy_sys_free_pages_count, // 获取空闲页数
    .check = basic_buddy_check, // 测试函数
};
