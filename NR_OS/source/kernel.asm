;*****************start of the kernel code***************
[org 0x000]
[bits 16]

[SEGMENT .text]

;START //////////////////////////////////////////////////////////////
    mov ax, 0x0100			;location where kernel is loaded
    mov ds, ax
    mov es, ax
    
    mov ax,0x13         ;clears the screen
    int 0x10           ;call bios video interrupt

   mov ah,02           ;clear the screen with big font
   int 0x10            ;interrupt display
    
    ;////////////////////////////////////////////////////////
    ; drawing window with lines

    push 0x0A000                ; video memory graphics segment
    pop es                      ; pop any extar segments from stack
    xor di,di                   ; set destination index to 0
    xor ax,ax                   ; set color register to zero

    ;//////////////////////////////////////////////
    ;******drawing top line of our window
    mov ax,0x02                 ; set color to green

    mov dx,0                    ; initialize counter(dx) to 0

    add di,320                  ; add di to 320(next line)
    imul di,10                  ;multiply by 10 to di to set y cordinate from where we need to start drawing

    add di,10                   ;set x cordinate of line from where to be drawn

_topLine_perPixel_Loop:

    mov [es:di],ax              ; move value ax to memory location es:di

    inc di                      ; increment di for next pixel
    inc dx                      ; increment our counter
    cmp dx,300                  ; comprae counter value with 300
    jbe _topLine_perPixel_Loop  ; if <= 300 jump to _topLine_perPixel_Loop

    hlt                         ; halt process after drawing

    ;//////////////////////////////////////////////
    ;******drawing bottm line of our window
    xor dx,dx
    xor di,di
    add di,320
    imul di,190         ; set y cordinate for line to be drawn
    add di,10           ;set x cordinate of line to be drawn

    mov ax,0x01         ; blue color

_bottmLine_perPixel_Loop:

    mov [es:di],ax

    inc di
    inc dx
    cmp dx,300
    jbe _bottmLine_perPixel_Loop
    hlt

    ;//////////////////////////////////////////////
    ;******drawing left line of our window
    xor dx,dx
    xor di,di
    add di,320
    imul di,10           ; set y cordinate for line to be drawn

    add di,10            ; set x cordinate for line to be drawn

    mov ax,0x03          ; cyan color

_leftLine_perPixel_Loop:

    mov [es:di],ax

    inc dx
    add di,320
    cmp dx,180
    jbe _leftLine_perPixel_Loop

    hlt 

    ;//////////////////////////////////////////////
    ;******drawing right line of our window
    xor dx,dx
    xor di,di
    add di,320
    imul di,10           ; set y cordinate for line to be drawn

    add di,310           ; set x cordinate for line to be drawn

    mov ax,0x06          ; orange color

_rightLine_perPixel_Loop:

    mov [es:di],ax

    inc dx
    add di,320
    cmp dx,180
    jbe _rightLine_perPixel_Loop

    hlt

    ;//////////////////////////////////////////////
    

  

    hlt

    ;set cursor to specific position
    mov ah,0x02
    mov bh,0x00
    mov dh,0x06  ; y cordinate
    mov dl,0x05   ; x cordinate
    int 0x10

    

    hlt

    ;set cursor to specific position
    mov ah,0x02
    mov bh,0x00
    mov dh,0x12   ; y cordinate
    mov dl,0x03  ; x cordinate
    int 0x10

    

    hlt

    ;set cursor to specific position on screen
    mov ah,0x02         ; set value for change to cursor position
    mov bh,0x00         ; page
    mov dh,0x10         ; y cordinate/row
    mov dl,0x09        ; x cordinate/col
    int 0x10

  mov si, start_os_intro              ; point start_os_intro string to source index
    call _print_DiffColor_String        ; call print different color string function
   
   
