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
;                  | | | | | 1 1 0   57600 baud                            
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
INIT:   JP START

BUFDAT: .db 0x00, 0x15, 0x3C      ; data about buffer
	.db 0x40, 0x15, 0x3C
	.db 0x80, 0x15, 0x3C
	.db 0xC0, 0x15, 0x3C
	.db 0x00, 0x16, 0x3C
	.db 0x40, 0x16, 0x3C
	.db 0x80, 0x16, 0x3C
	.db 0xC0, 0x16, 0x3C

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

BSTAB:  .drw B600
	.drw B1200
	.drw B2400
	.drw B4800
	.drw B9600
	.drw B19200
	.drw B57600

PSTAB:  .drw IGNPAR
	.drw IGNPAR
	.drw PARODD
	.drw PAREVE

SSTAB:  .drw STOP1
	.drw STOP2

HSTAB:  .drw HDSHN
	.drw HDSHX
	.drw HDSHR
	.drw HDSHI

DBTAB:  .drw DBIT5
	.drw DBIT6
	.drw DBIT7
	.drw DBIT8

	.org 0x0066
	;                   Non-maskable interrupt
NMIST:  XOR A              
	LD L, A
	LD H, A
	LD (RAMBEG), HL  ; clear RAM magic number
	LD (CHSUM), HL   ; clear SIO config checksum to load defaults
	JP 0x0000

HLPSTR: .db "Commands: (C)checksum (S)ystem, (P)orts, E(X)it\r\n\0"
CCSSTR: .db "Config checksum computed\r\n\0"
NOPRT:  .db "Illegal port: must be A - D\r\n\0"
PRMPT:  .db "Config>\0"

BDSTR:  .db "Baudrate:  \0"
PRSTR:  .db "Parity:    \0"
SBSTR:  .db "Stop bits: \0"
HSSTR:  .db "Handshake: \0"
DBSTR:  .db "Data bits: \0"

B600:   .db "600\0"
B1200:  .db "1200\0"
B2400:  .db "2400\0"
B4800:  .db "4800\0"
B9600:  .db "9600\0"
B19200: .db "19200\0"
B57600: .db "57600\0"

IGNPAR: .db "NONE\0"
PARODD: .db "ODD\0"
PAREVE: .db "EVEN\0"

STOP1:  .db "1\0"
STOP2:  .db "2\0"

HDSHN:  .db "NONE\0"
HDSHX:  .db "XON/XOFF\0"
HDSHR:  .db "RTS/CTS\0"
HDSHI:  .db "ILLEGAL\0"

DBIT5:  .db "5\0"
DBIT6:  .db "6\0"
DBIT7:  .db "7\0"
DBIT8:  .db "8\0"

CMPCRC: ; Compute CRC on a block of data
	;
	; HL: points to start of data block
	; BC: size of data block in bytes:
	;     contains CRC afterwards
	
	.equ    POLY,0x8005

	EXX
	LD DE, POLY
	XOR A
	LD H,A
	LD L,A
	EXX

NXTBYT: LD A,(HL)

	EXX
	LD C,A
	LD B,8
ROTAGN: SLA C
	RL L
	RL H
	JR NC, NOXOR

	LD A, H
	XOR D
	LD H,A
	LD A, L 
	XOR E
	LD L, A

NOXOR:  DJNZ ROTAGN
	EXX
	INC HL
	DEC BC
	LD A,B
	OR C
	JR NZ, NXTBYT

	EXX
	LD A, H
	EXX
	LD B, A
	EXX
	LD A, L
	EXX
	LD C, A
	RET

ERRFLSH:
	; FLASH - Error Routine: flash LED n times: m times 
	;
	; Register D: n
	; Register E: m

	.equ    SHTDLY, 8000    ; short delay
	.equ    LNGDLY, 0       ; long delay
 
	LD B, E
NXTRPT:
	LD E, B
	LD B, D          ; load flash counter

FLAGN:  LD A,5
	OUT(S2DC),A
	LD A,0x80       ; DTR on (LED on)
	OUT(S2DC),A

	LD HL, SHTDLY
DELY1:  DEC HL  
	LD A,H
	OR L
	JR NZ, DELY1

	LD A,5
	OUT(S2DC),A
	XOR A           ; DTR off (LED off)
	OUT(S2DC),A

	LD HL, SHTDLY
DELY2:  DEC HL
	LD A,H
	OR L
	JR NZ, DELY2

	DJNZ FLAGN

	LD HL, LNGDLY
DELY3:  DEC HL
	LD A,H
	OR L
	JR NZ, DELY3

	LD B, E
	DJNZ NXTRPT

	RET

