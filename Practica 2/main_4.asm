; Microcontroladores
; PRÁCTICA DE SECUENCIA DE LUCES CON TIMER0
; Programa para el PIC16F887 que controla una secuencia de ocho LEDs.
; La selección del patrón se realiza mediante un DipSwitch conectado a PORTA <RA2:RA0>.
; Los LEDs están conectados al puerto B (PORTB) <RB7:RB0>.
; El Timer0 se utiliza para generar los retardos entre los cambios de las luces.
; Autores: Juan Jose Yacumal, Juan Carlos Ruales
; Institución: Universidad del Cauca
; Fecha: 7-09-2026


    LIST    P=16F887
#include "p16f887.inc"

; CONFIGURACIÓN DE FUSIBLES
 __CONFIG _CONFIG1, _FOSC_INTRC_CLKOUT & _WDTE_OFF & _PWRTE_ON & _MCLRE_OFF & _CP_OFF & _CPD_OFF & _BOREN_ON & _IESO_ON & _FCMEN_ON & _LVP_OFF
 __CONFIG _CONFIG2, _BOR4V_BOR40V & _WRT_OFF


; VARIABLES EN RAM

; cont_retardo: contador utilizado para repetir el tiempo de espera
; opcion: almacena la selección realizada mediante el DipSwitch

    CBLOCK 0x20
        cont_retardo    ; Contador auxiliar para multiplicar el retardo
        opcion          ; Almacena la lectura del DipSwitch
    ENDC

RES_VECT  CODE    0x0000  ; Vector de Reset
    GOTO    START

MAIN_PROG CODE            ; Inicio del programa principal

START

; 1. CONFIGURACIÓN DE PUERTOS

; PORTA se utiliza como entrada para el DipSwitch.
; PORTB se utiliza como salida para controlar los LEDs.
; Se desactivan las funciones analógicas para trabajar en modo digital.

    BANKSEL ANSEL
    CLRF    ANSEL       ; Puerto A como Digital
    CLRF    ANSELH      ; Puerto B como Digital
    
    BANKSEL TRISA
    MOVLW   0xFF
    MOVWF   TRISA       ; PORTA como Entrada (DipSwitch)
    CLRF    TRISB       ; PORTB como Salida (LEDs)


; 2. CONFIGURACIÓN DEL TIMER0

; Se configura Timer0 utilizando el prescaler 1:256.
; Timer0 será utilizado como base de tiempo para los retardos.

    BANKSEL OPTION_REG
    MOVLW   b'11010111' ; Configuración en binario corregida (Prescaler 1:256)
    MOVWF   OPTION_REG  


; 3. BUCLE PRINCIPAL
; Lee el DipSwitch y selecciona uno de los 8 patrones.
; RA0, RA1 y RA2 forman un número de 3 bits:
; 000 = Patrón 0 ... 111 = Patrón 7.

LOOP
    BANKSEL PORTA
    MOVF    PORTA, W    ; Lee las entradas del PORTA
    ANDLW   b'00000111' ; Toma únicamente los primeros 3 bits (RA0, RA1, RA2)
    MOVWF   opcion      ; Guarda la selección del DipSwitch


; 4. SELECCIÓN DEL PATRÓN MEDIANTE TABLA DE SALTOS
; Se utiliza opcion para seleccionar uno de los ocho patrones.
; ADDWF PCL,F modifica la posición de salto según el valor leído.

    MOVF    opcion, W
    ADDWF   PCL, F      ; Salta según el número seleccionado (0 al 7)

    GOTO    PATRON_0
    GOTO    PATRON_1
    GOTO    PATRON_2
    GOTO    PATRON_3
    GOTO    PATRON_4
    GOTO    PATRON_5
    GOTO    PATRON_6
    GOTO    PATRON_7


; 5. RUTINAS DE LOS PATRONES DE LUCES



; PATRÓN 0: TODOS LOS LEDS PARPADEAN
; Enciende todos los LEDs y posteriormente los apaga.

PATRON_0:
    MOVLW   0xFF
    MOVWF   PORTB
    CALL    DELAY_200MS
    CLRF    PORTB
    CALL    DELAY_200MS
    GOTO    LOOP


; PATRÓN 1: DESPLAZAMIENTO HACIA LA IZQUIERDA
; Utiliza RLF para desplazar el LED encendido.
; PAT1_LOOP es el bucle que repite el desplazamiento.

PATRON_1:
    MOVLW   0x01
    MOVWF   PORTB

PAT1_LOOP:              ; BUCLE DEL PATRÓN 1
    CALL    DELAY_200MS
    RLF     PORTB, F    ; Desplaza los bits hacia la izquierda
    BTFSS   STATUS, C   ; Comprueba si se llegó al final
    GOTO    PAT1_LOOP   ; Repite el desplazamiento
    GOTO    LOOP


