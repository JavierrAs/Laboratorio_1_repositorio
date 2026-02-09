/*
* POSTLAB.asm
*
* Creado: Javier Sipac 
* Autor : Javier Sipac
* Descripción: PostLab 1, se realizo un sumador, que muestre el resultado de sumar los dos contadores, el resultado de esto se vera en 4 leds
*adicionalmente se le agrego un quinto led que funciona cuando haya un overflow o carry.
*/
/****************************************/
// Encabezado (Definición de Registros, Variables y Constantes)
.include "M328PDEF.inc"
.org 0x00
RJMP START


START:
	// Configuración de la pila
	LDI R16, LOW(RAMEND)
	OUT SPL, R16
	LDI R16, HIGH(RAMEND)
	OUT SPH, R16

	//Configurar clock a 1 MHz
	//LDI  R16, 0x80		 ; Habilitar cambio
	//STS  CLKPR, R16      ; permite modificar el prescaler
	//LDI  R16, 0x04       ;Prescaler = 16 (16MHz/16 = 1MHz)
	//STS  CLKPR, R16		 ; aplica el prescaler seleccionado

    //****************** CONTADOR 1 ***********************
    LDI R16, 0b00111100 ; configuro entradas PB0/PB1 y salidas PB2-PB5
    OUT DDRB, R16
    LDI R16, 0b00000011 ; configuro las entradas como pull-ups
    OUT PORTB, R16

    //****************** CONTADOR 2 ***********************
    LDI R16, 0b00001111 ; configuro entradas PC4/PC5 y salidas del PC0-PC3
    OUT DDRC, R16
    LDI R16, 0b00110000 ; configuro las entradas como pull-ups
    OUT PORTC, R16

    // **************** SUMADOR ************************
    LDI R16, 0b11111000 ;Configuro entradas PD2 Y salidas PD3-PD7
    OUT DDRD, R16
    LDI R16, 0b00000100 ; CONFIGURO PULL-UPS
    OUT PORTD, R16

    CLR R17        ; contador 1
    CLR R19        ; contador 2

LOOP:
    CALL CONTADOR_1			 ; llama a la subrutina del contador 1
    CALL CONTADOR_2			 ; llama a la subrutina del contador 2
    CALL MOSTRAR_RESULTADO	 ; llama a la subrutina del sumador
    RJMP LOOP

// ****************** CONTADOR *************************
CONTADOR_1:
    SBIC PINB, 0            ; si PB0 = 1, no presionado salta la siguiente instrucción
    RJMP REVISAR_RESTAR_1   ; si PB0 no está presionado, revisa botón de resta
    INC R17                 ; si pb0 = 0, este presionado comenzara a incrementar

ESPERAR_SOLTAR_SUMAR_1:
    SBIS PINB, 0			; va a esperar mientras el PB0=0 siga presionado, para evitar rebotes
    RJMP ESPERAR_SOLTAR_SUMAR_1 
    RJMP MOSTRAR_1	        ; pero cuando el boton se suelta, hara un jump a mostrar 1, donde nos mostrar el valor en las leds

REVISAR_RESTAR_1:          
    SBIC PINB, 1			; si PB1 = 1, no presionado salta la siguiente instrucción
    RJMP MOSTRAR_1			; si PB1 no está presionado, muestra sin restar
    DEC R17					; pero cuando PB1= 0, presionado comenzara a decrementar

ESPERAR_SOLTAR_RESTAR_1:
    SBIS PINB, 1			;va a esperar mientra el PB1 = 0 este presionado, hara el jump a Esperar soltar resta 1 para evitar que decremente demas
    RJMP ESPERAR_SOLTAR_RESTAR_1 

MOSTRAR_1:
    ANDI R17, 0x0F          ; es nuesto limite de bits que tiene el contador que va de 0 a 15
    MOV R16, R17			; copia el valor a 16 para mostrarla
    LSL R16					; desplaza 2 bits para que coincida en los pines de salida que definimos de PB2 a PB5
    LSL R16
    ORI R16, 0b00000011		; mantendra avtivo los pull ups de pb0 y pb1
    OUT PORTB, R16			; mostrara el valor del contador
    RET						; Nos regresa al loop