INTCT_A:        ; CTC channel A interrupt routine
		; test purposes only: increment HL
	INC HL
	EI
	RETI

INTCT_B:
INTCT_C:
INTCT_D:        ; CTC channel B,C,D interrupt routine
		; never used: do nothing
	EI
	RETI

	; compute checksum and store in config block
CFGCSM: LD HL, CHSUM
	XOR A 
	LD (HL),A
	INC HL
	LD (HL),A
	LD HL, CFGBLK
	LD BC, CFGEND - CFGBLK
	CALL CMPCRC
	LD HL, CHSUM
	LD (HL), B
	INC HL
	LD (HL), C
	RET

	;
	; Here is where it all starts
	;
	; Why do all assembler programs start somewhere
	; in the middle, with a wasteful jump from zero?
	; Well, don't ask me, but I follow the tradition here.

START:  LD HL,STACK     ; initialize stack pointer
	LD SP,HL

RAMTST: LD HL, RAMBEG   ; test all of RAM: cannot be a subroutine,
	LD BC, RAMSZ    ; because the stack may not work on buggy RAM
	JR RAMLOP

RAMERR: LD D, 1         ; flash LED once, if RAM is broken
	LD E, 0
	CALL ERRFLSH
	JR RAMERR

RAMRPT: LD D,(HL)       ; retrieve and save old byte
	XOR A           ; test all zeroes
	LD (HL),A
	CP (HL)
	JR NZ, RAMERR

	CPL             ; test all ones
	LD (HL),A
	CP (HL)
	JR NZ, RAMERR

	LD A, 0x55      ; odd ones
	LD (HL), A
	CP (HL)
	JR NZ, RAMERR
	
	CPL             ; even ones
	LD (HL), A
	CP (HL)
	JR NZ, RAMERR

	LD A,D          ; original value
	LD (HL),A
	CP(HL)
	JR NZ, RAMERR

	INC HL
	DEC BC
RAMLOP: LD A,B
	OR C
	JR NZ, RAMRPT

	;
	; if we are here, all RAM is OK
ROMTST: LD HL, ROMBEG   ; test ROM checksum
	LD BC, ROMSZ
	CALL CMPCRC     ; compute checksum into BC: must be zero

	LD A, B
	OR C
	JR Z, ROMOK

ROMERR: LD D, 2         ; flash LED twice if ROM is broken
	LD E, 0
	CALL ERRFLSH
	JR ROMERR

ROMOK:  ; we are in good shape: RAM and ROM OK: enable interrupts
	LD A, ITAB
	LD I,A
	IM 2
	EI

	.equ TSTDLY, 1000
	; Now test presence and proper operation of
	; CRC chip: program channel A so it interrupts
	; every 256 cycles and increments HL. Then go into
	; a loop of about 10000 cycles and, at the end,
	; look if HL has been incremented.
  
CTCTST: XOR A
	LD H,A
	LD L,A          ; clear HL
	OUT(CTCA),A     ; interrupt vector
	LD A,0x85       ; intr enable, time constant follows
	OUT(CTCA),A
	LD A,16         ; time constant
	OUT(CTCA),A

	LD BC, TSTDLY
CRCRPT: DEC BC
	LD A,B
	OR C
	JR NZ,CRCRPT    

	LD A,0x03       ; intr disable, reset
	OUT(CTCA),A
	DI

	LD A, H
	OR L
	JR NZ, CTCOK

CTCERR: LD D, 3         ; CTC error: flash LED 3 times
	LD E, 0
	CALL ERRFLSH
	JR CTCERR

CTCOK:  ; CTC test successfully completed
	; test SIO reaction: by writing and reading interrupt vectors
	LD A, 0x18      ; channel reset
	OUT (S1BC), A
	OUT (S2DC), A

	LD A, 0x01
	OUT (S1BC), A
	OUT (S2DC),A

	XOR A           ; clear register 1: status doesn't affect vector
	OUT (S1BC), A
	OUT (S2DC),A
	
	LD A, 0x02
	OUT (S1BC), A
	OUT (S2DC),A
	
	LD A, 0x5A      ; test pattern 1
	OUT (S1BC),A    ; write to interrupt vector register
	OUT (S2DC),A    ; same with SIO 2
	
	LD A, 0x02
	OUT (S1BC), A
	OUT (S2DC),A

	IN A,(S1BC)
	CP 0x5A
	JR NZ, S1ERR

	IN A,(S2DC)
	CP 0x5A
	JR NZ, S2ERR

	LD A, 0x02
	OUT(S1BC), A
	OUT(S2DC), A

	LD A, 0xA5
	OUT (S1BC),A
	OUT (S2DC),A
	
	LD A, 0x02
	OUT (S1BC), A
	OUT (S2DC), A

	IN A,(S1BC)
	CP 0xA5
	JR NZ, S1ERR

	IN A,(S2DC)
	CP 0xA5
	JR Z, SIOOK

