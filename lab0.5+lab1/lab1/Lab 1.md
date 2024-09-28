# <center>实验一：Lab0.5+Lab1</center>

<center>专业：信息安全  成员：李嘉桐 李晨阳 杨峥芃 2212023 2212731 2211819</center>



## Lab 0.5

### 1. 练习1练习过程

使用 `GDB` 调试 `QEMU` 模拟的 `RISC-V` 计算机，了解从加电到执行应用程序第一条指令（即跳转到 `0x80200000`）的过程。

在一个终端中，使用 `make debug` 启动 QEMU；
在另一个终端中，使用 `make gdb` 启动 GDB 并连接到 QEMU

当GDB启动后，在命令行输出如下所示。

```
Reading symbols from bin/kernel...     
#调试器正在从文件`bin/kernel`中读取符号表。符号表包含了程序中的函数名、全局变量等信息
The target architecture is set to "riscv:rv64".
Remote debugging using localhost:1234
0x0000000000001000 in ?? ()
#显示了当前程序计数器的位置是在地址`0x1000`处，但是函数名称未知（用`??`表示）
```

由实验指导书中可知，`QEMU`模拟的这款`riscv`处理器的**复位地址**是0x1000（所谓**复位地址**，指的是`CPU`在上电的时候，或者按下复位键的时候，`PC`被赋的初始值），与上述命令行输出匹配。

```
(gdb) x/10i $pc   #查看当前程序计数器（PC）位置开始的 10 条指令
=> 0x1000:	auipc	t0,0x0 # 将0x0的高20位与PC的低12位相加，结果存入寄存器t0，即t0=0+pc=0x1000
   0x1004:	addi	a1,t0,32  
   0x1008:	csrr	a0,mhartid  
   0x100c:	ld	t0,24(t0)  # t0=[t0+24]=0x80000000
   0x1010:	jr	t0  # 据寄存器t0中的地址跳转执行,即跳转到地址0x80000000处
   0x1014:	unimp   # 表示“未实现”
   0x1016:	unimp
   0x1018:	unimp
   0x101a:	0x8000
   0x101c:	unimp
```

**详细解释0x80000000:**
在执行这条指令之前 `t0` 寄存器的值是 `0x1000`，那么：

- 计算出的实际地址将是 `0x1000 + 24(0x0018) = 0x1018`。
- 然后使用`x/1xw 0x1018`从地址 `0x1018` 处读取 64 位的数据为 `0x80000000`。
- 最后，将读取的数据存入 `t0` 寄存器。

下面使用`si`单步执行一条汇编指令；使用`info r t0`显示 t0 寄存器的值。也证实了t0寄存器中的数据确实为 `0x80000000`。

```
(gdb) si
0x0000000000001004 in ?? ()
(gdb) info r t0
t0             0x1000	4096
(gdb) si 
0x0000000000001008 in ?? ()
(gdb) info r t0
t0             0x1000	4096
(gdb) si
0x000000000000100c in ?? ()
(gdb) info r t0
t0             0x1000	4096
(gdb) si
0x0000000000001010 in ?? ()
(gdb) info r t0
t0             0x80000000	2147483648
(gdb) si
0x0000000080000000 in ?? ()
(gdb) info r t0
t0             0x80000000	2147483648
```

由实验指导书中可知，在`QEMU`模拟的`riscv`计算机里，使用`QEMU`自带的`bootloader: OpenSBI`固件。

在 `Qemu` 开始执行任何指令之前，首先两个文件将被加载到 `Qemu` 的物理内存中：即作为 `bootloader` 的 `OpenSBI.bin` 被加载到物理内存以物理地址 `0x80000000` 开头的区域上。

使用`break *0x80000000`在`0x80000000`处设置断点；使用`continue` 执行直到碰到断点。使用`x/10i $pc`查看，如下所示：

```
gdb) break *0x80000000
Breakpoint 1 at 0x80000000
(gdb) continue
Continuing.

Breakpoint 1, 0x0000000080000000 in ?? ()
(gdb) x/10i $pc
=> 0x80000000:	csrr	a6,mhartid
   0x80000004:	bgtz	a6,0x80000108
   0x80000008:	auipc	t0,0x0  # t0=pc+(0x0<<12)=0x80000008
   0x8000000c:	addi	t0,t0,1032  # t0=t0+1032=0x80000408
   0x80000010:	auipc	t1,0x0
   0x80000014:	addi	t1,t1,-16
   0x80000018:	sd	t1,0(t0)
   0x8000001c:	auipc	t0,0x0  # t0=pc+(0x0<<12)=0x8000001c
   0x80000020:	addi	t0,t0,1020  # t0=t0+1020=0x80000400
   0x80000024:	ld	t0,0(t0)  # t0=[t0+0]=[0x80000400]
```

