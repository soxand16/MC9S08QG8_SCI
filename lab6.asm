                                                                                                            ; lab5.asm - sci transmitting and oscillator trimming -- note the 7 sections of code

;*** The following line is assembly language section 0 (define assembly constants)
    include 'mc9s08qg8.inc' ; get all the location names
     bufferSize: equ 20
;*** The following two lines comprise section 1 (declare program variables)	
	org $60			;beginning of RAM
msgcount ds.b	1   ;can only count to 255 before overflowing to 0
inptr    ds.w 1
outptr   ds.w 1
buffer   ds.b bufferSize

;*** The following several lines comprise section 2 (define program constants)
	org	$e000		;beginning of ROM

smsg      dc.b	$d,$a,'Program started.',$d,$a,0
rmsg      dc.b "This is a message that gets repeated over and over...",13,10,0

msg0      dc.b $d,$a,"Message 0.", $d, $a, 0
msg1      dc.b $d,$a,"Message 1.", $d, $a, 0
msg2      dc.b $d,$a,"Message 2.", $d, $a, 0
msg3      dc.b $d,$a,"Message 3.", $d, $a, 0
msg4      dc.b $d,$a,"Message 4.", $d, $a, 0
msg5      dc.b $d,$a,"Message 5.", $d, $a, 0
msg6      dc.b $d,$a,"Message 6.", $d, $a, 0
msg7      dc.b $d,$a,"Message 7.", $d, $a, 0
msg8      dc.b $d,$a,"Message 8.", $d, $a, 0
msg9      dc.b $d,$a,"Message 9.", $d, $a, 0

messageTable dc.w msg0, msg1, msg2, msg3, msg4, msg5, msg6, msg7, msg8, msg9

;*** The following section is section 3 (initialization code -- runs only once)
init 
    lda  #$53
    sta  SOPT1          ; kill cop timer
     
    ldhx  #$260
    txs                 ; initialize stack pointer
     
    mov  #13,SCIBDL     ; Set the communication rate to 19200 baud.
	bset SCIC2_TE,SCIC2 ; Enable transmit.
	bset SCIC2_RE,SCIC2 ; Enable receive
	bset SCIC2_RIE,SCIC2

    lda  NV_ICSTRM
	sta  ICSTRM			;center trim value
	
	ldhx #buffer
	sthx inptr
	sthx outptr

	clr	 msgcount		;initialize our only variable
    ldhx #smsg
    jsr  putstr		; Send a startup message. 
  
    cli  
;end init

;*** The following section is section 4 (main loop -- loops forever)
main
    ldhx outptr
    cphx inptr
    beq main
    
    jsr getbyte
    
    cbeqa #$0D, newline
      
      cmp #$30
      
      blt normalOutput
      
      cmp #$39
      
      bgt normalOutput
      
      and #$f
      lsla
      tax
      clrh
      ldhx messageTable,x
      jsr putstr
    
      bra main
   
    normalOutput:
      jsr putchar
      bra main 
    
    newline:
    
      lda #$0A
    
      jsr putchar
      
      lda #$0D
    
      jsr putchar
      
      bra main

    ;msgloop:
    ;  ldhx #rmsg
    ;  jsr  putstr
    ;  bra  msgloop 

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
; the char it is to send is in A
putchar
    brclr SCIS1_TDRE,SCIS1,*  ;repeat until TDRE set
    sta  SCID                 ;send the character
 rts

getbyte
  clra
  ldhx outptr
  cphx inptr
  beq return
    lda ,x
    aix #1
    cphx #buffer+bufferSize
    blo okay2
      ldhx #buffer
    okay2:
    sthx outptr
    return:
    rts
 
SCIRX_ISR
  pshh
  lda SCIS1
  lda SCID
  
  ldhx inptr
  sta ,x
  aix #1
  cphx #buffer+bufferSize
 
  blo skip
    ldhx #buffer
  skip:
    sthx inptr
  
  pulh
  rti

;*** The next two lines are section 6 (placing reset and ISR addresses)
    org  Vreset
    dc.w init
    
    org Vscirx
    dc.w SCIRX_ISR
     
; end  follows
 end