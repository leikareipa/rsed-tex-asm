;
; RSED_TEX
;
; A texture editor for Rally-Sport (the DOS game from 1996).
;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; constants.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PALA_BUFFER_SIZE    = 65024                 ; how many bytes of data from the PALA file we'll load and handle.
VRAM_SEG            = 0a000h                ; address of the video ram segment in vga mode 13h.
TRANSPARENT_COLOR   = 0                     ; transparent color index.
SCREEN_W            = 320                   ; screen resolution (vga mode 13h).
SCREEN_H            = 200                   ;
TIMER_RES           = 5                     ; timer resolution, in milliseconds.
TIMER_TICKS_PER_SEC = 200                   ; how many times per second the timer interrupt is fired.
FONT_HEIGHT         = 6                     ; how many px tall the font is.
PALA_W              = 16                    ; dimensions of a pala texture.
PALA_H              = 16
CURSOR_W            = 10                    ; dimensions of the mouse cursor. NOTE: neither the width nor height should be more than 16 px.
CURSOR_H            = 13                    ; NOTE: if you change the cursor width, you need to change the cursor drawing routines as well.

format MZ

entry @CODE:start
; default stack size = 4096 bytes.

segment @CODE use16

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; includes.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
include "useful.asm"
include "text/text.asm"
include "graphics/vga.asm"
include "graphics/draw_routines.asm"
include "timer/timer.asm"
include "input/mouse/mouse.asm"
include "file/file.asm"
include "cmd_line/cmd_line.asm"

start:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; parse the command line.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
call Parse_Command_Line
cmp al,1
je .cmd_line_parse_success

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; if we failed to parse the command line, display an error message and exit.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
mov dx,err_commd_line_malformed
mov ah,9h
int 21h
mov dx,cmd_argument_info_str
mov ah,9h
int 21h
;jmp .exit

.cmd_line_parse_success:
;mov dx,project_name_str
;mov ah,9h
;int 21h
;jmp .exit

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; assign segments.
; cs = code, ds = data, es = video memory buffer, fs = copy of ds, gs = palat file data as a flat array.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
mov ax,@BASE_DATA
mov ds,ax
mov fs,ax
mov ax,@BUFFER_1
mov es,ax
mov ax,@BUFFER_2
mov gs,ax

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; load the palat file. also check to see if there was an error loading it, and if so, exit.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
call Load_Palat_File
cmp al,0
jne .got_file
mov dx,palat_file_name                      ; if we failed to load the palat file, display an error message and exit.
mov ah,9h
int 21h
mov dx,err_palat_load
int 21h
jmp .exit
.got_file:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; enable the mouse. the routine will return 0 in ax if it failed.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
call Enable_Mouse
cmp ax,0
jne .got_mouse
mov dx,err_mouse_init                       ; if we fialed to acquire the mouse, display an error message and exit.
mov ah,9h
int 21h
jmp .exit
.got_mouse:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; initialize vga mode to 13h for graphics.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
call Set_Video_Mode_13H

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; set the game's palette.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
mov si,palette
call Set_Palette_13H

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; enable our own timer interrupt.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
call Set_Timer_Interrupt_Handler

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; clear the screen and fill the video buffer with the ui's controls.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
call Reset_Screen_Buffer_13H
call Draw_Color_Selector
call Draw_Palat_Selector
call Draw_Pala_Editor
call Save_Mouse_Cursor_Background           ; prevent a black box in the upper left corner of the screen on startup.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; loop until the user presses the right mouse button.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.main_loop:
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; clear the screen.
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;mov di,vga_buffer
    ;call Reset_Screen_Buffer_13H
    call Reset_Screen_Buffer_13H_Partially  ; for temporary debugging.

    ;call Draw_Color_Selector
    ;call Draw_Palat_Selector
    ;call Draw_Pala_Editor

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; exit if the user right-clicked the mouse.
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    test [mouse_buttons],10b                ; bit 1 is set if the right button was clicked.
    jnz .init_exit

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; get mouse position and button status. will place mouse x position in cx, and y position in dx. bx will hold mouse button status.
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    mov ecx,dword [mouse_pos_xy]
    mov dword [prev_mouse_pos_xy],ecx             ; save the mouse's location from last frame.
    mov ax,3
    int 33h
    shr cx,1                                ; divide x coordinate by 2.
    rol ecx,10h                             ; move x coordinate into high bits of ecx.
    mov cx,dx                               ; put y coordinate into low bits of ecx.
    mov dword [mouse_pos_xy],ecx                  ; save the mouse position for later use.
    mov word [mouse_buttons],bx                  ; save mouse buttons' status for later use.

    call Translate_Mouse_Pos_To_Edit_Segment

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; if the mouse is at the upper border of the screen, print out how long it took to render the previous frame.
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    mov ax,word [mouse_pos_xy]              ; get the mouse's y coordinate.
    cmp ax,0
    ;jnz .skip_fps_display                   ; if the mouse isn't at the upper border, don't print out the fps display.
    movzx bx,[frame_time]
    mov cl,'g'
    mov di,628
    call Draw_Unsigned_Integer
    mov [frame_time],0
    .skip_fps_display:

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; print out the mouse's current coordinates.
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    cmp [mouse_inside_edit],1
    jne .skip_mouse_display
    mov dx,[mouse_pos_edit_xy]
    movzx bx,dl
    mov cl,'g'
    mov di,(SCREEN_W * 1) + 70
    call Draw_Unsigned_Integer_Long
    movzx bx,dh
    mov cl,'g'
    mov di,(SCREEN_W * 1) + 50
    call Draw_Unsigned_Integer_Long
    .skip_mouse_display:

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; draw the mouse cursor.
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    call Redraw_Mouse_Cursor_Background     ; repaint the cursor's background at its position last frame.
    call Save_Mouse_Cursor_Background       ; save the cursor's background this frame, so we can use to it erase the cursor next frame.
    mov ecx,dword [mouse_pos_xy]
    call ECX_To_VGA_Mem_Offset              ; map the mouse's x,y position into an offset in the video memory buffer (di).
    add di,vga_buffer                       ; offset the video memory buffer index to start where the buffer starts in its segment.
    mov si,gfx_mouse_cursor
    call Draw_Mouse_Cursor

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; copy the vga buffer to video memory.
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    mov si,vga_buffer
    call Flip_Video_Buffer

    jmp .main_loop

