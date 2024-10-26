# Lab2

## Challenge1设计文档：Buddy System 分配器的实现

### 1. 简介

本次实现基于 Buddy System`（伙伴系统）内存分配算法。伙伴系统将内存空间划分为2的幂次方大小的内存块，旨在提高内存的分配效率并减少内存碎片。Buddy System 是一种经典的内存分配算法，广泛应用于操作系统的内存管理中。该算法通过将内存划分为2的幂次方大小的块，并采用特殊的“分离适配”策略进行内存分配。具体来说，内存按2的幂次方划分成若干个大小相等的空闲块，并维护一个空闲块链表。算法通过快速搜索找到与请求大小最匹配的空闲块，时间复杂度为 O(logN)，同时具有低外部碎片的优点。然而，由于内存按2的幂划分，可能会产生内部碎片。
从附加的辅助文件上来看：

#### Buddy System 的工作流程：

1. **内存分配**：
   
   - 寻找大于等于所需大小的最小空闲块。
   - 如果找不到合适的块，会将较大的块对半拆分，直到获得合适大小的块。
   - 一旦找到合适的块，将其分配给应用程序。

2. **内存释放**：
   
   - 释放内存时，会检查相邻的伙伴块是否也空闲。
   - 如果相邻的伙伴块空闲，则将两者合并为更大的块，并重复该过程，直到无法合并或达到最大块大小。

Buddy System 通过二叉树结构来监控和管理内存块的使用状态。高层节点代表大的内存块，低层节点代表较小的块。在内存分配时，系统从根节点开始搜索合适大小的块，逐步对半切割，直到找到匹配的块。在内存释放时，系统检查相邻块是否可以合并，从而减少内存碎片，提升内存利用率。

### 2. 设计思路

我们使用了一个**空闲链表数组**作为主要的数据结构。这个数组的每个元素都包含一个空闲链表的头部，链表中的所有块大小相同。具体来说，数组中的第 **i** 个元素会指向一个链表，链表中包含了所有大小为 \( $2^i (i<15)$ \) 页的空闲内存块。这种设计使得不同大小的内存块能够分别存储在对应的链表中，从而加快对所需内存块的查找和分配速度。系统按照14层（0-14层）的二叉树层次管理内存块，0层表示2^0=1页，14层表示2^14=16384页，顶层则为整个内存。通过这样的分级结构，可以更高效地管理和分配空闲页。

### 3. 核心数据结构

在实现中，内存块的管理通过 `buddy_system_free_t` 结构体进行，该结构体存储空闲内存块的链表和相关信息：

```c
typedef struct {
    unsigned int depth;                  // b_sys的二叉树深度
    list_entry_t free_block_lists[15];   // 空闲块链表数组（2^14 = 16384个可分配页）
    unsigned int free_blocks_count;      // 系统中剩余的空闲内存块总数
} buddy_system_free_t;
```

包含：

- `depth`：表示伙伴系统的二叉树深度（用于层级管理）。
- `free_block_lists[15]`：空闲块链表数组，每个链表表示该层次的空闲块，支持从0到14层的分级管理。
- `free_blocks_count`：系统中剩余的空闲块总数，表示当前可分配的空闲页数量。

**宏定义与辅助函数**

- **IS_POWER_OF_2(n)**：判断数值是否为2的幂，便于快速确定所需内存块的大小。
- **GET_POWER_OF_2(n)**：获取数值n的最大2的幂次，用于确定内存分配层级。
- **GET_BUDDY(page)**：获取页面的伙伴块地址，帮助在释放内存时判断是否可以进行合并。

### 4. 主要功能介绍

1. **初始化内存管理器**
   
   - 函数：`buddy_initialize()`  
     将 `free_block_lists` 的每层链表初始化为空链表，并将 `depth` 和 `free_blocks_count` 初始化为 0，以确保内存管理器的正常工作。

2. **初始化物理页**
   
   - 函数：`buddy_initialize_memory(struct Page *base, size_t real_n)`  
     初始化给定的物理页，确定所需的层次深度 `depth`，并将所有物理页标记为空闲。整个块加入到对应的链表中，以便后续的分配请求。
     
     ```c
     static void buddy_initialize_memory(struct Page *base, size_t real_n) {
       assert(real_n > 0);
       struct Page *p = base;
       depth = GET_POWER_OF_2(real_n);
       size_t n = 1 << depth;
       free_blocks_count = n;
       for (; p != base + n; p += 1) {
           assert(PageReserved(p));
           p->flags = 0;
           p->property = 0;
           set_page_ref(p, 0);
       }
       list_add(&(free_block_lists[depth]), &(base->page_link));
       base->property = depth;
     }
     ```

3. **分配内存块**
   
   - 函数：`allocate_buddy_pages(size_t real_n)`  
     根据请求的块大小选择最小的满足请求的块，若该层无合适块则尝试更高层的块并进行分割。成功分割后，将块的 `property` 标记为已用并返回块指针。
     
     ```c
     static struct Page * allocate_buddy_pages(size_t real_n) {
       assert(real_n > 0);
       if (real_n > free_blocks_count) return NULL;
       struct Page *page = NULL;
       depth = IS_POWER_OF_2(real_n) ? GET_POWER_OF_2(real_n) : GET_POWER_OF_2(real_n) + 1;
       size_t n = 1 << depth;
     
       while (1) {
           if (!list_empty(&(free_block_lists[depth]))) {
               page = le2page(list_next(&(free_block_lists[depth])), page_link);
               list_del(list_next(&(free_block_lists[depth])));
               SetPageProperty(page);
               free_blocks_count -= n;
               break;
           }
           for (int i = depth; i < 15; i++) {
               if (!list_empty(&(free_block_lists[i]))) {
                   struct Page *page1 = le2page(list_next(&(free_block_lists[i])), page_link);
                   struct Page *page2 = page1 + (1 << (i - 1));
                   page1->property = i - 1;
                   page2->property = i - 1;
                   list_del(list_next(&(free_block_lists[i])));
                   list_add(&(free_block_lists[i - 1]), &(page2->page_link));
                   list_add(&(free_block_lists[i - 1]), &(page1->page_link));
                   break;
               }
           }
       }
       return page;
     }
     ```

4. **释放内存块**
   
   - 函数：`release_buddy_pages(struct Page *base, size_t n)`  
     根据给定的内存块，首先将其添加回空闲链表中，然后根据伙伴系统规则查找相邻伙伴块，尝试合并成更大的块。合并过程会递归进行，直到无法继续合并为止。最终更新空闲块总数。
     
     ```c
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
     ```

在释放内存块的过程中，函数 `release_buddy_pages` 使用伙伴块的地址检查功能 `GET_BUDDY` 来检测相邻块是否空闲，从而决定是否合并为更大的块。

5. **展示空闲块分布**
   
   - 函数：`SHOW_FREE_BLOCKS()`  
     打印各层空闲块分布情况，用于调试和观察系统的内存使用状态。
     
     ```c
     static void SHOW_FREE_BLOCKS(void) {
       cprintf("显示空闲链表数组:\n");
       for (int i = 0; i < 15; i++) {
           cprintf("NO. %d 层: ", i);
           list_entry_t *le = &(free_block_lists[i]);
           while ((le = list_next(le)) != &(free_block_lists[i])) {
               struct Page *p = le2page(le, page_link);
               cprintf("%d ", 1 << (p->property));
           }
           cprintf("\n");
       }
     }
     ```

### 5. 结果展示

从输出结果来看，我们使用了一系列的分配和释放操作，配合 `basic_check()` 函数中的分配和释放测试，展示了 Buddy System 内存分配器的正确性。以下为相关代码

```cpp
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
}
```

#### 分配

- 从 `No.0` 到 `No.14` 代表不同大小的空闲块，块大小是 2 的幂次方，从 1 页到 16384页不等。

- 第 **0** 号链表存有 1 页的块，第 **1** 号链表存有 2 页的块，依次类推。

- **初始化状态**：系统初始化后，顶层（第14层）显示为16,384个页。
  
  ```
  NO. 14 层: 16384
  ```

- **分配单页后的状态**：在分配1页后，系统自动从较大的块中分割出1页，并将剩余的部分按需加入空闲块列表。
  
  ```
  NO. 0 层: 1
  NO. 2 层: 4
  NO. 3 层: 8
  ...
  ```

- **多次分配和释放**：分配不同大小的内存块，并观察空闲块的变化。系统根据需求将大的空闲块分割成多个小块，同时动态调整每层的空闲块数量。

- **最终释放后的状态**：完成所有分配与释放后，所有块被合并回第14层，恢复到初始状态。
  
  ```
  NO. 14 层: 16384
  ```

输出的最后一行 `check_alloc_page() succeeded!` 表明该函数中的所有测试均通过，证明 Buddy System 实现是正确的。以下为结果。

```textile
pp@pp-virtual-machine:~/lab2$ make qemu

