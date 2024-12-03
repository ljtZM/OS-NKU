### 练习1：分配并初始化一个进程控制块（需要编码）

alloc_proc函数（位于kern/process/proc.c中）负责分配并返回一个新的struct proc_struct结构，用于存储新建立的内核线程的管理信息。ucore需要对这个结构进行最基本的初始化，你需要完成这个初始化过程。

> 【提示】在alloc_proc函数的实现中，需要初始化的proc_struct结构中的成员变量至少包括：state/pid/runs/kstack/need_resched/parent/mm/context/tf/cr3/flags/name。

请在实验报告中简要说明你的设计实现过程。请回答如下问题：

- 请说明proc_struct中struct context context和struct trapframe *tf成员变量含义和在本实验中的作用是啥？（提示通过看代码和编程调试可以判断出来）
  1.实现初始化，补充alloc_proc函数

```
static struct proc_struct * alloc_proc(void) {
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
    if (proc != NULL) {
    //LAB4:EXERCISE1 YOUR CODE:2212731

        proc->state = PROC_UNINIT;                      //状态为未初始化
        proc->pid = -1;                                 //pid为未赋值
        proc->runs = 0;                                 //运行时间为0
        proc->kstack = 0;                               //除了idleproc其他线程的内核栈都要后续分配
        proc->need_resched = 0;                         //不需要调度切换线程
        proc->parent = NULL;                            //没有父线程
        proc->mm = NULL;                                //未分配内存
        memset(&(proc->context), 0, sizeof(struct context));//将上下文变量全部赋值为0，清空
        proc->tf = NULL;                                //初始化没有中断帧
        proc->cr3 = boot_cr3;                           //内核线程的cr3为boot_cr3，即页目录为内核页目录表
        proc->flags = 0;                                //标志位为0
        memset(proc->name, 0, PROC_NAME_LEN+1);         //将线程名变量全部赋值为0，清空

    }
    return proc;
}
```

可以注意到`alloc_proc()`负责分配创建一个 `proc_struct`并对其进行基本初始化，仅起到了创建进程块实例的作用，没有创建内核线程本身。

其实对照下文的void
proc_init(void)函数即可写出。

```
if(idleproc->cr3 == boot_cr3 && idleproc->tf == NULL && !context_init_flag
        && idleproc->state == PROC_UNINIT && idleproc->pid == -1 && idleproc->runs == 0
        && idleproc->kstack == 0 && idleproc->need_resched == 0 && idleproc->parent == NULL
        && idleproc->mm == NULL && idleproc->flags == 0 && !proc_name_flag
    ){
        cprintf("alloc_proc() correct!\n");
    }
```

2.`struct context context`成员变量的含义和在本实验中的作用

在`proc.h`中可以找到`context`结构体的定义。

```
struct context {
    uintptr_t ra;
    uintptr_t sp;
    uintptr_t s0;
    uintptr_t s1;
    uintptr_t s2;
    uintptr_t s3;
    uintptr_t s4;
    uintptr_t s5;
    uintptr_t s6;
    uintptr_t s7;
    uintptr_t s8;
    uintptr_t s9;
    uintptr_t s10;
    uintptr_t s11;
};
```

context保存了`ra`、`sp`、`s0-s11`共十四个寄存器。这些只是`callee-saved`寄存器，而`caller-saved`寄存器在调用`switch_to`函数时，由编译器自动帮助保存。

本次实验中，`context`的作用是保存`forkret`函数的返回地址，以及`forkret`函数的参数`struct trapframe`。

在`static void
copy_thread(struct proc_struct *proc, uintptr_t esp, struct trapframe *tf)`函数里，可以找到

```
    proc->context.ra = (uintptr_t)forkret;  // switch_to后返回到forkret，forkret再去trapret
    proc->context.sp = (uintptr_t)(proc->tf);  // switch_to将context的寄存器复原，但这里其实冗余了，因为forkret会传参给sp
```

`switch_to`函数执行后，`ra`寄存器值变为`context.ra`，接着就会跳转到`forkre`t函数。
到了forkret就意味着这次进程切换已经完成，`context`的使命结束，接着就是进入`trapret`恢复用户态/中断恢复。

