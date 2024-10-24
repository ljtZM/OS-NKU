# 练习1：理解first-fit 连续物理内存分配算法（思考题）
first-fit 连续物理内存分配算法作为物理内存分配一个很基础的方法，需要同学们理解它的实现过程。请大家仔细阅读实验手册的教程并结合**kern/mm/default_pmm.c**中的相关代码，认真分析**default_init，default_init_memmap**，**default_alloc_pages**， **default_free_pages**等相关函数，并描述程序在进行物理内存分配的过程以及各个函数的作用。 请在实验报告中简要说明你的设计实现过程。请回答如下问题：

##### <span style="background:rgba(240, 167, 216, 0.55)">你的first fit算法是否有进一步的改进空间？</span>
**static void default_init(void)函数**：从总体上来看初始化空闲链表free_list和将空闲块数量nr_free设置为0。

**static void default_init_memmap(struct Page *base, size_t n)函数**：首先遍历从base开始的n个页面，通过
assert(PageReserved(p))确保每个页面被保留，将当前页面的标志和属性重置，将页面引用计数设置为0。然后将base页面的属性设置为块的总大小n，标记该页面具有属性，增加n个空闲块计数。接下来将将空闲块加入链接，如果此时链表为空，则直接添加；否则，遍历链表找到合适的位置按地址从低到高排序插入。从总体上来看，这个函数的功能是初始化一个空闲内存块，并将其加入到空闲链表中。

**static struct Page * default_alloc_pages(size_t n)函数**：首先确保请求的页面数量n大于0，检查是否有足够的空闲页面，如果没有的话，返回NULL。然后遍历空闲链表查找合适的块，先初始化page为NULL，遍历并找到第一个property >= n的页面p，并将其赋值给page。如果找到了合适的块，获取该块前一个链表节点prev，从空闲链表中删除该块。如果块大小大于请求大小，计算剩余部分的新块p = page + n，设置新块的属性为剩余大小page->property - n，标记新块具有属性，然后将它插入到刚刚得到的prev的后面，更新空闲块计数nr_free -= n，清除分配块的属性标记ClearPageProperty，并返回分配的页面。如果没有找到，返回NULL。从总体上来看，这个函数的功能是在空闲链表中查找第一个足够大的空闲块，并分配n个页面。

**static void default_free_pages(struct Page *base, size_t n)函数**：首先遍历从base看是的n个页面，确保页面未被保留且不具有属性，重置页面标志，将页面引用计数设置为0。然后将base页面的大小设置为n，标记该页面具有属性，并把空闲块计数nr_free增加n。接下来把块插入到空闲链表中，如果链表为空，则直接添加；否则，遍历链表找到合适的位置按地址从低到高排序插入。然后尝试进行合并操作，先尝试向前合并，获取当前块前一个链表节点le，如果le的末尾地址与当前块的起始地址相同，则合并两个块，更新合并后的块的属性，并从链表中删除当前块；接着尝试向后合并，获取当前块后一个链表节点le，如果当前块的末尾地址与le的起始地址相同，则合并两个块，更新合并后的块的属性，并从链表中删除后一个块。从总体上来看，该函数的功能是释放内存并将其重新插入到空闲链表中，同时尝试合并相邻的空闲块。

**static size_t default_nr_free_pages(void)函数**：返回当前空闲页面的总数，即nr_free变量的值。

**static void basic_check(void)函数**：在这个函数中对一些内容进行了检查，比如能否成功分配三个页面p0、p1和p2，验证这三个页面地址不同，验证引用计数为0，验证页面物理地址有效，保存并重置空闲链表，保存并重置空闲块计数，验证分配失败，释放已分配的页面，重新分配页面，释放部分页面并验证链表，验证分配回收的页面，恢复空闲链表和计数，释放页面。从总体上来说，这个函数的功能是执行一系列基本检查以验证内存管理器的正确性。