;set cursor to specific position on screen
    mov ah,0x02
    mov bh,0x00
    mov dh,0x06
    mov dl,0x05
    int 0x10
    
    mov si,press_key                    ; point press_key string to source index
    call _print_GreenColor_String       ; call print green color string function

    mov ax,0x00         ; get keyboard input
   int 0x16            ; interrupt for hold & read input
   
   
    ;/////////////////////////////////////////////////////////////
        ; load second sector into memory

    mov ah, 0x02                    ; load second stage to memory
    mov al, 1                       ; numbers of sectors to read into memory
    mov dl, 0x80                    ; sector read from fixed/usb disk
   mov ch, 0                       ; cylinder number
    mov dh, 0                       ; head number
    mov cl, 2                       ; sector number
    mov bx, _OS_Stage_2             ; load into es:bx ;segment :offset of buffer
    int 0x13                        ; disk I/O interrupt


    jmp _OS_Stage_2                 ; jump to second stage
       


    ;/////////////////////////////////////////////////////////////
    ; declaring string datas here
    press_key db 'Welcome to NR Operating System',0
    start_os_intro db '>>> Press any key <<<',0
    
    

;****** print string with different colors

_print_DiffColor_String:
        mov bl,1                ;color value
    mov ah, 0x0E

.repeat_next_char:
    lodsb
    cmp al, 0
    je .done_print
    add bl,6               ;increase color value by 6
    int 0x10
    jmp .repeat_next_char

.done_print:
    ret

;****** print string with green color

_print_GreenColor_String:
    mov bl,10
    mov ah, 0x0E

.repeat_next_char:
    lodsb
    cmp al, 0
    je .done_print
    int 0x10
    jmp .repeat_next_char

.done_print:
    ret






    
    _OS_Stage_2 :
    mov al,2                    ; set font to normal mode
    mov ah,0                    ; clear the screen
    int 0x10                    ; call video interrupt

    mov cx,0                    ; initialize counter(cx) to get input


    mov ax, 0x0100			;location where kernel is loaded
    mov ds, ax
    mov es, ax
    
    cli
    mov ss, ax				;stack segment
    mov sp, 0xFFFF			;stack pointer at 64k limit
    sti

    push dx
    push es
    xor ax, ax
    mov es, ax
    cli
    mov word [es:0x21*4], _int0x21	; setup interrupt service
    mov [es:0x21*4+2], cs
    sti
    pop es
    pop dx

    mov si, strWelcomeMsg   ; load message
    mov al, 0x01            ; request sub-service 0x01
    int 0x21

	call _shell				; call the shell
    
    int 0x19                ; reboot
    
;END #######################################################

_int0x21:
	_int0x21_ser0x01:       ;service 0x01
	cmp al, 0x01            ;see if service 0x01 wanted
	jne _int0x21_end        ;goto next check (now it is end)
    
	_int0x21_ser0x01_start:
	lodsb                   ; load next character
	or  al, al              ; test for NUL character
	jz  _int0x21_ser0x01_end
	mov ah, 0x0E            ; BIOS teletype
	mov bh, 0x00            ; display page 0
	mov bl, 0x07            ; text attribute
	int 0x10                ; invoke BIOS
	jmp _int0x21_ser0x01_start
	_int0x21_ser0x01_end:
	jmp _int0x21_end

	_int0x21_end:
    	iret