S1ERR:  LD D, 4         ; SIO 1 error: flash LED 4 times
	LD E, 0
	CALL ERRFLSH
	JR S1ERR

S2ERR:  LD D, 5         ; SIO 2 error: flash LED 5 times
	LD E, 0 
	CALL ERRFLSH
	JR S2ERR

SIOOK:  ; SIO test successfully completed
	; check RAM override program area for magic number 0x1357
	; magic stored in location: RAM Begin
	; if present, compute checksum of RAM override area
	; length stored in location: RAM Begin + 2 bytes
	; if OK, start RAM program, else continue
	
	LD HL, RAMBEG
	LD A, (HL)
	CP 0x57
	JR NZ, NOMGC
	INC HL
	LD A, (HL)
	CP 0x13
	JR NZ, NOMGC

	INC HL
	LD C,(HL)
	INC HL
	LD B,(HL)
	DEC HL
	DEC HL
	DEC HL

	CALL CMPCRC
	LD A, B
	OR C
	JR NZ, CRCERR

	LD HL,RAMBEG + 4    ; execute override program
	JP (HL)

RESETA: XOR A               ; reset port A
	DI
	CALL INITSIO
	EI
	JR IDLE2

RESETB: LD A, 1             ; reset port B
	DI
	CALL INITSIO
	EI
	JR IDLE1

RESETC: LD A, 2             ; reset port C
	DI
	CALL INITSIO
	EI
	JR IDLE1

RESETD: LD A, 3             ; reset port D
	DI
	CALL INITSIO
	EI
	JR IDLE1

CRCERR: LD D, 6             ; flash LED 6 times: 3 times
	LD E, 3
	CALL ERRFLSH

NOMGC:  ; if no magic number continue
	; check RAM SIO config block checksum
	
	LD HL,CFGBLK 
	LD BC,CFGEND - CFGBLK
	CALL CMPCRC

	LD A,B
	OR C
	JR Z, CFGOK

	LD D, 7             ; flash LED 7 times: 3 times
	LD E, 3
	CALL ERRFLSH

	; if not ok, load default values
	LD HL, DFCFG
	LD DE, CFGBLK
	LD BC, 8
	LDIR

	CALL CFGCSM

CFGOK:  ; configuration OK
	; or serial timeout: initialize everything anew
	; initialize status variables
	DI              ; disable interrupts
	XOR A
	CALL INITSIO
	LD A, 1
	CALL INITSIO
	LD A, 2
	CALL INITSIO
	LD A, 3
	CALL INITSIO
	EI                  ; enable interrupts

	; Multiplexerlogik:
IDLE1:  CALL CSTS_A         ; standby mode: wait for characters ports A/C
	JR NZ, A1
IDLE2:  CALL CSTS_C
	JR NZ, ID1_XC     
	
	LD A, (IST_A)
	AND 0x70            ; errors port A
	JP NZ, RESETA

	LD A, (IST_C)         ; errors port C
	AND 0x70
	JR NZ, RESETC
	JR IDLE1

ID1_XC: CALL CI_C           ; character from port C (PSION)
	
	CP '@'              ; catch escape sequence
	JP Z, ESCAPE 
	LD C,A
	CALL CO_B           ; thru to B (Hercules)
	CP 0x0D
	JR Z,C2
	JR C1

A1:     LD HL, SERTOUT

A11:    DEC HL
	LD A, H
	OR L
	JP Z, RESETA
	
	CALL CSTS_A         ; wait for characters from A (Mast display)
	JR Z, A11
	CALL CI_A           ; get port A character
	LD C,A
	CALL CO_B           ; thru to B (Hercules)
	CP 0x0D             ; on CR character end this mode
	JR NZ, A11

A2:     LD HL, SERTOUT

A22:    DEC HL
	LD A, H
	OR L
	JP Z, RESETB

	CALL CSTS_B         ; wait for response from B (Hercules)
	JR Z, A22
	CALL CI_B           ; get port B character
	LD C,A
	CALL CO_A           ; thru to A (Mast display)
	CP 0x0D             ; on CR character back to idle mode
	JP Z,IDLE2
	JR A22

C1:     LD HL, SERTOUT

C11:    DEC HL
	LD A, H
	OR L
	JP Z, RESETC

	CALL CSTS_C
	JR Z, C11
	CALL CI_C
	LD C,A
	CALL CO_B
	CP 0x0D
	JR NZ, C11