**static void default_check(void)函数**：首先验证空闲链表和总空闲页数，具体来说遍历空闲链表，确保每个块具有属性，并统计总空闲页数，确保它与实际的nr_free_pages一致。然后调用basic_check函数，执行基本检查。接下来分配5个页面，需要确保分配成功且分配的块不具有属性。然后保存当前空闲链表，初始化空闲链表并确保它为空，保存当前空闲块计数，并将它重置为0。接下来进行释放测试，先释放p0后的三个页面，尝试分配4个页面应失败，确保释放的块具有属性且大小为3，再分配3个页面，并确保是刚刚释放的块。然后也是一个释放的测试，分两次释放p0、p1开始的3个页面，确保p0有属性1，p1有属性3。接下来分配p0页面，并确保它是p2前面的，释放p0再分配2个页面，需要确保p0 == p2 + 1。然后释放p0开始的2个页面以及p2，给p0分配5个页面，需要确保这次分配成功，再进行分配操作时失败的，需要确保空闲块计数为0。在这之后，可以恢复原来的空闲块计数nr_free和原来的空闲链表free_list，释放刚刚分配给p0的5个页面。最后遍历空闲链表，确保所有块被正确释放，count和total应该为0。从总体上来说，这个函数的功能是执行一系列更复杂的测试，以验证first-fit算法的正确性。

**const struct pmm_manager default_pmm_manager结构体**：定义一个pmm_manager结构体实例，指定内存管理器的名称为default_pmm_manager和各个操作函数。
操作函数有初始化函数.init，指向default_init；初始化内存映射的函数.init_memmap，指向default_init_memmap；分配页面的函数.alloc_pages，指向default_alloc_pages；释放页面的函数.free_pages，指向default_free_pages；获取空闲页面数的函数.nr_free_pages，指向default_nr_free_pages；检查函数.check，指向default_check。

**程序在进行物理内存分配的过程以及各个函数的作用**：在进行物理内存分配时，要进行以下的操作
1.初始化：通过 default_init 和 default_init_memmap 函数初始化空闲内存块链表，建立空闲块列表。

2.内存分配：调用 default_alloc_pages 函数，根据需要分配一定数量的连续物理页。函数遍历空闲链表，找到第一个足够大的块进行分配，如果块过大，则拆分剩余部分重新加入链表。

3.内存释放：调用 default_free_pages 函数，将已分配的内存块释放并插入空闲链表，同时尝试与相邻的空闲块进行合并，减少碎片化。

4.状态查询：通过 default_nr_free_pages 函数可以查询当前系统中空闲物理页的总数。

5.算法测试：通过 default_check 函数可以对内存管理的各个步骤进行测试，验证分配和释放的正确性。
各个函数的作用已经在上面详细介绍过了，在这里不做赘述。
这个程序维护了一个空闲链表，管理了空闲内存块的分配和释放。关键函数包括初始化、内存块的初始化、页面的分配与释放，以及相关的检查函数以确保内存管理的正确性。最终，通过default_pmm_manager结构体将这些函数绑定在一起，形成一个完整的内存管理器模块。

**改进空间：**
1.碎片化问题
first fit算法可能导致外部碎片的积累，因为它只是找到第一个满足需求的块，这个块可能会比需要的空间大很多，也可能只比需要的空间大一点点，导致切分后得到的小块无法满足我们最小的需求，只能一直保留。
一个可能的改进是使用更高级的分配策略，如Best-Fit、Next-Fit、伙伴系统等，这些算法尝试选择尺寸更接近请求的块，从而减少碎片化。

2.开销
每次都是从低址部分查找，使得查找空闲分区的开销增大；每次查询第一块符合条件的空闲内存块时，最坏情况需要找遍整个链表，时间复杂度是O（N）。
尝试使用平衡二叉树等结构维护空闲块，其中按照中序遍历得到的空闲块序列的物理地址恰好按照从小到大排序，每个二叉树节点上维护该节点为根的子树上的最大的空闲块的大小。使用二分查找查找到物理地址最小的能够满足条件的空闲地址块。

3.优化内存块的管理
在当前实现中，内存块的插入和删除操作可能导致链表频繁调整，影响性能。
可以缓存最近使用的内存块：通过缓存最近分配或释放的内存块，可以提高局部性，减少链表遍历的时间。
使用位图或其他压缩数据结构：对于内存块的管理，可以考虑使用位图等压缩数据结构，以减少内存开销和提高查找速度。

4.支持更复杂的内存分配策略
first-fit 算法虽然简单，但在某些场景下表现不佳，特别是在高并发或实时系统中。
可以实现多种分配策略：根据不同的应用场景，动态选择最合适的分配策略（如 first-fit、best-fit、next-fit 等），以提高整体性能。
引入延迟合并：在某些情况下，可以延迟合并空闲块，避免频繁的内存操作，提高系统响应速度。

