;**********************************************************
; ROTB - Return of the Beast
; Copyright 2014-2017 S. Orchard
;**********************************************************

	section "DPVARS"

control_set	rmb 2
jbuttons	rmb 1
keytable	rmb 8

	section "RUN_ONCE"

controls_init
	ldd #control_keys		; default controls`
	std control_set			;
	ldd #$ff09				; initialise buttons & keys
	ldx #jbuttons			; to non-pressed state.
1	sta ,x+					;
	decb					;
	bne 1b					;
	rts
	

	section "CODE"

scan_keys
	ldu #$ff00

	lda #$ff
	sta 2,u
	ldb ,u
	andb #127
	stb jbuttons
	incb
	bpl 2f		; don't scan keys if joystick button pressed
	
	ldx #keytable
	coma		; set carry
	lda #$fe
1	sta 2,u
	ldb ,u
	stb ,x+
	rola	
	bcs 1b
2	rts

;*************************************

control_keys

	if (COCO == 1)
		lda #$08;
	else
		lda #$20;
	endif

	; UP
	bita keytable+3
	bne 1f

	; DOWN
1	bita keytable+4
	bne 1f

	; LEFT
1	bita keytable+5
	bne 1f
	inc player_dir
	bra 2f
	
	; RIGHT
1	bita keytable+6
	bne 1f
	dec player_dir
2
	; SPACE - FIRE
	if (COCO == 1)
1		lda #$08;
	else
1		lda #$20;
	endif
	bita keytable+7
	beq control_fire
	rts

;*************************************

olddac		equ temp0

control_joy
	ldu #$ff00
	leay $20,u
	lda ,y			; save dac value
	sta olddac		;

	clrb

	lda #CFG_FF23_DIS_SND	; disable sound
	sta 3,y					;

	lda #CFG_FF01_JOY_Y		; select right joystick y-axis
	sta 1,u					;
	lda #CFG_JOYSTK_HI
	sta ,y
	lsl ,u
	rolb
	lda #CFG_JOYSTK_LO
	sta ,y
	lsl ,u
	rolb
	
	lda #CFG_FF01_JOY_X		; select right joystick x-axis (also dac sound)
	sta 1,u					;
	lda #CFG_JOYSTK_HI
	sta ,y
	lsl ,u
	rolb
	lda #CFG_JOYSTK_LO
	sta ,y
	lsl ,u
	rolb
	
	lda olddac				; restore DAC value
	sta ,y					;
	lda #CFG_FF23_ENA_SND	; enable sound
	sta 3,y					;
	
	ldx #joystk_dir_table
	lda b,x
	bmi 5f			; joystick centred - do nothing
	ldb #1			; set up for ccw turn
	suba player_dir ; get difference in joystick & player directions
	beq 5f			; directions equal - do nothing
	bpl 1f			; turn ccw
	negb			; turn cw
	nega			; get absolute difference
1	cmpa #16		; compare difference to 180 deg
	bls 1f			; <= 180 deg
	negb			; > 180 deg - turn other way
1	addb player_dir	; apply turn
	andb #$1f		;
	stb player_dir	;
5	
	lda jbuttons
	bita #1
	bne 9f

control_fire
	lda frmflag
	beq 9f
	jmp pb_fire
9	rts

; translates packed comparator bits into a direction	
joystk_dir_table
	fcb 12, 8, -1, 4		; NW,  N,   n/a, NE
	fcb 16, -1, -1, 0		; W,   C,   n/a, E
	fcb -1, -1, -1, -1		; n/a, n/a, n/a, n/a
	fcb 20, 24, -1, 28		; SW,  S,   n/a, SE
	

;*************************************

select_controls
1	lda #1				; check joystick buttons first
	bita jbuttons		; as first key scan could be skipped
	bne 1f
	ldd #control_joy
	std control_set
	clra
	rts
	if (COCO == 1)
1		lda #$08
	else
1		lda #$20
	endif
	bita keytable+7
	bne 1f
	ldd #control_keys
	std control_set
	clra
1	rts
