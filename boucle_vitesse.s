;DATE:		15/11/2019
;AUTHORS :	Henri PREVOST, Alexis MOURLON
;TITLE :	Speed_loop_project
;LAST UPDATE:	29/11/2019

;OVERVIEW :	Given a speed reference as input with the potentiometer,
;			measure the speed of the motor with a rotary encoder and determine the speed error.
;			Then apply a correction to make a speed control of the DC motor.
;..............................................................................
.equ __30F6010A, 1
.include "p30f6010A.inc"
    config	__FOSC, CSW_FSCM_OFF & XT_PLL16	;Turn off clock switching and
    config	__FWDT, WDT_OFF					;Turn off Watchdog Timer
    config	__FBORPOR, PBOR_ON & PWRT_16 & MCLR_EN
    config	__FGS, GWRP_OFF					;Set Code Protection Off for the
											;general segment
;..............................................................................
    .global	__reset
    .global	__T1Interrupt
	.global __PWMInterrupt
;..............................................................................
;Useful constants/variables for speed control	
    .global	angle
    .global	speed
	.global consigne
    .equ	Nb_Points, 1024					;Rotary encoder nb points
    .equ	Nb_max, Nb_Points*4
    .equ	Vmax, 4000						;4000 rpm
;..............................................................................
;Useful constants for PWM	
	.equ 	F_QUARTZ,7370000; 7.37MHz
	.equ 	F_CYCLE, 4*F_QUARTZ
	.equ 	F_PWM, 16000 ; 16kHz
	.equ 	PWM_PER,F_CYCLE/F_PWM/2
	.equ 	deadTime, 60					;2 ms
	.equ RC50,PWM_PER
	.equ RC25,RC50/2
	.equ RC75,RC50+RC25
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
    BSET 	IEC0, #T1IE						;TIMER1 Interrupt unmasked
	
	BCLR	IFS2, #PWMIF					
	BSET	IEC2, #PWMIE					;PWM Interrupt unmasked

;Acquittement des défault 
	BCLR LATE,#9
	REPEAT #65
	BSET LATE,#9
	BCLR LATE,#9
done:
	BCLR LATA, #9
	BTSS ADCON1,#DONE
	GOTO met_0
	GOTO met_1
met_0:
	BCLR LATA,#RA14
	BRA done
met_1:
	BSET LATA,#RA14
	BRA done

;..............................................................................
;Fonctions initializations
;..............................................................................

INITIALIZATIONS:
;GPIO inits, put as output RA9,RA14,RD11,RE9
    BCLR TRISA, #RA9	      				;Define bit 9 of port A as output
	BCLR TRISA, #RA14
	BCLR TRISD, #RD11
	BCLR PORTD, #RD11
	BCLR TRISE, #RE9
;Config QEICON in x4 mode, reset with index
    BSET	QEICON, #2						;Enable the POSRES bit
    BCLR	QEICON, #8
    BSET	QEICON, #9
    BSET	QEICON, #10
    MOV		#Nb_max, W0
    MOV		W0, MAXCNT
;TIMER1 config
    MOV		#29412, W0		;Choosen dt of 1ms over Tcy equals 29412 CPU cycles
    MOV		W0, PR1			;Set a value in PR1 to count until 1ms
    BSET	T1CON, #TON		;Set the TIMER1 on
;..............................................................................
;Initialisation du PWM
;Config Timers
	MOV #0x00FF, W0
	MOV W0, PWMCON1
;Activer 8 sorties PWM
	MOV #RC25,W0
	MOV W0, PDC1
	MOV #RC50,W0 
	MOV W0, PDC2
	MOV #RC75,W0 
	MOV W0, PDC3 
;Nombre de cycles Tcy permettant d'obtenir le tps mort
	MOV #deadTime,W0
	MOV W0,DTCON1
;Définition de la période
	MOV #PWM_PER,W0
	MOV W0,PTPER
;Position du declenchement de l'interruption
	MOV #PWM_PER,W0
	MOV W0,SEVTCMP
; Mise en route du PWM Timer
	BSET PTCON, #PTEN
	BSET PTCON, #PTMOD1
;..............................................................................
;Init ADC  
    MOV #0x0FF7F,W0
	MOV W0,ADPCFG
	MOV #7,W0
	MOV W0,ADCHS
	MOV #0x033F,W0
	MOV W0,ADCON3
	MOV #0,W0
	MOV W0,ADCON2
	MOV #0x836E,W0 			;on met les bits 8 et 9 a 1 pour format 1.15 signe
    MOV W0,ADCON1
    RETURN
;..............................................................................
;Interruption
;..............................................................................
__PWMInterrupt:
	PUSH.D W4 
    BSET LATA, #RA9
	MOV ADCBUF0, W4
	MOV #RC50,W5
	MPY W4*W5,A 
	SAC A,W4
	ADD W4,W5,W4
	MOV W4,PDC1

	ADD W5,W5,W5
	SUB W5,W4,W4
	MOV W4,PDC2
    BCLR IFS2, #PWMIF

	POP.D W4                                                 
       RETFIE  
;..............................................................................

__T1Interrupt:
    PUSH.D	W2		   		;Save context using double-word PUSH
    PUSH.D	W4

	MOV #100, W1			;gain for the potentiomoter to adapt magnitude
	MOV ADCBUF0, W0
	MUL.SU 	W1, W0, W6		;Multiplication W3 = W1 (signed) * W0 (unsigned)

    BTG		LATA, #RA9
    MOV		angle,W2
    MOV 	POSCNT, W4	    ;current value of theta
    SUB 	W4, W2, W3	    ;W3 = W4 - W2   W4 become angular gap mesured in dt = 1ms
    MOV 	W3, speed
    MOV		W4, angle

    BCLR 	IFS0, #T1IF	    ;Clear the Timer1 Interrupt flag Status bit.

    POP.D	W2		   		;angular gap mesured is saved
    POP.D	W4		    	;old value of theta is saved
    RETFIE			    	;end of TIMER1 interupt
;..............................................................................

.end