5.增强内存管理的鲁棒性
当前实现对错误处理和边界情况的处理可能不够完善，容易导致内存泄漏或系统崩溃。
增加更多的断言和错误检查：在关键操作前后增加断言和错误检查，确保内存管理的正确性和稳定性。
实现内存保护机制：通过内存保护机制，防止非法访问和越界操作，增强系统的安全性。
# 练习2：实现 Best-Fit 连续物理内存分配算法（需要编程）

在完成练习一后，参考**kern/mm/default_pmm.c**对First Fit算法的实现，编程实现Best Fit页面分配算法，算法的时空复杂度不做要求，能通过测试即可。 请在实验报告中简要说明你的设计实现过程，阐述代码是如何对物理内存进行分配和释放，并回答如下问题：
##### <span style="background:rgba(240, 167, 216, 0.55)">你的 Best-Fit 算法是否有进一步的改进空间？</span>

### 物理内存分配过程及相关函数
实现过程应该包括以下步骤：
1.初始化物理内存管理器，设置 free_list 和 nr_free 。
best_fit_init：物理内存管理器的初始化函数。用于初始化空闲内存块列表 free_list 并将空闲内存块数量 nr_free 设置为0。这个函数在系统启动时调用，一次性初始化物理内存管理器。

2.在系统启动时，通过调用 best_fit_init_memmap 函数初始化可用的物理页面。
best_fit_init_memmap：用于初始化内存映射。在系统启动时，内核需要知道哪些物理页面是可用的，default_init_memmap函数被用于初始化这些可用页面。遍历一个内存块中的每一页，初始化每一页的属性，包括标志 flags 和属性 property；然后将引用计数 ref 设置为0，并将这些页面添加到 free_list 列表中，以表示它们是可用的；更新 nr_free 变量，表示可用页面的总数量。

```c
static void best_fit_init_memmap(struct Page *base, size_t n) {
    assert(n > 0);
    struct Page *p = base;
    for (; p != base + n; p ++) {
        assert(PageReserved(p));
        /*LAB2 EXERCISE 2: YOUR CODE:2212731*/ 
        // 清空当前页框的标志和属性信息，并将页框的引用计数设置为0
        p->flags = 0;
        p->property = 0;
        set_page_ref(p, 0);
    }
     -------省略掉一部分-------
     else {
        list_entry_t* le = &free_list;
        while ((le = list_next(le)) != &free_list) {
            struct Page* page = le2page(le, page_link);
             /*LAB2 EXERCISE 2: YOUR CODE:2212731*/ 
            // 编写代码
            // 1、当base < page时，找到第一个大于base的页，将base插入到它前面，并退出循环
            if(base<page)
            {
                list_add_before(le,&(base->page_link));
                break;
            }
            // 2、当list_next(le) == &free_list时，若已经到达链表结尾，将base插入到链表尾部
            if(list_next(le)==&free_list)
            {
                list_add(le,&(base->page_link));
            }
        }
    }
}
```

3.在进程或内核代码中，使用 best_fit_alloc_pages 函数来分配物理页面，并使用  best_fit_free_pages 函数来释放页面。
best_fit_alloc_pages函数：用于分配指定数量的物理页面，实现了第一适应内存分配算法。遍历 free_list 列表，查找满足需求的空闲页框。如果找到满足需求的页面，记录该页面以及当前找到的最小连续空闲页框数量。最终获得满足需求且连续空闲页数量最少的块，分配其中的页面，并将剩余的页面添加回 free_list 列表。如果没有找到满足条件的块，返回NULL。

```c
static struct Page * best_fit_alloc_pages(size_t n) {
    assert(n > 0);
    if (n > nr_free) {
        return NULL;
    }
    struct Page *page = NULL;
    list_entry_t *le = &free_list;
    size_t min_size = nr_free + 1;
     /*LAB2 EXERCISE 2: YOUR CODE:2212731*/ 
    // 下面的代码是first-fit的部分代码，请修改下面的代码改为best-fit
    // 遍历空闲链表，查找满足需求的空闲页框
    // 如果找到满足需求的页面，记录该页面以及当前找到的最小连续空闲页框数量
    while ((le = list_next(le)) != &free_list) {
        struct Page *p = le2page(le, page_link);
        if (p->property >= n&&p->property<min_size) {
            page = p;
            min_size=p->property;
        }
    }

    if (page != NULL) {
        list_entry_t* prev = list_prev(&(page->page_link));
        list_del(&(page->page_link));
        if (page->property > n) {
            struct Page *p = page + n;
            p->property = page->property - n;
            SetPageProperty(p);
            list_add(prev, &(p->page_link));
        }
        nr_free -= n;
        ClearPageProperty(page);
    }
    return page;
}
```

