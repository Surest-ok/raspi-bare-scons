.equ Mode_USR,        0x10
.equ Mode_FIQ,        0x11
.equ Mode_IRQ,        0x12
.equ Mode_SVC,        0x13
.equ Mode_ABT,        0x17
.equ Mode_UND,        0x1B
.equ Mode_SYS,        0x1F

.equ I_Bit,           0x80            @ when I bit is set, IRQ is disabled
.equ F_Bit,           0x40            @ when F bit is set, FIQ is disabled


.text
.global _start
_start:

	bl set_svc                       @设置CPU工作在SVC模式，关闭中断
	bl disable_mmu                   @设置CPU关闭MMU,dcache，icache
	bl stack_setup                   @设置svc模式运行堆栈
	bl clean_bss                     @清空bss段
	ldr pc, =main                    @进入C程序运行阶段

set_svc:
	mrs r0, cpsr                     @操作CPSR寄存器
	bic r0, r0,#0x1f 
	orr r0, r0,#0xd3                
	msr cpsr, r0
	mov pc, lr

disable_mmu:
	mcr p15,0,r0,c7,c7,0
	mrc p15,0,r0,c1,c0,0
	bic r0, r0, #0x00000007
	mcr p15,0,r0,c1,c0,0
	mov pc, lr


stack_setup:

    mov r0, #(Mode_SVC |F_Bit | I_Bit)    @建立堆栈
    msr     cpsr_c, r0
    @  Set the startup stack for svc
    mov sp, #0x6000000                    @设置堆栈指针
    
    bx      lr
stop_mmu:
    mrc p15,0,r2,c1,c0,0                 @设置协处理器C1 
    bic r2,#0x1000                       @关闭icache
    bic r2,#0x0004                       @关闭dcache
    bic r2,#0x0001                       @关闭mmu
    mcr p15,0,r2,c1,c0,0
    bx lr   

clean_bss:
	ldr r0, =bss_start                   @bss_start变量取自于链接文件，数据段起始
	ldr r1, =bss_end                     @bss_end变量取自于链接文件，数据段结束
	cmp r0, r1
	moveq pc, lr

clean_loop:
	mov r2, #0                           @数据段全部赋值为0
	str r2, [r0], #4
	cmp r0, r1
	bne clean_loop
	mov pc, lr