_shell:
	_shell_begin:
	;move to next line
	call _display_endl

	;display prompt
	call _display_prompt

	;get user command
	call _get_command
	
	;split command into components
	call _split_cmd

	;check command & perform action

	; empty command
	_cmd_none:		
	mov si, strCmd0
	cmp BYTE [si], 0x00
	jne _cmd_ver		;next command
	jmp _cmd_done
	
	; display version
	_cmd_ver:		
	mov si, strCmd0
	mov di, cmdVer
	mov cx, 4
	repe	cmpsb
	jne	_cmd_info		;next command;
	
	call _display_endl
	mov si, strOsName		;display version
	mov al, 0x01
	int 0x21
	call _display_space
	mov si, txtVersion		;display version
	mov al, 0x01
	int 0x21
	call _display_space

	mov si, strMajorVer		
	mov al, 0x01
	int 0x21
	mov si, strMinorVer
	mov al, 0x01
	int 0x21
	jmp _cmd_done





	; display hardware info
	_cmd_info:		
	mov si, strCmd0
	mov di, cmdInfo
	mov cx, 5
	repe	cmpsb
	jne	_cmd_displayHelpMenu		;next command
	
	call _display_endl
	mov si, strInfo1		; Prints the topic
	mov al, 0x01
	int 0x21
	
	call _display_endl
	mov si, strInfo2		; Prints the topic
	mov al, 0x01
	int 0x21
	call _display_endl
	
	
	call _display_endl
	
	call _cmd_cpuVendorID
	call _cmd_ProcessorType
	call _cmd_SerialNo
	
	call _display_endl
	jmp _cmd_done

	_cmd_cpuVendorID:
		call _display_endl
		mov si,strcpuid
		mov al, 0x01
		int 0x21

		mov eax,0
		cpuid; call cpuid command
		mov [strcpuid],ebx; load last string
		mov [strcpuid+4],edx; load middle string
		mov [strcpuid+8],ecx; load first string
		;call _display_endl
		mov si, strcpuid;print CPU vender ID
		mov al, 0x01
		int 0x21
		ret

	_cmd_ProcessorType:
		call _display_endl
		mov si, strtypecpu
		mov al, 0x01
		int 0x21

	
		mov eax, 0x80000002		; get first part of the brand
		cpuid
		mov  [strcputype], eax
		mov  [strcputype+4], ebx
		mov  [strcputype+8], ecx
		mov  [strcputype+12], edx

		mov eax,0x80000003
		cpuid; call cpuid command
		mov [strcputype+16],eax
		mov [strcputype+20],ebx
		mov [strcputype+24],ecx
		mov [strcputype+28],edx

		mov eax,0x80000004
		cpuid     ; call cpuid command
		mov [strcputype+32],eax
		mov [strcputype+36],ebx
		mov [strcputype+40],ecx
		mov [strcputype+44],edx

		

		mov si, strcputype           ;print processor type
		mov al, 0x01
		int 0x21
		ret

	_cmd_SerialNo:
		call _display_endl
		mov si, strcpuserial
		mov al, 0x01
		int 0x21

		mov eax, 3		; get first part of the brand
		cpuid
		and edx,1
		;mov  [strcpusno], eax
		;mov  [strcpusno+4], ebx
		mov  [strcpusno], ecx
		mov  [strcpusno+32], edx
		


		mov si, strcpusno           ;print processor type
		mov al, 0x01
		int 0x21
		ret



	


	_cmd_displayHelpMenu:
		call _display_endl		
		mov si, strCmd0
		mov di, cmdHelp
		mov cx, 5
		repe	cmpsb
		jne	_cmd_mouse

		call _display_endl
		mov si, strHelpMsg1
		mov al, 0x01
		int 0x21
		call _display_endl
		mov si, strHelpMsg2
		mov al, 0x01
		int 0x21
		call _display_endl
		mov si, strHelpMsg3
		mov al, 0x01
		int 0x21
		call _display_endl
		mov si, strHelpMsg4
		mov al, 0x01
		int 0x21
		call _display_endl
		mov si, strHelpMsg5
		mov al, 0x01
		int 0x21
		call _display_endl
		mov si, strHelpMsg6
		mov al, 0x01
		int 0x21
		call _display_endl
		jmp _cmd_done



	
	;display mousestatus
	_cmd_mouse:		
		mov si, strCmd0
		mov di, cmdMouse
		mov cx, 6
		repe	cmpsb
		jne	_cmd_exit

		mov ax, 0
		int 33h
		cmp ax, 0
		jne ok
		
		mov si, strMouse0
		mov al, 0x01
		int 0x21
		call _display_endl
		
		jmp _cmd_done

	ok:
		mov ax, 1
		int 33h
		mov si, strMouse1
		mov al, 0x01
		int 0x21
		call _display_endl
		

	; exit shell
	_cmd_exit:		
	mov si, strCmd0
	mov di, cmdExit
	mov cx, 5
	repe	cmpsb
	jne	_cmd_unknown		;next command

	je _shell_end			;exit from shell

	_cmd_unknown:
	call _display_endl
	mov si, msgUnknownCmd		;unknown command
	mov al, 0x01
    int 0x21

	_cmd_done:

	;call _display_endl
	jmp _shell_begin
	
	_shell_end:
	ret





	
