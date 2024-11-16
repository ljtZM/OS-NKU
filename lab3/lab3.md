## 练习一：理解基于FIFO的页面替换算法（思考题)

描述FIFO页面置换算法下，一个页面从被换入到被换出的过程中，会经过代码里哪些函数/宏的处理（或者说，需要调用哪些函数/宏），并用简单的一两句话描述每个函数在过程中做了什么？（为了方便同学们完成练习，所以实际上我们的项目代码和实验指导的还是略有不同，例如我们将FIFO页面置换算法头文件的大部分代码放在了`kern/mm/swap_fifo.c`文件中，这点请同学们注意）>=10个
回答：在FIFO页面置换算法下，页面换入换出过程中，会经过以下函数/宏处理：
首先，在实际触发页异常的时候，会进入trap/trap.c文件，并通过其中的**pgfault_handler()** 处理函数：

```cpp
print_pgfault(tf);
if (check_mm_struct != NULL) {
    return do_pgfault(check_mm_struct, tf->cause, tf->badvaddr);
}
```

过程中 **print_pgfault()** 打印错误信息并将之转交给**do_pgfault()** 函数处理（进入mm/vmm.c文件）。

1. **`do_pgfault`**:
   
   - **功能**: 访问页面缺失时，进入该函数进行处理。
   - `do_pgfault(check_mm_struct, tf->cause, tf->badvaddr)`

2. **`assert`**:
   
   - **功能**: 用于逐步验证程序执行的正确性。在页面置换过程中，`assert`被用来确保不同阶段的页面访问次数与预期一致，帮助检查置换是否发生。

3. **`find_vma`**:
   
   - **功能**: 在do_pgfault（）中被调用，在指定的内存管理结构mm_struct中查找与给定地址addr相关联的虚拟内存区vma_struct（判断地址是否合法）。
   - `find_vma(struct mm_struct *mm, uintptr_t addr)`

4. **`get_pte`**:
   
   - **功能**: 随后在在do_pgfault（）中被调用，若合法，则获取该虚拟地址对应的页表项。函数通过多级页目录检查并创建缺失页表项，以确保指定的逻辑地址对应的页表项存在并返回其指针。即依次判断，二级页目录项，一级页目录项，页表项是否存在，若不存在则分配新的项给这些部分。如果页表项全零，这个时候就会调用 pgdir_alloc_page 。首先会调用alloc_page 函数。
   - `get_pte(mm->pgdir, addr, 1)`

5. **`alloc_page`**:
   
   - **功能**: 在pgdir_alloc_page()中首先被调用（struct Page *page = alloc_page();进入文件mm/pmm.c）分配指定数量的页并返回一个指向分配的页的指针，如果内存不足且条件允许（例如交换机制已初始化），则尝试通过交换机制释放内存，确保分配成功。
   - 补充：在pmm.h中有宏定义`#define alloc_page() alloc_pages(1)`故而实际使用了`alloc_pages()`
   - `alloc_pages(size_t n)`

6. **`swap_out`**:
   
   - **功能**:在alloc_pages()中进行调用（定义在mm/swap.c中），将一定数量的内存页从物理内存中换出到磁盘上的交换区，以释放物理内存供其他需求使用。
   - 步骤：循环存储；choose victim_pages；get_pte()选择获取页面对应的页表项；swapfs_write() 函数将页面写入磁盘的交换空间；tlb_invalidate()。
   - `swap_out(struct mm_struct *mm, int n, int in_tick)`

7. **`_fifo_swap_out_victim`**:
   
   - **功能**: 在swapout步骤二中使用，基于FIFO（先进先出）策略选择一个受害页（victim page）以进行换出。它从 `mm_struct` 的页面管理队列中找到最早插入的页，将其从队列中移除，并返回给调用者。
   - `_fifo_swap_out_victim(struct mm_struct *mm, struct Page ** ptr_page, int in_tick)`

8. **`swapfs_write`**:
   
   - **功能**: 步骤四中使用，把要换出页面的内容保存到硬盘中（fs/swapfs.c）。
   - `swapfs_write(swap_entry_t entry, struct Page *page)`

9. **`swap_in`**:
   
   - **功能**: 回到do_pgfault()，在当时若存在页表项，说明之前有映射关系，但是对应的物理页被换出，现在需要换入。
   - `swap_in(struct mm_struct *mm, uintptr_t addr, struct Page **ptr_result)`