; PATRÓN 2: DESPLAZAMIENTO HACIA LA DERECHA
; Utiliza RRF para desplazar el LED encendido.
; PAT2_LOOP es el bucle que repite el desplazamiento.

PATRON_2:
    MOVLW   0x80
    MOVWF   PORTB

PAT2_LOOP:              ; BUCLE DEL PATRÓN 2
    CALL    DELAY_200MS
    RRF     PORTB, F    ; Desplaza los bits hacia la derecha
    BTFSS   STATUS, C   ; Comprueba si se llegó al final
    GOTO    PAT2_LOOP   ; Repite el desplazamiento
    GOTO    LOOP


; PATRÓN 3: CONTADOR BINARIO
; INCF incrementa el valor actual de PORTB.
; Cada incremento cambia la combinación de los 8 LEDs.

PATRON_3:
    INCF    PORTB, F
    CALL    DELAY_200MS
    GOTO    LOOP


; PATRÓN 4: AUTO FANTÁSTICO
; El LED se desplaza hacia un extremo y luego regresa.
; PAT4_IZQ y PAT4_DER forman los dos bucles de desplazamiento.

PATRON_4:
    MOVLW   0x01
    MOVWF   PORTB

PAT4_IZQ:               ; BUCLE DE DESPLAZAMIENTO DE IDA
    CALL    DELAY_200MS
    RLF     PORTB, F
    BTFSS   PORTB, 7    ; Comprueba si llegó al bit 7
    GOTO    PAT4_IZQ

PAT4_DER:               ; BUCLE DE DESPLAZAMIENTO DE REGRESO
    CALL    DELAY_200MS
    RRF     PORTB, F
    BTFSS   PORTB, 0    ; Comprueba si llegó al bit 0
    GOTO    PAT4_DER
    GOTO    LOOP


; PATRÓN 5: ALTERNADO
; Alterna dos combinaciones diferentes de LEDs.

PATRON_5:
    MOVLW   b'10101010'
    MOVWF   PORTB
    CALL    DELAY_200MS
    MOVLW   b'01010101'
    MOVWF   PORTB
    CALL    DELAY_200MS
    GOTO    LOOP


; PATRÓN 6: CENTRO HACIA AFUERA
; Se cargan diferentes combinaciones para producir un desplazamiento
; progresivo desde el centro hacia los extremos.

PATRON_6:
    MOVLW   b'00011000'
    MOVWF   PORTB
    CALL    DELAY_200MS
    MOVLW   b'00100100'
    MOVWF   PORTB
    CALL    DELAY_200MS
    MOVLW   b'01000010'
    MOVWF   PORTB
    CALL    DELAY_200MS
    MOVLW   b'10000001'
    MOVWF   PORTB
    CALL    DELAY_200MS
    GOTO    LOOP

; -------------------------------------------------------------------
; PATRÓN 7: AFUERA HACIA EL CENTRO
; Es el proceso inverso al patrón 6.
; Los LEDs comienzan en los extremos y avanzan hacia el centro.
; -------------------------------------------------------------------
PATRON_7:
    MOVLW   b'10000001'
    MOVWF   PORTB
    CALL    DELAY_200MS
    MOVLW   b'01000010'
    MOVWF   PORTB
    CALL    DELAY_200MS
    MOVLW   b'00100100'
    MOVWF   PORTB
    CALL    DELAY_200MS
    MOVLW   b'00011000'
    MOVWF   PORTB
    CALL    DELAY_200MS
    GOTO    LOOP


; 6. SUBRUTINA DE RETARDO DE ~200 ms USANDO TIMER0

; Se utiliza Timer0 para generar aproximadamente 10 ms por ciclo.
; cont_retardo repite este proceso 20 veces para obtener ~200 ms.

DELAY_200MS
    MOVLW   D'20'               ; Carga 20 repeticiones
    MOVWF   cont_retardo        ; Inicializa el contador de software

RET_LOOP                         ; BUCLE PRINCIPAL DEL RETARDO
    BANKSEL TMR0
    MOVLW   D'61'               ; Precarga del TMR0 (256 - 195) para 10ms
    MOVWF   TMR0
    BCF     INTCON, T0IF        ; Limpia la bandera de desbordamiento

ESPERA_TMR0:                     ; BUCLE DE ESPERA DE TIMER0
    BTFSS   INTCON, T0IF         ; ¿TMR0 terminó de contar?
    GOTO    ESPERA_TMR0          ; Si no terminó, continúa esperando
    
    DECFSZ  cont_retardo, F      ; Decrementa el contador de ciclos
    GOTO    RET_LOOP             ; Si no llegó a cero, repite el proceso
    RETURN                       ; Termina el retardo y regresa al patrón

    END