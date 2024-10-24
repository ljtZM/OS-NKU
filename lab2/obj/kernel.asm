
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:

    .section .text,"ax",%progbits
    .globl kern_entry
kern_entry:
    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200000:	c02052b7          	lui	t0,0xc0205
    # t1 := 0xffffffff40000000 即虚实映射偏移量
    li      t1, 0xffffffffc0000000 - 0x80000000
ffffffffc0200004:	ffd0031b          	addiw	t1,zero,-3
ffffffffc0200008:	037a                	slli	t1,t1,0x1e
    # t0 减去虚实映射偏移量 0xffffffff40000000，变为三级页表的物理地址
    sub     t0, t0, t1
ffffffffc020000a:	406282b3          	sub	t0,t0,t1
    # t0 >>= 12，变为三级页表的物理页号
    srli    t0, t0, 12
ffffffffc020000e:	00c2d293          	srli	t0,t0,0xc

    # t1 := 8 << 60，设置 satp 的 MODE 字段为 Sv39
    li      t1, 8 << 60
ffffffffc0200012:	fff0031b          	addiw	t1,zero,-1
ffffffffc0200016:	137e                	slli	t1,t1,0x3f
    # 将刚才计算出的预设三级页表物理页号附加到 satp 中
    or      t0, t0, t1
ffffffffc0200018:	0062e2b3          	or	t0,t0,t1
    # 将算出的 t0(即新的MODE|页表基址物理页号) 覆盖到 satp 中
    csrw    satp, t0
ffffffffc020001c:	18029073          	csrw	satp,t0
    # 使用 sfence.vma 指令刷新 TLB
    sfence.vma
ffffffffc0200020:	12000073          	sfence.vma
    # 从此，我们给内核搭建出了一个完美的虚拟内存空间！
    #nop # 可能映射的位置有些bug。。插入一个nop
    
    # 我们在虚拟内存空间中：随意将 sp 设置为虚拟地址！
    lui sp, %hi(bootstacktop)
ffffffffc0200024:	c0205137          	lui	sp,0xc0205

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc0200028:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc020002c:	03228293          	addi	t0,t0,50 # ffffffffc0200032 <kern_init>
    jr t0
ffffffffc0200030:	8282                	jr	t0

ffffffffc0200032 <kern_init>:
void grade_backtrace(void);


int kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc0200032:	00006517          	auipc	a0,0x6
ffffffffc0200036:	ff650513          	addi	a0,a0,-10 # ffffffffc0206028 <free_area>
ffffffffc020003a:	00006617          	auipc	a2,0x6
ffffffffc020003e:	44e60613          	addi	a2,a2,1102 # ffffffffc0206488 <end>
int kern_init(void) {
ffffffffc0200042:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc0200044:	8e09                	sub	a2,a2,a0
ffffffffc0200046:	4581                	li	a1,0
int kern_init(void) {
ffffffffc0200048:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc020004a:	54b010ef          	jal	ra,ffffffffc0201d94 <memset>
    cons_init();  // init the console
ffffffffc020004e:	404000ef          	jal	ra,ffffffffc0200452 <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc0200052:	00002517          	auipc	a0,0x2
ffffffffc0200056:	d5650513          	addi	a0,a0,-682 # ffffffffc0201da8 <etext+0x2>
ffffffffc020005a:	098000ef          	jal	ra,ffffffffc02000f2 <cputs>

    print_kerninfo();
ffffffffc020005e:	0e4000ef          	jal	ra,ffffffffc0200142 <print_kerninfo>

    // grade_backtrace();
    idt_init();  // init interrupt descriptor table
ffffffffc0200062:	40a000ef          	jal	ra,ffffffffc020046c <idt_init>

    pmm_init();  // init physical memory management
ffffffffc0200066:	268010ef          	jal	ra,ffffffffc02012ce <pmm_init>

    idt_init();  // init interrupt descriptor table
ffffffffc020006a:	402000ef          	jal	ra,ffffffffc020046c <idt_init>

    clock_init();   // init clock interrupt
ffffffffc020006e:	3a2000ef          	jal	ra,ffffffffc0200410 <clock_init>
    intr_enable();  // enable irq interrupt
ffffffffc0200072:	3ee000ef          	jal	ra,ffffffffc0200460 <intr_enable>
    
    slub_init();
ffffffffc0200076:	5b2010ef          	jal	ra,ffffffffc0201628 <slub_init>
    slub_test();
ffffffffc020007a:	5ba010ef          	jal	ra,ffffffffc0201634 <slub_test>


    /* do nothing */
    while (1)
ffffffffc020007e:	a001                	j	ffffffffc020007e <kern_init+0x4c>

ffffffffc0200080 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc0200080:	1141                	addi	sp,sp,-16
ffffffffc0200082:	e022                	sd	s0,0(sp)
ffffffffc0200084:	e406                	sd	ra,8(sp)
ffffffffc0200086:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc0200088:	3cc000ef          	jal	ra,ffffffffc0200454 <cons_putc>
    (*cnt) ++;
ffffffffc020008c:	401c                	lw	a5,0(s0)
}
ffffffffc020008e:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc0200090:	2785                	addiw	a5,a5,1
ffffffffc0200092:	c01c                	sw	a5,0(s0)
}
ffffffffc0200094:	6402                	ld	s0,0(sp)
ffffffffc0200096:	0141                	addi	sp,sp,16
ffffffffc0200098:	8082                	ret

ffffffffc020009a <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc020009a:	1101                	addi	sp,sp,-32
ffffffffc020009c:	862a                	mv	a2,a0
ffffffffc020009e:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000a0:	00000517          	auipc	a0,0x0
ffffffffc02000a4:	fe050513          	addi	a0,a0,-32 # ffffffffc0200080 <cputch>
ffffffffc02000a8:	006c                	addi	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
ffffffffc02000aa:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc02000ac:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000ae:	011010ef          	jal	ra,ffffffffc02018be <vprintfmt>
    return cnt;
}
ffffffffc02000b2:	60e2                	ld	ra,24(sp)
ffffffffc02000b4:	4532                	lw	a0,12(sp)
ffffffffc02000b6:	6105                	addi	sp,sp,32
ffffffffc02000b8:	8082                	ret