10. **`swapfs_read()`**:
    
    - **功能**: 在in中被调用，调用内存和硬盘的I/O接口，读取硬盘中相应的内容到一个内存的物理页，实现换入过程。
    - `swapfs_read((*ptep)`

11. **`page_insert`**:
    
    - **功能**: 在in之后调用，根据换入的页面和虚拟地址建立映射，插入新的页表项，刷新TLB。
    
    - `page_insert(mm->pgdir, page, addr, perm);`

12. **`tlb_invalidate`**:
    
    - **功能**: 刷新TLB
    
    - `tlb_invalidate(pde_t *pgdir, uintptr_t la)`

13. **`swap_map_swappable->_fifo_map_swappable`**:
    
    - **功能**: 在insert之后调用，实际用了_fifo_map_swappable根据 FIFO（先进先出）页面替换算法，将最近到达的页面链接到pra_list_head 队列的末尾。
    
    - sm->map_swappable(mm, addr, page, swap_in);.map_swappable   = &_fifo_map_swappable。
    
    - `_fifo_map_swappable(struct mm_struct *mm, uintptr_t addr, struct Page *page, int swap_in)`

14. **`list_add`**:
    
    - **功能**: 13的最后调用，为了将新的页面插入队列中而调用的函数。
    
    - `list_add(list_entry_t *listelm, list_entry_t *elm) __attribute__((always_inline))`

15. **`free_page`**:
    
    - **功能**: 释放页面，完成换出。(这个在pgdir_alloc_page()就有，当时没有看到)
    
    - `free_page(page)`

16. **补充（mm/swap_fifo.c中）**：
    
    - `_fifo_check_swap()`:检查页置换算法中的FIFO算法是否正常工作——在不同的虚拟地址写入不同的值，并使用断言来检查页面错误的次数是否符合预期。
    
    - `swap_init()`:系统启动时进行交换空间的初始化操作，使用FIFO的页面置换算法进行交换管理。

## 练习二

#### 深入理解不同分页模式的工作原理

##### sv32、sv39、sv48的异同

这三个分页模式主要在地址位数和页表的层级上存在差异：

1. **虚拟地址空间大小**：
   
   - sv32：32位虚拟地址，支持4GB的虚拟地址空间。
   - sv39：39位虚拟地址，支持高达512GB的虚拟地址空间。
   - sv48：48位虚拟地址，支持高达256TB的虚拟地址空间。

2. **页表层级**
   
   - sv32：页表有2级（页目录和页表）。
   
   - sv39：页表有3级（页目录、页中间表和页表）。
   
   - sv48：页表有4级（页目录、页中间表、页表和页表项）。支持Sv48的系统还必须支持Sv39，以便与假设Sv39的监督软件兼容。
   
   - 主要体现在地址空间的位数和对应的索引计算上。具体的 `PDX`、`PTX` 宏的实现会有所不同，以适应不同的地址空间和页表结构。
     
     #### get_pte()函数中有两段形式类似的代码， 结合sv32，sv39，sv48的异同，解释这两段代码为什么如此相像。
     
     `get_pte()` 函数的目的是查找或创建对应于指定线性地址的页表项。函数中主要的工作流程包括：

3. **查找页目录项**：首先，通过线性地址 `la` 计算出页目录项的索引 `PDX1(la)`。检查该目录项是否有效（即是否存在）。

4. **创建页目录项**：如果目录项无效且需要创建（`create` 为 `true`），则分配新的物理页面，并将其映射到页目录项。

5. **查找页表项**：通过目录项获取页表的基地址，再根据线性地址计算出页表项的索引 `PDX0(la)`。

6. **创建页表项**：如果页表项无效，同样进行创建。

代码的结构非常相似，主要是因为无论是 sv32、sv39 还是 sv48，页表的查找和创建逻辑都是相似的：都是依次按照多级页表的映射关系，找到下一级的页目录或者页表项，如果出现了不存在或者不有效的情况，就进行了重新分配，执行相应的内存分配和初始化。不同的是，页表的层级数量和每个层级的索引计算方法会有所不同，如果是**sv32**则只需要进行一次pdep然后直接返回就可以得到页表项，这是因为其只有两层页表关系；而**sv48**则还需要多一层页表递进关系，因此需要pdep2,pdep1和pdep0然后才能返回。但总体逻辑是相同的。

#### 目前get_pte()函数将页表项的查找和页表项的分配合并在一个函数里，你认为这种写法好吗？有没有必要把两个功能拆开？

