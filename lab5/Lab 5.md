### 练习1：加载应用程序并执行（需要编码）

**do_execv**函数调用`load_icode`（位于kern/process/proc.c中）来加载并解析一个处于内存中的ELF执行文件格式的应用程序。你需要补充`load_icode`的第6步，建立相应的用户内存空间来放置应用程序的代码段、数据段等，且要设置好`proc_struct`结构中的成员变量trapframe中的内容，确保在执行此进程后，能够从应用程序设定的起始执行地址开始执行。需设置正确的trapframe内容。

请在实验报告中简要说明你的设计实现过程。

- 请简要描述这个用户态进程被ucore选择占用CPU执行（RUNNING态）到具体执行应用程序第一条指令的整个经过。

#### 设置trapframe

首先，在程序中的代码修改如下：

```cpp
    //(6) setup trapframe for user environment
    struct trapframe *tf = current->tf;
    // Keep sstatus
    uintptr_t sstatus = tf->status;
    memset(tf, 0, sizeof(struct trapframe));
    /* LAB5:EXERCISE1 2211819杨峥芃
     * should set tf->gpr.sp, tf->epc, tf->status
     * NOTICE: If we set trapframe correctly, then the user level process can return to USER MODE from kernel. So
     *          tf->gpr.sp should be user stack top (the value of sp)
     *          tf->epc should be entry point of user program (the value of sepc)
     *          tf->status should be appropriate for user program (the value of sstatus)
     *          hint: check meaning of SPP, SPIE in SSTATUS, use them by SSTATUS_SPP, SSTATUS_SPIE(defined in risv.h)
     */
    // tf->gpr.sp should be user stack top (the value of sp)
    tf->gpr.sp = USTACKTOP;
    // tf->epc should be entry point of user program (the value of sepc)
    tf->epc = elf->e_entry;
    // tf->status should be appropriate for user program (the value of sstatus)
    tf->status = (read_csr(sstatus) | SSTATUS_SPIE ) & ~SSTATUS_SPP;
```

以上即为相关代码填充，具体的实现过程设计如下：
第一步，理解`load_icode`函数：

`load_icode` 是一个用于加载二进制程序（ELF 格式）并将其作为当前进程内容的函数。它完成了从二进制程序的解析、内存空间的分配到最终用户态执行的准备工作。

**主要工作流程：**

1. **创建内存管理结构（`mm_struct`）**  
   为当前进程创建一个新的内存管理结构体 `mm`，用于管理进程的虚拟内存空间。

2. **设置页目录表（PDT）**  
   调用 `setup_pgdir` 函数，创建一个新的页目录表，并将其地址赋值给 `mm->pgdir`。

3. **加载 ELF 文件的 TEXT/DATA/BSS 段**
   
   - 检查 ELF 文件的合法性（通过魔数 `ELF_MAGIC` 判断）。
   - 遍历 ELF 文件的 Program Header 表，定位可加载段（`ELF_PT_LOAD` 类型）。
   - 调用 `mm_map` 为每个段分配虚拟地址空间。
   - 将文件中的 TEXT/DATA 段拷贝到虚拟内存，构建 BSS 段（将未初始化数据清零）。

4. **设置用户栈**  
   分配用户栈空间（4 页大小），设置虚拟内存标志，并映射到物理内存。

5. **切换到新内存空间**  
   设置当前进程的 `mm` 和 `cr3`（物理页目录地址），将页表注册到 CR3 寄存器。

6. **设置Trapframe**  
   为用户态程序返回做好准备：设置栈指针（`sp`）、程序入口地址（`epc`）和用户模式的状态标志（`status`）。

**Trapframe设计实现**

**目的**： `Trapframe` 是用户态和内核态切换时用于保存上下文的结构。当内核完成用户程序加载后，`Trapframe` 需要被正确初始化，确保用户程序能够顺利返回用户态并开始执行。

**实现步骤：**

1. **保存原始状态**  `uintptr_t sstatus = tf->status;`  
   这里保存了当前 `trapframe` 的状态，确保后续修改时不会丢失关键信息。

2. **清零 Trapframe**  `memset(tf, 0, sizeof(struct trapframe));`  
   清空 `trapframe`，为接下来的初始化提供干净起始点。

3. **设置用户栈指针 (`sp`)**  `tf->gpr.sp = USTACKTOP;`  
   将用户栈的顶端地址 `USTACKTOP` 设置为栈指针，用户程序运行时会从这里开始压栈操作。

