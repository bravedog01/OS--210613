
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
ffffffffc0200036:	fde50513          	addi	a0,a0,-34 # ffffffffc0206010 <buddy>
ffffffffc020003a:	00006617          	auipc	a2,0x6
ffffffffc020003e:	57660613          	addi	a2,a2,1398 # ffffffffc02065b0 <end>
int kern_init(void) {
ffffffffc0200042:	1141                	addi	sp,sp,-16 # ffffffffc0204ff0 <bootstack+0x1ff0>
    memset(edata, 0, end - edata);
ffffffffc0200044:	8e09                	sub	a2,a2,a0
ffffffffc0200046:	4581                	li	a1,0
int kern_init(void) {
ffffffffc0200048:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc020004a:	694010ef          	jal	ffffffffc02016de <memset>
    cons_init();  // init the console
ffffffffc020004e:	3f8000ef          	jal	ffffffffc0200446 <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc0200052:	00001517          	auipc	a0,0x1
ffffffffc0200056:	69e50513          	addi	a0,a0,1694 # ffffffffc02016f0 <etext>
ffffffffc020005a:	08e000ef          	jal	ffffffffc02000e8 <cputs>

    print_kerninfo();
ffffffffc020005e:	0e8000ef          	jal	ffffffffc0200146 <print_kerninfo>

    // grade_backtrace();
    idt_init();  // init interrupt descriptor table
ffffffffc0200062:	3fe000ef          	jal	ffffffffc0200460 <idt_init>

    pmm_init();  // init physical memory management
ffffffffc0200066:	77f000ef          	jal	ffffffffc0200fe4 <pmm_init>

    idt_init();  // init interrupt descriptor table
ffffffffc020006a:	3f6000ef          	jal	ffffffffc0200460 <idt_init>

    clock_init();   // init clock interrupt
ffffffffc020006e:	396000ef          	jal	ffffffffc0200404 <clock_init>
    intr_enable();  // enable irq interrupt
ffffffffc0200072:	3e2000ef          	jal	ffffffffc0200454 <intr_enable>



    /* do nothing */
    while (1)
ffffffffc0200076:	a001                	j	ffffffffc0200076 <kern_init+0x44>

ffffffffc0200078 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc0200078:	1141                	addi	sp,sp,-16
ffffffffc020007a:	e022                	sd	s0,0(sp)
ffffffffc020007c:	e406                	sd	ra,8(sp)
ffffffffc020007e:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc0200080:	3c8000ef          	jal	ffffffffc0200448 <cons_putc>
    (*cnt) ++;
ffffffffc0200084:	401c                	lw	a5,0(s0)
}
ffffffffc0200086:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc0200088:	2785                	addiw	a5,a5,1
ffffffffc020008a:	c01c                	sw	a5,0(s0)
}
ffffffffc020008c:	6402                	ld	s0,0(sp)
ffffffffc020008e:	0141                	addi	sp,sp,16
ffffffffc0200090:	8082                	ret

ffffffffc0200092 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc0200092:	1101                	addi	sp,sp,-32
ffffffffc0200094:	862a                	mv	a2,a0
ffffffffc0200096:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200098:	00000517          	auipc	a0,0x0
ffffffffc020009c:	fe050513          	addi	a0,a0,-32 # ffffffffc0200078 <cputch>
ffffffffc02000a0:	006c                	addi	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
ffffffffc02000a2:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc02000a4:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000a6:	150010ef          	jal	ffffffffc02011f6 <vprintfmt>
    return cnt;
}
ffffffffc02000aa:	60e2                	ld	ra,24(sp)
ffffffffc02000ac:	4532                	lw	a0,12(sp)
ffffffffc02000ae:	6105                	addi	sp,sp,32
ffffffffc02000b0:	8082                	ret

ffffffffc02000b2 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc02000b2:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc02000b4:	02810313          	addi	t1,sp,40
cprintf(const char *fmt, ...) {
ffffffffc02000b8:	f42e                	sd	a1,40(sp)
ffffffffc02000ba:	f832                	sd	a2,48(sp)
ffffffffc02000bc:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000be:	862a                	mv	a2,a0
ffffffffc02000c0:	004c                	addi	a1,sp,4
ffffffffc02000c2:	00000517          	auipc	a0,0x0
ffffffffc02000c6:	fb650513          	addi	a0,a0,-74 # ffffffffc0200078 <cputch>
ffffffffc02000ca:	869a                	mv	a3,t1
cprintf(const char *fmt, ...) {
ffffffffc02000cc:	ec06                	sd	ra,24(sp)
ffffffffc02000ce:	e0ba                	sd	a4,64(sp)
ffffffffc02000d0:	e4be                	sd	a5,72(sp)
ffffffffc02000d2:	e8c2                	sd	a6,80(sp)
ffffffffc02000d4:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc02000d6:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc02000d8:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000da:	11c010ef          	jal	ffffffffc02011f6 <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc02000de:	60e2                	ld	ra,24(sp)
ffffffffc02000e0:	4512                	lw	a0,4(sp)
ffffffffc02000e2:	6125                	addi	sp,sp,96
ffffffffc02000e4:	8082                	ret

ffffffffc02000e6 <cputchar>:

/* cputchar - writes a single character to stdout */
void
cputchar(int c) {
    cons_putc(c);
ffffffffc02000e6:	a68d                	j	ffffffffc0200448 <cons_putc>

ffffffffc02000e8 <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc02000e8:	1101                	addi	sp,sp,-32
ffffffffc02000ea:	ec06                	sd	ra,24(sp)
ffffffffc02000ec:	e822                	sd	s0,16(sp)
ffffffffc02000ee:	87aa                	mv	a5,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc02000f0:	00054503          	lbu	a0,0(a0)
ffffffffc02000f4:	c905                	beqz	a0,ffffffffc0200124 <cputs+0x3c>
ffffffffc02000f6:	e426                	sd	s1,8(sp)
ffffffffc02000f8:	00178493          	addi	s1,a5,1
ffffffffc02000fc:	8426                	mv	s0,s1
    cons_putc(c);
ffffffffc02000fe:	34a000ef          	jal	ffffffffc0200448 <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc0200102:	00044503          	lbu	a0,0(s0)
ffffffffc0200106:	87a2                	mv	a5,s0
ffffffffc0200108:	0405                	addi	s0,s0,1
ffffffffc020010a:	f975                	bnez	a0,ffffffffc02000fe <cputs+0x16>
    (*cnt) ++;
ffffffffc020010c:	9f85                	subw	a5,a5,s1
    cons_putc(c);
ffffffffc020010e:	4529                	li	a0,10
    (*cnt) ++;
ffffffffc0200110:	0027841b          	addiw	s0,a5,2
ffffffffc0200114:	64a2                	ld	s1,8(sp)
    cons_putc(c);
ffffffffc0200116:	332000ef          	jal	ffffffffc0200448 <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc020011a:	60e2                	ld	ra,24(sp)
ffffffffc020011c:	8522                	mv	a0,s0
ffffffffc020011e:	6442                	ld	s0,16(sp)
ffffffffc0200120:	6105                	addi	sp,sp,32
ffffffffc0200122:	8082                	ret
    cons_putc(c);
ffffffffc0200124:	4529                	li	a0,10
ffffffffc0200126:	322000ef          	jal	ffffffffc0200448 <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc020012a:	4405                	li	s0,1
}
ffffffffc020012c:	60e2                	ld	ra,24(sp)
ffffffffc020012e:	8522                	mv	a0,s0
ffffffffc0200130:	6442                	ld	s0,16(sp)
ffffffffc0200132:	6105                	addi	sp,sp,32
ffffffffc0200134:	8082                	ret

ffffffffc0200136 <getchar>:

/* getchar - reads a single non-zero character from stdin */
int
getchar(void) {
ffffffffc0200136:	1141                	addi	sp,sp,-16
ffffffffc0200138:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc020013a:	316000ef          	jal	ffffffffc0200450 <cons_getc>
ffffffffc020013e:	dd75                	beqz	a0,ffffffffc020013a <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc0200140:	60a2                	ld	ra,8(sp)
ffffffffc0200142:	0141                	addi	sp,sp,16
ffffffffc0200144:	8082                	ret

ffffffffc0200146 <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc0200146:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc0200148:	00001517          	auipc	a0,0x1
ffffffffc020014c:	5c850513          	addi	a0,a0,1480 # ffffffffc0201710 <etext+0x20>
void print_kerninfo(void) {
ffffffffc0200150:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200152:	f61ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", kern_init);
ffffffffc0200156:	00000597          	auipc	a1,0x0
ffffffffc020015a:	edc58593          	addi	a1,a1,-292 # ffffffffc0200032 <kern_init>
ffffffffc020015e:	00001517          	auipc	a0,0x1
ffffffffc0200162:	5d250513          	addi	a0,a0,1490 # ffffffffc0201730 <etext+0x40>
ffffffffc0200166:	f4dff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc020016a:	00001597          	auipc	a1,0x1
ffffffffc020016e:	58658593          	addi	a1,a1,1414 # ffffffffc02016f0 <etext>
ffffffffc0200172:	00001517          	auipc	a0,0x1
ffffffffc0200176:	5de50513          	addi	a0,a0,1502 # ffffffffc0201750 <etext+0x60>
ffffffffc020017a:	f39ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc020017e:	00006597          	auipc	a1,0x6
ffffffffc0200182:	e9258593          	addi	a1,a1,-366 # ffffffffc0206010 <buddy>
ffffffffc0200186:	00001517          	auipc	a0,0x1
ffffffffc020018a:	5ea50513          	addi	a0,a0,1514 # ffffffffc0201770 <etext+0x80>
ffffffffc020018e:	f25ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc0200192:	00006597          	auipc	a1,0x6
ffffffffc0200196:	41e58593          	addi	a1,a1,1054 # ffffffffc02065b0 <end>
ffffffffc020019a:	00001517          	auipc	a0,0x1
ffffffffc020019e:	5f650513          	addi	a0,a0,1526 # ffffffffc0201790 <etext+0xa0>
ffffffffc02001a2:	f11ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc02001a6:	00007797          	auipc	a5,0x7
ffffffffc02001aa:	80978793          	addi	a5,a5,-2039 # ffffffffc02069af <end+0x3ff>
ffffffffc02001ae:	00000717          	auipc	a4,0x0
ffffffffc02001b2:	e8470713          	addi	a4,a4,-380 # ffffffffc0200032 <kern_init>
ffffffffc02001b6:	8f99                	sub	a5,a5,a4
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001b8:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc02001bc:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001be:	3ff5f593          	andi	a1,a1,1023
ffffffffc02001c2:	95be                	add	a1,a1,a5
ffffffffc02001c4:	85a9                	srai	a1,a1,0xa
ffffffffc02001c6:	00001517          	auipc	a0,0x1
ffffffffc02001ca:	5ea50513          	addi	a0,a0,1514 # ffffffffc02017b0 <etext+0xc0>
}
ffffffffc02001ce:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001d0:	b5cd                	j	ffffffffc02000b2 <cprintf>

ffffffffc02001d2 <print_stackframe>:
 * Note that, the length of ebp-chain is limited. In boot/bootasm.S, before
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void) {
ffffffffc02001d2:	1141                	addi	sp,sp,-16

    panic("Not Implemented!");
ffffffffc02001d4:	00001617          	auipc	a2,0x1
ffffffffc02001d8:	60c60613          	addi	a2,a2,1548 # ffffffffc02017e0 <etext+0xf0>
ffffffffc02001dc:	04e00593          	li	a1,78
ffffffffc02001e0:	00001517          	auipc	a0,0x1
ffffffffc02001e4:	61850513          	addi	a0,a0,1560 # ffffffffc02017f8 <etext+0x108>
void print_stackframe(void) {
ffffffffc02001e8:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc02001ea:	1bc000ef          	jal	ffffffffc02003a6 <__panic>

ffffffffc02001ee <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc02001ee:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02001f0:	00001617          	auipc	a2,0x1
ffffffffc02001f4:	62060613          	addi	a2,a2,1568 # ffffffffc0201810 <etext+0x120>
ffffffffc02001f8:	00001597          	auipc	a1,0x1
ffffffffc02001fc:	63858593          	addi	a1,a1,1592 # ffffffffc0201830 <etext+0x140>
ffffffffc0200200:	00001517          	auipc	a0,0x1
ffffffffc0200204:	63850513          	addi	a0,a0,1592 # ffffffffc0201838 <etext+0x148>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200208:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc020020a:	ea9ff0ef          	jal	ffffffffc02000b2 <cprintf>
ffffffffc020020e:	00001617          	auipc	a2,0x1
ffffffffc0200212:	63a60613          	addi	a2,a2,1594 # ffffffffc0201848 <etext+0x158>
ffffffffc0200216:	00001597          	auipc	a1,0x1
ffffffffc020021a:	65a58593          	addi	a1,a1,1626 # ffffffffc0201870 <etext+0x180>
ffffffffc020021e:	00001517          	auipc	a0,0x1
ffffffffc0200222:	61a50513          	addi	a0,a0,1562 # ffffffffc0201838 <etext+0x148>
ffffffffc0200226:	e8dff0ef          	jal	ffffffffc02000b2 <cprintf>
ffffffffc020022a:	00001617          	auipc	a2,0x1
ffffffffc020022e:	65660613          	addi	a2,a2,1622 # ffffffffc0201880 <etext+0x190>
ffffffffc0200232:	00001597          	auipc	a1,0x1
ffffffffc0200236:	66e58593          	addi	a1,a1,1646 # ffffffffc02018a0 <etext+0x1b0>
ffffffffc020023a:	00001517          	auipc	a0,0x1
ffffffffc020023e:	5fe50513          	addi	a0,a0,1534 # ffffffffc0201838 <etext+0x148>
ffffffffc0200242:	e71ff0ef          	jal	ffffffffc02000b2 <cprintf>
    }
    return 0;
}
ffffffffc0200246:	60a2                	ld	ra,8(sp)
ffffffffc0200248:	4501                	li	a0,0
ffffffffc020024a:	0141                	addi	sp,sp,16
ffffffffc020024c:	8082                	ret

ffffffffc020024e <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc020024e:	1141                	addi	sp,sp,-16
ffffffffc0200250:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc0200252:	ef5ff0ef          	jal	ffffffffc0200146 <print_kerninfo>
    return 0;
}
ffffffffc0200256:	60a2                	ld	ra,8(sp)
ffffffffc0200258:	4501                	li	a0,0
ffffffffc020025a:	0141                	addi	sp,sp,16
ffffffffc020025c:	8082                	ret

ffffffffc020025e <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc020025e:	1141                	addi	sp,sp,-16
ffffffffc0200260:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc0200262:	f71ff0ef          	jal	ffffffffc02001d2 <print_stackframe>
    return 0;
}
ffffffffc0200266:	60a2                	ld	ra,8(sp)
ffffffffc0200268:	4501                	li	a0,0
ffffffffc020026a:	0141                	addi	sp,sp,16
ffffffffc020026c:	8082                	ret