OpenSBI v0.4 (Jul  2 2019 11:53:53)
   ____                    _____ ____ _____
  / __ \                  / ____|  _ \_   _|
 | |  | |_ __   ___ _ __ | (___ | |_) || |
 | |  | | '_ \ / _ \ '_ \ \___ \|  _ < | |
 | |__| | |_) |  __/ | | |____) | |_) || |_
  \____/| .__/ \___|_| |_|_____/|____/_____|
        | |
        |_|

Platform Name          : QEMU Virt Machine
Platform HART Features : RV64ACDFIMSU
Platform Max HARTs     : 8
Current Hart           : 0
Firmware Base          : 0x80000000
Firmware Size          : 112 KB
Runtime SBI Version    : 0.1

PMP0: 0x0000000080000000-0x000000008001ffff (A)
PMP1: 0x0000000000000000-0xffffffffffffffff (A,R,W,X)
(THU.CST) os is loading ...
Special kernel symbols:
  entry  0xffffffffc0200032 (virtual)
  etext  0xffffffffc02017f8 (virtual)
  edata  0xffffffffc0206010 (virtual)
  end    0xffffffffc0206560 (virtual)
Kernel executable memory footprint: 26KB
memory management: buddy_pmm_manager
physcial memory map:
  memory: 0x0000000007e00000, [0x0000000080200000, 0x0000000087ffffff].