4. **设置程序入口地址 (`epc`)**  `tf->epc = elf->e_entry;`  
   `epc` 保存了用户程序的入口点地址，即 ELF 文件中定义的 `e_entry`。用户程序返回用户态时，会从这个地址开始执行。

5. **设置用户状态标志 (`status`)**  `tf->status = (read_csr(sstatus) | SSTATUS_SPIE) & ~SSTATUS_SPP;`
   
   - `SSTATUS_SPIE`：启用用户态中断，使得返回用户态时能够正确处理中断。
   - `SSTATUS_SPP`：清零 SPP 位，表示返回用户态（而非内核态）。
   
   这个步骤确保用户程序回到用户态，而不是继续在内核态运行，同时保持必要的状态标志。`SSTATUS_SPIE` 和 `SSTATUS_SPP` 确保了用户程序可以在正确的中断模式下运行，保证系统稳定性和用户程序的正确执行。

#### 简要描述这个用户态进程被ucore选择占用CPU执行（RUNNING态）到具体执行应用程序第一条指令的整个经过

1. **创建并初始化内存管理结构 (`mm`)**  
   使用 `mm_create` 函数为当前进程分配一个新的 `mm_struct` 结构，用于管理该进程的虚拟内存。

2. **分配页目录表 (`PDT`) 并初始化内核空间映射**  
   使用 `setup_pgdir` 分配一个页目录表所需的页，并将内核的虚拟地址空间映射（`boot_pgdir`）拷贝到新的页目录表。随后将 `mm->pgdir` 指向这个新的页目录表，为用户进程初始化虚拟地址空间。

3. **解析 ELF 格式程序并建立 VMA 结构**
   
   - 根据 ELF 文件头和程序段头表（`elfhdr` 和 `proghdr`）解析程序的起始位置。
   - 遍历所有可加载段（`ELF_PT_LOAD`），为代码段、数据段和 BSS 段等建立虚拟内存区域（VMA），调用 `mm_map` 将其插入到 `mm` 中，作为用户进程的合法虚拟地址空间。

4. **分配物理内存并拷贝程序内容**
   
   - 根据 ELF 段的大小，为每个段分配物理内存，建立虚拟地址到物理地址的映射。
   - 将 ELF 文件中的内容（代码段和数据段）拷贝到对应的物理内存位置，同时清零 BSS 段的内存区域。

5. **设置用户栈**
   
   - 为用户进程设置栈空间，调用 `mm_map` 为用户栈建立虚拟内存区域（VMA）。
   - 用户栈位于虚拟内存的顶端（`USTACKTOP`），占据 256 页（如代码中 `USTACKSIZE` 所定义）。为这些虚拟地址分配物理内存并建立映射。

6. **切换到用户进程的页目录表**  
   将用户进程的 `mm->pgdir` 地址加载到 `CR3` 寄存器中，更新当前虚拟内存空间的页表。

7. **设置陷阱帧（Trapframe）以切换到用户态**
   
   - 清空当前进程的陷阱帧结构 (`trapframe`)。
   - 设置 `tf->gpr.sp` 为用户栈的顶端（`USTACKTOP`）。
   - 设置 `tf->epc` 为 ELF 文件的入口地址（`e_entry`），即用户程序的第一条指令地址。
   - 设置 `tf->status` 确保中断返回时切换到用户态（`Ring3`），并允许用户态中断（通过 `SSTATUS_SPIE` 和清除 `SSTATUS_SPP`）。

8. **恢复用户态，执行第一条指令**  
   调用 `sret` 指令通过陷阱帧返回到用户态：
   
   - 程序计数器从 `tf->epc` 加载，执行用户程序的第一条指令。
   - 用户栈指针从 `tf->gpr.sp` 加载，进入用户栈。

### 练习2：父进程复制自己的内存空间给子进程（需要编码）

**编程实现**

