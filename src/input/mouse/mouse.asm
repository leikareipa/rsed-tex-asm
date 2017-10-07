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
    mov ebx,[mouse_pos_xy]                  ; ax = mouse x, upper 16 bits = mouse y coordinate.

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
    ; translate.
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    mov cl,[magnification]
    mov ax,bx
    div cl
    movzx bx,al
    rol ebx,16
    mov ax,bx
    div cl
    movzx bx,al

    rol ebx,16
    mov [mouse_pos_edit_xy],ebx

    jmp .exit

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; if the cursor isn't inside the edit segment, set the 16th bit in eax to 1 to signal this.
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    .not_in_segment:
    ;mov eax,[mouse_pos_edit_xy]
    ;or eax,10000000000000000000000000000000b
    ;mov [mouse_pos_edit_xy],eax

    .exit:
    ret