3.`struct trapframe *tf`成员变量含义和在本实验中的作用

在kern\process\trap\trap.h中可以找到trapframe结构体的定义。

```
struct trapframe {
    struct pushregs gpr;
    uintptr_t status;
    uintptr_t epc;
    uintptr_t badvaddr;
    uintptr_t cause;
};
```

可以看出`trapframe`保存了进程的中断帧，是从用户态进入内核态时进程的状态，包含通用寄存器和中断时的特殊系统寄存器。

在本次实验中，`trapframe`的作用是保存`kernel_thread_entry`函数的地址以及参数，即`fn`和`arg`。

```
static void
copy_thread(struct proc_struct *proc, uintptr_t esp, struct trapframe *tf) {
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE - sizeof(struct trapframe));
    *(proc->tf) = *tf;

    // Set a0 to 0 so a child process knows it's just forked
    proc->tf->gpr.a0 = 0;
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;

    proc->context.ra = (uintptr_t)forkret;
    proc->context.sp = (uintptr_t)(proc->tf);
}
```

在`kernel_thread`函数中，将通用寄存器`s0`和`s1`赋值为了`fn`和`arg`，`epc`设置为`kernel_thread_entry`的返回地址，并设置了`status`寄存器调整中断设置。

```
int
kernel_thread(int (*fn)(void *), void *arg, uint32_t clone_flags) {
    struct trapframe tf;
    memset(&tf, 0, sizeof(struct trapframe));
    tf.gpr.s0 = (uintptr_t)fn;
    tf.gpr.s1 = (uintptr_t)arg;
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
    tf.epc = (uintptr_t)kernel_thread_entry;
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
}
```

`forkret`函数会将`trapframe`放到栈顶，接着进入`trapret`函数。`trapret`进行一次`RESTORE_ALL`操作，把`trapframe`中的值恢复到CPU寄存器中。然后通过`epc`跳转到`kernel_thread_entry`函数，调用`s0`寄存器里保存的`fn`函数，至此就完成了中断恢复，CPU接着在对应态下执行`fn`函数。

### 练习2：为新创建的内核线程分配资源(需要编码)

创建一个内核线程需要分配和设置好很多资源。kernel thread函数通过调用do_fork函数完成具体内核线程的创建工作。do_kemel函数会调用alloc_proc函数来分配并初始化一个进程控制块，但alloc proc只是找到了一小块内存用以记录进程的必要信息，并没有实际分配这些资源。ucore一般通过do fork实际创建新的内核线程。do fork的作用是，创建当前内核线程的一个副本，它们的执行上下文、代码、数据都一样，但是存储位置不同。因此，我们实际需要"fork"的东西就是stack和trapframe。在这个过程中，需要给新内核线程分配资源，并且复制原进程的状态。你需要完成在kern/process/proc.c中的dofork函数中的处理过程。它的大致执行步骤包括:

- 调用alloc_proc，首先获得一块用户信息块。

- 为进程分配一个内核栈。

- 复制原进程的内存管理信息到新进程（但内核线程不必做此事）。

- 复制原进程上下文到新进程。

- 将新进程添加到进程列表。

- 唤醒新进程。

- 返回新进程号。

#### kern/process/proc.c中的dofork函数填写：

