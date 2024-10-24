# Lab2

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
}```
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