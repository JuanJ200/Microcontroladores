; Programa para el PIC16F887 que suma dos números de cuatro bits (A y B).
; A corresponde a la parte baja del puerto A (PORTA) <A3:A0>;
; B corresponde a la parte alta del puerto A (PORTA) <A7:A4>;
; El resultado de la operación es mostrado en el puerto B (PORTB) <B7:B0>;
; Autores: Juan Jose Yacumal, Juan Carlos Ruales
; Institución: Universidad del Cauca
; Fecha: 13-08-2026
    

; ALU para PIC16F887
;
; PORTA<3:0>  = Operando A
; PORTA<7:4>  = Operando B
; PORTC<2:0>  = Seleccion de operacion
; PORTB<7:0>  = Resultado
;
; Seleccion:
; 000 = A + B
; 001 = A - B
; 010 = A * B
; 011 = A / B
; 100 = A AND B
; 101 = A OR B
; 110 = A XOR B
; 111 = NOT A
;


        LIST    P=16F887
        #include <p16f887.inc>


; CONFIGURACION DE FUSES (OSCILADOR INTERNO Y RESET)

        __CONFIG _CONFIG1, _INTRC_OSC_NOCLKOUT & _WDT_OFF & _PWRTE_ON & _MCLRE_ON & _CP_OFF & _CPD_OFF & _BOREN_ON & _IESO_OFF & _FCMEN_OFF & _LVP_OFF


; VARIABLES


operandoA   EQU     20h
operandoB   EQU     21h
resultado   EQU     22h
contador    EQU     23h
cociente    EQU     24h
residuo     EQU     25h
operacion   EQU     26h


; VECTOR DE RESET


        RES_VECT    CODE    0x0000
        GOTO        START


; PROGRAMA PRINCIPAL


MAIN_PROG CODE

START


; CONFIGURACION DE PUERTOS


        ; PORTA como entrada
        BANKSEL     PORTA
        CLRF        PORTA

        ; PORTB como salida
        CLRF        PORTB

        ; PORTC como entrada
        CLRF        PORTC

        ; Deshabilitar entradas analogicas
        BANKSEL     ANSEL
        CLRF        ANSEL
        CLRF        ANSELH

        ; Configurar PORTA como entrada
        BANKSEL     TRISA
        MOVLW       0xFF
        MOVWF       TRISA

        ; Configurar PORTB como salida
        CLRF        TRISB

        ; Configurar PORTC como entrada
        MOVLW       0xFF
        MOVWF       TRISC


; BUCLE PRINCIPAL


LOOP

        BANKSEL     PORTA


; OBTENER OPERANDO A
; PORTA<3:0>


        MOVF        PORTA,W
        ANDLW       0x0F
        MOVWF       operandoA


; OBTENER OPERANDO B
; PORTA<7:4>


        MOVF        PORTA,W
        ANDLW       0xF0
        MOVWF       operandoB

        ; Pasar B de <7:4> a <3:0>
        SWAPF       operandoB,F
        MOVLW       0x0F
        ANDWF       operandoB,F


; OBTENER OPERACION
; PORTC<2:0>


        MOVF        PORTC,W
        ANDLW       0x07
        MOVWF       operacion


; SELECCION DE OPERACION


        ; 000 = SUMA
        MOVF        operacion,W
        XORLW       0x00
        BTFSC       STATUS,Z
        GOTO        SUMA

        ; 001 = RESTA
        MOVF        operacion,W
        XORLW       0x01
        BTFSC       STATUS,Z
        GOTO        RESTA

        ; 010 = MULTIPLICACION
        MOVF        operacion,W
        XORLW       0x02
        BTFSC       STATUS,Z
        GOTO        MULTIPLICACION

        ; 011 = DIVISION
        MOVF        operacion,W
        XORLW       0x03
        BTFSC       STATUS,Z
        GOTO        DIVISION

        ; 100 = AND
        MOVF        operacion,W
        XORLW       0x04
        BTFSC       STATUS,Z
        GOTO        AND_OP

        ; 101 = OR
        MOVF        operacion,W
        XORLW       0x05
        BTFSC       STATUS,Z
        GOTO        OR_OP

        ; 110 = XOR
        MOVF        operacion,W
        XORLW       0x06
        BTFSC       STATUS,Z
        GOTO        XOR_OP

        ; 111 = NOT
        GOTO        NOT_OP


; SUMA
; resultado = A + B


SUMA

        MOVF        operandoA,W
        ADDWF       operandoB,W
        MOVWF       resultado

        GOTO        MOSTRAR


; RESTA
; resultado = A - B


RESTA

        MOVF        operandoB,W
        SUBWF       operandoA,W
        MOVWF       resultado

        GOTO        MOSTRAR


; MULTIPLICACION
; resultado = A * B
;
; Se realizan B sumas de A.


MULTIPLICACION

        CLRF        resultado

        MOVF        operandoB,W
        MOVWF       contador

MULT_LOOP

        MOVF        contador,W
        BTFSC       STATUS,Z
        GOTO        MULT_FIN

        MOVF        operandoA,W
        ADDWF       resultado,F

        DECFSZ      contador,F
        GOTO        MULT_LOOP

MULT_FIN

        GOTO        MOSTRAR


; DIVISION
; resultado = A / B
;
; Division entera mediante restas sucesivas.
;
; Si B = 0:
; resultado = FFh


DIVISION

        ; Verificar division entre cero
        MOVF        operandoB,W
        BTFSC       STATUS,Z
        GOTO        DIV_CERO

        CLRF        cociente

        MOVF        operandoA,W
        MOVWF       residuo

DIV_LOOP

        MOVF        operandoB,W

        ; W = residuo - B
        SUBWF       residuo,W

        ; Si C=0 significa que residuo < B
        BTFSS       STATUS,C
        GOTO        DIV_FIN

        ; Guardar nuevo residuo
        MOVWF       residuo

        ; Incrementar cociente
        INCF        cociente,F

        GOTO        DIV_LOOP

DIV_FIN

        MOVF        cociente,W
        MOVWF       resultado

        GOTO        MOSTRAR

DIV_CERO

        ; Division entre cero
        MOVLW       0xFF
        MOVWF       resultado

        GOTO        MOSTRAR


; AND
; resultado = A AND B


AND_OP

        MOVF        operandoA,W
        ANDWF       operandoB,W
        MOVWF       resultado

        GOTO        MOSTRAR


; OR
; resultado = A OR B


OR_OP

        MOVF        operandoA,W
        IORWF       operandoB,W
        MOVWF       resultado

        GOTO        MOSTRAR


; XOR
; resultado = A XOR B


XOR_OP

        MOVF        operandoA,W
        XORWF       operandoB,W
        MOVWF       resultado

        GOTO        MOSTRAR


; NOT
; resultado = NOT A


NOT_OP

        COMF        operandoA,W
        MOVWF       resultado

        GOTO        MOSTRAR


; MOSTRAR RESULTADO


MOSTRAR

        MOVF        resultado,W
        MOVWF       PORTB

        GOTO        LOOP



        END