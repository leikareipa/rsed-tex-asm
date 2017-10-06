;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Subroutines for drawing things to screen in VGA mode 13h.
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Draws the currently selected pala as a large, paintable version in the middle of the screen.
;;;
;;; EXPECTS:
;;;     - ds to be the general data segment.
;;; DESTROYS:
;;;     - ax, si
;;; RETURNS:
;;;     (- nothing)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Draw_Pala_Editor:
    mov di,(SCREEN_W * 4) + 99                      ; positioning of the editor on screen.

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; draw the currently selected pala.
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    movzx ax,[selected_pala]
    .12x:
    cmp [magnification],3
    jne .8x
    call Draw_Pala_Enlarged_12X
    jmp .exit
    .8x:
    cmp [magnification],2
    jne .4x
    call Draw_Pala_Enlarged_8X
    jmp .exit
    .4x:
    call Draw_Pala_Enlarged_4X

    .exit:
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Draws a single pala texture as a custom-sized thumbnail.
;;;
;;; EXPECTS:
;;;     - es:di to point to the first pixel in the screen buffer to draw to
;;;     - ax to give the id of the pala texture to be drawn.
;;; DESTROYS:
;;;     (- unknown)
;;; RETURNS:
;;;     (- unknown)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Draw_Pala_Enlarged_4X:
    .MAGNIF = 4

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; calculate the starting offset of the given pala in the pala data array.
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    mov si,(PALA_W * PALA_H)
    mul si
    mov si,ax                                       ; si stores the offset.

    mov cx,PALA_H
    .column:
        push cx
        mov cx,PALA_W
        .row:
            mov ebx,dword [gs:pala_data+si]         ; get the next pixel from the pala.
            add si,1

            ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
            ; duplicate the pixel 4x into eax.
            ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
            mov bh,bl
            mov ax,bx
            rol eax,16
            mov ax,bx

            ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
            ; draw an enlarged pixel.
            ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
            push di
            stosd
            add di,(SCREEN_W - .MAGNIF)
            stosd
            add di,(SCREEN_W - .MAGNIF)
            stosd
            add di,(SCREEN_W - .MAGNIF)
            stosd
            pop di

            add di,.MAGNIF
            loop .row
        add di,((SCREEN_W * .MAGNIF) - (PALA_W * .MAGNIF))          ; move down to the next scanline.
        pop cx
        loop .column

    ret
Draw_Pala_Enlarged_8X:
    .MAGNIF = 8

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; calculate the starting offset of the given pala in the pala data array.
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    mov si,(PALA_W * PALA_H)
    mul si
    mov si,ax                                       ; si stores the offset.

    mov cx,PALA_H
    .column:
        push cx
        mov cx,PALA_W
        .row:
            mov ebx,dword [gs:pala_data+si]         ; get the next pixel from the pala.
            add si,1

            ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
            ; duplicate the pixel 4x into eax.
            ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
            mov bh,bl
            mov ax,bx
            rol eax,16
            mov ax,bx

            ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
            ; draw an enlarged pixel.
            ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
            push di
            stosd
            stosd
            add di,(SCREEN_W - .MAGNIF)
            stosd
            stosd
            add di,(SCREEN_W - .MAGNIF)
            stosd
            stosd
            add di,(SCREEN_W - .MAGNIF)
            stosd
            stosd

            add di,(SCREEN_W - .MAGNIF)
            stosd
            stosd
            add di,(SCREEN_W - .MAGNIF)
            stosd
            stosd
            add di,(SCREEN_W - .MAGNIF)
            stosd
            stosd
            add di,(SCREEN_W - .MAGNIF)
            stosd
            stosd
            pop di

            add di,.MAGNIF
            loop .row
        add di,((SCREEN_W * .MAGNIF) - (PALA_W * .MAGNIF))          ; move down to the next scanline.
        pop cx
        loop .column

    ret
