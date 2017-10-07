;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Subroutines for handling mouse input.
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Initialize the mouse driver.
;;;
;;; EXPECTS:
;;;     - the video mode should be regular text mode when calling this routine, as the routine may print an error message
;;; DESTROYS:
;;;     - ax
;;; RETURNS:
;;;     - ax = whether we successfully initialized the mouse (0 = no, FFFF = yes).
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Enable_Mouse:
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; acquire the mouse via interrupt 33.
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    xor ax,ax
    int 33h                                 ; if failed to acquire, will return 0 in ax, otherwise ax will be ffff.
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Translates the mouse's current coordinates to the edit segment.
;;;
;;; Note that this function should be called AFTER you've obtained the mouse cursor's current x,y coordinates
;;; and stored them in mouse_pos_xy.
;;;
;;; EXPECTS:
;;;     - ds to point to the general data segment.
;;; DESTROYS:
;;;     (- unknown)
;;; RETURNS:
;;;     (- unknown)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Translate_Mouse_Pos_To_Edit_Segment:
    mov ebx,dword [mouse_pos_xy]                  ; get the mouse cursor position. ax = mouse x, eax upper 16 bits = mouse y coordinate.

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; make the mouse position relative to the 0,0 corner of the edit segment, and make sure that
    ; position is inside the screen.
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    sub bx,4
    js .not_in_segment                      ; jump if below 0.
    rol ebx,16                              ; move x coordinate into ax.
    sub bx,99
    js .not_in_segment                      ; jump if below 0.

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; translate the mouse cursor to a pala pixel index (i.e. to a 16x16 grid).
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    mov cl,[magnification]
    mov ax,bx
    div cl
    cmp al,PALA_W
    jge .not_in_segment                     ; if the index is >= 16, we know we're outside the pala.
    mov dl,al                               ; set translated mouse x.
    rol ebx,16
    mov ax,bx
    div cl
    cmp al,PALA_H
    jge .not_in_segment                     ; if the index is >= 16, we know we're outside the pala.
    mov dh,al                               ; set translated mouse y.

    mov [mouse_pos_edit_xy],dx
    mov [mouse_inside_edit],1

    jmp .exit

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; if the cursor isn't inside the edit segment, set the 16th bit in eax to 0 to signal this.
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    .not_in_segment:
    mov [mouse_inside_edit],0

    .exit:
    ret
