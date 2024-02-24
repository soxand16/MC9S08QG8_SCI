; lab6.asm - sci transmitting and oscillator trimming -- note the 7 sections of code

;*** The following line is assembly language section 0 (define assembly constants)
    include 'mc9s08qg8.inc' ; get all the location names

;*** The following two lines comprise section 1 (declare program variables)	
	org $60			;beginning of RAM
msgcount ds.b	1   ;can only count to 255 before overflowing to 0

;*** The following several lines comprise section 2 (define program constants)
	org	$e000		;beginning of ROM

smsg      dc.b	$d,$a,'Program started.',$d,$a,0
rmsg      dc.b "This is a message that gets repeated over and over...",13,10,0

;*** The following section is section 3 (initialization code -- runs only once)
init 
    lda  #$53
    sta  SOPT1          ; kill cop timer
     
    ldhx  #$260
    txs                 ; initialize stack pointer
    
	; STUDENTS:
	; Initialize SCI module according to specs in the lab handout:
    

    lda  #$80
	sta  ICSTRM			;center trim value

	clr	 msgcount		;initialize our only variable
    ldhx #smsg
    jsr  putstr		; Send a startup message.   
;end init

;*** The following section is section 4 (main loop -- loops forever)
main
;To perform trimming will will loop sending a 'U' which is $55

    lda  #'U'
    trimloop:
      jsr  putchar
      bra  trimloop
       
;Later we will comment out the above 4 lines and loop sending rmsg (defined above)

    msgloop:
      ldhx #rmsg
      jsr  putstr
      bra  msgloop 

    bra  *               ;stall if we ever get here
	
;***The following subroutines make up section 5 (subroutines and ISRs)

; putstr does not need to preserve any registers
; it is called with H:X pointing to null terminated string
putstr
    psloop:
      lda  ,x       ;get next character in string
      beq  done     ;if null ($00), we are done
         jsr putchar
      aix  #1       ;advance string pointer
      bra  psloop   ;repeat for next char
    done:
    inc  msgcount
	rts
	
; putchar must preserve the IX and A registers
; the character to be sent is in A
putchar
    ; STUDENTS:
	; Put the code that checks if the module is ready for the next character
	; and then put the new value from A in the SCI data register
	; it takes only two lines of assembly code
 rts

;*** The next two lines are section 6 (placing reset and ISR addresses)
    org  Vreset
    dc.w init
     
; end  follows
 end