Draw_Pala_Enlarged_12X:
    .MAGNIF = 12

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; calculate the starting offset of the given pala in the pala data array.
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    mov si,(PALA_W * PALA_H)
    mul si
    mov si,ax                                       ; si stores the offset.

    mov cx,PALA_H
    .column:
        push cx
        mov cx,PALA_W
        .row:
            mov ebx,dword [gs:pala_data+si]         ; get the next pixel from the pala.
            add si,1

            ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
            ; duplicate the pixel 4x into eax.
            ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
            mov bh,bl
            mov ax,bx
            rol eax,16
            mov ax,bx

            ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
            ; draw an enlarged pixel.
            ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
            push di
            mov dx,3
            .do:
                stosd
                stosd
                stosd
                add di,(SCREEN_W - .MAGNIF)
                stosd
                stosd
                stosd
                add di,(SCREEN_W - .MAGNIF)
                stosd
                stosd
                stosd
                add di,(SCREEN_W - .MAGNIF)
                stosd
                stosd
                stosd
                add di,(SCREEN_W - .MAGNIF)
                sub dx,1
                cmp dx,0
                jne .do
            pop di

            add di,.MAGNIF
            loop .row
        add di,((SCREEN_W * .MAGNIF) - (PALA_W * .MAGNIF)) ; move down to the next scanline.
        pop cx
        loop .column

    ret

Draw_Scaled_Pala_Pixel:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Draws all the editable pala textures.
;;;
;;; EXPECTS:
;;;     (- nothing)
;;; DESTROYS:
;;;     - ax, bx, cx, si, di
;;; RETURNS:
;;;     (- nothing)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Draw_Palat_Selector:
    .NUM_THUMBNAIL_ROWS     = 23
    .NUM_THUMBNAIL_COLUMNS  = 11
    .THUMBNAIL_SIZE         = 8

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; print the name of the project and palat file in the top right corner of the selector.
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    mov di,(SCREEN_W * 3) + 4
    mov si,str_unsaved_changes
    call Draw_String

    mov di,(SCREEN_W * 2) + 9
    mov si,project_name_str
    call Draw_String

    mov di,(SCREEN_W * 2) + 57
    mov si,pala_file_str
    call Draw_String

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; draw the thumbnails.
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    mov di,(SCREEN_W * (FONT_HEIGHT + 2)) + 3
    xor ax,ax
    mov cx,.NUM_THUMBNAIL_ROWS
    .column:
        push cx
        mov cx,.NUM_THUMBNAIL_COLUMNS
        .row:
            call Draw_Pala_Thumbnail
            add ax,1
            add di,.THUMBNAIL_SIZE
            loop .row
        pop cx
        add di,2560 - (.NUM_THUMBNAIL_COLUMNS * .THUMBNAIL_SIZE) ; move to the start of the next thumbnail row on the screen.
        loop .column

    mov di,(SCREEN_W * (SCREEN_H - FONT_HEIGHT - 0))+2
    mov si,pala_file_str
    call Draw_String

    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Draws a single pala texture as a 8x8 thumbnail.
;;;
;;; EXPECTS:
;;;     - es:di to point to the first pixel in the screen buffer to draw to
;;;     - ax to give the id of the pala texture to be drawn.
;;; DESTROYS:
;;;     - bx
;;; RETURNS:
;;;     (- nothing)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Draw_Pala_Thumbnail:
    .THUMBNAIL_SIZE         = 8

    push di
    push cx
    push ax

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; calculate the starting offset of the given pala in the pala data array.
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    mov bx,(PALA_W * PALA_H)
    mul bx
    mov bx,ax                               ; bx stores the offset.

    mov cx,(.THUMBNAIL_SIZE - 1)            ; we subtract 1 to get a horizontal outline effect.
    .row:
        push cx
        mov cx,(.THUMBNAIL_SIZE - 1)        ; we subtract 1 to get a vertical outline effect.
        add bx,2                            ; pre-add to these to get that outline effect.
        add di,1                            ;
        .column:
            mov al,[gs:pala_data+bx]        ; get the next pixel from the pala.
            mov byte [es:di],al             ; draw.
            add di,1
            add bx,2
            loop .column
        add di,(SCREEN_W - .THUMBNAIL_SIZE) ; move down to the next scanline.
        add bx,PALA_W                       ; skip a line in the pala, since we're doing 8x8 instead of 16x16.
        pop cx
        loop .row

    pop ax
    pop cx
    pop di

    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Draws a strip of palette color swatches from which the user can select the color to draw with.