由实验指导书中可知，作为` bootloader` 的 `OpenSBI.bin` 被加载到物理内存以物理地址 `0x80000000` 开头的区域上，同时内核镜像 `os.bin` 被加载到以物理地址 `0x80200000` 开头的区域上。

所以使用`break *0x80200000`在`0x80200000`处设置断点；使用`continue` 执行直到碰到断点。

```
(gdb) break *0x80200000
Breakpoint 2 at 0x80200000: file kern/init/entry.S, line 7.
# GDB 显示这个断点对应于文件 `kern/init/entry.S` 的第 7 行
(gdb) continue
Continuing.

Breakpoint 2, kern_entry () at kern/init/entry.S:7
# 当前执行的函数是 `kern_entry`，位于 `kern/init/entry.S` 文件的第 7 行
7	    la sp, bootstacktop
# 将bootstacktop符号所代表的地址加载到sp寄存器中。
# 初始化堆栈指针，以便后续的函数调用可以正确地使用堆栈
```

`kern/init/entry.S`: `OpenSBI`启动之后将要跳转到的一段汇编代码。在这里进行内核栈的分配，然后转入C语言编写的内核初始化函数。
`kern/init/init.c`： C语言编写的内核入口点。主要包含`kern_init()`函数，从`kern/entry.S`跳转过来完成其他初始化工作。

使用`x/10i $pc`查看，如下所示：

```
(gdb) x/10i $pc
=> 0x80200000 <kern_entry>:	    auipc	sp,0x3
   0x80200004 <kern_entry+4>:	mv	sp,sp
   0x80200008 <kern_entry+8>:	j	0x8020000a <kern_init>  # 无条件跳转到0x8020000a <kern_init>
   0x8020000a <kern_init>:	    auipc	a0,0x3
   0x8020000e <kern_init+4>:	addi	a0,a0,-2
   0x80200012 <kern_init+8>:	auipc	a2,0x3
   0x80200016 <kern_init+12>:	addi	a2,a2,-10
   0x8020001a <kern_init+16>:	addi	sp,sp,-16
   0x8020001c <kern_init+18>:	li	a1,0
   0x8020001e <kern_init+20>:	sub	a2,a2,a0
```

所以，使用`break kern_init`在目标函数`kern_init`处设置断点，使用`continue` 执行直到碰到断点。

```
(gdb) break kern_init
Breakpoint 3 at 0x8020000a: file kern/init/init.c, line 8.
# GDB 显示这个断点对应于文件 `kern/init/init.c` 的第 8 行
(gdb) continue
Continuing.

Breakpoint 3, kern_init () at kern/init/init.c:8
8	    memset(edata, 0, end - edata);
# 将从edata开始到end结束的内存区域全部清零。这在内核初始化过程中非常常见，因为 BSS 段通常包含未初始化的全局变量和静态变量，这些变量需要在程序开始时被设置为零。
```

使用`continue` 执行，`debug`窗口出现以下输出。

```
(THU.CST) os is loading ...
```

在`gdb`窗口输入`disassemble kern_init`查看反汇编代码，如下所示：

```
(gdb) disassemble kern_init
Dump of assembler code for function kern_init:
   0x000000008020000a <+0>:	    auipc	a0,0x3
   0x000000008020000e <+4>:	    addi	a0,a0,-2 # 0x80203008
   0x0000000080200012 <+8>:	    auipc	a2,0x3
   0x0000000080200016 <+12>:	addi	a2,a2,-10 # 0x80203008
   0x000000008020001a <+16>:	addi	sp,sp,-16
   0x000000008020001c <+18>:	li	a1,0
   0x000000008020001e <+20>:	sub	a2,a2,a0
   0x0000000080200020 <+22>:	sd	ra,8(sp)
   0x0000000080200022 <+24>:	jal	ra,0x802004b6 <memset>
   0x0000000080200026 <+28>:	auipc	a1,0x0
   0x000000008020002a <+32>:	addi	a1,a1,1186 # 0x802004c8
   0x000000008020002e <+36>:	auipc	a0,0x0
   0x0000000080200032 <+40>:	addi	a0,a0,1210 # 0x802004e8
   0x0000000080200036 <+44>:	jal	ra,0x80200056 <cprintf>
=> 0x000000008020003a <+48>:	j	0x8020003a <kern_init+48>
End of assembler dump.
```