C2:     LD HL, SERTOUT

C22:    DEC HL
	LD A, H
	OR L
	JP Z, RESETB

	CALL CSTS_B
	JR Z, C22
	CALL CI_B
	LD C,A
	CALL CO_C
	CP 0x0D
	JP Z, IDLE1
	JR C22

ESCAPE: CALL CRLF
	LD HL, PRMPT
	CALL LPRINT
ECHO:   CALL CI_C
	CALL OUTCH
	CP 'C'
	JP Z, CCSM
	CP 'S'
	JP Z, MSTART
	CP 'P'
	JP Z, PORTS
	CP '?'
	JR Z, HELP
	CP 'X'
	JP Z, IDLE1
	CP '\r'
	JR NZ, ECHO
	CALL CRLF
	JR ESCAPE
 
CCSM:   CALL CFGCSM
	CALL CRLF
	LD HL, CCSSTR
	CALL LPRINT
	JR ESCAPE

HELP:   CALL CRLF
	LD HL, HLPSTR
	CALL LPRINT
	JR ESCAPE

PORTS:  CALL CI_C
	CALL OUTCH
	CP 'A'
	JR C, PRTERR
	CP 'E'
	JR NC, PRTERR
	SUB 'A'
	PUSH AF
	CALL CRLF
	POP AF
	CALL PRTCFG
	JR ESCAPE

PRTERR: CALL CRLF
	LD HL, NOPRT
	CALL LPRINT  
	JR ESCAPE

PRTCFG: SLA A
	LD HL, CFGBLK    
	LD C, A
	XOR A
	LD B,A
	ADD HL, BC
	LD D,(HL)
	INC HL
	LD E,(HL)

	LD HL,BDSTR
	CALL LPRINT
	LD HL, BSTAB
	LD A,D
	AND 0x07
	SLA A
	CALL PDSTR
	
	LD HL,PRSTR
	CALL LPRINT
	LD HL, PSTAB
	LD A,D
	RRCA
	RRCA
	AND 0x06
	CALL PDSTR
	
	LD HL,HSSTR
	CALL LPRINT
	LD HL, HSTAB
	LD A,D
	RLCA
	RLCA
	RLCA
	RLCA
	AND 0x06
	CALL PDSTR
	
	LD HL, DBSTR
	CALL LPRINT
	LD HL, DBTAB
	LD A,E
	SLA A
	AND 0x06
	CALL PDSTR

	LD HL,SBSTR
	CALL LPRINT
	LD HL, SSTAB
	LD A,D
	RLCA
	RLCA
	AND 0x02

PDSTR:  LD C,A
	ADD HL, BC
	LD C,(HL)
	INC HL
	LD A,(HL)
	LD H,A
	LD L,C
	CALL LPRINT
	JP CRLF

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
	OUT (C), A      ; initialize CTC
	OUT (C), E      ; output timer value

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
	LD (HL), 0x30   ; error reset
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
	OTIR          ; finally: out to SIO

	RET

	; 
	; MONITOR Program
	;

PRAC:   ; A in 2 digits ausgeben
	PUSH AF
	RRA
	RRA
	RRA
	RRA
	CALL OUTH
	POP AF

OUTH:   AND 0x0F
	ADD A, '0'
	CP '9'+1
	JR C, OUTCH
	ADD A, 'A'-'9'-1
OUTCH:  LD C, A
	JP CO_C

PRHL:   ; HL in 4 digits ausgeben
	LD A, H
	CALL PRAC
	LD A, L
	JR PRAC

EXPR:   ; Hexzahl in HL eingeben, Terminator in A speichern
	LD HL, 0x000
EX0:    CALL CI_C
	CALL OUTCH
EX1:    CALL NIBBLE
	JR C, EX2
	ADD HL, HL
	ADD HL, HL
	ADD HL, HL
	ADD HL, HL
	OR L
	LD L, A
	JR EX0
NIBBLE: SUB '0'
	RET C
	CP 'G'-'0'
	CCF
	RET C
	CP 10
	CCF
	RET NC
	SUB 'A'-'9'-1
	CP 10
	RET
EX2:    LD A, C
	CP '\r'
	JR Z, ECHU
	RET
ECHU:   PUSH AF
	LD C, '\n'
	CALL CO_C
	POP AF
	LD C, A
	RET

CRLF:   LD C, '\r'
	CALL CO_C
	LD C, '\n'
	JP CO_C

LPRINT: LD A, (HL)
	INC HL
	OR A
	RET Z
	CALL OUTCH
	JR LPRINT