这种写法好。`get_pte` 函数用于在虚拟地址（`la`）和页表之间进行转换，并返回指向该地址对应的页表项的指针。主要用途是在操作系统内核进行内存管理时，将虚拟地址映射到物理内存地址。
使用get_pte()的地方就是在的do_pgfault()中，即发生缺页异常时候的处理。我们只有在获取页表非法的情况下才会创建页表，而且我们也只关心最后一级页表所给出的页，合在一起减少了代码重复和函数调用的开销及深度，使代码更简洁。
也就是说，如果将查找和分配合在一起，那么我们可以在层次递进映射依次取出每一级的页表或者页目录项时候就去查看一下其是否缺失，由此进行针对性的分配和弥补缺失。
将 `get_pte()` 函数分成两个单独的函数后，我们可以定义 `find_pte()` 来专门执行页表项的查找操作，以及 `allocate_pte()` 来处理页表项的分配操作。
`find_pte()` 函数负责查找给定虚拟地址的页表项。如果该页表项存在，则返回其指针；如果不存在，则返回 `NULL`。

```c
pte_t* find_pte(pde_t* pgdir, uintptr_t la) {
    // 获取第一级页目录项指针
    pde_t* pdep1 = &pgdir[PDX1(la)];
    if (!(*pdep1 & PTE_V)) {
        return nullptr;  // 如果一级页目录项无效，返回 NULL
    }

    // 获取第二级页表项指针
    pde_t* pdep0 = &((pde_t*)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
    if (!(*pdep0 & PTE_V)) {
        return nullptr;  // 如果二级页表项无效，返回 NULL
    }

    // 返回三级页表项的指针
    return &((pte_t*)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
}
```

这样处理的问题就是会导致即使中间一部分的某个页目录或者页表项实际上是不存在的，那么我们在外面仅根据函数返回值为NULL的结果是无法确定其究竟是在三级页表的哪一层造成了缺失导致的问题。我们也没有办法针对性对其重新分配，即使去查看究竟哪一步出现的问题也会导致不必要的查找的时间损耗。

## 练习三

#### 设计实现过程

do_pgdefault函数用于处理缺页异常，核心目的是在访问一个不存在或未映射的页面时进行处理，以便确保程序能够继续执行。
使用 `get_pte` 获取对应于该地址的页表项 (PTE)。如果对应的页表不存在，则创建一个。
在之后使用了if进行判断：

```c
if (*ptep == 0)
```

如果 `ptep` 指向的页表项为空，表示该页面还没有分配。调用 `pgdir_alloc_page` 分配页面并建立地址映射。
然而如果不是空项，说明物理页不存在于内存中，而在磁盘中，表明需要进行页交换处理。那么使用swap_in函数来将需要的物理页读入内存，代码如下所示：

```c
// 处理交换情况:
if (swap_init_ok) {
// 调用 swap_in 从交换设备加载页面内容到内存
//使用 page_insert 建立物理地址和线性地址之间的映射。
//调用 swap_map_swappable 标记页面为可交换状态。
    struct Page *page = NULL;
    swap_in(mm, addr, &page); // 分配一个内存页并从磁盘上的交换文件加载数据到该内存页
    page_insert(mm->pgdir, page, addr, perm); // 建立内存页 page 的物理地址和线性地址 addr 之间的映射
    swap_map_swappable(mm, addr, page, 1);    // 将页面标记为可交换
    page->pra_vaddr = addr;                   // 跟踪页面映射的线性地址
}
```

#### 请描述页目录项（Page Directory Entry）和页表项（Page Table Entry）中组成部分对ucore实现页替换算法的潜在用处。

##### 1. 算法选择

- **访问位（Accessed Bit）**:
  
  - 在实现如最近最少使用（LRU）和时钟算法时，**访问位**提供了一个页面是否被访问的快速指示。对于LRU，页面的访问历史决定了哪些页面应该被保留在内存中，而哪些可以被替换。
  - 在时钟算法中，当指针指向某一页面时，如果该页面的访问位为1，则将其设置为0，指向下一个页面；如果为0，则可以选择替换。

- **修改位（Dirty Bit）**:
  
  - **修改位**帮助决定页面的替换时机。对于一个被修改过的页面，系统需要在替换之前将其写回磁盘，以防数据丢失。
    
    ##### 2. 性能优化

- **减少不必要的磁盘 I/O**:
  
  - 通过**访问位**，系统可以判断哪些页面最近被使用，从而优先保留这些页面在内存中，减少对磁盘的访问频率。访问位未被设置的页面通常可以被优先替换。
  
  - **修改位**的应用则确保只有在必要时（即页面被修改过时）才执行写回操作。这样可以显著减少不必要的 I/O，尤其是在高负载情况下。
    
    ##### 3. 优先级管理

