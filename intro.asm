;**********************************************************
; ROTB - Return of the Beast
; Copyright 2014-2017 S. Orchard
;**********************************************************

	section "RUN_ONCE"

intr_fg		equ temp1
intr_bg		equ temp2

	
intro
	if DBG_SKIP_INTRO
	rts
	endif

	;ldd #$aa55
	;ldd #$aa00
	ldd #$55aa
	std intr_fg

	jsr intr_pcls
	
	ldy #msg_title
	jsr intr_stringz

	jsr show_frame

	clr $ff02		; detect any key or button

	ldb $ff00		; check for keys/buttons
	andb #127		;
	cmpb #127		;
	bne 2f			; key or button pressed: skip over tty

	lda #200
	jsr intr_delay
	ldy #msg_intro1
	jsr intr_stringz_slow
	
2	ldu td_fbuf
	leau -CFG_TOPOFF,u		; top of screen
	ldx #title_screen
1	ldd ,x++
	std ,u++
	cmpx #title_screen+3072
	blo 1b

	ldy #msg_start
	jsr intr_stringz

	jsr show_frame
	
1	lda $ff00		; check for keys/buttons
	anda #127		;
	cmpa #127		;
	bne 1b			; key or button pressed
	
intro_loop

	pshs dp
	lda	#player_dp
	tfr	a,dp

	clra
	jsr	select_tune

;	if VSYNC
;		; AD CPU rate
;		sta	reg_sam_r0s
;		sta	reg_sam_r1c
;	endif

	clr $ff02		; setup to detect any key or button
	
1	jsr	play_frag	; play 20ms of music
	lda $ff00		; check for keys/buttons
	anda #127		;
	cmpa #127		;
	beq 1b			; no keys or buttons pressed
	
	lda #$ff		; check for fire button
	sta $ff02		;
	lda $ff00		;
	bita #1			;
	beq 2f			; rh fire pressed

	lda #$7f		; check for spacebar
	sta $ff02		;
	lda $ff00		;
	if (COCO == 1)
		bita #$08;
	else
		bita #$20;
	endif
	bne 1b			; spacebar not pressed
	
2	puls dp

	jsr scan_keys
	jsr select_controls
	bne intro_loop
	rts
	;jmp pixel_fade

;------------------------------------------------

intr_delay
	pshs b
2	ldx #1110	; approx 10ms
1	leax -1,x
	bne 1b

	;ldb $ff00		; check for keys/buttons
	;andb #127		;
	;cmpb #127		;
	;bne 3f			; key or button pressed

	deca
	bne 2b
3	puls b,pc

intr_pcls
	lda intr_bg
	tfr a,b
	ldu td_fbuf
	leau -CFG_TOPOFF,u		; top of screen
	ldx #1536
1	std ,u++
	leax -1,x
	bne 1b
	rts

5	ldb #15
6	com ,u
	lda #15
	jsr intr_delay
	decb
	bne 6b
intr_stringz_slow
1	ldd ,y++
	beq 9f
	addd td_fbuf
	eora #FBUF_TOG_HI
	tfr d,u
2	ldb ,y+
	bmi 4f
	beq 5b
	bsr intr_char
	com ,u
	ldx #10
	ldb #64
3	stb $ff20
	lda #150
1	deca
	bne 1b
	eorb #64
	leax -1,x
	bne 3b
	lda #5
	jsr intr_delay
	bra 2b
4	lda ,y+
	sta intr_fg
	bra 2b
	

intr_stringz
1	ldd ,y++
	beq 9f
	addd td_fbuf
	tfr d,u
2	ldb ,y+
	bmi 4f
	beq 1b
	bsr intr_char
	bra 2b
4	lda ,y+
	sta intr_fg
	bra 2b
	
intr_char
	lda #5
	mul
	addd #allchars-(32*5)
	tfr d,x
intr_char_x
	ldb #-128
1	lda intr_fg		; apply fg/bg colours
	eora intr_bg	;
	anda ,x+		;
	eora intr_bg	;
	sta b,u
	addb #32
	cmpb #32
	bne 1b
	leau 1,u
9	rts



show_frame
	ldx #soundbuf		; reset sound buffer pointer
	stx snd_buf_ptr		; (flip_frame_buffers generates sound)
	jmp flip_frame_buffers


	include "allchars.asm"

MAC_MSG_POS macro
	fdb MSG_TOP + \2*32*6 + \1
	endm
	
MSG_TOP	equ -CFG_TOPOFF+128
	
msg_title
	MAC_MSG_POS 1,1
	fcc -1,$55,"RETURN OF THE BEAST",0
	MAC_MSG_POS 1,2
	fcc -1,0,"A DEMO FOR THE DRAGON 32",0
	MAC_MSG_POS 1,3
	fcc "(C) 2014-2017 S.ORCHARD",0

	MAC_MSG_POS 1,5
	fcc -1,$55,"THERE'S GOOD CYD",0
	MAC_MSG_POS 1,6
	fcc -1,0,"3 CHANNEL MUSIC PLAYER",0
	MAC_MSG_POS 1,7
	fcc "(C) 2013-2015 CIARAN ANSCOMB",0
	
	MAC_MSG_POS 1,9
	fcc "SPECIAL THANKS TO ",-1,$55,"BOSCO",-1,0," FOR",0
	MAC_MSG_POS 1,10
	fcc "GREAT IDEAS AND INSPIRATION",0
	
	fdb 0


msg_intro1
	MAC_MSG_POS 1,14
	fcc -1,$55,"SOMEWHERE IN THE MULTIVERSE",0
	MAC_MSG_POS 1,15
	fcc "ABOUT TEA TIME...",0
	fdb 0


	
msg_start
	MAC_MSG_POS 5,14
	fcc "SPACE OR FIRE TO START",0
	fdb 0

title_screen	
	includebin "title_screen.bin"
	
