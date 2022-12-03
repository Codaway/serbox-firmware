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
;
;
; Interrupt table:  0F00 - 0FFF
;
; Status variables:
;
;   Interface status
;
;                  7 6 5 4 3 2 1 0
;                  | | | | |   |
;                  | | | | |   DCD
;                  | | | | CTS
;                  | | | parity error
;                  | | overrun error
;                  | framing error
;                  interface idle  
;
;   Line parameters
;
;   register A     7 6 5 4 3 2 1 0   
;                  | | | | | | | |
;                  | | | | | 0 0 0     600 baud
;                  | | | | | 0 0 1    1200 baud
;                  | | | | | 0 1 0    2400 baud
;                  | | | | | 0 1 1    4800 baud
;                  | | | | | 1 0 0    9600 baud
;                  | | | | | 1 0 1   19200 baud
;                  | | | | | 1 1 0   38400 baud                            
;                  | | | | |
;                  | | | 0 0 no parity
;                  | | | 1 0 parity odd
;                  | | | 1 1 parity even
;                  | | | 
;                  | 0 0 no handshake
;                  | 0 1 XON/XOFF
;                  | 1 0 RTS/CTS
;                  |
;                  0 one stop bit                   
;                  1 two stop bits
;
;   register B     7 6 5 4 3 2 1 0
;                          | | | |
;                          | | 0 0  5 bits/char
;                          | | 0 1  6 bits/char
;                          | | 1 0  7 bits/char
;                          | | 1 1  8 bits/char
;                          | |
;                          0 0 low XOFF treshold 1/4
;                          0 1 medium XOFF treshold 2/4
;                          1 0 high XOFF treshold 3/4
;                          1 1 risky XOFF treshold 4/4

	.equ    ITAB,   0x0F    ; Interrupt table offset

	.equ    ROMBEG, 0x0000  ; Begin of ROM
	.equ    RAMBEG, 0x1000  ; Begin of RAM
	.equ    STACK,  0x1800  ; Top of stack
	.equ    RAMSZ,  0x800   ; Size of RAM
	.equ    ROMSZ,  0x1000  ; Size of ROM

	.equ    SERTOUT, 0x0000 ; serial port timeout

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

	.org 0x1400
IST_A:  .rs 1           ; interface status
IST_B:  .rs 1
IST_C:  .rs 1
IST_D:  .rs 1

CFGBLK:
CFG_AA: .rs 1           ; configuration
CFG_AB: .rs 1

CFG_BA: .rs 1
CFG_BB: .rs 1

CFG_CA: .rs 1
CFG_CB: .rs 1

CFG_DA: .rs 1
CFG_DB: .rs 1

CHSUM:  .rs 2           ; configuration checksum
CFGEND:
SIOPRM: .rs 12          ; SIO parameters        
	

	; BUFFERS

	.org 0x1500
IBUF_A: .rs 0x40        ; Buffer Input Port A 
OBUF_A: .rs 0x40        ; Buffer Output Port A

IBUF_B: .rs 0x40        ; Buffer Input Port B
OBUF_B: .rs 0x40        ; Buffer Output Port B

IBUF_C: .rs 0x40        ; Buffer Input Port C
OBUF_C: .rs 0x40        ; Buffer Output Port C

IBUF_D: .rs 0x40        ; Buffer Input Port D
OBUF_D: .rs 0x40        ; Buffer Output Port D

	.org 0x0000

	LD A, 0
	CALL INITSIO
	JP 0xF12C

BUFDAT: .db 0x00, 0x15, 0x38      ; data about buffer
	.db 0x40, 0x15, 0x38
	.db 0x80, 0x15, 0x38
	.db 0xA0, 0x15, 0x38
	.db 0x00, 0x16, 0x38
	.db 0x40, 0x16, 0x38
	.db 0x80, 0x16, 0x38
	.db 0xA0, 0x16, 0x38

DFCFG:                            ; default configuration block
DFCFGA: .db 0x1A, 0x02            ; default config port A
DFCFGB: .db 0x1C, 0x02            ; default config port B
DFCFGC: .db 0x1C, 0x02            ; default config port C
DFCFGD: .db 0x1C, 0x02            ; default config port D

CTCPTS:  ; table with CTC ports
	.db CTCA
	.db CTCB
	.db CTCC
	.db CTCC                  ; baud rates for ports C and D are the same
				  ; because the @#! CRC is missing one output
				  ; line!

SIOPTS:  ; table with SIO ports
	.db S1AC
	.db S1BC
	.db S2CC
	.db S2DC

