;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Subroutines for drawing things to screen in VGA mode 13h.
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Draws a strip of palette color swatches from which the user can select the color to draw with.
;;; Each swatch is 8 px wide and 6 px tall.
;;;
;;; EXPECTS:
;;;     (- unknown)
;;; DESTROYS:
;;;     (- unknown)
;;; RETURNS:
;;;     (- unknown)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Draw_Color_Selector:
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; constants.
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    .SIDE_OFFSET    = 13
    .SWATCH_WIDTH   = 8
    .SWATCH_HEIGHT  = 6
    .FONT_HEIGHT    = 6

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
        inc al
        cmp al,32
        jne .draw_swatches

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; draw swatch labels, which tell you the color index of the given swatch.
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    mov di,(SCREEN_W * 4) + (SCREEN_W - .SIDE_OFFSET) + 3
    mov bx,0                                ; index number to print to screen.
    .draw_labels:
        mov cl,'d'                          ; text color.
        call Draw_Unsigned_Integer
        inc bx
        add di,SCREEN_W * .FONT_HEIGHT
        cmp bx,32
        jne .draw_labels

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; draw the currently selected color's label with a brighter color.
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    mov ax, (.FONT_HEIGHT * SCREEN_W)
    movzx bx, [pen_color]
    mul bx                                  ; ax = y offset of the start of the swatch's label.
    mov di,(SCREEN_W * 4) + (SCREEN_W - .SIDE_OFFSET) + 3   ; x,y coordinate of the first color swatch.
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

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; constants.
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
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
;;; Draws an image on screen in VGA mode 13h.
;;;
;;; EXPECTS:
;;;     - ds:si to point to the beginning of the image's pixel buffer
;;;	- es:di to point to the location in video memory where the top left corner of the image will be drawn
;;;     - the first byte of the image should give the width of the image, and the second by the image's height.
;;; DESTROYS:
;;;     - eax, bx, cx
;;; RETURNS:
;;;     (- nothing)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Draw_Image:
    push si
    push di
    mov bx,word [ds:si]                     ; bl = image width, bh = image height.
    add si,2
    movzx cx,bh                             ; loop over each row in the image.
    .draw_img_y:
        push cx
        movzx cx,bl                         ; loop over each column on this row.
        .draw_img_x:
            lodsb                           ; load the next pixel from the image buffer (ds:si), and place it in al. also increments si.
            stosb                           ; write the pixel into the video buffer (es:di). also increments di.
            loop .draw_img_x
        add di,SCREEN_W                     ; move to the next row on the screen (-1 for obliqueness).
        movzx cx,bl                         ; move back to the start of the image's next row on the screen.
        sub di,cx                           ;
        pop cx
        loop .draw_img_y
    pop di
    pop si
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Draws an image on screen in VGA mode 13h, skipping pixels with a palette index of 15.
;;; The reason this subroutine is called Draw_Mouse_Cursor is that it checks to make sure no attempts are made to
;;; draw past the borders of the screen.
;;;
;;; Note that the maximum image size is 127 x 127.
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
            mov al,[ds:si]                  ; load the next pixel from the image buffer (ds:si).
            cmp al,TRANSPARENT_COLOR
            je .skip_pixel                  ; don't write transparent pixels.
            mov [es:di],al                  ; write the pixel into the video buffer (es:di).
            .skip_pixel:
            dec dh                          ; keep track of how far into the adjusted image width we've drawn,
            jz .next_row                    ; and if we've fully drawn up to the adjusted width, stop and move to the next row.
            inc di
            inc si
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