ffffffffc02000ba <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc02000ba:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc02000bc:	02810313          	addi	t1,sp,40 # ffffffffc0205028 <boot_page_table_sv39+0x28>
cprintf(const char *fmt, ...) {
ffffffffc02000c0:	8e2a                	mv	t3,a0
ffffffffc02000c2:	f42e                	sd	a1,40(sp)
ffffffffc02000c4:	f832                	sd	a2,48(sp)
ffffffffc02000c6:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000c8:	00000517          	auipc	a0,0x0
ffffffffc02000cc:	fb850513          	addi	a0,a0,-72 # ffffffffc0200080 <cputch>
ffffffffc02000d0:	004c                	addi	a1,sp,4
ffffffffc02000d2:	869a                	mv	a3,t1
ffffffffc02000d4:	8672                	mv	a2,t3
cprintf(const char *fmt, ...) {
ffffffffc02000d6:	ec06                	sd	ra,24(sp)
ffffffffc02000d8:	e0ba                	sd	a4,64(sp)
ffffffffc02000da:	e4be                	sd	a5,72(sp)
ffffffffc02000dc:	e8c2                	sd	a6,80(sp)
ffffffffc02000de:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc02000e0:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc02000e2:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000e4:	7da010ef          	jal	ra,ffffffffc02018be <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc02000e8:	60e2                	ld	ra,24(sp)
ffffffffc02000ea:	4512                	lw	a0,4(sp)
ffffffffc02000ec:	6125                	addi	sp,sp,96
ffffffffc02000ee:	8082                	ret

ffffffffc02000f0 <cputchar>:

/* cputchar - writes a single character to stdout */
void
cputchar(int c) {
    cons_putc(c);
ffffffffc02000f0:	a695                	j	ffffffffc0200454 <cons_putc>

ffffffffc02000f2 <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc02000f2:	1101                	addi	sp,sp,-32
ffffffffc02000f4:	e822                	sd	s0,16(sp)
ffffffffc02000f6:	ec06                	sd	ra,24(sp)
ffffffffc02000f8:	e426                	sd	s1,8(sp)
ffffffffc02000fa:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc02000fc:	00054503          	lbu	a0,0(a0)
ffffffffc0200100:	c51d                	beqz	a0,ffffffffc020012e <cputs+0x3c>
ffffffffc0200102:	0405                	addi	s0,s0,1
ffffffffc0200104:	4485                	li	s1,1
ffffffffc0200106:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc0200108:	34c000ef          	jal	ra,ffffffffc0200454 <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc020010c:	00044503          	lbu	a0,0(s0)
ffffffffc0200110:	008487bb          	addw	a5,s1,s0
ffffffffc0200114:	0405                	addi	s0,s0,1
ffffffffc0200116:	f96d                	bnez	a0,ffffffffc0200108 <cputs+0x16>
    (*cnt) ++;
ffffffffc0200118:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc020011c:	4529                	li	a0,10
ffffffffc020011e:	336000ef          	jal	ra,ffffffffc0200454 <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc0200122:	60e2                	ld	ra,24(sp)
ffffffffc0200124:	8522                	mv	a0,s0
ffffffffc0200126:	6442                	ld	s0,16(sp)
ffffffffc0200128:	64a2                	ld	s1,8(sp)
ffffffffc020012a:	6105                	addi	sp,sp,32
ffffffffc020012c:	8082                	ret
    while ((c = *str ++) != '\0') {
ffffffffc020012e:	4405                	li	s0,1
ffffffffc0200130:	b7f5                	j	ffffffffc020011c <cputs+0x2a>

ffffffffc0200132 <getchar>:

/* getchar - reads a single non-zero character from stdin */
int
getchar(void) {
ffffffffc0200132:	1141                	addi	sp,sp,-16
ffffffffc0200134:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc0200136:	326000ef          	jal	ra,ffffffffc020045c <cons_getc>
ffffffffc020013a:	dd75                	beqz	a0,ffffffffc0200136 <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc020013c:	60a2                	ld	ra,8(sp)
ffffffffc020013e:	0141                	addi	sp,sp,16
ffffffffc0200140:	8082                	ret

ffffffffc0200142 <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc0200142:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc0200144:	00002517          	auipc	a0,0x2
ffffffffc0200148:	c8450513          	addi	a0,a0,-892 # ffffffffc0201dc8 <etext+0x22>
void print_kerninfo(void) {
ffffffffc020014c:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc020014e:	f6dff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", kern_init);
ffffffffc0200152:	00000597          	auipc	a1,0x0
ffffffffc0200156:	ee058593          	addi	a1,a1,-288 # ffffffffc0200032 <kern_init>
ffffffffc020015a:	00002517          	auipc	a0,0x2
ffffffffc020015e:	c8e50513          	addi	a0,a0,-882 # ffffffffc0201de8 <etext+0x42>
ffffffffc0200162:	f59ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc0200166:	00002597          	auipc	a1,0x2
ffffffffc020016a:	c4058593          	addi	a1,a1,-960 # ffffffffc0201da6 <etext>
ffffffffc020016e:	00002517          	auipc	a0,0x2
ffffffffc0200172:	c9a50513          	addi	a0,a0,-870 # ffffffffc0201e08 <etext+0x62>
ffffffffc0200176:	f45ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc020017a:	00006597          	auipc	a1,0x6
ffffffffc020017e:	eae58593          	addi	a1,a1,-338 # ffffffffc0206028 <free_area>
ffffffffc0200182:	00002517          	auipc	a0,0x2
ffffffffc0200186:	ca650513          	addi	a0,a0,-858 # ffffffffc0201e28 <etext+0x82>
ffffffffc020018a:	f31ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc020018e:	00006597          	auipc	a1,0x6
ffffffffc0200192:	2fa58593          	addi	a1,a1,762 # ffffffffc0206488 <end>
ffffffffc0200196:	00002517          	auipc	a0,0x2
ffffffffc020019a:	cb250513          	addi	a0,a0,-846 # ffffffffc0201e48 <etext+0xa2>
ffffffffc020019e:	f1dff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc02001a2:	00006597          	auipc	a1,0x6
ffffffffc02001a6:	6e558593          	addi	a1,a1,1765 # ffffffffc0206887 <end+0x3ff>
ffffffffc02001aa:	00000797          	auipc	a5,0x0
ffffffffc02001ae:	e8878793          	addi	a5,a5,-376 # ffffffffc0200032 <kern_init>
ffffffffc02001b2:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001b6:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc02001ba:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001bc:	3ff5f593          	andi	a1,a1,1023
ffffffffc02001c0:	95be                	add	a1,a1,a5
ffffffffc02001c2:	85a9                	srai	a1,a1,0xa
ffffffffc02001c4:	00002517          	auipc	a0,0x2
ffffffffc02001c8:	ca450513          	addi	a0,a0,-860 # ffffffffc0201e68 <etext+0xc2>
}
ffffffffc02001cc:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001ce:	b5f5                	j	ffffffffc02000ba <cprintf>

ffffffffc02001d0 <print_stackframe>:
 * Note that, the length of ebp-chain is limited. In boot/bootasm.S, before
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void) {
ffffffffc02001d0:	1141                	addi	sp,sp,-16

    panic("Not Implemented!");
ffffffffc02001d2:	00002617          	auipc	a2,0x2
ffffffffc02001d6:	cc660613          	addi	a2,a2,-826 # ffffffffc0201e98 <etext+0xf2>
ffffffffc02001da:	04e00593          	li	a1,78
ffffffffc02001de:	00002517          	auipc	a0,0x2
ffffffffc02001e2:	cd250513          	addi	a0,a0,-814 # ffffffffc0201eb0 <etext+0x10a>
void print_stackframe(void) {
ffffffffc02001e6:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc02001e8:	1cc000ef          	jal	ra,ffffffffc02003b4 <__panic>

ffffffffc02001ec <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc02001ec:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02001ee:	00002617          	auipc	a2,0x2
ffffffffc02001f2:	cda60613          	addi	a2,a2,-806 # ffffffffc0201ec8 <etext+0x122>
ffffffffc02001f6:	00002597          	auipc	a1,0x2
ffffffffc02001fa:	cf258593          	addi	a1,a1,-782 # ffffffffc0201ee8 <etext+0x142>
ffffffffc02001fe:	00002517          	auipc	a0,0x2
ffffffffc0200202:	cf250513          	addi	a0,a0,-782 # ffffffffc0201ef0 <etext+0x14a>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200206:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc0200208:	eb3ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
ffffffffc020020c:	00002617          	auipc	a2,0x2
ffffffffc0200210:	cf460613          	addi	a2,a2,-780 # ffffffffc0201f00 <etext+0x15a>
ffffffffc0200214:	00002597          	auipc	a1,0x2
ffffffffc0200218:	d1458593          	addi	a1,a1,-748 # ffffffffc0201f28 <etext+0x182>
ffffffffc020021c:	00002517          	auipc	a0,0x2
ffffffffc0200220:	cd450513          	addi	a0,a0,-812 # ffffffffc0201ef0 <etext+0x14a>
ffffffffc0200224:	e97ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
ffffffffc0200228:	00002617          	auipc	a2,0x2
ffffffffc020022c:	d1060613          	addi	a2,a2,-752 # ffffffffc0201f38 <etext+0x192>
ffffffffc0200230:	00002597          	auipc	a1,0x2
ffffffffc0200234:	d2858593          	addi	a1,a1,-728 # ffffffffc0201f58 <etext+0x1b2>
ffffffffc0200238:	00002517          	auipc	a0,0x2
ffffffffc020023c:	cb850513          	addi	a0,a0,-840 # ffffffffc0201ef0 <etext+0x14a>
ffffffffc0200240:	e7bff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    }
    return 0;
}
ffffffffc0200244:	60a2                	ld	ra,8(sp)
ffffffffc0200246:	4501                	li	a0,0
ffffffffc0200248:	0141                	addi	sp,sp,16
ffffffffc020024a:	8082                	ret

ffffffffc020024c <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc020024c:	1141                	addi	sp,sp,-16
ffffffffc020024e:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc0200250:	ef3ff0ef          	jal	ra,ffffffffc0200142 <print_kerninfo>
    return 0;
}
ffffffffc0200254:	60a2                	ld	ra,8(sp)
ffffffffc0200256:	4501                	li	a0,0
ffffffffc0200258:	0141                	addi	sp,sp,16
ffffffffc020025a:	8082                	ret

ffffffffc020025c <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc020025c:	1141                	addi	sp,sp,-16
ffffffffc020025e:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc0200260:	f71ff0ef          	jal	ra,ffffffffc02001d0 <print_stackframe>
    return 0;
}
ffffffffc0200264:	60a2                	ld	ra,8(sp)
ffffffffc0200266:	4501                	li	a0,0
ffffffffc0200268:	0141                	addi	sp,sp,16
ffffffffc020026a:	8082                	ret

ffffffffc020026c <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc020026c:	7115                	addi	sp,sp,-224
ffffffffc020026e:	ed5e                	sd	s7,152(sp)
ffffffffc0200270:	8baa                	mv	s7,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200272:	00002517          	auipc	a0,0x2
ffffffffc0200276:	cf650513          	addi	a0,a0,-778 # ffffffffc0201f68 <etext+0x1c2>
kmonitor(struct trapframe *tf) {
ffffffffc020027a:	ed86                	sd	ra,216(sp)
ffffffffc020027c:	e9a2                	sd	s0,208(sp)
ffffffffc020027e:	e5a6                	sd	s1,200(sp)
ffffffffc0200280:	e1ca                	sd	s2,192(sp)
ffffffffc0200282:	fd4e                	sd	s3,184(sp)
ffffffffc0200284:	f952                	sd	s4,176(sp)
ffffffffc0200286:	f556                	sd	s5,168(sp)
ffffffffc0200288:	f15a                	sd	s6,160(sp)
ffffffffc020028a:	e962                	sd	s8,144(sp)
ffffffffc020028c:	e566                	sd	s9,136(sp)
ffffffffc020028e:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200290:	e2bff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc0200294:	00002517          	auipc	a0,0x2
ffffffffc0200298:	cfc50513          	addi	a0,a0,-772 # ffffffffc0201f90 <etext+0x1ea>
ffffffffc020029c:	e1fff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    if (tf != NULL) {
ffffffffc02002a0:	000b8563          	beqz	s7,ffffffffc02002aa <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc02002a4:	855e                	mv	a0,s7
ffffffffc02002a6:	3a4000ef          	jal	ra,ffffffffc020064a <print_trapframe>
ffffffffc02002aa:	00002c17          	auipc	s8,0x2
ffffffffc02002ae:	d56c0c13          	addi	s8,s8,-682 # ffffffffc0202000 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02002b2:	00002917          	auipc	s2,0x2
ffffffffc02002b6:	d0690913          	addi	s2,s2,-762 # ffffffffc0201fb8 <etext+0x212>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002ba:	00002497          	auipc	s1,0x2
ffffffffc02002be:	d0648493          	addi	s1,s1,-762 # ffffffffc0201fc0 <etext+0x21a>
        if (argc == MAXARGS - 1) {
ffffffffc02002c2:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc02002c4:	00002b17          	auipc	s6,0x2
ffffffffc02002c8:	d04b0b13          	addi	s6,s6,-764 # ffffffffc0201fc8 <etext+0x222>
        argv[argc ++] = buf;
ffffffffc02002cc:	00002a17          	auipc	s4,0x2
ffffffffc02002d0:	c1ca0a13          	addi	s4,s4,-996 # ffffffffc0201ee8 <etext+0x142>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002d4:	4a8d                	li	s5,3
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02002d6:	854a                	mv	a0,s2
ffffffffc02002d8:	169010ef          	jal	ra,ffffffffc0201c40 <readline>
ffffffffc02002dc:	842a                	mv	s0,a0
ffffffffc02002de:	dd65                	beqz	a0,ffffffffc02002d6 <kmonitor+0x6a>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002e0:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc02002e4:	4c81                	li	s9,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002e6:	e1bd                	bnez	a1,ffffffffc020034c <kmonitor+0xe0>
    if (argc == 0) {
ffffffffc02002e8:	fe0c87e3          	beqz	s9,ffffffffc02002d6 <kmonitor+0x6a>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02002ec:	6582                	ld	a1,0(sp)
ffffffffc02002ee:	00002d17          	auipc	s10,0x2
ffffffffc02002f2:	d12d0d13          	addi	s10,s10,-750 # ffffffffc0202000 <commands>
        argv[argc ++] = buf;
ffffffffc02002f6:	8552                	mv	a0,s4
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002f8:	4401                	li	s0,0
ffffffffc02002fa:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02002fc:	265010ef          	jal	ra,ffffffffc0201d60 <strcmp>
ffffffffc0200300:	c919                	beqz	a0,ffffffffc0200316 <kmonitor+0xaa>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200302:	2405                	addiw	s0,s0,1
ffffffffc0200304:	0b540063          	beq	s0,s5,ffffffffc02003a4 <kmonitor+0x138>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200308:	000d3503          	ld	a0,0(s10)
ffffffffc020030c:	6582                	ld	a1,0(sp)
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020030e:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200310:	251010ef          	jal	ra,ffffffffc0201d60 <strcmp>
ffffffffc0200314:	f57d                	bnez	a0,ffffffffc0200302 <kmonitor+0x96>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc0200316:	00141793          	slli	a5,s0,0x1
ffffffffc020031a:	97a2                	add	a5,a5,s0
ffffffffc020031c:	078e                	slli	a5,a5,0x3
ffffffffc020031e:	97e2                	add	a5,a5,s8
ffffffffc0200320:	6b9c                	ld	a5,16(a5)
ffffffffc0200322:	865e                	mv	a2,s7
ffffffffc0200324:	002c                	addi	a1,sp,8
ffffffffc0200326:	fffc851b          	addiw	a0,s9,-1
ffffffffc020032a:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc020032c:	fa0555e3          	bgez	a0,ffffffffc02002d6 <kmonitor+0x6a>
}
ffffffffc0200330:	60ee                	ld	ra,216(sp)
ffffffffc0200332:	644e                	ld	s0,208(sp)
ffffffffc0200334:	64ae                	ld	s1,200(sp)
ffffffffc0200336:	690e                	ld	s2,192(sp)
ffffffffc0200338:	79ea                	ld	s3,184(sp)
ffffffffc020033a:	7a4a                	ld	s4,176(sp)
ffffffffc020033c:	7aaa                	ld	s5,168(sp)
ffffffffc020033e:	7b0a                	ld	s6,160(sp)
ffffffffc0200340:	6bea                	ld	s7,152(sp)
ffffffffc0200342:	6c4a                	ld	s8,144(sp)
ffffffffc0200344:	6caa                	ld	s9,136(sp)
ffffffffc0200346:	6d0a                	ld	s10,128(sp)
ffffffffc0200348:	612d                	addi	sp,sp,224
ffffffffc020034a:	8082                	ret
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020034c:	8526                	mv	a0,s1
ffffffffc020034e:	231010ef          	jal	ra,ffffffffc0201d7e <strchr>
ffffffffc0200352:	c901                	beqz	a0,ffffffffc0200362 <kmonitor+0xf6>
ffffffffc0200354:	00144583          	lbu	a1,1(s0)
            *buf ++ = '\0';
ffffffffc0200358:	00040023          	sb	zero,0(s0)
ffffffffc020035c:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020035e:	d5c9                	beqz	a1,ffffffffc02002e8 <kmonitor+0x7c>
ffffffffc0200360:	b7f5                	j	ffffffffc020034c <kmonitor+0xe0>
        if (*buf == '\0') {
ffffffffc0200362:	00044783          	lbu	a5,0(s0)
ffffffffc0200366:	d3c9                	beqz	a5,ffffffffc02002e8 <kmonitor+0x7c>
        if (argc == MAXARGS - 1) {
ffffffffc0200368:	033c8963          	beq	s9,s3,ffffffffc020039a <kmonitor+0x12e>
        argv[argc ++] = buf;
ffffffffc020036c:	003c9793          	slli	a5,s9,0x3
ffffffffc0200370:	0118                	addi	a4,sp,128
ffffffffc0200372:	97ba                	add	a5,a5,a4
ffffffffc0200374:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200378:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc020037c:	2c85                	addiw	s9,s9,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc020037e:	e591                	bnez	a1,ffffffffc020038a <kmonitor+0x11e>
ffffffffc0200380:	b7b5                	j	ffffffffc02002ec <kmonitor+0x80>
ffffffffc0200382:	00144583          	lbu	a1,1(s0)
            buf ++;
ffffffffc0200386:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200388:	d1a5                	beqz	a1,ffffffffc02002e8 <kmonitor+0x7c>
ffffffffc020038a:	8526                	mv	a0,s1
ffffffffc020038c:	1f3010ef          	jal	ra,ffffffffc0201d7e <strchr>
ffffffffc0200390:	d96d                	beqz	a0,ffffffffc0200382 <kmonitor+0x116>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200392:	00044583          	lbu	a1,0(s0)
ffffffffc0200396:	d9a9                	beqz	a1,ffffffffc02002e8 <kmonitor+0x7c>
ffffffffc0200398:	bf55                	j	ffffffffc020034c <kmonitor+0xe0>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc020039a:	45c1                	li	a1,16
ffffffffc020039c:	855a                	mv	a0,s6
ffffffffc020039e:	d1dff0ef          	jal	ra,ffffffffc02000ba <cprintf>
ffffffffc02003a2:	b7e9                	j	ffffffffc020036c <kmonitor+0x100>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc02003a4:	6582                	ld	a1,0(sp)
ffffffffc02003a6:	00002517          	auipc	a0,0x2
ffffffffc02003aa:	c4250513          	addi	a0,a0,-958 # ffffffffc0201fe8 <etext+0x242>
ffffffffc02003ae:	d0dff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    return 0;
ffffffffc02003b2:	b715                	j	ffffffffc02002d6 <kmonitor+0x6a>

ffffffffc02003b4 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc02003b4:	00006317          	auipc	t1,0x6
ffffffffc02003b8:	08c30313          	addi	t1,t1,140 # ffffffffc0206440 <is_panic>
ffffffffc02003bc:	00032e03          	lw	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc02003c0:	715d                	addi	sp,sp,-80
ffffffffc02003c2:	ec06                	sd	ra,24(sp)
ffffffffc02003c4:	e822                	sd	s0,16(sp)
ffffffffc02003c6:	f436                	sd	a3,40(sp)
ffffffffc02003c8:	f83a                	sd	a4,48(sp)
ffffffffc02003ca:	fc3e                	sd	a5,56(sp)
ffffffffc02003cc:	e0c2                	sd	a6,64(sp)
ffffffffc02003ce:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc02003d0:	020e1a63          	bnez	t3,ffffffffc0200404 <__panic+0x50>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc02003d4:	4785                	li	a5,1
ffffffffc02003d6:	00f32023          	sw	a5,0(t1)

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc02003da:	8432                	mv	s0,a2
ffffffffc02003dc:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02003de:	862e                	mv	a2,a1
ffffffffc02003e0:	85aa                	mv	a1,a0
ffffffffc02003e2:	00002517          	auipc	a0,0x2
ffffffffc02003e6:	c6650513          	addi	a0,a0,-922 # ffffffffc0202048 <commands+0x48>
    va_start(ap, fmt);
ffffffffc02003ea:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02003ec:	ccfff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    vcprintf(fmt, ap);
ffffffffc02003f0:	65a2                	ld	a1,8(sp)
ffffffffc02003f2:	8522                	mv	a0,s0
ffffffffc02003f4:	ca7ff0ef          	jal	ra,ffffffffc020009a <vcprintf>
    cprintf("\n");
ffffffffc02003f8:	00002517          	auipc	a0,0x2
ffffffffc02003fc:	a9850513          	addi	a0,a0,-1384 # ffffffffc0201e90 <etext+0xea>
ffffffffc0200400:	cbbff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    va_end(ap);

panic_dead:
    intr_disable();
ffffffffc0200404:	062000ef          	jal	ra,ffffffffc0200466 <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc0200408:	4501                	li	a0,0
ffffffffc020040a:	e63ff0ef          	jal	ra,ffffffffc020026c <kmonitor>
    while (1) {
ffffffffc020040e:	bfed                	j	ffffffffc0200408 <__panic+0x54>

ffffffffc0200410 <clock_init>:

/* *
 * clock_init - initialize 8253 clock to interrupt 100 times per second,
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
ffffffffc0200410:	1141                	addi	sp,sp,-16
ffffffffc0200412:	e406                	sd	ra,8(sp)
    // enable timer interrupt in sie
    set_csr(sie, MIP_STIP);
ffffffffc0200414:	02000793          	li	a5,32
ffffffffc0200418:	1047a7f3          	csrrs	a5,sie,a5
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc020041c:	c0102573          	rdtime	a0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200420:	67e1                	lui	a5,0x18
ffffffffc0200422:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc0200426:	953e                	add	a0,a0,a5
ffffffffc0200428:	0e7010ef          	jal	ra,ffffffffc0201d0e <sbi_set_timer>
}
ffffffffc020042c:	60a2                	ld	ra,8(sp)
    ticks = 0;
ffffffffc020042e:	00006797          	auipc	a5,0x6
ffffffffc0200432:	0007bd23          	sd	zero,26(a5) # ffffffffc0206448 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc0200436:	00002517          	auipc	a0,0x2
ffffffffc020043a:	c3250513          	addi	a0,a0,-974 # ffffffffc0202068 <commands+0x68>
}
ffffffffc020043e:	0141                	addi	sp,sp,16
    cprintf("++ setup timer interrupts\n");
ffffffffc0200440:	b9ad                	j	ffffffffc02000ba <cprintf>

ffffffffc0200442 <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200442:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200446:	67e1                	lui	a5,0x18
ffffffffc0200448:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc020044c:	953e                	add	a0,a0,a5
ffffffffc020044e:	0c10106f          	j	ffffffffc0201d0e <sbi_set_timer>

ffffffffc0200452 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc0200452:	8082                	ret

ffffffffc0200454 <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
ffffffffc0200454:	0ff57513          	zext.b	a0,a0
ffffffffc0200458:	09d0106f          	j	ffffffffc0201cf4 <sbi_console_putchar>

ffffffffc020045c <cons_getc>:
 * cons_getc - return the next input character from console,
 * or 0 if none waiting.
 * */
int cons_getc(void) {
    int c = 0;
    c = sbi_console_getchar();
ffffffffc020045c:	0cd0106f          	j	ffffffffc0201d28 <sbi_console_getchar>

ffffffffc0200460 <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc0200460:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc0200464:	8082                	ret

ffffffffc0200466 <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc0200466:	100177f3          	csrrci	a5,sstatus,2
ffffffffc020046a:	8082                	ret

ffffffffc020046c <idt_init>:
     */

    extern void __alltraps(void);
    /* Set sup0 scratch register to 0, indicating to exception vector
       that we are presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc020046c:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc0200470:	00000797          	auipc	a5,0x0
ffffffffc0200474:	2e478793          	addi	a5,a5,740 # ffffffffc0200754 <__alltraps>
ffffffffc0200478:	10579073          	csrw	stvec,a5
}
ffffffffc020047c:	8082                	ret

ffffffffc020047e <print_regs>:
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr) {
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020047e:	610c                	ld	a1,0(a0)
void print_regs(struct pushregs *gpr) {
ffffffffc0200480:	1141                	addi	sp,sp,-16
ffffffffc0200482:	e022                	sd	s0,0(sp)
ffffffffc0200484:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200486:	00002517          	auipc	a0,0x2
ffffffffc020048a:	c0250513          	addi	a0,a0,-1022 # ffffffffc0202088 <commands+0x88>
void print_regs(struct pushregs *gpr) {
ffffffffc020048e:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200490:	c2bff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc0200494:	640c                	ld	a1,8(s0)
ffffffffc0200496:	00002517          	auipc	a0,0x2
ffffffffc020049a:	c0a50513          	addi	a0,a0,-1014 # ffffffffc02020a0 <commands+0xa0>
ffffffffc020049e:	c1dff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc02004a2:	680c                	ld	a1,16(s0)
ffffffffc02004a4:	00002517          	auipc	a0,0x2
ffffffffc02004a8:	c1450513          	addi	a0,a0,-1004 # ffffffffc02020b8 <commands+0xb8>
ffffffffc02004ac:	c0fff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc02004b0:	6c0c                	ld	a1,24(s0)
ffffffffc02004b2:	00002517          	auipc	a0,0x2
ffffffffc02004b6:	c1e50513          	addi	a0,a0,-994 # ffffffffc02020d0 <commands+0xd0>
ffffffffc02004ba:	c01ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc02004be:	700c                	ld	a1,32(s0)
ffffffffc02004c0:	00002517          	auipc	a0,0x2
ffffffffc02004c4:	c2850513          	addi	a0,a0,-984 # ffffffffc02020e8 <commands+0xe8>
ffffffffc02004c8:	bf3ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc02004cc:	740c                	ld	a1,40(s0)
ffffffffc02004ce:	00002517          	auipc	a0,0x2
ffffffffc02004d2:	c3250513          	addi	a0,a0,-974 # ffffffffc0202100 <commands+0x100>
ffffffffc02004d6:	be5ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc02004da:	780c                	ld	a1,48(s0)
ffffffffc02004dc:	00002517          	auipc	a0,0x2
ffffffffc02004e0:	c3c50513          	addi	a0,a0,-964 # ffffffffc0202118 <commands+0x118>
ffffffffc02004e4:	bd7ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc02004e8:	7c0c                	ld	a1,56(s0)
ffffffffc02004ea:	00002517          	auipc	a0,0x2
ffffffffc02004ee:	c4650513          	addi	a0,a0,-954 # ffffffffc0202130 <commands+0x130>
ffffffffc02004f2:	bc9ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc02004f6:	602c                	ld	a1,64(s0)
ffffffffc02004f8:	00002517          	auipc	a0,0x2
ffffffffc02004fc:	c5050513          	addi	a0,a0,-944 # ffffffffc0202148 <commands+0x148>
ffffffffc0200500:	bbbff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc0200504:	642c                	ld	a1,72(s0)
ffffffffc0200506:	00002517          	auipc	a0,0x2
ffffffffc020050a:	c5a50513          	addi	a0,a0,-934 # ffffffffc0202160 <commands+0x160>
ffffffffc020050e:	badff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc0200512:	682c                	ld	a1,80(s0)
ffffffffc0200514:	00002517          	auipc	a0,0x2
ffffffffc0200518:	c6450513          	addi	a0,a0,-924 # ffffffffc0202178 <commands+0x178>
ffffffffc020051c:	b9fff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc0200520:	6c2c                	ld	a1,88(s0)
ffffffffc0200522:	00002517          	auipc	a0,0x2
ffffffffc0200526:	c6e50513          	addi	a0,a0,-914 # ffffffffc0202190 <commands+0x190>
ffffffffc020052a:	b91ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc020052e:	702c                	ld	a1,96(s0)
ffffffffc0200530:	00002517          	auipc	a0,0x2
ffffffffc0200534:	c7850513          	addi	a0,a0,-904 # ffffffffc02021a8 <commands+0x1a8>
ffffffffc0200538:	b83ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc020053c:	742c                	ld	a1,104(s0)
ffffffffc020053e:	00002517          	auipc	a0,0x2
ffffffffc0200542:	c8250513          	addi	a0,a0,-894 # ffffffffc02021c0 <commands+0x1c0>
ffffffffc0200546:	b75ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc020054a:	782c                	ld	a1,112(s0)
ffffffffc020054c:	00002517          	auipc	a0,0x2
ffffffffc0200550:	c8c50513          	addi	a0,a0,-884 # ffffffffc02021d8 <commands+0x1d8>
ffffffffc0200554:	b67ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200558:	7c2c                	ld	a1,120(s0)
ffffffffc020055a:	00002517          	auipc	a0,0x2
ffffffffc020055e:	c9650513          	addi	a0,a0,-874 # ffffffffc02021f0 <commands+0x1f0>
ffffffffc0200562:	b59ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200566:	604c                	ld	a1,128(s0)
ffffffffc0200568:	00002517          	auipc	a0,0x2
ffffffffc020056c:	ca050513          	addi	a0,a0,-864 # ffffffffc0202208 <commands+0x208>
ffffffffc0200570:	b4bff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200574:	644c                	ld	a1,136(s0)
ffffffffc0200576:	00002517          	auipc	a0,0x2
ffffffffc020057a:	caa50513          	addi	a0,a0,-854 # ffffffffc0202220 <commands+0x220>
ffffffffc020057e:	b3dff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200582:	684c                	ld	a1,144(s0)
ffffffffc0200584:	00002517          	auipc	a0,0x2
ffffffffc0200588:	cb450513          	addi	a0,a0,-844 # ffffffffc0202238 <commands+0x238>
ffffffffc020058c:	b2fff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200590:	6c4c                	ld	a1,152(s0)
ffffffffc0200592:	00002517          	auipc	a0,0x2
ffffffffc0200596:	cbe50513          	addi	a0,a0,-834 # ffffffffc0202250 <commands+0x250>
ffffffffc020059a:	b21ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc020059e:	704c                	ld	a1,160(s0)
ffffffffc02005a0:	00002517          	auipc	a0,0x2
ffffffffc02005a4:	cc850513          	addi	a0,a0,-824 # ffffffffc0202268 <commands+0x268>
ffffffffc02005a8:	b13ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc02005ac:	744c                	ld	a1,168(s0)
ffffffffc02005ae:	00002517          	auipc	a0,0x2
ffffffffc02005b2:	cd250513          	addi	a0,a0,-814 # ffffffffc0202280 <commands+0x280>
ffffffffc02005b6:	b05ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc02005ba:	784c                	ld	a1,176(s0)
ffffffffc02005bc:	00002517          	auipc	a0,0x2
ffffffffc02005c0:	cdc50513          	addi	a0,a0,-804 # ffffffffc0202298 <commands+0x298>
ffffffffc02005c4:	af7ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc02005c8:	7c4c                	ld	a1,184(s0)
ffffffffc02005ca:	00002517          	auipc	a0,0x2
ffffffffc02005ce:	ce650513          	addi	a0,a0,-794 # ffffffffc02022b0 <commands+0x2b0>
ffffffffc02005d2:	ae9ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc02005d6:	606c                	ld	a1,192(s0)
ffffffffc02005d8:	00002517          	auipc	a0,0x2
ffffffffc02005dc:	cf050513          	addi	a0,a0,-784 # ffffffffc02022c8 <commands+0x2c8>
ffffffffc02005e0:	adbff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc02005e4:	646c                	ld	a1,200(s0)
ffffffffc02005e6:	00002517          	auipc	a0,0x2
ffffffffc02005ea:	cfa50513          	addi	a0,a0,-774 # ffffffffc02022e0 <commands+0x2e0>
ffffffffc02005ee:	acdff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc02005f2:	686c                	ld	a1,208(s0)
ffffffffc02005f4:	00002517          	auipc	a0,0x2
ffffffffc02005f8:	d0450513          	addi	a0,a0,-764 # ffffffffc02022f8 <commands+0x2f8>
ffffffffc02005fc:	abfff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc0200600:	6c6c                	ld	a1,216(s0)
ffffffffc0200602:	00002517          	auipc	a0,0x2
ffffffffc0200606:	d0e50513          	addi	a0,a0,-754 # ffffffffc0202310 <commands+0x310>
ffffffffc020060a:	ab1ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc020060e:	706c                	ld	a1,224(s0)
ffffffffc0200610:	00002517          	auipc	a0,0x2
ffffffffc0200614:	d1850513          	addi	a0,a0,-744 # ffffffffc0202328 <commands+0x328>
ffffffffc0200618:	aa3ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc020061c:	746c                	ld	a1,232(s0)
ffffffffc020061e:	00002517          	auipc	a0,0x2
ffffffffc0200622:	d2250513          	addi	a0,a0,-734 # ffffffffc0202340 <commands+0x340>
ffffffffc0200626:	a95ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc020062a:	786c                	ld	a1,240(s0)
ffffffffc020062c:	00002517          	auipc	a0,0x2
ffffffffc0200630:	d2c50513          	addi	a0,a0,-724 # ffffffffc0202358 <commands+0x358>
ffffffffc0200634:	a87ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200638:	7c6c                	ld	a1,248(s0)
}
ffffffffc020063a:	6402                	ld	s0,0(sp)
ffffffffc020063c:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc020063e:	00002517          	auipc	a0,0x2
ffffffffc0200642:	d3250513          	addi	a0,a0,-718 # ffffffffc0202370 <commands+0x370>
}
ffffffffc0200646:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200648:	bc8d                	j	ffffffffc02000ba <cprintf>

ffffffffc020064a <print_trapframe>:
void print_trapframe(struct trapframe *tf) {
ffffffffc020064a:	1141                	addi	sp,sp,-16
ffffffffc020064c:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc020064e:	85aa                	mv	a1,a0
void print_trapframe(struct trapframe *tf) {
ffffffffc0200650:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200652:	00002517          	auipc	a0,0x2
ffffffffc0200656:	d3650513          	addi	a0,a0,-714 # ffffffffc0202388 <commands+0x388>
void print_trapframe(struct trapframe *tf) {
ffffffffc020065a:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc020065c:	a5fff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200660:	8522                	mv	a0,s0
ffffffffc0200662:	e1dff0ef          	jal	ra,ffffffffc020047e <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc0200666:	10043583          	ld	a1,256(s0)
ffffffffc020066a:	00002517          	auipc	a0,0x2
ffffffffc020066e:	d3650513          	addi	a0,a0,-714 # ffffffffc02023a0 <commands+0x3a0>
ffffffffc0200672:	a49ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200676:	10843583          	ld	a1,264(s0)
ffffffffc020067a:	00002517          	auipc	a0,0x2
ffffffffc020067e:	d3e50513          	addi	a0,a0,-706 # ffffffffc02023b8 <commands+0x3b8>
ffffffffc0200682:	a39ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
ffffffffc0200686:	11043583          	ld	a1,272(s0)
ffffffffc020068a:	00002517          	auipc	a0,0x2
ffffffffc020068e:	d4650513          	addi	a0,a0,-698 # ffffffffc02023d0 <commands+0x3d0>
ffffffffc0200692:	a29ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200696:	11843583          	ld	a1,280(s0)
}
ffffffffc020069a:	6402                	ld	s0,0(sp)
ffffffffc020069c:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc020069e:	00002517          	auipc	a0,0x2
ffffffffc02006a2:	d4a50513          	addi	a0,a0,-694 # ffffffffc02023e8 <commands+0x3e8>
}
ffffffffc02006a6:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc02006a8:	bc09                	j	ffffffffc02000ba <cprintf>

ffffffffc02006aa <interrupt_handler>:

void interrupt_handler(struct trapframe *tf) {
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc02006aa:	11853783          	ld	a5,280(a0)
ffffffffc02006ae:	472d                	li	a4,11
ffffffffc02006b0:	0786                	slli	a5,a5,0x1
ffffffffc02006b2:	8385                	srli	a5,a5,0x1
ffffffffc02006b4:	06f76c63          	bltu	a4,a5,ffffffffc020072c <interrupt_handler+0x82>
ffffffffc02006b8:	00002717          	auipc	a4,0x2
ffffffffc02006bc:	e1070713          	addi	a4,a4,-496 # ffffffffc02024c8 <commands+0x4c8>
ffffffffc02006c0:	078a                	slli	a5,a5,0x2
ffffffffc02006c2:	97ba                	add	a5,a5,a4
ffffffffc02006c4:	439c                	lw	a5,0(a5)
ffffffffc02006c6:	97ba                	add	a5,a5,a4
ffffffffc02006c8:	8782                	jr	a5
            break;
        case IRQ_H_SOFT:
            cprintf("Hypervisor software interrupt\n");
            break;
        case IRQ_M_SOFT:
            cprintf("Machine software interrupt\n");
ffffffffc02006ca:	00002517          	auipc	a0,0x2
ffffffffc02006ce:	d9650513          	addi	a0,a0,-618 # ffffffffc0202460 <commands+0x460>
ffffffffc02006d2:	b2e5                	j	ffffffffc02000ba <cprintf>
            cprintf("Hypervisor software interrupt\n");
ffffffffc02006d4:	00002517          	auipc	a0,0x2
ffffffffc02006d8:	d6c50513          	addi	a0,a0,-660 # ffffffffc0202440 <commands+0x440>
ffffffffc02006dc:	baf9                	j	ffffffffc02000ba <cprintf>
            cprintf("User software interrupt\n");
ffffffffc02006de:	00002517          	auipc	a0,0x2
ffffffffc02006e2:	d2250513          	addi	a0,a0,-734 # ffffffffc0202400 <commands+0x400>
ffffffffc02006e6:	bad1                	j	ffffffffc02000ba <cprintf>
            break;
        case IRQ_U_TIMER:
            cprintf("User Timer interrupt\n");
ffffffffc02006e8:	00002517          	auipc	a0,0x2
ffffffffc02006ec:	d9850513          	addi	a0,a0,-616 # ffffffffc0202480 <commands+0x480>
ffffffffc02006f0:	b2e9                	j	ffffffffc02000ba <cprintf>
void interrupt_handler(struct trapframe *tf) {
ffffffffc02006f2:	1141                	addi	sp,sp,-16
ffffffffc02006f4:	e406                	sd	ra,8(sp)
            // read-only." -- privileged spec1.9.1, 4.1.4, p59
            // In fact, Call sbi_set_timer will clear STIP, or you can clear it
            // directly.
            // cprintf("Supervisor timer interrupt\n");
            // clear_csr(sip, SIP_STIP);
            clock_set_next_event();
ffffffffc02006f6:	d4dff0ef          	jal	ra,ffffffffc0200442 <clock_set_next_event>
            if (++ticks % TICK_NUM == 0) {
ffffffffc02006fa:	00006697          	auipc	a3,0x6
ffffffffc02006fe:	d4e68693          	addi	a3,a3,-690 # ffffffffc0206448 <ticks>
ffffffffc0200702:	629c                	ld	a5,0(a3)
ffffffffc0200704:	06400713          	li	a4,100
ffffffffc0200708:	0785                	addi	a5,a5,1
ffffffffc020070a:	02e7f733          	remu	a4,a5,a4
ffffffffc020070e:	e29c                	sd	a5,0(a3)
ffffffffc0200710:	cf19                	beqz	a4,ffffffffc020072e <interrupt_handler+0x84>
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc0200712:	60a2                	ld	ra,8(sp)
ffffffffc0200714:	0141                	addi	sp,sp,16
ffffffffc0200716:	8082                	ret
            cprintf("Supervisor external interrupt\n");
ffffffffc0200718:	00002517          	auipc	a0,0x2
ffffffffc020071c:	d9050513          	addi	a0,a0,-624 # ffffffffc02024a8 <commands+0x4a8>
ffffffffc0200720:	ba69                	j	ffffffffc02000ba <cprintf>
            cprintf("Supervisor software interrupt\n");
ffffffffc0200722:	00002517          	auipc	a0,0x2
ffffffffc0200726:	cfe50513          	addi	a0,a0,-770 # ffffffffc0202420 <commands+0x420>
ffffffffc020072a:	ba41                	j	ffffffffc02000ba <cprintf>
            print_trapframe(tf);
ffffffffc020072c:	bf39                	j	ffffffffc020064a <print_trapframe>
}
ffffffffc020072e:	60a2                	ld	ra,8(sp)
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200730:	06400593          	li	a1,100
ffffffffc0200734:	00002517          	auipc	a0,0x2
ffffffffc0200738:	d6450513          	addi	a0,a0,-668 # ffffffffc0202498 <commands+0x498>
}
ffffffffc020073c:	0141                	addi	sp,sp,16
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc020073e:	bab5                	j	ffffffffc02000ba <cprintf>

ffffffffc0200740 <trap>:
            break;
    }
}

static inline void trap_dispatch(struct trapframe *tf) {
    if ((intptr_t)tf->cause < 0) {
ffffffffc0200740:	11853783          	ld	a5,280(a0)
ffffffffc0200744:	0007c763          	bltz	a5,ffffffffc0200752 <trap+0x12>
    switch (tf->cause) {
ffffffffc0200748:	472d                	li	a4,11
ffffffffc020074a:	00f76363          	bltu	a4,a5,ffffffffc0200750 <trap+0x10>
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void trap(struct trapframe *tf) {
    // dispatch based on what type of trap occurred
    trap_dispatch(tf);
}
ffffffffc020074e:	8082                	ret
            print_trapframe(tf);
ffffffffc0200750:	bded                	j	ffffffffc020064a <print_trapframe>
        interrupt_handler(tf);
ffffffffc0200752:	bfa1                	j	ffffffffc02006aa <interrupt_handler>

ffffffffc0200754 <__alltraps>:
    .endm

    .globl __alltraps
    .align(2)
__alltraps:
    SAVE_ALL
ffffffffc0200754:	14011073          	csrw	sscratch,sp
ffffffffc0200758:	712d                	addi	sp,sp,-288
ffffffffc020075a:	e002                	sd	zero,0(sp)
ffffffffc020075c:	e406                	sd	ra,8(sp)
ffffffffc020075e:	ec0e                	sd	gp,24(sp)
ffffffffc0200760:	f012                	sd	tp,32(sp)
ffffffffc0200762:	f416                	sd	t0,40(sp)
ffffffffc0200764:	f81a                	sd	t1,48(sp)
ffffffffc0200766:	fc1e                	sd	t2,56(sp)
ffffffffc0200768:	e0a2                	sd	s0,64(sp)
ffffffffc020076a:	e4a6                	sd	s1,72(sp)
ffffffffc020076c:	e8aa                	sd	a0,80(sp)
ffffffffc020076e:	ecae                	sd	a1,88(sp)
ffffffffc0200770:	f0b2                	sd	a2,96(sp)
ffffffffc0200772:	f4b6                	sd	a3,104(sp)
ffffffffc0200774:	f8ba                	sd	a4,112(sp)
ffffffffc0200776:	fcbe                	sd	a5,120(sp)
ffffffffc0200778:	e142                	sd	a6,128(sp)
ffffffffc020077a:	e546                	sd	a7,136(sp)
ffffffffc020077c:	e94a                	sd	s2,144(sp)
ffffffffc020077e:	ed4e                	sd	s3,152(sp)
ffffffffc0200780:	f152                	sd	s4,160(sp)
ffffffffc0200782:	f556                	sd	s5,168(sp)
ffffffffc0200784:	f95a                	sd	s6,176(sp)
ffffffffc0200786:	fd5e                	sd	s7,184(sp)
ffffffffc0200788:	e1e2                	sd	s8,192(sp)
ffffffffc020078a:	e5e6                	sd	s9,200(sp)
ffffffffc020078c:	e9ea                	sd	s10,208(sp)
ffffffffc020078e:	edee                	sd	s11,216(sp)
ffffffffc0200790:	f1f2                	sd	t3,224(sp)
ffffffffc0200792:	f5f6                	sd	t4,232(sp)
ffffffffc0200794:	f9fa                	sd	t5,240(sp)
ffffffffc0200796:	fdfe                	sd	t6,248(sp)
ffffffffc0200798:	14001473          	csrrw	s0,sscratch,zero
ffffffffc020079c:	100024f3          	csrr	s1,sstatus
ffffffffc02007a0:	14102973          	csrr	s2,sepc
ffffffffc02007a4:	143029f3          	csrr	s3,stval
ffffffffc02007a8:	14202a73          	csrr	s4,scause
ffffffffc02007ac:	e822                	sd	s0,16(sp)
ffffffffc02007ae:	e226                	sd	s1,256(sp)
ffffffffc02007b0:	e64a                	sd	s2,264(sp)
ffffffffc02007b2:	ea4e                	sd	s3,272(sp)
ffffffffc02007b4:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc02007b6:	850a                	mv	a0,sp
    jal trap
ffffffffc02007b8:	f89ff0ef          	jal	ra,ffffffffc0200740 <trap>

ffffffffc02007bc <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc02007bc:	6492                	ld	s1,256(sp)
ffffffffc02007be:	6932                	ld	s2,264(sp)
ffffffffc02007c0:	10049073          	csrw	sstatus,s1
ffffffffc02007c4:	14191073          	csrw	sepc,s2
ffffffffc02007c8:	60a2                	ld	ra,8(sp)
ffffffffc02007ca:	61e2                	ld	gp,24(sp)
ffffffffc02007cc:	7202                	ld	tp,32(sp)
ffffffffc02007ce:	72a2                	ld	t0,40(sp)
ffffffffc02007d0:	7342                	ld	t1,48(sp)
ffffffffc02007d2:	73e2                	ld	t2,56(sp)
ffffffffc02007d4:	6406                	ld	s0,64(sp)
ffffffffc02007d6:	64a6                	ld	s1,72(sp)
ffffffffc02007d8:	6546                	ld	a0,80(sp)
ffffffffc02007da:	65e6                	ld	a1,88(sp)
ffffffffc02007dc:	7606                	ld	a2,96(sp)
ffffffffc02007de:	76a6                	ld	a3,104(sp)
ffffffffc02007e0:	7746                	ld	a4,112(sp)
ffffffffc02007e2:	77e6                	ld	a5,120(sp)
ffffffffc02007e4:	680a                	ld	a6,128(sp)
ffffffffc02007e6:	68aa                	ld	a7,136(sp)
ffffffffc02007e8:	694a                	ld	s2,144(sp)
ffffffffc02007ea:	69ea                	ld	s3,152(sp)
ffffffffc02007ec:	7a0a                	ld	s4,160(sp)
ffffffffc02007ee:	7aaa                	ld	s5,168(sp)
ffffffffc02007f0:	7b4a                	ld	s6,176(sp)
ffffffffc02007f2:	7bea                	ld	s7,184(sp)
ffffffffc02007f4:	6c0e                	ld	s8,192(sp)
ffffffffc02007f6:	6cae                	ld	s9,200(sp)
ffffffffc02007f8:	6d4e                	ld	s10,208(sp)
ffffffffc02007fa:	6dee                	ld	s11,216(sp)
ffffffffc02007fc:	7e0e                	ld	t3,224(sp)
ffffffffc02007fe:	7eae                	ld	t4,232(sp)
ffffffffc0200800:	7f4e                	ld	t5,240(sp)
ffffffffc0200802:	7fee                	ld	t6,248(sp)
ffffffffc0200804:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc0200806:	10200073          	sret

ffffffffc020080a <best_fit_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc020080a:	00006797          	auipc	a5,0x6
ffffffffc020080e:	81e78793          	addi	a5,a5,-2018 # ffffffffc0206028 <free_area>
ffffffffc0200812:	e79c                	sd	a5,8(a5)
ffffffffc0200814:	e39c                	sd	a5,0(a5)
#define nr_free (free_area.nr_free)

static void
best_fit_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc0200816:	0007a823          	sw	zero,16(a5)
}
ffffffffc020081a:	8082                	ret

ffffffffc020081c <best_fit_nr_free_pages>:
}

static size_t
best_fit_nr_free_pages(void) {
    return nr_free;
}
ffffffffc020081c:	00006517          	auipc	a0,0x6
ffffffffc0200820:	81c56503          	lwu	a0,-2020(a0) # ffffffffc0206038 <free_area+0x10>
ffffffffc0200824:	8082                	ret

ffffffffc0200826 <best_fit_alloc_pages>:
    assert(n > 0);
ffffffffc0200826:	c14d                	beqz	a0,ffffffffc02008c8 <best_fit_alloc_pages+0xa2>
    if (n > nr_free) {
ffffffffc0200828:	00006617          	auipc	a2,0x6
ffffffffc020082c:	80060613          	addi	a2,a2,-2048 # ffffffffc0206028 <free_area>
ffffffffc0200830:	01062803          	lw	a6,16(a2)
ffffffffc0200834:	86aa                	mv	a3,a0
ffffffffc0200836:	02081793          	slli	a5,a6,0x20
ffffffffc020083a:	9381                	srli	a5,a5,0x20
ffffffffc020083c:	08a7e463          	bltu	a5,a0,ffffffffc02008c4 <best_fit_alloc_pages+0x9e>
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200840:	661c                	ld	a5,8(a2)
    size_t min_size = nr_free + 1;
ffffffffc0200842:	0018059b          	addiw	a1,a6,1
ffffffffc0200846:	1582                	slli	a1,a1,0x20
ffffffffc0200848:	9181                	srli	a1,a1,0x20
    struct Page *page = NULL;
ffffffffc020084a:	4501                	li	a0,0
    while ((le = list_next(le)) != &free_list) {
ffffffffc020084c:	06c78b63          	beq	a5,a2,ffffffffc02008c2 <best_fit_alloc_pages+0x9c>
        if (p->property >= n&&p->property<min_size) {
ffffffffc0200850:	ff87e703          	lwu	a4,-8(a5)
ffffffffc0200854:	00d76763          	bltu	a4,a3,ffffffffc0200862 <best_fit_alloc_pages+0x3c>
ffffffffc0200858:	00b77563          	bgeu	a4,a1,ffffffffc0200862 <best_fit_alloc_pages+0x3c>
        struct Page *p = le2page(le, page_link);
ffffffffc020085c:	fe878513          	addi	a0,a5,-24
ffffffffc0200860:	85ba                	mv	a1,a4
ffffffffc0200862:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200864:	fec796e3          	bne	a5,a2,ffffffffc0200850 <best_fit_alloc_pages+0x2a>
    if (page != NULL) {
ffffffffc0200868:	cd29                	beqz	a0,ffffffffc02008c2 <best_fit_alloc_pages+0x9c>
    __list_del(listelm->prev, listelm->next);
ffffffffc020086a:	711c                	ld	a5,32(a0)
 * list_prev - get the previous entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_prev(list_entry_t *listelm) {
    return listelm->prev;
ffffffffc020086c:	6d18                	ld	a4,24(a0)
        if (page->property > n) {
ffffffffc020086e:	490c                	lw	a1,16(a0)
            p->property = page->property - n;
ffffffffc0200870:	0006889b          	sext.w	a7,a3
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0200874:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0200876:	e398                	sd	a4,0(a5)
        if (page->property > n) {
ffffffffc0200878:	02059793          	slli	a5,a1,0x20
ffffffffc020087c:	9381                	srli	a5,a5,0x20
ffffffffc020087e:	02f6f863          	bgeu	a3,a5,ffffffffc02008ae <best_fit_alloc_pages+0x88>
            struct Page *p = page + n;
ffffffffc0200882:	00269793          	slli	a5,a3,0x2
ffffffffc0200886:	97b6                	add	a5,a5,a3
ffffffffc0200888:	078e                	slli	a5,a5,0x3
ffffffffc020088a:	97aa                	add	a5,a5,a0
            p->property = page->property - n;
ffffffffc020088c:	411585bb          	subw	a1,a1,a7
ffffffffc0200890:	cb8c                	sw	a1,16(a5)
 *
 * Note that @nr may be almost arbitrarily large; this function is not
 * restricted to acting on a single-word quantity.
 * */
static inline void set_bit(int nr, volatile void *addr) {
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0200892:	4689                	li	a3,2
ffffffffc0200894:	00878593          	addi	a1,a5,8
ffffffffc0200898:	40d5b02f          	amoor.d	zero,a3,(a1)
    __list_add(elm, listelm, listelm->next);
ffffffffc020089c:	6714                	ld	a3,8(a4)
            list_add(prev, &(p->page_link));
ffffffffc020089e:	01878593          	addi	a1,a5,24
        nr_free -= n;
ffffffffc02008a2:	01062803          	lw	a6,16(a2)
    prev->next = next->prev = elm;
ffffffffc02008a6:	e28c                	sd	a1,0(a3)
ffffffffc02008a8:	e70c                	sd	a1,8(a4)
    elm->next = next;
ffffffffc02008aa:	f394                	sd	a3,32(a5)
    elm->prev = prev;
ffffffffc02008ac:	ef98                	sd	a4,24(a5)
ffffffffc02008ae:	4118083b          	subw	a6,a6,a7
ffffffffc02008b2:	01062823          	sw	a6,16(a2)
 * clear_bit - Atomically clears a bit in memory
 * @nr:     the bit to clear
 * @addr:   the address to start counting from
 * */
static inline void clear_bit(int nr, volatile void *addr) {
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc02008b6:	57f5                	li	a5,-3
ffffffffc02008b8:	00850713          	addi	a4,a0,8
ffffffffc02008bc:	60f7302f          	amoand.d	zero,a5,(a4)
}
ffffffffc02008c0:	8082                	ret
}
ffffffffc02008c2:	8082                	ret
        return NULL;
ffffffffc02008c4:	4501                	li	a0,0
ffffffffc02008c6:	8082                	ret
best_fit_alloc_pages(size_t n) {
ffffffffc02008c8:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc02008ca:	00002697          	auipc	a3,0x2
ffffffffc02008ce:	c2e68693          	addi	a3,a3,-978 # ffffffffc02024f8 <commands+0x4f8>
ffffffffc02008d2:	00002617          	auipc	a2,0x2
ffffffffc02008d6:	c2e60613          	addi	a2,a2,-978 # ffffffffc0202500 <commands+0x500>
ffffffffc02008da:	06e00593          	li	a1,110
ffffffffc02008de:	00002517          	auipc	a0,0x2
ffffffffc02008e2:	c3a50513          	addi	a0,a0,-966 # ffffffffc0202518 <commands+0x518>
best_fit_alloc_pages(size_t n) {
ffffffffc02008e6:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02008e8:	acdff0ef          	jal	ra,ffffffffc02003b4 <__panic>

ffffffffc02008ec <best_fit_check>:
}

// LAB2: below code is used to check the best fit allocation algorithm 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
best_fit_check(void) {
ffffffffc02008ec:	715d                	addi	sp,sp,-80
ffffffffc02008ee:	e0a2                	sd	s0,64(sp)
    return listelm->next;
ffffffffc02008f0:	00005417          	auipc	s0,0x5
ffffffffc02008f4:	73840413          	addi	s0,s0,1848 # ffffffffc0206028 <free_area>
ffffffffc02008f8:	641c                	ld	a5,8(s0)
ffffffffc02008fa:	e486                	sd	ra,72(sp)
ffffffffc02008fc:	fc26                	sd	s1,56(sp)
ffffffffc02008fe:	f84a                	sd	s2,48(sp)
ffffffffc0200900:	f44e                	sd	s3,40(sp)
ffffffffc0200902:	f052                	sd	s4,32(sp)
ffffffffc0200904:	ec56                	sd	s5,24(sp)
ffffffffc0200906:	e85a                	sd	s6,16(sp)
ffffffffc0200908:	e45e                	sd	s7,8(sp)
ffffffffc020090a:	e062                	sd	s8,0(sp)
    int score = 0 ,sumscore = 6;
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc020090c:	26878b63          	beq	a5,s0,ffffffffc0200b82 <best_fit_check+0x296>
    int count = 0, total = 0;
ffffffffc0200910:	4481                	li	s1,0
ffffffffc0200912:	4901                	li	s2,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200914:	ff07b703          	ld	a4,-16(a5)
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0200918:	8b09                	andi	a4,a4,2
ffffffffc020091a:	26070863          	beqz	a4,ffffffffc0200b8a <best_fit_check+0x29e>
        count ++, total += p->property;
ffffffffc020091e:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200922:	679c                	ld	a5,8(a5)
ffffffffc0200924:	2905                	addiw	s2,s2,1
ffffffffc0200926:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200928:	fe8796e3          	bne	a5,s0,ffffffffc0200914 <best_fit_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc020092c:	89a6                	mv	s3,s1
ffffffffc020092e:	167000ef          	jal	ra,ffffffffc0201294 <nr_free_pages>
ffffffffc0200932:	33351c63          	bne	a0,s3,ffffffffc0200c6a <best_fit_check+0x37e>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200936:	4505                	li	a0,1
ffffffffc0200938:	0df000ef          	jal	ra,ffffffffc0201216 <alloc_pages>
ffffffffc020093c:	8a2a                	mv	s4,a0
ffffffffc020093e:	36050663          	beqz	a0,ffffffffc0200caa <best_fit_check+0x3be>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200942:	4505                	li	a0,1
ffffffffc0200944:	0d3000ef          	jal	ra,ffffffffc0201216 <alloc_pages>
ffffffffc0200948:	89aa                	mv	s3,a0
ffffffffc020094a:	34050063          	beqz	a0,ffffffffc0200c8a <best_fit_check+0x39e>
    assert((p2 = alloc_page()) != NULL);
ffffffffc020094e:	4505                	li	a0,1
ffffffffc0200950:	0c7000ef          	jal	ra,ffffffffc0201216 <alloc_pages>
ffffffffc0200954:	8aaa                	mv	s5,a0
ffffffffc0200956:	2c050a63          	beqz	a0,ffffffffc0200c2a <best_fit_check+0x33e>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc020095a:	253a0863          	beq	s4,s3,ffffffffc0200baa <best_fit_check+0x2be>
ffffffffc020095e:	24aa0663          	beq	s4,a0,ffffffffc0200baa <best_fit_check+0x2be>
ffffffffc0200962:	24a98463          	beq	s3,a0,ffffffffc0200baa <best_fit_check+0x2be>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200966:	000a2783          	lw	a5,0(s4)
ffffffffc020096a:	26079063          	bnez	a5,ffffffffc0200bca <best_fit_check+0x2de>
ffffffffc020096e:	0009a783          	lw	a5,0(s3)
ffffffffc0200972:	24079c63          	bnez	a5,ffffffffc0200bca <best_fit_check+0x2de>
ffffffffc0200976:	411c                	lw	a5,0(a0)
ffffffffc0200978:	24079963          	bnez	a5,ffffffffc0200bca <best_fit_check+0x2de>
extern struct Page *pages;
extern size_t npage;
extern const size_t nbase;
extern uint64_t va_pa_offset;

static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc020097c:	00006797          	auipc	a5,0x6
ffffffffc0200980:	adc7b783          	ld	a5,-1316(a5) # ffffffffc0206458 <pages>
ffffffffc0200984:	40fa0733          	sub	a4,s4,a5
ffffffffc0200988:	870d                	srai	a4,a4,0x3
ffffffffc020098a:	00002597          	auipc	a1,0x2
ffffffffc020098e:	60e5b583          	ld	a1,1550(a1) # ffffffffc0202f98 <error_string+0x38>
ffffffffc0200992:	02b70733          	mul	a4,a4,a1
ffffffffc0200996:	00002617          	auipc	a2,0x2
ffffffffc020099a:	60a63603          	ld	a2,1546(a2) # ffffffffc0202fa0 <nbase>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc020099e:	00006697          	auipc	a3,0x6
ffffffffc02009a2:	ab26b683          	ld	a3,-1358(a3) # ffffffffc0206450 <npage>
ffffffffc02009a6:	06b2                	slli	a3,a3,0xc
ffffffffc02009a8:	9732                	add	a4,a4,a2

static inline uintptr_t page2pa(struct Page *page) {
    return page2ppn(page) << PGSHIFT;
ffffffffc02009aa:	0732                	slli	a4,a4,0xc
ffffffffc02009ac:	22d77f63          	bgeu	a4,a3,ffffffffc0200bea <best_fit_check+0x2fe>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc02009b0:	40f98733          	sub	a4,s3,a5
ffffffffc02009b4:	870d                	srai	a4,a4,0x3
ffffffffc02009b6:	02b70733          	mul	a4,a4,a1
ffffffffc02009ba:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc02009bc:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc02009be:	3ed77663          	bgeu	a4,a3,ffffffffc0200daa <best_fit_check+0x4be>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc02009c2:	40f507b3          	sub	a5,a0,a5
ffffffffc02009c6:	878d                	srai	a5,a5,0x3
ffffffffc02009c8:	02b787b3          	mul	a5,a5,a1
ffffffffc02009cc:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc02009ce:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc02009d0:	3ad7fd63          	bgeu	a5,a3,ffffffffc0200d8a <best_fit_check+0x49e>
    assert(alloc_page() == NULL);
ffffffffc02009d4:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc02009d6:	00043c03          	ld	s8,0(s0)
ffffffffc02009da:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc02009de:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc02009e2:	e400                	sd	s0,8(s0)
ffffffffc02009e4:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc02009e6:	00005797          	auipc	a5,0x5
ffffffffc02009ea:	6407a923          	sw	zero,1618(a5) # ffffffffc0206038 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc02009ee:	029000ef          	jal	ra,ffffffffc0201216 <alloc_pages>
ffffffffc02009f2:	36051c63          	bnez	a0,ffffffffc0200d6a <best_fit_check+0x47e>
    free_page(p0);
ffffffffc02009f6:	4585                	li	a1,1
ffffffffc02009f8:	8552                	mv	a0,s4
ffffffffc02009fa:	05b000ef          	jal	ra,ffffffffc0201254 <free_pages>
    free_page(p1);
ffffffffc02009fe:	4585                	li	a1,1
ffffffffc0200a00:	854e                	mv	a0,s3
ffffffffc0200a02:	053000ef          	jal	ra,ffffffffc0201254 <free_pages>
    free_page(p2);
ffffffffc0200a06:	4585                	li	a1,1
ffffffffc0200a08:	8556                	mv	a0,s5
ffffffffc0200a0a:	04b000ef          	jal	ra,ffffffffc0201254 <free_pages>
    assert(nr_free == 3);
ffffffffc0200a0e:	4818                	lw	a4,16(s0)
ffffffffc0200a10:	478d                	li	a5,3
ffffffffc0200a12:	32f71c63          	bne	a4,a5,ffffffffc0200d4a <best_fit_check+0x45e>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200a16:	4505                	li	a0,1
ffffffffc0200a18:	7fe000ef          	jal	ra,ffffffffc0201216 <alloc_pages>
ffffffffc0200a1c:	89aa                	mv	s3,a0
ffffffffc0200a1e:	30050663          	beqz	a0,ffffffffc0200d2a <best_fit_check+0x43e>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200a22:	4505                	li	a0,1
ffffffffc0200a24:	7f2000ef          	jal	ra,ffffffffc0201216 <alloc_pages>
ffffffffc0200a28:	8aaa                	mv	s5,a0
ffffffffc0200a2a:	2e050063          	beqz	a0,ffffffffc0200d0a <best_fit_check+0x41e>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200a2e:	4505                	li	a0,1
ffffffffc0200a30:	7e6000ef          	jal	ra,ffffffffc0201216 <alloc_pages>
ffffffffc0200a34:	8a2a                	mv	s4,a0
ffffffffc0200a36:	2a050a63          	beqz	a0,ffffffffc0200cea <best_fit_check+0x3fe>
    assert(alloc_page() == NULL);
ffffffffc0200a3a:	4505                	li	a0,1
ffffffffc0200a3c:	7da000ef          	jal	ra,ffffffffc0201216 <alloc_pages>
ffffffffc0200a40:	28051563          	bnez	a0,ffffffffc0200cca <best_fit_check+0x3de>
    free_page(p0);
ffffffffc0200a44:	4585                	li	a1,1
ffffffffc0200a46:	854e                	mv	a0,s3
ffffffffc0200a48:	00d000ef          	jal	ra,ffffffffc0201254 <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0200a4c:	641c                	ld	a5,8(s0)
ffffffffc0200a4e:	1a878e63          	beq	a5,s0,ffffffffc0200c0a <best_fit_check+0x31e>
    assert((p = alloc_page()) == p0);
ffffffffc0200a52:	4505                	li	a0,1
ffffffffc0200a54:	7c2000ef          	jal	ra,ffffffffc0201216 <alloc_pages>
ffffffffc0200a58:	52a99963          	bne	s3,a0,ffffffffc0200f8a <best_fit_check+0x69e>
    assert(alloc_page() == NULL);
ffffffffc0200a5c:	4505                	li	a0,1
ffffffffc0200a5e:	7b8000ef          	jal	ra,ffffffffc0201216 <alloc_pages>
ffffffffc0200a62:	50051463          	bnez	a0,ffffffffc0200f6a <best_fit_check+0x67e>
    assert(nr_free == 0);
ffffffffc0200a66:	481c                	lw	a5,16(s0)
ffffffffc0200a68:	4e079163          	bnez	a5,ffffffffc0200f4a <best_fit_check+0x65e>
    free_page(p);
ffffffffc0200a6c:	854e                	mv	a0,s3
ffffffffc0200a6e:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0200a70:	01843023          	sd	s8,0(s0)
ffffffffc0200a74:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc0200a78:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc0200a7c:	7d8000ef          	jal	ra,ffffffffc0201254 <free_pages>
    free_page(p1);
ffffffffc0200a80:	4585                	li	a1,1
ffffffffc0200a82:	8556                	mv	a0,s5
ffffffffc0200a84:	7d0000ef          	jal	ra,ffffffffc0201254 <free_pages>
    free_page(p2);
ffffffffc0200a88:	4585                	li	a1,1
ffffffffc0200a8a:	8552                	mv	a0,s4
ffffffffc0200a8c:	7c8000ef          	jal	ra,ffffffffc0201254 <free_pages>

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0200a90:	4515                	li	a0,5
ffffffffc0200a92:	784000ef          	jal	ra,ffffffffc0201216 <alloc_pages>
ffffffffc0200a96:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0200a98:	48050963          	beqz	a0,ffffffffc0200f2a <best_fit_check+0x63e>
ffffffffc0200a9c:	651c                	ld	a5,8(a0)
ffffffffc0200a9e:	8385                	srli	a5,a5,0x1
    assert(!PageProperty(p0));
ffffffffc0200aa0:	8b85                	andi	a5,a5,1
ffffffffc0200aa2:	46079463          	bnez	a5,ffffffffc0200f0a <best_fit_check+0x61e>
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0200aa6:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200aa8:	00043a83          	ld	s5,0(s0)
ffffffffc0200aac:	00843a03          	ld	s4,8(s0)
ffffffffc0200ab0:	e000                	sd	s0,0(s0)
ffffffffc0200ab2:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc0200ab4:	762000ef          	jal	ra,ffffffffc0201216 <alloc_pages>
ffffffffc0200ab8:	42051963          	bnez	a0,ffffffffc0200eea <best_fit_check+0x5fe>
    #endif
    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    // * - - * -
    free_pages(p0 + 1, 2);
ffffffffc0200abc:	4589                	li	a1,2
ffffffffc0200abe:	02898513          	addi	a0,s3,40
    unsigned int nr_free_store = nr_free;
ffffffffc0200ac2:	01042b03          	lw	s6,16(s0)
    free_pages(p0 + 4, 1);
ffffffffc0200ac6:	0a098c13          	addi	s8,s3,160
    nr_free = 0;
ffffffffc0200aca:	00005797          	auipc	a5,0x5
ffffffffc0200ace:	5607a723          	sw	zero,1390(a5) # ffffffffc0206038 <free_area+0x10>
    free_pages(p0 + 1, 2);
ffffffffc0200ad2:	782000ef          	jal	ra,ffffffffc0201254 <free_pages>
    free_pages(p0 + 4, 1);
ffffffffc0200ad6:	8562                	mv	a0,s8
ffffffffc0200ad8:	4585                	li	a1,1
ffffffffc0200ada:	77a000ef          	jal	ra,ffffffffc0201254 <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc0200ade:	4511                	li	a0,4
ffffffffc0200ae0:	736000ef          	jal	ra,ffffffffc0201216 <alloc_pages>
ffffffffc0200ae4:	3e051363          	bnez	a0,ffffffffc0200eca <best_fit_check+0x5de>
ffffffffc0200ae8:	0309b783          	ld	a5,48(s3)
ffffffffc0200aec:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0 + 1) && p0[1].property == 2);
ffffffffc0200aee:	8b85                	andi	a5,a5,1
ffffffffc0200af0:	3a078d63          	beqz	a5,ffffffffc0200eaa <best_fit_check+0x5be>
ffffffffc0200af4:	0389a703          	lw	a4,56(s3)
ffffffffc0200af8:	4789                	li	a5,2
ffffffffc0200afa:	3af71863          	bne	a4,a5,ffffffffc0200eaa <best_fit_check+0x5be>
    // * - - * *
    assert((p1 = alloc_pages(1)) != NULL);
ffffffffc0200afe:	4505                	li	a0,1
ffffffffc0200b00:	716000ef          	jal	ra,ffffffffc0201216 <alloc_pages>
ffffffffc0200b04:	8baa                	mv	s7,a0
ffffffffc0200b06:	38050263          	beqz	a0,ffffffffc0200e8a <best_fit_check+0x59e>
    assert(alloc_pages(2) != NULL);      // best fit feature
ffffffffc0200b0a:	4509                	li	a0,2
ffffffffc0200b0c:	70a000ef          	jal	ra,ffffffffc0201216 <alloc_pages>
ffffffffc0200b10:	34050d63          	beqz	a0,ffffffffc0200e6a <best_fit_check+0x57e>
    assert(p0 + 4 == p1);
ffffffffc0200b14:	337c1b63          	bne	s8,s7,ffffffffc0200e4a <best_fit_check+0x55e>
    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    p2 = p0 + 1;
    free_pages(p0, 5);
ffffffffc0200b18:	854e                	mv	a0,s3
ffffffffc0200b1a:	4595                	li	a1,5
ffffffffc0200b1c:	738000ef          	jal	ra,ffffffffc0201254 <free_pages>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0200b20:	4515                	li	a0,5
ffffffffc0200b22:	6f4000ef          	jal	ra,ffffffffc0201216 <alloc_pages>
ffffffffc0200b26:	89aa                	mv	s3,a0
ffffffffc0200b28:	30050163          	beqz	a0,ffffffffc0200e2a <best_fit_check+0x53e>
    assert(alloc_page() == NULL);
ffffffffc0200b2c:	4505                	li	a0,1
ffffffffc0200b2e:	6e8000ef          	jal	ra,ffffffffc0201216 <alloc_pages>
ffffffffc0200b32:	2c051c63          	bnez	a0,ffffffffc0200e0a <best_fit_check+0x51e>

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    assert(nr_free == 0);
ffffffffc0200b36:	481c                	lw	a5,16(s0)
ffffffffc0200b38:	2a079963          	bnez	a5,ffffffffc0200dea <best_fit_check+0x4fe>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0200b3c:	4595                	li	a1,5
ffffffffc0200b3e:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc0200b40:	01642823          	sw	s6,16(s0)
    free_list = free_list_store;
ffffffffc0200b44:	01543023          	sd	s5,0(s0)
ffffffffc0200b48:	01443423          	sd	s4,8(s0)
    free_pages(p0, 5);
ffffffffc0200b4c:	708000ef          	jal	ra,ffffffffc0201254 <free_pages>
    return listelm->next;
ffffffffc0200b50:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200b52:	00878963          	beq	a5,s0,ffffffffc0200b64 <best_fit_check+0x278>
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
ffffffffc0200b56:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200b5a:	679c                	ld	a5,8(a5)
ffffffffc0200b5c:	397d                	addiw	s2,s2,-1
ffffffffc0200b5e:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200b60:	fe879be3          	bne	a5,s0,ffffffffc0200b56 <best_fit_check+0x26a>
    }
    assert(count == 0);
ffffffffc0200b64:	26091363          	bnez	s2,ffffffffc0200dca <best_fit_check+0x4de>
    assert(total == 0);
ffffffffc0200b68:	e0ed                	bnez	s1,ffffffffc0200c4a <best_fit_check+0x35e>
    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
}
ffffffffc0200b6a:	60a6                	ld	ra,72(sp)
ffffffffc0200b6c:	6406                	ld	s0,64(sp)
ffffffffc0200b6e:	74e2                	ld	s1,56(sp)
ffffffffc0200b70:	7942                	ld	s2,48(sp)
ffffffffc0200b72:	79a2                	ld	s3,40(sp)
ffffffffc0200b74:	7a02                	ld	s4,32(sp)
ffffffffc0200b76:	6ae2                	ld	s5,24(sp)
ffffffffc0200b78:	6b42                	ld	s6,16(sp)
ffffffffc0200b7a:	6ba2                	ld	s7,8(sp)
ffffffffc0200b7c:	6c02                	ld	s8,0(sp)
ffffffffc0200b7e:	6161                	addi	sp,sp,80
ffffffffc0200b80:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200b82:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc0200b84:	4481                	li	s1,0
ffffffffc0200b86:	4901                	li	s2,0
ffffffffc0200b88:	b35d                	j	ffffffffc020092e <best_fit_check+0x42>
        assert(PageProperty(p));
ffffffffc0200b8a:	00002697          	auipc	a3,0x2
ffffffffc0200b8e:	9a668693          	addi	a3,a3,-1626 # ffffffffc0202530 <commands+0x530>
ffffffffc0200b92:	00002617          	auipc	a2,0x2
ffffffffc0200b96:	96e60613          	addi	a2,a2,-1682 # ffffffffc0202500 <commands+0x500>
ffffffffc0200b9a:	10d00593          	li	a1,269
ffffffffc0200b9e:	00002517          	auipc	a0,0x2
ffffffffc0200ba2:	97a50513          	addi	a0,a0,-1670 # ffffffffc0202518 <commands+0x518>
ffffffffc0200ba6:	80fff0ef          	jal	ra,ffffffffc02003b4 <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200baa:	00002697          	auipc	a3,0x2
ffffffffc0200bae:	a1668693          	addi	a3,a3,-1514 # ffffffffc02025c0 <commands+0x5c0>
ffffffffc0200bb2:	00002617          	auipc	a2,0x2
ffffffffc0200bb6:	94e60613          	addi	a2,a2,-1714 # ffffffffc0202500 <commands+0x500>
ffffffffc0200bba:	0d900593          	li	a1,217
ffffffffc0200bbe:	00002517          	auipc	a0,0x2
ffffffffc0200bc2:	95a50513          	addi	a0,a0,-1702 # ffffffffc0202518 <commands+0x518>
ffffffffc0200bc6:	feeff0ef          	jal	ra,ffffffffc02003b4 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200bca:	00002697          	auipc	a3,0x2
ffffffffc0200bce:	a1e68693          	addi	a3,a3,-1506 # ffffffffc02025e8 <commands+0x5e8>
ffffffffc0200bd2:	00002617          	auipc	a2,0x2
ffffffffc0200bd6:	92e60613          	addi	a2,a2,-1746 # ffffffffc0202500 <commands+0x500>
ffffffffc0200bda:	0da00593          	li	a1,218
ffffffffc0200bde:	00002517          	auipc	a0,0x2
ffffffffc0200be2:	93a50513          	addi	a0,a0,-1734 # ffffffffc0202518 <commands+0x518>
ffffffffc0200be6:	fceff0ef          	jal	ra,ffffffffc02003b4 <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200bea:	00002697          	auipc	a3,0x2
ffffffffc0200bee:	a3e68693          	addi	a3,a3,-1474 # ffffffffc0202628 <commands+0x628>
ffffffffc0200bf2:	00002617          	auipc	a2,0x2
ffffffffc0200bf6:	90e60613          	addi	a2,a2,-1778 # ffffffffc0202500 <commands+0x500>
ffffffffc0200bfa:	0dc00593          	li	a1,220
ffffffffc0200bfe:	00002517          	auipc	a0,0x2
ffffffffc0200c02:	91a50513          	addi	a0,a0,-1766 # ffffffffc0202518 <commands+0x518>
ffffffffc0200c06:	faeff0ef          	jal	ra,ffffffffc02003b4 <__panic>
    assert(!list_empty(&free_list));
ffffffffc0200c0a:	00002697          	auipc	a3,0x2
ffffffffc0200c0e:	aa668693          	addi	a3,a3,-1370 # ffffffffc02026b0 <commands+0x6b0>
ffffffffc0200c12:	00002617          	auipc	a2,0x2
ffffffffc0200c16:	8ee60613          	addi	a2,a2,-1810 # ffffffffc0202500 <commands+0x500>
ffffffffc0200c1a:	0f500593          	li	a1,245
ffffffffc0200c1e:	00002517          	auipc	a0,0x2
ffffffffc0200c22:	8fa50513          	addi	a0,a0,-1798 # ffffffffc0202518 <commands+0x518>
ffffffffc0200c26:	f8eff0ef          	jal	ra,ffffffffc02003b4 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200c2a:	00002697          	auipc	a3,0x2
ffffffffc0200c2e:	97668693          	addi	a3,a3,-1674 # ffffffffc02025a0 <commands+0x5a0>
ffffffffc0200c32:	00002617          	auipc	a2,0x2
ffffffffc0200c36:	8ce60613          	addi	a2,a2,-1842 # ffffffffc0202500 <commands+0x500>
ffffffffc0200c3a:	0d700593          	li	a1,215
ffffffffc0200c3e:	00002517          	auipc	a0,0x2
ffffffffc0200c42:	8da50513          	addi	a0,a0,-1830 # ffffffffc0202518 <commands+0x518>
ffffffffc0200c46:	f6eff0ef          	jal	ra,ffffffffc02003b4 <__panic>
    assert(total == 0);
ffffffffc0200c4a:	00002697          	auipc	a3,0x2
ffffffffc0200c4e:	b9668693          	addi	a3,a3,-1130 # ffffffffc02027e0 <commands+0x7e0>
ffffffffc0200c52:	00002617          	auipc	a2,0x2
ffffffffc0200c56:	8ae60613          	addi	a2,a2,-1874 # ffffffffc0202500 <commands+0x500>
ffffffffc0200c5a:	14f00593          	li	a1,335
ffffffffc0200c5e:	00002517          	auipc	a0,0x2
ffffffffc0200c62:	8ba50513          	addi	a0,a0,-1862 # ffffffffc0202518 <commands+0x518>
ffffffffc0200c66:	f4eff0ef          	jal	ra,ffffffffc02003b4 <__panic>
    assert(total == nr_free_pages());
ffffffffc0200c6a:	00002697          	auipc	a3,0x2
ffffffffc0200c6e:	8d668693          	addi	a3,a3,-1834 # ffffffffc0202540 <commands+0x540>
ffffffffc0200c72:	00002617          	auipc	a2,0x2
ffffffffc0200c76:	88e60613          	addi	a2,a2,-1906 # ffffffffc0202500 <commands+0x500>
ffffffffc0200c7a:	11000593          	li	a1,272
ffffffffc0200c7e:	00002517          	auipc	a0,0x2
ffffffffc0200c82:	89a50513          	addi	a0,a0,-1894 # ffffffffc0202518 <commands+0x518>
ffffffffc0200c86:	f2eff0ef          	jal	ra,ffffffffc02003b4 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200c8a:	00002697          	auipc	a3,0x2
ffffffffc0200c8e:	8f668693          	addi	a3,a3,-1802 # ffffffffc0202580 <commands+0x580>
ffffffffc0200c92:	00002617          	auipc	a2,0x2
ffffffffc0200c96:	86e60613          	addi	a2,a2,-1938 # ffffffffc0202500 <commands+0x500>
ffffffffc0200c9a:	0d600593          	li	a1,214
ffffffffc0200c9e:	00002517          	auipc	a0,0x2
ffffffffc0200ca2:	87a50513          	addi	a0,a0,-1926 # ffffffffc0202518 <commands+0x518>
ffffffffc0200ca6:	f0eff0ef          	jal	ra,ffffffffc02003b4 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200caa:	00002697          	auipc	a3,0x2
ffffffffc0200cae:	8b668693          	addi	a3,a3,-1866 # ffffffffc0202560 <commands+0x560>
ffffffffc0200cb2:	00002617          	auipc	a2,0x2
ffffffffc0200cb6:	84e60613          	addi	a2,a2,-1970 # ffffffffc0202500 <commands+0x500>
ffffffffc0200cba:	0d500593          	li	a1,213
ffffffffc0200cbe:	00002517          	auipc	a0,0x2
ffffffffc0200cc2:	85a50513          	addi	a0,a0,-1958 # ffffffffc0202518 <commands+0x518>
ffffffffc0200cc6:	eeeff0ef          	jal	ra,ffffffffc02003b4 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200cca:	00002697          	auipc	a3,0x2
ffffffffc0200cce:	9be68693          	addi	a3,a3,-1602 # ffffffffc0202688 <commands+0x688>
ffffffffc0200cd2:	00002617          	auipc	a2,0x2
ffffffffc0200cd6:	82e60613          	addi	a2,a2,-2002 # ffffffffc0202500 <commands+0x500>
ffffffffc0200cda:	0f200593          	li	a1,242
ffffffffc0200cde:	00002517          	auipc	a0,0x2
ffffffffc0200ce2:	83a50513          	addi	a0,a0,-1990 # ffffffffc0202518 <commands+0x518>
ffffffffc0200ce6:	eceff0ef          	jal	ra,ffffffffc02003b4 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200cea:	00002697          	auipc	a3,0x2
ffffffffc0200cee:	8b668693          	addi	a3,a3,-1866 # ffffffffc02025a0 <commands+0x5a0>
ffffffffc0200cf2:	00002617          	auipc	a2,0x2
ffffffffc0200cf6:	80e60613          	addi	a2,a2,-2034 # ffffffffc0202500 <commands+0x500>
ffffffffc0200cfa:	0f000593          	li	a1,240
ffffffffc0200cfe:	00002517          	auipc	a0,0x2
ffffffffc0200d02:	81a50513          	addi	a0,a0,-2022 # ffffffffc0202518 <commands+0x518>
ffffffffc0200d06:	eaeff0ef          	jal	ra,ffffffffc02003b4 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200d0a:	00002697          	auipc	a3,0x2
ffffffffc0200d0e:	87668693          	addi	a3,a3,-1930 # ffffffffc0202580 <commands+0x580>
ffffffffc0200d12:	00001617          	auipc	a2,0x1
ffffffffc0200d16:	7ee60613          	addi	a2,a2,2030 # ffffffffc0202500 <commands+0x500>
ffffffffc0200d1a:	0ef00593          	li	a1,239
ffffffffc0200d1e:	00001517          	auipc	a0,0x1
ffffffffc0200d22:	7fa50513          	addi	a0,a0,2042 # ffffffffc0202518 <commands+0x518>
ffffffffc0200d26:	e8eff0ef          	jal	ra,ffffffffc02003b4 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200d2a:	00002697          	auipc	a3,0x2
ffffffffc0200d2e:	83668693          	addi	a3,a3,-1994 # ffffffffc0202560 <commands+0x560>
ffffffffc0200d32:	00001617          	auipc	a2,0x1
ffffffffc0200d36:	7ce60613          	addi	a2,a2,1998 # ffffffffc0202500 <commands+0x500>
ffffffffc0200d3a:	0ee00593          	li	a1,238
ffffffffc0200d3e:	00001517          	auipc	a0,0x1
ffffffffc0200d42:	7da50513          	addi	a0,a0,2010 # ffffffffc0202518 <commands+0x518>
ffffffffc0200d46:	e6eff0ef          	jal	ra,ffffffffc02003b4 <__panic>
    assert(nr_free == 3);
ffffffffc0200d4a:	00002697          	auipc	a3,0x2
ffffffffc0200d4e:	95668693          	addi	a3,a3,-1706 # ffffffffc02026a0 <commands+0x6a0>
ffffffffc0200d52:	00001617          	auipc	a2,0x1
ffffffffc0200d56:	7ae60613          	addi	a2,a2,1966 # ffffffffc0202500 <commands+0x500>
ffffffffc0200d5a:	0ec00593          	li	a1,236
ffffffffc0200d5e:	00001517          	auipc	a0,0x1
ffffffffc0200d62:	7ba50513          	addi	a0,a0,1978 # ffffffffc0202518 <commands+0x518>
ffffffffc0200d66:	e4eff0ef          	jal	ra,ffffffffc02003b4 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200d6a:	00002697          	auipc	a3,0x2
ffffffffc0200d6e:	91e68693          	addi	a3,a3,-1762 # ffffffffc0202688 <commands+0x688>
ffffffffc0200d72:	00001617          	auipc	a2,0x1
ffffffffc0200d76:	78e60613          	addi	a2,a2,1934 # ffffffffc0202500 <commands+0x500>
ffffffffc0200d7a:	0e700593          	li	a1,231
ffffffffc0200d7e:	00001517          	auipc	a0,0x1
ffffffffc0200d82:	79a50513          	addi	a0,a0,1946 # ffffffffc0202518 <commands+0x518>
ffffffffc0200d86:	e2eff0ef          	jal	ra,ffffffffc02003b4 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200d8a:	00002697          	auipc	a3,0x2
ffffffffc0200d8e:	8de68693          	addi	a3,a3,-1826 # ffffffffc0202668 <commands+0x668>
ffffffffc0200d92:	00001617          	auipc	a2,0x1
ffffffffc0200d96:	76e60613          	addi	a2,a2,1902 # ffffffffc0202500 <commands+0x500>
ffffffffc0200d9a:	0de00593          	li	a1,222
ffffffffc0200d9e:	00001517          	auipc	a0,0x1
ffffffffc0200da2:	77a50513          	addi	a0,a0,1914 # ffffffffc0202518 <commands+0x518>
ffffffffc0200da6:	e0eff0ef          	jal	ra,ffffffffc02003b4 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200daa:	00002697          	auipc	a3,0x2
ffffffffc0200dae:	89e68693          	addi	a3,a3,-1890 # ffffffffc0202648 <commands+0x648>
ffffffffc0200db2:	00001617          	auipc	a2,0x1
ffffffffc0200db6:	74e60613          	addi	a2,a2,1870 # ffffffffc0202500 <commands+0x500>
ffffffffc0200dba:	0dd00593          	li	a1,221
ffffffffc0200dbe:	00001517          	auipc	a0,0x1
ffffffffc0200dc2:	75a50513          	addi	a0,a0,1882 # ffffffffc0202518 <commands+0x518>
ffffffffc0200dc6:	deeff0ef          	jal	ra,ffffffffc02003b4 <__panic>
    assert(count == 0);
ffffffffc0200dca:	00002697          	auipc	a3,0x2
ffffffffc0200dce:	a0668693          	addi	a3,a3,-1530 # ffffffffc02027d0 <commands+0x7d0>
ffffffffc0200dd2:	00001617          	auipc	a2,0x1
ffffffffc0200dd6:	72e60613          	addi	a2,a2,1838 # ffffffffc0202500 <commands+0x500>
ffffffffc0200dda:	14e00593          	li	a1,334
ffffffffc0200dde:	00001517          	auipc	a0,0x1
ffffffffc0200de2:	73a50513          	addi	a0,a0,1850 # ffffffffc0202518 <commands+0x518>
ffffffffc0200de6:	dceff0ef          	jal	ra,ffffffffc02003b4 <__panic>
    assert(nr_free == 0);
ffffffffc0200dea:	00002697          	auipc	a3,0x2
ffffffffc0200dee:	8fe68693          	addi	a3,a3,-1794 # ffffffffc02026e8 <commands+0x6e8>
ffffffffc0200df2:	00001617          	auipc	a2,0x1
ffffffffc0200df6:	70e60613          	addi	a2,a2,1806 # ffffffffc0202500 <commands+0x500>
ffffffffc0200dfa:	14300593          	li	a1,323
ffffffffc0200dfe:	00001517          	auipc	a0,0x1
ffffffffc0200e02:	71a50513          	addi	a0,a0,1818 # ffffffffc0202518 <commands+0x518>
ffffffffc0200e06:	daeff0ef          	jal	ra,ffffffffc02003b4 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200e0a:	00002697          	auipc	a3,0x2
ffffffffc0200e0e:	87e68693          	addi	a3,a3,-1922 # ffffffffc0202688 <commands+0x688>
ffffffffc0200e12:	00001617          	auipc	a2,0x1
ffffffffc0200e16:	6ee60613          	addi	a2,a2,1774 # ffffffffc0202500 <commands+0x500>
ffffffffc0200e1a:	13d00593          	li	a1,317
ffffffffc0200e1e:	00001517          	auipc	a0,0x1
ffffffffc0200e22:	6fa50513          	addi	a0,a0,1786 # ffffffffc0202518 <commands+0x518>
ffffffffc0200e26:	d8eff0ef          	jal	ra,ffffffffc02003b4 <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0200e2a:	00002697          	auipc	a3,0x2
ffffffffc0200e2e:	98668693          	addi	a3,a3,-1658 # ffffffffc02027b0 <commands+0x7b0>
ffffffffc0200e32:	00001617          	auipc	a2,0x1
ffffffffc0200e36:	6ce60613          	addi	a2,a2,1742 # ffffffffc0202500 <commands+0x500>
ffffffffc0200e3a:	13c00593          	li	a1,316
ffffffffc0200e3e:	00001517          	auipc	a0,0x1
ffffffffc0200e42:	6da50513          	addi	a0,a0,1754 # ffffffffc0202518 <commands+0x518>
ffffffffc0200e46:	d6eff0ef          	jal	ra,ffffffffc02003b4 <__panic>
    assert(p0 + 4 == p1);
ffffffffc0200e4a:	00002697          	auipc	a3,0x2
ffffffffc0200e4e:	95668693          	addi	a3,a3,-1706 # ffffffffc02027a0 <commands+0x7a0>
ffffffffc0200e52:	00001617          	auipc	a2,0x1
ffffffffc0200e56:	6ae60613          	addi	a2,a2,1710 # ffffffffc0202500 <commands+0x500>
ffffffffc0200e5a:	13400593          	li	a1,308
ffffffffc0200e5e:	00001517          	auipc	a0,0x1
ffffffffc0200e62:	6ba50513          	addi	a0,a0,1722 # ffffffffc0202518 <commands+0x518>
ffffffffc0200e66:	d4eff0ef          	jal	ra,ffffffffc02003b4 <__panic>
    assert(alloc_pages(2) != NULL);      // best fit feature
ffffffffc0200e6a:	00002697          	auipc	a3,0x2
ffffffffc0200e6e:	91e68693          	addi	a3,a3,-1762 # ffffffffc0202788 <commands+0x788>
ffffffffc0200e72:	00001617          	auipc	a2,0x1
ffffffffc0200e76:	68e60613          	addi	a2,a2,1678 # ffffffffc0202500 <commands+0x500>
ffffffffc0200e7a:	13300593          	li	a1,307
ffffffffc0200e7e:	00001517          	auipc	a0,0x1
ffffffffc0200e82:	69a50513          	addi	a0,a0,1690 # ffffffffc0202518 <commands+0x518>
ffffffffc0200e86:	d2eff0ef          	jal	ra,ffffffffc02003b4 <__panic>
    assert((p1 = alloc_pages(1)) != NULL);
ffffffffc0200e8a:	00002697          	auipc	a3,0x2
ffffffffc0200e8e:	8de68693          	addi	a3,a3,-1826 # ffffffffc0202768 <commands+0x768>
ffffffffc0200e92:	00001617          	auipc	a2,0x1
ffffffffc0200e96:	66e60613          	addi	a2,a2,1646 # ffffffffc0202500 <commands+0x500>
ffffffffc0200e9a:	13200593          	li	a1,306
ffffffffc0200e9e:	00001517          	auipc	a0,0x1
ffffffffc0200ea2:	67a50513          	addi	a0,a0,1658 # ffffffffc0202518 <commands+0x518>
ffffffffc0200ea6:	d0eff0ef          	jal	ra,ffffffffc02003b4 <__panic>
    assert(PageProperty(p0 + 1) && p0[1].property == 2);
ffffffffc0200eaa:	00002697          	auipc	a3,0x2
ffffffffc0200eae:	88e68693          	addi	a3,a3,-1906 # ffffffffc0202738 <commands+0x738>
ffffffffc0200eb2:	00001617          	auipc	a2,0x1
ffffffffc0200eb6:	64e60613          	addi	a2,a2,1614 # ffffffffc0202500 <commands+0x500>
ffffffffc0200eba:	13000593          	li	a1,304
ffffffffc0200ebe:	00001517          	auipc	a0,0x1
ffffffffc0200ec2:	65a50513          	addi	a0,a0,1626 # ffffffffc0202518 <commands+0x518>
ffffffffc0200ec6:	ceeff0ef          	jal	ra,ffffffffc02003b4 <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc0200eca:	00002697          	auipc	a3,0x2
ffffffffc0200ece:	85668693          	addi	a3,a3,-1962 # ffffffffc0202720 <commands+0x720>
ffffffffc0200ed2:	00001617          	auipc	a2,0x1
ffffffffc0200ed6:	62e60613          	addi	a2,a2,1582 # ffffffffc0202500 <commands+0x500>
ffffffffc0200eda:	12f00593          	li	a1,303
ffffffffc0200ede:	00001517          	auipc	a0,0x1
ffffffffc0200ee2:	63a50513          	addi	a0,a0,1594 # ffffffffc0202518 <commands+0x518>
ffffffffc0200ee6:	cceff0ef          	jal	ra,ffffffffc02003b4 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200eea:	00001697          	auipc	a3,0x1
ffffffffc0200eee:	79e68693          	addi	a3,a3,1950 # ffffffffc0202688 <commands+0x688>
ffffffffc0200ef2:	00001617          	auipc	a2,0x1
ffffffffc0200ef6:	60e60613          	addi	a2,a2,1550 # ffffffffc0202500 <commands+0x500>
ffffffffc0200efa:	12300593          	li	a1,291
ffffffffc0200efe:	00001517          	auipc	a0,0x1
ffffffffc0200f02:	61a50513          	addi	a0,a0,1562 # ffffffffc0202518 <commands+0x518>
ffffffffc0200f06:	caeff0ef          	jal	ra,ffffffffc02003b4 <__panic>
    assert(!PageProperty(p0));
ffffffffc0200f0a:	00001697          	auipc	a3,0x1
ffffffffc0200f0e:	7fe68693          	addi	a3,a3,2046 # ffffffffc0202708 <commands+0x708>
ffffffffc0200f12:	00001617          	auipc	a2,0x1
ffffffffc0200f16:	5ee60613          	addi	a2,a2,1518 # ffffffffc0202500 <commands+0x500>
ffffffffc0200f1a:	11a00593          	li	a1,282
ffffffffc0200f1e:	00001517          	auipc	a0,0x1
ffffffffc0200f22:	5fa50513          	addi	a0,a0,1530 # ffffffffc0202518 <commands+0x518>
ffffffffc0200f26:	c8eff0ef          	jal	ra,ffffffffc02003b4 <__panic>
    assert(p0 != NULL);
ffffffffc0200f2a:	00001697          	auipc	a3,0x1
ffffffffc0200f2e:	7ce68693          	addi	a3,a3,1998 # ffffffffc02026f8 <commands+0x6f8>
ffffffffc0200f32:	00001617          	auipc	a2,0x1
ffffffffc0200f36:	5ce60613          	addi	a2,a2,1486 # ffffffffc0202500 <commands+0x500>
ffffffffc0200f3a:	11900593          	li	a1,281
ffffffffc0200f3e:	00001517          	auipc	a0,0x1
ffffffffc0200f42:	5da50513          	addi	a0,a0,1498 # ffffffffc0202518 <commands+0x518>
ffffffffc0200f46:	c6eff0ef          	jal	ra,ffffffffc02003b4 <__panic>
    assert(nr_free == 0);
ffffffffc0200f4a:	00001697          	auipc	a3,0x1
ffffffffc0200f4e:	79e68693          	addi	a3,a3,1950 # ffffffffc02026e8 <commands+0x6e8>
ffffffffc0200f52:	00001617          	auipc	a2,0x1
ffffffffc0200f56:	5ae60613          	addi	a2,a2,1454 # ffffffffc0202500 <commands+0x500>
ffffffffc0200f5a:	0fb00593          	li	a1,251
ffffffffc0200f5e:	00001517          	auipc	a0,0x1
ffffffffc0200f62:	5ba50513          	addi	a0,a0,1466 # ffffffffc0202518 <commands+0x518>
ffffffffc0200f66:	c4eff0ef          	jal	ra,ffffffffc02003b4 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200f6a:	00001697          	auipc	a3,0x1
ffffffffc0200f6e:	71e68693          	addi	a3,a3,1822 # ffffffffc0202688 <commands+0x688>
ffffffffc0200f72:	00001617          	auipc	a2,0x1
ffffffffc0200f76:	58e60613          	addi	a2,a2,1422 # ffffffffc0202500 <commands+0x500>
ffffffffc0200f7a:	0f900593          	li	a1,249
ffffffffc0200f7e:	00001517          	auipc	a0,0x1
ffffffffc0200f82:	59a50513          	addi	a0,a0,1434 # ffffffffc0202518 <commands+0x518>
ffffffffc0200f86:	c2eff0ef          	jal	ra,ffffffffc02003b4 <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0200f8a:	00001697          	auipc	a3,0x1
ffffffffc0200f8e:	73e68693          	addi	a3,a3,1854 # ffffffffc02026c8 <commands+0x6c8>
ffffffffc0200f92:	00001617          	auipc	a2,0x1
ffffffffc0200f96:	56e60613          	addi	a2,a2,1390 # ffffffffc0202500 <commands+0x500>
ffffffffc0200f9a:	0f800593          	li	a1,248
ffffffffc0200f9e:	00001517          	auipc	a0,0x1
ffffffffc0200fa2:	57a50513          	addi	a0,a0,1402 # ffffffffc0202518 <commands+0x518>
ffffffffc0200fa6:	c0eff0ef          	jal	ra,ffffffffc02003b4 <__panic>

ffffffffc0200faa <best_fit_free_pages>:
best_fit_free_pages(struct Page *base, size_t n) {
ffffffffc0200faa:	1141                	addi	sp,sp,-16
ffffffffc0200fac:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200fae:	14058a63          	beqz	a1,ffffffffc0201102 <best_fit_free_pages+0x158>
    for (; p != base + n; p ++) {
ffffffffc0200fb2:	00259693          	slli	a3,a1,0x2
ffffffffc0200fb6:	96ae                	add	a3,a3,a1
ffffffffc0200fb8:	068e                	slli	a3,a3,0x3
ffffffffc0200fba:	96aa                	add	a3,a3,a0
ffffffffc0200fbc:	87aa                	mv	a5,a0
ffffffffc0200fbe:	02d50263          	beq	a0,a3,ffffffffc0200fe2 <best_fit_free_pages+0x38>
ffffffffc0200fc2:	6798                	ld	a4,8(a5)
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0200fc4:	8b05                	andi	a4,a4,1
ffffffffc0200fc6:	10071e63          	bnez	a4,ffffffffc02010e2 <best_fit_free_pages+0x138>
ffffffffc0200fca:	6798                	ld	a4,8(a5)
ffffffffc0200fcc:	8b09                	andi	a4,a4,2
ffffffffc0200fce:	10071a63          	bnez	a4,ffffffffc02010e2 <best_fit_free_pages+0x138>
        p->flags = 0;
ffffffffc0200fd2:	0007b423          	sd	zero,8(a5)



static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0200fd6:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0200fda:	02878793          	addi	a5,a5,40
ffffffffc0200fde:	fed792e3          	bne	a5,a3,ffffffffc0200fc2 <best_fit_free_pages+0x18>
    base->property = n;
ffffffffc0200fe2:	2581                	sext.w	a1,a1
ffffffffc0200fe4:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc0200fe6:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0200fea:	4789                	li	a5,2
ffffffffc0200fec:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc0200ff0:	00005697          	auipc	a3,0x5
ffffffffc0200ff4:	03868693          	addi	a3,a3,56 # ffffffffc0206028 <free_area>
ffffffffc0200ff8:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0200ffa:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc0200ffc:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc0201000:	9db9                	addw	a1,a1,a4
ffffffffc0201002:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list)) {
ffffffffc0201004:	0ad78863          	beq	a5,a3,ffffffffc02010b4 <best_fit_free_pages+0x10a>
            struct Page* page = le2page(le, page_link);
ffffffffc0201008:	fe878713          	addi	a4,a5,-24
ffffffffc020100c:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) {
ffffffffc0201010:	4581                	li	a1,0
            if (base < page) {
ffffffffc0201012:	00e56a63          	bltu	a0,a4,ffffffffc0201026 <best_fit_free_pages+0x7c>
    return listelm->next;
ffffffffc0201016:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc0201018:	06d70263          	beq	a4,a3,ffffffffc020107c <best_fit_free_pages+0xd2>
    for (; p != base + n; p ++) {
ffffffffc020101c:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc020101e:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc0201022:	fee57ae3          	bgeu	a0,a4,ffffffffc0201016 <best_fit_free_pages+0x6c>
ffffffffc0201026:	c199                	beqz	a1,ffffffffc020102c <best_fit_free_pages+0x82>
ffffffffc0201028:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc020102c:	6398                	ld	a4,0(a5)
    prev->next = next->prev = elm;
ffffffffc020102e:	e390                	sd	a2,0(a5)
ffffffffc0201030:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0201032:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201034:	ed18                	sd	a4,24(a0)
    if (le != &free_list) {
ffffffffc0201036:	02d70063          	beq	a4,a3,ffffffffc0201056 <best_fit_free_pages+0xac>
         if (p + p->property == base) {//1
ffffffffc020103a:	ff872803          	lw	a6,-8(a4)
        p = le2page(le, page_link);
ffffffffc020103e:	fe870593          	addi	a1,a4,-24
         if (p + p->property == base) {//1
ffffffffc0201042:	02081613          	slli	a2,a6,0x20
ffffffffc0201046:	9201                	srli	a2,a2,0x20
ffffffffc0201048:	00261793          	slli	a5,a2,0x2
ffffffffc020104c:	97b2                	add	a5,a5,a2
ffffffffc020104e:	078e                	slli	a5,a5,0x3
ffffffffc0201050:	97ae                	add	a5,a5,a1
ffffffffc0201052:	02f50f63          	beq	a0,a5,ffffffffc0201090 <best_fit_free_pages+0xe6>
    return listelm->next;
ffffffffc0201056:	7118                	ld	a4,32(a0)
    if (le != &free_list) {
ffffffffc0201058:	00d70f63          	beq	a4,a3,ffffffffc0201076 <best_fit_free_pages+0xcc>
        if (base + base->property == p) {
ffffffffc020105c:	490c                	lw	a1,16(a0)
        p = le2page(le, page_link);
ffffffffc020105e:	fe870693          	addi	a3,a4,-24
        if (base + base->property == p) {
ffffffffc0201062:	02059613          	slli	a2,a1,0x20
ffffffffc0201066:	9201                	srli	a2,a2,0x20
ffffffffc0201068:	00261793          	slli	a5,a2,0x2
ffffffffc020106c:	97b2                	add	a5,a5,a2
ffffffffc020106e:	078e                	slli	a5,a5,0x3
ffffffffc0201070:	97aa                	add	a5,a5,a0
ffffffffc0201072:	04f68863          	beq	a3,a5,ffffffffc02010c2 <best_fit_free_pages+0x118>
}
ffffffffc0201076:	60a2                	ld	ra,8(sp)
ffffffffc0201078:	0141                	addi	sp,sp,16
ffffffffc020107a:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc020107c:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc020107e:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0201080:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201082:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc0201084:	02d70563          	beq	a4,a3,ffffffffc02010ae <best_fit_free_pages+0x104>
    prev->next = next->prev = elm;
ffffffffc0201088:	8832                	mv	a6,a2
ffffffffc020108a:	4585                	li	a1,1
    for (; p != base + n; p ++) {
ffffffffc020108c:	87ba                	mv	a5,a4
ffffffffc020108e:	bf41                	j	ffffffffc020101e <best_fit_free_pages+0x74>
            p->property += base->property;//2
ffffffffc0201090:	491c                	lw	a5,16(a0)
ffffffffc0201092:	0107883b          	addw	a6,a5,a6
ffffffffc0201096:	ff072c23          	sw	a6,-8(a4)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc020109a:	57f5                	li	a5,-3
ffffffffc020109c:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc02010a0:	6d10                	ld	a2,24(a0)
ffffffffc02010a2:	711c                	ld	a5,32(a0)
            base = p;//5
ffffffffc02010a4:	852e                	mv	a0,a1
    prev->next = next;
ffffffffc02010a6:	e61c                	sd	a5,8(a2)
    return listelm->next;
ffffffffc02010a8:	6718                	ld	a4,8(a4)
    next->prev = prev;
ffffffffc02010aa:	e390                	sd	a2,0(a5)
ffffffffc02010ac:	b775                	j	ffffffffc0201058 <best_fit_free_pages+0xae>
ffffffffc02010ae:	e290                	sd	a2,0(a3)
        while ((le = list_next(le)) != &free_list) {
ffffffffc02010b0:	873e                	mv	a4,a5
ffffffffc02010b2:	b761                	j	ffffffffc020103a <best_fit_free_pages+0x90>
}
ffffffffc02010b4:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc02010b6:	e390                	sd	a2,0(a5)
ffffffffc02010b8:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02010ba:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02010bc:	ed1c                	sd	a5,24(a0)
ffffffffc02010be:	0141                	addi	sp,sp,16
ffffffffc02010c0:	8082                	ret
            base->property += p->property;
ffffffffc02010c2:	ff872783          	lw	a5,-8(a4)
ffffffffc02010c6:	ff070693          	addi	a3,a4,-16
ffffffffc02010ca:	9dbd                	addw	a1,a1,a5
ffffffffc02010cc:	c90c                	sw	a1,16(a0)
ffffffffc02010ce:	57f5                	li	a5,-3
ffffffffc02010d0:	60f6b02f          	amoand.d	zero,a5,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc02010d4:	6314                	ld	a3,0(a4)
ffffffffc02010d6:	671c                	ld	a5,8(a4)
}
ffffffffc02010d8:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc02010da:	e69c                	sd	a5,8(a3)
    next->prev = prev;
ffffffffc02010dc:	e394                	sd	a3,0(a5)
ffffffffc02010de:	0141                	addi	sp,sp,16
ffffffffc02010e0:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc02010e2:	00001697          	auipc	a3,0x1
ffffffffc02010e6:	70e68693          	addi	a3,a3,1806 # ffffffffc02027f0 <commands+0x7f0>
ffffffffc02010ea:	00001617          	auipc	a2,0x1
ffffffffc02010ee:	41660613          	addi	a2,a2,1046 # ffffffffc0202500 <commands+0x500>
ffffffffc02010f2:	09500593          	li	a1,149
ffffffffc02010f6:	00001517          	auipc	a0,0x1
ffffffffc02010fa:	42250513          	addi	a0,a0,1058 # ffffffffc0202518 <commands+0x518>
ffffffffc02010fe:	ab6ff0ef          	jal	ra,ffffffffc02003b4 <__panic>
    assert(n > 0);
ffffffffc0201102:	00001697          	auipc	a3,0x1
ffffffffc0201106:	3f668693          	addi	a3,a3,1014 # ffffffffc02024f8 <commands+0x4f8>
ffffffffc020110a:	00001617          	auipc	a2,0x1
ffffffffc020110e:	3f660613          	addi	a2,a2,1014 # ffffffffc0202500 <commands+0x500>
ffffffffc0201112:	09200593          	li	a1,146
ffffffffc0201116:	00001517          	auipc	a0,0x1
ffffffffc020111a:	40250513          	addi	a0,a0,1026 # ffffffffc0202518 <commands+0x518>
ffffffffc020111e:	a96ff0ef          	jal	ra,ffffffffc02003b4 <__panic>

ffffffffc0201122 <best_fit_init_memmap>:
best_fit_init_memmap(struct Page *base, size_t n) {
ffffffffc0201122:	1141                	addi	sp,sp,-16
ffffffffc0201124:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201126:	c9e1                	beqz	a1,ffffffffc02011f6 <best_fit_init_memmap+0xd4>
    for (; p != base + n; p ++) {
ffffffffc0201128:	00259693          	slli	a3,a1,0x2
ffffffffc020112c:	96ae                	add	a3,a3,a1
ffffffffc020112e:	068e                	slli	a3,a3,0x3
ffffffffc0201130:	96aa                	add	a3,a3,a0
ffffffffc0201132:	87aa                	mv	a5,a0
ffffffffc0201134:	00d50f63          	beq	a0,a3,ffffffffc0201152 <best_fit_init_memmap+0x30>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0201138:	6798                	ld	a4,8(a5)
        assert(PageReserved(p));
ffffffffc020113a:	8b05                	andi	a4,a4,1
ffffffffc020113c:	cf49                	beqz	a4,ffffffffc02011d6 <best_fit_init_memmap+0xb4>
        p->flags = 0;
ffffffffc020113e:	0007b423          	sd	zero,8(a5)
        p->property = 0;
ffffffffc0201142:	0007a823          	sw	zero,16(a5)
ffffffffc0201146:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc020114a:	02878793          	addi	a5,a5,40
ffffffffc020114e:	fed795e3          	bne	a5,a3,ffffffffc0201138 <best_fit_init_memmap+0x16>
    base->property = n;
ffffffffc0201152:	2581                	sext.w	a1,a1
ffffffffc0201154:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201156:	4789                	li	a5,2
ffffffffc0201158:	00850713          	addi	a4,a0,8
ffffffffc020115c:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc0201160:	00005697          	auipc	a3,0x5
ffffffffc0201164:	ec868693          	addi	a3,a3,-312 # ffffffffc0206028 <free_area>
ffffffffc0201168:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc020116a:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc020116c:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc0201170:	9db9                	addw	a1,a1,a4
ffffffffc0201172:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list)) {
ffffffffc0201174:	04d78a63          	beq	a5,a3,ffffffffc02011c8 <best_fit_init_memmap+0xa6>
            struct Page* page = le2page(le, page_link);
ffffffffc0201178:	fe878713          	addi	a4,a5,-24
ffffffffc020117c:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) {
ffffffffc0201180:	4581                	li	a1,0
            if(base<page)
ffffffffc0201182:	00e56a63          	bltu	a0,a4,ffffffffc0201196 <best_fit_init_memmap+0x74>
    return listelm->next;
ffffffffc0201186:	6798                	ld	a4,8(a5)
            if(list_next(le)==&free_list)
ffffffffc0201188:	02d70263          	beq	a4,a3,ffffffffc02011ac <best_fit_init_memmap+0x8a>
    for (; p != base + n; p ++) {
ffffffffc020118c:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc020118e:	fe878713          	addi	a4,a5,-24
            if(base<page)
ffffffffc0201192:	fee57ae3          	bgeu	a0,a4,ffffffffc0201186 <best_fit_init_memmap+0x64>
ffffffffc0201196:	c199                	beqz	a1,ffffffffc020119c <best_fit_init_memmap+0x7a>
ffffffffc0201198:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc020119c:	6398                	ld	a4,0(a5)
}
ffffffffc020119e:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc02011a0:	e390                	sd	a2,0(a5)
ffffffffc02011a2:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc02011a4:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02011a6:	ed18                	sd	a4,24(a0)
ffffffffc02011a8:	0141                	addi	sp,sp,16
ffffffffc02011aa:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc02011ac:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02011ae:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc02011b0:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc02011b2:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc02011b4:	00d70663          	beq	a4,a3,ffffffffc02011c0 <best_fit_init_memmap+0x9e>
    prev->next = next->prev = elm;
ffffffffc02011b8:	8832                	mv	a6,a2
ffffffffc02011ba:	4585                	li	a1,1
    for (; p != base + n; p ++) {
ffffffffc02011bc:	87ba                	mv	a5,a4
ffffffffc02011be:	bfc1                	j	ffffffffc020118e <best_fit_init_memmap+0x6c>
}
ffffffffc02011c0:	60a2                	ld	ra,8(sp)
ffffffffc02011c2:	e290                	sd	a2,0(a3)
ffffffffc02011c4:	0141                	addi	sp,sp,16
ffffffffc02011c6:	8082                	ret
ffffffffc02011c8:	60a2                	ld	ra,8(sp)
ffffffffc02011ca:	e390                	sd	a2,0(a5)
ffffffffc02011cc:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02011ce:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02011d0:	ed1c                	sd	a5,24(a0)
ffffffffc02011d2:	0141                	addi	sp,sp,16
ffffffffc02011d4:	8082                	ret
        assert(PageReserved(p));
ffffffffc02011d6:	00001697          	auipc	a3,0x1
ffffffffc02011da:	64268693          	addi	a3,a3,1602 # ffffffffc0202818 <commands+0x818>
ffffffffc02011de:	00001617          	auipc	a2,0x1
ffffffffc02011e2:	32260613          	addi	a2,a2,802 # ffffffffc0202500 <commands+0x500>
ffffffffc02011e6:	04a00593          	li	a1,74
ffffffffc02011ea:	00001517          	auipc	a0,0x1
ffffffffc02011ee:	32e50513          	addi	a0,a0,814 # ffffffffc0202518 <commands+0x518>
ffffffffc02011f2:	9c2ff0ef          	jal	ra,ffffffffc02003b4 <__panic>
    assert(n > 0);
ffffffffc02011f6:	00001697          	auipc	a3,0x1
ffffffffc02011fa:	30268693          	addi	a3,a3,770 # ffffffffc02024f8 <commands+0x4f8>
ffffffffc02011fe:	00001617          	auipc	a2,0x1
ffffffffc0201202:	30260613          	addi	a2,a2,770 # ffffffffc0202500 <commands+0x500>
ffffffffc0201206:	04700593          	li	a1,71
ffffffffc020120a:	00001517          	auipc	a0,0x1
ffffffffc020120e:	30e50513          	addi	a0,a0,782 # ffffffffc0202518 <commands+0x518>
ffffffffc0201212:	9a2ff0ef          	jal	ra,ffffffffc02003b4 <__panic>

ffffffffc0201216 <alloc_pages>:
#include <defs.h>
#include <intr.h>
#include <riscv.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201216:	100027f3          	csrr	a5,sstatus
ffffffffc020121a:	8b89                	andi	a5,a5,2
ffffffffc020121c:	e799                	bnez	a5,ffffffffc020122a <alloc_pages+0x14>
struct Page *alloc_pages(size_t n) {
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc020121e:	00005797          	auipc	a5,0x5
ffffffffc0201222:	2427b783          	ld	a5,578(a5) # ffffffffc0206460 <pmm_manager>
ffffffffc0201226:	6f9c                	ld	a5,24(a5)
ffffffffc0201228:	8782                	jr	a5
struct Page *alloc_pages(size_t n) {
ffffffffc020122a:	1141                	addi	sp,sp,-16
ffffffffc020122c:	e406                	sd	ra,8(sp)
ffffffffc020122e:	e022                	sd	s0,0(sp)
ffffffffc0201230:	842a                	mv	s0,a0
        intr_disable();
ffffffffc0201232:	a34ff0ef          	jal	ra,ffffffffc0200466 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201236:	00005797          	auipc	a5,0x5
ffffffffc020123a:	22a7b783          	ld	a5,554(a5) # ffffffffc0206460 <pmm_manager>
ffffffffc020123e:	6f9c                	ld	a5,24(a5)
ffffffffc0201240:	8522                	mv	a0,s0
ffffffffc0201242:	9782                	jalr	a5
ffffffffc0201244:	842a                	mv	s0,a0
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
        intr_enable();
ffffffffc0201246:	a1aff0ef          	jal	ra,ffffffffc0200460 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc020124a:	60a2                	ld	ra,8(sp)
ffffffffc020124c:	8522                	mv	a0,s0
ffffffffc020124e:	6402                	ld	s0,0(sp)
ffffffffc0201250:	0141                	addi	sp,sp,16
ffffffffc0201252:	8082                	ret

ffffffffc0201254 <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201254:	100027f3          	csrr	a5,sstatus
ffffffffc0201258:	8b89                	andi	a5,a5,2
ffffffffc020125a:	e799                	bnez	a5,ffffffffc0201268 <free_pages+0x14>
// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc020125c:	00005797          	auipc	a5,0x5
ffffffffc0201260:	2047b783          	ld	a5,516(a5) # ffffffffc0206460 <pmm_manager>
ffffffffc0201264:	739c                	ld	a5,32(a5)
ffffffffc0201266:	8782                	jr	a5
void free_pages(struct Page *base, size_t n) {
ffffffffc0201268:	1101                	addi	sp,sp,-32
ffffffffc020126a:	ec06                	sd	ra,24(sp)
ffffffffc020126c:	e822                	sd	s0,16(sp)
ffffffffc020126e:	e426                	sd	s1,8(sp)
ffffffffc0201270:	842a                	mv	s0,a0
ffffffffc0201272:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc0201274:	9f2ff0ef          	jal	ra,ffffffffc0200466 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0201278:	00005797          	auipc	a5,0x5
ffffffffc020127c:	1e87b783          	ld	a5,488(a5) # ffffffffc0206460 <pmm_manager>
ffffffffc0201280:	739c                	ld	a5,32(a5)
ffffffffc0201282:	85a6                	mv	a1,s1
ffffffffc0201284:	8522                	mv	a0,s0
ffffffffc0201286:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0201288:	6442                	ld	s0,16(sp)
ffffffffc020128a:	60e2                	ld	ra,24(sp)
ffffffffc020128c:	64a2                	ld	s1,8(sp)
ffffffffc020128e:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0201290:	9d0ff06f          	j	ffffffffc0200460 <intr_enable>

ffffffffc0201294 <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201294:	100027f3          	csrr	a5,sstatus
ffffffffc0201298:	8b89                	andi	a5,a5,2
ffffffffc020129a:	e799                	bnez	a5,ffffffffc02012a8 <nr_free_pages+0x14>
size_t nr_free_pages(void) {
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc020129c:	00005797          	auipc	a5,0x5
ffffffffc02012a0:	1c47b783          	ld	a5,452(a5) # ffffffffc0206460 <pmm_manager>
ffffffffc02012a4:	779c                	ld	a5,40(a5)
ffffffffc02012a6:	8782                	jr	a5
size_t nr_free_pages(void) {
ffffffffc02012a8:	1141                	addi	sp,sp,-16
ffffffffc02012aa:	e406                	sd	ra,8(sp)
ffffffffc02012ac:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc02012ae:	9b8ff0ef          	jal	ra,ffffffffc0200466 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc02012b2:	00005797          	auipc	a5,0x5
ffffffffc02012b6:	1ae7b783          	ld	a5,430(a5) # ffffffffc0206460 <pmm_manager>
ffffffffc02012ba:	779c                	ld	a5,40(a5)
ffffffffc02012bc:	9782                	jalr	a5
ffffffffc02012be:	842a                	mv	s0,a0
        intr_enable();
ffffffffc02012c0:	9a0ff0ef          	jal	ra,ffffffffc0200460 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc02012c4:	60a2                	ld	ra,8(sp)
ffffffffc02012c6:	8522                	mv	a0,s0
ffffffffc02012c8:	6402                	ld	s0,0(sp)
ffffffffc02012ca:	0141                	addi	sp,sp,16
ffffffffc02012cc:	8082                	ret

ffffffffc02012ce <pmm_init>:
    pmm_manager = &best_fit_pmm_manager;
ffffffffc02012ce:	00001797          	auipc	a5,0x1
ffffffffc02012d2:	57278793          	addi	a5,a5,1394 # ffffffffc0202840 <best_fit_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02012d6:	638c                	ld	a1,0(a5)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
    }
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc02012d8:	1101                	addi	sp,sp,-32
ffffffffc02012da:	e426                	sd	s1,8(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02012dc:	00001517          	auipc	a0,0x1
ffffffffc02012e0:	59c50513          	addi	a0,a0,1436 # ffffffffc0202878 <best_fit_pmm_manager+0x38>
    pmm_manager = &best_fit_pmm_manager;
ffffffffc02012e4:	00005497          	auipc	s1,0x5
ffffffffc02012e8:	17c48493          	addi	s1,s1,380 # ffffffffc0206460 <pmm_manager>
void pmm_init(void) {
ffffffffc02012ec:	ec06                	sd	ra,24(sp)
ffffffffc02012ee:	e822                	sd	s0,16(sp)
    pmm_manager = &best_fit_pmm_manager;
ffffffffc02012f0:	e09c                	sd	a5,0(s1)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02012f2:	dc9fe0ef          	jal	ra,ffffffffc02000ba <cprintf>
    pmm_manager->init();
ffffffffc02012f6:	609c                	ld	a5,0(s1)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc02012f8:	00005417          	auipc	s0,0x5
ffffffffc02012fc:	18040413          	addi	s0,s0,384 # ffffffffc0206478 <va_pa_offset>
    pmm_manager->init();
ffffffffc0201300:	679c                	ld	a5,8(a5)
ffffffffc0201302:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0201304:	57f5                	li	a5,-3
ffffffffc0201306:	07fa                	slli	a5,a5,0x1e
    cprintf("physcial memory map:\n");
ffffffffc0201308:	00001517          	auipc	a0,0x1
ffffffffc020130c:	58850513          	addi	a0,a0,1416 # ffffffffc0202890 <best_fit_pmm_manager+0x50>
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0201310:	e01c                	sd	a5,0(s0)
    cprintf("physcial memory map:\n");
ffffffffc0201312:	da9fe0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc0201316:	46c5                	li	a3,17
ffffffffc0201318:	06ee                	slli	a3,a3,0x1b
ffffffffc020131a:	40100613          	li	a2,1025
ffffffffc020131e:	16fd                	addi	a3,a3,-1
ffffffffc0201320:	07e005b7          	lui	a1,0x7e00
ffffffffc0201324:	0656                	slli	a2,a2,0x15
ffffffffc0201326:	00001517          	auipc	a0,0x1
ffffffffc020132a:	58250513          	addi	a0,a0,1410 # ffffffffc02028a8 <best_fit_pmm_manager+0x68>
ffffffffc020132e:	d8dfe0ef          	jal	ra,ffffffffc02000ba <cprintf>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0201332:	777d                	lui	a4,0xfffff
ffffffffc0201334:	00006797          	auipc	a5,0x6
ffffffffc0201338:	15378793          	addi	a5,a5,339 # ffffffffc0207487 <end+0xfff>
ffffffffc020133c:	8ff9                	and	a5,a5,a4
    npage = maxpa / PGSIZE;
ffffffffc020133e:	00005517          	auipc	a0,0x5
ffffffffc0201342:	11250513          	addi	a0,a0,274 # ffffffffc0206450 <npage>
ffffffffc0201346:	00088737          	lui	a4,0x88
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc020134a:	00005597          	auipc	a1,0x5
ffffffffc020134e:	10e58593          	addi	a1,a1,270 # ffffffffc0206458 <pages>
    npage = maxpa / PGSIZE;
ffffffffc0201352:	e118                	sd	a4,0(a0)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0201354:	e19c                	sd	a5,0(a1)
ffffffffc0201356:	4681                	li	a3,0
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0201358:	4701                	li	a4,0
ffffffffc020135a:	4885                	li	a7,1
ffffffffc020135c:	fff80837          	lui	a6,0xfff80
ffffffffc0201360:	a011                	j	ffffffffc0201364 <pmm_init+0x96>
        SetPageReserved(pages + i);
ffffffffc0201362:	619c                	ld	a5,0(a1)
ffffffffc0201364:	97b6                	add	a5,a5,a3
ffffffffc0201366:	07a1                	addi	a5,a5,8
ffffffffc0201368:	4117b02f          	amoor.d	zero,a7,(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc020136c:	611c                	ld	a5,0(a0)
ffffffffc020136e:	0705                	addi	a4,a4,1
ffffffffc0201370:	02868693          	addi	a3,a3,40
ffffffffc0201374:	01078633          	add	a2,a5,a6
ffffffffc0201378:	fec765e3          	bltu	a4,a2,ffffffffc0201362 <pmm_init+0x94>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020137c:	6190                	ld	a2,0(a1)
ffffffffc020137e:	00279713          	slli	a4,a5,0x2
ffffffffc0201382:	973e                	add	a4,a4,a5
ffffffffc0201384:	fec006b7          	lui	a3,0xfec00
ffffffffc0201388:	070e                	slli	a4,a4,0x3
ffffffffc020138a:	96b2                	add	a3,a3,a2
ffffffffc020138c:	96ba                	add	a3,a3,a4
ffffffffc020138e:	c0200737          	lui	a4,0xc0200
ffffffffc0201392:	08e6ef63          	bltu	a3,a4,ffffffffc0201430 <pmm_init+0x162>
ffffffffc0201396:	6018                	ld	a4,0(s0)
    if (freemem < mem_end) {
ffffffffc0201398:	45c5                	li	a1,17
ffffffffc020139a:	05ee                	slli	a1,a1,0x1b
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020139c:	8e99                	sub	a3,a3,a4
    if (freemem < mem_end) {
ffffffffc020139e:	04b6e863          	bltu	a3,a1,ffffffffc02013ee <pmm_init+0x120>
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc02013a2:	609c                	ld	a5,0(s1)
ffffffffc02013a4:	7b9c                	ld	a5,48(a5)
ffffffffc02013a6:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc02013a8:	00001517          	auipc	a0,0x1
ffffffffc02013ac:	59850513          	addi	a0,a0,1432 # ffffffffc0202940 <best_fit_pmm_manager+0x100>
ffffffffc02013b0:	d0bfe0ef          	jal	ra,ffffffffc02000ba <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc02013b4:	00004597          	auipc	a1,0x4
ffffffffc02013b8:	c4c58593          	addi	a1,a1,-948 # ffffffffc0205000 <boot_page_table_sv39>
ffffffffc02013bc:	00005797          	auipc	a5,0x5
ffffffffc02013c0:	0ab7ba23          	sd	a1,180(a5) # ffffffffc0206470 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc02013c4:	c02007b7          	lui	a5,0xc0200
ffffffffc02013c8:	08f5e063          	bltu	a1,a5,ffffffffc0201448 <pmm_init+0x17a>
ffffffffc02013cc:	6010                	ld	a2,0(s0)
}
ffffffffc02013ce:	6442                	ld	s0,16(sp)
ffffffffc02013d0:	60e2                	ld	ra,24(sp)
ffffffffc02013d2:	64a2                	ld	s1,8(sp)
    satp_physical = PADDR(satp_virtual);
ffffffffc02013d4:	40c58633          	sub	a2,a1,a2
ffffffffc02013d8:	00005797          	auipc	a5,0x5
ffffffffc02013dc:	08c7b823          	sd	a2,144(a5) # ffffffffc0206468 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc02013e0:	00001517          	auipc	a0,0x1
ffffffffc02013e4:	58050513          	addi	a0,a0,1408 # ffffffffc0202960 <best_fit_pmm_manager+0x120>
}
ffffffffc02013e8:	6105                	addi	sp,sp,32
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc02013ea:	cd1fe06f          	j	ffffffffc02000ba <cprintf>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc02013ee:	6705                	lui	a4,0x1
ffffffffc02013f0:	177d                	addi	a4,a4,-1
ffffffffc02013f2:	96ba                	add	a3,a3,a4
ffffffffc02013f4:	777d                	lui	a4,0xfffff
ffffffffc02013f6:	8ef9                	and	a3,a3,a4
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc02013f8:	00c6d513          	srli	a0,a3,0xc
ffffffffc02013fc:	00f57e63          	bgeu	a0,a5,ffffffffc0201418 <pmm_init+0x14a>
    pmm_manager->init_memmap(base, n);
ffffffffc0201400:	609c                	ld	a5,0(s1)
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc0201402:	982a                	add	a6,a6,a0
ffffffffc0201404:	00281513          	slli	a0,a6,0x2
ffffffffc0201408:	9542                	add	a0,a0,a6
ffffffffc020140a:	6b9c                	ld	a5,16(a5)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc020140c:	8d95                	sub	a1,a1,a3
ffffffffc020140e:	050e                	slli	a0,a0,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc0201410:	81b1                	srli	a1,a1,0xc
ffffffffc0201412:	9532                	add	a0,a0,a2
ffffffffc0201414:	9782                	jalr	a5
}
ffffffffc0201416:	b771                	j	ffffffffc02013a2 <pmm_init+0xd4>
        panic("pa2page called with invalid pa");
ffffffffc0201418:	00001617          	auipc	a2,0x1
ffffffffc020141c:	4f860613          	addi	a2,a2,1272 # ffffffffc0202910 <best_fit_pmm_manager+0xd0>
ffffffffc0201420:	06b00593          	li	a1,107
ffffffffc0201424:	00001517          	auipc	a0,0x1
ffffffffc0201428:	50c50513          	addi	a0,a0,1292 # ffffffffc0202930 <best_fit_pmm_manager+0xf0>
ffffffffc020142c:	f89fe0ef          	jal	ra,ffffffffc02003b4 <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201430:	00001617          	auipc	a2,0x1
ffffffffc0201434:	4a860613          	addi	a2,a2,1192 # ffffffffc02028d8 <best_fit_pmm_manager+0x98>
ffffffffc0201438:	07000593          	li	a1,112
ffffffffc020143c:	00001517          	auipc	a0,0x1
ffffffffc0201440:	4c450513          	addi	a0,a0,1220 # ffffffffc0202900 <best_fit_pmm_manager+0xc0>
ffffffffc0201444:	f71fe0ef          	jal	ra,ffffffffc02003b4 <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc0201448:	86ae                	mv	a3,a1
ffffffffc020144a:	00001617          	auipc	a2,0x1
ffffffffc020144e:	48e60613          	addi	a2,a2,1166 # ffffffffc02028d8 <best_fit_pmm_manager+0x98>
ffffffffc0201452:	08b00593          	li	a1,139
ffffffffc0201456:	00001517          	auipc	a0,0x1
ffffffffc020145a:	4aa50513          	addi	a0,a0,1194 # ffffffffc0202900 <best_fit_pmm_manager+0xc0>
ffffffffc020145e:	f57fe0ef          	jal	ra,ffffffffc02003b4 <__panic>

ffffffffc0201462 <free_small_block>:


static void free_small_block(void *block, int size) {
    small_block_t *current;
    small_block_t *block_to_free = (small_block_t *)block;
    if (!block) return;
ffffffffc0201462:	c971                	beqz	a0,ffffffffc0201536 <free_small_block+0xd4>
static void free_small_block(void *block, int size) {
ffffffffc0201464:	1101                	addi	sp,sp,-32
ffffffffc0201466:	e426                	sd	s1,8(sp)
ffffffffc0201468:	ec06                	sd	ra,24(sp)
ffffffffc020146a:	e822                	sd	s0,16(sp)
ffffffffc020146c:	e04a                	sd	s2,0(sp)
ffffffffc020146e:	84aa                	mv	s1,a0
    if (size) block_to_free->size_units = SIZE_TO_UNITS(size); // 设置块的大小
ffffffffc0201470:	e1ad                	bnez	a1,ffffffffc02014d2 <free_small_block+0x70>
            break;
        }
    }

    // 合并相邻的空闲块
    if ((char *)block_to_free + block_to_free->size_units * SMALL_UNIT == (char *)current->next) {
ffffffffc0201472:	4118                	lw	a4,0(a0)
    for (current = free_list_head; !(block_to_free > current && block_to_free < current->next); current = current->next) {
ffffffffc0201474:	00005917          	auipc	s2,0x5
ffffffffc0201478:	b9c90913          	addi	s2,s2,-1124 # ffffffffc0206010 <free_list_head>
ffffffffc020147c:	00093783          	ld	a5,0(s2)
        if (current >= current->next && (block_to_free > current || block_to_free < current->next)) {
ffffffffc0201480:	843e                	mv	s0,a5
    for (current = free_list_head; !(block_to_free > current && block_to_free < current->next); current = current->next) {
ffffffffc0201482:	679c                	ld	a5,8(a5)
ffffffffc0201484:	04947c63          	bgeu	s0,s1,ffffffffc02014dc <free_small_block+0x7a>
ffffffffc0201488:	00f4e463          	bltu	s1,a5,ffffffffc0201490 <free_small_block+0x2e>
        if (current >= current->next && (block_to_free > current || block_to_free < current->next)) {
ffffffffc020148c:	fef46ae3          	bltu	s0,a5,ffffffffc0201480 <free_small_block+0x1e>
    if ((char *)block_to_free + block_to_free->size_units * SMALL_UNIT == (char *)current->next) {
ffffffffc0201490:	00471693          	slli	a3,a4,0x4
ffffffffc0201494:	96a6                	add	a3,a3,s1
ffffffffc0201496:	04d78c63          	beq	a5,a3,ffffffffc02014ee <free_small_block+0x8c>
        block_to_free->size_units += current->next->size_units; // 合并
        block_to_free->next = current->next->next;
        cprintf("Merge successful! Free list length will decrease by 1.\n");
    } else {
        block_to_free->next = current->next;
ffffffffc020149a:	e49c                	sd	a5,8(s1)
        cprintf("No merge, inserting into the list.\n");
ffffffffc020149c:	00001517          	auipc	a0,0x1
ffffffffc02014a0:	53c50513          	addi	a0,a0,1340 # ffffffffc02029d8 <best_fit_pmm_manager+0x198>
ffffffffc02014a4:	c17fe0ef          	jal	ra,ffffffffc02000ba <cprintf>
    }

    if ((char *)current + current->size_units * SMALL_UNIT == (char *)block_to_free) {
ffffffffc02014a8:	4018                	lw	a4,0(s0)
ffffffffc02014aa:	00471793          	slli	a5,a4,0x4
ffffffffc02014ae:	97a2                	add	a5,a5,s0
ffffffffc02014b0:	06f48063          	beq	s1,a5,ffffffffc0201510 <free_small_block+0xae>
        current->size_units += block_to_free->size_units; // 合并
        current->next = block_to_free->next;
        cprintf("Merge successful with previous block! Free list length will decrease by 1.\n");
    } else {
        current->next = block_to_free; // 插入到当前块后
ffffffffc02014b4:	e404                	sd	s1,8(s0)
        cprintf("Inserted block without merging.\n");
ffffffffc02014b6:	00001517          	auipc	a0,0x1
ffffffffc02014ba:	59a50513          	addi	a0,a0,1434 # ffffffffc0202a50 <best_fit_pmm_manager+0x210>
ffffffffc02014be:	bfdfe0ef          	jal	ra,ffffffffc02000ba <cprintf>
    }

    free_list_head = current; // 更新空闲链表头
}
ffffffffc02014c2:	60e2                	ld	ra,24(sp)
    free_list_head = current; // 更新空闲链表头
ffffffffc02014c4:	00893023          	sd	s0,0(s2)
}
ffffffffc02014c8:	6442                	ld	s0,16(sp)
ffffffffc02014ca:	64a2                	ld	s1,8(sp)
ffffffffc02014cc:	6902                	ld	s2,0(sp)
ffffffffc02014ce:	6105                	addi	sp,sp,32
ffffffffc02014d0:	8082                	ret
    if (size) block_to_free->size_units = SIZE_TO_UNITS(size); // 设置块的大小
ffffffffc02014d2:	00f5871b          	addiw	a4,a1,15
ffffffffc02014d6:	8711                	srai	a4,a4,0x4
ffffffffc02014d8:	c118                	sw	a4,0(a0)
ffffffffc02014da:	bf69                	j	ffffffffc0201474 <free_small_block+0x12>
        if (current >= current->next && (block_to_free > current || block_to_free < current->next)) {
ffffffffc02014dc:	faf462e3          	bltu	s0,a5,ffffffffc0201480 <free_small_block+0x1e>
ffffffffc02014e0:	faf4f0e3          	bgeu	s1,a5,ffffffffc0201480 <free_small_block+0x1e>
    if ((char *)block_to_free + block_to_free->size_units * SMALL_UNIT == (char *)current->next) {
ffffffffc02014e4:	00471693          	slli	a3,a4,0x4
ffffffffc02014e8:	96a6                	add	a3,a3,s1
ffffffffc02014ea:	fad798e3          	bne	a5,a3,ffffffffc020149a <free_small_block+0x38>
        block_to_free->size_units += current->next->size_units; // 合并
ffffffffc02014ee:	4394                	lw	a3,0(a5)
        block_to_free->next = current->next->next;
ffffffffc02014f0:	679c                	ld	a5,8(a5)
        cprintf("Merge successful! Free list length will decrease by 1.\n");
ffffffffc02014f2:	00001517          	auipc	a0,0x1
ffffffffc02014f6:	4ae50513          	addi	a0,a0,1198 # ffffffffc02029a0 <best_fit_pmm_manager+0x160>
        block_to_free->size_units += current->next->size_units; // 合并
ffffffffc02014fa:	9f35                	addw	a4,a4,a3
ffffffffc02014fc:	c098                	sw	a4,0(s1)
        block_to_free->next = current->next->next;
ffffffffc02014fe:	e49c                	sd	a5,8(s1)
        cprintf("Merge successful! Free list length will decrease by 1.\n");
ffffffffc0201500:	bbbfe0ef          	jal	ra,ffffffffc02000ba <cprintf>
    if ((char *)current + current->size_units * SMALL_UNIT == (char *)block_to_free) {
ffffffffc0201504:	4018                	lw	a4,0(s0)
ffffffffc0201506:	00471793          	slli	a5,a4,0x4
ffffffffc020150a:	97a2                	add	a5,a5,s0
ffffffffc020150c:	faf494e3          	bne	s1,a5,ffffffffc02014b4 <free_small_block+0x52>
        current->size_units += block_to_free->size_units; // 合并
ffffffffc0201510:	409c                	lw	a5,0(s1)
        current->next = block_to_free->next;
ffffffffc0201512:	6494                	ld	a3,8(s1)
        cprintf("Merge successful with previous block! Free list length will decrease by 1.\n");
ffffffffc0201514:	00001517          	auipc	a0,0x1
ffffffffc0201518:	4ec50513          	addi	a0,a0,1260 # ffffffffc0202a00 <best_fit_pmm_manager+0x1c0>
        current->size_units += block_to_free->size_units; // 合并
ffffffffc020151c:	9f3d                	addw	a4,a4,a5
ffffffffc020151e:	c018                	sw	a4,0(s0)
        current->next = block_to_free->next;
ffffffffc0201520:	e414                	sd	a3,8(s0)
        cprintf("Merge successful with previous block! Free list length will decrease by 1.\n");
ffffffffc0201522:	b99fe0ef          	jal	ra,ffffffffc02000ba <cprintf>
}
ffffffffc0201526:	60e2                	ld	ra,24(sp)
    free_list_head = current; // 更新空闲链表头
ffffffffc0201528:	00893023          	sd	s0,0(s2)
}
ffffffffc020152c:	6442                	ld	s0,16(sp)
ffffffffc020152e:	64a2                	ld	s1,8(sp)
ffffffffc0201530:	6902                	ld	s2,0(sp)
ffffffffc0201532:	6105                	addi	sp,sp,32
ffffffffc0201534:	8082                	ret
ffffffffc0201536:	8082                	ret

ffffffffc0201538 <allocate_small_block>:
static void *allocate_small_block(size_t size) {
ffffffffc0201538:	7139                	addi	sp,sp,-64
ffffffffc020153a:	fc06                	sd	ra,56(sp)
ffffffffc020153c:	f822                	sd	s0,48(sp)
ffffffffc020153e:	f426                	sd	s1,40(sp)
ffffffffc0201540:	f04a                	sd	s2,32(sp)
ffffffffc0201542:	ec4e                	sd	s3,24(sp)
ffffffffc0201544:	e852                	sd	s4,16(sp)
ffffffffc0201546:	e456                	sd	s5,8(sp)
    assert(size < PGSIZE); // 确保请求的大小小于页面大小
ffffffffc0201548:	6785                	lui	a5,0x1
ffffffffc020154a:	0cf57063          	bgeu	a0,a5,ffffffffc020160a <allocate_small_block+0xd2>
    int required_units = SIZE_TO_UNITS(size); // 计算所需的单位数
ffffffffc020154e:	053d                	addi	a0,a0,15
    small_block_t *prev = free_list_head;
ffffffffc0201550:	00005497          	auipc	s1,0x5
ffffffffc0201554:	ac048493          	addi	s1,s1,-1344 # ffffffffc0206010 <free_list_head>
ffffffffc0201558:	0004b983          	ld	s3,0(s1)
    int required_units = SIZE_TO_UNITS(size); // 计算所需的单位数
ffffffffc020155c:	00455a93          	srli	s5,a0,0x4
ffffffffc0201560:	000a891b          	sext.w	s2,s5
    cprintf("Required units: %d\n", required_units);
ffffffffc0201564:	85ca                	mv	a1,s2
ffffffffc0201566:	00001517          	auipc	a0,0x1
ffffffffc020156a:	53250513          	addi	a0,a0,1330 # ffffffffc0202a98 <best_fit_pmm_manager+0x258>
ffffffffc020156e:	b4dfe0ef          	jal	ra,ffffffffc02000ba <cprintf>
        cprintf("Current block size: %d\n", curr->size_units);
ffffffffc0201572:	00001a17          	auipc	s4,0x1
ffffffffc0201576:	53ea0a13          	addi	s4,s4,1342 # ffffffffc0202ab0 <best_fit_pmm_manager+0x270>
    for (curr = prev->next; ; prev = curr, curr = curr->next) {
ffffffffc020157a:	0089b403          	ld	s0,8(s3)
ffffffffc020157e:	a019                	j	ffffffffc0201584 <allocate_small_block+0x4c>
        cprintf("Current block size: %d\n", curr->size_units);
ffffffffc0201580:	89a2                	mv	s3,s0
    for (curr = prev->next; ; prev = curr, curr = curr->next) {
ffffffffc0201582:	843e                	mv	s0,a5
        cprintf("Current block size: %d\n", curr->size_units);
ffffffffc0201584:	400c                	lw	a1,0(s0)
ffffffffc0201586:	8552                	mv	a0,s4
ffffffffc0201588:	b33fe0ef          	jal	ra,ffffffffc02000ba <cprintf>
        if (curr->size_units >= required_units) {
ffffffffc020158c:	401c                	lw	a5,0(s0)
ffffffffc020158e:	0327d163          	bge	a5,s2,ffffffffc02015b0 <allocate_small_block+0x78>
        if (curr->next == free_list_head) { // 遍历回到链表头
ffffffffc0201592:	641c                	ld	a5,8(s0)
ffffffffc0201594:	6098                	ld	a4,0(s1)
ffffffffc0201596:	fee795e3          	bne	a5,a4,ffffffffc0201580 <allocate_small_block+0x48>
            curr = (small_block_t *)alloc_pages(1); 
ffffffffc020159a:	4505                	li	a0,1
ffffffffc020159c:	c7bff0ef          	jal	ra,ffffffffc0201216 <alloc_pages>
ffffffffc02015a0:	842a                	mv	s0,a0
            if (!curr) return NULL; // 分配失败
ffffffffc02015a2:	cd15                	beqz	a0,ffffffffc02015de <allocate_small_block+0xa6>
            free_small_block(curr, PGSIZE); // 初始化新页面
ffffffffc02015a4:	6585                	lui	a1,0x1
ffffffffc02015a6:	ebdff0ef          	jal	ra,ffffffffc0201462 <free_small_block>
            curr = free_list_head; // 更新当前块
ffffffffc02015aa:	6080                	ld	s0,0(s1)
    for (curr = prev->next; ; prev = curr, curr = curr->next) {
ffffffffc02015ac:	641c                	ld	a5,8(s0)
ffffffffc02015ae:	bfc9                	j	ffffffffc0201580 <allocate_small_block+0x48>
            if (curr->size_units == required_units) {
ffffffffc02015b0:	05278163          	beq	a5,s2,ffffffffc02015f2 <allocate_small_block+0xba>
                prev->next = (small_block_t *)((char *)curr + required_units * SMALL_UNIT);
ffffffffc02015b4:	0a92                	slli	s5,s5,0x4
ffffffffc02015b6:	9aa2                	add	s5,s5,s0
ffffffffc02015b8:	0159b423          	sd	s5,8(s3)
                prev->next->next = curr->next;
ffffffffc02015bc:	6418                	ld	a4,8(s0)
                prev->next->size_units = curr->size_units - required_units;
ffffffffc02015be:	412787bb          	subw	a5,a5,s2
ffffffffc02015c2:	00faa023          	sw	a5,0(s5)
                prev->next->next = curr->next;
ffffffffc02015c6:	00eab423          	sd	a4,8(s5)
                curr->size_units = required_units; // 更新当前块大小
ffffffffc02015ca:	01242023          	sw	s2,0(s0)
                cprintf("Allocated smaller block, cutting!\n");
ffffffffc02015ce:	00001517          	auipc	a0,0x1
ffffffffc02015d2:	51a50513          	addi	a0,a0,1306 # ffffffffc0202ae8 <best_fit_pmm_manager+0x2a8>
ffffffffc02015d6:	ae5fe0ef          	jal	ra,ffffffffc02000ba <cprintf>
            free_list_head = prev; // 更新空闲链表头
ffffffffc02015da:	0134b023          	sd	s3,0(s1)
}
ffffffffc02015de:	70e2                	ld	ra,56(sp)
ffffffffc02015e0:	8522                	mv	a0,s0
ffffffffc02015e2:	7442                	ld	s0,48(sp)
ffffffffc02015e4:	74a2                	ld	s1,40(sp)
ffffffffc02015e6:	7902                	ld	s2,32(sp)
ffffffffc02015e8:	69e2                	ld	s3,24(sp)
ffffffffc02015ea:	6a42                	ld	s4,16(sp)
ffffffffc02015ec:	6aa2                	ld	s5,8(sp)
ffffffffc02015ee:	6121                	addi	sp,sp,64
ffffffffc02015f0:	8082                	ret
                prev->next = curr->next; // 完全匹配，移除当前块
ffffffffc02015f2:	641c                	ld	a5,8(s0)
                cprintf("Allocated a perfect match!\n");
ffffffffc02015f4:	00001517          	auipc	a0,0x1
ffffffffc02015f8:	4d450513          	addi	a0,a0,1236 # ffffffffc0202ac8 <best_fit_pmm_manager+0x288>
                prev->next = curr->next; // 完全匹配，移除当前块
ffffffffc02015fc:	00f9b423          	sd	a5,8(s3)
                cprintf("Allocated a perfect match!\n");
ffffffffc0201600:	abbfe0ef          	jal	ra,ffffffffc02000ba <cprintf>
            free_list_head = prev; // 更新空闲链表头
ffffffffc0201604:	0134b023          	sd	s3,0(s1)
            return curr; // 返回分配的内存块
ffffffffc0201608:	bfd9                	j	ffffffffc02015de <allocate_small_block+0xa6>
    assert(size < PGSIZE); // 确保请求的大小小于页面大小
ffffffffc020160a:	00001697          	auipc	a3,0x1
ffffffffc020160e:	46e68693          	addi	a3,a3,1134 # ffffffffc0202a78 <best_fit_pmm_manager+0x238>
ffffffffc0201612:	00001617          	auipc	a2,0x1
ffffffffc0201616:	eee60613          	addi	a2,a2,-274 # ffffffffc0202500 <commands+0x500>
ffffffffc020161a:	45f9                	li	a1,30
ffffffffc020161c:	00001517          	auipc	a0,0x1
ffffffffc0201620:	46c50513          	addi	a0,a0,1132 # ffffffffc0202a88 <best_fit_pmm_manager+0x248>
ffffffffc0201624:	d91fe0ef          	jal	ra,ffffffffc02003b4 <__panic>

ffffffffc0201628 <slub_init>:

void slub_init(void) {
    cprintf("slub_init() succeeded!\n");
ffffffffc0201628:	00001517          	auipc	a0,0x1
ffffffffc020162c:	4e850513          	addi	a0,a0,1256 # ffffffffc0202b10 <best_fit_pmm_manager+0x2d0>
ffffffffc0201630:	a8bfe06f          	j	ffffffffc02000ba <cprintf>

ffffffffc0201634 <slub_test>:
        length++;
    }
    return length;
}

void slub_test() {
ffffffffc0201634:	7179                	addi	sp,sp,-48
    cprintf("SLUB Test Begin\n");
ffffffffc0201636:	00001517          	auipc	a0,0x1
ffffffffc020163a:	4f250513          	addi	a0,a0,1266 # ffffffffc0202b28 <best_fit_pmm_manager+0x2e8>
void slub_test() {
ffffffffc020163e:	f022                	sd	s0,32(sp)
ffffffffc0201640:	f406                	sd	ra,40(sp)
ffffffffc0201642:	ec26                	sd	s1,24(sp)
ffffffffc0201644:	e84a                	sd	s2,16(sp)
ffffffffc0201646:	e44e                	sd	s3,8(sp)
    for (small_block_t *curr = free_list_head->next; curr != free_list_head; curr = curr->next) {
ffffffffc0201648:	00005417          	auipc	s0,0x5
ffffffffc020164c:	9c840413          	addi	s0,s0,-1592 # ffffffffc0206010 <free_list_head>
    cprintf("SLUB Test Begin\n");
ffffffffc0201650:	a6bfe0ef          	jal	ra,ffffffffc02000ba <cprintf>
    for (small_block_t *curr = free_list_head->next; curr != free_list_head; curr = curr->next) {
ffffffffc0201654:	6018                	ld	a4,0(s0)
    int length = 0;
ffffffffc0201656:	4581                	li	a1,0
    for (small_block_t *curr = free_list_head->next; curr != free_list_head; curr = curr->next) {
ffffffffc0201658:	671c                	ld	a5,8(a4)
ffffffffc020165a:	00f70663          	beq	a4,a5,ffffffffc0201666 <slub_test+0x32>
ffffffffc020165e:	679c                	ld	a5,8(a5)
        length++;
ffffffffc0201660:	2585                	addiw	a1,a1,1
    for (small_block_t *curr = free_list_head->next; curr != free_list_head; curr = curr->next) {
ffffffffc0201662:	fef71ee3          	bne	a4,a5,ffffffffc020165e <slub_test+0x2a>
    cprintf("Initial Free list length: %d\n", get_free_list_length());
ffffffffc0201666:	00001517          	auipc	a0,0x1
ffffffffc020166a:	4da50513          	addi	a0,a0,1242 # ffffffffc0202b40 <best_fit_pmm_manager+0x300>
ffffffffc020166e:	a4dfe0ef          	jal	ra,ffffffffc02000ba <cprintf>
        small_block_t *m = allocate_small_block(size + SMALL_UNIT); // 小块分配
ffffffffc0201672:	4549                	li	a0,18
ffffffffc0201674:	ec5ff0ef          	jal	ra,ffffffffc0201538 <allocate_small_block>
ffffffffc0201678:	84aa                	mv	s1,a0

    // 测试小块分配
    void *block1 = slub_alloc(2);
    cprintf("Allocated block1");
ffffffffc020167a:	00001517          	auipc	a0,0x1
ffffffffc020167e:	4e650513          	addi	a0,a0,1254 # ffffffffc0202b60 <best_fit_pmm_manager+0x320>
        return m ? (void *)(m + 1) : NULL;
ffffffffc0201682:	1a048163          	beqz	s1,ffffffffc0201824 <slub_test+0x1f0>
    cprintf("Allocated block1");
ffffffffc0201686:	a35fe0ef          	jal	ra,ffffffffc02000ba <cprintf>
    for (small_block_t *curr = free_list_head->next; curr != free_list_head; curr = curr->next) {
ffffffffc020168a:	6018                	ld	a4,0(s0)
        return m ? (void *)(m + 1) : NULL;
ffffffffc020168c:	01048913          	addi	s2,s1,16
    for (small_block_t *curr = free_list_head->next; curr != free_list_head; curr = curr->next) {
ffffffffc0201690:	671c                	ld	a5,8(a4)
ffffffffc0201692:	1af70863          	beq	a4,a5,ffffffffc0201842 <slub_test+0x20e>
    int length = 0;
ffffffffc0201696:	4581                	li	a1,0
    for (small_block_t *curr = free_list_head->next; curr != free_list_head; curr = curr->next) {
ffffffffc0201698:	679c                	ld	a5,8(a5)
        length++;
ffffffffc020169a:	2585                	addiw	a1,a1,1
    for (small_block_t *curr = free_list_head->next; curr != free_list_head; curr = curr->next) {
ffffffffc020169c:	fef71ee3          	bne	a4,a5,ffffffffc0201698 <slub_test+0x64>
    cprintf("Free list length after allocating block1: %d\n", get_free_list_length());
ffffffffc02016a0:	00001517          	auipc	a0,0x1
ffffffffc02016a4:	4d850513          	addi	a0,a0,1240 # ffffffffc0202b78 <best_fit_pmm_manager+0x338>
ffffffffc02016a8:	a13fe0ef          	jal	ra,ffffffffc02000ba <cprintf>
    if (!block) return;
ffffffffc02016ac:	00090863          	beqz	s2,ffffffffc02016bc <slub_test+0x88>
    free_small_block((small_block_t *)block - 1, 0); // 释放小块
ffffffffc02016b0:	ff090493          	addi	s1,s2,-16
ffffffffc02016b4:	4581                	li	a1,0
ffffffffc02016b6:	8526                	mv	a0,s1
ffffffffc02016b8:	dabff0ef          	jal	ra,ffffffffc0201462 <free_small_block>

    // 测试小块释放
    slub_free(block1);
    cprintf("Freed block1\n");
ffffffffc02016bc:	00001517          	auipc	a0,0x1
ffffffffc02016c0:	4ec50513          	addi	a0,a0,1260 # ffffffffc0202ba8 <best_fit_pmm_manager+0x368>
ffffffffc02016c4:	9f7fe0ef          	jal	ra,ffffffffc02000ba <cprintf>
    for (small_block_t *curr = free_list_head->next; curr != free_list_head; curr = curr->next) {
ffffffffc02016c8:	6018                	ld	a4,0(s0)
    int length = 0;
ffffffffc02016ca:	4581                	li	a1,0
    for (small_block_t *curr = free_list_head->next; curr != free_list_head; curr = curr->next) {
ffffffffc02016cc:	671c                	ld	a5,8(a4)
ffffffffc02016ce:	00f70663          	beq	a4,a5,ffffffffc02016da <slub_test+0xa6>
ffffffffc02016d2:	679c                	ld	a5,8(a5)
        length++;
ffffffffc02016d4:	2585                	addiw	a1,a1,1
    for (small_block_t *curr = free_list_head->next; curr != free_list_head; curr = curr->next) {
ffffffffc02016d6:	fef71ee3          	bne	a4,a5,ffffffffc02016d2 <slub_test+0x9e>
    cprintf("Free list length after freeing block1: %d\n", get_free_list_length());
ffffffffc02016da:	00001517          	auipc	a0,0x1
ffffffffc02016de:	4de50513          	addi	a0,a0,1246 # ffffffffc0202bb8 <best_fit_pmm_manager+0x378>
ffffffffc02016e2:	9d9fe0ef          	jal	ra,ffffffffc02000ba <cprintf>
        small_block_t *m = allocate_small_block(size + SMALL_UNIT); // 小块分配
ffffffffc02016e6:	4549                	li	a0,18
ffffffffc02016e8:	e51ff0ef          	jal	ra,ffffffffc0201538 <allocate_small_block>
ffffffffc02016ec:	84aa                	mv	s1,a0
        return m ? (void *)(m + 1) : NULL;
ffffffffc02016ee:	c119                	beqz	a0,ffffffffc02016f4 <slub_test+0xc0>
ffffffffc02016f0:	01050493          	addi	s1,a0,16

    // 测试释放后合并
    void *block2 = slub_alloc(2);
    cprintf("Allocated block2");
ffffffffc02016f4:	00001517          	auipc	a0,0x1
ffffffffc02016f8:	4f450513          	addi	a0,a0,1268 # ffffffffc0202be8 <best_fit_pmm_manager+0x3a8>
ffffffffc02016fc:	9bffe0ef          	jal	ra,ffffffffc02000ba <cprintf>
    for (small_block_t *curr = free_list_head->next; curr != free_list_head; curr = curr->next) {
ffffffffc0201700:	6018                	ld	a4,0(s0)
    int length = 0;
ffffffffc0201702:	4581                	li	a1,0
    for (small_block_t *curr = free_list_head->next; curr != free_list_head; curr = curr->next) {
ffffffffc0201704:	671c                	ld	a5,8(a4)
ffffffffc0201706:	00f70663          	beq	a4,a5,ffffffffc0201712 <slub_test+0xde>
ffffffffc020170a:	679c                	ld	a5,8(a5)
        length++;
ffffffffc020170c:	2585                	addiw	a1,a1,1
    for (small_block_t *curr = free_list_head->next; curr != free_list_head; curr = curr->next) {
ffffffffc020170e:	fef71ee3          	bne	a4,a5,ffffffffc020170a <slub_test+0xd6>
    cprintf("Free list length after allocating block2: %d\n", get_free_list_length());
ffffffffc0201712:	00001517          	auipc	a0,0x1
ffffffffc0201716:	4ee50513          	addi	a0,a0,1262 # ffffffffc0202c00 <best_fit_pmm_manager+0x3c0>
ffffffffc020171a:	9a1fe0ef          	jal	ra,ffffffffc02000ba <cprintf>
        small_block_t *m = allocate_small_block(size + SMALL_UNIT); // 小块分配
ffffffffc020171e:	4549                	li	a0,18
ffffffffc0201720:	e19ff0ef          	jal	ra,ffffffffc0201538 <allocate_small_block>
ffffffffc0201724:	89aa                	mv	s3,a0
        return m ? (void *)(m + 1) : NULL;
ffffffffc0201726:	c119                	beqz	a0,ffffffffc020172c <slub_test+0xf8>
ffffffffc0201728:	01050993          	addi	s3,a0,16
    void *block3 = slub_alloc(2);
    cprintf("Allocated block3");
ffffffffc020172c:	00001517          	auipc	a0,0x1
ffffffffc0201730:	50450513          	addi	a0,a0,1284 # ffffffffc0202c30 <best_fit_pmm_manager+0x3f0>
ffffffffc0201734:	987fe0ef          	jal	ra,ffffffffc02000ba <cprintf>
    for (small_block_t *curr = free_list_head->next; curr != free_list_head; curr = curr->next) {
ffffffffc0201738:	6018                	ld	a4,0(s0)
    int length = 0;
ffffffffc020173a:	4581                	li	a1,0
    for (small_block_t *curr = free_list_head->next; curr != free_list_head; curr = curr->next) {
ffffffffc020173c:	671c                	ld	a5,8(a4)
ffffffffc020173e:	00f70663          	beq	a4,a5,ffffffffc020174a <slub_test+0x116>
ffffffffc0201742:	679c                	ld	a5,8(a5)
        length++;
ffffffffc0201744:	2585                	addiw	a1,a1,1
    for (small_block_t *curr = free_list_head->next; curr != free_list_head; curr = curr->next) {
ffffffffc0201746:	fef71ee3          	bne	a4,a5,ffffffffc0201742 <slub_test+0x10e>
    cprintf("Free list length after allocating block3: %d\n", get_free_list_length());
ffffffffc020174a:	00001517          	auipc	a0,0x1
ffffffffc020174e:	4fe50513          	addi	a0,a0,1278 # ffffffffc0202c48 <best_fit_pmm_manager+0x408>
ffffffffc0201752:	969fe0ef          	jal	ra,ffffffffc02000ba <cprintf>
        small_block_t *m = allocate_small_block(size + SMALL_UNIT); // 小块分配
ffffffffc0201756:	11000513          	li	a0,272
ffffffffc020175a:	ddfff0ef          	jal	ra,ffffffffc0201538 <allocate_small_block>
ffffffffc020175e:	892a                	mv	s2,a0
        return m ? (void *)(m + 1) : NULL;
ffffffffc0201760:	c119                	beqz	a0,ffffffffc0201766 <slub_test+0x132>
ffffffffc0201762:	01050913          	addi	s2,a0,16
    void *block4 = slub_alloc(256);
    cprintf("Allocated block4");
ffffffffc0201766:	00001517          	auipc	a0,0x1
ffffffffc020176a:	51250513          	addi	a0,a0,1298 # ffffffffc0202c78 <best_fit_pmm_manager+0x438>
ffffffffc020176e:	94dfe0ef          	jal	ra,ffffffffc02000ba <cprintf>
    for (small_block_t *curr = free_list_head->next; curr != free_list_head; curr = curr->next) {
ffffffffc0201772:	6018                	ld	a4,0(s0)
    int length = 0;
ffffffffc0201774:	4581                	li	a1,0
    for (small_block_t *curr = free_list_head->next; curr != free_list_head; curr = curr->next) {
ffffffffc0201776:	671c                	ld	a5,8(a4)
ffffffffc0201778:	00f70663          	beq	a4,a5,ffffffffc0201784 <slub_test+0x150>
ffffffffc020177c:	679c                	ld	a5,8(a5)
        length++;
ffffffffc020177e:	2585                	addiw	a1,a1,1
    for (small_block_t *curr = free_list_head->next; curr != free_list_head; curr = curr->next) {
ffffffffc0201780:	fef71ee3          	bne	a4,a5,ffffffffc020177c <slub_test+0x148>
    cprintf("Free list length after allocating block4: %d\n", get_free_list_length());
ffffffffc0201784:	00001517          	auipc	a0,0x1
ffffffffc0201788:	50c50513          	addi	a0,a0,1292 # ffffffffc0202c90 <best_fit_pmm_manager+0x450>
ffffffffc020178c:	92ffe0ef          	jal	ra,ffffffffc02000ba <cprintf>
    if (!block) return;
ffffffffc0201790:	00098763          	beqz	s3,ffffffffc020179e <slub_test+0x16a>
    free_small_block((small_block_t *)block - 1, 0); // 释放小块
ffffffffc0201794:	4581                	li	a1,0
ffffffffc0201796:	ff098513          	addi	a0,s3,-16
ffffffffc020179a:	cc9ff0ef          	jal	ra,ffffffffc0201462 <free_small_block>
    
    
    slub_free(block3);
    cprintf("Freed block3\n");
ffffffffc020179e:	00001517          	auipc	a0,0x1
ffffffffc02017a2:	52250513          	addi	a0,a0,1314 # ffffffffc0202cc0 <best_fit_pmm_manager+0x480>
ffffffffc02017a6:	915fe0ef          	jal	ra,ffffffffc02000ba <cprintf>
    for (small_block_t *curr = free_list_head->next; curr != free_list_head; curr = curr->next) {
ffffffffc02017aa:	6018                	ld	a4,0(s0)
    int length = 0;
ffffffffc02017ac:	4581                	li	a1,0
    for (small_block_t *curr = free_list_head->next; curr != free_list_head; curr = curr->next) {
ffffffffc02017ae:	671c                	ld	a5,8(a4)
ffffffffc02017b0:	00f70663          	beq	a4,a5,ffffffffc02017bc <slub_test+0x188>
ffffffffc02017b4:	679c                	ld	a5,8(a5)
        length++;
ffffffffc02017b6:	2585                	addiw	a1,a1,1
    for (small_block_t *curr = free_list_head->next; curr != free_list_head; curr = curr->next) {
ffffffffc02017b8:	fef71ee3          	bne	a4,a5,ffffffffc02017b4 <slub_test+0x180>
    cprintf("Free list length after freeing block3: %d\n", get_free_list_length());
ffffffffc02017bc:	00001517          	auipc	a0,0x1
ffffffffc02017c0:	51450513          	addi	a0,a0,1300 # ffffffffc0202cd0 <best_fit_pmm_manager+0x490>
ffffffffc02017c4:	8f7fe0ef          	jal	ra,ffffffffc02000ba <cprintf>
    if (!block) return;
ffffffffc02017c8:	c491                	beqz	s1,ffffffffc02017d4 <slub_test+0x1a0>
    free_small_block((small_block_t *)block - 1, 0); // 释放小块
ffffffffc02017ca:	4581                	li	a1,0
ffffffffc02017cc:	ff048513          	addi	a0,s1,-16
ffffffffc02017d0:	c93ff0ef          	jal	ra,ffffffffc0201462 <free_small_block>
    if (!block) return;
ffffffffc02017d4:	00090763          	beqz	s2,ffffffffc02017e2 <slub_test+0x1ae>
    free_small_block((small_block_t *)block - 1, 0); // 释放小块
ffffffffc02017d8:	4581                	li	a1,0
ffffffffc02017da:	ff090513          	addi	a0,s2,-16
ffffffffc02017de:	c85ff0ef          	jal	ra,ffffffffc0201462 <free_small_block>
    slub_free(block2);
    slub_free(block4);
    cprintf("Freed block4\n");
ffffffffc02017e2:	00001517          	auipc	a0,0x1
ffffffffc02017e6:	51e50513          	addi	a0,a0,1310 # ffffffffc0202d00 <best_fit_pmm_manager+0x4c0>
ffffffffc02017ea:	8d1fe0ef          	jal	ra,ffffffffc02000ba <cprintf>
    for (small_block_t *curr = free_list_head->next; curr != free_list_head; curr = curr->next) {
ffffffffc02017ee:	6018                	ld	a4,0(s0)
    int length = 0;
ffffffffc02017f0:	4581                	li	a1,0
    for (small_block_t *curr = free_list_head->next; curr != free_list_head; curr = curr->next) {
ffffffffc02017f2:	671c                	ld	a5,8(a4)
ffffffffc02017f4:	00e78663          	beq	a5,a4,ffffffffc0201800 <slub_test+0x1cc>
ffffffffc02017f8:	679c                	ld	a5,8(a5)
        length++;
ffffffffc02017fa:	2585                	addiw	a1,a1,1
    for (small_block_t *curr = free_list_head->next; curr != free_list_head; curr = curr->next) {
ffffffffc02017fc:	fee79ee3          	bne	a5,a4,ffffffffc02017f8 <slub_test+0x1c4>
    cprintf("Free list length after freeing block2&4: %d\n", get_free_list_length());
ffffffffc0201800:	00001517          	auipc	a0,0x1
ffffffffc0201804:	51050513          	addi	a0,a0,1296 # ffffffffc0202d10 <best_fit_pmm_manager+0x4d0>
ffffffffc0201808:	8b3fe0ef          	jal	ra,ffffffffc02000ba <cprintf>

    cprintf("SLUB Test End\n");
   
}
ffffffffc020180c:	7402                	ld	s0,32(sp)
ffffffffc020180e:	70a2                	ld	ra,40(sp)
ffffffffc0201810:	64e2                	ld	s1,24(sp)
ffffffffc0201812:	6942                	ld	s2,16(sp)
ffffffffc0201814:	69a2                	ld	s3,8(sp)
    cprintf("SLUB Test End\n");
ffffffffc0201816:	00001517          	auipc	a0,0x1
ffffffffc020181a:	52a50513          	addi	a0,a0,1322 # ffffffffc0202d40 <best_fit_pmm_manager+0x500>
}
ffffffffc020181e:	6145                	addi	sp,sp,48
    cprintf("SLUB Test End\n");
ffffffffc0201820:	89bfe06f          	j	ffffffffc02000ba <cprintf>
    cprintf("Allocated block1");
ffffffffc0201824:	897fe0ef          	jal	ra,ffffffffc02000ba <cprintf>
    for (small_block_t *curr = free_list_head->next; curr != free_list_head; curr = curr->next) {
ffffffffc0201828:	6018                	ld	a4,0(s0)
        return m ? (void *)(m + 1) : NULL;
ffffffffc020182a:	4901                	li	s2,0
    for (small_block_t *curr = free_list_head->next; curr != free_list_head; curr = curr->next) {
ffffffffc020182c:	671c                	ld	a5,8(a4)
ffffffffc020182e:	e6f714e3          	bne	a4,a5,ffffffffc0201696 <slub_test+0x62>
    cprintf("Free list length after allocating block1: %d\n", get_free_list_length());
ffffffffc0201832:	4581                	li	a1,0
ffffffffc0201834:	00001517          	auipc	a0,0x1
ffffffffc0201838:	34450513          	addi	a0,a0,836 # ffffffffc0202b78 <best_fit_pmm_manager+0x338>
ffffffffc020183c:	87ffe0ef          	jal	ra,ffffffffc02000ba <cprintf>
    if (!block) return;
ffffffffc0201840:	bdb5                	j	ffffffffc02016bc <slub_test+0x88>
    cprintf("Free list length after allocating block1: %d\n", get_free_list_length());
ffffffffc0201842:	4581                	li	a1,0
ffffffffc0201844:	00001517          	auipc	a0,0x1
ffffffffc0201848:	33450513          	addi	a0,a0,820 # ffffffffc0202b78 <best_fit_pmm_manager+0x338>
ffffffffc020184c:	86ffe0ef          	jal	ra,ffffffffc02000ba <cprintf>
    if (!block) return;
ffffffffc0201850:	b595                	j	ffffffffc02016b4 <slub_test+0x80>

ffffffffc0201852 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0201852:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201856:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc0201858:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020185c:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc020185e:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201862:	f022                	sd	s0,32(sp)
ffffffffc0201864:	ec26                	sd	s1,24(sp)
ffffffffc0201866:	e84a                	sd	s2,16(sp)
ffffffffc0201868:	f406                	sd	ra,40(sp)
ffffffffc020186a:	e44e                	sd	s3,8(sp)
ffffffffc020186c:	84aa                	mv	s1,a0
ffffffffc020186e:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0201870:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc0201874:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc0201876:	03067e63          	bgeu	a2,a6,ffffffffc02018b2 <printnum+0x60>
ffffffffc020187a:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc020187c:	00805763          	blez	s0,ffffffffc020188a <printnum+0x38>
ffffffffc0201880:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0201882:	85ca                	mv	a1,s2
ffffffffc0201884:	854e                	mv	a0,s3
ffffffffc0201886:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0201888:	fc65                	bnez	s0,ffffffffc0201880 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020188a:	1a02                	slli	s4,s4,0x20
ffffffffc020188c:	00001797          	auipc	a5,0x1
ffffffffc0201890:	4c478793          	addi	a5,a5,1220 # ffffffffc0202d50 <best_fit_pmm_manager+0x510>
ffffffffc0201894:	020a5a13          	srli	s4,s4,0x20
ffffffffc0201898:	9a3e                	add	s4,s4,a5
}
ffffffffc020189a:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020189c:	000a4503          	lbu	a0,0(s4)
}
ffffffffc02018a0:	70a2                	ld	ra,40(sp)
ffffffffc02018a2:	69a2                	ld	s3,8(sp)
ffffffffc02018a4:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02018a6:	85ca                	mv	a1,s2
ffffffffc02018a8:	87a6                	mv	a5,s1
}
ffffffffc02018aa:	6942                	ld	s2,16(sp)
ffffffffc02018ac:	64e2                	ld	s1,24(sp)
ffffffffc02018ae:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02018b0:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc02018b2:	03065633          	divu	a2,a2,a6
ffffffffc02018b6:	8722                	mv	a4,s0
ffffffffc02018b8:	f9bff0ef          	jal	ra,ffffffffc0201852 <printnum>
ffffffffc02018bc:	b7f9                	j	ffffffffc020188a <printnum+0x38>

ffffffffc02018be <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc02018be:	7119                	addi	sp,sp,-128
ffffffffc02018c0:	f4a6                	sd	s1,104(sp)
ffffffffc02018c2:	f0ca                	sd	s2,96(sp)
ffffffffc02018c4:	ecce                	sd	s3,88(sp)
ffffffffc02018c6:	e8d2                	sd	s4,80(sp)
ffffffffc02018c8:	e4d6                	sd	s5,72(sp)
ffffffffc02018ca:	e0da                	sd	s6,64(sp)
ffffffffc02018cc:	fc5e                	sd	s7,56(sp)
ffffffffc02018ce:	f06a                	sd	s10,32(sp)
ffffffffc02018d0:	fc86                	sd	ra,120(sp)
ffffffffc02018d2:	f8a2                	sd	s0,112(sp)
ffffffffc02018d4:	f862                	sd	s8,48(sp)
ffffffffc02018d6:	f466                	sd	s9,40(sp)
ffffffffc02018d8:	ec6e                	sd	s11,24(sp)
ffffffffc02018da:	892a                	mv	s2,a0
ffffffffc02018dc:	84ae                	mv	s1,a1
ffffffffc02018de:	8d32                	mv	s10,a2
ffffffffc02018e0:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02018e2:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc02018e6:	5b7d                	li	s6,-1
ffffffffc02018e8:	00001a97          	auipc	s5,0x1
ffffffffc02018ec:	49ca8a93          	addi	s5,s5,1180 # ffffffffc0202d84 <best_fit_pmm_manager+0x544>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02018f0:	00001b97          	auipc	s7,0x1
ffffffffc02018f4:	670b8b93          	addi	s7,s7,1648 # ffffffffc0202f60 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02018f8:	000d4503          	lbu	a0,0(s10)
ffffffffc02018fc:	001d0413          	addi	s0,s10,1
ffffffffc0201900:	01350a63          	beq	a0,s3,ffffffffc0201914 <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc0201904:	c121                	beqz	a0,ffffffffc0201944 <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc0201906:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201908:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc020190a:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020190c:	fff44503          	lbu	a0,-1(s0)
ffffffffc0201910:	ff351ae3          	bne	a0,s3,ffffffffc0201904 <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201914:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc0201918:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc020191c:	4c81                	li	s9,0
ffffffffc020191e:	4881                	li	a7,0
        width = precision = -1;
ffffffffc0201920:	5c7d                	li	s8,-1
ffffffffc0201922:	5dfd                	li	s11,-1
ffffffffc0201924:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc0201928:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020192a:	fdd6059b          	addiw	a1,a2,-35
ffffffffc020192e:	0ff5f593          	zext.b	a1,a1
ffffffffc0201932:	00140d13          	addi	s10,s0,1
ffffffffc0201936:	04b56263          	bltu	a0,a1,ffffffffc020197a <vprintfmt+0xbc>
ffffffffc020193a:	058a                	slli	a1,a1,0x2
ffffffffc020193c:	95d6                	add	a1,a1,s5
ffffffffc020193e:	4194                	lw	a3,0(a1)
ffffffffc0201940:	96d6                	add	a3,a3,s5
ffffffffc0201942:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0201944:	70e6                	ld	ra,120(sp)
ffffffffc0201946:	7446                	ld	s0,112(sp)
ffffffffc0201948:	74a6                	ld	s1,104(sp)
ffffffffc020194a:	7906                	ld	s2,96(sp)
ffffffffc020194c:	69e6                	ld	s3,88(sp)
ffffffffc020194e:	6a46                	ld	s4,80(sp)
ffffffffc0201950:	6aa6                	ld	s5,72(sp)
ffffffffc0201952:	6b06                	ld	s6,64(sp)
ffffffffc0201954:	7be2                	ld	s7,56(sp)
ffffffffc0201956:	7c42                	ld	s8,48(sp)
ffffffffc0201958:	7ca2                	ld	s9,40(sp)
ffffffffc020195a:	7d02                	ld	s10,32(sp)
ffffffffc020195c:	6de2                	ld	s11,24(sp)
ffffffffc020195e:	6109                	addi	sp,sp,128
ffffffffc0201960:	8082                	ret
            padc = '0';
ffffffffc0201962:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc0201964:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201968:	846a                	mv	s0,s10
ffffffffc020196a:	00140d13          	addi	s10,s0,1
ffffffffc020196e:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0201972:	0ff5f593          	zext.b	a1,a1
ffffffffc0201976:	fcb572e3          	bgeu	a0,a1,ffffffffc020193a <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc020197a:	85a6                	mv	a1,s1
ffffffffc020197c:	02500513          	li	a0,37
ffffffffc0201980:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0201982:	fff44783          	lbu	a5,-1(s0)
ffffffffc0201986:	8d22                	mv	s10,s0
ffffffffc0201988:	f73788e3          	beq	a5,s3,ffffffffc02018f8 <vprintfmt+0x3a>
ffffffffc020198c:	ffed4783          	lbu	a5,-2(s10)
ffffffffc0201990:	1d7d                	addi	s10,s10,-1
ffffffffc0201992:	ff379de3          	bne	a5,s3,ffffffffc020198c <vprintfmt+0xce>
ffffffffc0201996:	b78d                	j	ffffffffc02018f8 <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc0201998:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc020199c:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02019a0:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc02019a2:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc02019a6:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc02019aa:	02d86463          	bltu	a6,a3,ffffffffc02019d2 <vprintfmt+0x114>
                ch = *fmt;
ffffffffc02019ae:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc02019b2:	002c169b          	slliw	a3,s8,0x2
ffffffffc02019b6:	0186873b          	addw	a4,a3,s8
ffffffffc02019ba:	0017171b          	slliw	a4,a4,0x1
ffffffffc02019be:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc02019c0:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc02019c4:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc02019c6:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc02019ca:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc02019ce:	fed870e3          	bgeu	a6,a3,ffffffffc02019ae <vprintfmt+0xf0>
            if (width < 0)
ffffffffc02019d2:	f40ddce3          	bgez	s11,ffffffffc020192a <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc02019d6:	8de2                	mv	s11,s8
ffffffffc02019d8:	5c7d                	li	s8,-1
ffffffffc02019da:	bf81                	j	ffffffffc020192a <vprintfmt+0x6c>
            if (width < 0)
ffffffffc02019dc:	fffdc693          	not	a3,s11
ffffffffc02019e0:	96fd                	srai	a3,a3,0x3f
ffffffffc02019e2:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02019e6:	00144603          	lbu	a2,1(s0)
ffffffffc02019ea:	2d81                	sext.w	s11,s11
ffffffffc02019ec:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02019ee:	bf35                	j	ffffffffc020192a <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc02019f0:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02019f4:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc02019f8:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02019fa:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc02019fc:	bfd9                	j	ffffffffc02019d2 <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc02019fe:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201a00:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201a04:	01174463          	blt	a4,a7,ffffffffc0201a0c <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc0201a08:	1a088e63          	beqz	a7,ffffffffc0201bc4 <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc0201a0c:	000a3603          	ld	a2,0(s4)
ffffffffc0201a10:	46c1                	li	a3,16
ffffffffc0201a12:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0201a14:	2781                	sext.w	a5,a5
ffffffffc0201a16:	876e                	mv	a4,s11
ffffffffc0201a18:	85a6                	mv	a1,s1
ffffffffc0201a1a:	854a                	mv	a0,s2
ffffffffc0201a1c:	e37ff0ef          	jal	ra,ffffffffc0201852 <printnum>
            break;
ffffffffc0201a20:	bde1                	j	ffffffffc02018f8 <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc0201a22:	000a2503          	lw	a0,0(s4)
ffffffffc0201a26:	85a6                	mv	a1,s1
ffffffffc0201a28:	0a21                	addi	s4,s4,8
ffffffffc0201a2a:	9902                	jalr	s2
            break;
ffffffffc0201a2c:	b5f1                	j	ffffffffc02018f8 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0201a2e:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201a30:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201a34:	01174463          	blt	a4,a7,ffffffffc0201a3c <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc0201a38:	18088163          	beqz	a7,ffffffffc0201bba <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc0201a3c:	000a3603          	ld	a2,0(s4)
ffffffffc0201a40:	46a9                	li	a3,10
ffffffffc0201a42:	8a2e                	mv	s4,a1
ffffffffc0201a44:	bfc1                	j	ffffffffc0201a14 <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201a46:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc0201a4a:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201a4c:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201a4e:	bdf1                	j	ffffffffc020192a <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc0201a50:	85a6                	mv	a1,s1
ffffffffc0201a52:	02500513          	li	a0,37
ffffffffc0201a56:	9902                	jalr	s2
            break;
ffffffffc0201a58:	b545                	j	ffffffffc02018f8 <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201a5a:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc0201a5e:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201a60:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201a62:	b5e1                	j	ffffffffc020192a <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc0201a64:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201a66:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201a6a:	01174463          	blt	a4,a7,ffffffffc0201a72 <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc0201a6e:	14088163          	beqz	a7,ffffffffc0201bb0 <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc0201a72:	000a3603          	ld	a2,0(s4)
ffffffffc0201a76:	46a1                	li	a3,8
ffffffffc0201a78:	8a2e                	mv	s4,a1
ffffffffc0201a7a:	bf69                	j	ffffffffc0201a14 <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc0201a7c:	03000513          	li	a0,48
ffffffffc0201a80:	85a6                	mv	a1,s1
ffffffffc0201a82:	e03e                	sd	a5,0(sp)
ffffffffc0201a84:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0201a86:	85a6                	mv	a1,s1
ffffffffc0201a88:	07800513          	li	a0,120
ffffffffc0201a8c:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201a8e:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0201a90:	6782                	ld	a5,0(sp)
ffffffffc0201a92:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201a94:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc0201a98:	bfb5                	j	ffffffffc0201a14 <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201a9a:	000a3403          	ld	s0,0(s4)
ffffffffc0201a9e:	008a0713          	addi	a4,s4,8
ffffffffc0201aa2:	e03a                	sd	a4,0(sp)
ffffffffc0201aa4:	14040263          	beqz	s0,ffffffffc0201be8 <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc0201aa8:	0fb05763          	blez	s11,ffffffffc0201b96 <vprintfmt+0x2d8>
ffffffffc0201aac:	02d00693          	li	a3,45
ffffffffc0201ab0:	0cd79163          	bne	a5,a3,ffffffffc0201b72 <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201ab4:	00044783          	lbu	a5,0(s0)
ffffffffc0201ab8:	0007851b          	sext.w	a0,a5
ffffffffc0201abc:	cf85                	beqz	a5,ffffffffc0201af4 <vprintfmt+0x236>
ffffffffc0201abe:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201ac2:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201ac6:	000c4563          	bltz	s8,ffffffffc0201ad0 <vprintfmt+0x212>
ffffffffc0201aca:	3c7d                	addiw	s8,s8,-1
ffffffffc0201acc:	036c0263          	beq	s8,s6,ffffffffc0201af0 <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc0201ad0:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201ad2:	0e0c8e63          	beqz	s9,ffffffffc0201bce <vprintfmt+0x310>
ffffffffc0201ad6:	3781                	addiw	a5,a5,-32
ffffffffc0201ad8:	0ef47b63          	bgeu	s0,a5,ffffffffc0201bce <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc0201adc:	03f00513          	li	a0,63
ffffffffc0201ae0:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201ae2:	000a4783          	lbu	a5,0(s4)
ffffffffc0201ae6:	3dfd                	addiw	s11,s11,-1
ffffffffc0201ae8:	0a05                	addi	s4,s4,1
ffffffffc0201aea:	0007851b          	sext.w	a0,a5
ffffffffc0201aee:	ffe1                	bnez	a5,ffffffffc0201ac6 <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc0201af0:	01b05963          	blez	s11,ffffffffc0201b02 <vprintfmt+0x244>
ffffffffc0201af4:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0201af6:	85a6                	mv	a1,s1
ffffffffc0201af8:	02000513          	li	a0,32
ffffffffc0201afc:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0201afe:	fe0d9be3          	bnez	s11,ffffffffc0201af4 <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201b02:	6a02                	ld	s4,0(sp)
ffffffffc0201b04:	bbd5                	j	ffffffffc02018f8 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0201b06:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201b08:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc0201b0c:	01174463          	blt	a4,a7,ffffffffc0201b14 <vprintfmt+0x256>
    else if (lflag) {
ffffffffc0201b10:	08088d63          	beqz	a7,ffffffffc0201baa <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc0201b14:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0201b18:	0a044d63          	bltz	s0,ffffffffc0201bd2 <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc0201b1c:	8622                	mv	a2,s0
ffffffffc0201b1e:	8a66                	mv	s4,s9
ffffffffc0201b20:	46a9                	li	a3,10
ffffffffc0201b22:	bdcd                	j	ffffffffc0201a14 <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc0201b24:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201b28:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc0201b2a:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc0201b2c:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc0201b30:	8fb5                	xor	a5,a5,a3
ffffffffc0201b32:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201b36:	02d74163          	blt	a4,a3,ffffffffc0201b58 <vprintfmt+0x29a>
ffffffffc0201b3a:	00369793          	slli	a5,a3,0x3
ffffffffc0201b3e:	97de                	add	a5,a5,s7
ffffffffc0201b40:	639c                	ld	a5,0(a5)
ffffffffc0201b42:	cb99                	beqz	a5,ffffffffc0201b58 <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc0201b44:	86be                	mv	a3,a5
ffffffffc0201b46:	00001617          	auipc	a2,0x1
ffffffffc0201b4a:	23a60613          	addi	a2,a2,570 # ffffffffc0202d80 <best_fit_pmm_manager+0x540>
ffffffffc0201b4e:	85a6                	mv	a1,s1
ffffffffc0201b50:	854a                	mv	a0,s2
ffffffffc0201b52:	0ce000ef          	jal	ra,ffffffffc0201c20 <printfmt>
ffffffffc0201b56:	b34d                	j	ffffffffc02018f8 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0201b58:	00001617          	auipc	a2,0x1
ffffffffc0201b5c:	21860613          	addi	a2,a2,536 # ffffffffc0202d70 <best_fit_pmm_manager+0x530>
ffffffffc0201b60:	85a6                	mv	a1,s1
ffffffffc0201b62:	854a                	mv	a0,s2
ffffffffc0201b64:	0bc000ef          	jal	ra,ffffffffc0201c20 <printfmt>
ffffffffc0201b68:	bb41                	j	ffffffffc02018f8 <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0201b6a:	00001417          	auipc	s0,0x1
ffffffffc0201b6e:	1fe40413          	addi	s0,s0,510 # ffffffffc0202d68 <best_fit_pmm_manager+0x528>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201b72:	85e2                	mv	a1,s8
ffffffffc0201b74:	8522                	mv	a0,s0
ffffffffc0201b76:	e43e                	sd	a5,8(sp)
ffffffffc0201b78:	1cc000ef          	jal	ra,ffffffffc0201d44 <strnlen>
ffffffffc0201b7c:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0201b80:	01b05b63          	blez	s11,ffffffffc0201b96 <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc0201b84:	67a2                	ld	a5,8(sp)
ffffffffc0201b86:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201b8a:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc0201b8c:	85a6                	mv	a1,s1
ffffffffc0201b8e:	8552                	mv	a0,s4
ffffffffc0201b90:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201b92:	fe0d9ce3          	bnez	s11,ffffffffc0201b8a <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201b96:	00044783          	lbu	a5,0(s0)
ffffffffc0201b9a:	00140a13          	addi	s4,s0,1
ffffffffc0201b9e:	0007851b          	sext.w	a0,a5
ffffffffc0201ba2:	d3a5                	beqz	a5,ffffffffc0201b02 <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201ba4:	05e00413          	li	s0,94
ffffffffc0201ba8:	bf39                	j	ffffffffc0201ac6 <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc0201baa:	000a2403          	lw	s0,0(s4)
ffffffffc0201bae:	b7ad                	j	ffffffffc0201b18 <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc0201bb0:	000a6603          	lwu	a2,0(s4)
ffffffffc0201bb4:	46a1                	li	a3,8
ffffffffc0201bb6:	8a2e                	mv	s4,a1
ffffffffc0201bb8:	bdb1                	j	ffffffffc0201a14 <vprintfmt+0x156>
ffffffffc0201bba:	000a6603          	lwu	a2,0(s4)
ffffffffc0201bbe:	46a9                	li	a3,10
ffffffffc0201bc0:	8a2e                	mv	s4,a1
ffffffffc0201bc2:	bd89                	j	ffffffffc0201a14 <vprintfmt+0x156>
ffffffffc0201bc4:	000a6603          	lwu	a2,0(s4)
ffffffffc0201bc8:	46c1                	li	a3,16
ffffffffc0201bca:	8a2e                	mv	s4,a1
ffffffffc0201bcc:	b5a1                	j	ffffffffc0201a14 <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc0201bce:	9902                	jalr	s2
ffffffffc0201bd0:	bf09                	j	ffffffffc0201ae2 <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc0201bd2:	85a6                	mv	a1,s1
ffffffffc0201bd4:	02d00513          	li	a0,45
ffffffffc0201bd8:	e03e                	sd	a5,0(sp)
ffffffffc0201bda:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0201bdc:	6782                	ld	a5,0(sp)
ffffffffc0201bde:	8a66                	mv	s4,s9
ffffffffc0201be0:	40800633          	neg	a2,s0
ffffffffc0201be4:	46a9                	li	a3,10
ffffffffc0201be6:	b53d                	j	ffffffffc0201a14 <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc0201be8:	03b05163          	blez	s11,ffffffffc0201c0a <vprintfmt+0x34c>
ffffffffc0201bec:	02d00693          	li	a3,45
ffffffffc0201bf0:	f6d79de3          	bne	a5,a3,ffffffffc0201b6a <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc0201bf4:	00001417          	auipc	s0,0x1
ffffffffc0201bf8:	17440413          	addi	s0,s0,372 # ffffffffc0202d68 <best_fit_pmm_manager+0x528>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201bfc:	02800793          	li	a5,40
ffffffffc0201c00:	02800513          	li	a0,40
ffffffffc0201c04:	00140a13          	addi	s4,s0,1
ffffffffc0201c08:	bd6d                	j	ffffffffc0201ac2 <vprintfmt+0x204>
ffffffffc0201c0a:	00001a17          	auipc	s4,0x1
ffffffffc0201c0e:	15fa0a13          	addi	s4,s4,351 # ffffffffc0202d69 <best_fit_pmm_manager+0x529>
ffffffffc0201c12:	02800513          	li	a0,40
ffffffffc0201c16:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201c1a:	05e00413          	li	s0,94
ffffffffc0201c1e:	b565                	j	ffffffffc0201ac6 <vprintfmt+0x208>

ffffffffc0201c20 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201c20:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0201c22:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201c26:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201c28:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201c2a:	ec06                	sd	ra,24(sp)
ffffffffc0201c2c:	f83a                	sd	a4,48(sp)
ffffffffc0201c2e:	fc3e                	sd	a5,56(sp)
ffffffffc0201c30:	e0c2                	sd	a6,64(sp)
ffffffffc0201c32:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0201c34:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201c36:	c89ff0ef          	jal	ra,ffffffffc02018be <vprintfmt>
}
ffffffffc0201c3a:	60e2                	ld	ra,24(sp)
ffffffffc0201c3c:	6161                	addi	sp,sp,80
ffffffffc0201c3e:	8082                	ret

ffffffffc0201c40 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc0201c40:	715d                	addi	sp,sp,-80
ffffffffc0201c42:	e486                	sd	ra,72(sp)
ffffffffc0201c44:	e0a6                	sd	s1,64(sp)
ffffffffc0201c46:	fc4a                	sd	s2,56(sp)
ffffffffc0201c48:	f84e                	sd	s3,48(sp)
ffffffffc0201c4a:	f452                	sd	s4,40(sp)
ffffffffc0201c4c:	f056                	sd	s5,32(sp)
ffffffffc0201c4e:	ec5a                	sd	s6,24(sp)
ffffffffc0201c50:	e85e                	sd	s7,16(sp)
    if (prompt != NULL) {
ffffffffc0201c52:	c901                	beqz	a0,ffffffffc0201c62 <readline+0x22>
ffffffffc0201c54:	85aa                	mv	a1,a0
        cprintf("%s", prompt);
ffffffffc0201c56:	00001517          	auipc	a0,0x1
ffffffffc0201c5a:	12a50513          	addi	a0,a0,298 # ffffffffc0202d80 <best_fit_pmm_manager+0x540>
ffffffffc0201c5e:	c5cfe0ef          	jal	ra,ffffffffc02000ba <cprintf>
readline(const char *prompt) {
ffffffffc0201c62:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201c64:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc0201c66:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc0201c68:	4aa9                	li	s5,10
ffffffffc0201c6a:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc0201c6c:	00004b97          	auipc	s7,0x4
ffffffffc0201c70:	3d4b8b93          	addi	s7,s7,980 # ffffffffc0206040 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201c74:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc0201c78:	cbafe0ef          	jal	ra,ffffffffc0200132 <getchar>
        if (c < 0) {
ffffffffc0201c7c:	00054a63          	bltz	a0,ffffffffc0201c90 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201c80:	00a95a63          	bge	s2,a0,ffffffffc0201c94 <readline+0x54>
ffffffffc0201c84:	029a5263          	bge	s4,s1,ffffffffc0201ca8 <readline+0x68>
        c = getchar();
ffffffffc0201c88:	caafe0ef          	jal	ra,ffffffffc0200132 <getchar>
        if (c < 0) {
ffffffffc0201c8c:	fe055ae3          	bgez	a0,ffffffffc0201c80 <readline+0x40>
            return NULL;
ffffffffc0201c90:	4501                	li	a0,0
ffffffffc0201c92:	a091                	j	ffffffffc0201cd6 <readline+0x96>
        else if (c == '\b' && i > 0) {
ffffffffc0201c94:	03351463          	bne	a0,s3,ffffffffc0201cbc <readline+0x7c>
ffffffffc0201c98:	e8a9                	bnez	s1,ffffffffc0201cea <readline+0xaa>
        c = getchar();
ffffffffc0201c9a:	c98fe0ef          	jal	ra,ffffffffc0200132 <getchar>
        if (c < 0) {
ffffffffc0201c9e:	fe0549e3          	bltz	a0,ffffffffc0201c90 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201ca2:	fea959e3          	bge	s2,a0,ffffffffc0201c94 <readline+0x54>
ffffffffc0201ca6:	4481                	li	s1,0
            cputchar(c);
ffffffffc0201ca8:	e42a                	sd	a0,8(sp)
ffffffffc0201caa:	c46fe0ef          	jal	ra,ffffffffc02000f0 <cputchar>
            buf[i ++] = c;
ffffffffc0201cae:	6522                	ld	a0,8(sp)
ffffffffc0201cb0:	009b87b3          	add	a5,s7,s1
ffffffffc0201cb4:	2485                	addiw	s1,s1,1
ffffffffc0201cb6:	00a78023          	sb	a0,0(a5)
ffffffffc0201cba:	bf7d                	j	ffffffffc0201c78 <readline+0x38>
        else if (c == '\n' || c == '\r') {
ffffffffc0201cbc:	01550463          	beq	a0,s5,ffffffffc0201cc4 <readline+0x84>
ffffffffc0201cc0:	fb651ce3          	bne	a0,s6,ffffffffc0201c78 <readline+0x38>
            cputchar(c);
ffffffffc0201cc4:	c2cfe0ef          	jal	ra,ffffffffc02000f0 <cputchar>
            buf[i] = '\0';
ffffffffc0201cc8:	00004517          	auipc	a0,0x4
ffffffffc0201ccc:	37850513          	addi	a0,a0,888 # ffffffffc0206040 <buf>
ffffffffc0201cd0:	94aa                	add	s1,s1,a0
ffffffffc0201cd2:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc0201cd6:	60a6                	ld	ra,72(sp)
ffffffffc0201cd8:	6486                	ld	s1,64(sp)
ffffffffc0201cda:	7962                	ld	s2,56(sp)
ffffffffc0201cdc:	79c2                	ld	s3,48(sp)
ffffffffc0201cde:	7a22                	ld	s4,40(sp)
ffffffffc0201ce0:	7a82                	ld	s5,32(sp)
ffffffffc0201ce2:	6b62                	ld	s6,24(sp)
ffffffffc0201ce4:	6bc2                	ld	s7,16(sp)
ffffffffc0201ce6:	6161                	addi	sp,sp,80
ffffffffc0201ce8:	8082                	ret
            cputchar(c);
ffffffffc0201cea:	4521                	li	a0,8
ffffffffc0201cec:	c04fe0ef          	jal	ra,ffffffffc02000f0 <cputchar>
            i --;
ffffffffc0201cf0:	34fd                	addiw	s1,s1,-1
ffffffffc0201cf2:	b759                	j	ffffffffc0201c78 <readline+0x38>

ffffffffc0201cf4 <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
ffffffffc0201cf4:	4781                	li	a5,0
ffffffffc0201cf6:	00004717          	auipc	a4,0x4
ffffffffc0201cfa:	32a73703          	ld	a4,810(a4) # ffffffffc0206020 <SBI_CONSOLE_PUTCHAR>
ffffffffc0201cfe:	88ba                	mv	a7,a4
ffffffffc0201d00:	852a                	mv	a0,a0
ffffffffc0201d02:	85be                	mv	a1,a5
ffffffffc0201d04:	863e                	mv	a2,a5
ffffffffc0201d06:	00000073          	ecall
ffffffffc0201d0a:	87aa                	mv	a5,a0
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc0201d0c:	8082                	ret

ffffffffc0201d0e <sbi_set_timer>:
    __asm__ volatile (
ffffffffc0201d0e:	4781                	li	a5,0
ffffffffc0201d10:	00004717          	auipc	a4,0x4
ffffffffc0201d14:	77073703          	ld	a4,1904(a4) # ffffffffc0206480 <SBI_SET_TIMER>
ffffffffc0201d18:	88ba                	mv	a7,a4
ffffffffc0201d1a:	852a                	mv	a0,a0
ffffffffc0201d1c:	85be                	mv	a1,a5
ffffffffc0201d1e:	863e                	mv	a2,a5
ffffffffc0201d20:	00000073          	ecall
ffffffffc0201d24:	87aa                	mv	a5,a0

void sbi_set_timer(unsigned long long stime_value) {
    sbi_call(SBI_SET_TIMER, stime_value, 0, 0);
}
ffffffffc0201d26:	8082                	ret

ffffffffc0201d28 <sbi_console_getchar>:
    __asm__ volatile (
ffffffffc0201d28:	4501                	li	a0,0
ffffffffc0201d2a:	00004797          	auipc	a5,0x4
ffffffffc0201d2e:	2ee7b783          	ld	a5,750(a5) # ffffffffc0206018 <SBI_CONSOLE_GETCHAR>
ffffffffc0201d32:	88be                	mv	a7,a5
ffffffffc0201d34:	852a                	mv	a0,a0
ffffffffc0201d36:	85aa                	mv	a1,a0
ffffffffc0201d38:	862a                	mv	a2,a0
ffffffffc0201d3a:	00000073          	ecall
ffffffffc0201d3e:	852a                	mv	a0,a0

int sbi_console_getchar(void) {
    return sbi_call(SBI_CONSOLE_GETCHAR, 0, 0, 0);
ffffffffc0201d40:	2501                	sext.w	a0,a0
ffffffffc0201d42:	8082                	ret

ffffffffc0201d44 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0201d44:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201d46:	e589                	bnez	a1,ffffffffc0201d50 <strnlen+0xc>
ffffffffc0201d48:	a811                	j	ffffffffc0201d5c <strnlen+0x18>
        cnt ++;
ffffffffc0201d4a:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201d4c:	00f58863          	beq	a1,a5,ffffffffc0201d5c <strnlen+0x18>
ffffffffc0201d50:	00f50733          	add	a4,a0,a5
ffffffffc0201d54:	00074703          	lbu	a4,0(a4)
ffffffffc0201d58:	fb6d                	bnez	a4,ffffffffc0201d4a <strnlen+0x6>
ffffffffc0201d5a:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0201d5c:	852e                	mv	a0,a1
ffffffffc0201d5e:	8082                	ret

ffffffffc0201d60 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201d60:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201d64:	0005c703          	lbu	a4,0(a1) # 1000 <kern_entry-0xffffffffc01ff000>
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201d68:	cb89                	beqz	a5,ffffffffc0201d7a <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc0201d6a:	0505                	addi	a0,a0,1
ffffffffc0201d6c:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201d6e:	fee789e3          	beq	a5,a4,ffffffffc0201d60 <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201d72:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0201d76:	9d19                	subw	a0,a0,a4
ffffffffc0201d78:	8082                	ret
ffffffffc0201d7a:	4501                	li	a0,0
ffffffffc0201d7c:	bfed                	j	ffffffffc0201d76 <strcmp+0x16>

ffffffffc0201d7e <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0201d7e:	00054783          	lbu	a5,0(a0)
ffffffffc0201d82:	c799                	beqz	a5,ffffffffc0201d90 <strchr+0x12>
        if (*s == c) {
ffffffffc0201d84:	00f58763          	beq	a1,a5,ffffffffc0201d92 <strchr+0x14>
    while (*s != '\0') {
ffffffffc0201d88:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc0201d8c:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0201d8e:	fbfd                	bnez	a5,ffffffffc0201d84 <strchr+0x6>
    }
    return NULL;
ffffffffc0201d90:	4501                	li	a0,0
}
ffffffffc0201d92:	8082                	ret

ffffffffc0201d94 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0201d94:	ca01                	beqz	a2,ffffffffc0201da4 <memset+0x10>
ffffffffc0201d96:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0201d98:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0201d9a:	0785                	addi	a5,a5,1
ffffffffc0201d9c:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0201da0:	fec79de3          	bne	a5,a2,ffffffffc0201d9a <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0201da4:	8082                	ret