; end of main loop.

.init_exit:
call Restore_Timer_Interrupt_Handler        ; make sure DOS gets its timer handler back.
call Set_Video_Mode_To_Text                 ; exit out of VGA mode 13h.

.exit:
mov ah,4ch
int 21h

; end of program





segment @BASE_DATA
    project_name db 0,0,0,0,0,0,0,0,0,"$"   ; the name of the project, i.e. the name on its files, etc.

    tmp_int_str db "m999",0                 ; a temporary buffer used when printing integers to the screen.

    ; mouse.
    mouse_pos_xy dd 0                       ; the x,y coordinates of the mouse cursor.
    prev_mouse_pos_xy dd 0                  ; the mouse's x,y coordinates in the previous frame.
    mouse_buttons dw 0                      ; mouse button status.

    mouse_inside_edit db 0                  ; set to 1 if the mouse is within the pala texture in the edit field.
    mouse_pos_edit_xy dw 0                  ; the position of the mouse cursor relative to the edit segment.

    ; editing.
    magnification db 12                     ; by how much the current pala should be magnified.
    selected_pala db 3                      ; the index in the PALAT file of the pala we've selected for editing.
    pen_color db 4                          ; which palette index the pen is painting with.

    ; STRINGS
    ; error messages.
    err_mouse_init db "ERROR: Failed to initialize the mouse. Exiting.",0ah,0dh,"$"
    err_palat_load db "ERROR: Could not load data from the PALAT file. Exiting.",0ah,0dh,"$"
    err_commd_line_malformed db "ERROR: Malformed command line argument. Exiting.",0ah,0dh,"$"

    ; ui messages.
    cmd_argument_info_str db "   Expected command line usage: rsed_tex <project name>",0ah,0dh
                          db "   The project name can be of up to eight ASCII characters from A-Z.",0ah,0dh,"$"
    project_name_str db "c",0,0,0,0,0,0,0,0,0
    pala_file_str db "cPALAT.001",0         ; the name of the palat file we're editing. for cosmetic purposes.
    str_unsaved_changes db "f*",0           ; a little indicator shown next to the project name when there are unsaved changes.

    palat_file_name db "PALAT.001",0,0ah,0dh,"$" ; the name of the actual file we'll load the palat data from.

    ; timer-related.
    int_8h_handler dd 10203040h             ; address of dos's interrupt handler. first word is the segment, second word is the address.
    frames_done db 0                        ; how many frames we've rendered. used for naive timing; loops over every 256 frames.
    seconds db 0
    timer_ticks db 0                        ; how many ticks we've counted. this gets reset when we've tallied enough for a full second.
    timer_seconds db 0
    timer_keepup db 0                       ; used to help the dos timer keep up with custom timer values.
    frame_time db 0

    include "text/font.inc"                 ; the character set for the text renderer.
    include "graphics/palette.inc"          ; the graphics palette.
    include "input/mouse/mouse_cursor.inc"  ; the mouse cursor image.

segment @BUFFER_1
    vga_buffer rb 0fa00h                    ; we draw into this buffer, then flip it onto the screen at the end of the frame.

segment @BUFFER_2
    pala_data rb PALA_BUFFER_SIZE           ; the texture pixel data loaded from the palat file is stored here.

    cursor_background rb (CURSOR_W * CURSOR_H) ; used to store the background of the mouse cursor, so we can erase the cursor without redrawing the whole screen.