LENGTH: LD B, 0
	PUSH HL
	POP DE
	LD A, (HL)
	AND 0xDF
	CP 0xDD
	JR Z, TAB5
	LD A, (HL)
	CP 0xCB
	JR Z, B2
	CP 0xED
	JR Z, TAB2
	CP 0xC3
	JR Z, B3
	CP 0xCD
	JR Z, B3
	AND 0xEF
	CP 0x22
	JR Z, B3
	CP 0x2A
	JR Z, B3
	AND 0xCF
	CP 1
	JR Z, B3
	AND 0xC7
	CP 0xC2
	JR Z, B3
	CP 0xC4
	JR Z, B3
	LD A, (HL)
	AND 0xF7
	CP 0x10
	JR Z, B2
	CP 0xD3
	JR Z, B2
	AND 0xE7
	CP 0x20
	JR Z, B2
	AND 0xC7
	CP 6
	JR Z, B2
	CP 0xC6
	JR Z, B2
	JR B1

B4:     INC B
B3:     INC B
B2:     INC B
B1:     INC B
	EX DE, HL
	RET

TAB2:   INC HL
	LD A, (HL)
	AND 0xC7
	CP 0x43
	JR Z, B4
	JR B2

TAB5:   INC HL
	LD A, (HL)
	CP 0xCB
	JR Z, B4
	CP 0x21
	JR Z, B4
	AND 0xFE
	CP 0x34
	JR Z, B3
	AND 0xFB
	CP 0x70
	JR Z, B3
	LD A, (HL)
	AND 0xCF
	CP 6
	JR Z, B4
	AND 0xC7
	CP 2
	JR Z, B4
	LD A, (HL)
	SUB 0x40
	AND 0x87
	CP 6
	JR Z, B3
	JR B2

MSTART:
MLOOP:  CALL CRLF
	LD HL, STRG1
	CALL LPRINT
	JR LBL1
STRG1:  .db "SYS>\0"
LBL1:   CALL CI_C   
	LD C, A
	CALL CO_C
	CP 'E'
	JR Z, ENTER
	CP 'G'
	JR Z, GOEX
	CP 'Q'
	JR Z, QUERY
	CP 'X'
	JP Z, ESCAPE
	JR MLOOP

GOEX:   CALL EXPR
	LD DE, MLOOP
	PUSH DE
	PUSH HL
	RET

QUERY:  CALL CI_C
	CALL OUTCH
	CP 'I'
	JR Z, INPQ
	CALL EXPR
	LD C, L
	CP ' ' 
	JP NZ, MLOOP
	PUSH BC
	CALL EXPR
	POP BC
	LD A, L
	OUT (C), A
	JP MLOOP
INPQ:   CALL EXPR
	LD C, ' '
	CALL CO_C
	LD C, L
	IN A, (C)
	CALL PRAC
	JP MLOOP

ENTER:  CALL EXPR
LOOP:   CALL CRLF
LOOPA:  CALL PRHL
	CALL LENGTH
	PUSH BC
	PUSH HL
LOOP1:  LD C, ' '
	CALL CO_C
	LD A, (HL)
	CALL PRAC
	INC HL
	DJNZ LOOP1

	POP DE
	POP BC
	LD A, 5
	SUB B
	LD B, A
	RLCA
	AND 0x0F
	ADD A, B
	LD B, A
LPP:    LD C, ' '
	CALL CO_C
	DJNZ LPP
	LD C, ':'
	CALL CO_C
	LD A, (DE)
	AND 0x7F
	CP 0x20
	JR C, CONT
	CP 0x7F
	JR Z, CONT
	LD C, A
	JR CONT1
CONT:   LD C, ' ' 
CONT1:  CALL CO_C
	LD C, ':'
	CALL CO_C
LOOP2:  CALL CI_C
	LD C, A
	CALL CO_C
LOOP3:  CP 0x7F
	JP Z, BACKGO
	CP '\r'
	JP Z, LPPA
	CP ' '
	JP Z, LOOP
	CP '.'
	JP Z, MLOOP
	CP '\''
	JP Z, TEXT
LOOP4:  LD HL, 0x0000
	CALL EX1
	LD B, A
	LD A, L
	LD (DE), A
	INC DE
	LD A, B
	CP ' ' 
	JR Z, LOOP2
	EX DE, HL
	JP LOOPA
BACKGO: DEC DE
	EX DE, HL
	JP LOOP
LPPA:   EX DE, HL
	INC HL
	JP LOOP
TEXT:   CALL CI_C
	CALL OUTCH
	CP '\''
	JR Z, CONTE
	CP 0x7F
	JR Z, BACK
	LD (DE), A
	INC DE
	JR TEXT