- **用户页与内核页的区别**:
  
  - 不同类型的页面具有不同的重要性。内核页通常比用户页更为关键，且经常被访问。通过访问位和修改位，系统可以优先保留内核页在内存中，确保系统的稳定性和响应速度。替换算法可以利用**用户/内核位**来判断不同类型的页面在替换时的优先级。

- **动态调整优先级**:
  
  - 根据系统的负载情况和页面的访问模式，动态调整页面的优先级。例如，长时间未被访问的用户页可以被标记为低优先级，便于替换；而频繁访问的内核页则应始终保持在内存中。
    
    ##### 4. 权限控制

- **区分读写权限**：
  
  - **读写位**指示该页面的访问权限。如果该位被设置为可写，用户程序可以对该页面进行写操作；如果未设置，则只能进行读取。这有助于保护内存中的数据，防止非法写入。

- **确保数据的完整性**：
  
  - 通过标记读写权限，操作系统可以确保只有授权的进程可以修改特定数据，从而维护数据的一致性和安全性。
    
    #### 如果ucore的缺页服务例程在执行过程中访问内存，出现了页访问异常，请问硬件要做哪些事情？

调用图：trap--> trap_dispatch-->pgfault_handler-->do_pgfault
处理器将导致异常的 32 位线性地址加载到 CR2 寄存器中

- 首先保存当前异常原因，根据`stvec`的地址跳转到中断处理程序，即`trap.c`文件中的`trap`函数。
  
  ```c
  void trap(struct trapframe *tf) {
    // dispatch based on what type of trap occurred
    if ((intptr_t)tf->cause < 0) {
        // interrupts
        interrupt_handler(tf);
    } else {
        // exceptions
        exception_handler(tf);
    }
  }
  ```

- 接着跳转到`exception_handler`中的`CAUSE_LOAD_ACCESS`处理缺页异常。
  
  ```c
  void exception_handler(struct trapframe *tf) {
    int ret;
    switch (tf->cause) {
        case CAUSE_MISALIGNED_FETCH:
            cprintf("Instruction address misaligned\n");
            break;
        case CAUSE_FETCH_ACCESS:
            cprintf("Instruction access fault\n");
            break;
        case CAUSE_ILLEGAL_INSTRUCTION:
            cprintf("Illegal instruction\n");
            break;
        case CAUSE_BREAKPOINT:
            cprintf("Breakpoint\n");
            break;
        case CAUSE_MISALIGNED_LOAD:
            cprintf("Load address misaligned\n");
            break;
        case CAUSE_LOAD_ACCESS:
            cprintf("Load access fault\n");
            if ((ret = pgfault_handler(tf)) != 0) {
                print_trapframe(tf);
                panic("handle pgfault failed. %e\n", ret);
            }
            break;
        case CAUSE_MISALIGNED_STORE:
            cprintf("AMO address misaligned\n");
            break;
        case CAUSE_STORE_ACCESS:
            cprintf("Store/AMO access fault\n");
            if ((ret = pgfault_handler(tf)) != 0) {
                print_trapframe(tf);
                panic("handle pgfault failed. %e\n", ret);
            }
            break;
        case CAUSE_USER_ECALL:
            cprintf("Environment call from U-mode\n");
            break;
        case CAUSE_SUPERVISOR_ECALL:
            cprintf("Environment call from S-mode\n");
            break;
        case CAUSE_HYPERVISOR_ECALL:
            cprintf("Environment call from H-mode\n");
            break;
        case CAUSE_MACHINE_ECALL:
            cprintf("Environment call from M-mode\n");
            break;
        case CAUSE_FETCH_PAGE_FAULT:
            cprintf("Instruction page fault\n");
            break;
        case CAUSE_LOAD_PAGE_FAULT:
            cprintf("Load page fault\n");
            if ((ret = pgfault_handler(tf)) != 0) {
                print_trapframe(tf);
                panic("handle pgfault failed. %e\n", ret);
            }
            break;
        case CAUSE_STORE_PAGE_FAULT:
            cprintf("Store/AMO page fault\n");
            if ((ret = pgfault_handler(tf)) != 0) {
                print_trapframe(tf);
                panic("handle pgfault failed. %e\n", ret);
            }
            break;
        default:
            print_trapframe(tf);
            break;
    }
  }
  ```

