;DATE: 18/10/2019
;AUTEURS:Henri PREVOST, Alexis MOURLON
;..............................................................................
		.equ __30F6010A, 1
        .include "p30f6010A.inc"
        config __FOSC, CSW_FSCM_OFF & XT_PLL16    ;Turn off clock switching and
        config __FWDT, WDT_OFF              ;Turn off Watchdog Timer
        config __FBORPOR, PBOR_ON & PWRT_16 & MCLR_EN
        config __FGS, GWRP_OFF         ;Set Code Protection Off for the 
;..............................................................................
        .global __reset     
		.global __T1Interrupt
		.global	angle
		.global	vitesse
		.equ	Nb_Points,1024
		.equ	Nb_max,Nb_Points*4
;..............................................................................
          	.section .nbss, bss, near
vitesse:  	.space 2               
angle:		.space 2
;..............................................................................
.text                             
__reset:
        MOV #__SP_init, W15       
        MOV #__SPLIM_init, W0     
        MOV W0, SPLIM
        NOP          
             
		CALL	INITIALISATION
		BSET 	IEC0, #T1IE		;Interruption démasquée
		
done:
        BRA     done              
;..............................................................................
;Fonction initialisations
;..............................................................................                   

INITIALISATION:
;Init des PIO, mettre en sortie RA9
		BCLR TRISA, #RA9	      	;Définir le bit 9 du port A en sortie
;Config du QEICON en mode x4, reset with index
		BSET QEICON, #2		;enable the POSRES bit
		BCLR QEICON, #8
		BSET QEICON, #9
		BSET QEICON, #10
		MOV #Nb_max, W0
		MOV W0, MAXCNT
;config du timer 1                                  
		MOV  #29412, W0		;choosen dt of 1ms over Tcy equals 29412 CPU cycles
		MOV  W0, PR1			;fixe une valeur pour compter jusqu'a 1ms
		BSET T1CON, #TON		;allume le timer 1
		RETURN
;..............................................................................
;Interruption 
;..............................................................................
__T1Interrupt:
        PUSH.D W2		    ;Save context using double-word PUSH
		PUSH.D W4

        BTG 	LATA, #RA9
		MOV		angle,W2
	    MOV 	POSCNT, W4	    ;current value of theta
	    SUB 	W4, W2, W3	    ;W3 = W4 - W2   W4 become angular gap mesured in dt = 1ms
		MOV 	W3, vitesse
		MOV		W4,angle

        BCLR 	IFS0, #T1IF	    ;Clear the Timer1 Interrupt flag Status bit.
	
        POP.D W2		    ;angular gap mesured is saved
		POP.D W4		    ;old value of theta is saved
        RETFIE			    ;end of TIMER1 interupt
;..............................................................................
.end