可以最后一个指令是`j 0x8020003c <kern_init+48>`，也就是跳转到自己，所以代码会在这里一直循环下去。

强制退出，在`gdb`窗口可以看到如下所示：

```c
(gdb) continue
Continuing.
^C
Program received signal SIGINT, Interrupt.
kern_init () at kern/init/init.c:12
12	   while (1)
```

打开`kern/init/init.c:12`文件，可以看到文件的具体内容如下，输出`(THU.CST) os is loading ...`之后就进入一个`while (1)`循环。

```c
#include <stdio.h>
#include <string.h>
#include <sbi.h>
int kern_init(void) __attribute__((noreturn));

int kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);

    const char *message = "(THU.CST) os is loading ...\n";
    cprintf("%s\n\n", message);
   while (1)
        ;
}
```

### 2. 练习1回答

#### 1.RISC-V硬件加电后的几条指令在哪里？

在地址 `0x1000` 到地址 `0x1010` 处

#### 2.完成了哪些功能

在 `0x1010` 处将跳转到 `0x80000000` 执行 OpenSBI 程序。具体如下所示：

- `auipc t0,0x0`：将0x0的高20位与PC的低12位相加，结果存入寄存器t0，即`t0=(0)+(pc)=0x1000`。
- `addi a1,t0,32`：将`t0`加上`32`，赋值给`a1`。
- `csrr a0,mhartid`：读取状态寄存器`mhartid`，存入`a0`中。`mhartid`为正在运行代码的硬件线程的整数ID。
- `ld t0,24(t0)`：`t0=[t0+24]=0x80000000`。 
- `jr t0`：据寄存器t0中的地址跳转执行,即跳转到地址0x80000000处，执行OpenS BI。

## Lab 1 

### 1.1 实验1的要求

- 填写各个基本练习中要求完成的报告内容

- 列出你认为本实验中重要的知识点，以及与对应的OS原理中的知识点，并简要说明你对二者的含义，关系，差异等方面的理解（也可能出现实验中的知识点没有对应的原理知识点）

- 列出你认为OS原理中很重要，但在实验中没有对应上的知识点

### 1.2.1 练习1：理解内核启动中的程序入口操作

在对所给代码的学习中，发现kern/init/entry.S由`section .text`和`section .data`两部分共同组成，代码段标识段属性为可x-执行以及a-可写；数据段用于存放堆栈数据。总体实现了定义操作系统内核启动时的堆栈设置和内核初始化调用。

```c
#include <mmu.h>
#include <memlayout.h>

    .section .text,"ax",%progbits
    .globl kern_entry
kern_entry:
    la sp, bootstacktop

    tail kern_init

.section .data
    # .align 2^12
    .align PGSHIFT
    .global bootstack
bootstack:
    .space KSTACKSIZE
    .global bootstacktop
bootstacktop:
```

- `la sp, bootstacktop`: 
  'la'(load address)，用于将符号地址加载到寄存器中。在这里是将bootstacktop标签（栈顶声明）所代表的地址存入目标寄存器sp（栈指针寄存器）。
  操作系统在启动时需要一个初始化后的栈空间，内核启动时CPU需要有一个栈来保存局部变量、函数调用信息等，此指令目的是将栈指针初始化到内核堆栈的顶部，从而实现内存栈的初始化，确保了后续操作能正确使用内核栈。
  **补充**： bootstacktop 表示bootstack （内核专用的栈区域）的顶部。而当sp为bootstacktop地址时，内核可以使用初始化栈进行函数调用和变量存储。

- `tail kern_init`: 

  tail kern_init通过tail（tail call）尾调用优化指令，直接跳转到kern_init函数并将控制权转移给它（不会保留当前函数的返回地址），kern_init是操作系统内核的初始化函数，进行内核的一系列初始化操作。
  程序将从kern_entry直接跳转到内核初始化函数 kern_init，不再需要返回到entry。此指令目的是启动内核的初始化过程，包括内存管理初始化、分页机制启用等。
  **补充**：使用尾调用，避免了堆栈的额外增长，节省资源。

### 1.2.2 **练习2：**完善中断处理 （需要编程）