```cpp
int
do_fork(uint32_t clone_flags, uintptr_t stack, struct trapframe *tf) {
    int ret = -E_NO_FREE_PROC;
    struct proc_struct *proc;
    if (nr_process >= MAX_PROCESS) {
        goto fork_out;
    }
    ret = -E_NO_MEM;
    //LAB4:EXERCISE2 2211819
    /*
     * Some Useful MACROs, Functions and DEFINEs, you can use them in below implementation.
     * MACROs or Functions:
     *   alloc_proc:   create a proc struct and init fields (lab4:exercise1)
     *   setup_kstack: alloc pages with size KSTACKPAGE as process kernel stack
     *   copy_mm:      process "proc" duplicate OR share process "current"'s mm according clone_flags
     *                 if clone_flags & CLONE_VM, then "share" ; else "duplicate"
     *   copy_thread:  setup the trapframe on the  process's kernel stack top and
     *                 setup the kernel entry point and stack of process
     *   hash_proc:    add proc into proc hash_list
     *   get_pid:      alloc a unique pid for process
     *   wakeup_proc:  set proc->state = PROC_RUNNABLE
     * VARIABLES:
     *   proc_list:    the process set's list
     *   nr_process:   the number of process set
     */

    //    1. call alloc_proc to allocate a proc_struct
    //    2. call setup_kstack to allocate a kernel stack for child process
    //    3. call copy_mm to dup OR share mm according clone_flag
    //    4. call copy_thread to setup tf & context in proc_struct
    //    5. insert proc_struct into hash_list && proc_list
    //    6. call wakeup_proc to make the new child process RUNNABLE
    //    7. set ret vau 
    proc = alloc_proc() //分配一个proc_struct 1
    if (proc == NULL) {
        goto fork_out; //没有内存空间
    }
    proc->parent = current;    

    if (setup_kstack(proc) != 0) // setup_kstack函数为子进程分配内核栈
    {
        goto bad_fork_cleanup_proc;// 2
    }

    if (copy_mm(clone_flags, proc) != 0) // copy_mm函数根据clone_flag管理内存info
    {
        goto bad_fork_cleanup_kstack;
    } 
    // 只是把current->mm 设置为NULL哈，mm无可用 3
    copy_thread(proc, stack, tf);  //copy_thread函数实现trap frame（common-working & 上下文）

    bool intr_flag;
    local_intr_save(intr_flag);  // shutdown 中断
    //{
    proc->pid = get_pid(); // 返回码->子进程的id号
    hash_proc(proc);
    list_add(&proc_list, &(proc->list_link)); // 进程控制块放入hash_list和proc_list 5
    nr_process ++;
    //}
    local_intr_restore(intr_flag);

    wakeup_proc(proc); // wakeup_proc函数-子进程变成可执行状态 6

    ret = proc->pid; // set ret vaule using child proc's pid 7

fork_out:
    return ret;

bad_fork_cleanup_kstack:
    put_kstack(proc);
bad_fork_cleanup_proc:
    kfree(proc);
    goto fork_out;
}
```

以上即为设计

#### 设计实现过程说明

- **调用 `alloc_proc` 分配 `proc_struct`**：
  
  - `alloc_proc()` 函数用于为新进程分配一个 `proc_struct` 结构体，它会初始化该结构体并分配内存。`proc_struct` 是进程控制块（PCB），包含进程的状态、PID、父进程、内存管理信息等。此时新进程尚未完成创建，仅仅分配了一个进程控制结构。
  - **实现方式**：`proc = alloc_proc()`。若 `alloc_proc` 返回 `NULL`，则意味着没有足够的内存分配新的进程，跳转到 `fork_out` 结束创建过程。

- **调用 `setup_kstack` 为子进程分配内核栈**：
  
  - `setup_kstack()` 用于为新进程分配内核栈。内核栈是进程执行内核代码时使用的栈空间。在这里分配栈空间是必要的，因为每个进程都需要自己的内核栈。
  - **实现方式**：通过 `setup_kstack(proc)` 函数为 `proc` 分配栈内存，若分配失败，则调用 `bad_fork_cleanup_proc` 清理已分配的资源，并跳转到 `fork_out` 返回失败。

- **调用 `copy_mm` 复制或共享内存管理信息**：
  
  - `copy_mm()` 用于根据 `clone_flags` 来决定是复制父进程的内存管理信息，还是与父进程共享内存。具体来说，当 `clone_flags` 中包含 `CLONE_VM` 标志时，子进程与父进程共享相同的虚拟内存空间；否则，子进程会复制父进程的内存管理信息。
  - **实现方式**：通过 `copy_mm(clone_flags, proc)` 复制内存管理信息。如果复制失败，调用 `bad_fork_cleanup_kstack` 清理栈内存，并跳转到 `fork_out` 返回失败。

- **调用 `copy_thread` 设置子进程的上下文和 trapframe**：
  
  - `copy_thread()` 用于复制父进程的上下文（包括程序计数器、寄存器等）到子进程的内核栈中，同时设置进程的入口点。此时子进程的上下文准备完成，能够执行下一步操作。
  - **实现方式**：通过 `copy_thread(proc, stack, tf)` 设置新进程的上下文信息。