```c
int copy_range(pde_t *to, pde_t *from, uintptr_t start, uintptr_t end,
               bool share) {
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
    assert(USER_ACCESS(start, end));
    // copy content by page unit.
    do {
        // call get_pte to find process A's pte according to the addr start
        pte_t *ptep = get_pte(from, start, 0), *nptep;
        if (ptep == NULL) {
            start = ROUNDDOWN(start + PTSIZE, PTSIZE); 
            continue;
        }
        // call get_pte to find process B's pte according to the addr start. If
        // pte is NULL, just alloc a PT
        if (*ptep & PTE_V) {
            if ((nptep = get_pte(to, start, 1)) == NULL) {
                return -E_NO_MEM;
            }
            uint32_t perm = (*ptep & PTE_USER);
            // get page from ptep
            struct Page *page = pte2page(*ptep);
            // alloc a page for process B
            struct Page *npage = alloc_page();
            assert(page != NULL);
            assert(npage != NULL);
            int ret = 0;
            /* LAB5:EXERCISE2 2212023
             * replicate content of page to npage, build the map of phy addr of
             * nage with the linear addr start
             *
             * Some Useful MACROs and DEFINEs, you can use them in below
             * implementation.
             * MACROs or Functions:
             *    page2kva(struct Page *page): return the kernel vritual addr of
             * memory which page managed (SEE pmm.h)
             *    page_insert: build the map of phy addr of an Page with the
             * linear addr la
             *    memcpy: typical memory copy function
             *
             * (1) find src_kvaddr: the kernel virtual address of page
             * (2) find dst_kvaddr: the kernel virtual address of npage
             * (3) memory copy from src_kvaddr to dst_kvaddr, size is PGSIZE
             * (4) build the map of phy addr of  nage with the linear addr start
             */
            uintptr_t* src = page2kva(page);
            uintptr_t* dst = page2kva(npage);
            memcpy(dst, src, PGSIZE);
            ret = page_insert(to, npage, start, perm);

            assert(ret == 0);
        }
        start += PGSIZE;
    } while (start != 0 && start < end);
    return 0;
}
```

1.确保开始和结束地址都是页对齐的，并且这些地址在用户空间内。
2.开始按页单位复制内容。对于每个开始地址，获取源进程的页表项（PTE）；如果 PTE 不存在，就跳过这个地址，并继续处理下一个地址。
3.如果源 PTE 存在并且有效（即，对应的页在内存中），就获取目标进程的 PTE；如果目标 PTE 不存在，就分配一个新的页表。
4.获取源 PTE 对应的页，并为目标进程分配一个新的页。
5.找到源页和目标页的内核虚拟地址，并将源页的内容复制到目标页。
6.将目标页插入到目标进程的页表中。

**如何设计实现`Copy on Write`机制？给出概要设计**
 Copy-on-Write机制的设计的基本思想是当多个进程共享同一资源（例如，内存页）时，只有当某个进程试图修改该资源时，系统才会创建该资源的副本，以供该进程单独使用。这样，大部分时间内，资源可以被多个进程共享，从而节省内存。

- 具体实现时，在`fork`时，将父线程的所有页表项设置为只读，在新线程的结构中只复制栈和虚拟内存的页表，不为其分配新的页。

- 切换到子线程执行时，当发生写操作时，会访问页表，如果发现该页被设置为只读，即该页不允许被修改，则触发异常。

- 异常处理部分负责重新分配一块空间，复制该页，更新子线程的页表项，使得发起写操作的进程看到的是新复制出的页。
  这样，对其他共享该页的进程是透明的，它们仍然看到的是原来的页。
  
### 练习3：阅读分析源代码，理解进程执行 fork/exec/wait/exit 的实现，以及系统调用的实现（不需要编码）
  
  **请分析fork/exec/wait/exit的执行流程。重点关注哪些操作是在用户态完成，哪些是在内核态完成？**
  
  1. `fork`：通过发起系统调用执行`do_fork`函数。用于创建并唤醒线程，可以通过`sys_fork`或者`kernel_thread`调用。
     - 初始化一个新线程
     - 为新线程分配内核栈空间
     - 为新线程分配新的虚拟内存或与其他线程共享虚拟内存
     - 获取原线程的上下文与中断帧，设置当前线程的上下文与中断帧
     - 将新线程插入哈希表和链表中
     - 唤醒新线程
     - 返回线程`id`
  2. `exec`：通过发起系统调用执行`do_execve`函数。用于创建用户空间，加载用户程序，可以通过`sys_exec`调用。
     - 回收当前线程的虚拟内存空间
     - 为当前线程分配新的虚拟内存空间并加载应用程序
  3. `wait`：通过发起系统调用执行`do_wait`函数。用于等待线程完成，可以通过`sys_wait`或者`init_main`调用。
     - 查找状态为`PROC_ZOMBIE`的子线程；如果查询到拥有子线程的线程，则设置线程状态并切换线程；如果线程已退出，则调用`do_exit`
     - 将线程从哈希表和链表中删除
     - 释放线程资源
  4. `exit`：通过发起系统调用执行`do_exit`函数。用于退出线程，可以通过`sys_exit`、`trap`、`do_execve`、`do_wait`调用。具体执行内容：
     - 如果当前线程的虚拟内存没有用于其他线程，则销毁该虚拟内存
     - 将当前线程状态设为`PROC_ZOMBIE`，唤醒该线程的父线程
     - 调用`schedule`切换到其他线程