best_fit_free_pages函数：用于释放一组连续的物理页面，将这些页面添加回 free_list 列表，并尝试合并相邻的空闲块，以最大程度地减少碎片化；更新 nr_free 变量以反映可用页面的数量。

```c
static void best_fit_free_pages(struct Page *base, size_t n) {
    -------省略掉一部分代码--------
    /*LAB2 EXERCISE 2: YOUR CODE:2212731*/ 
    // 编写代码
    // 具体来说就是设置当前页块的属性为释放的页块数、并将当前页块标记为已分配状态、最后增加nr_free的值
    base->property = n;
    SetPageProperty(base);
    nr_free += n;

    if (list_empty(&free_list)) {
        list_add(&free_list, &(base->page_link));
    } else {
        list_entry_t* le = &free_list;
        while ((le = list_next(le)) != &free_list) {
            struct Page* page = le2page(le, page_link);
            if (base < page) {
                list_add_before(le, &(base->page_link));
                break;
            } else if (list_next(le) == &free_list) {
                list_add(le, &(base->page_link));
            }
        }
    }

    list_entry_t* le = list_prev(&(base->page_link));
    if (le != &free_list) {
        p = le2page(le, page_link);
        /*LAB2 EXERCISE 2: YOUR CODE:2212731*/ 
         // 编写代码
        // 1、判断前面的空闲页块是否与当前页块是连续的，如果是连续的，则将当前页块合并到前面的空闲页块中
        // 2、首先更新前一个空闲页块的大小，加上当前页块的大小
        // 3、清除当前页块的属性标记，表示不再是空闲页块
        // 4、从链表中删除当前页块
        // 5、将指针指向前一个空闲页块，以便继续检查合并后的连续空闲页块
         if (p + p->property == base) {//1
            p->property += base->property;//2
            ClearPageProperty(base);//3
            list_del(&(base->page_link));//4
            base = p;//5
        }
    }
    ------省略掉一部分代码----------
}
```

4.定期调用 best_fit_check 函数来检查物理内存管理器的正确性，以确保它正常工作。
best_fit_nr_free_pages函数：用于查询可用页面的数量，返回 nr_free 变量的值，表示当前系统中可用的物理页面数量。
best_fit_check函数：用于检查物理内存管理器的正确性。执行一系列内存分配和释放操作，并检查各个步骤的结果是否符合预期。这有助于确保物理内存管理器的正确性和稳定性。

### 改进空间
1.开销
未改变维护空闲块的数据结构，每次仍然从低址部分查找，使得查找空闲分区的开销增大；每次查询符合条件的最小空闲内存块时，最坏情况需要找遍整个链表，时间复杂度是O（N）。

