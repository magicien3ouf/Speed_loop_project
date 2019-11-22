; DATE: 18/10/2019
;AUTEURS:Henri PREVOST, Alexis MOURLON
;..............................................................................
; 
;..............................................................................
		.equ __30F6010A, 1
        .include "p30f6010A.inc"
        config __FOSC, CSW_FSCM_OFF & XT_PLL16    ;Turn off clock switching and
        config __FWDT, WDT_OFF              ;Turn off Watchdog Timer
        config __FBORPOR, PBOR_ON & PWRT_16 & MCLR_EN
        config __FGS, GWRP_OFF         ;Set Code Protection Off for the 
;..............................................................................
		.equ F_QUARTZ,7370000; 7.37MHz
		.equ NMAX,1024;
		.equ WMAX,4500
		.equ F_CODEURMAX, WMAX*NMAX*4/60; 273kHz
		.equ DT_MAX, NMAX/F_CODEURMAX
;..............................................................................
        .global __reset     
		.global __T1Interrupt
;..............................................................................
          .section .nbss, bss, near
var1:     .space 2               
;..............................................................................
.text                             
__reset:
        MOV #__SP_init, W15       
        MOV #__SPLIM_init, W0     
        MOV W0, SPLIM
        NOP          
             
;Config du QEICON en mode x4, reset with index
		BCLR QEICON, #8
		BSET QEICON, #9
		BSET QEICON, #10     
                                  
		BCLR TRISA, #RA9	      	;Définir le bit 9 du port A en sortie
		MOV  #029412, W0		;choosen dt of 1ms over Tcy equals 29412 CPU cycles
		MOV  W0,PR1			;fixe une valeur pour compter jusqu'a 1ms
		;BSET T1CON, #TCKPS0
		;BSET T1CON, #TCKPS1		;A une frequence de 500ms diviser par 256
		BSET T1CON, #TON		;allume le timer 1
		BSET IEC0, #T1IE		;Interrupt request
		
done:
        BRA     done              

       
;..............................................................................
;Fonction initialisation du PWM
;..............................................................................                   

INITIALISATION:
;Init des PIO, mettre en sortie RA9
		BCLR TRISA, #RA9
		RETURN 
;..............................................................................
;Interruption 
;..............................................................................
__T1Interrupt:
        PUSH.D W4                  ;Save context using double-word PUSH
		PUSH.D W2

        BTG LATA, #RA9
		MOV #0,W4		
		MOV POSCNT,W4
		SUB W4,W2,W1
		MOV #0,W2
		MOV W4,W2


        BCLR IFS0, #T1IF           ;Clear the Timer1 Interrupt flag Status
                                   ;bit.
        POP.D W4
		POP.D W2                 
        RETFIE                     

;..............................................................................
.end



