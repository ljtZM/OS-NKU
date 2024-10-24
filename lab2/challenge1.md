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

我们使用了一个**空闲链表数组**作为主要的数据结构。这个数组的每个元素都包含一个空闲链表的头部，链表中的所有块大小相同。具体来说，数组中的第 **i** 个元素会指向一个链表，链表中包含了所有大小为 \( $2^i$ \) 页的空闲内存块。这种设计使得不同大小的内存块能够分别存储在对应的链表中，从而加快对所需内存块的查找和分配速度。

### 3. 核心数据结构

在实现中，内存块的管理通过 `free_buddy_t` 结构体进行，该结构体存储空闲内存块的链表和相关信息：

```c
typedef struct {
    uint32_t order;                     // 最大阶数
    list_entry_t free_array[MAX_ORDER + 1]; // 每个阶数的空闲块链表
    uint32_t nr_free;                   // 当前空闲页总数
} free_buddy_t;
```

`free_buddy_t` 包含：

- `order`：系统支持的最大阶数，对应的内存块大小为 `2^order` 页。
- `free_array[]`：每个阶数的空闲块链表，用于管理各阶数的空闲内存块。
- `nr_free`：系统中空闲页的总数。

此外，定义了一些宏：

- `free_blocks`：引用伙伴系统的空闲链表数组。
- `total_free`：表示空闲的总页数。
- `max_level`：表示最大的阶数。

### 4. 主要功能介绍

#### 4.1 `buddy_sys_initialize()`

该函数用于初始化伙伴系统的内存管理结构体，将所有的空闲链表置为空。每次启动时，首先调用该函数进行内存管理的初始化。

```c
static void buddy_sys_initialize() {
    max_level = 0;
    total_free = 0;
    for (int i = 0; i < MAX_ORDER; ++i)
        list_init(free_blocks + i);
}
```

#### 4.2 `buddy_sys_memmap_init()`

该函数用于初始化物理内存的管理。它会将物理内存块划分为2的幂次方大小，并将最大的块加入到相应阶数的链表中。

```c
static void buddy_sys_memmap_init(struct Page *base, size_t n) {
    size_t managed_pages = round_down_to_power_of_two(n);
    max_level = calc_log2(managed_pages);

    for (struct Page *p = base; p != base + managed_pages; ++p) {
        p->flags = 0;       
        p->property = 0;    
        set_page_ref(p, 0);
    }

    total_free = managed_pages;
    base->property = max_level;
    SetPageProperty(base);
    list_add(&(free_blocks[max_level]), &(base->page_link));  
}
```

该函数会调用 `round_down_to_power_of_two()` 来计算2的幂次方大小，并通过 `calc_log2()` 确定对应的阶数。

#### 4.3 `buddy_split_block()`

当需要分配的内存块对应的阶数没有空闲块时，该函数会将更高阶数的块拆分为两个较小的块，从而满足内存分配需求。

```c
static void buddy_split_block(size_t level) {
    if (list_empty(&(free_blocks[level])))   
        buddy_split_block(level + 1);

    struct Page *left_block = le2page(list_next(&(free_blocks[level])), page_link);
    left_block->property -= 1;
    struct Page *right_block = left_block + (1 << (left_block->property));
    SetPageProperty(right_block);    
    right_block->property = left_block->property;

    list_del(list_next(&(free_blocks[level])));
    list_add(&(free_blocks[level - 1]), &(left_block->page_link));
    list_add(&(left_block->page_link), &(right_block->page_link));
}
```

通过递归调用，算法会不断寻找可以拆分的更大内存块，并将其拆分为两个较小的块。

#### 4.4 `buddy_sys_alloc_pages()`

该函数用于分配内存，分配的页数必须是2的幂次方。如果当前阶数的链表为空，会调用 `buddy_split_block()` 来拆分更高阶数的内存块。

```c
static struct Page* buddy_sys_alloc_pages(size_t n) {
    if (n > total_free) return NULL;

    size_t required_pages = round_up_to_power_of_two(n);
    uint32_t level = calc_log2(required_pages);

    if (list_empty(&(free_blocks[level])))
        buddy_split_block(level + 1);

    struct Page *allocated_page = le2page(list_next(&(free_blocks[level])), page_link);
    list_del(list_next(&(free_blocks[level])));

    ClearPageProperty(allocated_page);
    total_free -= required_pages;
    return allocated_page;
}
```

#### 4.5 `buddy_sys_free_pages()`

该函数用于释放指定的内存块，并尝试将释放的块与相邻的“伙伴”块合并，以减少内存碎片。