CONTE:  CALL CI_C
	CALL OUTCH
	CP ' '
	JP Z, LOOP2
	EX DE, HL
	JP LOOP
BACK:   LD C, 8
	CALL CO_C
	LD C, ' '
	CALL CO_C
	LD C, 8
	CALL CO_C
	DEC DE
	JR TEXT

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


EMPTY:          ; HL points to a buffer. If the buffer is
		; empty, the zero flag is set, else it is
		; reset. A is destroyed, HL saved.
	INC HL
	LD A,(HL)
	DEC HL
	OR A
	RET


FULL:           ; HL points to a buffer. If the buffer is
		; full, the zero flag is set, else it is
		; reset. A is destroyed, HL saved.
	INC HL
	LD A,(HL)
	DEC HL
	CP (HL)
	RET


GET:            ; HL points to a buffer. The next character
		; is read from this buffer and returned in A
		; IX destroyed. This function
		; is defined only if the buffer is not empty
	PUSH DE
	PUSH IX
	LD D,0

	PUSH HL
	POP IX

	DEC (IX+1)
	LD A,(IX+2)     ; bytesin := bytesin +1
	INC A
	CP (IX+0)
	JP M,NRMLG
	LD (IX+2),0
	JR CMNG
NRMLG:  LD (IX+2),A
CMNG:   LD E,A
	ADD IX,DE
	LD A,(IX+3)
	
	POP IX
	POP DE
	RET


PUT:            ; HL points to a buffer. The character passed
		; in A is put to this buffer. HL is kept,
		; IX lost. This function is defined only
		; if the buffer is not full
	
	PUSH DE
	PUSH IX
	PUSH AF
	LD D,0
	PUSH HL
	POP IX

	INC (IX+1)
	LD A,(IX+3)
	INC A
	CP (IX+0)
	JP M, NRMLP
	LD (IX+3),0
	JR CMNP
NRMLP:  LD (IX+3),A
CMNP:   LD E,A
	POP AF
	ADD IX,DE
	LD (IX+3),A
	POP IX
	POP DE
	RET

; --------------------- per port routines start A--------
INTWR_A:
	PUSH AF
	PUSH HL
	LD HL, OBUF_A
	CALL EMPTY
	JR Z, EMPA

NOHDWA: CALL GET
	OUT (S1AD),A
RETRNA: POP HL
	POP AF
	EI
	RETI
EMPA:   LD HL, IST_A
	SET 7,(HL)
	LD A,0x28       ; reset pending interrupt
	OUT (S1AC),A
	JR RETRNA


INTRD_A:
	PUSH AF
	PUSH HL
	LD HL, IBUF_A
	CALL FULL
	IN A,(S1AD)
	JR Z, FULA
	AND 0x7F        ; 7 bit world
	CALL PUT
	JR RETRNA
FULA:   LD HL, IST_A
	LD A,(HL)
	OR 0x20         ; overflow bit
	LD (HL),A
	JR RETRNA


INTER_A:
	PUSH AF
	PUSH HL
	LD A,1
	OUT (S1AC),A
	IN A,(S1AC)
	AND 0x30
	LD HL, IST_A
	OR (HL)
	LD (HL),A
	IN A, (S1AD)
	LD A,0x30
	OUT (S1AC),A
	JR RETRNA


INTST_A:                 ; external status change
	PUSH AF
	PUSH HL
	LD HL, IST_A
	LD A,(HL)
	AND 0xF5        ; mask away CTS and DCD
	LD (HL),A
	XOR A           ; get status
	OUT (S1AC),A
	IN A,(S1AC)
	AND 0x28        ; mask CTS and DCD bits
	RRA
	RRA
	OR (HL)
	LD (HL),A
	LD A,0x10       ; reset status
	OUT (S1AC),A
	JR RETRNA                       

CI_A:
	PUSH HL
	LD HL, IBUF_A
	JR TEST1A
WAIT1A: HALT
TEST1A: CALL EMPTY
	JR Z, WAIT1A
	DI
	CALL GET
	EI
	POP HL
	RET

CO_A:   PUSH HL
	LD HL, OBUF_A
	JR TEST2A
WAIT2A: HALT
TEST2A: DI
	CALL FULL
	EI
	JR Z, WAIT2A
	LD A, (IST_A)
	BIT 7,A
	JR Z, ENDA
	RES 7,A
	LD (IST_A),A
	LD A,C
	OUT (S1AD),A
	POP HL
	RET
ENDA:   LD A,C
	DI
	CALL PUT
	EI
	POP HL
	RET
 
CSTS_A:
	PUSH HL
	LD HL, IBUF_A
	CALL EMPTY
	POP HL
	JR NZ, CDRESA
	XOR A
	RET