- 然后跳转到`pgfault_handler`，再到`do_pgfault`具体处理缺页异常。
  
  ```c
  static int pgfault_handler(struct trapframe *tf) {
    extern struct mm_struct *check_mm_struct;
    print_pgfault(tf);
    if (check_mm_struct != NULL) {
        return do_pgfault(check_mm_struct, tf->cause, tf->badvaddr);
    }
    panic("unhandled page fault.\n");
  }
  ```

- 如果处理成功，则返回到发生异常处继续执行。

- 否则输出`unhandled page fault`。
  
  #### 数据结构Page的全局变量（其实是一个数组）的每一项与页表中的页目录项和页表项有无对应关系？如果有，其对应关系是啥？
  
  有对应关系。
1. **页目录项（PDE）**：每个 PDE 对应一组页表，页表则会进一步指向具体的物理页面。
2. **页表项（PTE）**：每个 PTE 指向具体的物理页面。当一个虚拟地址被访问时，处理器会根据页目录和页表查找相应的 PTE，而 PTE 中保存的物理页面地址则指向 `Page` 数组中的一个项。这意味着每个 PTE 直接对应一个 `Page` 结构，表明该虚拟页面映射到哪个物理页面。
3. **对应关系**：
   - **PDE** -> 指向页表。
   - **PTE** -> 指向具体的物理页面，映射到 `Page` 数组中的某一项。`Page` 结构体数组的每一项都代表着一个物理页面，并且可以通过页表项间接关联。页表项存储物理地址信息，这又可以用来索引到对应的 `Page` 结构体，从而允许操作系统管理和跟踪物理内存的使用。

## 练习四：补充完成Clock页替换算法（需要编程）

通过之前的练习，相信大家对FIFO的页面替换算法有了更深入的了解，现在请在我们给出的框架上，填写代码，实现 Clock页替换算法（mm/swap_clock.c）。(提示:要输出curr_ptr的值才能通过make grade)

请在实验报告中简要说明你的设计实现过程。请回答如下问题：

- 比较Clock页替换算法和FIFO算法的不同。

### 实验过程

Clock（时钟）页替换算法是一种改进的**FIFO页替换算法**，它利用页面的访问位来减少不必要的页面替换操作。该算法结合了**LRU**的思想，能够更高效地选择换出页面。

**基本原理**在于假设每个页面都有一个访问位，其状态决定了页面是否最近被使用过：

- **访问位为 1**：页面最近被访问过，不宜换出。
- **访问位为 0**：页面“较长”时间未被访问，可以换出。

基本算法流程为通过循环遍历页面队列，并结合访问位的信息，决定要替换的页面：

- **页面访问位初始化**：为每个物理页框维护一个额外的访问位。

- **维护页面队列**：创建一个循环队列/链表，保存物理页框。

- **指针设置**：队列中的每个页框都关联一个指向页面的指针以及一个对应初始值为0的访问位。

- **检查访问位**：页面需要替换时，遍历队列，检查当curr访问位：
  
  - **访问位为0**：选中该页面作为换出页面，更新队列指针，以便下一次替换时从下一个页面开始检查。
  - **访问位为1**：表示页面最近被访问过，将访问位清零并移动指针到下一个页面。

- ```cpp
  sm = &swap_manager_clock;
  ```

实验代码如下（完成各个函数）：

- **_clock_init_mm**

```cpp
static int
_clock_init_mm(struct mm_struct *mm)
{     
     /*LAB3 EXERCISE 4: 2211819 2212731 2212023*/ 
     // 初始化pra_list_head为空链表
     // 初始化当前指针curr_ptr指向pra_list_head，表示当前页面替换位置为链表头
     // 将mm的私有成员指针指向pra_list_head，用于后续的页面替换算法操作

    list_init(&pra_list_head);
    curr_ptr = &pra_list_head;
    mm->sm_priv = &pra_list_head;
    cprintf(" mm->sm_priv %x in fifo_init_mm\n",mm->sm_priv);
     return 0;
}
```

初始化算法所需的数据结构，使用list_init初始化一个链表头`pra_list_head` （为空）和两个指针` curr_ptr` 和 `mm->sm_priv`，分别指向表头和pra_list_head。

- **_clock_map_swappable**

