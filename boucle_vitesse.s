;DATE:		15/11/2019
;AUTHORS :	Henri PREVOST, Alexis MOURLON
;TITLE :	Speed_loop_project
;LAST UPDATE:	29/11/2019

;OVERVIEW :	Given a speed reference as input with the potentiometer,
;		measure the speed of the motor with a rotary encoder and determine the speed error.
;		Then apply a correction to make a speed control of the DC motor.
;..............................................................................
.equ __30F6010A, 1
.include "p30f6010A.inc"
    config	__FOSC, CSW_FSCM_OFF & XT_PLL16	;Turn off clock switching and
    config	__FWDT, WDT_OFF			;Turn off Watchdog Timer
    config	__FBORPOR, PBOR_ON & PWRT_16 & MCLR_EN
    config	__FGS, GWRP_OFF			;Set Code Protection Off for the
						;general segment
;..............................................................................
    .global	__reset
    .global	__T1Interrupt
    .global	angle
    .global	speed
    .equ	Nb_Points, 1024
    .equ	Nb_max, Nb_Points*4
    .equ	Vmax, 4000			;4000 rpm
;..............................................................................
    .section	.nbss, bss, near
speed:  	.space 2
angle:		.space 2
;..............................................................................
.text
__reset:
    MOV		#__SP_init, W15
    MOV		#__SPLIM_init, W0
    MOV		W0, SPLIM
    NOP

    CALL	INITIALIZATIONS
    BSET 	IEC0, #T1IE		;Interrupt unmasked

done:
    BRA		done
;..............................................................................
;Fonctions initializations
;..............................................................................

INITIALIZATIONS:
;GPIO inits, put as output RA9
    BCLR	TRISA, #RA9	      	;Define bit 9 of port A as output
;Config QEICON in x4 mode, reset with index
    BSET	QEICON, #2		;Enable the POSRES bit
    BCLR	QEICON, #8
    BSET	QEICON, #9
    BSET	QEICON, #10
    MOV		#Nb_max, W0
    MOV		W0, MAXCNT
;TIMER1 config
    MOV		#29412, W0		;Choosen dt of 1ms over Tcy equals 29412 CPU cycles
    MOV		W0, PR1			;Set a value in PR1 to count until 1ms
    BSET	T1CON, #TON		;Set the TIMER1 on
;ADC1 init and config    
    MOV #0x836E,W0 ; on met les bits 8 et 9 a 1 pour format 1.15 signe
    MOV W0,ADCON1
    RETURN
;..............................................................................
;Interruption
;..............................................................................
__T1Interrupt:
    PUSH.D	W2		    ;Save context using double-word PUSH
    PUSH.D	W4

    BTG		LATA, #RA9
    MOV		angle,W2
    MOV 	POSCNT, W4	    ;current value of theta
    SUB 	W4, W2, W3	    ;W3 = W4 - W2   W4 become angular gap mesured in dt = 1ms
    MOV 	W3, speed
    MOV		W4, angle

    BCLR 	IFS0, #T1IF	    ;Clear the Timer1 Interrupt flag Status bit.

    POP.D	W2		    ;angular gap mesured is saved
    POP.D	W4		    ;old value of theta is saved
    RETFIE			    ;end of TIMER1 interupt
;..............................................................................
.end