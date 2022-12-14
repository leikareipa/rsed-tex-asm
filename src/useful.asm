; Useful subroutines for assembly programs.

; Waits for vertical refresh (vsync).
; EXPECTS:
;	(- nothing)
; DESTROYS:
;	- dx
; RETURNS:
;	(- nothing)
Wait_For_VSync:
        mov dx,3dah
        .wait_1:
                in al,dx
                and al,00001000b
                jnz .wait_1
        .wait_2:
                in al,dx
                and al,00001000b
                jz .wait_2
        ret

; Copies the video buffer pointed to by ds:si to video memory pointed to by es:di.
; EXPECTS:
;	- si = point to start of video memory buffer
; DESTROYS:
;	- di, ax
; RETURNS:
;	(- nothing)
Flip_Video_Buffer:
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; initialize.
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    push es
    push ds

    mov ax,es                               ; set up the source (video memory buffer).
    mov ds,ax                               ;
    mov ax,VRAM_SEG                         ; set up the destination (video memory).
    mov es,ax                               ;
    xor di,di                               ; start at offset 0 in video memory.
    xor si,si

    call Wait_For_VSync

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; copy the vga buffer into video memory.
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    mov cx,3e80h                            ; how many double words to copy (320*200 = 64000/4 = 16000).
    rep movsd

    pop ds
    pop es

    ret

ECX_To_VGA_Mem_Offset:
    ; convert the y coordinate into a row index on the screen.
    mov ax,cx										; y coordinate.
    mov bx,140h										; width of the screen in vga mode 13h.
    mul bx

    ; add the x coordinate to the row index.
    ror ecx,16										; move the high bits (x coordinate) in ecx to cx.
    mov bx,cx
    add ax,bx										; ax now contains a byte offset to the location on screen (video memory) where the mouse cursor should be drawn.
    mov di,ax

    ror ecx,10h										; restore the y coordinate to cx.

    ret