_get_command:
	;initiate count
	mov BYTE [cmdChrCnt], 0x00
	mov di, strUserCmd

	_get_cmd_start:
	mov ah, 0x10			;get character
	int 0x16

	cmp al, 0x00			;check if extended key
	je _extended_key
	cmp al, 0xE0			;check if new extended key
	je _extended_key

	cmp al, 0x08			;check if backspace pressed
	je _backspace_key

	cmp al, 0x0D			;check if Enter pressed
	je _enter_key

	mov bh, [cmdMaxLen]		;check if maxlen reached
	mov bl, [cmdChrCnt]
	cmp bh, bl
	je _get_cmd_start

	;add char to buffer, display it and start again
	mov [di], al			;add char to buffer
	inc di				;increment buffer pointer
	inc BYTE [cmdChrCnt]		;inc count

	mov ah, 0x0E			;display character
	mov bl, 0x07
	int 0x10
	jmp _get_cmd_start

	_extended_key:			;extended key - do nothing now
	jmp _get_cmd_start

	_backspace_key:
	mov bh, 0x00			;check if count = 0
	mov bl, [cmdChrCnt]
	cmp bh, bl
	je _get_cmd_start		;yes, do nothing
	
	dec BYTE [cmdChrCnt]		;dec count
	dec di

	;check if beginning of line
	mov ah, 0x03			;read cursor position
	mov bh, 0x00
	int 0x10

	cmp dl, 0x00
	jne	_move_back
	dec dh
	mov dl, 79
	mov ah, 0x02
	int 0x10

	mov ah, 0x09			; display without moving cursor
	mov al, ' '
    	mov bh, 0x00
	mov bl, 0x07
	mov cx, 1			; times to display
	int 0x10
	jmp _get_cmd_start

	_move_back:
	mov ah, 0x0E			; BIOS teletype acts on backspace!
	mov bh, 0x00
	mov bl, 0x07
	int 0x10
	mov ah, 0x09			; display without moving cursor
	mov al, ' '
	mov bh, 0x00
	mov bl, 0x07
	mov cx, 1			; times to display
	int 0x10
	jmp _get_cmd_start

	_enter_key:
	mov BYTE [di], 0x00
	ret

_split_cmd:
	;adjust si/di
	mov si, strUserCmd
	;mov di, strCmd0

	;move blanks
	_split_mb0_start:
	cmp BYTE [si], 0x20
	je _split_mb0_nb
	jmp _split_mb0_end

	_split_mb0_nb:
	inc si
	jmp _split_mb0_start

	_split_mb0_end:
	mov di, strCmd0

	_split_1_start:			;get first string
	cmp BYTE [si], 0x20
	je _split_1_end
	cmp BYTE [si], 0x00
	je _split_1_end
	mov al, [si]
	mov [di], al
	inc si
	inc di
	jmp _split_1_start

	_split_1_end:
	mov BYTE [di], 0x00

	;move blanks
	_split_mb1_start:
	cmp BYTE [si], 0x20
	je _split_mb1_nb
	jmp _split_mb1_end

	_split_mb1_nb:
	inc si
	jmp _split_mb1_start

	_split_mb1_end:
	mov di, strCmd1

	_split_2_start:			;get second string
	cmp BYTE [si], 0x20
	je _split_2_end
	cmp BYTE [si], 0x00
	je _split_2_end
	mov al, [si]
	mov [di], al
	inc si
	inc di
	jmp _split_2_start

	_split_2_end:
	mov BYTE [di], 0x00

	;move blanks
	_split_mb2_start:
	cmp BYTE [si], 0x20
	je _split_mb2_nb
	jmp _split_mb2_end

	_split_mb2_nb:
	inc si
	jmp _split_mb2_start

	_split_mb2_end:
	mov di, strCmd2

	_split_3_start:			;get third string
	cmp BYTE [si], 0x20
	je _split_3_end
	cmp BYTE [si], 0x00
	je _split_3_end
	mov al, [si]
	mov [di], al
	inc si
	inc di
	jmp _split_3_start

	_split_3_end:
	mov BYTE [di], 0x00

	;move blanks
	_split_mb3_start:
	cmp BYTE [si], 0x20
	je _split_mb3_nb
	jmp _split_mb3_end

	_split_mb3_nb:
	inc si
	jmp _split_mb3_start

	_split_mb3_end:
	mov di, strCmd3

	_split_4_start:			;get fourth string
	cmp BYTE [si], 0x20
	je _split_4_end
	cmp BYTE [si], 0x00
	je _split_4_end
	mov al, [si]
	mov [di], al
	inc si
	inc di
	jmp _split_4_start

	_split_4_end:
	mov BYTE [di], 0x00

	;move blanks
	_split_mb4_start:
	cmp BYTE [si], 0x20
	je _split_mb4_nb
	jmp _split_mb4_end

	_split_mb4_nb:
	inc si
	jmp _split_mb4_start

	_split_mb4_end:
	mov di, strCmd4

	_split_5_start:			;get last string
	cmp BYTE [si], 0x20
	je _split_5_end
	cmp BYTE [si], 0x00
	je _split_5_end
	mov al, [si]
	mov [di], al
	inc si
	inc di
	jmp _split_5_start

	_split_5_end:
	mov BYTE [di], 0x00

	ret

