;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Subroutines for handling things to do with the editor, like mouse clicks, painting, saving, etc.
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Deals with mouse clicks.
;;;
;;; EXPECTS:
;;;     (- unknown)
;;; DESTROYS:
;;;     (- unknown)
;;; RETURNS:
;;;     (- unknown)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Handle_Editor_Mouse_Click:
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; see if any mouse buttons were pressed, and if not, we can exit.
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    test [mouse_buttons],01b
    jz .exit

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; find out which editor segment the mouse is in.
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    mov eax,[mouse_pos_xy]
    rol eax,16                              ; move mouse x into ax.
    cmp ax,90
    jl .in_palat
    cmp ax,290
    jl .in_edit
    jmp .in_palette

    .in_palat:
    call Translate_Mouse_Pos_To_Palat_Segment

    cmp [mouse_inside_palat],1              ; if the mouse cursor isn't inside the editor rectangle for this segment, we don't need to do anything.
    jne .exit

    mov bx,1
    mov cl,'g'
    mov di,(SCREEN_W * 1) + 120
    call Draw_Unsigned_Integer_Long

    jmp .exit

    .in_edit:
    call Translate_Mouse_Pos_To_Edit_Segment

    cmp [mouse_inside_edit],1
    jne .exit

    mov bx,2
    mov cl,'g'
    mov di,(SCREEN_W * 1) + 120
    call Draw_Unsigned_Integer_Long

    jmp .exit

    .in_palette:
    call Translate_Mouse_Pos_To_Palette_Segment
    cmp [mouse_inside_palette],1
    jne .exit

    mov al,[mouse_pos_palette_y]
    mov [pen_color],al

    call Draw_Palette_Selector

    jmp .exit

    .exit:
    ret
