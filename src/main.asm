;
; RSED_TEX
;
; A texture editor for Rally-Sport (the DOS game from 1996).
;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; constants.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
VRAM_SEG            = 0a000h                ; address of the video ram segment in vga mode 13h.
TRANSPARENT_COLOR   = 0                    ; transparent color index.
SCREEN_W            = 320                   ; screen resolution (vga mode 13h).
SCREEN_H            = 200                   ;
REFRESH_RATE        = 60                    ; how many frames per second we render.
TIMER_RES           = 5                     ; timer resolution, in milliseconds.
TIMER_TICKS_PER_SEC = 200                   ; how many times per second the timer interrupt is fired.

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

start:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; assign segments.
; cs = code, ds = data, es = video memory buffer, fs = copy of ds.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
mov ax,@BASE_DATA
mov ds,ax
mov fs,ax
mov ax,@BUFFER_1
mov es,ax

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; initialize vga mode to 13h for graphics.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
call Set_Video_Mode_13H

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; enable the mouse. the routine will return 0 in ax if it failed.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
call Enable_Mouse
cmp ax,0
jne .got_mouse

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; if we didn't manage to acquire the mouse, display an error message and exit the program.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
call Set_Video_Mode_To_Text
mov dx,err_mouse_init
mov ah,9h
int 21h
jmp .exit

.got_mouse:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; set the game's palette.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
mov si,palette
call Set_Palette_13H

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; enable our own timer interrupt.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
call Set_Timer_Interrupt_Handler

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; loop until the user presses the right mouse button.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.main_loop:
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; clear the screen.
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    mov di,vga_buffer
    call Reset_Screen_Buffer_13H

    call Draw_Color_Selector

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; exit if the user right-clicked the mouse.
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    test [mouse_buttons],10b                ; bit 1 is set if the right button was clicked.
    jnz .init_exit

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; get mouse position and button status. will place mouse x position in cx, and y position in dx. bx will hold mouse button status.
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    mov ax,3
    int 33h
    shr cx,1                                ; divide x coordinate by 2.
    rol ecx,10h                             ; move x coordinate into high bits of ecx.
    mov cx,dx                               ; put y coordinate into low bits of ecx.
    mov [mouse_pos_xy],ecx                  ; save the mouse position for later use.
    mov [mouse_buttons],bx                  ; save mouse buttons' status for later use.

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; if the mouse is at the upper border of the screen, print out how long it took to render the previous frame.
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    mov ax,word [mouse_pos_xy]              ; get the mouse's y coordinate.
    cmp ax,0
    jnz .skip_fps_display                   ; if the mouse isn't at the upper border, don't print out the fps display.
    movzx bx,[frame_time]
    mov cl,'c'
    mov di,308
    call Draw_Unsigned_Integer
    mov [frame_time],0
    .skip_fps_display:

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; draw the mouse cursor.
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    mov ecx,[mouse_pos_xy]
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

call Restore_Timer_Interrupt_Handler        ; make sure DOS gets its timer handler back.

.init_exit:
call Set_Video_Mode_To_Text                 ; exit out of VGA mode 13h.
.exit:
mov ah,4ch
int 21h

; end of program





segment @BASE_DATA
    tmp_int_str db "m999",0                 ; a temporary buffer used when printing integers to the screen.
    mouse_pos_xy dd 0                       ; the x and y coordinates of the mouse cursor.
    mouse_buttons dw 0                      ; mouse button status.

    ; error messages.
    err_mouse_init db "ERROR: Failed to initialize the mouse.",0ah,0dh,"$"

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
    vga_buffer rb 0fa00h