请编程完善trap.c中的中断处理函数trap，在对时钟中断进行处理的部分填写kern/trap/trap.c函数中处理时钟中断的部分，使操作系统每遇到100次时钟中断后，调用print_ticks子程序，向屏幕上打印一行文字”100 ticks”，在打印完10行后调用sbi.h中的shut_down()函数关机。

要求完成问题1提出的相关函数实现，提交改进后的源代码包（可以编译执行），并在实验报告中简要说明实现过程和定时器中断中断处理的流程。实现要求的部分代码后，运行整个系统，大约每1秒会输出一次”100 ticks”，输出10行。

#### 实现过程

```c
volatile size_t num=0;

static void print_ticks() {
    cprintf("%d ticks\n", TICK_NUM);
#ifdef DEBUG_GRADE
    cprintf("End of Test.\n");
    panic("EOT: kernel seems ok.");
#endif
}

void interrupt_handler(struct trapframe *tf) {
    intptr_t cause = (tf->cause << 1) >> 1;
    switch (cause) {
        ......
        case IRQ_S_TIMER:
            clock_set_next_event();
            ticks++;
            if(ticks==TICK_NUM)
            {
                print_ticks();
                ticks=0;
                num++;
            }
            if(num==10)
            {
                sbi_shutdown();
            }
            break;
        ......
    }
}
```

这段代码中 `num`变量记录打印次数，调用 `clock_set_next_event()`设置下次始终中断，计数器 `ticks`累加记录中断次数。当操作系统每遇到100次时钟中断后，调用 `print_ticks()`，于控制台打印 `100 ticks`，同时打印次数 `num`累加，当打印完10行后，调用sbi.h中的 `shut_down()`函数关机。

#### 定时器中断处理流程

OpenSBI提供的 `sbi_set_timer()`接口，仅可以传入一个时刻，让它在那个时刻触发一次时钟中断。因此无法一次设置多个中断事件发生。于是选择初始只设置一个时钟中断，之后每次发生时钟中断时，设置下一次时钟中断的发生。 

在clock.c文件中找到如下代码，这段代码负责定时器中断的初始化和设置。它通过使用 RISC-V 的系统寄存器和 SBI（Supervisor Binary Interface）接口，来定期触发中断。。

```c
// Hardcode timebase
static uint64_t timebase = 100000;

/* *
 * clock_init - initialize 8253 clock to interrupt 100 times per second,
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
    // enable timer interrupt in sie
    set_csr(sie, MIP_STIP);
    // divided by 500 when using Spike(2MHz)
    // divided by 100 when using QEMU(10MHz)
    // timebase = sbi_timebase() / 500;
    clock_set_next_event();

    // initialize time counter 'ticks' to zero
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
```

`SIE`（Supervisor Interrupt Enable，监管者中断使能）用于控制和管理处理器的中断使能状态。因此在初始化clock时，需要先开启时钟中断的使能。接着调用 `clock_set_next_event(void)`设置时钟中断事件，使用 `sbi_set_timer()`接口，将`timer`的数值变为 `当前时间 + timebase`，即设置下次时钟中断的发生时间。

回看时钟中断处理流程：每秒发生100次时钟中断，触发每次时钟中断后设置10ms后触发下一次时钟中断，每触发100次时钟中断（1秒钟）输出 `100 ticks`到控制台。

### 1.3.0 扩展练习 Challenge1/2参考代码（trapentry.s）

