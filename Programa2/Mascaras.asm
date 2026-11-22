; Operador de mascaras AND, OR y XOR para bytes (8086/TASM 4.1).
.MODEL SMALL
.STACK 100h

.DATA
titulo      DB 13,10,'OPERADOR DE MASCARAS LOGICAS',13,10,'$'
msgdato     DB 'Ingrese el byte hexadecimal: $'
msgmascara  DB 13,10,'Ingrese la mascara hexadecimal: $'
menu        DB 13,10,'1. AND',13,10,'2. OR',13,10,'3. XOR',13,10,'Seleccione (1-3): $'
msginval    DB 13,10,'Entrada invalida; use de 1 a 2 digitos hexadecimales.',13,10,'$'
msgopbad    DB 13,10,'Opcion invalida. Seleccione 1, 2 o 3.',13,10,'$'
msgres      DB 13,10,'Resultado binario: $'
msgfin      DB 13,10,'$'
valor       DB ?
mascara     DB ?
buffer      DB 2,0,2 DUP(0)

.CODE
MAIN PROC
    MOV AX,@DATA
    MOV DS,AX
    LEA DX,titulo
    CALL PRINT_STRING
LEER_DATO:
    LEA DX,msgdato
    CALL PRINT_STRING
    CALL READ_HEX_BYTE
    JNC DATO_OK
    LEA DX,msginval
    CALL PRINT_STRING
    JMP LEER_DATO
DATO_OK:
    MOV valor,AL
LEER_MASCARA:
    LEA DX,msgmascara
    CALL PRINT_STRING
    CALL READ_HEX_BYTE
    JNC MASCARA_OK
    LEA DX,msginval
    CALL PRINT_STRING
    JMP LEER_MASCARA
MASCARA_OK:
    MOV mascara,AL
LEER_OPCION:
    LEA DX,menu
    CALL PRINT_STRING
    MOV AH,01h
    INT 21h
    CMP AL,'1'
    JE OPERAR_AND
    CMP AL,'2'
    JE OPERAR_OR
    CMP AL,'3'
    JE OPERAR_XOR
    LEA DX,msgopbad
    CALL PRINT_STRING
    JMP LEER_OPCION
OPERAR_AND:
    MOV AL,valor
    MOV BL,mascara
    AND AL,BL
    JMP MOSTRAR
OPERAR_OR:
    MOV AL,valor
    MOV BL,mascara
    OR AL,BL
    JMP MOSTRAR
OPERAR_XOR:
    MOV AL,valor
    MOV BL,mascara
    XOR AL,BL
MOSTRAR:
    LEA DX,msgres
    CALL PRINT_STRING
    CALL PRINT_BINARY
    LEA DX,msgfin
    CALL PRINT_STRING
    MOV AX,4C00h
    INT 21h
MAIN ENDP

PRINT_STRING PROC NEAR
    MOV AH,09h
    INT 21h
    RET
PRINT_STRING ENDP

; Lee uno o dos caracteres y retorna el byte en AL, o CF=1 si son invalidos.
READ_HEX_BYTE PROC NEAR
    PUSH BX
    PUSH CX
    PUSH SI
    MOV AH,0Ah
    LEA DX,buffer
    INT 21h
    XOR BX,BX
    XOR CX,CX
    MOV CL,buffer+1
    CMP CL,1
    JB HEX_ERROR
    CMP CL,2
    JA HEX_ERROR
    LEA SI,buffer+2
HEX_LOOP:
    MOV AL,[SI]
    CALL READ_NIBBLE
    JC HEX_ERROR
    SHL BX,1
    SHL BX,1
    SHL BX,1
    SHL BX,1
    OR BL,AL
    INC SI
    LOOP HEX_LOOP
    MOV AL,BL
    CLC
    JMP HEX_EXIT
HEX_ERROR:
    STC
HEX_EXIT:
    POP SI
    POP CX
    POP BX
    RET
READ_HEX_BYTE ENDP

READ_NIBBLE PROC NEAR
    CMP AL,'0'
    JB NIBBLE_BAD
    CMP AL,'9'
    JBE NIBBLE_DIGIT
    CMP AL,'A'
    JB NIBBLE_LOWER
    CMP AL,'F'
    JBE NIBBLE_UPPER
NIBBLE_LOWER:
    CMP AL,'a'
    JB NIBBLE_BAD
    CMP AL,'f'
    JA NIBBLE_BAD
    SUB AL,'a'-10
    CLC
    RET
NIBBLE_UPPER:
    SUB AL,'A'-10
    CLC
    RET
NIBBLE_DIGIT:
    SUB AL,'0'
    CLC
    RET
NIBBLE_BAD:
    STC
    RET
READ_NIBBLE ENDP

; Desplaza el byte hacia la izquierda y envia cada bit superior a pantalla.
; El conteo fijo de ocho iteraciones garantiza exactamente ocho caracteres.
PRINT_BINARY PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    MOV BL,AL
    MOV CX,8
BIT_LOOP:
    SHL BL,1
    JC BIT_ONE
    MOV DL,'0'
    JMP BIT_PRINT
BIT_ONE:
    MOV DL,'1'
BIT_PRINT:
    MOV AH,02h
    INT 21h
    LOOP BIT_LOOP
    POP CX
    POP BX
    POP AX
    RET
PRINT_BINARY ENDP

END MAIN