显示空闲链表数组:
NO. 0 层: 
NO. 1 层: 
NO. 2 层: 
NO. 3 层: 
NO. 4 层: 
NO. 5 层: 
NO. 6 层: 
NO. 7 层: 
NO. 8 层: 
NO. 9 层: 
NO. 10 层: 
NO. 11 层: 
NO. 12 层: 
NO. 13 层: 
NO. 14 层: 16384 
P0,P1,P2_SINGLE PAGES(WITH ORDER):
显示空闲链表数组:
NO. 0 层: 1 
NO. 1 层: 
NO. 2 层: 4 
NO. 3 层: 8 
NO. 4 层: 16 
NO. 5 层: 32 
NO. 6 层: 64 
NO. 7 层: 128 
NO. 8 层: 256 
NO. 9 层: 512 
NO. 10 层: 1024 
NO. 11 层: 2048 
NO. 12 层: 4096 
NO. 13 层: 8192 
NO. 14 层: 
FREE_P0,P1,P2:
显示空闲链表数组:
NO. 0 层: 
NO. 1 层: 
NO. 2 层: 
NO. 3 层: 
NO. 4 层: 
NO. 5 层: 
NO. 6 层: 
NO. 7 层: 
NO. 8 层: 
NO. 9 层: 
NO. 10 层: 
NO. 11 层: 
NO. 12 层: 
NO. 13 层: 
NO. 14 层: 16384 
P0,P1_3 PAGES:
显示空闲链表数组:
NO. 0 层: 
NO. 1 层: 
NO. 2 层: 
NO. 3 层: 8 
NO. 4 层: 16 
NO. 5 层: 32 
NO. 6 层: 64 
NO. 7 层: 128 
NO. 8 层: 256 
NO. 9 层: 512 
NO. 10 层: 1024 
NO. 11 层: 2048 
NO. 12 层: 4096 
NO. 13 层: 8192 
NO. 14 层: 
FREE_P0,P1:
显示空闲链表数组:
NO. 0 层: 
NO. 1 层: 
NO. 2 层: 
NO. 3 层: 
NO. 4 层: 
NO. 5 层: 
NO. 6 层: 
NO. 7 层: 
NO. 8 层: 
NO. 9 层: 
NO. 10 层: 
NO. 11 层: 
NO. 12 层: 
NO. 13 层: 
NO. 14 层: 16384 
ALLOC_P0_4 PAGES:
显示空闲链表数组:
NO. 0 层: 
NO. 1 层: 
NO. 2 层: 4 
NO. 3 层: 8 
NO. 4 层: 16 
NO. 5 层: 32 
NO. 6 层: 64 
NO. 7 层: 128 
NO. 8 层: 256 
NO. 9 层: 512 
NO. 10 层: 1024 
NO. 11 层: 2048 
NO. 12 层: 4096 
NO. 13 层: 8192 
NO. 14 层: 
ALLOC_P1_2 PAGES:
显示空闲链表数组:
NO. 0 层: 
NO. 1 层: 2 
NO. 2 层: 
NO. 3 层: 8 
NO. 4 层: 16 
NO. 5 层: 32 
NO. 6 层: 64 
NO. 7 层: 128 
NO. 8 层: 256 
NO. 9 层: 512 
NO. 10 层: 1024 
NO. 11 层: 2048 
NO. 12 层: 4096 
NO. 13 层: 8192 
NO. 14 层: 
ALLOC_P1_1 PAGE:
显示空闲链表数组:
NO. 0 层: 1 
NO. 1 层: 
NO. 2 层: 
NO. 3 层: 8 
NO. 4 层: 16 
NO. 5 层: 32 
NO. 6 层: 64 
NO. 7 层: 128 
NO. 8 层: 256 
NO. 9 层: 512 
NO. 10 层: 1024 
NO. 11 层: 2048 
NO. 12 层: 4096 
NO. 13 层: 8192 
NO. 14 层: 
FREE:
显示空闲链表数组:
NO. 0 层: 
NO. 1 层: 
NO. 2 层: 
NO. 3 层: 
NO. 4 层: 
NO. 5 层: 
NO. 6 层: 
NO. 7 层: 
NO. 8 层: 
NO. 9 层: 
NO. 10 层: 
NO. 11 层: 
NO. 12 层: 
NO. 13 层: 
NO. 14 层: 16384 
check_alloc_page() succeeded!
satp virtual address: 0xffffffffc0205000
satp physical address: 0x0000000080205000
++ setup timer interrupts
100 ticks
100 ticks
100 ticks
100 ticks
```

### 6. 总结

该实现有效利用了 `Buddy System` 的特性，通过对内存块的拆分与合并，确保了内存的高效分配和回收。此外，借助多个辅助函数，如 `GET_POWER_OF_2()` 等，提高了内存块大小计算的准确性。本次实现还提供了测试用例 `basic_check()`，验证了内存管理模块的功能正确性。

在实际应用中，`Buddy System` 算法能够很好地减少内存碎片，并且在大块内存分配和释放时表现优异，是一种高效的内存管理算法。