```C
#include <riscv.h>

    .macro SAVE_ALL

    csrw sscratch, sp

    addi sp, sp, -36 * REGBYTES
    # save x registers
    STORE x0, 0*REGBYTES(sp)
    STORE x1, 1*REGBYTES(sp)
    STORE x3, 3*REGBYTES(sp)
    STORE x4, 4*REGBYTES(sp)
    STORE x5, 5*REGBYTES(sp)
    STORE x6, 6*REGBYTES(sp)
    STORE x7, 7*REGBYTES(sp)
    STORE x8, 8*REGBYTES(sp)
    STORE x9, 9*REGBYTES(sp)
    STORE x10, 10*REGBYTES(sp)
    STORE x11, 11*REGBYTES(sp)
    STORE x12, 12*REGBYTES(sp)
    STORE x13, 13*REGBYTES(sp)
    STORE x14, 14*REGBYTES(sp)
    STORE x15, 15*REGBYTES(sp)
    STORE x16, 16*REGBYTES(sp)
    STORE x17, 17*REGBYTES(sp)
    STORE x18, 18*REGBYTES(sp)
    STORE x19, 19*REGBYTES(sp)
    STORE x20, 20*REGBYTES(sp)
    STORE x21, 21*REGBYTES(sp)
    STORE x22, 22*REGBYTES(sp)
    STORE x23, 23*REGBYTES(sp)
    STORE x24, 24*REGBYTES(sp)
    STORE x25, 25*REGBYTES(sp)
    STORE x26, 26*REGBYTES(sp)
    STORE x27, 27*REGBYTES(sp)
    STORE x28, 28*REGBYTES(sp)
    STORE x29, 29*REGBYTES(sp)
    STORE x30, 30*REGBYTES(sp)
    STORE x31, 31*REGBYTES(sp)

    # get sr, epc, badvaddr, cause
    # Set sscratch register to 0, so that if a recursive exception
    # occurs, the exception vector knows it came from the kernel
    csrrw s0, sscratch, x0
    csrr s1, sstatus
    csrr s2, sepc
    csrr s3, sbadaddr
    csrr s4, scause

    STORE s0, 2*REGBYTES(sp)
    STORE s1, 32*REGBYTES(sp)
    STORE s2, 33*REGBYTES(sp)
    STORE s3, 34*REGBYTES(sp)
    STORE s4, 35*REGBYTES(sp)
    .endm

    .macro RESTORE_ALL

    LOAD s1, 32*REGBYTES(sp)
    LOAD s2, 33*REGBYTES(sp)

    csrw sstatus, s1
    csrw sepc, s2

    # restore x registers
    LOAD x1, 1*REGBYTES(sp)
    LOAD x3, 3*REGBYTES(sp)
    LOAD x4, 4*REGBYTES(sp)
    LOAD x5, 5*REGBYTES(sp)
    LOAD x6, 6*REGBYTES(sp)
    LOAD x7, 7*REGBYTES(sp)
    LOAD x8, 8*REGBYTES(sp)
    LOAD x9, 9*REGBYTES(sp)
    LOAD x10, 10*REGBYTES(sp)
    LOAD x11, 11*REGBYTES(sp)
    LOAD x12, 12*REGBYTES(sp)
    LOAD x13, 13*REGBYTES(sp)
    LOAD x14, 14*REGBYTES(sp)
    LOAD x15, 15*REGBYTES(sp)
    LOAD x16, 16*REGBYTES(sp)
    LOAD x17, 17*REGBYTES(sp)
    LOAD x18, 18*REGBYTES(sp)
    LOAD x19, 19*REGBYTES(sp)
    LOAD x20, 20*REGBYTES(sp)
    LOAD x21, 21*REGBYTES(sp)
    LOAD x22, 22*REGBYTES(sp)
    LOAD x23, 23*REGBYTES(sp)
    LOAD x24, 24*REGBYTES(sp)
    LOAD x25, 25*REGBYTES(sp)
    LOAD x26, 26*REGBYTES(sp)
    LOAD x27, 27*REGBYTES(sp)
    LOAD x28, 28*REGBYTES(sp)
    LOAD x29, 29*REGBYTES(sp)
    LOAD x30, 30*REGBYTES(sp)
    LOAD x31, 31*REGBYTES(sp)
    # restore sp last
    LOAD x2, 2*REGBYTES(sp)
    #addi sp, sp, 36 * REGBYTES
    .endm

    .globl __alltraps
.align(2)
__alltraps:
    SAVE_ALL

    move  a0, sp
    jal trap
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
    # return from supervisor call
    sret
```

### 1.3.1 扩展练习 Challenge1：描述与理解中断流程

描述`ucore`中处理中断异常的流程（从异常的产生开始），其中`mov a0，sp`的目的是什么？`SAVE_ALL`中寄存器保存在栈中的位置是什么确定的？对于任何中断，`__alltraps`中都需要保存所有寄存器吗？请说明理由。

#### Q1：ucore中处理中断异常的流程

**中断异常产生**

- 操作系统处理器检测到异常或中断（例如系统调用、地址错误等）。
- 中断分为异常（Exception）陷入（Trap）、外部中断（Interrupt）。
- 保存当前的程序计数器到 sepc 寄存器，设置 scause 寄存器，指示异常原因。

**定位中断处理程序**

在中断或异常发生后，跳转到异常向量表中的相应入口（此次实验中 stvec值设置成为中断入口点__alltraps地址），执行处理程序的入口代码。

