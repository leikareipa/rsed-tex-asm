;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Subroutines for handling things to do with the editor, like mouse clicks, painting, saving, etc.
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Deals with mouse movement.
;;;
;;; EXPECTS:
;;;     (- unknown)
;;; DESTROYS:
;;;     (- unknown)
;;; RETURNS:
;;;     (- unknown)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Handle_Editor_Mouse_Move:
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; find out which editor segment the mouse is in.
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    mov ax,word[mouse_pos_xy+2]         ; ax = mouse y pos.
    cmp ax,90
    jl .in_palat
    cmp ax,290
    jl .in_edit
    jmp .in_palette

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; deal with clicks to the palat segment.
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    .in_palat:
    jmp .exit

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; deal with clicks to the edit segment.
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    .in_edit:
    jmp .exit

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; deal with clicks to the palette segment.
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    .in_palette:
    jmp .exit

    .exit:
    ret

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
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; see if any mouse buttons were pressed, and if not, we can exit.
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    test [mouse_buttons],01b
    jz .exit

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; find out which editor segment the mouse is in.
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    mov ax,word[mouse_pos_xy+2]             ; ax = mouse y pos.
    cmp ax,90
    jl .in_palat
    cmp ax,290
    jl .in_edit
    jmp .in_palette

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; deal with clicks to the palat segment.
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    .in_palat:
    call Handle_Pala_Click
    jmp .exit

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; deal with clicks to the edit segment.
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    .in_edit:
    call Handle_Edit_Click
    jmp .exit

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; deal with clicks to the palette segment.
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    .in_palette:
    call Translate_Mouse_Pos_To_Palette_Segment
    cmp [mouse_inside_palette],1
    jne .exit

    ; change the pen color.
    mov al,[mouse_pos_palette_y]
    cmp al,[pen_color]                      ; if the pen color is the same as before, no need to change anything.
    je .exit
    mov [pen_color],al
    mov [gfx_mouse_cursor+13],al            ; make the color of the mouse cursor's tip be the color we've got selected.

    call Draw_Palette_Selector

    jmp .exit

    .exit:
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Handles a mouse click to the pala selector segment.
;;;
;;; EXPECTS:
;;;     (- unknown)
;;; DESTROYS:
;;;     (- unknown)
;;; RETURNS:
;;;     (- unknown)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Handle_Pala_Click:
    call Translate_Mouse_Pos_To_Palat_Segment

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; bail out if the mouse cursor isn't inside the palat segment at all.
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    cmp [mouse_inside_palat],1
    jne .exit

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; calculate the index of the pala.
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    mov al,byte[mouse_pos_palat_xy+1]       ; y.
    mov cl,NUM_PALA_THUMB_X
    mul cl                                  ; al = index horizontally.
    add al,byte[mouse_pos_palat_xy]         ; al += x.

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; we don't need to do anything if the pala we clicked on was already selected.
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    cmp al,[selected_pala]
    je .exit

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; repaint the previously selected pala's thumbnail, to indicate any changes in it.
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    push ax
    movzx ax,[selected_pala]
    mov di,[prev_pala_thumb_offs]
    add di,SCREEN_W
    call Draw_Pala_Thumbnail
    pop ax

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; change the pala we've got selected, and redraw the editor to update that we've selected
    ; a different pala.
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    mov [selected_pala],al
    call Draw_Pala_Editor

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; erase the frame of the previously-selected pala's thumbnail.
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    mov di,[prev_pala_thumb_offs]
    mov eax,0                               ; the frame's color.
    call Draw_Pala_Thumb_Halo

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; draw a frame around the pala we chose.
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; first, calculate the x,y pixel offset at the top left corner of this thumbnail.
    movzx ax,byte[mouse_pos_palat_xy]       ; x.
    shl ax,3                                ; ax *= 8, the height of a pala thumbnail.
    mov di,ax
    add di,3                                ; offset horizontally to match the palat selector segment.
    movzx ax,byte[mouse_pos_palat_xy+1]     ; y.
    shl ax,3                                ; ax *= 8, the width of a pala thumbnail.
    add ax,8                                ; offset vertically to match the palat selector segment.
    mov cx,SCREEN_W
    mul cx                                  ; ax = absolute screen y coordinate.
    add di,ax
    mov [prev_pala_thumb_offs],di
    ; then draw it.
    mov eax,05050505h                       ; the frame's color.
    call Draw_Pala_Thumb_Halo

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; update the ui text on which pala we've got selected.
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    call Draw_Current_Pala_ID

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
    mov dx,SCREEN_W
    mul dx
    add bx,ax
    add bx,99                               ; x offset on screen of the edit segment.
    mov di,bx                               ; set the starting pixel in the video buffer for drawing the new edit pixel.
    mov bl,[pen_color]

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; draw the pixel with the set color at the current level of magnification.
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
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
    ; get the offset in the pala's data where we clicked.
   ; mov cl,PALA_W
    movzx di,byte[mouse_pos_edit_xy]    ; x.
    movzx ax,byte[mouse_pos_edit_xy+1]    ; y.
    ;mul cl                              ; ax = al * PALA_W.
    shl ax,4                            ; multiply by 16 (PALA_W).
    add di,ax                           ; di = offset in pala's data where we clicked.
    ; then get the offset of this pala's first pixel in the palat data buffer.
    mov ax,(PALA_W * PALA_H)
    movzx cx,byte[selected_pala]
    mul cx
    add di,ax                           ; di = offset of the pixel we edited in the palat data buffer.
    mov bl,[pen_color]
    mov [gs:pala_data+di],bl            ; save the altered pixel into the data array.

    .exit:
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Deals with keyboard input by responding properly to the program's keyboard shortcuts.
;;;
;;; EXPECTS:
;;;     (- unknown)
;;; DESTROYS:
;;;     (- unknown)
;;; RETURNS:
;;;     (- unknown)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Handle_Editor_Keyboard_Input:
    mov al,[key_pressed]

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; find out which key was pressed.
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    .test_no_key:
    cmp al,KEY_NO_KEY
    je .exit

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; set the pala editor's size larger.
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    .test_plus:
    cmp al,KEY_PLUS
    jne .test_minus
    add [magnification],4
    cmp [magnification],12                  ; make sure we set the size no larger than 12.
    jng .repaint_plus
    mov [magnification],12
    jmp .exit                               ; we already had the maximum size, so don't need to redraw.
    .repaint_plus:
    call Redraw_All
    jmp .exit

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; set the pala editor's size smaller.
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    .test_minus:
    cmp al,KEY_MINUS
    jne .exit
    sub [magnification],4
    jnz .repaint_minus
    mov [magnification],4                   ; if the size is smaller than 4, set it to 4.
    jmp .exit                               ; we already had the minimum size, so no need to redraw.
    .repaint_minus:
    call Redraw_All
    jmp .exit

    .exit:
    ret
