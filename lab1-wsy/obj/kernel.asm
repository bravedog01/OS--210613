
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080200000 <kern_entry>:
#include <memlayout.h>

    .section .text,"ax",%progbits
    .globl kern_entry
kern_entry:
    la sp, bootstacktop
    80200000:	00004117          	auipc	sp,0x4
    80200004:	00010113          	mv	sp,sp

    tail kern_init
    80200008:	a009                	j	8020000a <kern_init>

000000008020000a <kern_init>:
int kern_init(void) __attribute__((noreturn));
void grade_backtrace(void);

int kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
    8020000a:	00004517          	auipc	a0,0x4
    8020000e:	00650513          	addi	a0,a0,6 # 80204010 <ticks>
    80200012:	00004617          	auipc	a2,0x4
    80200016:	01660613          	addi	a2,a2,22 # 80204028 <end>
int kern_init(void) {
    8020001a:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
    8020001c:	8e09                	sub	a2,a2,a0
    8020001e:	4581                	li	a1,0
int kern_init(void) {
    80200020:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
    80200022:	5c8000ef          	jal	ra,802005ea <memset>

    cons_init();  // init the console
    80200026:	156000ef          	jal	ra,8020017c <cons_init>

    const char *message = "(THU.CST) os is loading ...\n";
    cprintf("%s\n\n", message);
    8020002a:	00001597          	auipc	a1,0x1
    8020002e:	a0e58593          	addi	a1,a1,-1522 # 80200a38 <etext>
    80200032:	00001517          	auipc	a0,0x1
    80200036:	a2650513          	addi	a0,a0,-1498 # 80200a58 <etext+0x20>
    8020003a:	030000ef          	jal	ra,8020006a <cprintf>

    print_kerninfo();
    8020003e:	062000ef          	jal	ra,802000a0 <print_kerninfo>

    // grade_backtrace();

    idt_init();  // init interrupt descriptor table
    80200042:	14a000ef          	jal	ra,8020018c <idt_init>

    // rdtime in mbare mode crashes
    clock_init();  // init clock interrupt
    80200046:	0e8000ef          	jal	ra,8020012e <clock_init>

    intr_enable();  // enable irq interrupt
    8020004a:	13c000ef          	jal	ra,80200186 <intr_enable>
    
    while (1)
    8020004e:	a001                	j	8020004e <kern_init+0x44>

0000000080200050 <cputch>:

/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void cputch(int c, int *cnt) {
    80200050:	1141                	addi	sp,sp,-16
    80200052:	e022                	sd	s0,0(sp)
    80200054:	e406                	sd	ra,8(sp)
    80200056:	842e                	mv	s0,a1
    cons_putc(c);
    80200058:	126000ef          	jal	ra,8020017e <cons_putc>
    (*cnt)++;
    8020005c:	401c                	lw	a5,0(s0)
}
    8020005e:	60a2                	ld	ra,8(sp)
    (*cnt)++;
    80200060:	2785                	addiw	a5,a5,1
    80200062:	c01c                	sw	a5,0(s0)
}
    80200064:	6402                	ld	s0,0(sp)
    80200066:	0141                	addi	sp,sp,16
    80200068:	8082                	ret

000000008020006a <cprintf>:
 * cprintf - formats a string and writes it to stdout
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int cprintf(const char *fmt, ...) {
    8020006a:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
    8020006c:	02810313          	addi	t1,sp,40 # 80204028 <end>
int cprintf(const char *fmt, ...) {
    80200070:	8e2a                	mv	t3,a0
    80200072:	f42e                	sd	a1,40(sp)
    80200074:	f832                	sd	a2,48(sp)
    80200076:	fc36                	sd	a3,56(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
    80200078:	00000517          	auipc	a0,0x0
    8020007c:	fd850513          	addi	a0,a0,-40 # 80200050 <cputch>
    80200080:	004c                	addi	a1,sp,4
    80200082:	869a                	mv	a3,t1
    80200084:	8672                	mv	a2,t3
int cprintf(const char *fmt, ...) {
    80200086:	ec06                	sd	ra,24(sp)
    80200088:	e0ba                	sd	a4,64(sp)
    8020008a:	e4be                	sd	a5,72(sp)
    8020008c:	e8c2                	sd	a6,80(sp)
    8020008e:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
    80200090:	e41a                	sd	t1,8(sp)
    int cnt = 0;
    80200092:	c202                	sw	zero,4(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
    80200094:	5d4000ef          	jal	ra,80200668 <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
    80200098:	60e2                	ld	ra,24(sp)
    8020009a:	4512                	lw	a0,4(sp)
    8020009c:	6125                	addi	sp,sp,96
    8020009e:	8082                	ret

00000000802000a0 <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
    802000a0:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
    802000a2:	00001517          	auipc	a0,0x1
    802000a6:	9be50513          	addi	a0,a0,-1602 # 80200a60 <etext+0x28>
void print_kerninfo(void) {
    802000aa:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
    802000ac:	fbfff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  entry  0x%016x (virtual)\n", kern_init);
    802000b0:	00000597          	auipc	a1,0x0
    802000b4:	f5a58593          	addi	a1,a1,-166 # 8020000a <kern_init>
    802000b8:	00001517          	auipc	a0,0x1
    802000bc:	9c850513          	addi	a0,a0,-1592 # 80200a80 <etext+0x48>
    802000c0:	fabff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  etext  0x%016x (virtual)\n", etext);
    802000c4:	00001597          	auipc	a1,0x1
    802000c8:	97458593          	addi	a1,a1,-1676 # 80200a38 <etext>
    802000cc:	00001517          	auipc	a0,0x1
    802000d0:	9d450513          	addi	a0,a0,-1580 # 80200aa0 <etext+0x68>
    802000d4:	f97ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  edata  0x%016x (virtual)\n", edata);
    802000d8:	00004597          	auipc	a1,0x4
    802000dc:	f3858593          	addi	a1,a1,-200 # 80204010 <ticks>
    802000e0:	00001517          	auipc	a0,0x1
    802000e4:	9e050513          	addi	a0,a0,-1568 # 80200ac0 <etext+0x88>
    802000e8:	f83ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  end    0x%016x (virtual)\n", end);
    802000ec:	00004597          	auipc	a1,0x4
    802000f0:	f3c58593          	addi	a1,a1,-196 # 80204028 <end>
    802000f4:	00001517          	auipc	a0,0x1
    802000f8:	9ec50513          	addi	a0,a0,-1556 # 80200ae0 <etext+0xa8>
    802000fc:	f6fff0ef          	jal	ra,8020006a <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
    80200100:	00004597          	auipc	a1,0x4
    80200104:	32758593          	addi	a1,a1,807 # 80204427 <end+0x3ff>
    80200108:	00000797          	auipc	a5,0x0
    8020010c:	f0278793          	addi	a5,a5,-254 # 8020000a <kern_init>
    80200110:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
    80200114:	43f7d593          	srai	a1,a5,0x3f
}
    80200118:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
    8020011a:	3ff5f593          	andi	a1,a1,1023
    8020011e:	95be                	add	a1,a1,a5
    80200120:	85a9                	srai	a1,a1,0xa
    80200122:	00001517          	auipc	a0,0x1
    80200126:	9de50513          	addi	a0,a0,-1570 # 80200b00 <etext+0xc8>
}
    8020012a:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
    8020012c:	bf3d                	j	8020006a <cprintf>

000000008020012e <clock_init>:

/* *
 * clock_init - initialize 8253 clock to interrupt 100 times per second,
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
    8020012e:	1141                	addi	sp,sp,-16
    80200130:	e406                	sd	ra,8(sp)
    // enable timer interrupt in sie
    set_csr(sie, MIP_STIP);
    80200132:	02000793          	li	a5,32
    80200136:	1047a7f3          	csrrs	a5,sie,a5
    __asm__ __volatile__("rdtime %0" : "=r"(n));
    8020013a:	c0102573          	rdtime	a0

    // 插入一个mret指令以从机器态返回到先前的模式
    __asm__ volatile("mret");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
    8020013e:	67e1                	lui	a5,0x18
    80200140:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0x801e7960>
    80200144:	953e                	add	a0,a0,a5
    80200146:	0bf000ef          	jal	ra,80200a04 <sbi_set_timer>
    cprintf("++ setup timer interrupts\n");
    8020014a:	00001517          	auipc	a0,0x1
    8020014e:	9e650513          	addi	a0,a0,-1562 # 80200b30 <etext+0xf8>
    ticks = 0;
    80200152:	00004797          	auipc	a5,0x4
    80200156:	ea07bf23          	sd	zero,-322(a5) # 80204010 <ticks>
    cprintf("++ setup timer interrupts\n");
    8020015a:	f11ff0ef          	jal	ra,8020006a <cprintf>
    __asm__ volatile("mret");
    8020015e:	30200073          	mret
    __asm__ volatile("mret");
    80200162:	30200073          	mret
}
    80200166:	60a2                	ld	ra,8(sp)
    80200168:	0141                	addi	sp,sp,16
    8020016a:	8082                	ret

000000008020016c <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
    8020016c:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
    80200170:	67e1                	lui	a5,0x18
    80200172:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0x801e7960>
    80200176:	953e                	add	a0,a0,a5
    80200178:	08d0006f          	j	80200a04 <sbi_set_timer>

000000008020017c <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
    8020017c:	8082                	ret

000000008020017e <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
    8020017e:	0ff57513          	zext.b	a0,a0
    80200182:	0690006f          	j	802009ea <sbi_console_putchar>

0000000080200186 <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
    80200186:	100167f3          	csrrsi	a5,sstatus,2
    8020018a:	8082                	ret

000000008020018c <idt_init>:
 */
void idt_init(void) {
    extern void __alltraps(void);
    /* Set sscratch register to 0, indicating to exception vector that we are
     * presently executing in the kernel */
    write_csr(sscratch, 0);
    8020018c:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
    80200190:	00000797          	auipc	a5,0x0
    80200194:	38878793          	addi	a5,a5,904 # 80200518 <__alltraps>
    80200198:	10579073          	csrw	stvec,a5
}
    8020019c:	8082                	ret

000000008020019e <print_regs>:
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr) {
    cprintf("  zero     0x%08x\n", gpr->zero);
    8020019e:	610c                	ld	a1,0(a0)
void print_regs(struct pushregs *gpr) {
    802001a0:	1141                	addi	sp,sp,-16
    802001a2:	e022                	sd	s0,0(sp)
    802001a4:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
    802001a6:	00001517          	auipc	a0,0x1
    802001aa:	9aa50513          	addi	a0,a0,-1622 # 80200b50 <etext+0x118>
void print_regs(struct pushregs *gpr) {
    802001ae:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
    802001b0:	ebbff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
    802001b4:	640c                	ld	a1,8(s0)
    802001b6:	00001517          	auipc	a0,0x1
    802001ba:	9b250513          	addi	a0,a0,-1614 # 80200b68 <etext+0x130>
    802001be:	eadff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
    802001c2:	680c                	ld	a1,16(s0)
    802001c4:	00001517          	auipc	a0,0x1
    802001c8:	9bc50513          	addi	a0,a0,-1604 # 80200b80 <etext+0x148>
    802001cc:	e9fff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
    802001d0:	6c0c                	ld	a1,24(s0)
    802001d2:	00001517          	auipc	a0,0x1
    802001d6:	9c650513          	addi	a0,a0,-1594 # 80200b98 <etext+0x160>
    802001da:	e91ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
    802001de:	700c                	ld	a1,32(s0)
    802001e0:	00001517          	auipc	a0,0x1
    802001e4:	9d050513          	addi	a0,a0,-1584 # 80200bb0 <etext+0x178>
    802001e8:	e83ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
    802001ec:	740c                	ld	a1,40(s0)
    802001ee:	00001517          	auipc	a0,0x1
    802001f2:	9da50513          	addi	a0,a0,-1574 # 80200bc8 <etext+0x190>
    802001f6:	e75ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
    802001fa:	780c                	ld	a1,48(s0)
    802001fc:	00001517          	auipc	a0,0x1
    80200200:	9e450513          	addi	a0,a0,-1564 # 80200be0 <etext+0x1a8>
    80200204:	e67ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
    80200208:	7c0c                	ld	a1,56(s0)
    8020020a:	00001517          	auipc	a0,0x1
    8020020e:	9ee50513          	addi	a0,a0,-1554 # 80200bf8 <etext+0x1c0>
    80200212:	e59ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
    80200216:	602c                	ld	a1,64(s0)
    80200218:	00001517          	auipc	a0,0x1
    8020021c:	9f850513          	addi	a0,a0,-1544 # 80200c10 <etext+0x1d8>
    80200220:	e4bff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
    80200224:	642c                	ld	a1,72(s0)
    80200226:	00001517          	auipc	a0,0x1
    8020022a:	a0250513          	addi	a0,a0,-1534 # 80200c28 <etext+0x1f0>
    8020022e:	e3dff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
    80200232:	682c                	ld	a1,80(s0)
    80200234:	00001517          	auipc	a0,0x1
    80200238:	a0c50513          	addi	a0,a0,-1524 # 80200c40 <etext+0x208>
    8020023c:	e2fff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
    80200240:	6c2c                	ld	a1,88(s0)
    80200242:	00001517          	auipc	a0,0x1
    80200246:	a1650513          	addi	a0,a0,-1514 # 80200c58 <etext+0x220>
    8020024a:	e21ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
    8020024e:	702c                	ld	a1,96(s0)
    80200250:	00001517          	auipc	a0,0x1
    80200254:	a2050513          	addi	a0,a0,-1504 # 80200c70 <etext+0x238>
    80200258:	e13ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
    8020025c:	742c                	ld	a1,104(s0)
    8020025e:	00001517          	auipc	a0,0x1
    80200262:	a2a50513          	addi	a0,a0,-1494 # 80200c88 <etext+0x250>
    80200266:	e05ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
    8020026a:	782c                	ld	a1,112(s0)
    8020026c:	00001517          	auipc	a0,0x1
    80200270:	a3450513          	addi	a0,a0,-1484 # 80200ca0 <etext+0x268>
    80200274:	df7ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
    80200278:	7c2c                	ld	a1,120(s0)
    8020027a:	00001517          	auipc	a0,0x1
    8020027e:	a3e50513          	addi	a0,a0,-1474 # 80200cb8 <etext+0x280>
    80200282:	de9ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
    80200286:	604c                	ld	a1,128(s0)
    80200288:	00001517          	auipc	a0,0x1
    8020028c:	a4850513          	addi	a0,a0,-1464 # 80200cd0 <etext+0x298>
    80200290:	ddbff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
    80200294:	644c                	ld	a1,136(s0)
    80200296:	00001517          	auipc	a0,0x1
    8020029a:	a5250513          	addi	a0,a0,-1454 # 80200ce8 <etext+0x2b0>
    8020029e:	dcdff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
    802002a2:	684c                	ld	a1,144(s0)
    802002a4:	00001517          	auipc	a0,0x1
    802002a8:	a5c50513          	addi	a0,a0,-1444 # 80200d00 <etext+0x2c8>
    802002ac:	dbfff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
    802002b0:	6c4c                	ld	a1,152(s0)
    802002b2:	00001517          	auipc	a0,0x1
    802002b6:	a6650513          	addi	a0,a0,-1434 # 80200d18 <etext+0x2e0>
    802002ba:	db1ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
    802002be:	704c                	ld	a1,160(s0)
    802002c0:	00001517          	auipc	a0,0x1
    802002c4:	a7050513          	addi	a0,a0,-1424 # 80200d30 <etext+0x2f8>
    802002c8:	da3ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
    802002cc:	744c                	ld	a1,168(s0)
    802002ce:	00001517          	auipc	a0,0x1
    802002d2:	a7a50513          	addi	a0,a0,-1414 # 80200d48 <etext+0x310>
    802002d6:	d95ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
    802002da:	784c                	ld	a1,176(s0)
    802002dc:	00001517          	auipc	a0,0x1
    802002e0:	a8450513          	addi	a0,a0,-1404 # 80200d60 <etext+0x328>
    802002e4:	d87ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
    802002e8:	7c4c                	ld	a1,184(s0)
    802002ea:	00001517          	auipc	a0,0x1
    802002ee:	a8e50513          	addi	a0,a0,-1394 # 80200d78 <etext+0x340>
    802002f2:	d79ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
    802002f6:	606c                	ld	a1,192(s0)
    802002f8:	00001517          	auipc	a0,0x1
    802002fc:	a9850513          	addi	a0,a0,-1384 # 80200d90 <etext+0x358>
    80200300:	d6bff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
    80200304:	646c                	ld	a1,200(s0)
    80200306:	00001517          	auipc	a0,0x1
    8020030a:	aa250513          	addi	a0,a0,-1374 # 80200da8 <etext+0x370>
    8020030e:	d5dff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
    80200312:	686c                	ld	a1,208(s0)
    80200314:	00001517          	auipc	a0,0x1
    80200318:	aac50513          	addi	a0,a0,-1364 # 80200dc0 <etext+0x388>
    8020031c:	d4fff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
    80200320:	6c6c                	ld	a1,216(s0)
    80200322:	00001517          	auipc	a0,0x1
    80200326:	ab650513          	addi	a0,a0,-1354 # 80200dd8 <etext+0x3a0>
    8020032a:	d41ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
    8020032e:	706c                	ld	a1,224(s0)
    80200330:	00001517          	auipc	a0,0x1
    80200334:	ac050513          	addi	a0,a0,-1344 # 80200df0 <etext+0x3b8>
    80200338:	d33ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
    8020033c:	746c                	ld	a1,232(s0)
    8020033e:	00001517          	auipc	a0,0x1
    80200342:	aca50513          	addi	a0,a0,-1334 # 80200e08 <etext+0x3d0>
    80200346:	d25ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
    8020034a:	786c                	ld	a1,240(s0)
    8020034c:	00001517          	auipc	a0,0x1
    80200350:	ad450513          	addi	a0,a0,-1324 # 80200e20 <etext+0x3e8>
    80200354:	d17ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
    80200358:	7c6c                	ld	a1,248(s0)
}
    8020035a:	6402                	ld	s0,0(sp)
    8020035c:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
    8020035e:	00001517          	auipc	a0,0x1
    80200362:	ada50513          	addi	a0,a0,-1318 # 80200e38 <etext+0x400>
}
    80200366:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
    80200368:	b309                	j	8020006a <cprintf>

000000008020036a <print_trapframe>:
void print_trapframe(struct trapframe *tf) {
    8020036a:	1141                	addi	sp,sp,-16
    8020036c:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
    8020036e:	85aa                	mv	a1,a0
void print_trapframe(struct trapframe *tf) {
    80200370:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
    80200372:	00001517          	auipc	a0,0x1
    80200376:	ade50513          	addi	a0,a0,-1314 # 80200e50 <etext+0x418>
void print_trapframe(struct trapframe *tf) {
    8020037a:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
    8020037c:	cefff0ef          	jal	ra,8020006a <cprintf>
    print_regs(&tf->gpr);
    80200380:	8522                	mv	a0,s0
    80200382:	e1dff0ef          	jal	ra,8020019e <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
    80200386:	10043583          	ld	a1,256(s0)
    8020038a:	00001517          	auipc	a0,0x1
    8020038e:	ade50513          	addi	a0,a0,-1314 # 80200e68 <etext+0x430>
    80200392:	cd9ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
    80200396:	10843583          	ld	a1,264(s0)
    8020039a:	00001517          	auipc	a0,0x1
    8020039e:	ae650513          	addi	a0,a0,-1306 # 80200e80 <etext+0x448>
    802003a2:	cc9ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
    802003a6:	11043583          	ld	a1,272(s0)
    802003aa:	00001517          	auipc	a0,0x1
    802003ae:	aee50513          	addi	a0,a0,-1298 # 80200e98 <etext+0x460>
    802003b2:	cb9ff0ef          	jal	ra,8020006a <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
    802003b6:	11843583          	ld	a1,280(s0)
}
    802003ba:	6402                	ld	s0,0(sp)
    802003bc:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
    802003be:	00001517          	auipc	a0,0x1
    802003c2:	af250513          	addi	a0,a0,-1294 # 80200eb0 <etext+0x478>
}
    802003c6:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
    802003c8:	b14d                	j	8020006a <cprintf>

00000000802003ca <interrupt_handler>:

void interrupt_handler(struct trapframe *tf) {
    intptr_t cause = (tf->cause << 1) >> 1;
    802003ca:	11853783          	ld	a5,280(a0)
    802003ce:	472d                	li	a4,11
    802003d0:	0786                	slli	a5,a5,0x1
    802003d2:	8385                	srli	a5,a5,0x1
    802003d4:	06f76763          	bltu	a4,a5,80200442 <interrupt_handler+0x78>
    802003d8:	00001717          	auipc	a4,0x1
    802003dc:	bb870713          	addi	a4,a4,-1096 # 80200f90 <etext+0x558>
    802003e0:	078a                	slli	a5,a5,0x2
    802003e2:	97ba                	add	a5,a5,a4
    802003e4:	439c                	lw	a5,0(a5)
    802003e6:	97ba                	add	a5,a5,a4
    802003e8:	8782                	jr	a5
            break;
        case IRQ_H_SOFT:
            cprintf("Hypervisor software interrupt\n");
            break;
        case IRQ_M_SOFT:
            cprintf("Machine software interrupt\n");
    802003ea:	00001517          	auipc	a0,0x1
    802003ee:	b3e50513          	addi	a0,a0,-1218 # 80200f28 <etext+0x4f0>
    802003f2:	b9a5                	j	8020006a <cprintf>
            cprintf("Hypervisor software interrupt\n");
    802003f4:	00001517          	auipc	a0,0x1
    802003f8:	b1450513          	addi	a0,a0,-1260 # 80200f08 <etext+0x4d0>
    802003fc:	b1bd                	j	8020006a <cprintf>
            cprintf("User software interrupt\n");
    802003fe:	00001517          	auipc	a0,0x1
    80200402:	aca50513          	addi	a0,a0,-1334 # 80200ec8 <etext+0x490>
    80200406:	b195                	j	8020006a <cprintf>
            cprintf("Supervisor software interrupt\n");
    80200408:	00001517          	auipc	a0,0x1
    8020040c:	ae050513          	addi	a0,a0,-1312 # 80200ee8 <etext+0x4b0>
    80200410:	b9a9                	j	8020006a <cprintf>
void interrupt_handler(struct trapframe *tf) {
    80200412:	1141                	addi	sp,sp,-16
    80200414:	e406                	sd	ra,8(sp)
            /*(1)设置下次时钟中断- clock_set_next_event()
             *(2)计数器（ticks）加一
             *(3)当计数器加到100的时候，我们会输出一个`100ticks`表示我们触发了100次时钟中断，同时打印次数（num）加一
            * (4)判断打印次数，当打印次数为10时，调用<sbi.h>中的关机函数关机
            */
            clock_set_next_event(); // 设置下次时钟中断
    80200416:	d57ff0ef          	jal	ra,8020016c <clock_set_next_event>
            ticks++; // 增加中断次数
    8020041a:	00004797          	auipc	a5,0x4
    8020041e:	bf678793          	addi	a5,a5,-1034 # 80204010 <ticks>
    80200422:	6398                	ld	a4,0(a5)
            // 检查是否达到100次时钟中断
            if (ticks==100) {
    80200424:	06400693          	li	a3,100
            ticks++; // 增加中断次数
    80200428:	0705                	addi	a4,a4,1
    8020042a:	e398                	sd	a4,0(a5)
            if (ticks==100) {
    8020042c:	639c                	ld	a5,0(a5)
    8020042e:	00d78b63          	beq	a5,a3,80200444 <interrupt_handler+0x7a>
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
    80200432:	60a2                	ld	ra,8(sp)
    80200434:	0141                	addi	sp,sp,16
    80200436:	8082                	ret
            cprintf("Supervisor external interrupt\n");
    80200438:	00001517          	auipc	a0,0x1
    8020043c:	b3850513          	addi	a0,a0,-1224 # 80200f70 <etext+0x538>
    80200440:	b12d                	j	8020006a <cprintf>
            print_trapframe(tf);
    80200442:	b725                	j	8020036a <print_trapframe>
    cprintf("%d ticks\n", TICK_NUM);
    80200444:	06400593          	li	a1,100
    80200448:	00001517          	auipc	a0,0x1
    8020044c:	b0050513          	addi	a0,a0,-1280 # 80200f48 <etext+0x510>
    80200450:	c1bff0ef          	jal	ra,8020006a <cprintf>
                num++;
    80200454:	00004797          	auipc	a5,0x4
    80200458:	bc478793          	addi	a5,a5,-1084 # 80204018 <num>
    8020045c:	6398                	ld	a4,0(a5)
                if (num >= 10) {
    8020045e:	46a5                	li	a3,9
                num++;
    80200460:	0705                	addi	a4,a4,1
    80200462:	e398                	sd	a4,0(a5)
                ticks= 0; // 重置中断计数
    80200464:	00004717          	auipc	a4,0x4
    80200468:	ba073623          	sd	zero,-1108(a4) # 80204010 <ticks>
                if (num >= 10) {
    8020046c:	639c                	ld	a5,0(a5)
    8020046e:	fcf6f2e3          	bgeu	a3,a5,80200432 <interrupt_handler+0x68>
                    cprintf("line counters = 10\n");
    80200472:	00001517          	auipc	a0,0x1
    80200476:	ae650513          	addi	a0,a0,-1306 # 80200f58 <etext+0x520>
    8020047a:	bf1ff0ef          	jal	ra,8020006a <cprintf>
}
    8020047e:	60a2                	ld	ra,8(sp)
    80200480:	0141                	addi	sp,sp,16
                    sbi_shutdown();
    80200482:	ab71                	j	80200a1e <sbi_shutdown>

0000000080200484 <exception_handler>:

void exception_handler(struct trapframe *tf) {
    switch (tf->cause) {
    80200484:	11853783          	ld	a5,280(a0)
void exception_handler(struct trapframe *tf) {
    80200488:	1141                	addi	sp,sp,-16
    8020048a:	e022                	sd	s0,0(sp)
    8020048c:	e406                	sd	ra,8(sp)
    switch (tf->cause) {
    8020048e:	470d                	li	a4,3
void exception_handler(struct trapframe *tf) {
    80200490:	842a                	mv	s0,a0
    switch (tf->cause) {
    80200492:	04e78663          	beq	a5,a4,802004de <exception_handler+0x5a>
    80200496:	02f76c63          	bltu	a4,a5,802004ce <exception_handler+0x4a>
    8020049a:	4709                	li	a4,2
    8020049c:	02e79563          	bne	a5,a4,802004c6 <exception_handler+0x42>
             /* LAB1 CHALLENGE3   YOUR CODE :  */
             /*(1)输出指令异常类型（ Illegal instruction）
             *(2)输出异常指令地址
             *(3)更新 tf->epc寄存器
            */
            cprintf("Illegal instruction caught at 0x%x\n", tf->epc);
    802004a0:	10853583          	ld	a1,264(a0)
    802004a4:	00001517          	auipc	a0,0x1
    802004a8:	b1c50513          	addi	a0,a0,-1252 # 80200fc0 <etext+0x588>
    802004ac:	bbfff0ef          	jal	ra,8020006a <cprintf>
            cprintf("Exception type: Illegal instruction\n");
    802004b0:	00001517          	auipc	a0,0x1
    802004b4:	b3850513          	addi	a0,a0,-1224 # 80200fe8 <etext+0x5b0>
    802004b8:	bb3ff0ef          	jal	ra,8020006a <cprintf>
            tf->epc += 4;
    802004bc:	10843783          	ld	a5,264(s0)
    802004c0:	0791                	addi	a5,a5,4
    802004c2:	10f43423          	sd	a5,264(s0)
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
    802004c6:	60a2                	ld	ra,8(sp)
    802004c8:	6402                	ld	s0,0(sp)
    802004ca:	0141                	addi	sp,sp,16
    802004cc:	8082                	ret
    switch (tf->cause) {
    802004ce:	17f1                	addi	a5,a5,-4
    802004d0:	471d                	li	a4,7
    802004d2:	fef77ae3          	bgeu	a4,a5,802004c6 <exception_handler+0x42>
}
    802004d6:	6402                	ld	s0,0(sp)
    802004d8:	60a2                	ld	ra,8(sp)
    802004da:	0141                	addi	sp,sp,16
            print_trapframe(tf);
    802004dc:	b579                	j	8020036a <print_trapframe>
            cprintf("ebreak caught at 0x%x\n", tf->epc);
    802004de:	10853583          	ld	a1,264(a0)
    802004e2:	00001517          	auipc	a0,0x1
    802004e6:	b2e50513          	addi	a0,a0,-1234 # 80201010 <etext+0x5d8>
    802004ea:	b81ff0ef          	jal	ra,8020006a <cprintf>
            cprintf("Exception type: breakpoint\n");
    802004ee:	00001517          	auipc	a0,0x1
    802004f2:	b3a50513          	addi	a0,a0,-1222 # 80201028 <etext+0x5f0>
    802004f6:	b75ff0ef          	jal	ra,8020006a <cprintf>
            tf->epc += 4;
    802004fa:	10843783          	ld	a5,264(s0)
}
    802004fe:	60a2                	ld	ra,8(sp)
            tf->epc += 4;
    80200500:	0791                	addi	a5,a5,4
    80200502:	10f43423          	sd	a5,264(s0)
}
    80200506:	6402                	ld	s0,0(sp)
    80200508:	0141                	addi	sp,sp,16
    8020050a:	8082                	ret

000000008020050c <trap>:

/* trap_dispatch - dispatch based on what type of trap occurred */
static inline void trap_dispatch(struct trapframe *tf) {
    if ((intptr_t)tf->cause < 0) {
    8020050c:	11853783          	ld	a5,280(a0)
    80200510:	0007c363          	bltz	a5,80200516 <trap+0xa>
        // interrupts
        interrupt_handler(tf);
    } else {
        // exceptions
        exception_handler(tf);
    80200514:	bf85                	j	80200484 <exception_handler>
        interrupt_handler(tf);
    80200516:	bd55                	j	802003ca <interrupt_handler>

0000000080200518 <__alltraps>:
    .endm

    .globl __alltraps
.align(2)
__alltraps:
    SAVE_ALL
    80200518:	14011073          	csrw	sscratch,sp
    8020051c:	712d                	addi	sp,sp,-288
    8020051e:	e002                	sd	zero,0(sp)
    80200520:	e406                	sd	ra,8(sp)
    80200522:	ec0e                	sd	gp,24(sp)
    80200524:	f012                	sd	tp,32(sp)
    80200526:	f416                	sd	t0,40(sp)
    80200528:	f81a                	sd	t1,48(sp)
    8020052a:	fc1e                	sd	t2,56(sp)
    8020052c:	e0a2                	sd	s0,64(sp)
    8020052e:	e4a6                	sd	s1,72(sp)
    80200530:	e8aa                	sd	a0,80(sp)
    80200532:	ecae                	sd	a1,88(sp)
    80200534:	f0b2                	sd	a2,96(sp)
    80200536:	f4b6                	sd	a3,104(sp)
    80200538:	f8ba                	sd	a4,112(sp)
    8020053a:	fcbe                	sd	a5,120(sp)
    8020053c:	e142                	sd	a6,128(sp)
    8020053e:	e546                	sd	a7,136(sp)
    80200540:	e94a                	sd	s2,144(sp)
    80200542:	ed4e                	sd	s3,152(sp)
    80200544:	f152                	sd	s4,160(sp)
    80200546:	f556                	sd	s5,168(sp)
    80200548:	f95a                	sd	s6,176(sp)
    8020054a:	fd5e                	sd	s7,184(sp)
    8020054c:	e1e2                	sd	s8,192(sp)
    8020054e:	e5e6                	sd	s9,200(sp)
    80200550:	e9ea                	sd	s10,208(sp)
    80200552:	edee                	sd	s11,216(sp)
    80200554:	f1f2                	sd	t3,224(sp)
    80200556:	f5f6                	sd	t4,232(sp)
    80200558:	f9fa                	sd	t5,240(sp)
    8020055a:	fdfe                	sd	t6,248(sp)
    8020055c:	14001473          	csrrw	s0,sscratch,zero
    80200560:	100024f3          	csrr	s1,sstatus
    80200564:	14102973          	csrr	s2,sepc
    80200568:	143029f3          	csrr	s3,stval
    8020056c:	14202a73          	csrr	s4,scause
    80200570:	e822                	sd	s0,16(sp)
    80200572:	e226                	sd	s1,256(sp)
    80200574:	e64a                	sd	s2,264(sp)
    80200576:	ea4e                	sd	s3,272(sp)
    80200578:	ee52                	sd	s4,280(sp)

    move  a0, sp
    8020057a:	850a                	mv	a0,sp
    jal trap
    8020057c:	f91ff0ef          	jal	ra,8020050c <trap>

0000000080200580 <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
    80200580:	6492                	ld	s1,256(sp)
    80200582:	6932                	ld	s2,264(sp)
    80200584:	10049073          	csrw	sstatus,s1
    80200588:	14191073          	csrw	sepc,s2
    8020058c:	60a2                	ld	ra,8(sp)
    8020058e:	61e2                	ld	gp,24(sp)
    80200590:	7202                	ld	tp,32(sp)
    80200592:	72a2                	ld	t0,40(sp)
    80200594:	7342                	ld	t1,48(sp)
    80200596:	73e2                	ld	t2,56(sp)
    80200598:	6406                	ld	s0,64(sp)
    8020059a:	64a6                	ld	s1,72(sp)
    8020059c:	6546                	ld	a0,80(sp)
    8020059e:	65e6                	ld	a1,88(sp)
    802005a0:	7606                	ld	a2,96(sp)
    802005a2:	76a6                	ld	a3,104(sp)
    802005a4:	7746                	ld	a4,112(sp)
    802005a6:	77e6                	ld	a5,120(sp)
    802005a8:	680a                	ld	a6,128(sp)
    802005aa:	68aa                	ld	a7,136(sp)
    802005ac:	694a                	ld	s2,144(sp)
    802005ae:	69ea                	ld	s3,152(sp)
    802005b0:	7a0a                	ld	s4,160(sp)
    802005b2:	7aaa                	ld	s5,168(sp)
    802005b4:	7b4a                	ld	s6,176(sp)
    802005b6:	7bea                	ld	s7,184(sp)
    802005b8:	6c0e                	ld	s8,192(sp)
    802005ba:	6cae                	ld	s9,200(sp)
    802005bc:	6d4e                	ld	s10,208(sp)
    802005be:	6dee                	ld	s11,216(sp)
    802005c0:	7e0e                	ld	t3,224(sp)
    802005c2:	7eae                	ld	t4,232(sp)
    802005c4:	7f4e                	ld	t5,240(sp)
    802005c6:	7fee                	ld	t6,248(sp)
    802005c8:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
    802005ca:	10200073          	sret

00000000802005ce <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
    802005ce:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
    802005d0:	e589                	bnez	a1,802005da <strnlen+0xc>
    802005d2:	a811                	j	802005e6 <strnlen+0x18>
        cnt ++;
    802005d4:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
    802005d6:	00f58863          	beq	a1,a5,802005e6 <strnlen+0x18>
    802005da:	00f50733          	add	a4,a0,a5
    802005de:	00074703          	lbu	a4,0(a4)
    802005e2:	fb6d                	bnez	a4,802005d4 <strnlen+0x6>
    802005e4:	85be                	mv	a1,a5
    }
    return cnt;
}
    802005e6:	852e                	mv	a0,a1
    802005e8:	8082                	ret

00000000802005ea <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
    802005ea:	ca01                	beqz	a2,802005fa <memset+0x10>
    802005ec:	962a                	add	a2,a2,a0
    char *p = s;
    802005ee:	87aa                	mv	a5,a0
        *p ++ = c;
    802005f0:	0785                	addi	a5,a5,1
    802005f2:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
    802005f6:	fec79de3          	bne	a5,a2,802005f0 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
    802005fa:	8082                	ret

00000000802005fc <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
    802005fc:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
    80200600:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
    80200602:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
    80200606:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
    80200608:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
    8020060c:	f022                	sd	s0,32(sp)
    8020060e:	ec26                	sd	s1,24(sp)
    80200610:	e84a                	sd	s2,16(sp)
    80200612:	f406                	sd	ra,40(sp)
    80200614:	e44e                	sd	s3,8(sp)
    80200616:	84aa                	mv	s1,a0
    80200618:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
    8020061a:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
    8020061e:	2a01                	sext.w	s4,s4
    if (num >= base) {
    80200620:	03067e63          	bgeu	a2,a6,8020065c <printnum+0x60>
    80200624:	89be                	mv	s3,a5
        while (-- width > 0)
    80200626:	00805763          	blez	s0,80200634 <printnum+0x38>
    8020062a:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
    8020062c:	85ca                	mv	a1,s2
    8020062e:	854e                	mv	a0,s3
    80200630:	9482                	jalr	s1
        while (-- width > 0)
    80200632:	fc65                	bnez	s0,8020062a <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
    80200634:	1a02                	slli	s4,s4,0x20
    80200636:	00001797          	auipc	a5,0x1
    8020063a:	a1278793          	addi	a5,a5,-1518 # 80201048 <etext+0x610>
    8020063e:	020a5a13          	srli	s4,s4,0x20
    80200642:	9a3e                	add	s4,s4,a5
}
    80200644:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
    80200646:	000a4503          	lbu	a0,0(s4)
}
    8020064a:	70a2                	ld	ra,40(sp)
    8020064c:	69a2                	ld	s3,8(sp)
    8020064e:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
    80200650:	85ca                	mv	a1,s2
    80200652:	87a6                	mv	a5,s1
}
    80200654:	6942                	ld	s2,16(sp)
    80200656:	64e2                	ld	s1,24(sp)
    80200658:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
    8020065a:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
    8020065c:	03065633          	divu	a2,a2,a6
    80200660:	8722                	mv	a4,s0
    80200662:	f9bff0ef          	jal	ra,802005fc <printnum>
    80200666:	b7f9                	j	80200634 <printnum+0x38>

0000000080200668 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
    80200668:	7119                	addi	sp,sp,-128
    8020066a:	f4a6                	sd	s1,104(sp)
    8020066c:	f0ca                	sd	s2,96(sp)
    8020066e:	ecce                	sd	s3,88(sp)
    80200670:	e8d2                	sd	s4,80(sp)
    80200672:	e4d6                	sd	s5,72(sp)
    80200674:	e0da                	sd	s6,64(sp)
    80200676:	fc5e                	sd	s7,56(sp)
    80200678:	f06a                	sd	s10,32(sp)
    8020067a:	fc86                	sd	ra,120(sp)
    8020067c:	f8a2                	sd	s0,112(sp)
    8020067e:	f862                	sd	s8,48(sp)
    80200680:	f466                	sd	s9,40(sp)
    80200682:	ec6e                	sd	s11,24(sp)
    80200684:	892a                	mv	s2,a0
    80200686:	84ae                	mv	s1,a1
    80200688:	8d32                	mv	s10,a2
    8020068a:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
    8020068c:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
    80200690:	5b7d                	li	s6,-1
    80200692:	00001a97          	auipc	s5,0x1
    80200696:	9eaa8a93          	addi	s5,s5,-1558 # 8020107c <etext+0x644>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
    8020069a:	00001b97          	auipc	s7,0x1
    8020069e:	bbeb8b93          	addi	s7,s7,-1090 # 80201258 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
    802006a2:	000d4503          	lbu	a0,0(s10)
    802006a6:	001d0413          	addi	s0,s10,1
    802006aa:	01350a63          	beq	a0,s3,802006be <vprintfmt+0x56>
            if (ch == '\0') {
    802006ae:	c121                	beqz	a0,802006ee <vprintfmt+0x86>
            putch(ch, putdat);
    802006b0:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
    802006b2:	0405                	addi	s0,s0,1
            putch(ch, putdat);
    802006b4:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
    802006b6:	fff44503          	lbu	a0,-1(s0)
    802006ba:	ff351ae3          	bne	a0,s3,802006ae <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
    802006be:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
    802006c2:	02000793          	li	a5,32
        lflag = altflag = 0;
    802006c6:	4c81                	li	s9,0
    802006c8:	4881                	li	a7,0
        width = precision = -1;
    802006ca:	5c7d                	li	s8,-1
    802006cc:	5dfd                	li	s11,-1
    802006ce:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
    802006d2:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
    802006d4:	fdd6059b          	addiw	a1,a2,-35
    802006d8:	0ff5f593          	zext.b	a1,a1
    802006dc:	00140d13          	addi	s10,s0,1
    802006e0:	04b56263          	bltu	a0,a1,80200724 <vprintfmt+0xbc>
    802006e4:	058a                	slli	a1,a1,0x2
    802006e6:	95d6                	add	a1,a1,s5
    802006e8:	4194                	lw	a3,0(a1)
    802006ea:	96d6                	add	a3,a3,s5
    802006ec:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
    802006ee:	70e6                	ld	ra,120(sp)
    802006f0:	7446                	ld	s0,112(sp)
    802006f2:	74a6                	ld	s1,104(sp)
    802006f4:	7906                	ld	s2,96(sp)
    802006f6:	69e6                	ld	s3,88(sp)
    802006f8:	6a46                	ld	s4,80(sp)
    802006fa:	6aa6                	ld	s5,72(sp)
    802006fc:	6b06                	ld	s6,64(sp)
    802006fe:	7be2                	ld	s7,56(sp)
    80200700:	7c42                	ld	s8,48(sp)
    80200702:	7ca2                	ld	s9,40(sp)
    80200704:	7d02                	ld	s10,32(sp)
    80200706:	6de2                	ld	s11,24(sp)
    80200708:	6109                	addi	sp,sp,128
    8020070a:	8082                	ret
            padc = '0';
    8020070c:	87b2                	mv	a5,a2
            goto reswitch;
    8020070e:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
    80200712:	846a                	mv	s0,s10
    80200714:	00140d13          	addi	s10,s0,1
    80200718:	fdd6059b          	addiw	a1,a2,-35
    8020071c:	0ff5f593          	zext.b	a1,a1
    80200720:	fcb572e3          	bgeu	a0,a1,802006e4 <vprintfmt+0x7c>
            putch('%', putdat);
    80200724:	85a6                	mv	a1,s1
    80200726:	02500513          	li	a0,37
    8020072a:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
    8020072c:	fff44783          	lbu	a5,-1(s0)
    80200730:	8d22                	mv	s10,s0
    80200732:	f73788e3          	beq	a5,s3,802006a2 <vprintfmt+0x3a>
    80200736:	ffed4783          	lbu	a5,-2(s10)
    8020073a:	1d7d                	addi	s10,s10,-1
    8020073c:	ff379de3          	bne	a5,s3,80200736 <vprintfmt+0xce>
    80200740:	b78d                	j	802006a2 <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
    80200742:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
    80200746:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
    8020074a:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
    8020074c:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
    80200750:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
    80200754:	02d86463          	bltu	a6,a3,8020077c <vprintfmt+0x114>
                ch = *fmt;
    80200758:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
    8020075c:	002c169b          	slliw	a3,s8,0x2
    80200760:	0186873b          	addw	a4,a3,s8
    80200764:	0017171b          	slliw	a4,a4,0x1
    80200768:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
    8020076a:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
    8020076e:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
    80200770:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
    80200774:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
    80200778:	fed870e3          	bgeu	a6,a3,80200758 <vprintfmt+0xf0>
            if (width < 0)
    8020077c:	f40ddce3          	bgez	s11,802006d4 <vprintfmt+0x6c>
                width = precision, precision = -1;
    80200780:	8de2                	mv	s11,s8
    80200782:	5c7d                	li	s8,-1
    80200784:	bf81                	j	802006d4 <vprintfmt+0x6c>
            if (width < 0)
    80200786:	fffdc693          	not	a3,s11
    8020078a:	96fd                	srai	a3,a3,0x3f
    8020078c:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
    80200790:	00144603          	lbu	a2,1(s0)
    80200794:	2d81                	sext.w	s11,s11
    80200796:	846a                	mv	s0,s10
            goto reswitch;
    80200798:	bf35                	j	802006d4 <vprintfmt+0x6c>
            precision = va_arg(ap, int);
    8020079a:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
    8020079e:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
    802007a2:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
    802007a4:	846a                	mv	s0,s10
            goto process_precision;
    802007a6:	bfd9                	j	8020077c <vprintfmt+0x114>
    if (lflag >= 2) {
    802007a8:	4705                	li	a4,1
            precision = va_arg(ap, int);
    802007aa:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
    802007ae:	01174463          	blt	a4,a7,802007b6 <vprintfmt+0x14e>
    else if (lflag) {
    802007b2:	1a088e63          	beqz	a7,8020096e <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
    802007b6:	000a3603          	ld	a2,0(s4)
    802007ba:	46c1                	li	a3,16
    802007bc:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
    802007be:	2781                	sext.w	a5,a5
    802007c0:	876e                	mv	a4,s11
    802007c2:	85a6                	mv	a1,s1
    802007c4:	854a                	mv	a0,s2
    802007c6:	e37ff0ef          	jal	ra,802005fc <printnum>
            break;
    802007ca:	bde1                	j	802006a2 <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
    802007cc:	000a2503          	lw	a0,0(s4)
    802007d0:	85a6                	mv	a1,s1
    802007d2:	0a21                	addi	s4,s4,8
    802007d4:	9902                	jalr	s2
            break;
    802007d6:	b5f1                	j	802006a2 <vprintfmt+0x3a>
    if (lflag >= 2) {
    802007d8:	4705                	li	a4,1
            precision = va_arg(ap, int);
    802007da:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
    802007de:	01174463          	blt	a4,a7,802007e6 <vprintfmt+0x17e>
    else if (lflag) {
    802007e2:	18088163          	beqz	a7,80200964 <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
    802007e6:	000a3603          	ld	a2,0(s4)
    802007ea:	46a9                	li	a3,10
    802007ec:	8a2e                	mv	s4,a1
    802007ee:	bfc1                	j	802007be <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
    802007f0:	00144603          	lbu	a2,1(s0)
            altflag = 1;
    802007f4:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
    802007f6:	846a                	mv	s0,s10
            goto reswitch;
    802007f8:	bdf1                	j	802006d4 <vprintfmt+0x6c>
            putch(ch, putdat);
    802007fa:	85a6                	mv	a1,s1
    802007fc:	02500513          	li	a0,37
    80200800:	9902                	jalr	s2
            break;
    80200802:	b545                	j	802006a2 <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
    80200804:	00144603          	lbu	a2,1(s0)
            lflag ++;
    80200808:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
    8020080a:	846a                	mv	s0,s10
            goto reswitch;
    8020080c:	b5e1                	j	802006d4 <vprintfmt+0x6c>
    if (lflag >= 2) {
    8020080e:	4705                	li	a4,1
            precision = va_arg(ap, int);
    80200810:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
    80200814:	01174463          	blt	a4,a7,8020081c <vprintfmt+0x1b4>
    else if (lflag) {
    80200818:	14088163          	beqz	a7,8020095a <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
    8020081c:	000a3603          	ld	a2,0(s4)
    80200820:	46a1                	li	a3,8
    80200822:	8a2e                	mv	s4,a1
    80200824:	bf69                	j	802007be <vprintfmt+0x156>
            putch('0', putdat);
    80200826:	03000513          	li	a0,48
    8020082a:	85a6                	mv	a1,s1
    8020082c:	e03e                	sd	a5,0(sp)
    8020082e:	9902                	jalr	s2
            putch('x', putdat);
    80200830:	85a6                	mv	a1,s1
    80200832:	07800513          	li	a0,120
    80200836:	9902                	jalr	s2
            num = (unsigned long long)va_arg(ap, void *);
    80200838:	0a21                	addi	s4,s4,8
            goto number;
    8020083a:	6782                	ld	a5,0(sp)
    8020083c:	46c1                	li	a3,16
            num = (unsigned long long)va_arg(ap, void *);
    8020083e:	ff8a3603          	ld	a2,-8(s4)
            goto number;
    80200842:	bfb5                	j	802007be <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
    80200844:	000a3403          	ld	s0,0(s4)
    80200848:	008a0713          	addi	a4,s4,8
    8020084c:	e03a                	sd	a4,0(sp)
    8020084e:	14040263          	beqz	s0,80200992 <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
    80200852:	0fb05763          	blez	s11,80200940 <vprintfmt+0x2d8>
    80200856:	02d00693          	li	a3,45
    8020085a:	0cd79163          	bne	a5,a3,8020091c <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
    8020085e:	00044783          	lbu	a5,0(s0)
    80200862:	0007851b          	sext.w	a0,a5
    80200866:	cf85                	beqz	a5,8020089e <vprintfmt+0x236>
    80200868:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
    8020086c:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
    80200870:	000c4563          	bltz	s8,8020087a <vprintfmt+0x212>
    80200874:	3c7d                	addiw	s8,s8,-1
    80200876:	036c0263          	beq	s8,s6,8020089a <vprintfmt+0x232>
                    putch('?', putdat);
    8020087a:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
    8020087c:	0e0c8e63          	beqz	s9,80200978 <vprintfmt+0x310>
    80200880:	3781                	addiw	a5,a5,-32
    80200882:	0ef47b63          	bgeu	s0,a5,80200978 <vprintfmt+0x310>
                    putch('?', putdat);
    80200886:	03f00513          	li	a0,63
    8020088a:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
    8020088c:	000a4783          	lbu	a5,0(s4)
    80200890:	3dfd                	addiw	s11,s11,-1
    80200892:	0a05                	addi	s4,s4,1
    80200894:	0007851b          	sext.w	a0,a5
    80200898:	ffe1                	bnez	a5,80200870 <vprintfmt+0x208>
            for (; width > 0; width --) {
    8020089a:	01b05963          	blez	s11,802008ac <vprintfmt+0x244>
    8020089e:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
    802008a0:	85a6                	mv	a1,s1
    802008a2:	02000513          	li	a0,32
    802008a6:	9902                	jalr	s2
            for (; width > 0; width --) {
    802008a8:	fe0d9be3          	bnez	s11,8020089e <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
    802008ac:	6a02                	ld	s4,0(sp)
    802008ae:	bbd5                	j	802006a2 <vprintfmt+0x3a>
    if (lflag >= 2) {
    802008b0:	4705                	li	a4,1
            precision = va_arg(ap, int);
    802008b2:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
    802008b6:	01174463          	blt	a4,a7,802008be <vprintfmt+0x256>
    else if (lflag) {
    802008ba:	08088d63          	beqz	a7,80200954 <vprintfmt+0x2ec>
        return va_arg(*ap, long);
    802008be:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
    802008c2:	0a044d63          	bltz	s0,8020097c <vprintfmt+0x314>
            num = getint(&ap, lflag);
    802008c6:	8622                	mv	a2,s0
    802008c8:	8a66                	mv	s4,s9
    802008ca:	46a9                	li	a3,10
    802008cc:	bdcd                	j	802007be <vprintfmt+0x156>
            err = va_arg(ap, int);
    802008ce:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
    802008d2:	4719                	li	a4,6
            err = va_arg(ap, int);
    802008d4:	0a21                	addi	s4,s4,8
            if (err < 0) {
    802008d6:	41f7d69b          	sraiw	a3,a5,0x1f
    802008da:	8fb5                	xor	a5,a5,a3
    802008dc:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
    802008e0:	02d74163          	blt	a4,a3,80200902 <vprintfmt+0x29a>
    802008e4:	00369793          	slli	a5,a3,0x3
    802008e8:	97de                	add	a5,a5,s7
    802008ea:	639c                	ld	a5,0(a5)
    802008ec:	cb99                	beqz	a5,80200902 <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
    802008ee:	86be                	mv	a3,a5
    802008f0:	00000617          	auipc	a2,0x0
    802008f4:	78860613          	addi	a2,a2,1928 # 80201078 <etext+0x640>
    802008f8:	85a6                	mv	a1,s1
    802008fa:	854a                	mv	a0,s2
    802008fc:	0ce000ef          	jal	ra,802009ca <printfmt>
    80200900:	b34d                	j	802006a2 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
    80200902:	00000617          	auipc	a2,0x0
    80200906:	76660613          	addi	a2,a2,1894 # 80201068 <etext+0x630>
    8020090a:	85a6                	mv	a1,s1
    8020090c:	854a                	mv	a0,s2
    8020090e:	0bc000ef          	jal	ra,802009ca <printfmt>
    80200912:	bb41                	j	802006a2 <vprintfmt+0x3a>
                p = "(null)";
    80200914:	00000417          	auipc	s0,0x0
    80200918:	74c40413          	addi	s0,s0,1868 # 80201060 <etext+0x628>
                for (width -= strnlen(p, precision); width > 0; width --) {
    8020091c:	85e2                	mv	a1,s8
    8020091e:	8522                	mv	a0,s0
    80200920:	e43e                	sd	a5,8(sp)
    80200922:	cadff0ef          	jal	ra,802005ce <strnlen>
    80200926:	40ad8dbb          	subw	s11,s11,a0
    8020092a:	01b05b63          	blez	s11,80200940 <vprintfmt+0x2d8>
                    putch(padc, putdat);
    8020092e:	67a2                	ld	a5,8(sp)
    80200930:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
    80200934:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
    80200936:	85a6                	mv	a1,s1
    80200938:	8552                	mv	a0,s4
    8020093a:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
    8020093c:	fe0d9ce3          	bnez	s11,80200934 <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
    80200940:	00044783          	lbu	a5,0(s0)
    80200944:	00140a13          	addi	s4,s0,1
    80200948:	0007851b          	sext.w	a0,a5
    8020094c:	d3a5                	beqz	a5,802008ac <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
    8020094e:	05e00413          	li	s0,94
    80200952:	bf39                	j	80200870 <vprintfmt+0x208>
        return va_arg(*ap, int);
    80200954:	000a2403          	lw	s0,0(s4)
    80200958:	b7ad                	j	802008c2 <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
    8020095a:	000a6603          	lwu	a2,0(s4)
    8020095e:	46a1                	li	a3,8
    80200960:	8a2e                	mv	s4,a1
    80200962:	bdb1                	j	802007be <vprintfmt+0x156>
    80200964:	000a6603          	lwu	a2,0(s4)
    80200968:	46a9                	li	a3,10
    8020096a:	8a2e                	mv	s4,a1
    8020096c:	bd89                	j	802007be <vprintfmt+0x156>
    8020096e:	000a6603          	lwu	a2,0(s4)
    80200972:	46c1                	li	a3,16
    80200974:	8a2e                	mv	s4,a1
    80200976:	b5a1                	j	802007be <vprintfmt+0x156>
                    putch(ch, putdat);
    80200978:	9902                	jalr	s2
    8020097a:	bf09                	j	8020088c <vprintfmt+0x224>
                putch('-', putdat);
    8020097c:	85a6                	mv	a1,s1
    8020097e:	02d00513          	li	a0,45
    80200982:	e03e                	sd	a5,0(sp)
    80200984:	9902                	jalr	s2
                num = -(long long)num;
    80200986:	6782                	ld	a5,0(sp)
    80200988:	8a66                	mv	s4,s9
    8020098a:	40800633          	neg	a2,s0
    8020098e:	46a9                	li	a3,10
    80200990:	b53d                	j	802007be <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
    80200992:	03b05163          	blez	s11,802009b4 <vprintfmt+0x34c>
    80200996:	02d00693          	li	a3,45
    8020099a:	f6d79de3          	bne	a5,a3,80200914 <vprintfmt+0x2ac>
                p = "(null)";
    8020099e:	00000417          	auipc	s0,0x0
    802009a2:	6c240413          	addi	s0,s0,1730 # 80201060 <etext+0x628>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
    802009a6:	02800793          	li	a5,40
    802009aa:	02800513          	li	a0,40
    802009ae:	00140a13          	addi	s4,s0,1
    802009b2:	bd6d                	j	8020086c <vprintfmt+0x204>
    802009b4:	00000a17          	auipc	s4,0x0
    802009b8:	6ada0a13          	addi	s4,s4,1709 # 80201061 <etext+0x629>
    802009bc:	02800513          	li	a0,40
    802009c0:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
    802009c4:	05e00413          	li	s0,94
    802009c8:	b565                	j	80200870 <vprintfmt+0x208>

00000000802009ca <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
    802009ca:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
    802009cc:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
    802009d0:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
    802009d2:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
    802009d4:	ec06                	sd	ra,24(sp)
    802009d6:	f83a                	sd	a4,48(sp)
    802009d8:	fc3e                	sd	a5,56(sp)
    802009da:	e0c2                	sd	a6,64(sp)
    802009dc:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
    802009de:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
    802009e0:	c89ff0ef          	jal	ra,80200668 <vprintfmt>
}
    802009e4:	60e2                	ld	ra,24(sp)
    802009e6:	6161                	addi	sp,sp,80
    802009e8:	8082                	ret

00000000802009ea <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
    802009ea:	4781                	li	a5,0
    802009ec:	00003717          	auipc	a4,0x3
    802009f0:	61473703          	ld	a4,1556(a4) # 80204000 <SBI_CONSOLE_PUTCHAR>
    802009f4:	88ba                	mv	a7,a4
    802009f6:	852a                	mv	a0,a0
    802009f8:	85be                	mv	a1,a5
    802009fa:	863e                	mv	a2,a5
    802009fc:	00000073          	ecall
    80200a00:	87aa                	mv	a5,a0
int sbi_console_getchar(void) {
    return sbi_call(SBI_CONSOLE_GETCHAR, 0, 0, 0);
}
void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
    80200a02:	8082                	ret

0000000080200a04 <sbi_set_timer>:
    __asm__ volatile (
    80200a04:	4781                	li	a5,0
    80200a06:	00003717          	auipc	a4,0x3
    80200a0a:	61a73703          	ld	a4,1562(a4) # 80204020 <SBI_SET_TIMER>
    80200a0e:	88ba                	mv	a7,a4
    80200a10:	852a                	mv	a0,a0
    80200a12:	85be                	mv	a1,a5
    80200a14:	863e                	mv	a2,a5
    80200a16:	00000073          	ecall
    80200a1a:	87aa                	mv	a5,a0

void sbi_set_timer(unsigned long long stime_value) {
    sbi_call(SBI_SET_TIMER, stime_value, 0, 0);
}
    80200a1c:	8082                	ret

0000000080200a1e <sbi_shutdown>:
    __asm__ volatile (
    80200a1e:	4781                	li	a5,0
    80200a20:	00003717          	auipc	a4,0x3
    80200a24:	5e873703          	ld	a4,1512(a4) # 80204008 <SBI_SHUTDOWN>
    80200a28:	88ba                	mv	a7,a4
    80200a2a:	853e                	mv	a0,a5
    80200a2c:	85be                	mv	a1,a5
    80200a2e:	863e                	mv	a2,a5
    80200a30:	00000073          	ecall
    80200a34:	87aa                	mv	a5,a0


void sbi_shutdown(void)
{
    sbi_call(SBI_SHUTDOWN,0,0,0);
    80200a36:	8082                	ret