- **将 `proc_struct` 插入哈希表和进程列表中**：
  
  - `hash_proc()` 用于将新进程添加到进程哈希表中，以便高效查找进程。`list_add()` 将新进程加入到进程列表 `proc_list` 中。
  - **实现方式**：通过 `proc->pid = get_pid()` 获取一个唯一的进程 ID，并调用 `hash_proc(proc)` 和 `list_add(&proc_list, &(proc->list_link))` 将新进程插入到进程表中。

- **调用 `wakeup_proc` 将子进程设为可运行状态**：
  
  - `wakeup_proc()` 用于将新进程的状态设置为 `PROC_RUNNABLE`，意味着该进程已经准备好执行。
  - **实现方式**：通过 `wakeup_proc(proc)` 将新进程设置为可运行状态。

- **设置 `ret` 返回子进程的 PID**：
  
  - 最终，将新创建的子进程的 PID 赋值给 `ret`，并返回该值。`ret` 会被用作 `do_fork` 函数的返回值，表示子进程的 PID。
  - **实现方式**：通过 `ret = proc->pid` 设置 `ret`，并将其返回。

同时我们存在错误处理：在分配内存、内核栈或复制内存管理信息等操作失败时，`do_fork` 会跳转到错误处理部分，清理已分配的资源，避免内存泄漏。

- **清理流程**：当任意步骤失败时，调用 `bad_fork_cleanup_kstack` 清理内核栈，或者 `bad_fork_cleanup_proc` 清理 `proc_struct`，然后跳转到 `fork_out` 返回失败。

#### 请说明ucore是否做到给每个新fork的线程一个唯一的id？请说明你的分析和理由。

`do_fork`函数通过调用`get_pid()`函数为新进程分配一个唯一的进程ID——从全局的PID池中获取一个未分配使用的PID分配给新的进程。所以，ucore 做到给每个新 `fork` 的线程一个唯一的 `id`.

```cpp
static int
get_pid(void) {
    static_assert(MAX_PID > MAX_PROCESS);
    struct proc_struct *proc;
    list_entry_t *list = &proc_list, *le;
    static int next_safe = MAX_PID, last_pid = MAX_PID;
    if (++ last_pid >= MAX_PID) {
        last_pid = 1;
        goto inside;
    }
    if (last_pid >= next_safe) {
    inside:
        next_safe = MAX_PID;
    repeat:
        le = list;
        while ((le = list_next(le)) != list) {
            proc = le2proc(le, list_link);
            if (proc->pid == last_pid) {
                if (++ last_pid >= next_safe) {
                    if (last_pid >= MAX_PID) {
                        last_pid = 1;
                    }
                    next_safe = MAX_PID;
                    goto repeat;
                }
            }
            else if (proc->pid > last_pid && next_safe > proc->pid) {
                next_safe = proc->pid;
            }
        }
    }
    return last_pid;
}
```

关于此函数的简要分析：

##### 主要功能：

- 为新进程分配一个唯一的 PID。
- 遍历进程列表，查找一个尚未使用的 PID。
- 如果 PID 超过最大值（`MAX_PID`），则从 1 开始重新分配 PID。

##### 关键步骤解析：

1. **静态变量**：
   
   - `next_safe`: 跟踪下一个可用的安全 PID。如果找到了一个可用的 PID，`next_safe` 会被更新为下一个最小的 PID。
   - `last_pid`: 记录上一个分配的 PID，每次分配 PID 时会递增。它是遍历 PID 的起点。

2. **PID 分配逻辑**：
   
   - **PID 循环检查**：首先，`last_pid` 被递增。如果 `last_pid` 大于或等于 `MAX_PID`，它会重置为 1，从头开始查找。
   - 如果 `last_pid` 大于等于 `next_safe`，则进入查找阶段，遍历 `proc_list` 中的所有进程，寻找一个空闲的 PID。