SIOVEC: ; table with SIO interrupt vectors
	.db 0x10
	.db 0x10
	.db 0x20
	.db 0x20

BAUDTB:  ; table with CTC values for different baudrates
	.db  96                   ;   600 baud
	.db  48                   ;  1200 baud
	.db  24                   ;  2400 baud
	.db  12                   ;  4800 baud
	.db   6                   ;  9600 baud
	.db   3                   ; 19200 baud
	.db   1                   ; 57600 baud  


INITSIO:        ; initialize SIO channel
		; register A contains a number from 0 to 3 designating the
		; port
					    
	LD D,A          ; channel number into C' and D
	
	EXX
	LD C,A           
	SLA C           ; multiply by 2
	XOR A           ; clear B'
	LD B,A
	LD HL, CFGBLK   ; get config register adress into HL'
	ADD HL, BC
	LD D, (HL)      ; first config register into D' and A
	INC HL
	LD A, (HL)      ; second config register into A
	LD E, A
	AND 0x02        ; flip bits of character length selector
	RRCA         
	RRCA         
	OR E        
	AND 0x81    
	RRCA        
	LD E,A          ; E' now contains SIO conforming char length in 7/6
	LD A, D
	EXX

	AND 0x07        ; mask out baud rate fields
	LD C, A         ; baud rate number into C

	XOR A           ; clear B
	LD B,A
	LD HL, BAUDTB
	ADD HL, BC
	LD E,(HL)       ; get CTC timer value for baudrate into E

	LD C,D          ; recall port number
	LD HL, CTCPTS
	ADD HL, BC
	LD C, (HL)      ; get CTC port number into C

	LD A, 0x47      ; external clock: counter mode

	LD C, D         ; reset interface status
	LD HL, IST_A
	ADD HL, BC
	LD (HL), 0x80   ; interface idle, no errors

	LD B, D         ; multiply port number * 6 and add to BUFDAT
	INC B
	LD IX, BUFDAT
	JR M3TST
M3INC:  INC IX
	INC IX
	INC IX
	INC IX
	INC IX
	INC IX
M3TST:  DJNZ M3INC

	LD B, 2          ; create 2 ring buffers 
I2BUF:  LD L, (IX+0)
	LD H, (IX+1)
	LD A, (IX+2)
	CALL CREATE
	INC IX
	INC IX
	INC IX
	DJNZ I2BUF
	
	; now, initialize SIO channel

	LD C,D          ; recall port number
	LD HL, SIOPTS
	ADD HL, BC
	LD C, (HL)      ; get SIO port number into C

	LD HL, SIOPRM   ; set HL to area, where SIO parameters are assembled
	LD (HL), 0x18   ; channel reset
	INC HL
	LD (HL), 0x01   ; select register 1
	INC HL
	LD (HL), 0x17   ; Int on all characters; parity,  status affects vec.
	INC HL
	LD (HL), 0x02   ; select register 2
	INC HL
	LD A,D          ; get channel number
	
	EXX             ; get interrupt vector
	LD HL, SIOVEC
	LD C,A
	XOR A
	LD B,A
	ADD HL, BC
	LD A,(HL)
	EXX
	LD (HL),A
	INC HL
	
	LD (HL), 0x03  ; select register 3 
	INC HL

	EXX            ; character length from E'
	LD A,E
	EXX
	OR 0x01        ; enable receiver
	LD (HL), A
	INC HL

	LD (HL), 0x04  ; select register 4
	INC HL

	EXX
	LD A,D  
	AND 0x98
	LD D,A  
	AND 0x08
	RLCA    
	RLCA    
	OR D    
	EXX
	AND 0xB0
	RLCA    
	RLCA    
	RLCA    
	RLCA 
	OR 0x44       ; add x16 clock mode, stop bit qualifier
	LD (HL),A
	INC HL

	LD (HL), 0x05 ; select register 5
	INC HL

	EXX
	LD A,E
	EXX

	RRCA
	OR 0x8A
	LD (HL), A

	LD B,11
	LD HL, SIOPRM

	RET

CREATE:         ; HL points to a buffer, A contains the
		; maxleng value. The buffer is initialized
		; to be empty. AF is destroyed, HL lost.

	LD (HL),A       ; maxleng := A
	INC HL
	XOR A
	LD (HL),A       ; bytesin := 0
	INC HL
	LD (HL),A       ; getind := 0
	INC HL
	LD (HL),A       ; putind := 0
	DEC HL
	DEC HL
	DEC HL
	RET
	.end
