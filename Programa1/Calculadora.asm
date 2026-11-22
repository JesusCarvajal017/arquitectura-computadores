; Calculadora de suma y resta hexadecimal para 8086 y TASM 4.1.
.MODEL SMALL
.STACK 100h

.DATA
titulo      DB 13,10,'CALCULADORA HEXADECIMAL (00h a FFh)',13,10,'$'
msg1        DB 'Ingrese el primer byte hexadecimal: $'
msg2        DB 13,10,'Ingrese el segundo byte hexadecimal: $'
msgop       DB 13,10,'Operacion (+ o -): $'
msgres      DB 13,10,'Resultado: $'
msgcarry    DB 13,10,'Carry: $'
msgborrow   DB 13,10,'Borrow: $'
msgbadhex   DB 13,10,'Entrada invalida. Use de 1 a 2 digitos hexadecimales.',13,10,'$'
msgbadop    DB 13,10,'Operador invalido. Escriba + o -.',13,10,'$'
msgagain    DB 13,10,'$'
msgH        DB 'h$'
msgzero     DB '0$'
msgone      DB '1$'
opcion      DB ?
valor1      DB ?
valor2      DB ?
indicador   DB ?
; DOS funcion 0Ah: capacidad incluye espacio para ENTER (CR).
; Capacidad 3 permite dos digitos hexadecimales y el retorno de carro.
buffer      DB 3,0,3 DUP(0)

.CODE
MAIN PROC
    MOV AX,@DATA
    MOV DS,AX
    LEA DX,titulo
    CALL PRINT_STRING

LEER_PRIMERO:
    LEA DX,msg1
    CALL PRINT_STRING
    CALL READ_HEX_BYTE
    JNC PRIMERO_OK
    LEA DX,msgbadhex
    CALL PRINT_STRING
    JMP LEER_PRIMERO
PRIMERO_OK:
    MOV valor1,AL

LEER_SEGUNDO:
    LEA DX,msg2
    CALL PRINT_STRING
    CALL READ_HEX_BYTE
    JNC SEGUNDO_OK
    LEA DX,msgbadhex
    CALL PRINT_STRING
    JMP LEER_SEGUNDO
SEGUNDO_OK:
    MOV valor2,AL

LEER_OPERADOR:
    LEA DX,msgop
    CALL PRINT_STRING
    MOV AH,01h
    INT 21h
    MOV opcion,AL
    CMP AL,'+'
    JE HACER_SUMA
    CMP AL,'-'
    JE HACER_RESTA
    LEA DX,msgbadop
    CALL PRINT_STRING
    JMP LEER_OPERADOR

HACER_SUMA:
    MOV AL,valor1
    MOV BL,valor2
    ADD AL,BL
    ; Capturar CF inmediatamente; PUSHF/POP no modifican banderas.
    PUSHF
    POP DX
    MOV CX,0
    MOV CL,AL
    AND DX,1
    MOV indicador,DL
    JZ SUMA_SIN_ACARREO
    MOV CH,1
SUMA_SIN_ACARREO:
    LEA DX,msgres
    CALL PRINT_STRING
    MOV AX,CX
    CALL PRINT_HEX_WORD
    LEA DX,msgH
    CALL PRINT_STRING
    LEA DX,msgcarry
    CALL PRINT_STRING
    CMP indicador,0
    JE MOSTRAR_CERO_S
    LEA DX,msgone
    CALL PRINT_STRING
    JMP SALIR
MOSTRAR_CERO_S:
    LEA DX,msgzero
    CALL PRINT_STRING
    JMP SALIR

HACER_RESTA:
    MOV AL,valor1
    MOV BL,valor2
    SUB AL,BL
    ; En resta sin signo, CF=1 indica préstamo.
    PUSHF
    POP DX
    MOV BL,AL
    AND DX,1
    MOV indicador,DL
    LEA DX,msgres
    CALL PRINT_STRING
    MOV AL,BL
    CALL PRINT_HEX_BYTE
    LEA DX,msgH
    CALL PRINT_STRING
    LEA DX,msgborrow
    CALL PRINT_STRING
    CMP indicador,0
    JE MOSTRAR_CERO_R
    LEA DX,msgone
    CALL PRINT_STRING
    JMP SALIR
MOSTRAR_CERO_R:
    LEA DX,msgzero
    CALL PRINT_STRING
    JMP SALIR

SALIR:
    MOV AX,4C00h
    INT 21h
MAIN ENDP

; Imprime una cadena terminada en '$'. Entrada: DS:DX.
PRINT_STRING PROC NEAR
    MOV AH,09h
    INT 21h
    RET
PRINT_STRING ENDP

; Lee hasta dos dígitos hexadecimales con DOS. Retorna AL=byte y CF=0;
; ante caracteres o longitud incorrectos retorna CF=1.
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
    ; Acumula el siguiente nibble: valor = valor*16 + nibble.
    SHL BX,1
    SHL BX,1
    SHL BX,1
    SHL BX,1
    XOR AH,AH
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

; Convierte un carácter ASCII hexadecimal en nibble AL; CF=1 si inválido.
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

; Imprime dos dígitos hexadecimales de AL.
PRINT_HEX_BYTE PROC NEAR
    PUSH AX
    PUSH BX
    MOV BL,AL
    SHR AL,1
    SHR AL,1
    SHR AL,1
    SHR AL,1
    CALL PRINT_NIBBLE
    MOV AL,BL
    AND AL,0Fh
    CALL PRINT_NIBBLE
    POP BX
    POP AX
    RET
PRINT_HEX_BYTE ENDP

; Imprime tres dígitos hexadecimales de AX (000h a 1FFh).
PRINT_HEX_WORD PROC NEAR
    PUSH AX
    MOV AL,AH
    AND AL,0Fh
    CALL PRINT_NIBBLE
    POP AX
    PUSH AX
    SHR AL,1
    SHR AL,1
    SHR AL,1
    SHR AL,1
    CALL PRINT_NIBBLE
    POP AX
    PUSH AX
    AND AL,0Fh
    CALL PRINT_NIBBLE
    POP AX
    RET
PRINT_HEX_WORD ENDP

; Imprime el nibble de AL como 0-9 o A-F.
PRINT_NIBBLE PROC NEAR
    AND AL,0Fh
    CMP AL,9
    JBE NIBBLE_TO_ASCII
    ADD AL,7
NIBBLE_TO_ASCII:
    ADD AL,'0'
    MOV DL,AL
    MOV AH,02h
    INT 21h
    RET
PRINT_NIBBLE ENDP

END MAIN