改进：尝试使用平衡二叉树等结构维护空闲块，其中按照中序遍历得到的空闲块序列的物理地址恰好按照从小到大排序，每个二叉树节点上维护该节点为根的子树上的最大的空闲块的大小。使用二分查找查找到物理地址最小的能够满足条件的空闲地址块，平均复杂度为O(logn)。
# Challenge1设计文档：Buddy System 分配器的实现

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
```context
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
# Challenge2-SLUB 分配器设计文档

## 1. 引言
SLUB（SLOB-like Unbounded Buddy）算法是一种内存分配器，旨在高效地管理内存块的分配和释放。SLUB算法实现了两层架构的内存分配，其中第一层基于页面大小进行内存管理，第二层则在此基础上实现任意大小的内存分配。本文档将详细描述SLUB算法的设计思路、数据结构、核心功能以及测试用例。
## 2. 设计目标
- **灵活性**：支持不同大小的内存请求，既能处理小块内存，也能处理大块内存。
- **内存碎片化控制**：通过合并相邻的空闲块，减少内存碎片，提高内存利用率。
## 3. 数据结构
  SLUB算法使用两种主要的数据结构来管理内存：小块结构（small_block_t）和大块结构（big_block_t）。
### 3.1 小块结构（small_block_t）
  ```c
  typedef struct small_block {
    int size_units; // 块的大小，以单位表示
    struct small_block *next; // 下一个空闲块
  } small_block_t;
  ```
- **size_units**: 表示块的大小，以`small_block_t`结构的大小为单位，便于管理和计算。
- **next**: 指向下一个空闲块的指针，形成一个循环链表，方便内存块的遍历与管理。
### 3.2 大块结构（big_block_t）
  ```c
  typedef struct big_block {
    int order; // 内存页的数量
    void *pages; // 指向实际内存的指针
    struct big_block *next; // 下一个大块的指针
  } big_block_t;
  ```
- **order**: 表示所分配内存的页数，支持大块内存的管理。
- **pages**: 指向实际分配的内存块，通常是从操作系统请求的连续内存页。
- **next**: 指向下一个大块的指针，形成一个链表，方便大块的遍历与释放。
### 3.3 自定义常量
- **SMALL_UNIT**: 设定为`small_block_t`结构的大小，用于后续的内存请求转换。
- **SIZE_TO_UNITS(size)**: 宏定义，将字节大小转换为`small_block_t`单位，以确保分配请求的准确性。
## 4. 内存分配与释放
  SLUB算法的内存分配和释放分为两层：小块分配与大块分配。
### 4.1 小块分配（allocate_small_block）
  ```c
  static void *allocate_small_block(size_t size) {
    assert(size < PGSIZE); // 确保请求的大小小于页面大小
  
    small_block_t *prev = free_list_head;
    small_block_t *curr;
  
    int required_units = SIZE_TO_UNITS(size); // 计算所需的单位数
  
    for (curr = prev->next; ; prev = curr, curr = curr->next) {
        if (curr->size_units >= required_units) { // 找到足够大的块
            if (curr->size_units == required_units) {
                prev->next = curr->next; // 完全匹配，移除当前块
            } else {
                prev->next = (small_block_t *)((char *)curr + required_units *
                SMALL_UNIT);
                prev->next->size_units = curr->size_units - required_units;
                prev->next->next = curr->next;
                curr->size_units = required_units; // 更新当前块大小
            }
            free_list_head = prev; // 更新空闲链表头
            return curr; // 返回分配的内存块
        }
        if (curr == free_list_head) { // 返回到链表头，表示没有足够的块
            if (size == PGSIZE) return NULL; // 如果请求的大小为页面大小，返回 NULL
            curr = (small_block_t *)alloc_pages(1); // 分配一个新页面
            if (!curr) return NULL; // 分配失败
            free_small_block(curr, PGSIZE); // 初始化新页面
            curr = free_list_head; // 更新当前块
        }
    }
  }
  ```
1. **预检查**: 在代码中，使用`assert(size < PGSIZE);`确保请求的大小小于页面大小，以防止无效请求。
2. **遍历空闲链表**: 通过`for`循环遍历空闲链表，从`free_list_head`开始，寻找满足请求大小的空闲块，并计算所需的单位数。
3. **满足条件的处理**: 如果找到完全匹配的空闲块，则通过链表操作将其移除并返回其指针；如果当前块大于请求大小，则进行分割，并更新链表。
4. **未找到合适块**: 如果遍历回到链表头，表示没有足够大的块，代码通过`alloc_pages(1);`尝试分配一个新页面，并初始化该页面为小块，再次尝试分配。
   - **(char )curr:**
     - 将 `curr` 指针强制转换为 `char *` 类型。由于 `char` 类型的指针可以在字节级别进行算术运算，这样做的目的是方便进行内存地址的加法运算。
- **required_units * SMALL_UNIT**:
    - 计算所需的字节数。`required_units` 表示所请求的内存单位数量，而 `SMALL_UNIT` 是每个 `small_block_t` 结构的大小（以字节为单位）。
    - 这个乘法结果表示在内存中要跳过的字节数，从而得到分配后剩余空闲块的起始地址。
- **((char )curr + required_units * SMALL_UNIT)**:
    - 将 `curr` 指针的地址加上计算得到的字节数，得到下一个空闲块的地址。这一地址对应的是在当前块中，分配所需大小后剩余部分的起始位置。
- **(small_block_t *)**: 
    - 将计算得到的地址强制转换回 `small_block_t *` 类型，以便赋值给 `prev->next`。这表明 `prev->next` 将指向剩余的空闲块。
### 4.2 小块释放（free_small_block）
```c
    static void free_small_block(void *block, int size) {
    small_block_t *current;
    small_block_t *block_to_free = (small_block_t *)block;
    if (!block) return;
    if (size) block_to_free->size_units = SIZE_TO_UNITS(size); // 设置块的大小
    
    // 查找插入点,如果 `block_to_free` 位于这两个块之间，则表示找到了合适的插入位置，循环将停止(内存地址)
    for (current = free_list_head; !(block_to_free > current && block_to_free < 
    current->next); current = current->next) {
      if (current >= current->next && (block_to_free > current || block_to_free <
    current->next)) {
          break;
      }
    }
    
    // 合并相邻的空闲块
    // 与curr->next相邻
    // 如果 `block_to_free` 的结束地址（起始地址加上大小）正好等于 `current->next` 的起始地址
    if ((char *)block_to_free + block_to_free->size_units * SMALL_UNIT == (char 
    *)current->next) {
      block_to_free->size_units += current->next->size_units; // 合并
      block_to_free->next = current->next->next;
    } else {
    // `current` 是当前遍历到的空闲块，`current->next` 是下一个空闲块。
    // 如果 `block_to_free` 与 `current->next` 不相邻（即没有合并），那么`block_to_free` 应该插入到 `current` 和 `current->next` 之间。
      block_to_free->next = current->next;
    }
    
    // 要释放的块在curr之后
    // 如果 `current` 的结束地址正好等于 `block_to_free` 的起始地址，则这两个块也是相邻的
    // 与curr相邻
    if ((char *)current + current->size_units * SMALL_UNIT == (char 
    *)block_to_free) {
      current->size_units += block_to_free->size_units; // 合并
      current->next = block_to_free->next;
    } else {
      current->next = block_to_free; // 插入到当前块后
    }
    
    free_list_head = current; // 更新空闲链表头
    }