CDRESA: LD A, 0xFF
	OR A
	RET 
; --------------------- per port routines end A--------

; --------------------- per port routines start B--------
INTWR_B:
	PUSH AF
	PUSH HL
	LD HL, OBUF_B
	CALL EMPTY
	JR Z, EMPB
	
NOHDWB: CALL GET
	OUT (S1BD),A
RETRNB: POP HL
	POP AF
	EI
	RETI
EMPB:   LD HL, IST_B
	SET 7,(HL)
	LD A,0x28       ; reset pending interrupt
	OUT (S1BC),A
	JR RETRNB


INTRD_B:
	PUSH AF
	PUSH HL
	LD HL, IBUF_B
	CALL FULL
	IN A,(S1BD)
	JR Z, FULB
	AND 0x7F        ; 7 bit world
	CALL PUT
	JR RETRNB
FULB:   LD HL, IST_B
	LD A,(HL)
	OR 0x20         ; overflow bit
	LD (HL),A
	JR RETRNB


INTER_B:
	PUSH AF
	PUSH HL
	LD A,1
	OUT (S1BC),A
	IN A,(S1BC)
	AND 0x30
	LD HL, IST_B
	OR (HL)
	LD (HL),A
	IN A, (S1BD)
	LD A,0x30
	OUT (S1BC),A
	JR RETRNB


INTST_B:                 ; external status change
	PUSH AF
	PUSH HL
	LD HL, IST_B
	LD A,(HL)
	AND 0xF5        ; mask away CTS and DCD
	LD (HL),A
	XOR A           ; get status
	OUT (S1BC),A 
	IN A,(S1BC)
	AND 0x28        ; mask CTS and DCD bits
	RRA
	RRA
	OR (HL)
	LD (HL),A
	LD A, 0x10      ; reset status
	OUT (S1BC),A
	JR RETRNB                       

CI_B:
	PUSH HL
	LD HL, IBUF_B
	JR TEST1B
WAIT1B: HALT
TEST1B: CALL EMPTY
	JR Z, WAIT1B
	DI
	CALL GET
	EI
	POP HL
	RET

CO_B:   PUSH HL
	LD HL, OBUF_B
	JR TEST2B
WAIT2B: HALT
TEST2B: DI
	CALL FULL
	EI
	JR Z, WAIT2B
	LD A,(IST_B)
	BIT 7,A
	JR Z, ENDB
	RES 7,A
	LD (IST_B),A
	LD A,C
	OUT (S1BD),A
	POP HL
	RET
ENDB:   LD A,C
	DI
	CALL PUT
	EI
	POP HL
	RET
 
CSTS_B:
	PUSH HL
	LD HL, IBUF_B
	CALL EMPTY
	POP HL
	JR NZ, CDRESB
	XOR A
	RET
CDRESB: LD A, 0xFF
	OR A
	RET 
; --------------------- per port routines end B--------

; --------------------- per port routines start C--------
INTWR_C:
	PUSH AF
	PUSH HL
	LD HL, OBUF_C
	CALL EMPTY
	JR Z, EMPC
	
NOHDWC: CALL GET
	OUT (S2CD),A
RETRNC: POP HL
	POP AF
	EI
	RETI
EMPC:   LD HL, IST_C
	SET 7,(HL)
	LD A,0x28       ; reset pending interrupt
	OUT (S2CC),A
	JR RETRNC


INTRD_C:
	PUSH AF
	PUSH HL
	LD HL, IBUF_C
	CALL FULL
	IN A,(S2CD)
	JR Z, FULC
	AND 0x7F        ; 7 bit
	CALL PUT
	JR RETRNC
FULC:   LD HL, IST_C
	LD A,(HL)
	OR 0x20         ; overflow bit
	LD (HL),A
	JR RETRNC


INTER_C:
	PUSH AF
	PUSH HL
	LD A,1
	OUT (S2CC),A
	IN A,(S2CC)
	AND 0x30
	LD HL, IST_C
	OR (HL)
	LD (HL),A
	IN A, (S2CD)
	LD A,0x30
	OUT (S2CC),A
	JR RETRNC


INTST_C:                 ; external status change
	PUSH AF
	PUSH HL
	LD HL, IST_C
	LD A,(HL)
	AND 0xF5        ; mask away CTS and DCD
	LD (HL),A
	XOR A           ; get status
	OUT (S2CC),A
	IN A,(S2CC)
	AND 0x28        ; mask CTS and DCD bits
	RRA
	RRA
	OR (HL)
	LD (HL),A
	LD A, 0x10      ; reset status
	OUT (S2CC),A
	JR RETRNC