;;; Each swatch is 8 px wide and 6 px tall.
;;;
;;; EXPECTS:
;;;     (- nothing)
;;; DESTROYS:
;;;     - di, ax, bx
;;; RETURNS:
;;;     (- nothing)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Draw_Color_Selector:
    .SIDE_OFFSET    = 13
    .SWATCH_WIDTH   = 8
    .SWATCH_HEIGHT  = 6

    sti                                     ; make sure the direction flag points forward.

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; we want to start drawing on the 5th scanline, in the right-hand corner of the screen.
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    mov di,(SCREEN_W * 4) + (SCREEN_W - .SIDE_OFFSET) - .SWATCH_WIDTH

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; draw the swatches.
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    mov al,0
    .draw_swatches:
        call Draw_Color_Swatch
        add al,1
        cmp al,32
        jne .draw_swatches

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; draw swatch labels, which tell you the color index of the given swatch.
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    mov di,(SCREEN_W * 4) + (SCREEN_W - .SIDE_OFFSET) + 2
    mov bx,0                                ; index number to print to screen.
    .draw_labels:
        mov cl,'d'                          ; text color.
        call Draw_Unsigned_Integer
        add bx,1
        add di,SCREEN_W * FONT_HEIGHT
        cmp bx,32
        jne .draw_labels

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; draw the currently selected color's label with a brighter color.
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    mov ax, (FONT_HEIGHT * SCREEN_W)
    movzx bx, [pen_color]
    mul bx                                  ; ax = y offset of the start of the swatch's label.
    mov di,(SCREEN_W * 4) + (SCREEN_W - .SIDE_OFFSET) + 2   ; x,y coordinate of the first color swatch.
    add di,ax                               ; move to the x,y of the selected color swatch.
    mov cl,'b'                              ; select a light color to print the label.
    call Draw_Unsigned_Integer

    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Draws a single color swatch, i.e. a block of a given color.
;;;
;;; EXPECTS:
;;;     - al to hold the palette index to be drawn.
;;;     - es:di to point to the first pixel in the screen buffer to start drawing to.
;;; DESTROYS:
;;;     - high 16 bits of eax
;;; RETURNS:
;;;     (- nothing)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Draw_Color_Swatch:
    push cx

    .SWATCH_WIDTH   = 8
    .SWATCH_HEIGHT  = 6

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; duplicate the palette index into all 4 bytes of eax, so we can write the 4 bytes to screen at once.
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    shl eax,8
    mov al,ah
    shl eax,8
    mov al,ah
    shl eax,8
    mov al,ah

    mov cx,.SWATCH_HEIGHT
    .draw_slice:
        stosd
        stosd
        add di,SCREEN_W - .SWATCH_WIDTH     ; move to the next scanline.
        loop .draw_slice

    pop cx

    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Draws the mouse cursor, with alpha. Checks to make sure no out-of-screen drawing is done.