```
1. **检查有效性**: 在函数开始时，如果传入的块指针为空，直接返回。
2. **设置块大小**: 如果指定了大小，则根据传入的大小设置块的`size_units`，以便在后续操作中使用。
3. **查找插入点**: 通过循环遍历空闲链表，确保在插入时维护链表的有序性，处理链表的循环边界情况。
4. **合并相邻空闲块**: 检查当前块与前后空闲块是否相邻，并进行合并操作，更新链表指针，以确保链表结构的完整性。
### 4.3 大块分配（slub_alloc）
```c
void *slub_alloc(size_t size) {
    if (size < PGSIZE - SMALL_UNIT) {
        small_block_t *m = allocate_small_block(size + SMALL_UNIT); // 小块分配
        return m ? (void *)(m + 1) : NULL;
    }

    // 在分配大块内存（比如多个页面）之前，程序需要一个结构体来存储大块的相关信息，如页面数量和实际内存地址。这是通过 big_block_t 结构来管理的。
    // 由于 big_block_t 本身是一个结构体，程序需要分配内存来存储这个结构体，因此调用 allocate_small_block(sizeof(big_block_t))

    // 大块分配
    big_block_t *big_block = allocate_small_block(sizeof(big_block_t));
    if (!big_block) return NULL;
    // 计算所需页面数量
    // PGSHIFT 通常是一个常量，用于定义页面的大小（通常是 4096 字节，即 2^12）。该表达式将请求的内存大小 size 转换为所需的页面数量：
    // (size - 1) >> PGSHIFT：通过右移操作计算完整页面的数量（每个页面大小为 PGSIZE）。
    // + 1 是因为即使请求的内存大小不整除页面大小，也需要一个完整页面来满足请求
    big_block->order = ((size - 1) >> PGSHIFT) + 1;
    big_block->pages = alloc_pages(big_block->order);

    if (big_block->pages) {
        big_block->next = big_block_list;
        big_block_list = big_block;
        return big_block->pages;
    }

    free_small_block(big_block, sizeof(big_block_t)); // 释放失败的块
    return NULL;
}
```
1. **小块请求处理**: 当请求的大小小于页面大小减去小块头部大小时，调用`allocate_small_block`进行小块分配。
2. **大块请求处理**: 对于大块请求，首先分配一个`big_block_t`结构，以管理大块的元数据，然后计算所需的页面数量并调用`alloc_pages`获取实际的内存块。
3. **管理链表**: 如果成功获取内存页，则将其添加到大块链表中，确保大块的管理，同时返回指向分配内存块的指针。 
### 4.4 大块释放（slub_free）
   ```c
   void slub_free(void *block) {
    if (!block) return;
   
    big_block_t *bb, **last = &big_block_list;
   
    if (!((uintptr_t)block & (PGSIZE - 1))) {
        for (bb = big_block_list; bb; last = &bb->next, bb = bb->next) {
            if (bb->pages == block) {
                *last = bb->next;
                free_pages((struct Page *)block, bb->order);
                free_small_block(bb, sizeof(big_block_t)); // 释放大块
                return;
            }
        }
    }
   
    free_small_block((small_block_t *)block - 1, 0); // 释放小块
   }
   ```
1. **检查有效性**: 如果块指针为空，则直接返回。
2. **判断块类型**: 通过位运算检查块是否对齐到页面边界，从而判断其是小块还是大块。如果是大块，则遍历大块链表，找到对应的块，移除并释放相应的页面。
3. **小块释放处理**: 如果是小块，调用`free_small_block`进行释放并合并操作，确保内存管理的正确性。
## 5. 其他功能
### 5.1 内存块大小查询（slub_size）
   ```c
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
   ```
1. **检查有效性**: 如果块指针为空，则返回0。
2. **大块大小处理**: 判断块指针是否对齐到页面边界，如果对齐，则遍历大块链表，返回大块的大小。
3. **小块大小处理**: 对于小块，通过指针访问其元数据，计算并返回块的大小。
### 5.2 空闲链表长度获取（get_free_list_length）
   ```c
   int get_free_list_length() {
    int length = 0;
    for (small_block_t *curr = free_list_head->next; curr != free_list_head; curr
    = curr->next) {
        length++;
    }
    return length;
   }
   ```
1. **遍历空闲链表**: 从空闲链表头开始遍历，计数空闲块的数量，直到回到头部。
2. **返回长度**: 返回计算得到的空闲块数量。
### 5.3 测试功能（slub_test）
```c
    void slub_test() {
     cprintf("SLUB Test Begin\n");
     cprintf("Initial Free list length: %d\n", get_free_list_length());
    
     // 测试小块分配
     void *block1 = slub_alloc(2);
     cprintf("Allocated block1");
     cprintf("Free list length after allocating block1: %d\n",
     get_free_list_length());
    
     // 测试小块释放
     slub_free(block1);
     cprintf("Freed block1\n");
     cprintf("Free list length after freeing block1: %d\n",
     get_free_list_length());
    
     // 测试释放后合并
     void *block2 = slub_alloc(2);
     cprintf("Allocated block2");
     cprintf("Free list length after allocating block2: %d\n", 
     get_free_list_length());
     void *block3 = slub_alloc(2);
     cprintf("Allocated block3");
     cprintf("Free list length after allocating block3: %d\n", 
     get_free_list_length());
     void *block4 = slub_alloc(256);
     cprintf("Allocated block4");
     cprintf("Free list length after allocating block4: %d\n", 
     get_free_list_length());
    
    slub_free(block3);
    cprintf("Freed block3\n");
    cprintf("Free list length after freeing block3: %d\n", get_free_list_length());
    slub_free(block2);
    slub_free(block4);
    cprintf("Freed block4\n");
    cprintf("Free list length after freeing block2&4: %d\n", 
    get_free_list_length());
    
    cprintf("SLUB Test End\n")
}
```
1. **初始化测试**: 通过`printf`输出SLUB测试开始信息和当前空闲链表长度，确保测试环境的初始状态明确。
2. **小块分配与释放测试**:
   - 使用`allocate_small_block(2)`分配小块内存，首次分配会先取一页，再进行小内存分配。
   - 释放分配的小块，并再次输出空闲链表的长度，验证释放操作的正确性。
3. **连续分配测试**:
   - 连续分配三个小内存，先释放第二个分配的内存块，此时空闲链表的长度会加一，然后释放第一个和第三个内存块，空闲链表的长度又减一。
4. **测试结束信息**: 最后输出SLUB测试结束信息，标志着测试的完成。
   测试结果具体内容如下：
```
slub_init() succeeded!
SLUB Test Begin
Initial Free list length: 0
Required units: 2
Current block size: 1
No merge, inserting into the list.
Inserted block without merging.
Current block size: 256
Allocated smaller block, cutting!
Allocated block1Free list length after allocating block1: 1
Merge successful! Free list length will decrease by 1.
Inserted block without merging.
Freed block1
Free list length after freeing block1: 1
Required units: 2
Current block size: 256
Allocated smaller block, cutting!
Allocated block2Free list length after allocating block2: 1
Required units: 2
Current block size: 254
Allocated smaller block, cutting!
Allocated block3Free list length after allocating block3: 1
Required units: 17
Current block size: 252
Allocated smaller block, cutting!
Allocated block4Free list length after allocating block4: 1
No merge, inserting into the list.
Inserted block without merging.
Freed block3
Free list length after freeing block3: 2
Merge successful! Free list length will decrease by 1.
Inserted block without merging.
Merge successful! Free list length will decrease by 1.
Merge successful with previous block! Free list length will decrease by 1.
Freed block4
Free list length after freeing block2&4: 1
SLUB Test End
```
## 6. 结论
   SLUB算法通过两层架构的设计，结合小块与大块的灵活分配策略，实现了高效的内存管理。其数据结构的设计优化了内存的利用率，并通过合并相邻空闲块降低了碎片化程度。经过测试，SLUB算法在分配与释放的准确性上表现良好，为系统的内存管理提供了可靠支持。未来的工作可以集中在进一步优化内存碎片化问题以及提升整体分配速度。
# Challenge3

##### 1. BIOS/UEFI 接口
- **概念**：BIOS（基本输入输出系统）和 UEFI（统一可扩展固件接口）是计算机启动时的固件，它们提供了硬件抽象层。操作系统可以通过这些接口获取系统硬件的信息。
- **实现方法**：
  - 操作系统在启动时会执行 BIOS 或 UEFI 的调用，通常使用特定的接口函数来请求内存信息。
  - 在 UEFI 中，可以调用 `GetMemoryMap` 函数来获取系统的物理内存映射信息，这包括每个内存区域的基址和大小、状态（可用、保留、保留等）等。
##### 2. **内存检测工具**
- **概念**：这些工具专门设计用于检测和验证计算机的内存是否工作正常，并可以显示详细的内存信息。
- **实现方法**：
  - 在操作系统启动之前，可以使用像 `memtest86` 这样的工具来运行内存测试。它通过对所有可用内存区域进行读写操作来检测内存。
  - 操作系统可以在后续启动过程中通过读取这些工具生成的报告来获取可用内存的范围，或在自定义的启动配置中引导这些工具并将其结果传递给内核。
##### 3. **物理内存地址范围映射**
- **概念**：通过直接与硬件交互，操作系统可以探索和验证哪些物理地址是可用的。
- **实现方法**：
  - 操作系统可以选择一个地址范围（如常见的 0x00000000 到 0xFFFFFFFF），并尝试对这些地址执行写操作，随后读取它们以检查值是否一致。
  - 如果可以成功写入和读取，说明该地址是可用的；如果出现访问错误或读取失败，则该地址不可用。
  - 这种方法可以帮助操作系统动态发现可用内存，但会比较耗时并可能影响系统性能。
##### 4. **设备驱动程序**
- **概念**：设备驱动程序负责管理操作系统与硬件之间的交互，它们在系统启动时运行并进行初始化。
- **实现方法**：
  - 当设备驱动程序初始化时，可以查询硬件信息，包括内存映射。它们通常会使用特定的 I/O 控制代码（IOCTL）和接口与操作系统的内核进行交互。
  - 驱动程序可以通过读取控制寄存器或调用系统 API 获取信息，并将结果存储在系统内存中，以便其他系统组件使用。
##### 5. **查看系统日志**
- **概念**：操作系统在启动时通常会记录硬件和内存配置的详细日志。
- **实现方法**：
  - 在操作系统启动过程中，内核会记录内存的初始化状态，包括检测到的可用和不可用的内存区域。
  - 操作系统可以在运行时分析这些日志文件（如 `dmesg` 输出），提取和解析有关物理内存的信息，以更新其内存管理策略。
##### 6. **使用现有内存管理机制**
- **概念**：操作系统有内存管理子系统，可以利用它来动态发现物理内存。
- **实现方法**：
  - 操作系统可以使用分页机制跟踪每个页面的状态。在启动时，所有页面都标记为未使用，然后在分配内存时将状态更新为已使用。
  - 通过分析页面的分配情况，操作系统能够实时更新其对可用物理内存的理解。