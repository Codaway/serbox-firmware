; Serial interface box software
;
;
;
; 1995
; (c) Dipl.-Ing. Gernot Kunz

; Memory map:
;
;     0000 ROM
;        :        4K ROM
;     0FFF ROM
;     1000 RAM
;        :        2K RAM
;     17FF RAM
;
; IO map:
;
;     F8       CTC A
;     F9       CTC B
;     FA       CTC C
;     FB       CTC D
;
;     F4       SIO 1A data
;     F5       SIO 1A control
;     F6       SIO 1B data
;     F7       SIO 1B control
;
;     EC       SIO 2C data
;     ED       SIO 2C control
;     EE       SIO 2D data
;     EF       SIO 2D control
	.equ    CTCA,   0xF8
	.equ    CTCB,   0xF9
	.equ    CTCC,   0xFA
	.equ    CTCD,   0xFB

	.equ    S1AD,   0xF4
	.equ    S1AC,   0xF5
	.equ    S1BD,   0xF6
	.equ    S1BC,   0xF7

	.equ    S2CD,   0xEC
	.equ    S2CC,   0xED
	.equ    S2DD,   0xEE
	.equ    S2DC,   0xEF

	.org 0x0125
	INIT:   LD HL, 0x1800
	LD SP, HL

	LD A, 0x47
	OUT (CTCC), A
	LD A, 6
	OUT (CTCC), A

	LD A, 1
	OUT (S2CC), A
	LD A, 0x00
	OUT (S2CC), A
	LD A, 3
	OUT (S2CC), A
	LD A, 0xC1
	OUT (S2CC), A
	LD A, 4
	OUT (S2CC), A
	LD A, 0x44
	OUT (S2CC), A
	LD A, 5
	OUT (S2CC), A
	LD A, 0xEA
	OUT (S2CC), A

	LD HL, STRING
	CALL PRT_C

INWAIT1:XOR A
	OUT (S2CC), A
	IN A, (S2CC)
	AND 0x01
	JR Z, INWAIT1

	IN A, (S2CD)
	LD C, A
	CALL OUT_C        

	CP 0x0d
	JR NZ, INWAIT1

	LD A, 0x0a
	LD C, A
	CALL OUT_C
	JP INIT

OUT_C:  PUSH AF
OUT1:   XOR A
	OUT (S2CC), A
	IN A, (S2CC)
	AND 0x04
	JR Z, OUT1

	LD A, C
	OUT (S2CD), A
	POP AF
	RET

PRT_C:  LD A, (HL)
	OR A
	RET Z
	LD C, A
	CALL OUT_C
	INC HL
	JR PRT_C

STRING: .db "This is a test string: hope it is received.\r\n\0"
	.end