CI_C:
	PUSH HL
	LD HL, IBUF_C
	JR TEST1C
WAIT1C: HALT
TEST1C: CALL EMPTY
	JR Z, WAIT1C
	DI
	CALL GET
	EI
	POP HL
	RET

CO_C:   PUSH HL
	LD HL, OBUF_C
	JR TEST2C
WAIT2C: HALT
TEST2C: DI
	CALL FULL
	EI
	JR Z, WAIT2C
	LD A,(IST_C)
	BIT 7,A
	JR Z, ENDC
	RES 7,A
	LD (IST_C),A
	LD A,C
	OUT (S2CD), A
	POP HL
	RET
ENDC:   LD A,C
	DI
	CALL PUT
	EI
	POP HL
	RET

CSTS_C:
	PUSH HL
	LD HL, IBUF_C
	CALL EMPTY
	POP HL
	JR NZ, CDRESC
	XOR A
	RET
CDRESC: LD A, 0xFF
	OR A
	RET 
; --------------------- per port routines end C--------


; --------------------- per port routines start D--------
INTWR_D:
	PUSH AF
	PUSH HL
	LD HL, OBUF_D
	CALL EMPTY
	JR Z, EMPD
	
NOHDWD: CALL GET
	OUT (S2DD),A
RETRND: POP HL
	POP AF
	EI
	RETI
EMPD:   LD HL, IST_D
	SET 7,(HL)
	LD A,0x28       ; reset pending interrupt
	OUT (S2DC),A
	JR RETRND


INTRD_D:
	PUSH AF
	PUSH HL
	LD HL, IBUF_D
	CALL FULL
	IN A,(S2DD)
	JR Z, FULD
	AND 0x7F        ; 7 bit
	CALL PUT
	JR RETRND
FULD:   LD HL, IST_D
	LD A,(HL)
	OR 0x20         ; overflow bit
	LD (HL),A
	JR RETRND


INTER_D:
	PUSH AF
	PUSH HL
	LD A,1
	OUT (S2DC),A
	IN A,(S2DC)
	AND 0x30
	LD HL, IST_D
	OR (HL)
	LD (HL),A
	IN A,(S2DD)
	LD A,0x30
	OUT (S2DC),A
	JR RETRND


INTST_D:                 ; external status change
	PUSH AF
	PUSH HL
	LD HL, IST_D
	LD A,(HL)
	AND 0xF5        ; mask away CTS and DCD
	LD (HL),A
	XOR A           ; reset status
	OUT (S2DC),A
	IN A,(S2DC)
	AND 0x28        ; mask CTS and DCD bits
	RRA
	RRA
	OR (HL)
	LD (HL),A
	LD A,0x10       ; reset status
	OUT (S2DC),A
	JR RETRND


CI_D:
	PUSH HL
	LD HL, IBUF_D
	JR TEST1D
WAIT1D: HALT
TEST1D: CALL EMPTY
	JR Z, WAIT1D
	DI
	CALL GET
	EI
	POP HL
	RET

CO_D:   PUSH HL
	LD HL, OBUF_D
	JR TEST2D
WAIT2D: HALT
TEST2D: DI
	CALL FULL
	EI
	JR Z, WAIT2D
	LD A,(IST_D)
	BIT 7,A
	JR Z, ENDD
	RES 7,A
	LD (IST_D),A
	LD A,C
	OUT (S2DD),A
	POP HL
	RET
ENDD:   LD A,C
	DI
	CALL PUT
	EI
	POP HL
	RET
 
CSTS_D:
	PUSH HL
	LD HL, IBUF_D
	CALL EMPTY
	POP HL
	JR NZ, CDRESD
	XOR A
	RET
CDRESD: LD A, 0xFF
	OR A
	RET 
; --------------------- per port routines end D--------


	.org 0x0f00
INT_TABLE:
	.drw    INTCT_A         ; CTC interrupts: for test purposes only
	.drw    INTCT_B
	.drw    INTCT_C
	.drw    INTCT_D

	.org 0x0f10
	.drw    INTWR_B         ; SIO 1 channel B
	.drw    INTST_B
	.drw    INTRD_B
	.drw    INTER_B

	.drw    INTWR_A         ; SIO 1 channel A
	.drw    INTST_A
	.drw    INTRD_A
	.drw    INTER_A

	.org 0x0f20
	.drw    INTWR_D         ; SIO 2 channel D
	.drw    INTST_D
	.drw    INTRD_D
	.drw    INTER_D

	.drw    INTWR_C         ; SIO 2 channel C
	.drw    INTST_C
	.drw    INTRD_C
	.drw    INTER_C

	.end
