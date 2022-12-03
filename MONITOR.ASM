        .org 0x0000
        JP START
CI:     JP 0x0000
CO:     JP 0x0000

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
        JP CO

PRHL:   ; HL in 4 digits ausgeben
        LD A, H
        CALL PRAC
        LD A, L
        JR PRAC

EXPR:   ; Hexzahl in HL eingeben, Terminator in A speichern
        LD HL, 0x000
EX0:    CALL CI
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
        CALL CO
        POP AF
        LD C, A
        RET

CRLF:   LD C, '\r'
        CALL CO
        LD C, '\n'
        JR CO

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

START:
MLOOP:  CALL CRLF
        LD HL, STRG1
        CALL LPRINT
        JR LBL1
STRG1:  .db "SYS>\0"
LBL1:   CALL CI   
        LD C, A
        CALL CO
        CP 'E'
        JR Z, ENTER
        CP 'G'
        JR Z, GOEX
        CP 'Q'
        JR Z, QUERY
        JR MLOOP

GOEX:   CALL EXPR
        LD DE, MLOOP
        PUSH DE
        PUSH HL
        RET

QUERY:  CALL CI
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
        CALL CO
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
        CALL CO
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
        CALL CO
        DJNZ LPP
        LD C, ':'
        CALL CO
        LD A, (DE)
        AND 0x7F
        CP 0x20
        JR C, CONT
        CP 0x7F
        JR Z, CONT
        LD C, A
        JR CONT1
CONT:   LD C, ' ' 
CONT1:  CALL CO
        LD C, ':'
        CALL CO
LOOP2:  CALL CI
        LD C, A
        CALL CO
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
TEXT:   CALL CI
        CALL OUTCH
        CP '\''
        JR Z, CONTE
        CP 0x7F
        JR Z, BACK
        LD (DE), A
        INC DE
        JR TEXT
CONTE:  CALL CI
        CALL OUTCH
        CP ' '
        JP Z, LOOP2
        EX DE, HL
        JP LOOP
BACK:   LD C, 8
        CALL CO
        LD C, ' '
        CALL CO
        LD C, 8
        CALL CO
        DEC DE
        JR TEXT
        .end

