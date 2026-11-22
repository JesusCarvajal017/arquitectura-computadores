; Contador ascendente hexadecimal de 0 a F para 8086 y TASM 4.1.
.MODEL SMALL
.STACK 100h

.DATA
titulo  DB 13,10,'CONTADOR HEXADECIMAL DE 0 A F',13,10,'$'
salto   DB 13,10,'$'

.CODE
MAIN PROC
    MOV AX,@DATA
    MOV DS,AX
    LEA DX,titulo
    MOV AH,09h
    INT 21h

    MOV BX,0          ; BX contiene el valor hexadecimal actual.
    MOV CX,16         ; Se realizaran exactamente 16 iteraciones.

CONTAR:
    CMP BX,9
    JBE ES_DIGITO
    ; Para 10..15 se suma 7 y luego '0': se obtiene A..F.
    MOV DL,BL
    ADD DL,7
    JMP MOSTRAR
ES_DIGITO:
    MOV DL,BL
MOSTRAR:
    ADD DL,'0'
    MOV AH,02h
    INT 21h
    LEA DX,salto
    MOV AH,09h
    INT 21h

    INC BX             ; Avanza al siguiente numero, de uno en uno.
    CMP BX,16
    JNZ CONTINUAR
    JMP FIN_CONTADOR
CONTINUAR:
    LOOP CONTAR        ; Decrementa CX y repite mientras CX != 0.

FIN_CONTADOR:
    MOV AX,4C00h
    INT 21h
MAIN ENDP

END MAIN