; ================= CONTADOR 2 =================
; Practicamente se copio el mismo código del contador 1 para realizar el contador 2, solo con ciertos cambios
CONTADOR_2:
    SBIC PINC, 4			; Si pc4 = 1,  no esta presionado hara un salto a la siguiente instruccion
    RJMP REVISAR_RESTAR_2	; si PB4 no está presionado, revisa botón de resta 
    INC R19					; si pb4 = 0, este presionado comenzara a incrementar

ESPERAR_SOLTAR_SUMAR_2:
    SBIS PINC, 4			; va a esperar mientras el PB4=0 siga presionado, para evitar rebotes
    RJMP ESPERAR_SOLTAR_SUMAR_2
    RJMP MOSTRAR_2			; pero cuando el boton se suelta, hara un jump a mostrar 2, donde nos mostrar el valor en las leds

REVISAR_RESTAR_2:
    SBIC PINC, 5			; si PB5 = 1, no presionado salta la siguiente instrucción
    RJMP MOSTRAR_2			; si PB5 no está presionado, muestra sin restar
    DEC R19					; pero cuando PB5= 0, presionado comenzara a decrementar

ESPERAR_SOLTAR_RESTAR_2:
    SBIS PINC, 5			;va a esperar mientra el PB5 = 0 este presionado, hara el jump a Esperar soltar resta 2 para evitar que decremente demas
    RJMP ESPERAR_SOLTAR_RESTAR_2

MOSTRAR_2:
    ANDI R19, 0x0F			; nuestro limite de 0 a 15
    MOV R16, R19			; copia el valor en 16
    ORI R16, 0b00110000		; mantiene los pull ups de pC4 Y PC5
    OUT PORTC, R16			; Muestra el valor en los leds
    RET						; Nos regresa al loop

//******************* SUMADOR ************************
MOSTRAR_RESULTADO:
    SBIC PIND, 2			; Si el PD2 = 1 no esta resionado, salta a la siguiente instruccion
    RJMP FIN_RESULTADO		; Si el boton no esta presionado no calcula la suma
  
	//********** suma ******************
    MOV R20, R17			; Copia el valor del contador 1 a R20
    ADD R20, R19			; Suma el contador 2 ósea el registro R19 al valor de R20
							; si la suma supera 0x0F se activa el overflow 
	
	//**********overflow*************
    CBI PORTD, 3			; Limpia el bit PD3 del puerto D, apaga el led del overflow antes de realizar la suma
    SBRC R20, 4				; Va a revisar el bit 4 del resultado de R20, si el bit 4 es 0, se salta la siguiente instrucción pero  
							; si el bit 4 es 1, indica carry/overflow
    SBI PORTD, 3			; Enciende el led del overflow

	ANDI R20, 0x0F			; El limite de 0-15
	LSL R20					; desplaza 4 bits para que coincida en los pines de salida que definimos de PD4 a PB7
	LSL R20
	LSL R20
	LSL R20

	IN  R16, PORTD			; lee estado actual del portd
	ANDI R16, 0b00001111	; conservar el estado de PD0 a PD3, ósea mantiene el boton de resultado y el led de carry/overflow
	OR   R16, R20			; meter resultado en PD4–PD7
	OUT  PORTD, R16			; Nos muestra el resultado de la suma en los leds

ESPERAR_SOLTAR_RESULTADO:
    SBIS PIND, 2			; Verifica si el PD2 ya no esta presionado, si sigue presionado no salta la siguiente instrucción
    RJMP ESPERAR_SOLTAR_RESULTADO ; evitar que se vuelva a calcular la suma mientras este presionado, un tipo de antirebote.

FIN_RESULTADO:
    RET						; Nos regresa al lopp