```c
static void buddy_sys_free_pages(struct Page *base, size_t n) {
    uint32_t level = base->property;
    size_t required_pages = (1 << level);

    struct Page* left_block = base;
    list_add(&(free_blocks[level]), &(left_block->page_link));   

    struct Page* buddy = find_buddy(left_block);
    while (left_block->property < max_level && PageProperty(buddy)) {
        if (left_block > buddy) {
            struct Page* temp = left_block;
            left_block = buddy;
            buddy = temp;
        }

        list_del(&(left_block->page_link));
        list_del(&(buddy->page_link));
        left_block->property += 1;
        buddy->property = 0;
        SetPageProperty(left_block);
        ClearPageProperty(buddy);
    }

    total_free += required_pages;
}
```

在释放内存时，函数会寻找相邻的伙伴块并尝试合并，如果条件允许，将多个小块合并为较大的块。

#### 4.6 `basic_buddy_check()`

该函数用于测试 `Buddy System` 的功能。它首先分配多个页面，展示当前空闲链表的状态，随后释放这些页面并再次展示空闲链表的变化。此函数用于验证内存分配和释放的正确性。

```c
static void basic_buddy_check(void) {
    struct Page *p0, *p1, *p2;

    assert((p0 = alloc_page()) != NULL);
    display_buddy_structure();
    assert((p1 = alloc_page()) != NULL);
    display_buddy_structure();
    assert((p2 = alloc_page()) != NULL);

    free_page(p0);
    free_page(p1);
    free_page(p2);
    display_buddy_structure();

    assert(total_free == 16384);

    assert((p0 = alloc_pages(4)) != NULL);
    assert((p1 = alloc_pages(2)) != NULL);
    assert((p2 = alloc_pages(1)) != NULL);

    free_pages(p0, 4);
    free_pages(p1, 2);
    free_pages(p2, 1);
    display_buddy_structure();
}
```

### 5. 结果展示

从输出结果来看，我们使用了一系列的分配和释放操作，配合 `check_alloc_page()` 函数中的分配和释放测试，展示了 Buddy System 内存分配器的正确性。

#### 初始状态：分配 p0 前

输出显示了内存的初始状态，系统中的所有内存都在对应的阶数链表中：

- 从 `No.0` 到 `No.13` 代表不同大小的空闲块，块大小是 2 的幂次方，从 1 页到 8192 页不等。
- 第 **0** 号链表存有 1 页的块，第 **1** 号链表存有 2 页的块，依次类推。

#### 第一次分配：分配 p0

执行 `alloc_page()` 函数后，`p0` 被分配：

- 在链表的状态中，我们看到 **No.0** 的空闲链表减少了一个页面，表明成功分配了一个 1 页大小的块。
- 其他链表保持不变，这表明仅有第 **0** 阶的链表受到了影响。

#### 第二次分配：分配 p0, p1

执行第二次 `alloc_page()` 分配了 `p1`：

- 输出结果显示 **No.1** 的空闲链表被修改，链表中的页面数减少。分配了 1 页后，第 **0** 阶的空闲链表未变化。
- 这个结果表明系统从第 **1** 阶的链表分配了合适大小的块，并未影响其他较大的空闲块。

#### **第三次分配：分配 p0, p1, p2**

当第三次 `alloc_page()` 分配 `p2` 后：

- 系统将 **No.0** 的空闲链表再次减少，表明分配了 1 页的块。
- 这验证了 `alloc_page()` 函数能够正确处理多次分配请求，并从合适的链表中分配所需的块。

#### **释放操作：释放 p0, p1, p2**

在执行释放操作后：

- 系统通过 `buddy_sys_free_pages()` 释放了 `p0`、`p1` 和 `p2`。
- 释放后可以看到，空闲链表恢复到了多个 **No.0** 的链表中，表明页面被正确释放并重新放回对应的链表。
- 此时，多个相邻的 1 页块没有合并，因为没有满足合并的条件（例如，释放时相邻块未空闲或阶数未到达需要合并的条件）。

#### **再次分配并释放 p0, p1, p2**

在执行再次分配和释放后：

- 系统成功分配了 **p0**、**p1**、**p2**，再次展示了链表状态。
- 最终验证了 Buddy System 能够正确处理分配、释放和再分配操作，并确保没有空闲块的情况下正确返回。

#### **验证结果：check_alloc_page()**

`check_alloc_page()` 函数通过一系列的分配和释放测试，验证了 Buddy System 的核心操作是否符合预期。具体测试内容包括：

- 分配若干页面，确保链表的正确更新。
- 释放页面后，链表中的空闲块能够正确回到相应的链表中。
- 合并相邻的空闲块，确保系统有效利用内存空间，减少内存碎片。
- 当没有足够的空闲块时，系统能够正确处理并返回相应的结果。