- 操作系统会根据stvex把不同种类的中断映射到对应的中断处理程序。
- stvec寄存器最低2位是00——高位保存的是唯一的中断处理程序的地址；是01——高位保存的是中断向量表的地址。

**保存上下文（`SAVE_ALL` 宏）**

SAVE_ALL 负责将当前 CPU 的寄存器状态保存到栈中，以便在处理中断或异常时不丢失寄存器的值。依次将所有重要的寄存器（包括 x0 到x31，以及一些状态寄存器如 sepc 和 scause 等）保存到内核栈上，并将上下文包装成结构体送入对应的中断处理程序。

**中断处理**

- 通过 jal trap 跳转到异常处理函数 trap()，进行具体的中断或异常处理。
- 根据sscratch来判断是内核态产生的中断还是用户态产生的中断，根据scause把中断处理、异常处理的工作分别交给interrupt_handler()或exception_handler()函数来进行处理。

**恢复上下文（`RESTORE_ALL` 宏）**

当异常处理完成后，ucore 会将保存在内核栈上的上下文信息恢复回来，RESTORE_ALL宏会从栈中恢复寄存器的值，将寄存器的状态恢复到中断或异常发生之前的状态。

**返回到原程序继续执行**

使用 sret 指令恢复并继续执行被打断的程序，也即通过sepc值给到pc，恢复到之前被中断的指令地址并继续执行。

#### **Q2：`mov a0, sp` 的目的**

将栈指针sp的值传递给a0寄存器，目的是将当前栈的地址作为参数传递给异常处理函数trap()。在处理函数中，a0寄存器是参数寄存器通常用于传递参数，当前栈指针可以为异常处理函数提供必要的上下文信息，从而实现中断处理。

#### Q3：`SAVE_ALL` 中寄存器保存在栈中的位置

`SAVE_ALL` 宏使用栈指针sp依次保存每个寄存器到栈中，并根据寄存器编号为每个寄存器分配空间。

- 首先通过指令`addi sp, sp, -36 * REGBYTES`，在内存中开辟出了保存上下文的内存区域，而后进行sp的移动保存。

- x0 寄存器保存到栈的 0 * REGBYTES偏移位置，
- 寄存器依次保存到相对于 sp不同偏移量的栈位置。

#### Q4：__alltraps是否需要保存所有寄存器

并不是，寄存器的保存和恢复方式可以根据具体的中断或异常处理需求进行灵活调整。理由如下：

- 中断和异常是异步事件，可能在任何时候发生，而 CPU 中的寄存器可能包含着重要的数据。为了确保中断处理程序不影响被打断的程序的状态，所有寄存器（包括 x0 到 x31，状态寄存器等）都需要保存。
- 但是，对于某些中断，其处理程序可能只会用到部分寄存器，也只需要将这些寄存器保存下来即可，全部保存会导致系统的性能和效率大大降低；而且有很多寄存器的值实际上是不会受中断影响而改变的，也不用保存，降低程序开销。在本次的实验中，可以看到在SAVE_ALL中，从x0-x31中的通用寄存器被保存在栈上，但只有x0、x1、x3-x31的通用寄存器被恢复，这就代表着大部分没有修改，无需浪费空间。

### 1.3.2 扩展练习 Challenge2：理解上下文切换机制

回答：在trapentry.S中汇编代码 csrw sscratch, sp；csrrw s0, sscratch, x0实现了什么操作，目的是什么？save all里面保存了stval scause这些csr，而在restore all里面却不还原它们？那这样store的意义何在呢？**csrw sscratch, sp：**

**操作：**将当前的栈指针 (sp) 值写入到 sscratch 寄存器。csrw 是 RISC-V 的 CSR（控制和状态寄存器）操作指令，意思是将通用寄存器的值写入到特定的 CSR 寄存器，在这里sscratch 就是要写入的CSR寄存器。

**作用：**sscratch寄存器通常在异常处理期间用作保存一些临时信息。在进入中断或异常时，sscratch 可以用来存储临时数据，方便异常处理完成后恢复系统状态。栈指针 sp 保存了当前函数调用栈的地址，因此它会随程序的执行动态变化。在这里，将 sp 存储到 sscratch 中，确保在异常处理期间不会丢失栈指针的值。

**csrrw s0, sscratch, x0：**

