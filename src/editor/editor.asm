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
    rol eax,16                                  ; move mouse x into ax.
    cmp ax,90
    jl .in_palat
    cmp ax,290
    jl .in_edit
    jmp .in_palette

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; deal with clicks to the palat segment.
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    .in_palat:
    call Translate_Mouse_Pos_To_Palat_Segment

    cmp [mouse_inside_palat],1                  ; if the mouse cursor isn't inside the editor rectangle for this segment, we don't need to do anything.
    jne .exit

    ; pre-calculate the pala offset in the PALA data.

    jmp .exit

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; deal with clicks to the edit segment.
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    .in_edit:
    call Translate_Mouse_Pos_To_Edit_Segment

    cmp [mouse_inside_edit],1
    jne .exit

    ; set the pala pixel in the PALA dta array.
    ;
    mov cl,[magnification]
    mov al,byte [mouse_pos_edit_xy+1]     ; y.
    mul cl                                  ; convert from relative edit segment coordinates to absolute screen coordinates.
    add ax,4                                ; y offset on screen of the edit segment.
    mov cx,SCREEN_W
    mul cx
    mov bx,ax
    mov al,byte [mouse_pos_edit_xy]         ; x.
    mov cl,[magnification]
    mul cl                                  ; convert from relative edit segment coordinates to absolute screen coordinates.
    add bx,ax
    add bx,99                               ; x offset on screen of the edit segment.
    mov di,bx                               ; set the starting pixel in the video buffer for drawing the new edit pixel.
    mov bl,[pen_color]
    call Draw_Edit_Pixel_12X

    jmp .exit

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; deal with clicks to the palette segment.
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
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