3. **遍历进程列表**：
   
   - 代码通过 `list_next(le)` 遍历 `proc_list` 中的每个进程。
   - 如果当前进程的 PID 等于 `last_pid`，则递增 `last_pid` 并重新检查，直到找到一个空闲的 PID。
   - 如果当前进程的 PID 大于 `last_pid`，并且 `next_safe` 比当前进程的 PID 大，则更新 `next_safe` 为当前进程的 PID，表示下一个可用 PID 为当前 PID 之前的一个。

4. **静态断言**：
   
   - `static_assert(MAX_PID > MAX_PROCESS)`：这确保了系统中的最大 PID 数量 `MAX_PID` 大于最大进程数 `MAX_PROCESS`，避免 PID 资源耗尽。

5. **循环跳转**：
   
   - 如果 `last_pid` 达到最大值 `MAX_PID`，它会重新开始从 1 分配 PID，直到找到一个未被使用的 PID。

### 练习3：编写proc_run 函数（需要编码）

**函数的主要流程**：
1.判断切换到的进程（线程）是否是当前进程（线程），如果是，则无需进行任何处理；如果要切换的进程（线程）不是当前进程（线程），则进行进程切换操作。
2.调用 `local_intr_save(intr_flag)` 函数关闭中断，以确保在进程切换过程中不会被中断.
3.声明两个指向 `struct proc_struct` 类型的指针 `prev` 和 `next`，分别用于保存当前进程和要切换到的下一个进程，将当前进程指针 `current` 设置为要切换到的下一个进程。
4.调用 `lcr3(proc->cr3)` 函数切换到下一个进程的页表，即将页表寄存器 CR3 的值设置为下一个进程的页表基址。
5.调用 `switch_to(&(prev->context), &(next->context))` 函数进行上下文切换，将当前进程的上下文保存到 `prev->context` 中，将下一个进程的上下文恢复到 `next->context` 中。
6.最后再调用 `local_intr_restore(intr_flag)` 函数开启中断，恢复中断状态。至此，进程切换完成，当前进程被切换为要切换到的下一个进程（线程）。
**编程实现**

```c
// proc_run - 用来切换到一个新的进程（线程）
void proc_run(struct proc_struct *proc) {
    //检查要切换的进程是否与当前正在运行的进程相同，如果相同则不需要切换
    if (proc != current) {
        // LAB4:EXERCISE3 2212023
        /*
        * Some Useful MACROs, Functions and DEFINEs, you can use them in below implementation.
        * MACROs or Functions:
        *   local_intr_save():        Disable interrupts
        *   local_intr_restore():     Enable Interrupts
        *   lcr3():                   Modify the value of CR3 register
        *   switch_to():              Context switching between two processes
        */
        bool intr_flag;
        //宏`local_intr_save(x)``local_intr_restore(x)`来实现关、开中断。
        local_intr_save(intr_flag); // 关闭中断

        struct proc_struct *prev = current; // 保存当前进程
        struct proc_struct *next = proc;    // 保存下一个进程

        current = proc; // 将当前进程设置为下一个进程
        //`lcr3(unsigned int cr3)`函数实现修改CR3寄存器值的功能
        lcr3(proc->cr3);    // 切换到下一个进程的页表
        //`switch_to()`函数实现两个进程的context切换
        switch_to(&(prev->context), &(next->context));  // 进行上下文切换

        local_intr_restore(intr_flag);  // 开启中断
    }
}
```

**问题1**：在本实验的执行过程中，创建且运行了几个内核线程？
在本实验中，一共创建并运行了两个内核线程，一个为 0号线程`idleproc`, 另外一个为执行 `init_main` 的 1号线程`initproc` 。
**问题2**：编译并运行代码的结果输出如下所示:

```
(THU.CST) os is loading ...

Special kernel symbols:
  entry  0xc0200032 (virtual)
  etext  0xc0204f4a (virtual)
  edata  0xc020b060 (virtual)
  end    0xc02165cc (virtual)

...

++ setup timer interrupts
this initproc, pid = 1, name = "init"
To U: "Hello world!!".
To U: "en.., Bye, Bye. :)"
kernel panic at kern/process/proc.c:374:
    process exit!!.

Welcome to the kernel debug monitor!!
Type 'help' for a list of commands.

```