**内核态与用户态程序是如何交错执行的？**
  - 系统调用部分在内核态进行，用户程序的执行在用户态进行
  - 内核态通过系统调用结束后的`sret`指令切换到用户态，用户态通过发起系统调用产生`ebreak`异常切换到内核态
**内核态执行结果是如何返回给用户程序的？**
  - 内核态执行的结果通过`kernel_execve_ret`将中断帧添加到线程的内核栈中，从而将结果返回给用户

**请给出ucore中一个用户态进程的执行状态生命周期图（包执行状态，执行状态之间的变换关系，以及产生变换的事件或函数调用）。（字符方式画即可）**

```
                    +-------------+
               +--> |     none       |
               |    +-------------+       ---+
               |          | alloc_proc         |
               |          V                     |
               |    +-------------+             |
               |    | PROC_UNINIT |             |---> do_fork
               |    +-------------+             |
      do_wait  |         | wakeup_proc         |
               |         V                     ---+
               |    +-------------+    do_wait             +-------------+
               |    |PROC_RUNNABLE| <------------>    |PROC_SLEEPING|
               |    +-------------+    wake_up        +-------------+
               |         | do_exit
               |         V
               |    +-------------+
               +--- | PROC_ZOMBIE |
                    +-------------+
```

- 新建：进程被创建。
- 就绪：进程获得除 CPU 外的所有必要资源，等待 CPU 资源。
- 运行：进程获得 CPU 资源，正在执行。
- 退出：进程结束，等待父进程回收资源。

产生状态变换的事件或函数调用：

- 新建到就绪：进程被创建后，进入就绪状态，等待调度。
- 就绪到运行：进程调度程序选择一个就绪状态的进程，分配 CPU 资源，进程开始执行。
- 运行到就绪：进程的时间片用完，操作系统剥夺其 CPU 资源，进程回到就绪状态。
- 运行到退出：进程执行完毕，或者调用 exit 函数，进程进入退出状态。进程的资源还没有被回收。
- 退出到新建：父进程调用 wait 或 waitpid 函数，回收进程的资源，进程彻底结束。如果父进程创建了新的进程，新进程进入新建状态。如果父进程没有创建新的进程，那么这个转换不会发生。

```
新建 (new) --调度--> 就绪 (ready)
   ^                      |
   |                      v
退出 (exit) <--运行-- 运行 (running)
```

### 扩展练习 Challenge

实现 Copy on Write （COW）机制

给出实现源码,测试用例和设计报告（包括在cow情况下的各种状态转换（类似有限状态自动机）的说明）。

这个扩展练习涉及到本实验和上一个实验“虚拟内存管理”。在ucore操作系统中，当一个用户父进程创建自己的子进程时，父进程会把其申请的用户空间设置为只读，子进程可共享父进程占用的用户内存空间中的页面（这就是一个共享的资源）。当其中任何一个进程修改此用户内存空间中的某页面时，ucore会通过page fault异常获知该操作，并完成拷贝内存页面，使得两个进程都有各自的内存页面。这样一个进程所做的修改不会被另外一个进程可见了。请在ucore中实现这样的COW机制。

由于COW实现比较复杂，容易引入bug，请参考 https://dirtycow.ninja/ 看看能否在ucore的COW实现中模拟这个错误和解决方案。需要有解释。

这是一个big challenge.

说明该用户程序是何时被预先加载到内存中的？与我们常用操作系统的加载有何区别，原因是什么？

#### 代码实现

首先，在fork时将父进程的空间设为只读，再将子进程的虚拟地址空间映射到父进程的物理页，二者共享内存空间。

代码如下，根据share的值来判断是否需要共享内存空间。如果需要，则通过page_insert将子进程的虚拟地址空间映射到父进程的物理页，否则，将父进程的内存空间复制给子进程。

