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

    ; pre-calculate the pala offset in the PALAT data.

    jmp .exit

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; deal with clicks to the edit segment.
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    .in_edit:
    call Handle_Edit_Click
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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Handles a mouse click to the edit segment.
;;;
;;; EXPECTS:
;;;     (- unknown)
;;; DESTROYS:
;;;     (- unknown)
;;; RETURNS:
;;;     (- unknown)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Handle_Edit_Click:
    call Translate_Mouse_Pos_To_Edit_Segment

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; bail out if the mouse cursor isn't inside the edit segment at all.
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    cmp [mouse_inside_edit],1
    jne .exit

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; update the edit pixel under the mouse cursor.
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    mov cl,[magnification]
    mov al,byte [mouse_pos_edit_xy]         ; x.
    mul cl                                  ; convert from relative edit segment coordinates to absolute screen coordinates.
    mov bx,ax
    mov al,byte [mouse_pos_edit_xy+1]       ; y.
    mul cl                                  ; convert from relative edit segment coordinates to absolute screen coordinates.
    add ax,4                                ; y offset on screen of the edit segment.
    mov cx,SCREEN_W
    mul cx
    add bx,ax
    add bx,99                               ; x offset on screen of the edit segment.
    mov di,bx                               ; set the starting pixel in the video buffer for drawing the new edit pixel.
    mov bl,[pen_color]

    mov cl,[magnification]
    cmp cl,12
    jne .8x
    call Draw_Edit_Pixel_12X
    jmp .update_pala_data
    .8x:
    cmp cl,8
    jne .4x
    call Draw_Edit_Pixel_8X
    jmp .update_pala_data
    .4x:
    call Draw_Edit_Pixel_4X

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; update the pala's data in the PALAT array
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    .update_pala_data:
    mov cl,PALA_W
    movzx bx,byte [mouse_pos_edit_xy]         ; x.
    mov al,byte [mouse_pos_edit_xy+1]         ; y.
    mul cl                                  ; ax = al * PALA_W.
    add bx,ax                               ; bx = offset in pala's data where we clicked.
    ; then find the current index in the pala data.

    .exit:
    ret