### 扩展练习 Challenge：

说明语句local_intr_save(intr_flag);....local_intr_restore(intr_flag);是如何实现开关中断的？

local_intr_save宏首先调用__intr_save()函数，这个函数会检查当前的中断状态（通过读取CSR寄存器的sstatus位）。如果中断是开启的（SSTATUS_SIE位为1），那么它会关闭中断（通过调用intr_disable()函数）并返回1；否则，它会返回0。这个返回值会被保存到intr_flag变量中。

local_intr_restore宏检查flag参数。如果flag为1表明的是原本中断时开启状态，那么它会开启中断（通过调用intr_enable()函数）。

所以，通过先调用local_intr_save，后调用local_intr_restore，从而在两者之间形成了临界区，临界区前保存中断位，临界区的代码在中断关闭的状态下运行，并在临界区代码执行完毕后恢复原来的中断状态。

在练习三中proc_run函数的完善中就使用到了这两个语句。

```c++
void
proc_run(struct proc_struct *proc) {
    if (proc != current) {
        bool intr_flag;
        local_intr_save(intr_flag);
    ······
    ······
        local_intr_restore(intr_flag);
    }
}
```

其中的 `local_intr_save(intr_flag);....local_intr_restore(intr_flag);`在krn/sync/sync.h中定义如下：

```c++
//kern/sync/sync.h
#define local_intr_save(x) \
    do {                   \
        x = __intr_save(); \
    } while (0)
#define local_intr_restore(x) __intr_restore(x);

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
        //read_csr(sstatus)读取控制寄存器sstatus位与操作检查其中的SIE位
        //如果SIE位为1，表示中断允许
        intr_disable();//关闭中断
        return 1;//保存中断状态
    }
    return 0;//中断禁止，中断状态未被保存
}

static inline void __intr_restore(bool flag) {
    if (flag) {
        intr_enable();//开启中断
    }
}

///kern/driver/intr.c
/* intr_enable - enable irq interrupt */
void intr_enable(void) { 
    //将SSTATUS寄存器的SIE位设置为1，以允许中断触发和响应。
    set_csr(sstatus, SSTATUS_SIE); 
}

/* intr_disable - disable irq interrupt */
void intr_disable(void) { 
    //将SSTATUS寄存器的SIE位清除为0，以禁止中断触发和响应。
    clear_csr(sstatus, SSTATUS_SIE); 
}
```

总的来说，local_intr_save(intr_flag);....local_intr_restore(intr_flag);语句块用于保存和恢复中断状态。

local_intr_save(x)宏定义中，__intr_save()函数被调用来保存当前的中断状态，并将其赋值给变量x。__intr_save函数首先通过read_csr(sstatus)读取控制寄存器sstatus的值，并使用位与操作检查其中的SIE位（Supervisor Interrupt Enable）。如果SIE位为1，表示中断允许，则调用intr_disable()函数关闭中断，并返回1，表示中断状态已被保存；intr_enable函数通过调用set_csr函数，将SSTATUS寄存器的SIE位设置为1，以允许中断触发和响应。如果SIE位为0，表示中断禁止，则直接返回0，表示中断状态未被保存。

local_intr_restore(x)宏定义中，__intr_restore(x)函数被调用来恢复之前保存的中断状态。即将变量x的值作为参数传递给__intr_restore()函数，以恢复之前保存的中断状态。__intr_restore函数接受一个布尔类型的参数flag，如果flag为真，则调用intr_enable()函数开启中断；否则不执行任何操作。
intr_disable函数通过调用clear_csr函数，将SSTATUS寄存器的SIE位清除为0，以禁止中断触发和响应。

所以，通过先调用local_intr_save，后调用local_intr_restore，从而在两者之间形成了临界区，临界区前保存中断位，临界区的代码在中断关闭的状态下运行，并在临界区代码执行完毕后恢复原来的中断状态。

### 关键知识点

内核线程与用户进程的区别：

- 内核线程只运行在内核态
- 用户进程会在内核态和用户态交替运行
- 所有内核线程共用ucore内存空间，不需要为每个内核线程维护单独的内存空间
- 而用户进程需要维护各自的用户内存空间