ffffffffc020026e <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc020026e:	7115                	addi	sp,sp,-224
ffffffffc0200270:	f15a                	sd	s6,160(sp)
ffffffffc0200272:	8b2a                	mv	s6,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200274:	00001517          	auipc	a0,0x1
ffffffffc0200278:	63c50513          	addi	a0,a0,1596 # ffffffffc02018b0 <etext+0x1c0>
kmonitor(struct trapframe *tf) {
ffffffffc020027c:	ed86                	sd	ra,216(sp)
ffffffffc020027e:	e9a2                	sd	s0,208(sp)
ffffffffc0200280:	e5a6                	sd	s1,200(sp)
ffffffffc0200282:	e1ca                	sd	s2,192(sp)
ffffffffc0200284:	fd4e                	sd	s3,184(sp)
ffffffffc0200286:	f952                	sd	s4,176(sp)
ffffffffc0200288:	f556                	sd	s5,168(sp)
ffffffffc020028a:	ed5e                	sd	s7,152(sp)
ffffffffc020028c:	e962                	sd	s8,144(sp)
ffffffffc020028e:	e566                	sd	s9,136(sp)
ffffffffc0200290:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200292:	e21ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc0200296:	00001517          	auipc	a0,0x1
ffffffffc020029a:	64250513          	addi	a0,a0,1602 # ffffffffc02018d8 <etext+0x1e8>
ffffffffc020029e:	e15ff0ef          	jal	ffffffffc02000b2 <cprintf>
    if (tf != NULL) {
ffffffffc02002a2:	000b0563          	beqz	s6,ffffffffc02002ac <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc02002a6:	855a                	mv	a0,s6
ffffffffc02002a8:	396000ef          	jal	ffffffffc020063e <print_trapframe>
ffffffffc02002ac:	00002c17          	auipc	s8,0x2
ffffffffc02002b0:	074c0c13          	addi	s8,s8,116 # ffffffffc0202320 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02002b4:	00001917          	auipc	s2,0x1
ffffffffc02002b8:	64c90913          	addi	s2,s2,1612 # ffffffffc0201900 <etext+0x210>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002bc:	00001497          	auipc	s1,0x1
ffffffffc02002c0:	64c48493          	addi	s1,s1,1612 # ffffffffc0201908 <etext+0x218>
        if (argc == MAXARGS - 1) {
ffffffffc02002c4:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc02002c6:	00001a97          	auipc	s5,0x1
ffffffffc02002ca:	64aa8a93          	addi	s5,s5,1610 # ffffffffc0201910 <etext+0x220>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002ce:	4a0d                	li	s4,3
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc02002d0:	00001b97          	auipc	s7,0x1
ffffffffc02002d4:	660b8b93          	addi	s7,s7,1632 # ffffffffc0201930 <etext+0x240>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02002d8:	854a                	mv	a0,s2
ffffffffc02002da:	296010ef          	jal	ffffffffc0201570 <readline>
ffffffffc02002de:	842a                	mv	s0,a0
ffffffffc02002e0:	dd65                	beqz	a0,ffffffffc02002d8 <kmonitor+0x6a>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002e2:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc02002e6:	4c81                	li	s9,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002e8:	e59d                	bnez	a1,ffffffffc0200316 <kmonitor+0xa8>
    if (argc == 0) {
ffffffffc02002ea:	fe0c87e3          	beqz	s9,ffffffffc02002d8 <kmonitor+0x6a>
ffffffffc02002ee:	00002d17          	auipc	s10,0x2
ffffffffc02002f2:	032d0d13          	addi	s10,s10,50 # ffffffffc0202320 <commands>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002f6:	4401                	li	s0,0
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02002f8:	6582                	ld	a1,0(sp)
ffffffffc02002fa:	000d3503          	ld	a0,0(s10)
ffffffffc02002fe:	392010ef          	jal	ffffffffc0201690 <strcmp>
ffffffffc0200302:	c53d                	beqz	a0,ffffffffc0200370 <kmonitor+0x102>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200304:	2405                	addiw	s0,s0,1
ffffffffc0200306:	0d61                	addi	s10,s10,24
ffffffffc0200308:	ff4418e3          	bne	s0,s4,ffffffffc02002f8 <kmonitor+0x8a>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc020030c:	6582                	ld	a1,0(sp)
ffffffffc020030e:	855e                	mv	a0,s7
ffffffffc0200310:	da3ff0ef          	jal	ffffffffc02000b2 <cprintf>
    return 0;
ffffffffc0200314:	b7d1                	j	ffffffffc02002d8 <kmonitor+0x6a>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200316:	8526                	mv	a0,s1
ffffffffc0200318:	3b0010ef          	jal	ffffffffc02016c8 <strchr>
ffffffffc020031c:	c901                	beqz	a0,ffffffffc020032c <kmonitor+0xbe>
ffffffffc020031e:	00144583          	lbu	a1,1(s0)
            *buf ++ = '\0';
ffffffffc0200322:	00040023          	sb	zero,0(s0)
ffffffffc0200326:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200328:	d1e9                	beqz	a1,ffffffffc02002ea <kmonitor+0x7c>
ffffffffc020032a:	b7f5                	j	ffffffffc0200316 <kmonitor+0xa8>
        if (*buf == '\0') {
ffffffffc020032c:	00044783          	lbu	a5,0(s0)
ffffffffc0200330:	dfcd                	beqz	a5,ffffffffc02002ea <kmonitor+0x7c>
        if (argc == MAXARGS - 1) {
ffffffffc0200332:	033c8a63          	beq	s9,s3,ffffffffc0200366 <kmonitor+0xf8>
        argv[argc ++] = buf;
ffffffffc0200336:	003c9793          	slli	a5,s9,0x3
ffffffffc020033a:	08078793          	addi	a5,a5,128
ffffffffc020033e:	978a                	add	a5,a5,sp
ffffffffc0200340:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200344:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc0200348:	2c85                	addiw	s9,s9,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc020034a:	e591                	bnez	a1,ffffffffc0200356 <kmonitor+0xe8>
ffffffffc020034c:	bf79                	j	ffffffffc02002ea <kmonitor+0x7c>
ffffffffc020034e:	00144583          	lbu	a1,1(s0)
            buf ++;
ffffffffc0200352:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200354:	d9d9                	beqz	a1,ffffffffc02002ea <kmonitor+0x7c>
ffffffffc0200356:	8526                	mv	a0,s1
ffffffffc0200358:	370010ef          	jal	ffffffffc02016c8 <strchr>
ffffffffc020035c:	d96d                	beqz	a0,ffffffffc020034e <kmonitor+0xe0>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020035e:	00044583          	lbu	a1,0(s0)
ffffffffc0200362:	d5c1                	beqz	a1,ffffffffc02002ea <kmonitor+0x7c>
ffffffffc0200364:	bf4d                	j	ffffffffc0200316 <kmonitor+0xa8>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc0200366:	45c1                	li	a1,16
ffffffffc0200368:	8556                	mv	a0,s5
ffffffffc020036a:	d49ff0ef          	jal	ffffffffc02000b2 <cprintf>
ffffffffc020036e:	b7e1                	j	ffffffffc0200336 <kmonitor+0xc8>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc0200370:	00141793          	slli	a5,s0,0x1
ffffffffc0200374:	97a2                	add	a5,a5,s0
ffffffffc0200376:	078e                	slli	a5,a5,0x3
ffffffffc0200378:	97e2                	add	a5,a5,s8
ffffffffc020037a:	6b9c                	ld	a5,16(a5)
ffffffffc020037c:	865a                	mv	a2,s6
ffffffffc020037e:	002c                	addi	a1,sp,8
ffffffffc0200380:	fffc851b          	addiw	a0,s9,-1
ffffffffc0200384:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc0200386:	f40559e3          	bgez	a0,ffffffffc02002d8 <kmonitor+0x6a>
}
ffffffffc020038a:	60ee                	ld	ra,216(sp)
ffffffffc020038c:	644e                	ld	s0,208(sp)
ffffffffc020038e:	64ae                	ld	s1,200(sp)
ffffffffc0200390:	690e                	ld	s2,192(sp)
ffffffffc0200392:	79ea                	ld	s3,184(sp)
ffffffffc0200394:	7a4a                	ld	s4,176(sp)
ffffffffc0200396:	7aaa                	ld	s5,168(sp)
ffffffffc0200398:	7b0a                	ld	s6,160(sp)
ffffffffc020039a:	6bea                	ld	s7,152(sp)
ffffffffc020039c:	6c4a                	ld	s8,144(sp)
ffffffffc020039e:	6caa                	ld	s9,136(sp)
ffffffffc02003a0:	6d0a                	ld	s10,128(sp)
ffffffffc02003a2:	612d                	addi	sp,sp,224
ffffffffc02003a4:	8082                	ret

ffffffffc02003a6 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc02003a6:	00006317          	auipc	t1,0x6
ffffffffc02003aa:	1c230313          	addi	t1,t1,450 # ffffffffc0206568 <is_panic>
ffffffffc02003ae:	00032e03          	lw	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc02003b2:	715d                	addi	sp,sp,-80
ffffffffc02003b4:	ec06                	sd	ra,24(sp)
ffffffffc02003b6:	f436                	sd	a3,40(sp)
ffffffffc02003b8:	f83a                	sd	a4,48(sp)
ffffffffc02003ba:	fc3e                	sd	a5,56(sp)
ffffffffc02003bc:	e0c2                	sd	a6,64(sp)
ffffffffc02003be:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc02003c0:	020e1c63          	bnez	t3,ffffffffc02003f8 <__panic+0x52>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc02003c4:	4785                	li	a5,1
ffffffffc02003c6:	00f32023          	sw	a5,0(t1)

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc02003ca:	e822                	sd	s0,16(sp)
ffffffffc02003cc:	103c                	addi	a5,sp,40
ffffffffc02003ce:	8432                	mv	s0,a2
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02003d0:	862e                	mv	a2,a1
ffffffffc02003d2:	85aa                	mv	a1,a0
ffffffffc02003d4:	00001517          	auipc	a0,0x1
ffffffffc02003d8:	57450513          	addi	a0,a0,1396 # ffffffffc0201948 <etext+0x258>
    va_start(ap, fmt);
ffffffffc02003dc:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02003de:	cd5ff0ef          	jal	ffffffffc02000b2 <cprintf>
    vcprintf(fmt, ap);
ffffffffc02003e2:	65a2                	ld	a1,8(sp)
ffffffffc02003e4:	8522                	mv	a0,s0
ffffffffc02003e6:	cadff0ef          	jal	ffffffffc0200092 <vcprintf>
    cprintf("\n");
ffffffffc02003ea:	00001517          	auipc	a0,0x1
ffffffffc02003ee:	57e50513          	addi	a0,a0,1406 # ffffffffc0201968 <etext+0x278>
ffffffffc02003f2:	cc1ff0ef          	jal	ffffffffc02000b2 <cprintf>
ffffffffc02003f6:	6442                	ld	s0,16(sp)
    va_end(ap);

panic_dead:
    intr_disable();
ffffffffc02003f8:	062000ef          	jal	ffffffffc020045a <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc02003fc:	4501                	li	a0,0
ffffffffc02003fe:	e71ff0ef          	jal	ffffffffc020026e <kmonitor>
    while (1) {
ffffffffc0200402:	bfed                	j	ffffffffc02003fc <__panic+0x56>

ffffffffc0200404 <clock_init>:

/* *
 * clock_init - initialize 8253 clock to interrupt 100 times per second,
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
ffffffffc0200404:	1141                	addi	sp,sp,-16
ffffffffc0200406:	e406                	sd	ra,8(sp)
    // enable timer interrupt in sie
    set_csr(sie, MIP_STIP);
ffffffffc0200408:	02000793          	li	a5,32
ffffffffc020040c:	1047a7f3          	csrrs	a5,sie,a5
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200410:	c0102573          	rdtime	a0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200414:	67e1                	lui	a5,0x18
ffffffffc0200416:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc020041a:	953e                	add	a0,a0,a5
ffffffffc020041c:	222010ef          	jal	ffffffffc020163e <sbi_set_timer>
}
ffffffffc0200420:	60a2                	ld	ra,8(sp)
    ticks = 0;
ffffffffc0200422:	00006797          	auipc	a5,0x6
ffffffffc0200426:	1407b723          	sd	zero,334(a5) # ffffffffc0206570 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc020042a:	00001517          	auipc	a0,0x1
ffffffffc020042e:	54650513          	addi	a0,a0,1350 # ffffffffc0201970 <etext+0x280>
}
ffffffffc0200432:	0141                	addi	sp,sp,16
    cprintf("++ setup timer interrupts\n");
ffffffffc0200434:	b9bd                	j	ffffffffc02000b2 <cprintf>

ffffffffc0200436 <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200436:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc020043a:	67e1                	lui	a5,0x18
ffffffffc020043c:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc0200440:	953e                	add	a0,a0,a5
ffffffffc0200442:	1fc0106f          	j	ffffffffc020163e <sbi_set_timer>

ffffffffc0200446 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc0200446:	8082                	ret

ffffffffc0200448 <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
ffffffffc0200448:	0ff57513          	zext.b	a0,a0
ffffffffc020044c:	1d80106f          	j	ffffffffc0201624 <sbi_console_putchar>

ffffffffc0200450 <cons_getc>:
 * cons_getc - return the next input character from console,
 * or 0 if none waiting.
 * */
int cons_getc(void) {
    int c = 0;
    c = sbi_console_getchar();
ffffffffc0200450:	2080106f          	j	ffffffffc0201658 <sbi_console_getchar>

ffffffffc0200454 <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc0200454:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc0200458:	8082                	ret

ffffffffc020045a <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc020045a:	100177f3          	csrrci	a5,sstatus,2
ffffffffc020045e:	8082                	ret

ffffffffc0200460 <idt_init>:
     */

    extern void __alltraps(void);
    /* Set sup0 scratch register to 0, indicating to exception vector
       that we are presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc0200460:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc0200464:	00000797          	auipc	a5,0x0
ffffffffc0200468:	2e878793          	addi	a5,a5,744 # ffffffffc020074c <__alltraps>
ffffffffc020046c:	10579073          	csrw	stvec,a5
}
ffffffffc0200470:	8082                	ret

ffffffffc0200472 <print_regs>:
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr) {
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200472:	610c                	ld	a1,0(a0)
void print_regs(struct pushregs *gpr) {
ffffffffc0200474:	1141                	addi	sp,sp,-16
ffffffffc0200476:	e022                	sd	s0,0(sp)
ffffffffc0200478:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020047a:	00001517          	auipc	a0,0x1
ffffffffc020047e:	51650513          	addi	a0,a0,1302 # ffffffffc0201990 <etext+0x2a0>
void print_regs(struct pushregs *gpr) {
ffffffffc0200482:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200484:	c2fff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc0200488:	640c                	ld	a1,8(s0)
ffffffffc020048a:	00001517          	auipc	a0,0x1
ffffffffc020048e:	51e50513          	addi	a0,a0,1310 # ffffffffc02019a8 <etext+0x2b8>
ffffffffc0200492:	c21ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc0200496:	680c                	ld	a1,16(s0)
ffffffffc0200498:	00001517          	auipc	a0,0x1
ffffffffc020049c:	52850513          	addi	a0,a0,1320 # ffffffffc02019c0 <etext+0x2d0>
ffffffffc02004a0:	c13ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc02004a4:	6c0c                	ld	a1,24(s0)
ffffffffc02004a6:	00001517          	auipc	a0,0x1
ffffffffc02004aa:	53250513          	addi	a0,a0,1330 # ffffffffc02019d8 <etext+0x2e8>
ffffffffc02004ae:	c05ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc02004b2:	700c                	ld	a1,32(s0)
ffffffffc02004b4:	00001517          	auipc	a0,0x1
ffffffffc02004b8:	53c50513          	addi	a0,a0,1340 # ffffffffc02019f0 <etext+0x300>
ffffffffc02004bc:	bf7ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc02004c0:	740c                	ld	a1,40(s0)
ffffffffc02004c2:	00001517          	auipc	a0,0x1
ffffffffc02004c6:	54650513          	addi	a0,a0,1350 # ffffffffc0201a08 <etext+0x318>
ffffffffc02004ca:	be9ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc02004ce:	780c                	ld	a1,48(s0)
ffffffffc02004d0:	00001517          	auipc	a0,0x1
ffffffffc02004d4:	55050513          	addi	a0,a0,1360 # ffffffffc0201a20 <etext+0x330>
ffffffffc02004d8:	bdbff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc02004dc:	7c0c                	ld	a1,56(s0)
ffffffffc02004de:	00001517          	auipc	a0,0x1
ffffffffc02004e2:	55a50513          	addi	a0,a0,1370 # ffffffffc0201a38 <etext+0x348>
ffffffffc02004e6:	bcdff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc02004ea:	602c                	ld	a1,64(s0)
ffffffffc02004ec:	00001517          	auipc	a0,0x1
ffffffffc02004f0:	56450513          	addi	a0,a0,1380 # ffffffffc0201a50 <etext+0x360>
ffffffffc02004f4:	bbfff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc02004f8:	642c                	ld	a1,72(s0)
ffffffffc02004fa:	00001517          	auipc	a0,0x1
ffffffffc02004fe:	56e50513          	addi	a0,a0,1390 # ffffffffc0201a68 <etext+0x378>
ffffffffc0200502:	bb1ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc0200506:	682c                	ld	a1,80(s0)
ffffffffc0200508:	00001517          	auipc	a0,0x1
ffffffffc020050c:	57850513          	addi	a0,a0,1400 # ffffffffc0201a80 <etext+0x390>
ffffffffc0200510:	ba3ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc0200514:	6c2c                	ld	a1,88(s0)
ffffffffc0200516:	00001517          	auipc	a0,0x1
ffffffffc020051a:	58250513          	addi	a0,a0,1410 # ffffffffc0201a98 <etext+0x3a8>
ffffffffc020051e:	b95ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc0200522:	702c                	ld	a1,96(s0)
ffffffffc0200524:	00001517          	auipc	a0,0x1
ffffffffc0200528:	58c50513          	addi	a0,a0,1420 # ffffffffc0201ab0 <etext+0x3c0>
ffffffffc020052c:	b87ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc0200530:	742c                	ld	a1,104(s0)
ffffffffc0200532:	00001517          	auipc	a0,0x1
ffffffffc0200536:	59650513          	addi	a0,a0,1430 # ffffffffc0201ac8 <etext+0x3d8>
ffffffffc020053a:	b79ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc020053e:	782c                	ld	a1,112(s0)
ffffffffc0200540:	00001517          	auipc	a0,0x1
ffffffffc0200544:	5a050513          	addi	a0,a0,1440 # ffffffffc0201ae0 <etext+0x3f0>
ffffffffc0200548:	b6bff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc020054c:	7c2c                	ld	a1,120(s0)
ffffffffc020054e:	00001517          	auipc	a0,0x1
ffffffffc0200552:	5aa50513          	addi	a0,a0,1450 # ffffffffc0201af8 <etext+0x408>
ffffffffc0200556:	b5dff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc020055a:	604c                	ld	a1,128(s0)
ffffffffc020055c:	00001517          	auipc	a0,0x1
ffffffffc0200560:	5b450513          	addi	a0,a0,1460 # ffffffffc0201b10 <etext+0x420>
ffffffffc0200564:	b4fff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200568:	644c                	ld	a1,136(s0)
ffffffffc020056a:	00001517          	auipc	a0,0x1
ffffffffc020056e:	5be50513          	addi	a0,a0,1470 # ffffffffc0201b28 <etext+0x438>
ffffffffc0200572:	b41ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200576:	684c                	ld	a1,144(s0)
ffffffffc0200578:	00001517          	auipc	a0,0x1
ffffffffc020057c:	5c850513          	addi	a0,a0,1480 # ffffffffc0201b40 <etext+0x450>
ffffffffc0200580:	b33ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200584:	6c4c                	ld	a1,152(s0)
ffffffffc0200586:	00001517          	auipc	a0,0x1
ffffffffc020058a:	5d250513          	addi	a0,a0,1490 # ffffffffc0201b58 <etext+0x468>
ffffffffc020058e:	b25ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc0200592:	704c                	ld	a1,160(s0)
ffffffffc0200594:	00001517          	auipc	a0,0x1
ffffffffc0200598:	5dc50513          	addi	a0,a0,1500 # ffffffffc0201b70 <etext+0x480>
ffffffffc020059c:	b17ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc02005a0:	744c                	ld	a1,168(s0)
ffffffffc02005a2:	00001517          	auipc	a0,0x1
ffffffffc02005a6:	5e650513          	addi	a0,a0,1510 # ffffffffc0201b88 <etext+0x498>
ffffffffc02005aa:	b09ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc02005ae:	784c                	ld	a1,176(s0)
ffffffffc02005b0:	00001517          	auipc	a0,0x1
ffffffffc02005b4:	5f050513          	addi	a0,a0,1520 # ffffffffc0201ba0 <etext+0x4b0>
ffffffffc02005b8:	afbff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc02005bc:	7c4c                	ld	a1,184(s0)
ffffffffc02005be:	00001517          	auipc	a0,0x1
ffffffffc02005c2:	5fa50513          	addi	a0,a0,1530 # ffffffffc0201bb8 <etext+0x4c8>
ffffffffc02005c6:	aedff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc02005ca:	606c                	ld	a1,192(s0)
ffffffffc02005cc:	00001517          	auipc	a0,0x1
ffffffffc02005d0:	60450513          	addi	a0,a0,1540 # ffffffffc0201bd0 <etext+0x4e0>
ffffffffc02005d4:	adfff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc02005d8:	646c                	ld	a1,200(s0)
ffffffffc02005da:	00001517          	auipc	a0,0x1
ffffffffc02005de:	60e50513          	addi	a0,a0,1550 # ffffffffc0201be8 <etext+0x4f8>
ffffffffc02005e2:	ad1ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc02005e6:	686c                	ld	a1,208(s0)
ffffffffc02005e8:	00001517          	auipc	a0,0x1
ffffffffc02005ec:	61850513          	addi	a0,a0,1560 # ffffffffc0201c00 <etext+0x510>
ffffffffc02005f0:	ac3ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc02005f4:	6c6c                	ld	a1,216(s0)
ffffffffc02005f6:	00001517          	auipc	a0,0x1
ffffffffc02005fa:	62250513          	addi	a0,a0,1570 # ffffffffc0201c18 <etext+0x528>
ffffffffc02005fe:	ab5ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc0200602:	706c                	ld	a1,224(s0)
ffffffffc0200604:	00001517          	auipc	a0,0x1
ffffffffc0200608:	62c50513          	addi	a0,a0,1580 # ffffffffc0201c30 <etext+0x540>
ffffffffc020060c:	aa7ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc0200610:	746c                	ld	a1,232(s0)
ffffffffc0200612:	00001517          	auipc	a0,0x1
ffffffffc0200616:	63650513          	addi	a0,a0,1590 # ffffffffc0201c48 <etext+0x558>
ffffffffc020061a:	a99ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc020061e:	786c                	ld	a1,240(s0)
ffffffffc0200620:	00001517          	auipc	a0,0x1
ffffffffc0200624:	64050513          	addi	a0,a0,1600 # ffffffffc0201c60 <etext+0x570>
ffffffffc0200628:	a8bff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc020062c:	7c6c                	ld	a1,248(s0)
}
ffffffffc020062e:	6402                	ld	s0,0(sp)
ffffffffc0200630:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200632:	00001517          	auipc	a0,0x1
ffffffffc0200636:	64650513          	addi	a0,a0,1606 # ffffffffc0201c78 <etext+0x588>
}
ffffffffc020063a:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc020063c:	bc9d                	j	ffffffffc02000b2 <cprintf>

ffffffffc020063e <print_trapframe>:
void print_trapframe(struct trapframe *tf) {
ffffffffc020063e:	1141                	addi	sp,sp,-16
ffffffffc0200640:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200642:	85aa                	mv	a1,a0
void print_trapframe(struct trapframe *tf) {
ffffffffc0200644:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200646:	00001517          	auipc	a0,0x1
ffffffffc020064a:	64a50513          	addi	a0,a0,1610 # ffffffffc0201c90 <etext+0x5a0>
void print_trapframe(struct trapframe *tf) {
ffffffffc020064e:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200650:	a63ff0ef          	jal	ffffffffc02000b2 <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200654:	8522                	mv	a0,s0
ffffffffc0200656:	e1dff0ef          	jal	ffffffffc0200472 <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc020065a:	10043583          	ld	a1,256(s0)
ffffffffc020065e:	00001517          	auipc	a0,0x1
ffffffffc0200662:	64a50513          	addi	a0,a0,1610 # ffffffffc0201ca8 <etext+0x5b8>
ffffffffc0200666:	a4dff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc020066a:	10843583          	ld	a1,264(s0)
ffffffffc020066e:	00001517          	auipc	a0,0x1
ffffffffc0200672:	65250513          	addi	a0,a0,1618 # ffffffffc0201cc0 <etext+0x5d0>
ffffffffc0200676:	a3dff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
ffffffffc020067a:	11043583          	ld	a1,272(s0)
ffffffffc020067e:	00001517          	auipc	a0,0x1
ffffffffc0200682:	65a50513          	addi	a0,a0,1626 # ffffffffc0201cd8 <etext+0x5e8>
ffffffffc0200686:	a2dff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc020068a:	11843583          	ld	a1,280(s0)
}
ffffffffc020068e:	6402                	ld	s0,0(sp)
ffffffffc0200690:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200692:	00001517          	auipc	a0,0x1
ffffffffc0200696:	65e50513          	addi	a0,a0,1630 # ffffffffc0201cf0 <etext+0x600>
}
ffffffffc020069a:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc020069c:	bc19                	j	ffffffffc02000b2 <cprintf>

ffffffffc020069e <interrupt_handler>:

void interrupt_handler(struct trapframe *tf) {
    intptr_t cause = (tf->cause << 1) >> 1;
    switch (cause) {
ffffffffc020069e:	11853783          	ld	a5,280(a0)
ffffffffc02006a2:	472d                	li	a4,11
ffffffffc02006a4:	0786                	slli	a5,a5,0x1
ffffffffc02006a6:	8385                	srli	a5,a5,0x1
ffffffffc02006a8:	06f76c63          	bltu	a4,a5,ffffffffc0200720 <interrupt_handler+0x82>
ffffffffc02006ac:	00002717          	auipc	a4,0x2
ffffffffc02006b0:	cbc70713          	addi	a4,a4,-836 # ffffffffc0202368 <commands+0x48>
ffffffffc02006b4:	078a                	slli	a5,a5,0x2
ffffffffc02006b6:	97ba                	add	a5,a5,a4
ffffffffc02006b8:	439c                	lw	a5,0(a5)
ffffffffc02006ba:	97ba                	add	a5,a5,a4
ffffffffc02006bc:	8782                	jr	a5
            break;
        case IRQ_H_SOFT:
            cprintf("Hypervisor software interrupt\n");
            break;
        case IRQ_M_SOFT:
            cprintf("Machine software interrupt\n");
ffffffffc02006be:	00001517          	auipc	a0,0x1
ffffffffc02006c2:	6aa50513          	addi	a0,a0,1706 # ffffffffc0201d68 <etext+0x678>
ffffffffc02006c6:	b2f5                	j	ffffffffc02000b2 <cprintf>
            cprintf("Hypervisor software interrupt\n");
ffffffffc02006c8:	00001517          	auipc	a0,0x1
ffffffffc02006cc:	68050513          	addi	a0,a0,1664 # ffffffffc0201d48 <etext+0x658>
ffffffffc02006d0:	b2cd                	j	ffffffffc02000b2 <cprintf>
            cprintf("User software interrupt\n");
ffffffffc02006d2:	00001517          	auipc	a0,0x1
ffffffffc02006d6:	63650513          	addi	a0,a0,1590 # ffffffffc0201d08 <etext+0x618>
ffffffffc02006da:	bae1                	j	ffffffffc02000b2 <cprintf>
            break;
        case IRQ_U_TIMER:
            cprintf("User Timer interrupt\n");
ffffffffc02006dc:	00001517          	auipc	a0,0x1
ffffffffc02006e0:	6ac50513          	addi	a0,a0,1708 # ffffffffc0201d88 <etext+0x698>
ffffffffc02006e4:	b2f9                	j	ffffffffc02000b2 <cprintf>
void interrupt_handler(struct trapframe *tf) {
ffffffffc02006e6:	1141                	addi	sp,sp,-16
ffffffffc02006e8:	e406                	sd	ra,8(sp)
            // read-only." -- privileged spec1.9.1, 4.1.4, p59
            // In fact, Call sbi_set_timer will clear STIP, or you can clear it
            // directly.
            // cprintf("Supervisor timer interrupt\n");
            // clear_csr(sip, SIP_STIP);
            clock_set_next_event();
ffffffffc02006ea:	d4dff0ef          	jal	ffffffffc0200436 <clock_set_next_event>
            if (++ticks % TICK_NUM == 0) {
ffffffffc02006ee:	00006697          	auipc	a3,0x6
ffffffffc02006f2:	e8268693          	addi	a3,a3,-382 # ffffffffc0206570 <ticks>
ffffffffc02006f6:	629c                	ld	a5,0(a3)
ffffffffc02006f8:	06400713          	li	a4,100
ffffffffc02006fc:	0785                	addi	a5,a5,1
ffffffffc02006fe:	02e7f733          	remu	a4,a5,a4
ffffffffc0200702:	e29c                	sd	a5,0(a3)
ffffffffc0200704:	cf19                	beqz	a4,ffffffffc0200722 <interrupt_handler+0x84>
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc0200706:	60a2                	ld	ra,8(sp)
ffffffffc0200708:	0141                	addi	sp,sp,16
ffffffffc020070a:	8082                	ret
            cprintf("Supervisor external interrupt\n");
ffffffffc020070c:	00001517          	auipc	a0,0x1
ffffffffc0200710:	6a450513          	addi	a0,a0,1700 # ffffffffc0201db0 <etext+0x6c0>
ffffffffc0200714:	ba79                	j	ffffffffc02000b2 <cprintf>
            cprintf("Supervisor software interrupt\n");
ffffffffc0200716:	00001517          	auipc	a0,0x1
ffffffffc020071a:	61250513          	addi	a0,a0,1554 # ffffffffc0201d28 <etext+0x638>
ffffffffc020071e:	ba51                	j	ffffffffc02000b2 <cprintf>
            print_trapframe(tf);
ffffffffc0200720:	bf39                	j	ffffffffc020063e <print_trapframe>
}
ffffffffc0200722:	60a2                	ld	ra,8(sp)
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200724:	06400593          	li	a1,100
ffffffffc0200728:	00001517          	auipc	a0,0x1
ffffffffc020072c:	67850513          	addi	a0,a0,1656 # ffffffffc0201da0 <etext+0x6b0>
}
ffffffffc0200730:	0141                	addi	sp,sp,16
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200732:	981ff06f          	j	ffffffffc02000b2 <cprintf>

ffffffffc0200736 <trap>:
            break;
    }
}

static inline void trap_dispatch(struct trapframe *tf) {
    if ((intptr_t)tf->cause < 0) {
ffffffffc0200736:	11853783          	ld	a5,280(a0)
ffffffffc020073a:	0007c763          	bltz	a5,ffffffffc0200748 <trap+0x12>
    switch (tf->cause) {
ffffffffc020073e:	472d                	li	a4,11
ffffffffc0200740:	00f76363          	bltu	a4,a5,ffffffffc0200746 <trap+0x10>
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void trap(struct trapframe *tf) {
    // dispatch based on what type of trap occurred
    trap_dispatch(tf);
}
ffffffffc0200744:	8082                	ret
            print_trapframe(tf);
ffffffffc0200746:	bde5                	j	ffffffffc020063e <print_trapframe>
        interrupt_handler(tf);
ffffffffc0200748:	bf99                	j	ffffffffc020069e <interrupt_handler>
	...

ffffffffc020074c <__alltraps>:
    .endm

    .globl __alltraps
    .align(2)
__alltraps:
    SAVE_ALL
ffffffffc020074c:	14011073          	csrw	sscratch,sp
ffffffffc0200750:	712d                	addi	sp,sp,-288
ffffffffc0200752:	e002                	sd	zero,0(sp)
ffffffffc0200754:	e406                	sd	ra,8(sp)
ffffffffc0200756:	ec0e                	sd	gp,24(sp)
ffffffffc0200758:	f012                	sd	tp,32(sp)
ffffffffc020075a:	f416                	sd	t0,40(sp)
ffffffffc020075c:	f81a                	sd	t1,48(sp)
ffffffffc020075e:	fc1e                	sd	t2,56(sp)
ffffffffc0200760:	e0a2                	sd	s0,64(sp)
ffffffffc0200762:	e4a6                	sd	s1,72(sp)
ffffffffc0200764:	e8aa                	sd	a0,80(sp)
ffffffffc0200766:	ecae                	sd	a1,88(sp)
ffffffffc0200768:	f0b2                	sd	a2,96(sp)
ffffffffc020076a:	f4b6                	sd	a3,104(sp)
ffffffffc020076c:	f8ba                	sd	a4,112(sp)
ffffffffc020076e:	fcbe                	sd	a5,120(sp)
ffffffffc0200770:	e142                	sd	a6,128(sp)
ffffffffc0200772:	e546                	sd	a7,136(sp)
ffffffffc0200774:	e94a                	sd	s2,144(sp)
ffffffffc0200776:	ed4e                	sd	s3,152(sp)
ffffffffc0200778:	f152                	sd	s4,160(sp)
ffffffffc020077a:	f556                	sd	s5,168(sp)
ffffffffc020077c:	f95a                	sd	s6,176(sp)
ffffffffc020077e:	fd5e                	sd	s7,184(sp)
ffffffffc0200780:	e1e2                	sd	s8,192(sp)
ffffffffc0200782:	e5e6                	sd	s9,200(sp)
ffffffffc0200784:	e9ea                	sd	s10,208(sp)
ffffffffc0200786:	edee                	sd	s11,216(sp)
ffffffffc0200788:	f1f2                	sd	t3,224(sp)
ffffffffc020078a:	f5f6                	sd	t4,232(sp)
ffffffffc020078c:	f9fa                	sd	t5,240(sp)
ffffffffc020078e:	fdfe                	sd	t6,248(sp)
ffffffffc0200790:	14001473          	csrrw	s0,sscratch,zero
ffffffffc0200794:	100024f3          	csrr	s1,sstatus
ffffffffc0200798:	14102973          	csrr	s2,sepc
ffffffffc020079c:	143029f3          	csrr	s3,stval
ffffffffc02007a0:	14202a73          	csrr	s4,scause
ffffffffc02007a4:	e822                	sd	s0,16(sp)
ffffffffc02007a6:	e226                	sd	s1,256(sp)
ffffffffc02007a8:	e64a                	sd	s2,264(sp)
ffffffffc02007aa:	ea4e                	sd	s3,272(sp)
ffffffffc02007ac:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc02007ae:	850a                	mv	a0,sp
    jal trap
ffffffffc02007b0:	f87ff0ef          	jal	ffffffffc0200736 <trap>

ffffffffc02007b4 <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc02007b4:	6492                	ld	s1,256(sp)
ffffffffc02007b6:	6932                	ld	s2,264(sp)
ffffffffc02007b8:	10049073          	csrw	sstatus,s1
ffffffffc02007bc:	14191073          	csrw	sepc,s2
ffffffffc02007c0:	60a2                	ld	ra,8(sp)
ffffffffc02007c2:	61e2                	ld	gp,24(sp)
ffffffffc02007c4:	7202                	ld	tp,32(sp)
ffffffffc02007c6:	72a2                	ld	t0,40(sp)
ffffffffc02007c8:	7342                	ld	t1,48(sp)
ffffffffc02007ca:	73e2                	ld	t2,56(sp)
ffffffffc02007cc:	6406                	ld	s0,64(sp)
ffffffffc02007ce:	64a6                	ld	s1,72(sp)
ffffffffc02007d0:	6546                	ld	a0,80(sp)
ffffffffc02007d2:	65e6                	ld	a1,88(sp)
ffffffffc02007d4:	7606                	ld	a2,96(sp)
ffffffffc02007d6:	76a6                	ld	a3,104(sp)
ffffffffc02007d8:	7746                	ld	a4,112(sp)
ffffffffc02007da:	77e6                	ld	a5,120(sp)
ffffffffc02007dc:	680a                	ld	a6,128(sp)
ffffffffc02007de:	68aa                	ld	a7,136(sp)
ffffffffc02007e0:	694a                	ld	s2,144(sp)
ffffffffc02007e2:	69ea                	ld	s3,152(sp)
ffffffffc02007e4:	7a0a                	ld	s4,160(sp)
ffffffffc02007e6:	7aaa                	ld	s5,168(sp)
ffffffffc02007e8:	7b4a                	ld	s6,176(sp)
ffffffffc02007ea:	7bea                	ld	s7,184(sp)
ffffffffc02007ec:	6c0e                	ld	s8,192(sp)
ffffffffc02007ee:	6cae                	ld	s9,200(sp)
ffffffffc02007f0:	6d4e                	ld	s10,208(sp)
ffffffffc02007f2:	6dee                	ld	s11,216(sp)
ffffffffc02007f4:	7e0e                	ld	t3,224(sp)
ffffffffc02007f6:	7eae                	ld	t4,232(sp)
ffffffffc02007f8:	7f4e                	ld	t5,240(sp)
ffffffffc02007fa:	7fee                	ld	t6,248(sp)
ffffffffc02007fc:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc02007fe:	10200073          	sret

ffffffffc0200802 <buddy_init>:
    }
    cprintf("---------------------------\n");
}
// 初始化空闲块链表
static void buddy_init(void) {
     for (int i = 0; i < Max_Order; i++) {
ffffffffc0200802:	00006797          	auipc	a5,0x6
ffffffffc0200806:	80e78793          	addi	a5,a5,-2034 # ffffffffc0206010 <buddy>
ffffffffc020080a:	00006717          	auipc	a4,0x6
ffffffffc020080e:	91670713          	addi	a4,a4,-1770 # ffffffffc0206120 <buddy+0x110>
ffffffffc0200812:	00006697          	auipc	a3,0x6
ffffffffc0200816:	8fe68693          	addi	a3,a3,-1794 # ffffffffc0206110 <buddy+0x100>
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc020081a:	e79c                	sd	a5,8(a5)
ffffffffc020081c:	e39c                	sd	a5,0(a5)
        list_init(&free_list[i]);
        nr_free[i] = 0;
ffffffffc020081e:	00072023          	sw	zero,0(a4)
     for (int i = 0; i < Max_Order; i++) {
ffffffffc0200822:	07c1                	addi	a5,a5,16
ffffffffc0200824:	0711                	addi	a4,a4,4
ffffffffc0200826:	fed79ae3          	bne	a5,a3,ffffffffc020081a <buddy_init+0x18>
    }
}
ffffffffc020082a:	8082                	ret

ffffffffc020082c <buddy_nr_free_pages>:


// 获取空闲页数量
static size_t buddy_nr_free_pages(void) {
    size_t total_free = 0;
    for (size_t i = 0; i <= Max_Order; i++) {
ffffffffc020082c:	00006797          	auipc	a5,0x6
ffffffffc0200830:	8f478793          	addi	a5,a5,-1804 # ffffffffc0206120 <buddy+0x110>
ffffffffc0200834:	00006697          	auipc	a3,0x6
ffffffffc0200838:	93068693          	addi	a3,a3,-1744 # ffffffffc0206164 <buddy+0x154>
    size_t total_free = 0;
ffffffffc020083c:	4501                	li	a0,0
        total_free += nr_free[i];
ffffffffc020083e:	0007e703          	lwu	a4,0(a5)
    for (size_t i = 0; i <= Max_Order; i++) {
ffffffffc0200842:	0791                	addi	a5,a5,4
        total_free += nr_free[i];
ffffffffc0200844:	953a                	add	a0,a0,a4
    for (size_t i = 0; i <= Max_Order; i++) {
ffffffffc0200846:	fed79ce3          	bne	a5,a3,ffffffffc020083e <buddy_nr_free_pages+0x12>
    }
    return total_free;
}
ffffffffc020084a:	8082                	ret

ffffffffc020084c <buddy_check>:
    free_pages(p2, 3);
   // show_buddy_array();
}

/* 完整检查函数 */
static void buddy_check(void) {
ffffffffc020084c:	1101                	addi	sp,sp,-32
    assert((p0 = alloc_pages(1)) && (p1 = alloc_pages(3)) && (p2 = alloc_pages(5)));
ffffffffc020084e:	4505                	li	a0,1
static void buddy_check(void) {
ffffffffc0200850:	ec06                	sd	ra,24(sp)
ffffffffc0200852:	e822                	sd	s0,16(sp)
ffffffffc0200854:	e426                	sd	s1,8(sp)
ffffffffc0200856:	e04a                	sd	s2,0(sp)
    assert((p0 = alloc_pages(1)) && (p1 = alloc_pages(3)) && (p2 = alloc_pages(5)));
ffffffffc0200858:	70e000ef          	jal	ffffffffc0200f66 <alloc_pages>
ffffffffc020085c:	c52d                	beqz	a0,ffffffffc02008c6 <buddy_check+0x7a>
ffffffffc020085e:	842a                	mv	s0,a0
ffffffffc0200860:	450d                	li	a0,3
ffffffffc0200862:	704000ef          	jal	ffffffffc0200f66 <alloc_pages>
ffffffffc0200866:	84aa                	mv	s1,a0
ffffffffc0200868:	cd39                	beqz	a0,ffffffffc02008c6 <buddy_check+0x7a>
ffffffffc020086a:	4515                	li	a0,5
ffffffffc020086c:	6fa000ef          	jal	ffffffffc0200f66 <alloc_pages>
ffffffffc0200870:	892a                	mv	s2,a0
ffffffffc0200872:	c931                	beqz	a0,ffffffffc02008c6 <buddy_check+0x7a>
    free_pages(p0,1);
ffffffffc0200874:	8522                	mv	a0,s0
ffffffffc0200876:	4585                	li	a1,1
ffffffffc0200878:	72c000ef          	jal	ffffffffc0200fa4 <free_pages>
    free_pages(p2,5);
ffffffffc020087c:	4595                	li	a1,5
ffffffffc020087e:	854a                	mv	a0,s2
ffffffffc0200880:	724000ef          	jal	ffffffffc0200fa4 <free_pages>
    assert((p0 = alloc_pages(4)) && (p2 = alloc_pages(3)));
ffffffffc0200884:	4511                	li	a0,4
ffffffffc0200886:	6e0000ef          	jal	ffffffffc0200f66 <alloc_pages>
ffffffffc020088a:	842a                	mv	s0,a0
ffffffffc020088c:	cd29                	beqz	a0,ffffffffc02008e6 <buddy_check+0x9a>
ffffffffc020088e:	450d                	li	a0,3
ffffffffc0200890:	6d6000ef          	jal	ffffffffc0200f66 <alloc_pages>
ffffffffc0200894:	892a                	mv	s2,a0
ffffffffc0200896:	c921                	beqz	a0,ffffffffc02008e6 <buddy_check+0x9a>
    free_pages(p0, 4);
ffffffffc0200898:	4591                	li	a1,4
ffffffffc020089a:	8522                	mv	a0,s0
ffffffffc020089c:	708000ef          	jal	ffffffffc0200fa4 <free_pages>
    free_pages(p1, 3);
ffffffffc02008a0:	8526                	mv	a0,s1
ffffffffc02008a2:	458d                	li	a1,3
ffffffffc02008a4:	700000ef          	jal	ffffffffc0200fa4 <free_pages>
    assert((p0 = alloc_pages(9)));
ffffffffc02008a8:	4525                	li	a0,9
ffffffffc02008aa:	6bc000ef          	jal	ffffffffc0200f66 <alloc_pages>
ffffffffc02008ae:	cd21                	beqz	a0,ffffffffc0200906 <buddy_check+0xba>
    free_pages(p0, 9);
ffffffffc02008b0:	45a5                	li	a1,9
ffffffffc02008b2:	6f2000ef          	jal	ffffffffc0200fa4 <free_pages>
    basic_check();
}
ffffffffc02008b6:	6442                	ld	s0,16(sp)
ffffffffc02008b8:	60e2                	ld	ra,24(sp)
ffffffffc02008ba:	64a2                	ld	s1,8(sp)
    free_pages(p2, 3);
ffffffffc02008bc:	854a                	mv	a0,s2
}
ffffffffc02008be:	6902                	ld	s2,0(sp)
    free_pages(p2, 3);
ffffffffc02008c0:	458d                	li	a1,3
}
ffffffffc02008c2:	6105                	addi	sp,sp,32
    free_pages(p2, 3);
ffffffffc02008c4:	a5c5                	j	ffffffffc0200fa4 <free_pages>
    assert((p0 = alloc_pages(1)) && (p1 = alloc_pages(3)) && (p2 = alloc_pages(5)));
ffffffffc02008c6:	00001697          	auipc	a3,0x1
ffffffffc02008ca:	50a68693          	addi	a3,a3,1290 # ffffffffc0201dd0 <etext+0x6e0>
ffffffffc02008ce:	00001617          	auipc	a2,0x1
ffffffffc02008d2:	54a60613          	addi	a2,a2,1354 # ffffffffc0201e18 <etext+0x728>
ffffffffc02008d6:	13100593          	li	a1,305
ffffffffc02008da:	00001517          	auipc	a0,0x1
ffffffffc02008de:	55650513          	addi	a0,a0,1366 # ffffffffc0201e30 <etext+0x740>
ffffffffc02008e2:	ac5ff0ef          	jal	ffffffffc02003a6 <__panic>
    assert((p0 = alloc_pages(4)) && (p2 = alloc_pages(3)));
ffffffffc02008e6:	00001697          	auipc	a3,0x1
ffffffffc02008ea:	56268693          	addi	a3,a3,1378 # ffffffffc0201e48 <etext+0x758>
ffffffffc02008ee:	00001617          	auipc	a2,0x1
ffffffffc02008f2:	52a60613          	addi	a2,a2,1322 # ffffffffc0201e18 <etext+0x728>
ffffffffc02008f6:	13600593          	li	a1,310
ffffffffc02008fa:	00001517          	auipc	a0,0x1
ffffffffc02008fe:	53650513          	addi	a0,a0,1334 # ffffffffc0201e30 <etext+0x740>
ffffffffc0200902:	aa5ff0ef          	jal	ffffffffc02003a6 <__panic>
    assert((p0 = alloc_pages(9)));
ffffffffc0200906:	00001697          	auipc	a3,0x1
ffffffffc020090a:	57268693          	addi	a3,a3,1394 # ffffffffc0201e78 <etext+0x788>
ffffffffc020090e:	00001617          	auipc	a2,0x1
ffffffffc0200912:	50a60613          	addi	a2,a2,1290 # ffffffffc0201e18 <etext+0x728>
ffffffffc0200916:	13b00593          	li	a1,315
ffffffffc020091a:	00001517          	auipc	a0,0x1
ffffffffc020091e:	51650513          	addi	a0,a0,1302 # ffffffffc0201e30 <etext+0x740>
ffffffffc0200922:	a85ff0ef          	jal	ffffffffc02003a6 <__panic>

ffffffffc0200926 <buddy_init_memmap>:
extern struct Page *pages;
extern size_t npage;
extern const size_t nbase;
extern uint64_t va_pa_offset;

static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200926:	fcccd7b7          	lui	a5,0xfcccd
static void buddy_init_memmap(struct Page *base, size_t n) {
ffffffffc020092a:	7159                	addi	sp,sp,-112
ffffffffc020092c:	ccd78793          	addi	a5,a5,-819 # fffffffffccccccd <end+0x3cac671d>
ffffffffc0200930:	e4ce                	sd	s3,72(sp)
ffffffffc0200932:	07b2                	slli	a5,a5,0xc
ffffffffc0200934:	00006997          	auipc	s3,0x6
ffffffffc0200938:	c6c98993          	addi	s3,s3,-916 # ffffffffc02065a0 <pages>
ffffffffc020093c:	0009b703          	ld	a4,0(s3)
ffffffffc0200940:	ccd78793          	addi	a5,a5,-819
ffffffffc0200944:	07b2                	slli	a5,a5,0xc
ffffffffc0200946:	ccd78793          	addi	a5,a5,-819
ffffffffc020094a:	eca6                	sd	s1,88(sp)
ffffffffc020094c:	07b2                	slli	a5,a5,0xc
ffffffffc020094e:	40e504b3          	sub	s1,a0,a4
ffffffffc0200952:	ccd78793          	addi	a5,a5,-819
ffffffffc0200956:	848d                	srai	s1,s1,0x3
ffffffffc0200958:	02f484b3          	mul	s1,s1,a5
ffffffffc020095c:	e0d2                	sd	s4,64(sp)
ffffffffc020095e:	00002a17          	auipc	s4,0x2
ffffffffc0200962:	c02a0a13          	addi	s4,s4,-1022 # ffffffffc0202560 <nbase>
ffffffffc0200966:	000a3783          	ld	a5,0(s4)
ffffffffc020096a:	f0a2                	sd	s0,96(sp)
  cprintf("构建buddy_system前:\n");
ffffffffc020096c:	00001517          	auipc	a0,0x1
ffffffffc0200970:	52450513          	addi	a0,a0,1316 # ffffffffc0201e90 <etext+0x7a0>
ffffffffc0200974:	00005417          	auipc	s0,0x5
ffffffffc0200978:	7ac40413          	addi	s0,s0,1964 # ffffffffc0206120 <buddy+0x110>
static void buddy_init_memmap(struct Page *base, size_t n) {
ffffffffc020097c:	e8ca                	sd	s2,80(sp)
ffffffffc020097e:	fc56                	sd	s5,56(sp)
ffffffffc0200980:	f85a                	sd	s6,48(sp)
ffffffffc0200982:	94be                	add	s1,s1,a5
ffffffffc0200984:	f45e                	sd	s7,40(sp)
ffffffffc0200986:	f062                	sd	s8,32(sp)
ffffffffc0200988:	f486                	sd	ra,104(sp)
ffffffffc020098a:	8c2e                	mv	s8,a1

static inline uintptr_t page2pa(struct Page *page) {
    return page2ppn(page) << PGSHIFT;
ffffffffc020098c:	04b2                	slli	s1,s1,0xc
  cprintf("构建buddy_system前:\n");
ffffffffc020098e:	f24ff0ef          	jal	ffffffffc02000b2 <cprintf>
ffffffffc0200992:	8aa2                	mv	s5,s0
    .check = buddy_check,
};


void print_buddy(){
    for (int i = 0; i <= Max_Order; i++) {
ffffffffc0200994:	4901                	li	s2,0
                cprintf("Order %d: %d free blocks\n", i, nr_free[i]);
ffffffffc0200996:	00001b97          	auipc	s7,0x1
ffffffffc020099a:	512b8b93          	addi	s7,s7,1298 # ffffffffc0201ea8 <etext+0x7b8>
    for (int i = 0; i <= Max_Order; i++) {
ffffffffc020099e:	4b45                	li	s6,17
                cprintf("Order %d: %d free blocks\n", i, nr_free[i]);
ffffffffc02009a0:	000aa603          	lw	a2,0(s5)
ffffffffc02009a4:	85ca                	mv	a1,s2
ffffffffc02009a6:	855e                	mv	a0,s7
    for (int i = 0; i <= Max_Order; i++) {
ffffffffc02009a8:	2905                	addiw	s2,s2,1
                cprintf("Order %d: %d free blocks\n", i, nr_free[i]);
ffffffffc02009aa:	f08ff0ef          	jal	ffffffffc02000b2 <cprintf>
    for (int i = 0; i <= Max_Order; i++) {
ffffffffc02009ae:	0a91                	addi	s5,s5,4
ffffffffc02009b0:	ff6918e3          	bne	s2,s6,ffffffffc02009a0 <buddy_init_memmap+0x7a>
  while(n){
ffffffffc02009b4:	00006a97          	auipc	s5,0x6
ffffffffc02009b8:	be4a8a93          	addi	s5,s5,-1052 # ffffffffc0206598 <npage>
ffffffffc02009bc:	0c0c0463          	beqz	s8,ffffffffc0200a84 <buddy_init_memmap+0x15e>
ffffffffc02009c0:	ec66                	sd	s9,24(sp)
ffffffffc02009c2:	e86a                	sd	s10,16(sp)
ffffffffc02009c4:	e46e                	sd	s11,8(sp)
    if (x <= 1) return 0;
ffffffffc02009c6:	4c85                	li	s9,1
 * Insert the new element @elm *after* the element @listelm which
 * is already in the list.
 * */
static inline void
list_add_after(list_entry_t *listelm, list_entry_t *elm) {
    __list_add(elm, listelm, listelm->next);
ffffffffc02009c8:	00005917          	auipc	s2,0x5
ffffffffc02009cc:	64890913          	addi	s2,s2,1608 # ffffffffc0206010 <buddy>
ffffffffc02009d0:	0f9c0b63          	beq	s8,s9,ffffffffc0200ac6 <buddy_init_memmap+0x1a0>
    unsigned int exponent = 0;
ffffffffc02009d4:	4701                	li	a4,0
    unsigned int power = 1;
ffffffffc02009d6:	4785                	li	a5,1
        power <<= 1;
ffffffffc02009d8:	0017979b          	slliw	a5,a5,0x1
    while (power <= x) {
ffffffffc02009dc:	02079693          	slli	a3,a5,0x20
ffffffffc02009e0:	9281                	srli	a3,a3,0x20
ffffffffc02009e2:	00070b9b          	sext.w	s7,a4
        exponent++;
ffffffffc02009e6:	2705                	addiw	a4,a4,1
    while (power <= x) {
ffffffffc02009e8:	fedc78e3          	bgeu	s8,a3,ffffffffc02009d8 <buddy_init_memmap+0xb2>
    order_size=1u<<order;
ffffffffc02009ec:	4785                	li	a5,1
ffffffffc02009ee:	01779dbb          	sllw	s11,a5,s7
ffffffffc02009f2:	1d82                	slli	s11,s11,0x20
    order=round_down(n);
ffffffffc02009f4:	000b8d1b          	sext.w	s10,s7
    order_size=1u<<order;
ffffffffc02009f8:	020ddd93          	srli	s11,s11,0x20
    cprintf("order:%d\n",order);
ffffffffc02009fc:	85ea                	mv	a1,s10
ffffffffc02009fe:	00001517          	auipc	a0,0x1
ffffffffc0200a02:	4e250513          	addi	a0,a0,1250 # ffffffffc0201ee0 <etext+0x7f0>
ffffffffc0200a06:	eacff0ef          	jal	ffffffffc02000b2 <cprintf>
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc0200a0a:	000ab783          	ld	a5,0(s5)
ffffffffc0200a0e:	00c4d713          	srli	a4,s1,0xc
ffffffffc0200a12:	0af77e63          	bgeu	a4,a5,ffffffffc0200ace <buddy_init_memmap+0x1a8>
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc0200a16:	000a3783          	ld	a5,0(s4)
ffffffffc0200a1a:	0009b583          	ld	a1,0(s3)
ffffffffc0200a1e:	8f1d                	sub	a4,a4,a5
ffffffffc0200a20:	00271793          	slli	a5,a4,0x2
ffffffffc0200a24:	97ba                	add	a5,a5,a4
ffffffffc0200a26:	078e                	slli	a5,a5,0x3
ffffffffc0200a28:	00f58b33          	add	s6,a1,a5
    p->property = order;//
ffffffffc0200a2c:	017b2823          	sw	s7,16(s6)
 *
 * Note that @nr may be almost arbitrarily large; this function is not
 * restricted to acting on a single-word quantity.
 * */
static inline void set_bit(int nr, volatile void *addr) {
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0200a30:	008b0793          	addi	a5,s6,8
ffffffffc0200a34:	4709                	li	a4,2
ffffffffc0200a36:	40e7b02f          	amoor.d	zero,a4,(a5)
   cprintf("Adding page at %p to free_list[%d]\n", p, order);
ffffffffc0200a3a:	00001517          	auipc	a0,0x1
ffffffffc0200a3e:	4e650513          	addi	a0,a0,1254 # ffffffffc0201f20 <etext+0x830>
ffffffffc0200a42:	866a                	mv	a2,s10
ffffffffc0200a44:	85da                	mv	a1,s6
ffffffffc0200a46:	e6cff0ef          	jal	ffffffffc02000b2 <cprintf>
ffffffffc0200a4a:	004d1793          	slli	a5,s10,0x4
ffffffffc0200a4e:	97ca                	add	a5,a5,s2
   nr_free[order]++;
ffffffffc0200a50:	044d0613          	addi	a2,s10,68
ffffffffc0200a54:	6794                	ld	a3,8(a5)
ffffffffc0200a56:	060a                	slli	a2,a2,0x2
ffffffffc0200a58:	964a                	add	a2,a2,s2
ffffffffc0200a5a:	4218                	lw	a4,0(a2)
   list_add(&free_list[order],&p->page_link);//这里的free——list编号从下到上编号 8页对应3
ffffffffc0200a5c:	018b0513          	addi	a0,s6,24
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc0200a60:	e288                	sd	a0,0(a3)
ffffffffc0200a62:	e788                	sd	a0,8(a5)
    elm->next = next;
    elm->prev = prev;
ffffffffc0200a64:	00fb3c23          	sd	a5,24(s6)
    elm->next = next;
ffffffffc0200a68:	02db3023          	sd	a3,32(s6)
   nr_free[order]++;
ffffffffc0200a6c:	2705                	addiw	a4,a4,1
   begin_addr+=order_size*PGSIZE;
ffffffffc0200a6e:	00cd9793          	slli	a5,s11,0xc
   nr_free[order]++;
ffffffffc0200a72:	c218                	sw	a4,0(a2)
   n-=order_size;
ffffffffc0200a74:	41bc0c33          	sub	s8,s8,s11
   begin_addr+=order_size*PGSIZE;
ffffffffc0200a78:	94be                	add	s1,s1,a5
  while(n){
ffffffffc0200a7a:	f40c1be3          	bnez	s8,ffffffffc02009d0 <buddy_init_memmap+0xaa>
ffffffffc0200a7e:	6ce2                	ld	s9,24(sp)
ffffffffc0200a80:	6d42                	ld	s10,16(sp)
ffffffffc0200a82:	6da2                	ld	s11,8(sp)
  cprintf("构建buddy_system后:\n");
ffffffffc0200a84:	00001517          	auipc	a0,0x1
ffffffffc0200a88:	44450513          	addi	a0,a0,1092 # ffffffffc0201ec8 <etext+0x7d8>
ffffffffc0200a8c:	e26ff0ef          	jal	ffffffffc02000b2 <cprintf>
    for (int i = 0; i <= Max_Order; i++) {
ffffffffc0200a90:	4481                	li	s1,0
                cprintf("Order %d: %d free blocks\n", i, nr_free[i]);
ffffffffc0200a92:	00001997          	auipc	s3,0x1
ffffffffc0200a96:	41698993          	addi	s3,s3,1046 # ffffffffc0201ea8 <etext+0x7b8>
    for (int i = 0; i <= Max_Order; i++) {
ffffffffc0200a9a:	4945                	li	s2,17
                cprintf("Order %d: %d free blocks\n", i, nr_free[i]);
ffffffffc0200a9c:	4010                	lw	a2,0(s0)
ffffffffc0200a9e:	85a6                	mv	a1,s1
ffffffffc0200aa0:	854e                	mv	a0,s3
    for (int i = 0; i <= Max_Order; i++) {
ffffffffc0200aa2:	2485                	addiw	s1,s1,1
                cprintf("Order %d: %d free blocks\n", i, nr_free[i]);
ffffffffc0200aa4:	e0eff0ef          	jal	ffffffffc02000b2 <cprintf>
    for (int i = 0; i <= Max_Order; i++) {
ffffffffc0200aa8:	0411                	addi	s0,s0,4
ffffffffc0200aaa:	ff2499e3          	bne	s1,s2,ffffffffc0200a9c <buddy_init_memmap+0x176>
}
ffffffffc0200aae:	70a6                	ld	ra,104(sp)
ffffffffc0200ab0:	7406                	ld	s0,96(sp)
ffffffffc0200ab2:	64e6                	ld	s1,88(sp)
ffffffffc0200ab4:	6946                	ld	s2,80(sp)
ffffffffc0200ab6:	69a6                	ld	s3,72(sp)
ffffffffc0200ab8:	6a06                	ld	s4,64(sp)
ffffffffc0200aba:	7ae2                	ld	s5,56(sp)
ffffffffc0200abc:	7b42                	ld	s6,48(sp)
ffffffffc0200abe:	7ba2                	ld	s7,40(sp)
ffffffffc0200ac0:	7c02                	ld	s8,32(sp)
ffffffffc0200ac2:	6165                	addi	sp,sp,112
ffffffffc0200ac4:	8082                	ret
ffffffffc0200ac6:	4d85                	li	s11,1
ffffffffc0200ac8:	4d01                	li	s10,0
    if (x <= 1) return 0;
ffffffffc0200aca:	4b81                	li	s7,0
ffffffffc0200acc:	bf05                	j	ffffffffc02009fc <buddy_init_memmap+0xd6>
        panic("pa2page called with invalid pa");
ffffffffc0200ace:	00001617          	auipc	a2,0x1
ffffffffc0200ad2:	42260613          	addi	a2,a2,1058 # ffffffffc0201ef0 <etext+0x800>
ffffffffc0200ad6:	06b00593          	li	a1,107
ffffffffc0200ada:	00001517          	auipc	a0,0x1
ffffffffc0200ade:	43650513          	addi	a0,a0,1078 # ffffffffc0201f10 <etext+0x820>
ffffffffc0200ae2:	8c5ff0ef          	jal	ffffffffc02003a6 <__panic>

ffffffffc0200ae6 <buddy_alloc_pages>:
 static struct Page *buddy_alloc_pages(size_t n) {
ffffffffc0200ae6:	7139                	addi	sp,sp,-64
ffffffffc0200ae8:	fc06                	sd	ra,56(sp)
ffffffffc0200aea:	f04a                	sd	s2,32(sp)
ffffffffc0200aec:	e852                	sd	s4,16(sp)
    if (x <= 1) return 0;
ffffffffc0200aee:	4785                	li	a5,1
 static struct Page *buddy_alloc_pages(size_t n) {
ffffffffc0200af0:	85aa                	mv	a1,a0
    if (x <= 1) return 0;
ffffffffc0200af2:	18a7f763          	bgeu	a5,a0,ffffffffc0200c80 <buddy_alloc_pages+0x19a>
    unsigned int exponent = 0;
ffffffffc0200af6:	4701                	li	a4,0
        power <<= 1; // 左移相当于乘以2
ffffffffc0200af8:	0017979b          	slliw	a5,a5,0x1
    while (power < x) {
ffffffffc0200afc:	02079693          	slli	a3,a5,0x20
        exponent++;
ffffffffc0200b00:	0017091b          	addiw	s2,a4,1
    while (power < x) {
ffffffffc0200b04:	9281                	srli	a3,a3,0x20
        exponent++;
ffffffffc0200b06:	0009071b          	sext.w	a4,s2
    while (power < x) {
ffffffffc0200b0a:	feb6e7e3          	bltu	a3,a1,ffffffffc0200af8 <buddy_alloc_pages+0x12>
     cprintf("所要分配大小：%d\n",n);
ffffffffc0200b0e:	00001517          	auipc	a0,0x1
ffffffffc0200b12:	43a50513          	addi	a0,a0,1082 # ffffffffc0201f48 <etext+0x858>
    size_t need_order = round_up(n); // 向上取整，得到需要的order
ffffffffc0200b16:	1902                	slli	s2,s2,0x20
     cprintf("所要分配大小：%d\n",n);
ffffffffc0200b18:	d9aff0ef          	jal	ffffffffc02000b2 <cprintf>
    size_t need_order = round_up(n); // 向上取整，得到需要的order
ffffffffc0200b1c:	02095913          	srli	s2,s2,0x20
  cprintf("预计分配大小：%d\n",need_order);
ffffffffc0200b20:	85ca                	mv	a1,s2
ffffffffc0200b22:	00001517          	auipc	a0,0x1
ffffffffc0200b26:	44650513          	addi	a0,a0,1094 # ffffffffc0201f68 <etext+0x878>
ffffffffc0200b2a:	d88ff0ef          	jal	ffffffffc02000b2 <cprintf>
    for (size_t order = need_order; order <= Max_Order; order++) {
ffffffffc0200b2e:	47c1                	li	a5,16
ffffffffc0200b30:	1327eb63          	bltu	a5,s2,ffffffffc0200c66 <buddy_alloc_pages+0x180>
ffffffffc0200b34:	f822                	sd	s0,48(sp)
ffffffffc0200b36:	f426                	sd	s1,40(sp)
ffffffffc0200b38:	ec4e                	sd	s3,24(sp)
ffffffffc0200b3a:	e456                	sd	s5,8(sp)
ffffffffc0200b3c:	04490493          	addi	s1,s2,68
ffffffffc0200b40:	048a                	slli	s1,s1,0x2
ffffffffc0200b42:	00005a97          	auipc	s5,0x5
ffffffffc0200b46:	4cea8a93          	addi	s5,s5,1230 # ffffffffc0206010 <buddy>
ffffffffc0200b4a:	94d6                	add	s1,s1,s5
ffffffffc0200b4c:	844a                	mv	s0,s2
      cprintf("order：%d\n",order);
ffffffffc0200b4e:	00001997          	auipc	s3,0x1
ffffffffc0200b52:	45a98993          	addi	s3,s3,1114 # ffffffffc0201fa8 <etext+0x8b8>
    for (size_t order = need_order; order <= Max_Order; order++) {
ffffffffc0200b56:	4a45                	li	s4,17
ffffffffc0200b58:	a021                	j	ffffffffc0200b60 <buddy_alloc_pages+0x7a>
ffffffffc0200b5a:	0405                	addi	s0,s0,1
ffffffffc0200b5c:	11440163          	beq	s0,s4,ffffffffc0200c5e <buddy_alloc_pages+0x178>
      cprintf("order：%d\n",order);
ffffffffc0200b60:	85a2                	mv	a1,s0
ffffffffc0200b62:	854e                	mv	a0,s3
ffffffffc0200b64:	d4eff0ef          	jal	ffffffffc02000b2 <cprintf>
        if (nr_free[order] > 0) {
ffffffffc0200b68:	409c                	lw	a5,0(s1)
    for (size_t order = need_order; order <= Max_Order; order++) {
ffffffffc0200b6a:	0491                	addi	s1,s1,4
        if (nr_free[order] > 0) {
ffffffffc0200b6c:	d7fd                	beqz	a5,ffffffffc0200b5a <buddy_alloc_pages+0x74>
    return listelm->next;
ffffffffc0200b6e:	00441713          	slli	a4,s0,0x4
ffffffffc0200b72:	9756                	add	a4,a4,s5
ffffffffc0200b74:	00873983          	ld	s3,8(a4)
            nr_free[order]--;
ffffffffc0200b78:	04440713          	addi	a4,s0,68
ffffffffc0200b7c:	070a                	slli	a4,a4,0x2
    __list_del(listelm->prev, listelm->next);
ffffffffc0200b7e:	0009b603          	ld	a2,0(s3)
ffffffffc0200b82:	0089b683          	ld	a3,8(s3)
ffffffffc0200b86:	9756                	add	a4,a4,s5
ffffffffc0200b88:	37fd                	addiw	a5,a5,-1
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0200b8a:	e614                	sd	a3,8(a2)
    next->prev = prev;
ffffffffc0200b8c:	e290                	sd	a2,0(a3)
ffffffffc0200b8e:	c31c                	sw	a5,0(a4)
            struct Page *allocated_page = le2page(le, page_link); //这里的page_link指的是啥呀
ffffffffc0200b90:	fe898a13          	addi	s4,s3,-24
            allocated_page->property = order; // 设置属性
ffffffffc0200b94:	fe89ac23          	sw	s0,-8(s3)
            SetPageProperty(allocated_page);
ffffffffc0200b98:	ff098893          	addi	a7,s3,-16
ffffffffc0200b9c:	4789                	li	a5,2
ffffffffc0200b9e:	40f8b02f          	amoor.d	zero,a5,(a7)
            while (order > need_order) {
ffffffffc0200ba2:	06897363          	bgeu	s2,s0,ffffffffc0200c08 <buddy_alloc_pages+0x122>
ffffffffc0200ba6:	fff40613          	addi	a2,s0,-1
ffffffffc0200baa:	04340413          	addi	s0,s0,67
ffffffffc0200bae:	00461713          	slli	a4,a2,0x4
ffffffffc0200bb2:	040a                	slli	s0,s0,0x2
ffffffffc0200bb4:	9756                	add	a4,a4,s5
ffffffffc0200bb6:	008a86b3          	add	a3,s5,s0
                struct Page *remaining_page = allocated_page + (1 << order); // 计算剩余页面数量
ffffffffc0200bba:	4e05                	li	t3,1
ffffffffc0200bbc:	4309                	li	t1,2
ffffffffc0200bbe:	a011                	j	ffffffffc0200bc2 <buddy_alloc_pages+0xdc>
ffffffffc0200bc0:	167d                	addi	a2,a2,-1
ffffffffc0200bc2:	00ce15bb          	sllw	a1,t3,a2
ffffffffc0200bc6:	00259793          	slli	a5,a1,0x2
ffffffffc0200bca:	97ae                	add	a5,a5,a1
ffffffffc0200bcc:	078e                	slli	a5,a5,0x3
ffffffffc0200bce:	97d2                	add	a5,a5,s4
                remaining_page->property = order; 
ffffffffc0200bd0:	0006059b          	sext.w	a1,a2
ffffffffc0200bd4:	cb8c                	sw	a1,16(a5)
ffffffffc0200bd6:	00878513          	addi	a0,a5,8
ffffffffc0200bda:	4065302f          	amoor.d	zero,t1,(a0)
                 allocated_page->property = order; // 设置属性
ffffffffc0200bde:	feb9ac23          	sw	a1,-8(s3)
ffffffffc0200be2:	4068b02f          	amoor.d	zero,t1,(a7)
    __list_add(elm, listelm, listelm->next);
ffffffffc0200be6:	6708                	ld	a0,8(a4)
                nr_free[order]++;
ffffffffc0200be8:	428c                	lw	a1,0(a3)
                list_add(&free_list[order], &remaining_page->page_link);
ffffffffc0200bea:	01878813          	addi	a6,a5,24
    prev->next = next->prev = elm;
ffffffffc0200bee:	01053023          	sd	a6,0(a0)
ffffffffc0200bf2:	01073423          	sd	a6,8(a4)
    elm->prev = prev;
ffffffffc0200bf6:	ef98                	sd	a4,24(a5)
    elm->next = next;
ffffffffc0200bf8:	f388                	sd	a0,32(a5)
                nr_free[order]++;
ffffffffc0200bfa:	0015879b          	addiw	a5,a1,1
ffffffffc0200bfe:	c29c                	sw	a5,0(a3)
            while (order > need_order) {
ffffffffc0200c00:	1741                	addi	a4,a4,-16
ffffffffc0200c02:	16f1                	addi	a3,a3,-4
ffffffffc0200c04:	fb261ee3          	bne	a2,s2,ffffffffc0200bc0 <buddy_alloc_pages+0xda>
            cprintf("buddy_system:\n");
ffffffffc0200c08:	00001517          	auipc	a0,0x1
ffffffffc0200c0c:	38050513          	addi	a0,a0,896 # ffffffffc0201f88 <etext+0x898>
ffffffffc0200c10:	ca2ff0ef          	jal	ffffffffc02000b2 <cprintf>
    for (int i = 0; i <= Max_Order; i++) {
ffffffffc0200c14:	00005497          	auipc	s1,0x5
ffffffffc0200c18:	50c48493          	addi	s1,s1,1292 # ffffffffc0206120 <buddy+0x110>
ffffffffc0200c1c:	4401                	li	s0,0
                cprintf("Order %d: %d free blocks\n", i, nr_free[i]);
ffffffffc0200c1e:	00001a97          	auipc	s5,0x1
ffffffffc0200c22:	28aa8a93          	addi	s5,s5,650 # ffffffffc0201ea8 <etext+0x7b8>
    for (int i = 0; i <= Max_Order; i++) {
ffffffffc0200c26:	4945                	li	s2,17
                cprintf("Order %d: %d free blocks\n", i, nr_free[i]);
ffffffffc0200c28:	4090                	lw	a2,0(s1)
ffffffffc0200c2a:	85a2                	mv	a1,s0
ffffffffc0200c2c:	8556                	mv	a0,s5
    for (int i = 0; i <= Max_Order; i++) {
ffffffffc0200c2e:	2405                	addiw	s0,s0,1
                cprintf("Order %d: %d free blocks\n", i, nr_free[i]);
ffffffffc0200c30:	c82ff0ef          	jal	ffffffffc02000b2 <cprintf>
    for (int i = 0; i <= Max_Order; i++) {
ffffffffc0200c34:	0491                	addi	s1,s1,4
ffffffffc0200c36:	ff2419e3          	bne	s0,s2,ffffffffc0200c28 <buddy_alloc_pages+0x142>
           cprintf("allocated_page; order：%d\n",allocated_page->property);
ffffffffc0200c3a:	ff89a583          	lw	a1,-8(s3)
ffffffffc0200c3e:	00001517          	auipc	a0,0x1
ffffffffc0200c42:	35a50513          	addi	a0,a0,858 # ffffffffc0201f98 <etext+0x8a8>
ffffffffc0200c46:	c6cff0ef          	jal	ffffffffc02000b2 <cprintf>
}
ffffffffc0200c4a:	70e2                	ld	ra,56(sp)
            return allocated_page; // 返回分配的页面
ffffffffc0200c4c:	7442                	ld	s0,48(sp)
ffffffffc0200c4e:	74a2                	ld	s1,40(sp)
ffffffffc0200c50:	69e2                	ld	s3,24(sp)
ffffffffc0200c52:	6aa2                	ld	s5,8(sp)
}
ffffffffc0200c54:	7902                	ld	s2,32(sp)
ffffffffc0200c56:	8552                	mv	a0,s4
ffffffffc0200c58:	6a42                	ld	s4,16(sp)
ffffffffc0200c5a:	6121                	addi	sp,sp,64
ffffffffc0200c5c:	8082                	ret
ffffffffc0200c5e:	7442                	ld	s0,48(sp)
ffffffffc0200c60:	74a2                	ld	s1,40(sp)
ffffffffc0200c62:	69e2                	ld	s3,24(sp)
ffffffffc0200c64:	6aa2                	ld	s5,8(sp)
    cprintf("No block!\n");
ffffffffc0200c66:	00001517          	auipc	a0,0x1
ffffffffc0200c6a:	35250513          	addi	a0,a0,850 # ffffffffc0201fb8 <etext+0x8c8>
ffffffffc0200c6e:	c44ff0ef          	jal	ffffffffc02000b2 <cprintf>
}
ffffffffc0200c72:	70e2                	ld	ra,56(sp)
    return NULL; // 没有找到合适的块
ffffffffc0200c74:	4a01                	li	s4,0
}
ffffffffc0200c76:	7902                	ld	s2,32(sp)
ffffffffc0200c78:	8552                	mv	a0,s4
ffffffffc0200c7a:	6a42                	ld	s4,16(sp)
ffffffffc0200c7c:	6121                	addi	sp,sp,64
ffffffffc0200c7e:	8082                	ret
     cprintf("所要分配大小：%d\n",n);
ffffffffc0200c80:	00001517          	auipc	a0,0x1
ffffffffc0200c84:	2c850513          	addi	a0,a0,712 # ffffffffc0201f48 <etext+0x858>
ffffffffc0200c88:	f822                	sd	s0,48(sp)
ffffffffc0200c8a:	f426                	sd	s1,40(sp)
ffffffffc0200c8c:	ec4e                	sd	s3,24(sp)
ffffffffc0200c8e:	e456                	sd	s5,8(sp)
ffffffffc0200c90:	c22ff0ef          	jal	ffffffffc02000b2 <cprintf>
  cprintf("预计分配大小：%d\n",need_order);
ffffffffc0200c94:	4581                	li	a1,0
ffffffffc0200c96:	00001517          	auipc	a0,0x1
ffffffffc0200c9a:	2d250513          	addi	a0,a0,722 # ffffffffc0201f68 <etext+0x878>
ffffffffc0200c9e:	c14ff0ef          	jal	ffffffffc02000b2 <cprintf>
    size_t need_order = round_up(n); // 向上取整，得到需要的order
ffffffffc0200ca2:	4901                	li	s2,0
ffffffffc0200ca4:	bd61                	j	ffffffffc0200b3c <buddy_alloc_pages+0x56>

ffffffffc0200ca6 <buddy_free_pages>:
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200ca6:	fcccd7b7          	lui	a5,0xfcccd
static void buddy_free_pages(struct Page *base, size_t n) {
ffffffffc0200caa:	7119                	addi	sp,sp,-128
ffffffffc0200cac:	ccd78793          	addi	a5,a5,-819 # fffffffffccccccd <end+0x3cac671d>
ffffffffc0200cb0:	f466                	sd	s9,40(sp)
ffffffffc0200cb2:	07b2                	slli	a5,a5,0xc
ffffffffc0200cb4:	00006c97          	auipc	s9,0x6
ffffffffc0200cb8:	8ecc8c93          	addi	s9,s9,-1812 # ffffffffc02065a0 <pages>
ffffffffc0200cbc:	000cb703          	ld	a4,0(s9)
ffffffffc0200cc0:	ccd78793          	addi	a5,a5,-819
ffffffffc0200cc4:	07b2                	slli	a5,a5,0xc
ffffffffc0200cc6:	ccd78793          	addi	a5,a5,-819
ffffffffc0200cca:	e8d2                	sd	s4,80(sp)
ffffffffc0200ccc:	07b2                	slli	a5,a5,0xc
ffffffffc0200cce:	40e50a33          	sub	s4,a0,a4
ffffffffc0200cd2:	ccd78793          	addi	a5,a5,-819
ffffffffc0200cd6:	403a5a13          	srai	s4,s4,0x3
ffffffffc0200cda:	02fa0a33          	mul	s4,s4,a5
ffffffffc0200cde:	e0da                	sd	s6,64(sp)
ffffffffc0200ce0:	00002b17          	auipc	s6,0x2
ffffffffc0200ce4:	880b3b03          	ld	s6,-1920(s6) # ffffffffc0202560 <nbase>
ffffffffc0200ce8:	e4d6                	sd	s5,72(sp)
ffffffffc0200cea:	8aaa                	mv	s5,a0
    cprintf("所要合并大小：%d\n",n);
ffffffffc0200cec:	00001517          	auipc	a0,0x1
ffffffffc0200cf0:	2dc50513          	addi	a0,a0,732 # ffffffffc0201fc8 <etext+0x8d8>
static void buddy_free_pages(struct Page *base, size_t n) {
ffffffffc0200cf4:	fc86                	sd	ra,120(sp)
ffffffffc0200cf6:	f06a                	sd	s10,32(sp)
ffffffffc0200cf8:	f8a2                	sd	s0,112(sp)
    size_t order = base->property;  // 获取当前块的 order
ffffffffc0200cfa:	010aed03          	lwu	s10,16(s5)
ffffffffc0200cfe:	9a5a                	add	s4,s4,s6
static void buddy_free_pages(struct Page *base, size_t n) {
ffffffffc0200d00:	f4a6                	sd	s1,104(sp)
ffffffffc0200d02:	f0ca                	sd	s2,96(sp)
ffffffffc0200d04:	ecce                	sd	s3,88(sp)
    return page2ppn(page) << PGSHIFT;
ffffffffc0200d06:	0a32                	slli	s4,s4,0xc
    cprintf("所要合并大小：%d\n",n);
ffffffffc0200d08:	baaff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("合并地址为：%x\n",base_addr);
ffffffffc0200d0c:	85d2                	mv	a1,s4
ffffffffc0200d0e:	00001517          	auipc	a0,0x1
ffffffffc0200d12:	2da50513          	addi	a0,a0,730 # ffffffffc0201fe8 <etext+0x8f8>
ffffffffc0200d16:	b9cff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("base order：%d\n",order);
ffffffffc0200d1a:	85ea                	mv	a1,s10
ffffffffc0200d1c:	00001517          	auipc	a0,0x1
ffffffffc0200d20:	2e450513          	addi	a0,a0,740 # ffffffffc0202000 <etext+0x910>
ffffffffc0200d24:	b8eff0ef          	jal	ffffffffc02000b2 <cprintf>
    while (order <= Max_Order) {
ffffffffc0200d28:	4741                	li	a4,16
ffffffffc0200d2a:	21a76d63          	bltu	a4,s10,ffffffffc0200f44 <buddy_free_pages+0x29e>
ffffffffc0200d2e:	fc5e                	sd	s7,56(sp)
ffffffffc0200d30:	f862                	sd	s8,48(sp)
        if ( left_buddy_addr >= 0x80200000 && // 确保左侧伙伴在有效内存范围内
ffffffffc0200d32:	40100b93          	li	s7,1025
        else if ( right_buddy_addr < 0x88000000 && // 确保右侧伙伴在有效内存范围内
ffffffffc0200d36:	4c45                	li	s8,17
ffffffffc0200d38:	ec6e                	sd	s11,24(sp)
        if ( left_buddy_addr >= 0x80200000 && // 确保左侧伙伴在有效内存范围内
ffffffffc0200d3a:	0bd6                	slli	s7,s7,0x15
ffffffffc0200d3c:	00006d97          	auipc	s11,0x6
ffffffffc0200d40:	85cd8d93          	addi	s11,s11,-1956 # ffffffffc0206598 <npage>
        else if ( right_buddy_addr < 0x88000000 && // 确保右侧伙伴在有效内存范围内
ffffffffc0200d44:	0c6e                	slli	s8,s8,0x1b
        uintptr_t left_buddy_addr = base_addr - (1 << order);
ffffffffc0200d46:	4785                	li	a5,1
ffffffffc0200d48:	01a7993b          	sllw	s2,a5,s10
ffffffffc0200d4c:	412a09b3          	sub	s3,s4,s2
        cprintf("left_buddy_addr：%x\n",left_buddy_addr);
ffffffffc0200d50:	85ce                	mv	a1,s3
ffffffffc0200d52:	00001517          	auipc	a0,0x1
ffffffffc0200d56:	2c650513          	addi	a0,a0,710 # ffffffffc0202018 <etext+0x928>
ffffffffc0200d5a:	b58ff0ef          	jal	ffffffffc02000b2 <cprintf>
        uintptr_t right_buddy_addr = base_addr + (1 << order);
ffffffffc0200d5e:	9952                	add	s2,s2,s4
        cprintf("right_buddy_addr：%x\n",right_buddy_addr);
ffffffffc0200d60:	85ca                	mv	a1,s2
ffffffffc0200d62:	00001517          	auipc	a0,0x1
ffffffffc0200d66:	2ce50513          	addi	a0,a0,718 # ffffffffc0202030 <etext+0x940>
ffffffffc0200d6a:	b48ff0ef          	jal	ffffffffc02000b2 <cprintf>
    if (PPN(pa) >= npage) {
ffffffffc0200d6e:	000db603          	ld	a2,0(s11)
ffffffffc0200d72:	00c9d713          	srli	a4,s3,0xc
ffffffffc0200d76:	1cc77c63          	bgeu	a4,a2,ffffffffc0200f4e <buddy_free_pages+0x2a8>
    return &pages[PPN(pa) - nbase];
ffffffffc0200d7a:	41670733          	sub	a4,a4,s6
ffffffffc0200d7e:	000cb483          	ld	s1,0(s9)
ffffffffc0200d82:	00271413          	slli	s0,a4,0x2
ffffffffc0200d86:	943a                	add	s0,s0,a4
ffffffffc0200d88:	040e                	slli	s0,s0,0x3
    if (PPN(pa) >= npage) {
ffffffffc0200d8a:	00c95693          	srli	a3,s2,0xc
    return &pages[PPN(pa) - nbase];
ffffffffc0200d8e:	9426                	add	s0,s0,s1
    if (PPN(pa) >= npage) {
ffffffffc0200d90:	1ac6ff63          	bgeu	a3,a2,ffffffffc0200f4e <buddy_free_pages+0x2a8>
    return &pages[PPN(pa) - nbase];
ffffffffc0200d94:	416686b3          	sub	a3,a3,s6
ffffffffc0200d98:	00269713          	slli	a4,a3,0x2
        cprintf("left_buddy_page->property :%d\n",left_buddy_page->property );
ffffffffc0200d9c:	480c                	lw	a1,16(s0)
ffffffffc0200d9e:	9736                	add	a4,a4,a3
ffffffffc0200da0:	070e                	slli	a4,a4,0x3
ffffffffc0200da2:	00001517          	auipc	a0,0x1
ffffffffc0200da6:	2a650513          	addi	a0,a0,678 # ffffffffc0202048 <etext+0x958>
ffffffffc0200daa:	94ba                	add	s1,s1,a4
ffffffffc0200dac:	b06ff0ef          	jal	ffffffffc02000b2 <cprintf>
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200db0:	640c                	ld	a1,8(s0)
        cprintf("PageProperty(left_buddy_page):%d\n",PageProperty(left_buddy_page));
ffffffffc0200db2:	00001517          	auipc	a0,0x1
ffffffffc0200db6:	2b650513          	addi	a0,a0,694 # ffffffffc0202068 <etext+0x978>
ffffffffc0200dba:	8185                	srli	a1,a1,0x1
ffffffffc0200dbc:	8985                	andi	a1,a1,1
ffffffffc0200dbe:	af4ff0ef          	jal	ffffffffc02000b2 <cprintf>
         cprintf("right_buddy_page->property :%d\n",right_buddy_page->property );
ffffffffc0200dc2:	488c                	lw	a1,16(s1)
ffffffffc0200dc4:	00001517          	auipc	a0,0x1
ffffffffc0200dc8:	2cc50513          	addi	a0,a0,716 # ffffffffc0202090 <etext+0x9a0>
ffffffffc0200dcc:	ae6ff0ef          	jal	ffffffffc02000b2 <cprintf>
ffffffffc0200dd0:	648c                	ld	a1,8(s1)
        cprintf("PageProperty(right_buddy_page):%d\n",  PageProperty(right_buddy_page));
ffffffffc0200dd2:	00001517          	auipc	a0,0x1
ffffffffc0200dd6:	2de50513          	addi	a0,a0,734 # ffffffffc02020b0 <etext+0x9c0>
ffffffffc0200dda:	8185                	srli	a1,a1,0x1
ffffffffc0200ddc:	8985                	andi	a1,a1,1
ffffffffc0200dde:	ad4ff0ef          	jal	ffffffffc02000b2 <cprintf>
        if ( left_buddy_addr >= 0x80200000 && // 确保左侧伙伴在有效内存范围内
ffffffffc0200de2:	1579ec63          	bltu	s3,s7,ffffffffc0200f3a <buddy_free_pages+0x294>
            left_buddy_page->property == order && 
ffffffffc0200de6:	480c                	lw	a1,16(s0)
ffffffffc0200de8:	00005717          	auipc	a4,0x5
ffffffffc0200dec:	22870713          	addi	a4,a4,552 # ffffffffc0206010 <buddy>
ffffffffc0200df0:	02059693          	slli	a3,a1,0x20
ffffffffc0200df4:	9281                	srli	a3,a3,0x20
        if ( left_buddy_addr >= 0x80200000 && // 确保左侧伙伴在有效内存范围内
ffffffffc0200df6:	0fa68963          	beq	a3,s10,ffffffffc0200ee8 <buddy_free_pages+0x242>
        else if ( right_buddy_addr < 0x88000000 && // 确保右侧伙伴在有效内存范围内
ffffffffc0200dfa:	07897563          	bgeu	s2,s8,ffffffffc0200e64 <buddy_free_pages+0x1be>
                 right_buddy_page->property == order && 
ffffffffc0200dfe:	0104e683          	lwu	a3,16(s1)
        else if ( right_buddy_addr < 0x88000000 && // 确保右侧伙伴在有效内存范围内
ffffffffc0200e02:	07a69163          	bne	a3,s10,ffffffffc0200e64 <buddy_free_pages+0x1be>
ffffffffc0200e06:	6494                	ld	a3,8(s1)
                 right_buddy_page->property == order && 
ffffffffc0200e08:	8a89                	andi	a3,a3,2
ffffffffc0200e0a:	cea9                	beqz	a3,ffffffffc0200e64 <buddy_free_pages+0x1be>
                  nr_free[order]) {
ffffffffc0200e0c:	044d0913          	addi	s2,s10,68
ffffffffc0200e10:	090a                	slli	s2,s2,0x2
ffffffffc0200e12:	993a                	add	s2,s2,a4
                  PageProperty(right_buddy_page)&&
ffffffffc0200e14:	00092783          	lw	a5,0(s2)
ffffffffc0200e18:	c7b1                	beqz	a5,ffffffffc0200e64 <buddy_free_pages+0x1be>
            cprintf("右侧伙伴块order:%d",left_buddy_page->property );
ffffffffc0200e1a:	480c                	lw	a1,16(s0)
ffffffffc0200e1c:	00001517          	auipc	a0,0x1
ffffffffc0200e20:	2fc50513          	addi	a0,a0,764 # ffffffffc0202118 <etext+0xa28>
ffffffffc0200e24:	e03a                	sd	a4,0(sp)
ffffffffc0200e26:	a8cff0ef          	jal	ffffffffc02000b2 <cprintf>
    __list_del(listelm->prev, listelm->next);
ffffffffc0200e2a:	6c90                	ld	a2,24(s1)
ffffffffc0200e2c:	7094                	ld	a3,32(s1)
            nr_free[order]--;
ffffffffc0200e2e:	00092783          	lw	a5,0(s2)
            cprintf("合并右边，首地址为：%d\n",base_addr);
ffffffffc0200e32:	85d2                	mv	a1,s4
    prev->next = next;
ffffffffc0200e34:	e614                	sd	a3,8(a2)
    next->prev = prev;
ffffffffc0200e36:	e290                	sd	a2,0(a3)
            nr_free[order]--;
ffffffffc0200e38:	37fd                	addiw	a5,a5,-1
            cprintf("合并右边，首地址为：%d\n",base_addr);
ffffffffc0200e3a:	00001517          	auipc	a0,0x1
ffffffffc0200e3e:	2f650513          	addi	a0,a0,758 # ffffffffc0202130 <etext+0xa40>
            nr_free[order]--;
ffffffffc0200e42:	00f92023          	sw	a5,0(s2)
            cprintf("合并右边，首地址为：%d\n",base_addr);
ffffffffc0200e46:	a6cff0ef          	jal	ffffffffc02000b2 <cprintf>
ffffffffc0200e4a:	6702                	ld	a4,0(sp)
            base->property++;
ffffffffc0200e4c:	010aa783          	lw	a5,16(s5)
    while (order <= Max_Order) {
ffffffffc0200e50:	46c1                	li	a3,16
            base->property++;
ffffffffc0200e52:	2785                	addiw	a5,a5,1
            order = base->property;
ffffffffc0200e54:	02079d13          	slli	s10,a5,0x20
            base->property++;
ffffffffc0200e58:	00faa823          	sw	a5,16(s5)
            order = base->property;
ffffffffc0200e5c:	020d5d13          	srli	s10,s10,0x20
    while (order <= Max_Order) {
ffffffffc0200e60:	efa6f3e3          	bgeu	a3,s10,ffffffffc0200d46 <buddy_free_pages+0xa0>
ffffffffc0200e64:	7be2                	ld	s7,56(sp)
ffffffffc0200e66:	7c42                	ld	s8,48(sp)
ffffffffc0200e68:	6de2                	ld	s11,24(sp)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0200e6a:	4789                	li	a5,2
ffffffffc0200e6c:	008a8693          	addi	a3,s5,8
ffffffffc0200e70:	40f6b02f          	amoor.d	zero,a5,(a3)
    __list_add(elm, listelm, listelm->next);
ffffffffc0200e74:	010ae783          	lwu	a5,16(s5)
    list_add(&free_list[base->property], &base->page_link);
ffffffffc0200e78:	018a8593          	addi	a1,s5,24
    cprintf("buddy_system:\n");
ffffffffc0200e7c:	00001517          	auipc	a0,0x1
ffffffffc0200e80:	10c50513          	addi	a0,a0,268 # ffffffffc0201f88 <etext+0x898>
ffffffffc0200e84:	00479693          	slli	a3,a5,0x4
ffffffffc0200e88:	96ba                	add	a3,a3,a4
    nr_free[base->property]++;
ffffffffc0200e8a:	04478793          	addi	a5,a5,68
ffffffffc0200e8e:	6690                	ld	a2,8(a3)
ffffffffc0200e90:	078a                	slli	a5,a5,0x2
ffffffffc0200e92:	973e                	add	a4,a4,a5
ffffffffc0200e94:	431c                	lw	a5,0(a4)
    prev->next = next->prev = elm;
ffffffffc0200e96:	e20c                	sd	a1,0(a2)
ffffffffc0200e98:	e68c                	sd	a1,8(a3)
    elm->next = next;
ffffffffc0200e9a:	02cab023          	sd	a2,32(s5)
    elm->prev = prev;
ffffffffc0200e9e:	00dabc23          	sd	a3,24(s5)
ffffffffc0200ea2:	2785                	addiw	a5,a5,1
ffffffffc0200ea4:	c31c                	sw	a5,0(a4)
    cprintf("buddy_system:\n");
ffffffffc0200ea6:	00005497          	auipc	s1,0x5
ffffffffc0200eaa:	27a48493          	addi	s1,s1,634 # ffffffffc0206120 <buddy+0x110>
ffffffffc0200eae:	a04ff0ef          	jal	ffffffffc02000b2 <cprintf>
    for (int i = 0; i <= Max_Order; i++) {
ffffffffc0200eb2:	4401                	li	s0,0
                cprintf("Order %d: %d free blocks\n", i, nr_free[i]);
ffffffffc0200eb4:	00001997          	auipc	s3,0x1
ffffffffc0200eb8:	ff498993          	addi	s3,s3,-12 # ffffffffc0201ea8 <etext+0x7b8>
    for (int i = 0; i <= Max_Order; i++) {
ffffffffc0200ebc:	4945                	li	s2,17
                cprintf("Order %d: %d free blocks\n", i, nr_free[i]);
ffffffffc0200ebe:	4090                	lw	a2,0(s1)
ffffffffc0200ec0:	85a2                	mv	a1,s0
ffffffffc0200ec2:	854e                	mv	a0,s3
    for (int i = 0; i <= Max_Order; i++) {
ffffffffc0200ec4:	2405                	addiw	s0,s0,1
                cprintf("Order %d: %d free blocks\n", i, nr_free[i]);
ffffffffc0200ec6:	9ecff0ef          	jal	ffffffffc02000b2 <cprintf>
    for (int i = 0; i <= Max_Order; i++) {
ffffffffc0200eca:	0491                	addi	s1,s1,4
ffffffffc0200ecc:	ff2419e3          	bne	s0,s2,ffffffffc0200ebe <buddy_free_pages+0x218>
}
ffffffffc0200ed0:	70e6                	ld	ra,120(sp)
ffffffffc0200ed2:	7446                	ld	s0,112(sp)
ffffffffc0200ed4:	74a6                	ld	s1,104(sp)
ffffffffc0200ed6:	7906                	ld	s2,96(sp)
ffffffffc0200ed8:	69e6                	ld	s3,88(sp)
ffffffffc0200eda:	6a46                	ld	s4,80(sp)
ffffffffc0200edc:	6aa6                	ld	s5,72(sp)
ffffffffc0200ede:	6b06                	ld	s6,64(sp)
ffffffffc0200ee0:	7ca2                	ld	s9,40(sp)
ffffffffc0200ee2:	7d02                	ld	s10,32(sp)
ffffffffc0200ee4:	6109                	addi	sp,sp,128
ffffffffc0200ee6:	8082                	ret
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200ee8:	6418                	ld	a4,8(s0)
            left_buddy_page->property == order && 
ffffffffc0200eea:	8b09                	andi	a4,a4,2
ffffffffc0200eec:	c739                	beqz	a4,ffffffffc0200f3a <buddy_free_pages+0x294>
            nr_free[order]) {
ffffffffc0200eee:	044d0693          	addi	a3,s10,68
ffffffffc0200ef2:	00005717          	auipc	a4,0x5
ffffffffc0200ef6:	11e70713          	addi	a4,a4,286 # ffffffffc0206010 <buddy>
ffffffffc0200efa:	068a                	slli	a3,a3,0x2
ffffffffc0200efc:	96ba                	add	a3,a3,a4
            PageProperty(left_buddy_page)&&//该页是否自由
ffffffffc0200efe:	4290                	lw	a2,0(a3)
ffffffffc0200f00:	ee060de3          	beqz	a2,ffffffffc0200dfa <buddy_free_pages+0x154>
            cprintf("左侧伙伴块order:%d",left_buddy_page->property );
ffffffffc0200f04:	00001517          	auipc	a0,0x1
ffffffffc0200f08:	1d450513          	addi	a0,a0,468 # ffffffffc02020d8 <etext+0x9e8>
ffffffffc0200f0c:	e43a                	sd	a4,8(sp)
ffffffffc0200f0e:	e036                	sd	a3,0(sp)
ffffffffc0200f10:	9a2ff0ef          	jal	ffffffffc02000b2 <cprintf>
            nr_free[order]--;
ffffffffc0200f14:	6682                	ld	a3,0(sp)
    __list_del(listelm->prev, listelm->next);
ffffffffc0200f16:	6c08                	ld	a0,24(s0)
ffffffffc0200f18:	7010                	ld	a2,32(s0)
ffffffffc0200f1a:	429c                	lw	a5,0(a3)
            cprintf("合并左边，首地址为：%d\n",base_addr);  
ffffffffc0200f1c:	85ce                	mv	a1,s3
    prev->next = next;
ffffffffc0200f1e:	e510                	sd	a2,8(a0)
    next->prev = prev;
ffffffffc0200f20:	e208                	sd	a0,0(a2)
            nr_free[order]--;
ffffffffc0200f22:	37fd                	addiw	a5,a5,-1
            cprintf("合并左边，首地址为：%d\n",base_addr);  
ffffffffc0200f24:	00001517          	auipc	a0,0x1
ffffffffc0200f28:	1cc50513          	addi	a0,a0,460 # ffffffffc02020f0 <etext+0xa00>
            nr_free[order]--;
ffffffffc0200f2c:	c29c                	sw	a5,0(a3)
            cprintf("合并左边，首地址为：%d\n",base_addr);  
ffffffffc0200f2e:	984ff0ef          	jal	ffffffffc02000b2 <cprintf>
        if (merged) {
ffffffffc0200f32:	6722                	ld	a4,8(sp)
            base_addr = left_buddy_addr;
ffffffffc0200f34:	8a4e                	mv	s4,s3
            base = left_buddy_page;  // 合并后，base 指向较小地址的块
ffffffffc0200f36:	8aa2                	mv	s5,s0
ffffffffc0200f38:	bf11                	j	ffffffffc0200e4c <buddy_free_pages+0x1a6>
ffffffffc0200f3a:	00005717          	auipc	a4,0x5
ffffffffc0200f3e:	0d670713          	addi	a4,a4,214 # ffffffffc0206010 <buddy>
ffffffffc0200f42:	bd65                	j	ffffffffc0200dfa <buddy_free_pages+0x154>
ffffffffc0200f44:	00005717          	auipc	a4,0x5
ffffffffc0200f48:	0cc70713          	addi	a4,a4,204 # ffffffffc0206010 <buddy>
ffffffffc0200f4c:	bf39                	j	ffffffffc0200e6a <buddy_free_pages+0x1c4>
        panic("pa2page called with invalid pa");
ffffffffc0200f4e:	00001617          	auipc	a2,0x1
ffffffffc0200f52:	fa260613          	addi	a2,a2,-94 # ffffffffc0201ef0 <etext+0x800>
ffffffffc0200f56:	06b00593          	li	a1,107
ffffffffc0200f5a:	00001517          	auipc	a0,0x1
ffffffffc0200f5e:	fb650513          	addi	a0,a0,-74 # ffffffffc0201f10 <etext+0x820>
ffffffffc0200f62:	c44ff0ef          	jal	ffffffffc02003a6 <__panic>

ffffffffc0200f66 <alloc_pages>:
#include <defs.h>
#include <intr.h>
#include <riscv.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0200f66:	100027f3          	csrr	a5,sstatus
ffffffffc0200f6a:	8b89                	andi	a5,a5,2
ffffffffc0200f6c:	e799                	bnez	a5,ffffffffc0200f7a <alloc_pages+0x14>
struct Page *alloc_pages(size_t n) {
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc0200f6e:	00005797          	auipc	a5,0x5
ffffffffc0200f72:	60a7b783          	ld	a5,1546(a5) # ffffffffc0206578 <pmm_manager>
ffffffffc0200f76:	6f9c                	ld	a5,24(a5)
ffffffffc0200f78:	8782                	jr	a5
struct Page *alloc_pages(size_t n) {
ffffffffc0200f7a:	1141                	addi	sp,sp,-16
ffffffffc0200f7c:	e406                	sd	ra,8(sp)
ffffffffc0200f7e:	e022                	sd	s0,0(sp)
ffffffffc0200f80:	842a                	mv	s0,a0
        intr_disable();
ffffffffc0200f82:	cd8ff0ef          	jal	ffffffffc020045a <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0200f86:	00005797          	auipc	a5,0x5
ffffffffc0200f8a:	5f27b783          	ld	a5,1522(a5) # ffffffffc0206578 <pmm_manager>
ffffffffc0200f8e:	6f9c                	ld	a5,24(a5)
ffffffffc0200f90:	8522                	mv	a0,s0
ffffffffc0200f92:	9782                	jalr	a5
ffffffffc0200f94:	842a                	mv	s0,a0
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
        intr_enable();
ffffffffc0200f96:	cbeff0ef          	jal	ffffffffc0200454 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc0200f9a:	60a2                	ld	ra,8(sp)
ffffffffc0200f9c:	8522                	mv	a0,s0
ffffffffc0200f9e:	6402                	ld	s0,0(sp)
ffffffffc0200fa0:	0141                	addi	sp,sp,16
ffffffffc0200fa2:	8082                	ret

ffffffffc0200fa4 <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0200fa4:	100027f3          	csrr	a5,sstatus
ffffffffc0200fa8:	8b89                	andi	a5,a5,2
ffffffffc0200faa:	e799                	bnez	a5,ffffffffc0200fb8 <free_pages+0x14>
// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0200fac:	00005797          	auipc	a5,0x5
ffffffffc0200fb0:	5cc7b783          	ld	a5,1484(a5) # ffffffffc0206578 <pmm_manager>
ffffffffc0200fb4:	739c                	ld	a5,32(a5)
ffffffffc0200fb6:	8782                	jr	a5
void free_pages(struct Page *base, size_t n) {
ffffffffc0200fb8:	1101                	addi	sp,sp,-32
ffffffffc0200fba:	ec06                	sd	ra,24(sp)
ffffffffc0200fbc:	e822                	sd	s0,16(sp)
ffffffffc0200fbe:	e426                	sd	s1,8(sp)
ffffffffc0200fc0:	842a                	mv	s0,a0
ffffffffc0200fc2:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc0200fc4:	c96ff0ef          	jal	ffffffffc020045a <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0200fc8:	00005797          	auipc	a5,0x5
ffffffffc0200fcc:	5b07b783          	ld	a5,1456(a5) # ffffffffc0206578 <pmm_manager>
ffffffffc0200fd0:	739c                	ld	a5,32(a5)
ffffffffc0200fd2:	85a6                	mv	a1,s1
ffffffffc0200fd4:	8522                	mv	a0,s0
ffffffffc0200fd6:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0200fd8:	6442                	ld	s0,16(sp)
ffffffffc0200fda:	60e2                	ld	ra,24(sp)
ffffffffc0200fdc:	64a2                	ld	s1,8(sp)
ffffffffc0200fde:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0200fe0:	c74ff06f          	j	ffffffffc0200454 <intr_enable>

ffffffffc0200fe4 <pmm_init>:
    pmm_manager = &buddy_pmm_manager;//补充伙伴系统
ffffffffc0200fe4:	00001797          	auipc	a5,0x1
ffffffffc0200fe8:	3b478793          	addi	a5,a5,948 # ffffffffc0202398 <buddy_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200fec:	638c                	ld	a1,0(a5)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
    }
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc0200fee:	1101                	addi	sp,sp,-32
ffffffffc0200ff0:	ec06                	sd	ra,24(sp)
ffffffffc0200ff2:	e822                	sd	s0,16(sp)
ffffffffc0200ff4:	e426                	sd	s1,8(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200ff6:	00001517          	auipc	a0,0x1
ffffffffc0200ffa:	17a50513          	addi	a0,a0,378 # ffffffffc0202170 <etext+0xa80>
    pmm_manager = &buddy_pmm_manager;//补充伙伴系统
ffffffffc0200ffe:	00005497          	auipc	s1,0x5
ffffffffc0201002:	57a48493          	addi	s1,s1,1402 # ffffffffc0206578 <pmm_manager>
ffffffffc0201006:	e09c                	sd	a5,0(s1)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201008:	8aaff0ef          	jal	ffffffffc02000b2 <cprintf>
    pmm_manager->init();
ffffffffc020100c:	609c                	ld	a5,0(s1)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc020100e:	00005417          	auipc	s0,0x5
ffffffffc0201012:	58240413          	addi	s0,s0,1410 # ffffffffc0206590 <va_pa_offset>
    pmm_manager->init();
ffffffffc0201016:	679c                	ld	a5,8(a5)
ffffffffc0201018:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc020101a:	57f5                	li	a5,-3
ffffffffc020101c:	07fa                	slli	a5,a5,0x1e
    cprintf("physcial memory map:\n");
ffffffffc020101e:	00001517          	auipc	a0,0x1
ffffffffc0201022:	16a50513          	addi	a0,a0,362 # ffffffffc0202188 <etext+0xa98>
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0201026:	e01c                	sd	a5,0(s0)
    cprintf("physcial memory map:\n");
ffffffffc0201028:	88aff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc020102c:	46c5                	li	a3,17
ffffffffc020102e:	06ee                	slli	a3,a3,0x1b
ffffffffc0201030:	40100613          	li	a2,1025
ffffffffc0201034:	16fd                	addi	a3,a3,-1
ffffffffc0201036:	0656                	slli	a2,a2,0x15
ffffffffc0201038:	07e005b7          	lui	a1,0x7e00
ffffffffc020103c:	00001517          	auipc	a0,0x1
ffffffffc0201040:	16450513          	addi	a0,a0,356 # ffffffffc02021a0 <etext+0xab0>
ffffffffc0201044:	86eff0ef          	jal	ffffffffc02000b2 <cprintf>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0201048:	777d                	lui	a4,0xfffff
ffffffffc020104a:	00006797          	auipc	a5,0x6
ffffffffc020104e:	56578793          	addi	a5,a5,1381 # ffffffffc02075af <end+0xfff>
ffffffffc0201052:	8ff9                	and	a5,a5,a4
    npage = maxpa / PGSIZE;
ffffffffc0201054:	00005517          	auipc	a0,0x5
ffffffffc0201058:	54450513          	addi	a0,a0,1348 # ffffffffc0206598 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc020105c:	00005597          	auipc	a1,0x5
ffffffffc0201060:	54458593          	addi	a1,a1,1348 # ffffffffc02065a0 <pages>
    npage = maxpa / PGSIZE;
ffffffffc0201064:	00088737          	lui	a4,0x88
ffffffffc0201068:	e118                	sd	a4,0(a0)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc020106a:	e19c                	sd	a5,0(a1)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc020106c:	4705                	li	a4,1
ffffffffc020106e:	07a1                	addi	a5,a5,8
ffffffffc0201070:	40e7b02f          	amoor.d	zero,a4,(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0201074:	02800693          	li	a3,40
ffffffffc0201078:	4885                	li	a7,1
ffffffffc020107a:	fff80837          	lui	a6,0xfff80
        SetPageReserved(pages + i);
ffffffffc020107e:	619c                	ld	a5,0(a1)
ffffffffc0201080:	97b6                	add	a5,a5,a3
ffffffffc0201082:	07a1                	addi	a5,a5,8
ffffffffc0201084:	4117b02f          	amoor.d	zero,a7,(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0201088:	611c                	ld	a5,0(a0)
ffffffffc020108a:	0705                	addi	a4,a4,1 # 88001 <kern_entry-0xffffffffc0177fff>
ffffffffc020108c:	02868693          	addi	a3,a3,40
ffffffffc0201090:	01078633          	add	a2,a5,a6
ffffffffc0201094:	fec765e3          	bltu	a4,a2,ffffffffc020107e <pmm_init+0x9a>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201098:	6190                	ld	a2,0(a1)
ffffffffc020109a:	00279693          	slli	a3,a5,0x2
ffffffffc020109e:	96be                	add	a3,a3,a5
ffffffffc02010a0:	fec00737          	lui	a4,0xfec00
ffffffffc02010a4:	9732                	add	a4,a4,a2
ffffffffc02010a6:	068e                	slli	a3,a3,0x3
ffffffffc02010a8:	96ba                	add	a3,a3,a4
ffffffffc02010aa:	c0200737          	lui	a4,0xc0200
ffffffffc02010ae:	0ae6e463          	bltu	a3,a4,ffffffffc0201156 <pmm_init+0x172>
ffffffffc02010b2:	6018                	ld	a4,0(s0)
    if (freemem < mem_end) {
ffffffffc02010b4:	45c5                	li	a1,17
ffffffffc02010b6:	05ee                	slli	a1,a1,0x1b
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02010b8:	8e99                	sub	a3,a3,a4
    if (freemem < mem_end) {
ffffffffc02010ba:	04b6e963          	bltu	a3,a1,ffffffffc020110c <pmm_init+0x128>
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc02010be:	609c                	ld	a5,0(s1)
ffffffffc02010c0:	7b9c                	ld	a5,48(a5)
ffffffffc02010c2:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc02010c4:	00001517          	auipc	a0,0x1
ffffffffc02010c8:	14450513          	addi	a0,a0,324 # ffffffffc0202208 <etext+0xb18>
ffffffffc02010cc:	fe7fe0ef          	jal	ffffffffc02000b2 <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc02010d0:	00004597          	auipc	a1,0x4
ffffffffc02010d4:	f3058593          	addi	a1,a1,-208 # ffffffffc0205000 <boot_page_table_sv39>
ffffffffc02010d8:	00005797          	auipc	a5,0x5
ffffffffc02010dc:	4ab7b823          	sd	a1,1200(a5) # ffffffffc0206588 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc02010e0:	c02007b7          	lui	a5,0xc0200
ffffffffc02010e4:	08f5e563          	bltu	a1,a5,ffffffffc020116e <pmm_init+0x18a>
ffffffffc02010e8:	601c                	ld	a5,0(s0)
}
ffffffffc02010ea:	6442                	ld	s0,16(sp)
ffffffffc02010ec:	60e2                	ld	ra,24(sp)
ffffffffc02010ee:	64a2                	ld	s1,8(sp)
    satp_physical = PADDR(satp_virtual);
ffffffffc02010f0:	40f586b3          	sub	a3,a1,a5
ffffffffc02010f4:	00005797          	auipc	a5,0x5
ffffffffc02010f8:	48d7b623          	sd	a3,1164(a5) # ffffffffc0206580 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc02010fc:	00001517          	auipc	a0,0x1
ffffffffc0201100:	12c50513          	addi	a0,a0,300 # ffffffffc0202228 <etext+0xb38>
ffffffffc0201104:	8636                	mv	a2,a3
}
ffffffffc0201106:	6105                	addi	sp,sp,32
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0201108:	fabfe06f          	j	ffffffffc02000b2 <cprintf>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc020110c:	6705                	lui	a4,0x1
ffffffffc020110e:	177d                	addi	a4,a4,-1 # fff <kern_entry-0xffffffffc01ff001>
ffffffffc0201110:	96ba                	add	a3,a3,a4
ffffffffc0201112:	777d                	lui	a4,0xfffff
ffffffffc0201114:	8ef9                	and	a3,a3,a4
    if (PPN(pa) >= npage) {
ffffffffc0201116:	00c6d713          	srli	a4,a3,0xc
ffffffffc020111a:	02f77263          	bgeu	a4,a5,ffffffffc020113e <pmm_init+0x15a>
    pmm_manager->init_memmap(base, n);
ffffffffc020111e:	0004b803          	ld	a6,0(s1)
    return &pages[PPN(pa) - nbase];
ffffffffc0201122:	fff807b7          	lui	a5,0xfff80
ffffffffc0201126:	97ba                	add	a5,a5,a4
ffffffffc0201128:	00279513          	slli	a0,a5,0x2
ffffffffc020112c:	953e                	add	a0,a0,a5
ffffffffc020112e:	01083783          	ld	a5,16(a6) # fffffffffff80010 <end+0x3fd79a60>
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0201132:	8d95                	sub	a1,a1,a3
ffffffffc0201134:	050e                	slli	a0,a0,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc0201136:	81b1                	srli	a1,a1,0xc
ffffffffc0201138:	9532                	add	a0,a0,a2
ffffffffc020113a:	9782                	jalr	a5
}
ffffffffc020113c:	b749                	j	ffffffffc02010be <pmm_init+0xda>
        panic("pa2page called with invalid pa");
ffffffffc020113e:	00001617          	auipc	a2,0x1
ffffffffc0201142:	db260613          	addi	a2,a2,-590 # ffffffffc0201ef0 <etext+0x800>
ffffffffc0201146:	06b00593          	li	a1,107
ffffffffc020114a:	00001517          	auipc	a0,0x1
ffffffffc020114e:	dc650513          	addi	a0,a0,-570 # ffffffffc0201f10 <etext+0x820>
ffffffffc0201152:	a54ff0ef          	jal	ffffffffc02003a6 <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201156:	00001617          	auipc	a2,0x1
ffffffffc020115a:	07a60613          	addi	a2,a2,122 # ffffffffc02021d0 <etext+0xae0>
ffffffffc020115e:	07200593          	li	a1,114
ffffffffc0201162:	00001517          	auipc	a0,0x1
ffffffffc0201166:	09650513          	addi	a0,a0,150 # ffffffffc02021f8 <etext+0xb08>
ffffffffc020116a:	a3cff0ef          	jal	ffffffffc02003a6 <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc020116e:	86ae                	mv	a3,a1
ffffffffc0201170:	00001617          	auipc	a2,0x1
ffffffffc0201174:	06060613          	addi	a2,a2,96 # ffffffffc02021d0 <etext+0xae0>
ffffffffc0201178:	08d00593          	li	a1,141
ffffffffc020117c:	00001517          	auipc	a0,0x1
ffffffffc0201180:	07c50513          	addi	a0,a0,124 # ffffffffc02021f8 <etext+0xb08>
ffffffffc0201184:	a22ff0ef          	jal	ffffffffc02003a6 <__panic>

ffffffffc0201188 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0201188:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020118c:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc020118e:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201192:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0201194:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201198:	f022                	sd	s0,32(sp)
ffffffffc020119a:	ec26                	sd	s1,24(sp)
ffffffffc020119c:	e84a                	sd	s2,16(sp)
ffffffffc020119e:	f406                	sd	ra,40(sp)
ffffffffc02011a0:	84aa                	mv	s1,a0
ffffffffc02011a2:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc02011a4:	fff7041b          	addiw	s0,a4,-1 # ffffffffffffefff <end+0x3fdf8a4f>
    unsigned mod = do_div(result, base);
ffffffffc02011a8:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc02011aa:	05067063          	bgeu	a2,a6,ffffffffc02011ea <printnum+0x62>
ffffffffc02011ae:	e44e                	sd	s3,8(sp)
ffffffffc02011b0:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc02011b2:	4785                	li	a5,1
ffffffffc02011b4:	00e7d763          	bge	a5,a4,ffffffffc02011c2 <printnum+0x3a>
            putch(padc, putdat);
ffffffffc02011b8:	85ca                	mv	a1,s2
ffffffffc02011ba:	854e                	mv	a0,s3
        while (-- width > 0)
ffffffffc02011bc:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc02011be:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc02011c0:	fc65                	bnez	s0,ffffffffc02011b8 <printnum+0x30>
ffffffffc02011c2:	69a2                	ld	s3,8(sp)
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02011c4:	1a02                	slli	s4,s4,0x20
ffffffffc02011c6:	020a5a13          	srli	s4,s4,0x20
ffffffffc02011ca:	00001797          	auipc	a5,0x1
ffffffffc02011ce:	09e78793          	addi	a5,a5,158 # ffffffffc0202268 <etext+0xb78>
ffffffffc02011d2:	97d2                	add	a5,a5,s4
}
ffffffffc02011d4:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02011d6:	0007c503          	lbu	a0,0(a5)
}
ffffffffc02011da:	70a2                	ld	ra,40(sp)
ffffffffc02011dc:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02011de:	85ca                	mv	a1,s2
ffffffffc02011e0:	87a6                	mv	a5,s1
}
ffffffffc02011e2:	6942                	ld	s2,16(sp)
ffffffffc02011e4:	64e2                	ld	s1,24(sp)
ffffffffc02011e6:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02011e8:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc02011ea:	03065633          	divu	a2,a2,a6
ffffffffc02011ee:	8722                	mv	a4,s0
ffffffffc02011f0:	f99ff0ef          	jal	ffffffffc0201188 <printnum>
ffffffffc02011f4:	bfc1                	j	ffffffffc02011c4 <printnum+0x3c>

ffffffffc02011f6 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc02011f6:	7119                	addi	sp,sp,-128
ffffffffc02011f8:	f4a6                	sd	s1,104(sp)
ffffffffc02011fa:	f0ca                	sd	s2,96(sp)
ffffffffc02011fc:	ecce                	sd	s3,88(sp)
ffffffffc02011fe:	e8d2                	sd	s4,80(sp)
ffffffffc0201200:	e4d6                	sd	s5,72(sp)
ffffffffc0201202:	e0da                	sd	s6,64(sp)
ffffffffc0201204:	f862                	sd	s8,48(sp)
ffffffffc0201206:	fc86                	sd	ra,120(sp)
ffffffffc0201208:	f8a2                	sd	s0,112(sp)
ffffffffc020120a:	fc5e                	sd	s7,56(sp)
ffffffffc020120c:	f466                	sd	s9,40(sp)
ffffffffc020120e:	f06a                	sd	s10,32(sp)
ffffffffc0201210:	ec6e                	sd	s11,24(sp)
ffffffffc0201212:	892a                	mv	s2,a0
ffffffffc0201214:	84ae                	mv	s1,a1
ffffffffc0201216:	8c32                	mv	s8,a2
ffffffffc0201218:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020121a:	02500993          	li	s3,37
        char padc = ' ';
        width = precision = -1;
        lflag = altflag = 0;

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020121e:	05500b13          	li	s6,85
ffffffffc0201222:	00001a97          	auipc	s5,0x1
ffffffffc0201226:	1aea8a93          	addi	s5,s5,430 # ffffffffc02023d0 <buddy_pmm_manager+0x38>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020122a:	000c4503          	lbu	a0,0(s8)
ffffffffc020122e:	001c0413          	addi	s0,s8,1
ffffffffc0201232:	01350a63          	beq	a0,s3,ffffffffc0201246 <vprintfmt+0x50>
            if (ch == '\0') {
ffffffffc0201236:	cd0d                	beqz	a0,ffffffffc0201270 <vprintfmt+0x7a>
            putch(ch, putdat);
ffffffffc0201238:	85a6                	mv	a1,s1
ffffffffc020123a:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020123c:	00044503          	lbu	a0,0(s0)
ffffffffc0201240:	0405                	addi	s0,s0,1
ffffffffc0201242:	ff351ae3          	bne	a0,s3,ffffffffc0201236 <vprintfmt+0x40>
        char padc = ' ';
ffffffffc0201246:	02000d93          	li	s11,32
        lflag = altflag = 0;
ffffffffc020124a:	4b81                	li	s7,0
ffffffffc020124c:	4601                	li	a2,0
        width = precision = -1;
ffffffffc020124e:	5d7d                	li	s10,-1
ffffffffc0201250:	5cfd                	li	s9,-1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201252:	00044683          	lbu	a3,0(s0)
ffffffffc0201256:	00140c13          	addi	s8,s0,1
ffffffffc020125a:	fdd6859b          	addiw	a1,a3,-35
ffffffffc020125e:	0ff5f593          	zext.b	a1,a1
ffffffffc0201262:	02bb6663          	bltu	s6,a1,ffffffffc020128e <vprintfmt+0x98>
ffffffffc0201266:	058a                	slli	a1,a1,0x2
ffffffffc0201268:	95d6                	add	a1,a1,s5
ffffffffc020126a:	4198                	lw	a4,0(a1)
ffffffffc020126c:	9756                	add	a4,a4,s5
ffffffffc020126e:	8702                	jr	a4
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0201270:	70e6                	ld	ra,120(sp)
ffffffffc0201272:	7446                	ld	s0,112(sp)
ffffffffc0201274:	74a6                	ld	s1,104(sp)
ffffffffc0201276:	7906                	ld	s2,96(sp)
ffffffffc0201278:	69e6                	ld	s3,88(sp)
ffffffffc020127a:	6a46                	ld	s4,80(sp)
ffffffffc020127c:	6aa6                	ld	s5,72(sp)
ffffffffc020127e:	6b06                	ld	s6,64(sp)
ffffffffc0201280:	7be2                	ld	s7,56(sp)
ffffffffc0201282:	7c42                	ld	s8,48(sp)
ffffffffc0201284:	7ca2                	ld	s9,40(sp)
ffffffffc0201286:	7d02                	ld	s10,32(sp)
ffffffffc0201288:	6de2                	ld	s11,24(sp)
ffffffffc020128a:	6109                	addi	sp,sp,128
ffffffffc020128c:	8082                	ret
            putch('%', putdat);
ffffffffc020128e:	85a6                	mv	a1,s1
ffffffffc0201290:	02500513          	li	a0,37
ffffffffc0201294:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0201296:	fff44703          	lbu	a4,-1(s0)
ffffffffc020129a:	02500793          	li	a5,37
ffffffffc020129e:	8c22                	mv	s8,s0
ffffffffc02012a0:	f8f705e3          	beq	a4,a5,ffffffffc020122a <vprintfmt+0x34>
ffffffffc02012a4:	02500713          	li	a4,37
ffffffffc02012a8:	ffec4783          	lbu	a5,-2(s8)
ffffffffc02012ac:	1c7d                	addi	s8,s8,-1
ffffffffc02012ae:	fee79de3          	bne	a5,a4,ffffffffc02012a8 <vprintfmt+0xb2>
ffffffffc02012b2:	bfa5                	j	ffffffffc020122a <vprintfmt+0x34>
                ch = *fmt;
ffffffffc02012b4:	00144783          	lbu	a5,1(s0)
                if (ch < '0' || ch > '9') {
ffffffffc02012b8:	4725                	li	a4,9
                precision = precision * 10 + ch - '0';
ffffffffc02012ba:	fd068d1b          	addiw	s10,a3,-48
                if (ch < '0' || ch > '9') {
ffffffffc02012be:	fd07859b          	addiw	a1,a5,-48
                ch = *fmt;
ffffffffc02012c2:	0007869b          	sext.w	a3,a5
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02012c6:	8462                	mv	s0,s8
                if (ch < '0' || ch > '9') {
ffffffffc02012c8:	02b76563          	bltu	a4,a1,ffffffffc02012f2 <vprintfmt+0xfc>
ffffffffc02012cc:	4525                	li	a0,9
                ch = *fmt;
ffffffffc02012ce:	00144783          	lbu	a5,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc02012d2:	002d171b          	slliw	a4,s10,0x2
ffffffffc02012d6:	01a7073b          	addw	a4,a4,s10
ffffffffc02012da:	0017171b          	slliw	a4,a4,0x1
ffffffffc02012de:	9f35                	addw	a4,a4,a3
                if (ch < '0' || ch > '9') {
ffffffffc02012e0:	fd07859b          	addiw	a1,a5,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc02012e4:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc02012e6:	fd070d1b          	addiw	s10,a4,-48
                ch = *fmt;
ffffffffc02012ea:	0007869b          	sext.w	a3,a5
                if (ch < '0' || ch > '9') {
ffffffffc02012ee:	feb570e3          	bgeu	a0,a1,ffffffffc02012ce <vprintfmt+0xd8>
            if (width < 0)
ffffffffc02012f2:	f60cd0e3          	bgez	s9,ffffffffc0201252 <vprintfmt+0x5c>
                width = precision, precision = -1;
ffffffffc02012f6:	8cea                	mv	s9,s10
ffffffffc02012f8:	5d7d                	li	s10,-1
ffffffffc02012fa:	bfa1                	j	ffffffffc0201252 <vprintfmt+0x5c>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02012fc:	8db6                	mv	s11,a3
ffffffffc02012fe:	8462                	mv	s0,s8
ffffffffc0201300:	bf89                	j	ffffffffc0201252 <vprintfmt+0x5c>
ffffffffc0201302:	8462                	mv	s0,s8
            altflag = 1;
ffffffffc0201304:	4b85                	li	s7,1
            goto reswitch;
ffffffffc0201306:	b7b1                	j	ffffffffc0201252 <vprintfmt+0x5c>
    if (lflag >= 2) {
ffffffffc0201308:	4785                	li	a5,1
            precision = va_arg(ap, int);
ffffffffc020130a:	008a0713          	addi	a4,s4,8
    if (lflag >= 2) {
ffffffffc020130e:	00c7c463          	blt	a5,a2,ffffffffc0201316 <vprintfmt+0x120>
    else if (lflag) {
ffffffffc0201312:	1a060163          	beqz	a2,ffffffffc02014b4 <vprintfmt+0x2be>
        return va_arg(*ap, unsigned long);
ffffffffc0201316:	000a3603          	ld	a2,0(s4)
ffffffffc020131a:	46c1                	li	a3,16
ffffffffc020131c:	8a3a                	mv	s4,a4
            printnum(putch, putdat, num, base, width, padc);
ffffffffc020131e:	000d879b          	sext.w	a5,s11
ffffffffc0201322:	8766                	mv	a4,s9
ffffffffc0201324:	85a6                	mv	a1,s1
ffffffffc0201326:	854a                	mv	a0,s2
ffffffffc0201328:	e61ff0ef          	jal	ffffffffc0201188 <printnum>
            break;
ffffffffc020132c:	bdfd                	j	ffffffffc020122a <vprintfmt+0x34>
            putch(va_arg(ap, int), putdat);
ffffffffc020132e:	000a2503          	lw	a0,0(s4)
ffffffffc0201332:	85a6                	mv	a1,s1
ffffffffc0201334:	0a21                	addi	s4,s4,8
ffffffffc0201336:	9902                	jalr	s2
            break;
ffffffffc0201338:	bdcd                	j	ffffffffc020122a <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc020133a:	4785                	li	a5,1
            precision = va_arg(ap, int);
ffffffffc020133c:	008a0713          	addi	a4,s4,8
    if (lflag >= 2) {
ffffffffc0201340:	00c7c463          	blt	a5,a2,ffffffffc0201348 <vprintfmt+0x152>
    else if (lflag) {
ffffffffc0201344:	16060363          	beqz	a2,ffffffffc02014aa <vprintfmt+0x2b4>
        return va_arg(*ap, unsigned long);
ffffffffc0201348:	000a3603          	ld	a2,0(s4)
ffffffffc020134c:	46a9                	li	a3,10
ffffffffc020134e:	8a3a                	mv	s4,a4
ffffffffc0201350:	b7f9                	j	ffffffffc020131e <vprintfmt+0x128>
            putch('0', putdat);
ffffffffc0201352:	85a6                	mv	a1,s1
ffffffffc0201354:	03000513          	li	a0,48
ffffffffc0201358:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc020135a:	85a6                	mv	a1,s1
ffffffffc020135c:	07800513          	li	a0,120
ffffffffc0201360:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201362:	000a3603          	ld	a2,0(s4)
            goto number;
ffffffffc0201366:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201368:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc020136a:	bf55                	j	ffffffffc020131e <vprintfmt+0x128>
            putch(ch, putdat);
ffffffffc020136c:	85a6                	mv	a1,s1
ffffffffc020136e:	02500513          	li	a0,37
ffffffffc0201372:	9902                	jalr	s2
            break;
ffffffffc0201374:	bd5d                	j	ffffffffc020122a <vprintfmt+0x34>
            precision = va_arg(ap, int);
ffffffffc0201376:	000a2d03          	lw	s10,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020137a:	8462                	mv	s0,s8
            precision = va_arg(ap, int);
ffffffffc020137c:	0a21                	addi	s4,s4,8
            goto process_precision;
ffffffffc020137e:	bf95                	j	ffffffffc02012f2 <vprintfmt+0xfc>
    if (lflag >= 2) {
ffffffffc0201380:	4785                	li	a5,1
            precision = va_arg(ap, int);
ffffffffc0201382:	008a0713          	addi	a4,s4,8
    if (lflag >= 2) {
ffffffffc0201386:	00c7c463          	blt	a5,a2,ffffffffc020138e <vprintfmt+0x198>
    else if (lflag) {
ffffffffc020138a:	10060b63          	beqz	a2,ffffffffc02014a0 <vprintfmt+0x2aa>
        return va_arg(*ap, unsigned long);
ffffffffc020138e:	000a3603          	ld	a2,0(s4)
ffffffffc0201392:	46a1                	li	a3,8
ffffffffc0201394:	8a3a                	mv	s4,a4
ffffffffc0201396:	b761                	j	ffffffffc020131e <vprintfmt+0x128>
            if (width < 0)
ffffffffc0201398:	fffcc793          	not	a5,s9
ffffffffc020139c:	97fd                	srai	a5,a5,0x3f
ffffffffc020139e:	00fcf7b3          	and	a5,s9,a5
ffffffffc02013a2:	00078c9b          	sext.w	s9,a5
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02013a6:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc02013a8:	b56d                	j	ffffffffc0201252 <vprintfmt+0x5c>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02013aa:	000a3403          	ld	s0,0(s4)
ffffffffc02013ae:	008a0793          	addi	a5,s4,8
ffffffffc02013b2:	e43e                	sd	a5,8(sp)
ffffffffc02013b4:	12040063          	beqz	s0,ffffffffc02014d4 <vprintfmt+0x2de>
            if (width > 0 && padc != '-') {
ffffffffc02013b8:	0d905963          	blez	s9,ffffffffc020148a <vprintfmt+0x294>
ffffffffc02013bc:	02d00793          	li	a5,45
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02013c0:	00140a13          	addi	s4,s0,1
            if (width > 0 && padc != '-') {
ffffffffc02013c4:	12fd9763          	bne	s11,a5,ffffffffc02014f2 <vprintfmt+0x2fc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02013c8:	00044783          	lbu	a5,0(s0)
ffffffffc02013cc:	0007851b          	sext.w	a0,a5
ffffffffc02013d0:	cb9d                	beqz	a5,ffffffffc0201406 <vprintfmt+0x210>
ffffffffc02013d2:	547d                	li	s0,-1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02013d4:	05e00d93          	li	s11,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02013d8:	000d4563          	bltz	s10,ffffffffc02013e2 <vprintfmt+0x1ec>
ffffffffc02013dc:	3d7d                	addiw	s10,s10,-1
ffffffffc02013de:	028d0263          	beq	s10,s0,ffffffffc0201402 <vprintfmt+0x20c>
                    putch('?', putdat);
ffffffffc02013e2:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02013e4:	0c0b8d63          	beqz	s7,ffffffffc02014be <vprintfmt+0x2c8>
ffffffffc02013e8:	3781                	addiw	a5,a5,-32
ffffffffc02013ea:	0cfdfa63          	bgeu	s11,a5,ffffffffc02014be <vprintfmt+0x2c8>
                    putch('?', putdat);
ffffffffc02013ee:	03f00513          	li	a0,63
ffffffffc02013f2:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02013f4:	000a4783          	lbu	a5,0(s4)
ffffffffc02013f8:	3cfd                	addiw	s9,s9,-1
ffffffffc02013fa:	0a05                	addi	s4,s4,1
ffffffffc02013fc:	0007851b          	sext.w	a0,a5
ffffffffc0201400:	ffe1                	bnez	a5,ffffffffc02013d8 <vprintfmt+0x1e2>
            for (; width > 0; width --) {
ffffffffc0201402:	01905963          	blez	s9,ffffffffc0201414 <vprintfmt+0x21e>
                putch(' ', putdat);
ffffffffc0201406:	85a6                	mv	a1,s1
ffffffffc0201408:	02000513          	li	a0,32
            for (; width > 0; width --) {
ffffffffc020140c:	3cfd                	addiw	s9,s9,-1
                putch(' ', putdat);
ffffffffc020140e:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0201410:	fe0c9be3          	bnez	s9,ffffffffc0201406 <vprintfmt+0x210>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201414:	6a22                	ld	s4,8(sp)
ffffffffc0201416:	bd11                	j	ffffffffc020122a <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc0201418:	4785                	li	a5,1
            precision = va_arg(ap, int);
ffffffffc020141a:	008a0b93          	addi	s7,s4,8
    if (lflag >= 2) {
ffffffffc020141e:	00c7c363          	blt	a5,a2,ffffffffc0201424 <vprintfmt+0x22e>
    else if (lflag) {
ffffffffc0201422:	ce25                	beqz	a2,ffffffffc020149a <vprintfmt+0x2a4>
        return va_arg(*ap, long);
ffffffffc0201424:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0201428:	08044d63          	bltz	s0,ffffffffc02014c2 <vprintfmt+0x2cc>
            num = getint(&ap, lflag);
ffffffffc020142c:	8622                	mv	a2,s0
ffffffffc020142e:	8a5e                	mv	s4,s7
ffffffffc0201430:	46a9                	li	a3,10
ffffffffc0201432:	b5f5                	j	ffffffffc020131e <vprintfmt+0x128>
            if (err < 0) {
ffffffffc0201434:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201438:	4619                	li	a2,6
            if (err < 0) {
ffffffffc020143a:	41f7d71b          	sraiw	a4,a5,0x1f
ffffffffc020143e:	8fb9                	xor	a5,a5,a4
ffffffffc0201440:	40e786bb          	subw	a3,a5,a4
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201444:	02d64663          	blt	a2,a3,ffffffffc0201470 <vprintfmt+0x27a>
ffffffffc0201448:	00369713          	slli	a4,a3,0x3
ffffffffc020144c:	00001797          	auipc	a5,0x1
ffffffffc0201450:	0dc78793          	addi	a5,a5,220 # ffffffffc0202528 <error_string>
ffffffffc0201454:	97ba                	add	a5,a5,a4
ffffffffc0201456:	639c                	ld	a5,0(a5)
ffffffffc0201458:	cf81                	beqz	a5,ffffffffc0201470 <vprintfmt+0x27a>
                printfmt(putch, putdat, "%s", p);
ffffffffc020145a:	86be                	mv	a3,a5
ffffffffc020145c:	00001617          	auipc	a2,0x1
ffffffffc0201460:	e3c60613          	addi	a2,a2,-452 # ffffffffc0202298 <etext+0xba8>
ffffffffc0201464:	85a6                	mv	a1,s1
ffffffffc0201466:	854a                	mv	a0,s2
ffffffffc0201468:	0e8000ef          	jal	ffffffffc0201550 <printfmt>
            err = va_arg(ap, int);
ffffffffc020146c:	0a21                	addi	s4,s4,8
ffffffffc020146e:	bb75                	j	ffffffffc020122a <vprintfmt+0x34>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0201470:	00001617          	auipc	a2,0x1
ffffffffc0201474:	e1860613          	addi	a2,a2,-488 # ffffffffc0202288 <etext+0xb98>
ffffffffc0201478:	85a6                	mv	a1,s1
ffffffffc020147a:	854a                	mv	a0,s2
ffffffffc020147c:	0d4000ef          	jal	ffffffffc0201550 <printfmt>
            err = va_arg(ap, int);
ffffffffc0201480:	0a21                	addi	s4,s4,8
ffffffffc0201482:	b365                	j	ffffffffc020122a <vprintfmt+0x34>
            lflag ++;
ffffffffc0201484:	2605                	addiw	a2,a2,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201486:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc0201488:	b3e9                	j	ffffffffc0201252 <vprintfmt+0x5c>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020148a:	00044783          	lbu	a5,0(s0)
ffffffffc020148e:	0007851b          	sext.w	a0,a5
ffffffffc0201492:	d3c9                	beqz	a5,ffffffffc0201414 <vprintfmt+0x21e>
ffffffffc0201494:	00140a13          	addi	s4,s0,1
ffffffffc0201498:	bf2d                	j	ffffffffc02013d2 <vprintfmt+0x1dc>
        return va_arg(*ap, int);
ffffffffc020149a:	000a2403          	lw	s0,0(s4)
ffffffffc020149e:	b769                	j	ffffffffc0201428 <vprintfmt+0x232>
        return va_arg(*ap, unsigned int);
ffffffffc02014a0:	000a6603          	lwu	a2,0(s4)
ffffffffc02014a4:	46a1                	li	a3,8
ffffffffc02014a6:	8a3a                	mv	s4,a4
ffffffffc02014a8:	bd9d                	j	ffffffffc020131e <vprintfmt+0x128>
ffffffffc02014aa:	000a6603          	lwu	a2,0(s4)
ffffffffc02014ae:	46a9                	li	a3,10
ffffffffc02014b0:	8a3a                	mv	s4,a4
ffffffffc02014b2:	b5b5                	j	ffffffffc020131e <vprintfmt+0x128>
ffffffffc02014b4:	000a6603          	lwu	a2,0(s4)
ffffffffc02014b8:	46c1                	li	a3,16
ffffffffc02014ba:	8a3a                	mv	s4,a4
ffffffffc02014bc:	b58d                	j	ffffffffc020131e <vprintfmt+0x128>
                    putch(ch, putdat);
ffffffffc02014be:	9902                	jalr	s2
ffffffffc02014c0:	bf15                	j	ffffffffc02013f4 <vprintfmt+0x1fe>
                putch('-', putdat);
ffffffffc02014c2:	85a6                	mv	a1,s1
ffffffffc02014c4:	02d00513          	li	a0,45
ffffffffc02014c8:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc02014ca:	40800633          	neg	a2,s0
ffffffffc02014ce:	8a5e                	mv	s4,s7
ffffffffc02014d0:	46a9                	li	a3,10
ffffffffc02014d2:	b5b1                	j	ffffffffc020131e <vprintfmt+0x128>
            if (width > 0 && padc != '-') {
ffffffffc02014d4:	01905663          	blez	s9,ffffffffc02014e0 <vprintfmt+0x2ea>
ffffffffc02014d8:	02d00793          	li	a5,45
ffffffffc02014dc:	04fd9263          	bne	s11,a5,ffffffffc0201520 <vprintfmt+0x32a>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02014e0:	02800793          	li	a5,40
ffffffffc02014e4:	00001a17          	auipc	s4,0x1
ffffffffc02014e8:	d9da0a13          	addi	s4,s4,-611 # ffffffffc0202281 <etext+0xb91>
ffffffffc02014ec:	02800513          	li	a0,40
ffffffffc02014f0:	b5cd                	j	ffffffffc02013d2 <vprintfmt+0x1dc>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02014f2:	85ea                	mv	a1,s10
ffffffffc02014f4:	8522                	mv	a0,s0
ffffffffc02014f6:	17e000ef          	jal	ffffffffc0201674 <strnlen>
ffffffffc02014fa:	40ac8cbb          	subw	s9,s9,a0
ffffffffc02014fe:	01905963          	blez	s9,ffffffffc0201510 <vprintfmt+0x31a>
                    putch(padc, putdat);
ffffffffc0201502:	2d81                	sext.w	s11,s11
ffffffffc0201504:	85a6                	mv	a1,s1
ffffffffc0201506:	856e                	mv	a0,s11
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201508:	3cfd                	addiw	s9,s9,-1
                    putch(padc, putdat);
ffffffffc020150a:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020150c:	fe0c9ce3          	bnez	s9,ffffffffc0201504 <vprintfmt+0x30e>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201510:	00044783          	lbu	a5,0(s0)
ffffffffc0201514:	0007851b          	sext.w	a0,a5
ffffffffc0201518:	ea079de3          	bnez	a5,ffffffffc02013d2 <vprintfmt+0x1dc>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc020151c:	6a22                	ld	s4,8(sp)
ffffffffc020151e:	b331                	j	ffffffffc020122a <vprintfmt+0x34>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201520:	85ea                	mv	a1,s10
ffffffffc0201522:	00001517          	auipc	a0,0x1
ffffffffc0201526:	d5e50513          	addi	a0,a0,-674 # ffffffffc0202280 <etext+0xb90>
ffffffffc020152a:	14a000ef          	jal	ffffffffc0201674 <strnlen>
ffffffffc020152e:	40ac8cbb          	subw	s9,s9,a0
                p = "(null)";
ffffffffc0201532:	00001417          	auipc	s0,0x1
ffffffffc0201536:	d4e40413          	addi	s0,s0,-690 # ffffffffc0202280 <etext+0xb90>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020153a:	00001a17          	auipc	s4,0x1
ffffffffc020153e:	d47a0a13          	addi	s4,s4,-697 # ffffffffc0202281 <etext+0xb91>
ffffffffc0201542:	02800793          	li	a5,40
ffffffffc0201546:	02800513          	li	a0,40
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020154a:	fb904ce3          	bgtz	s9,ffffffffc0201502 <vprintfmt+0x30c>
ffffffffc020154e:	b551                	j	ffffffffc02013d2 <vprintfmt+0x1dc>

ffffffffc0201550 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201550:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0201552:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201556:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201558:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc020155a:	ec06                	sd	ra,24(sp)
ffffffffc020155c:	f83a                	sd	a4,48(sp)
ffffffffc020155e:	fc3e                	sd	a5,56(sp)
ffffffffc0201560:	e0c2                	sd	a6,64(sp)
ffffffffc0201562:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0201564:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201566:	c91ff0ef          	jal	ffffffffc02011f6 <vprintfmt>
}
ffffffffc020156a:	60e2                	ld	ra,24(sp)
ffffffffc020156c:	6161                	addi	sp,sp,80
ffffffffc020156e:	8082                	ret

ffffffffc0201570 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc0201570:	715d                	addi	sp,sp,-80
ffffffffc0201572:	e486                	sd	ra,72(sp)
ffffffffc0201574:	e0a2                	sd	s0,64(sp)
ffffffffc0201576:	fc26                	sd	s1,56(sp)
ffffffffc0201578:	f84a                	sd	s2,48(sp)
ffffffffc020157a:	f44e                	sd	s3,40(sp)
ffffffffc020157c:	f052                	sd	s4,32(sp)
ffffffffc020157e:	ec56                	sd	s5,24(sp)
ffffffffc0201580:	e85a                	sd	s6,16(sp)
    if (prompt != NULL) {
ffffffffc0201582:	c901                	beqz	a0,ffffffffc0201592 <readline+0x22>
ffffffffc0201584:	85aa                	mv	a1,a0
        cprintf("%s", prompt);
ffffffffc0201586:	00001517          	auipc	a0,0x1
ffffffffc020158a:	d1250513          	addi	a0,a0,-750 # ffffffffc0202298 <etext+0xba8>
ffffffffc020158e:	b25fe0ef          	jal	ffffffffc02000b2 <cprintf>
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
            cputchar(c);
            buf[i ++] = c;
ffffffffc0201592:	4401                	li	s0,0
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201594:	44fd                	li	s1,31
        }
        else if (c == '\b' && i > 0) {
ffffffffc0201596:	4921                	li	s2,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc0201598:	4a29                	li	s4,10
ffffffffc020159a:	4ab5                	li	s5,13
            buf[i ++] = c;
ffffffffc020159c:	00005b17          	auipc	s6,0x5
ffffffffc02015a0:	bccb0b13          	addi	s6,s6,-1076 # ffffffffc0206168 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02015a4:	3fe00993          	li	s3,1022
        c = getchar();
ffffffffc02015a8:	b8ffe0ef          	jal	ffffffffc0200136 <getchar>
        if (c < 0) {
ffffffffc02015ac:	00054a63          	bltz	a0,ffffffffc02015c0 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02015b0:	00a4da63          	bge	s1,a0,ffffffffc02015c4 <readline+0x54>
ffffffffc02015b4:	0289d263          	bge	s3,s0,ffffffffc02015d8 <readline+0x68>
        c = getchar();
ffffffffc02015b8:	b7ffe0ef          	jal	ffffffffc0200136 <getchar>
        if (c < 0) {
ffffffffc02015bc:	fe055ae3          	bgez	a0,ffffffffc02015b0 <readline+0x40>
            return NULL;
ffffffffc02015c0:	4501                	li	a0,0
ffffffffc02015c2:	a091                	j	ffffffffc0201606 <readline+0x96>
        else if (c == '\b' && i > 0) {
ffffffffc02015c4:	03251463          	bne	a0,s2,ffffffffc02015ec <readline+0x7c>
ffffffffc02015c8:	04804963          	bgtz	s0,ffffffffc020161a <readline+0xaa>
        c = getchar();
ffffffffc02015cc:	b6bfe0ef          	jal	ffffffffc0200136 <getchar>
        if (c < 0) {
ffffffffc02015d0:	fe0548e3          	bltz	a0,ffffffffc02015c0 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02015d4:	fea4d8e3          	bge	s1,a0,ffffffffc02015c4 <readline+0x54>
            cputchar(c);
ffffffffc02015d8:	e42a                	sd	a0,8(sp)
ffffffffc02015da:	b0dfe0ef          	jal	ffffffffc02000e6 <cputchar>
            buf[i ++] = c;
ffffffffc02015de:	6522                	ld	a0,8(sp)
ffffffffc02015e0:	008b07b3          	add	a5,s6,s0
ffffffffc02015e4:	2405                	addiw	s0,s0,1
ffffffffc02015e6:	00a78023          	sb	a0,0(a5)
ffffffffc02015ea:	bf7d                	j	ffffffffc02015a8 <readline+0x38>
        else if (c == '\n' || c == '\r') {
ffffffffc02015ec:	01450463          	beq	a0,s4,ffffffffc02015f4 <readline+0x84>
ffffffffc02015f0:	fb551ce3          	bne	a0,s5,ffffffffc02015a8 <readline+0x38>
            cputchar(c);
ffffffffc02015f4:	af3fe0ef          	jal	ffffffffc02000e6 <cputchar>
            buf[i] = '\0';
ffffffffc02015f8:	00005517          	auipc	a0,0x5
ffffffffc02015fc:	b7050513          	addi	a0,a0,-1168 # ffffffffc0206168 <buf>
ffffffffc0201600:	942a                	add	s0,s0,a0
ffffffffc0201602:	00040023          	sb	zero,0(s0)
            return buf;
        }
    }
}
ffffffffc0201606:	60a6                	ld	ra,72(sp)
ffffffffc0201608:	6406                	ld	s0,64(sp)
ffffffffc020160a:	74e2                	ld	s1,56(sp)
ffffffffc020160c:	7942                	ld	s2,48(sp)
ffffffffc020160e:	79a2                	ld	s3,40(sp)
ffffffffc0201610:	7a02                	ld	s4,32(sp)
ffffffffc0201612:	6ae2                	ld	s5,24(sp)
ffffffffc0201614:	6b42                	ld	s6,16(sp)
ffffffffc0201616:	6161                	addi	sp,sp,80
ffffffffc0201618:	8082                	ret
            cputchar(c);
ffffffffc020161a:	4521                	li	a0,8
ffffffffc020161c:	acbfe0ef          	jal	ffffffffc02000e6 <cputchar>
            i --;
ffffffffc0201620:	347d                	addiw	s0,s0,-1
ffffffffc0201622:	b759                	j	ffffffffc02015a8 <readline+0x38>

ffffffffc0201624 <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
ffffffffc0201624:	4781                	li	a5,0
ffffffffc0201626:	00005717          	auipc	a4,0x5
ffffffffc020162a:	9e273703          	ld	a4,-1566(a4) # ffffffffc0206008 <SBI_CONSOLE_PUTCHAR>
ffffffffc020162e:	88ba                	mv	a7,a4
ffffffffc0201630:	852a                	mv	a0,a0
ffffffffc0201632:	85be                	mv	a1,a5
ffffffffc0201634:	863e                	mv	a2,a5
ffffffffc0201636:	00000073          	ecall
ffffffffc020163a:	87aa                	mv	a5,a0
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc020163c:	8082                	ret

ffffffffc020163e <sbi_set_timer>:
    __asm__ volatile (
ffffffffc020163e:	4781                	li	a5,0
ffffffffc0201640:	00005717          	auipc	a4,0x5
ffffffffc0201644:	f6873703          	ld	a4,-152(a4) # ffffffffc02065a8 <SBI_SET_TIMER>
ffffffffc0201648:	88ba                	mv	a7,a4
ffffffffc020164a:	852a                	mv	a0,a0
ffffffffc020164c:	85be                	mv	a1,a5
ffffffffc020164e:	863e                	mv	a2,a5
ffffffffc0201650:	00000073          	ecall
ffffffffc0201654:	87aa                	mv	a5,a0

void sbi_set_timer(unsigned long long stime_value) {
    sbi_call(SBI_SET_TIMER, stime_value, 0, 0);
}
ffffffffc0201656:	8082                	ret

ffffffffc0201658 <sbi_console_getchar>:
    __asm__ volatile (
ffffffffc0201658:	4501                	li	a0,0
ffffffffc020165a:	00005797          	auipc	a5,0x5
ffffffffc020165e:	9a67b783          	ld	a5,-1626(a5) # ffffffffc0206000 <SBI_CONSOLE_GETCHAR>
ffffffffc0201662:	88be                	mv	a7,a5
ffffffffc0201664:	852a                	mv	a0,a0
ffffffffc0201666:	85aa                	mv	a1,a0
ffffffffc0201668:	862a                	mv	a2,a0
ffffffffc020166a:	00000073          	ecall
ffffffffc020166e:	852a                	mv	a0,a0

int sbi_console_getchar(void) {
    return sbi_call(SBI_CONSOLE_GETCHAR, 0, 0, 0);
ffffffffc0201670:	2501                	sext.w	a0,a0
ffffffffc0201672:	8082                	ret

ffffffffc0201674 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0201674:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201676:	e589                	bnez	a1,ffffffffc0201680 <strnlen+0xc>
ffffffffc0201678:	a811                	j	ffffffffc020168c <strnlen+0x18>
        cnt ++;
ffffffffc020167a:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc020167c:	00f58863          	beq	a1,a5,ffffffffc020168c <strnlen+0x18>
ffffffffc0201680:	00f50733          	add	a4,a0,a5
ffffffffc0201684:	00074703          	lbu	a4,0(a4)
ffffffffc0201688:	fb6d                	bnez	a4,ffffffffc020167a <strnlen+0x6>
ffffffffc020168a:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc020168c:	852e                	mv	a0,a1
ffffffffc020168e:	8082                	ret

ffffffffc0201690 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201690:	00054783          	lbu	a5,0(a0)
ffffffffc0201694:	e791                	bnez	a5,ffffffffc02016a0 <strcmp+0x10>
ffffffffc0201696:	a02d                	j	ffffffffc02016c0 <strcmp+0x30>
ffffffffc0201698:	00054783          	lbu	a5,0(a0)
ffffffffc020169c:	cf89                	beqz	a5,ffffffffc02016b6 <strcmp+0x26>
ffffffffc020169e:	85b6                	mv	a1,a3
ffffffffc02016a0:	0005c703          	lbu	a4,0(a1)
        s1 ++, s2 ++;
ffffffffc02016a4:	0505                	addi	a0,a0,1
ffffffffc02016a6:	00158693          	addi	a3,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02016aa:	fef707e3          	beq	a4,a5,ffffffffc0201698 <strcmp+0x8>
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02016ae:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc02016b2:	9d19                	subw	a0,a0,a4
ffffffffc02016b4:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02016b6:	0015c703          	lbu	a4,1(a1)
ffffffffc02016ba:	4501                	li	a0,0
}
ffffffffc02016bc:	9d19                	subw	a0,a0,a4
ffffffffc02016be:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02016c0:	0005c703          	lbu	a4,0(a1)
ffffffffc02016c4:	4501                	li	a0,0
ffffffffc02016c6:	b7f5                	j	ffffffffc02016b2 <strcmp+0x22>

ffffffffc02016c8 <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc02016c8:	00054783          	lbu	a5,0(a0)
ffffffffc02016cc:	c799                	beqz	a5,ffffffffc02016da <strchr+0x12>
        if (*s == c) {
ffffffffc02016ce:	00f58763          	beq	a1,a5,ffffffffc02016dc <strchr+0x14>
    while (*s != '\0') {
ffffffffc02016d2:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc02016d6:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc02016d8:	fbfd                	bnez	a5,ffffffffc02016ce <strchr+0x6>
    }
    return NULL;
ffffffffc02016da:	4501                	li	a0,0
}
ffffffffc02016dc:	8082                	ret

ffffffffc02016de <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc02016de:	ca01                	beqz	a2,ffffffffc02016ee <memset+0x10>
ffffffffc02016e0:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc02016e2:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc02016e4:	0785                	addi	a5,a5,1
ffffffffc02016e6:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc02016ea:	fef61de3          	bne	a2,a5,ffffffffc02016e4 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc02016ee:	8082                	ret