**操作：**交换 sscratch 寄存器和 s0 寄存器的值，同时将 x0 的值（恒为0）写入sscratch。csrrw 是 CSR 读-写-交换指令，它将 sscratch 的当前值读入到寄存器 s0，并将 x0（即 0）的值写入到 sscratch。
s0 寄存器（也叫 x8）是通用寄存器，可以用于保存中间值。此操作会将 sscratch 中保存的 sp 值传送到 s0 中，同时将 sscratch 寄存器清零（因为 x0 恒为 0）。

**作用：**通过这个操作，原本存放在 sscratch 中的栈指针被临时保存在 s0 中，而 sscratch 被清零，用于后续的处理。如果再发生新的异常，sscratch 为零能够让异常处理程序区分当前状态是否在内核中处理异常。

**为什么不还原：**

stval（即sbadaddr）和scause等寄存器只在进入异常时有意义，它们记录了异常发生时的状态。异常处理完成后，程序将恢复正常执行，这时这些寄存器的值对后续正常的程序执行没有影响。因此，不需要将它们还原。
这些寄存器的值是只在异常处理程序中有用，恢复原来的执行状态时，不需要再用之前保存的值，因此不进行还原。

**保存的原因：**

在发生异常或中断时，stval和scause等寄存器包含了异常的具体原因和相关的地址信息。这些寄存器保存的值是非常重要的调试信息，它们用于解释异常是如何发生的、哪条指令或数据引发了问题。因此，将这些寄存器保存到栈中是为了让异常处理程序能够访问这些信息，进行适当的处理、调试或日志记录。

### 1.3.3 扩展练习 Challenge3：完善异常中断

编程完善在触发一条非法指令异常 mret和，在 kern/trap/trap.c的异常处理函数中捕获，并对其进行处理，简单输出异常类型和异常指令触发地址，即“Illegal instruction caught at 0x(地址)”，“ebreak caught at 0x（地址）”与“Exception type:Illegal instruction"，“Exception type: breakpoint”。为了实现此二者，我们在kern/init/init.c中添加ebreak和mert指令的汇编代码：

```c
    asm volatile("mret"); //  插入无效指令
    asm volatile("ebreak"); // 插入断点指令
```

在kern/trap/trap.c中进行更新，完善代码，在exception_handler()中进行增添，查阅参考资料：实际上此时ebreak设置环境断点调用的是16位的指令c.ebreak，而不是32位的break。因此在对应的打印语句后，应该分别更新epc为 +4和 +2：

```c
        case CAUSE_ILLEGAL_INSTRUCTION:
             // 非法指令异常处理
             /* LAB1 CHALLENGE3   YOUR CODE : 2212023 2212731 2211819 */
            cprintf("Exception type:Illegal instruction\n");
            cprintf("Illegal instruction caught at 0x%p\n",tf->epc);
            tf->epc+=4;
            break;
        case CAUSE_BREAKPOINT:
            //断点异常处理
            /* LAB1 CHALLLENGE3   YOUR CODE : 2212023 2212731 2211819 */
            cprintf("Exception type:breakpoint\n");
            cprintf("breakpoint caught at 0x%p\n",tf->epc);
            tf->epc+=2;
            break;
```

make qume:

```plaintxt
lml@lml-virtual-machine:~/riscv64-ucore-labcodes/lab1$ make qemu
+ cc kern/init/entry.S
+ cc kern/init/init.c
+ cc kern/libs/stdio.c
+ cc kern/debug/kdebug.c
+ cc kern/debug/kmonitor.c
+ cc kern/debug/panic.c
+ cc kern/driver/clock.c
+ cc kern/driver/console.c
+ cc kern/driver/intr.c
+ cc kern/trap/trap.c
+ cc kern/trap/trapentry.S
+ cc kern/mm/pmm.c
+ cc libs/printfmt.c
+ cc libs/readline.c
+ cc libs/sbi.c
+ cc libs/string.c
+ ld bin/kernel
riscv64-unknown-elf-objcopy bin/kernel --strip-all -O binary bin/ucore.img

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
  entry  0x000000008020000a (virtual)
  etext  0x0000000080200a30 (virtual)
  edata  0x0000000080204010 (virtual)
  end    0x0000000080204028 (virtual)
Kernel executable memory footprint: 17KB
++ setup timer interrupts
sbi_emulate_csr_read: hartid0: invalid csr_num=0x302
Exception type:Illegal instruction
Illegal instruction caught at 0x0x8020004e
Exception type:breakpoint
breakpoint caught at 0x0x80200052
100 ticks
100 ticks
100 ticks
100 ticks
100 ticks
100 ticks
100 ticks
100 ticks
100 ticks
100 ticks
```