;;;
;;; EXPECTS:
;;;     - ds:si to point to the beginning of the image's pixel buffer
;;;	- es:di to point to the location in video memory where the top left corner of the image will be drawn
;;; DESTROYS:
;;;     - ax, bx, cx, dx
;;; RETURNS:
;;;     (- nothing)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Draw_Mouse_Cursor:
    push si
    push di

    mov bx,word [ds:si]                     ; bl = image width, bh = image height.
    mov dl,bl                               ; make a copy of the image width, for adjusting the size if the cursor is outside the screen (see below).
    add si,2

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; make sure the image doesn't go past the borders of the screen. if it seems it would,
    ; adjust its bounding rectangle.
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    .check_height:
    xor dx,dx                               ; clear the remainder buffer for the upcoming div.
    mov ax,di
    mov cx,SCREEN_W
    div cx                                  ; ax / 320 to get the y coordinate (it'll fit into cl).
    movzx cx,bh
    mov dx,ax                               ; y coordinate += image height.
    add dx,cx                               ;
    sub dx,SCREEN_H
    js .check_width                         ; if y coordinate + image height < 200, move on, otherwise,
    sub cx,dx                               ; set the image's height such that it no longer extends below the screen's bottom border.
    mov bh,cl                               ; bh = adjusted image height.

    .check_width:
    xor dx,dx                               ; clear the remainder buffer for the upcoming mul.
    mov cx,SCREEN_W
    mul cx                                  ; 320 * floor(ax / 320),
    mov dx,di                               ; which gives us the x coordinate in dx,
    sub dx,ax                               ; when we subtract it from the full index (di).
    movzx cx,bl                             ; store image width in cx.
    add dx,cx                               ; dx = image x offset + image width.
    sub dx,SCREEN_W
    js .set_normal_width                    ; if x coordinate + image width < 320, move on, otherwise,
    sub cx,dx                               ; set the image's width such that it no longer extends below the screen's bottom border.
    mov dl,cl                               ; dl = adjusted image width.
    jmp .draw_image

    .set_normal_width:
    mov dl,bl

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; draw the image.
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    .draw_image:
    movzx cx,bh                             ; loop over each row in the image.
    .draw_img_y:
        push cx
        movzx cx,bl                         ; loop over each column on this row.
        mov dh,dl                           ; copy the adjusted image width into a scratch register, where it can be modified while maintaining the original.
        .draw_img_x:
            mov al,[ds:si]                  ; load the next pixel from the cursor image buffer (ds:si).
            cmp al,TRANSPARENT_COLOR
            je .skip_pixel                  ; don't write transparent pixels.
            mov [es:di],al                  ; write the pixel into the video buffer (es:di).
            .skip_pixel:
            dec dh                          ; keep track of how far into the adjusted image width we've drawn,
            jz .next_row                    ; and if we've fully drawn up to the adjusted width, stop and move to the next row.
            add di,1
            add si,1
            loop .draw_img_x
        .next_row:
        add di,cx                           ; in case we skipped pixels due to the image being outside the screen borders,
        add si,cx                           ; adjust the indices to account for that skipping. if no skipping was done, cx == 0.
        add di,SCREEN_W                     ; move to the next row on the screen.
        movzx cx,bl                         ; move back to the start of the image's next row on the screen.
        sub di,cx                           ;
        pop cx
        loop .draw_img_y

    .done:
    pop di
    pop si
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Stores the mouse's current background into a buffer.
;;;
;;; EXPECTS:
;;;     - gs to point to the pixel buffer's segment.
;;;	- es to point to the video memory buffer's segment.
;;; DESTROYS:
;;;     - al, ecx, di, si
;;; RETURNS:
;;;     (- nothing)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Save_Mouse_Cursor_Background:
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; map the mouse's x,y position into an offset in the video memory buffer.
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    mov ecx,[mouse_pos_xy]
    call ECX_To_VGA_Mem_Offset
    add di,vga_buffer                       ; offset the video memory buffer index to start where the buffer starts in its segment.
    mov si,cursor_background                ; we'll save the pixels into gs:si.

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; save the background. note that we omit to check for access outside the boundaries of the screen.
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    mov cl,CURSOR_H
    .column:
        mov ch,CURSOR_W
        .row:
            mov al,[es:di]                  ; load a pixel from the screen.
            mov [gs:si],al                  ; save the pixel into the pixel buffer.
            add di,1
            add si,1
            sub ch,1
            jnz .row
        add di,(SCREEN_W - CURSOR_W)        ; move to the next scanline.
        sub cl,1
        jnz .column

    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Draws an image that represents the mouse cursor's background over the mouse cursor, thereby erasing the
;;; cursor from the screen while minimizing the screen area that is redrawn.
;;;
;;; EXPECTS:
;;;     - gs to point to the pixel buffer's segment.
;;;	- es to point to the video buffer's segment.
;;; DESTROYS:
;;;     - al, ecx, di, si
;;; RETURNS:
;;;     (- nothing)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Redraw_Mouse_Cursor_Background:
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; map the mouse's x,y position into an offset in the video memory buffer.
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    mov ecx,[prev_mouse_pos_xy]
    call ECX_To_VGA_Mem_Offset
    add di,vga_buffer                       ; offset the video memory buffer index to start where the buffer starts in its segment.
    mov si,cursor_background                ; the background pixel buffer.

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; redraw the cursor. note that we omit to check for access outside the boundaries of the screen.
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    mov cl,CURSOR_H
    .column:
        mov ch,CURSOR_W
        .row:
            mov al,[gs:si]                  ; load a pixel from the buffer.
            mov [es:di],al                  ; save the pixel into the video buffer.
            add di,1
            add si,1
            sub ch,1
            jnz .row
        add di,(SCREEN_W - CURSOR_W)        ; move to the next scanline.
        sub cl,1
        jnz .column

    ret