```cpp
static int
_clock_map_swappable(struct mm_struct *mm, uintptr_t addr, struct Page *page, int swap_in)
{
    list_entry_t *entry=&(page->pra_page_link);

    assert(entry != NULL && curr_ptr != NULL);
    //record the page access situlation
    /*LAB3 EXERCISE 4: 2211819 2212731 2212023*/ 
    // link the most recent arrival page at the back of the pra_list_head qeueue.
    // 将页面page插入到页面链表pra_list_head的末尾
    // 将页面的visited标志置为1，表示该页面已被访问
    list_entry_t *head = (list_entry_t *) mm->sm_priv;
    list_add(head, entry);
    page->visited = 1;
    curr_ptr = entry;
    cprintf("curr_ptr %p\n", curr_ptr);
    return 0;
}
```

将新访问的页面加入到替换队列中，并更新curr_ptr 指针。Clock页面替换算法通过维护一个指针curr_ptr，始终指向最老的/未被访问的页面，从而实现页面替换。采用反向插法，即每次均插到链表头(head指向的链表项的下一个)，之后遍历则从链表尾向前遍历。

- **_clock_swap_out_victim**

```cpp
static int
_clock_swap_out_victim(struct mm_struct *mm, struct Page ** ptr_page, int in_tick)
{
     list_entry_t *head=(list_entry_t*) mm->sm_priv;
         assert(head != NULL);
     assert(in_tick==0);
     /* Select the victim */
     //(1)  unlink the  earliest arrival page in front of pra_list_head qeueue
     //(2)  set the addr of addr of this page to ptr_page
    list_entry_t *tmpt = head;
    while (1) {
        /*LAB3 EXERCISE 4: 2211819 2212731 2212023*/ 
        // 编写代码
        // 遍历页面链表pra_list_head，查找最早未被访问的页面
        list_entry_t *entry = list_prev(tmpt);
        // 获取当前页面对应的Page结构指针
        //struct Page* curr_page = le2page(curr_ptr,pra_page_link);
        struct Page *p = le2page(entry, pra_page_link);
        // 如果当前页面未被访问，则将该页面从页面链表中删除，并将该页面指针赋值给ptr_page作为换出页面
        if (p->visited == 0){
            list_del(entry);
            *ptr_page = p;
            cprintf("curr_ptr %p\n", curr_ptr);
            break;
        }
        // 如果当前页面已被访问，则将visited标志置为0，表示该页面已被重新访问
        if (p->visited == 1){
            p->visited = 0;
        }
        tmpt = entry;
    }
    return 0;
}
```

实现了Clock页面替换算法中选择牺牲页面（victim_page）的逻辑，遍历pra_list_head ，找到最早未被访问的页面，作为vp返回。head指针无法利用le2page宏转成Page结构体指针，从链表尾部(即head指向链表项的前一个项，环形链表)依次向前遍历，直到找到第一个visited=0的项，将其移除可交换页链表。在p->visited == 0的条件下，*ptr_page = p;将当前页面指针赋值给ptr_page，作为被替换的页面；在p->visited == 1时，表示当前页面已被访问，将visited标志置为0，表示该页面已被重新访问的机会。

### 比较Clock页替换算法和FIFO算法的不同

- **替换策略**:
  
  **Clock算法**：Clock算法基于页面的访问位决定是否替换页面。它尝试保留最近被访问过的页面，只有当页面未被访问时才替换它。这使得它适用于访问模式有较强局部性的情况，同时使得访问频率高的页面有机会留在缓存中。
  
  **FIFO算法**：FIFO在页面置换时，总是选择最早进入的页面进行替换，不考虑页面的访问频率或重要性。不考虑页面是否被访问过，只考虑页面进入内存的顺序。

- **数据结构**:
  
  **Clock算法**：通常使用一个循环队列/链表来维护页面的顺序，同时需要维护一个访问位。
  
  **FIFO算法**：FIFO算法只需要一个简单的队列或链表来维护页面的进入顺序。

- **工作**:
  
  **Clock算法**：Clock算法相对较复杂，因为它需要维护访问位和定期重置访问位。这可能需要更多的计算和额外的操作。
  
  **FIFO算法**：FIFO算法非常简单，只需要在页面进入内存时将其添加到队列尾部，然后在替换时选择队列头部的页面。按照最早进入页面缓存的页面顺序进行替换。类似排队原则，最先进入的页面最先被替换出去。

- **性能**:
  
  **Clock算法**：由于考虑了页面的访问情况，Clock算法通常比FIFO算法更好地适应一些访问模式，尤其是具有局部性的模式。
  
  **FIFO算法**：FIFO算法在某些情况下可能表现不佳，特别是在存在页面访问局部性较弱的情况下，因为它只考虑了页面的进入顺序。