_display_space:
	mov ah, 0x0E                            ; BIOS teletype
	mov al, 0x20
	mov bh, 0x00                            ; display page 0
	mov bl, 0x07                            ; text attribute
	int 0x10                                ; invoke BIOS
	ret

_display_endl:
	mov ah, 0x0E		; BIOS teletype acts on newline!
	mov al, 0x0D
	mov bh, 0x00
	mov bl, 0x07
	int 0x10

	mov ah, 0x0E		; BIOS teletype acts on linefeed!
	mov al, 0x0A
	mov bh, 0x00
	mov bl, 0x07
	int 0x10
	ret

_display_prompt:
	mov si, strPrompt
	mov al, 0x01
	int 0x21
	ret
	



[SEGMENT .data]
	strWelcomeMsg		db	" Welcome to NR_OS...type 'help' for further instructions", 0x00
	strPrompt		db	"NROS$->> ", 0x00
	cmdMaxLen		db	255			;maximum length of commands

	strOsName		db	"NR_OS", 0x00	;OS details
	strMajorVer		db	"0", 0x00
	strMinorVer		db	".01", 0x00

	cmdVer			db	"version", 0x00		; internal commands
	cmdExit			db	"exit", 0x00
	cmdInfo			db	"info", 0x00		; Shows hardware information
	cmdHelp			db	"help",0x00
	cmdMouse  		db 	"mouse",0x00	;show mouse status

	txtVersion		db	"version", 0x00	;messages and other strings
	msgUnknownCmd		db	"Unknown command or bad file name!", 0x00
	
	
	strInfo1			db	"   Hardware Information   ", 0x00
	strInfo2			db	"===========================", 0x00
	strcpuid		db	"CPU Vendor : ", 0x00
	strtypecpu		db	"CPU Type: ", 0x00
	strcpuserial	db	"CPU Serial No : ",0x00
	
	strHelpMsg1		db  "  Command                 Description",0x00
	strHelpMsg2		db  "==========               ===================",0x00
	strHelpMsg3		db  "  help         -          for further instructions",0x00
	strHelpMsg4		db  "  version      -          for get version",0x00
	strHelpMsg5		db  "  info         -          for to obtain Hardware informations of the machine",0x00
	strHelpMsg6		db  "  exit         -          for a reboot",0x00
	strMouse0		db	"The Mouse Not Found",0x00
	strMouse1		db 	"The Mouse Found",0x00
	
[SEGMENT .bss]
	strUserCmd	resb	256		;buffer for user commands
	cmdChrCnt	resb	1		;count of characters
	strCmd0		resb	256		;buffers for the command components
	strCmd1		resb	256
	strCmd2		resb	256
	strCmd3		resb	256
	strCmd4		resb	256
	strVendorID	resb	16
	strcputype	resb	64
	strcpusno	resb 	64

;********************end of the kernel code********************