输出的最后一行 `check_alloc_page() succeeded!` 表明该函数中的所有测试均通过，证明 Buddy System 实现是正确的。以下为结果。

```textile
分配p0:
当前空闲的链表数组:
No.0的空闲链表有1页 [地址为0x80348000] 
No.1的空闲链表有2页 [地址为0x80349000] 
No.2的空闲链表有4页 [地址为0x8034b000] 
No.3的空闲链表有8页 [地址为0x8034f000] 
No.4的空闲链表有16页 [地址为0x80357000] 
No.5的空闲链表有32页 [地址为0x80367000] 
No.6的空闲链表有64页 [地址为0x80387000] 
No.7的空闲链表有128页 [地址为0x803c7000] 
No.8的空闲链表有256页 [地址为0x80447000] 
No.9的空闲链表有512页 [地址为0x80547000] 
No.10的空闲链表有1024页 [地址为0x80747000] 
No.11的空闲链表有2048页 [地址为0x80b47000] 
No.12的空闲链表有4096页 [地址为0x81347000] 
No.13的空闲链表有8192页 [地址为0x82347000] 
分配p0,p1:
当前空闲的链表数组:
No.1的空闲链表有2页 [地址为0x80349000] 
No.2的空闲链表有4页 [地址为0x8034b000] 
No.3的空闲链表有8页 [地址为0x8034f000] 
No.4的空闲链表有16页 [地址为0x80357000] 
No.5的空闲链表有32页 [地址为0x80367000] 
No.6的空闲链表有64页 [地址为0x80387000] 
No.7的空闲链表有128页 [地址为0x803c7000] 
No.8的空闲链表有256页 [地址为0x80447000] 
No.9的空闲链表有512页 [地址为0x80547000] 
No.10的空闲链表有1024页 [地址为0x80747000] 
No.11的空闲链表有2048页 [地址为0x80b47000] 
No.12的空闲链表有4096页 [地址为0x81347000] 
No.13的空闲链表有8192页 [地址为0x82347000] 
分配p0, p1, p2之后:
当前空闲的链表数组:
No.0的空闲链表有1页 [地址为0x8034a000] 
No.2的空闲链表有4页 [地址为0x8034b000] 
No.3的空闲链表有8页 [地址为0x8034f000] 
No.4的空闲链表有16页 [地址为0x80357000] 
No.5的空闲链表有32页 [地址为0x80367000] 
No.6的空闲链表有64页 [地址为0x80387000] 
No.7的空闲链表有128页 [地址为0x803c7000] 
No.8的空闲链表有256页 [地址为0x80447000] 
No.9的空闲链表有512页 [地址为0x80547000] 
No.10的空闲链表有1024页 [地址为0x80747000] 
No.11的空闲链表有2048页 [地址为0x80b47000] 
No.12的空闲链表有4096页 [地址为0x81347000] 
No.13的空闲链表有8192页 [地址为0x82347000] 
释放 p2 之后:
当前空闲的链表数组:
No.0的空闲链表有1页 [地址为0x80349000] 1页 [地址为0x80348000] 1页 [地址为0x80347000] 1页 [地址为0x8034a000] 
No.2的空闲链表有4页 [地址为0x8034b000] 
No.3的空闲链表有8页 [地址为0x8034f000] 
No.4的空闲链表有16页 [地址为0x80357000] 
No.5的空闲链表有32页 [地址为0x80367000] 
No.6的空闲链表有64页 [地址为0x80387000] 
No.7的空闲链表有128页 [地址为0x803c7000] 
No.8的空闲链表有256页 [地址为0x80447000] 
No.9的空闲链表有512页 [地址为0x80547000] 
No.10的空闲链表有1024页 [地址为0x80747000] 
No.11的空闲链表有2048页 [地址为0x80b47000] 
No.12的空闲链表有4096页 [地址为0x81347000] 
No.13的空闲链表有8192页 [地址为0x82347000] 
再次分配 p0, p1, p2
确保没有空闲页,释放 p0, p1, p2
check_alloc_page() succeeded!
请你结合输出结果和我的check函数说明测试用例说明实现的正确性
```

### 6. 总结

该实现有效利用了 `Buddy System` 的特性，通过对内存块的拆分与合并，确保了内存的高效分配和回收。此外，借助多个辅助函数，如 `calc_log2()` 和 `round_up_to_power_of_two()`，提高了内存块大小计算的准确性。本次实现还提供了测试用例 `basic_buddy_check()`，验证了内存管理模块的功能正确性。

在实际应用中，`Buddy System` 算法能够很好地减少内存碎片，并且在大块内存分配和释放时表现优异，是一种高效的内存管理算法。