​总的来说，Clock算法是FIFO算法的改进版本，增加了对页面访问情况的考量，更加智能地进行页面替换，而FIFO算法是一种非常简单的算法。简略说，即Clock算法考虑了页表项表示的页是否被访问过，而FIFO不考虑这点.

## 练习五：阅读代码和实现手册，理解页表映射方式相关知识（思考题）

如果我们采用”一个大页“ 的页表映射方式，相比分级页表，有什么好处、优势，有什么坏处、风险？

#### 优势

1.可以减少页表项数量:一个大页面可以映射更多的虚拟地址空间,可以节省页表所占用的内存空间,同时也可以加快查找和访问页表的速度。
2.提高TLB命中率:在大页面模式下,TLB中缓存的是大页面的信息,而不是每个小页面的信息,这样可以减少TLB的缺失次数。
3.可以减少页表访问开销:在分级页表中,每个虚拟地址需要查找多个页表来确定对应的物理地址,而在大页面模式下,只需要查找一次页表就可以确定对应的物理地址。
4.覆盖范围增加:在容量不变的前提下TLB能存储的内存区域增加，这使得TLB的命中率得到大大提升。
5.发生缺页异常时，能够减少处理次数；现代应用程序经常会存在超过4KB的连续内存请求，大页能够一次性地取出足够大的数据区域，以满足程序的需求。

#### 缺点

1.内存碎片问题:如果系统中没有足够的连续物理内存来分配大页面,那么就无法使用这种映射方式。
2.内存利用率低:如果一个进程只需要映射部分虚拟地址空间,但是采用了大页面,分配精细度不够，就会浪费一部分物理内存。
3.响应时间长:如果需要访问一个未映射的虚拟地址,就需要将整个大页面从磁盘读入内存,这可能会导致响应时间更长。
4.大页比较臃肿，在分配时不够灵活，动态调整能力较弱。

<!--
【相关参考】
们知道一个程序通常含有下面几段：
.text段：存放代码，需要是可读、可执行的，但不可写。
.rodata 段：存放只读数据，顾名思义，需要可读，但不可写亦不可执行。
.data 段：存放经过初始化的数据，需要可读、可写。
.bss段：存放经过零初始化的数据，需要可读、可写。与 .data 段的区别在于由于我们知道它被零初始化，因此在可执行文件中可以只存放该段的开头地址和大小而不用存全为 0的数据。在执行时由操作系统进行处理。
我们看到各个段需要的访问权限是不同的。但是现在使用一个大大页(Giga Page)进行映射时，它们都拥有相同的权限，那么在现在的映射下，我们甚至可以修改内核 .text 段的代码，因为我们通过一个标志位 W=1 的页表项就可以完成映射，但这显然会带来安全隐患。
因此，我们考虑对这些段分别进行重映射，使得他们的访问权限可以被正确设置。虽然还是每个段都还是映射以同样的偏移量映射到相同的地方，但实现过程需要更加精细。
这里还有一个小坑：对于我们最开始已经用特殊方式映射的一个大大页(Giga Page)，该怎么对那里面的地址重新进行映射？这个过程比较麻烦。但大家可以基本理解为放弃现有的页表，直接新建一个页表，在新页表里面完成重映射，然后把satp指向新的页表，这样就实现了重新映射
-->

### 扩展练习 Challenge：实现不考虑实现开销和效率的LRU页替换算法（需要编程）

challenge部分不是必做部分，不过在正确最后会酌情加分。需写出有详细的设计、分析和测试的实验报告。完成出色的可获得适当加分。

#### 算法设计

LRU目的是寻找最近最少访问的页面，最精确的设计需要实时监控哪些内存页被访问，并将其移动到链表前端。
在本次实验中，没有相应的硬件支持，我们无法获悉内存页被访问的具体时间，只有当发生pageFault的时候才能够确认。但如果仅靠pageFault时来进行检查访问情况以调整链表，效果上又和FIFO没有太大区别了。
为了最好的设计出近似LRU的效果，不考虑开销和效率，我们想到了利用时钟中断。
因为内存页被访问时，其PTE_A位会被相应的置位（硬件上存在问题，后续进行讨论），我们可以借助时钟中断，确认在两次时钟中断期间，哪些页面被进行了访问，进而调整其在置换链表中的位置。理论上，只要时钟中断频率够高，该设计就越近似于LRU。
在代码实现上，其他函数均能复用FIFO的代码，但需重写tick_event：
下面的函数将被逐层封装，在时钟中断时会进行调用，遍历整个置换页链表，找出在两次时钟中断期间被访问了的页，将其移动到链表头部，并改变它的PTE_A位。