```
    if(share){
        // COW，共享，初始两边都设置为只读
        page_insert(from, page, start, perm & (~PTE_W));
        ret = page_insert(to, page, start, perm & (~PTE_W));
    }
    else{
        struct Page *npage = alloc_page();
        assert(npage != NULL);
        void* src_kvaddr = page2kva(page);
        void* dst_kvaddr = page2kva(npage);
        memcpy(dst_kvaddr, src_kvaddr, PGSIZE);
        ret = page_insert(to, npage, start, perm);
    }
```

接着就是修改do_pgfault函数，当发生缺页中断时，判断是否是写一个只读页面。

如果是，则需要将页面复制一份，然后修改子进程的页表，建立新的映射关系，使得子进程的内存空间与父进程的内存空间分离。

另外还需查看原来共享的物理页是否只有一个进程在使用，如果是，需恢复原来的读写权限。

```
    // Copy on Write，发生写不可写页面错误时，tf->cause == 0xf
    else if((*ptep & PTE_V) && (error_code == 0xf)) {
        struct Page *page = pte2page(*ptep);
        if(page_ref(page) == 1) {
            // 该页面只有一个引用，直接修改权限
            page_insert(mm->pgdir, page, addr, perm);
        }
        else {
            // 该页面有多个引用，需要复制页面
            struct Page *npage = alloc_page();
            assert(npage != NULL);
            memcpy(page2kva(npage), page2kva(page), PGSIZE);
            if(page_insert(mm->pgdir, npage, addr, perm) != 0) {
                cprintf("page_insert in do_pgfault failed\n");
                goto failed;
            }
        }
    }
```

#### 测试结果

由于时间所限，没有设置专门的测试用例以及模拟指导书中提出的错误场景。
只是设置为Copy On Write机制后，运行了make grade，测试结果如下:

```
把运行结果复制过来或者粘图片
```

可以看到，能够通过所有测试用例。
查看exit.c的输出日志，可以看到，当进程修改共享页面时，触发了缺页中断，进行了Copy On Write操作复制了页面，用户程序正常执行。

```
把运行结果复制过来或者粘图片
```

### 用户程序是何时被预先加载到内存中的？与常用操作系统加载的区别，原因是什么？

本次实验把用户准备的二进制程序编译到了内核镜像中。

由于在本次实验中文件系统还没实现，于是想要执行一个编译好的二进制程序，就要将二进制程序和内核一同编译，把可执行程序链接到内核中，也就是在内存中创建了一个大空间，将这个文件以二进制形式保存在了这一片内存区域中。

常用操作系统是通过以下步骤来加载用户程序的：

- 1.操作系统根据路径找到对应的程序，检测程序的头部，找到代码段和数据段的位置，以及程序的入口点。
- 2.操作系统为程序分配内存空间，将程序的各个段加载到内存中，并进行地址重定位，使得程序能够正确地访问自己的数据和代码。
- 3.操作系统将执行权移交给程序的入口点，开始执行用户程序。

常用操作系统是在用户程序需要执行时被加载到内存，而本次实验，用户程序是在内核启动时就被加载到内存中，原因在于文件系统尚未实现，无法将可执行文件从硬盘加载到内存。

### 知识点分析

#### 重要知识点

- 1.特权转换：在RISCV中，用户程序通过调用syscall函数，触发ecall中断，从而陷入到内核态，完成系统调用，通过sret指令返回用户态。
- 2.应用程序加载：通过sys_exec系统调用，利用load_icode将用户程序加载到内存中，然后通过trapret函数返回用户态，执行用户程序。

#### 额外知识点

本次实验只是创建了一个用户进程，对于用户进程间的同步和通信，以及多个进程为竞争资源死锁的问题。

- 1.进程同步：进程同步是指多个进程之间按照一定的顺序执行，以确保数据的一致性和正确性。进程同步的方法互斥锁，信号量，临界区等方式，通过控制进程对共享资源的访问，从而实现进程同步。
- 2.死锁：死锁是多个进程因竞争有限的系统资源而被永久阻塞的一种状态。当每个进程都持有一些资源并等待其他进程释放其资源时，就可能发生死锁。死锁的发生是由于进程之间的相互等待，导致它们都无法继续执行。死锁的常用的解决策略有：预防，避免，检测恢复，忽略。