正常打印十次 `100ticks`并退出,完成！

## 重要知识点

### Lab 0.5

BootLoader的启动分为两个阶段:
(1)第一个阶段通常用汇编语言来实现，包含依赖于CPU的体系架构的硬件的初始化代码。该阶段的任务:
1.对硬件设备进行初始化(如屏蔽所有中断，关闭处理器内部指令/数据Cache等)2.为第二阶段准备RAM空间;
3.复制BootLoader的第二阶段代码到RAM中;4.设置堆栈为第二阶段的C语言环境做准备。第一阶段关闭Cache的原因:通常使用Cache是为了提高系统性能，但此时Cache的使用可能改变访问主存的数量，类型或时间，BootLoader是不需要的，即BootLoader直接访问主存即可不需要通过缓存来访问。
(2)第一阶段执行完会跳转到第二阶段的C程序入口点，该阶段是由C语言完成，以便实现更复杂的功能，也是程序有更好的可读性和可移植性。该阶段的任务:1.初始化本阶段要用到的硬件设备;
2.检测系统的内存映射;
3.将操作系统程序从Flash读到RAM;
4.为操作系统设置启动参数;
5.调用操作系统代码进行启动

固件(firmware)是一种特定的计算机软件，它为设备的特定硬件提供低级控制，也可以进一步加载其他软件。固件可以为设备更复杂的软件(如操作系统)提供标准化的操作环境。对于不太复杂的设备，固件可以直接充当设备的完整操作系统，执行所有控制、监视和数据操作功能。在是于 x86 的计算机系统中,BIOS 或 UEF| 是固件;在基于 riscv 的计算机系统中，OpenSBl 是固件。OpenSBl运行在M态(M-mode)，因为固件需要直接访问硬件。地址无关代码(PIC):
使得码可以在任何内存地址执行而无需修改且不依赖于程序在内存中的特定位置
优点:*灵活性:代码可以在任意内存地址执行，且无需重新编译。加载时不必进行地址重定位。*节省内存:多个进程可以共享相同的代码段，减少了内存占用，因为每个进程都可以将该代码映射到不同的地址空间。
缺点:
*性能开销:PIC 在某些情况下可能会导致较小的性能损失，特别是在函数调用和全局变量访问时。### 地址相关代码(PDC):
地址相关代码依赖于它在内存中的固定位置，即在编译时，代码生成时已经假定了它将在某个固定的地址上执行。该代码如果加载到不同的地址，必须进行重定位或重新编译，
优点:
*简单高效:由于直接使用绝对地址，代码在执行时不需要计算相对地址，因此访问内存和函数时的性能较好

地址相关代码依赖于它在内存中的固定位置，即在编译时，代码生成时已经假定了它将在某个固定的地址上执行。该代码如果加载到不同的地址，必须进行重定位或重新编译。
优点:
*简单高效:由于直接使用绝对地址，代码在执行时不需要计算相对地址，因此访问内存和函数
时的性能较好。
缺点:
缺乏灵活性:代码只能在特定的地址运行，如果要加载到不同地址，必须进行重定位。

### Lab 1

1. 上下文环境的保存与恢复

   中断与异常发生时，进行上下文切换——对应操作系统的进程切换：

     1. 当操作系统终止当前进程时，将通用寄存器的值保存到内存或堆栈中->保存特殊寄存器的值（CSR）->保存pc、sp等；
     2. 根据中断或异常类型执行相应的函数，进行相应的操作；
     3. 恢复寄存器状态->恢复pc、sp等->恢复csr等，根据需要，有些csr不用恢复。

2. 时钟中断的处理

   1. 中断请求被处理器接收后，处理器会根据中断向量表（Interrupt Vector Table）或中断描述符来查找与时钟中断相关联的中断处理程序->保存任务的上下文环境->时钟中断处理->恢复上下文

    2. 时钟中断处理程序执行的与时钟中断相关的操作：
       1. 更新任务的时间片（如果采用时间片轮转调度）；
       2. 执行任务切换，选择下一个要运行的任务；s
       3. 更新系统时间，维护系统时钟；
       4. 处理与时间相关的任务，例如定时器事件等。

3. 程序入口和内核初始化

## 未出现要点