```
static int _lru_tick_event(struct mm_struct *mm)
{ 
    list_entry_t* head = (list_entry_t*)mm->sm_priv;
    list_entry_t* cur = head;
    while (cur->next != head)  // 遍历链表
    {
        cur = cur->next;
        struct Page* page = le2page(cur, pra_page_link);
        pte_t *ptep = get_pte(mm->pgdir, page->pra_vaddr, 0);
        if (*ptep & PTE_A)      // 如果页面在一段时间内被访问，就拿到最前面，置零
        {
            list_entry_t* temp = cur->prev;
            list_del(cur);
            *ptep &= ~PTE_A;  // 清0
            list_add(head, cur);  // 移动位置
            cur = temp;
        }
        // cprintf("here in lru_tick_event\n");
    }
    return 0;
}
```

#### 测试样例

下面给出精心设计的测试样例：

```
static int
_lru_check_swap(void) {
    //pte_t* ptep = get_pte()
    // 页面状态：d1 c1 b1 a1
    // 假设发生一次时钟中断，导致lru
    swap_tick_event(check_mm_struct);
    // 页面状态：a0 b0 c0 d0

    cprintf("write Virt Page e in lru_check_swap\n");
    *(unsigned char *)0x5000 = 0x0e;
    assert(pgfault_num==5);

    // 页面状态：e1 a0 b0 c0
    cprintf("write Virt Page c and set Access bit\n");
    pte_t *ptep = get_pte(check_mm_struct->pgdir, 0x3000, 0);
    *ptep |= PTE_A;
    // 页面状态：e1 a0 b0 c1

    // 假设发生一次时钟中断，导致lru
    swap_tick_event(check_mm_struct);
    // 页面状态：c0 e0 a0 b0

    cprintf("write Virt Page d in lru_check_swap\n");
    *(unsigned char *)0x4000 = 0x0e;
    assert(pgfault_num==6);
    // 页面状态：d1 c0 e0 a0

    cprintf("write Virt Page b in lru_check_swap\n");
    *(unsigned char *)0x2000 = 0x0e;
    assert(pgfault_num==7);

    return 0;
}
```

使用手动调用swap_tick_event的方式来模拟真实情况下PTE_A标志位被硬件置位的过程，每次调用swap_tick_event，都将最近访问过的页提到最前并将其PTE_A复位。
设计流程

| 时间  | 页表          | 实时状况    |
| --- | ----------- | ------- |
| 1   | d1 c1 b1 a1 | 初始化     |
| 2   | a0 b0 c0 d0 | LRU置换   |
| 3   | e1 a0 b0 c0 | 访问e，换出d |
| 4   | e1 a0 b0 c1 | 访问c     |
| 5   | c0 e0 a0 b0 | lru置换   |
| 6   | d1 c0 e0 a0 | 访问d，换出b |
| 7   | b1 d1 c0 e0 | 访问b，换出a |

上面的_lru_check_swap函数便是按照上述表格所展示的流程编写的。
随后我们对上述代码进行测试，测试结果显示，lru的实现是正确的。

### 知识点分析

#### 重要知识点

1.缺页异常：当程序访问一个不存在于物理内存中的虚拟页面时，会触发缺页异常，由操作系统负责处理。处理过程包括找到所需页面的磁盘位置，选择一个合适的物理帧进行置换，将所需页面加载到物理内存中，更新页表和帧表，恢复程序执行。
2.页面置换：当物理内存不足时，需要将某些物理页面换出到外存中，以腾出空间给新的页面。页面置换算法决定了哪些页面应该被换出，以达到最小化缺页次数和最大化内存利用率的目的。
3.页面置换算法：有多种页面置换算法，例如FIFO, LRU, Clock, 工作集, 缺页率等。不同的算法有不同的优缺点和实现难度。一些算法可能会出现Belady现象，即增加物理页面数反而导致缺页次数增加。
4.uCore虚拟内存机制：uCore实现了基于工作集的页面置换算法，使用mm_struct结构体管理虚拟内存空间，使用vma_struct结构体描述虚拟内存区域，使用swap_manager接口实现交换机制。

#### 额外知识点

本次实验并未设计页面置换算法的评价标准和性能比较，页面置换算法的目标是尽量减少缺页异常的发生次数，提高内存利用率和程序运行效率。页面置换算法的评价标准主要有缺页率和置换开销。
-缺页率：指发生缺页异常的次数与程序访问内存次数的比值。
-置换开销：指进行页面置换所需的时间和资源消耗。