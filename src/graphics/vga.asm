;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Subroutines that have to do with handling video modes.
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Assigns the palette colors in VGA mode 13h from the 'palette' array (defined externally).
;;;
;;; EXPECTS:
;;;     - existance of a 'palette' array, which is 256 * 3 db and gives the red, green, and blue components
;;;       of each palette entry (value range 0-63 for each channel)
;;;     - the current video mode must be set to mode 13h before calling this subroutine
;;;     - ds:si to point to the beginning of the palette array
;;; DESTROYS:
;;;     - al, cl, dx, si, ebx
;;; RETURNS:
;;;     (- nothing)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Set_Palette_13H:
    xor cl,cl
    call Wait_For_VSync
    index:
        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        ; load the next color into a register. we load all three 8-bit components (r,g,b) at once,
        ; plus one exra that we ignore (as we don't have a 24-bit register to get just the three components).
        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        mov ebx,dword [ds:si]               ; bl = red, bh = green, low 8 bits above bh = blue.
        add si,3                            ; move the array pointer to the beginning of the next palette entry.

        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        ; set which palette index to modify.
        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        mov al,cl
        mov dx,3c8h
        out dx,al

        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        ; set the color (r, g, b) at that index.
        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        mov dx,3c9h
        mov al,bl
        out dx,al
        mov al,bh
        out dx,al
        shr ebx,8                           ; shift right to move the 8 bits above bh into bh.
        mov al,bh
        out dx,al

        inc cl
        jnz index                           ; stop looping when cl==0, i.e. when the counter loops from ..., 253, 254, 255 to 0.
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Clears the video memory in VGA mode 13h four bytes at a time.
;;;
;;; EXPECTS:
;;;	- eax to hold the value to clear with, such that each of its bytes is a copy of that value
;;;	- di to point to the beginning of video memory (segment: es).
;;; DESTROYS:
;;;     - di
;;; RETURNS:
;;;     (- nothing)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Reset_Screen_Buffer_13H:
    mov eax,0                           ; color to clear with.
    mov cx,3e80h                        ; how many bytes to clear (320*200 = 64000/4 = 16000).
    rep stosd                           ; clear the screen in four-byte steps.

    ret
