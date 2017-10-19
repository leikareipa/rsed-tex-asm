;
; RSED_TEX
;
; A texture editor for Rally-Sport (the DOS game from 1996).
;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; constants.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DEBUG_MODE          = 0                     ; set to 1 if the debug mode is enabled.
BASE_MEM_REQUIRED   = 200                   ; how much base (conventional) memory the program needs. if the user has less, the program exits.
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
NUM_PALA_THUMB_X    = 11                    ; the number of pala thumbnails horizontally in the palat selector.
NUM_PALA_THUMB_Y    = 23                    ; the number of pala thumbnails vertically in the palat selector.

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
include "editor/editor.asm"

start:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; get the amount of free conventional memory, by looking at the dos psp (program segment prefix).
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
mov ax,@BASE_DATA
mov gs,ax
mov bx,ds                                   ; get the address of the psp.
mov ax,[ds:2]                               ; get from the psp the last paragraph allocated to the program.
sub ax,bx
shr ax,6                                    ; convert to kilobytes.
mov [gs:free_conventional_memory],ax

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; skip parsing the command line if we have debugging enabled. if we don't do this, the dosbox debugger wigs out.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
mov ax,DEBUG_MODE
cmp ax,1
je .assign_segments

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; parse the command line.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
call Parse_Command_Line
cmp al,1
je .assign_segments

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; if we failed to parse the command line, display an error message and exit.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
mov dx,str_cmd_argument_info
mov ah,9h
int 21h
mov dx,err_bad_cmd_line
mov ah,9h
int 21h
jmp .exit

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; assign segments.
; cs = code, ds = data, es = video memory buffer, fs = copy of ds, gs = palat file data as a flat array.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.assign_segments:
mov ax,@BASE_DATA
mov ds,ax
mov fs,ax
mov ax,@BUFFER_1
mov es,ax
mov ax,@BUFFER_2
mov gs,ax

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; exit if we don't have enough conventional memory.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
cmp [free_conventional_memory],BASE_MEM_REQUIRED
jge .load_sandbox
mov dx,err_low_memory
mov ah,9h
int 21h
jmp .exit

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; load the track's specific data from the sandboxed ~~LLYE.EXE. this assumes that rsed_ldr has first been run
; to sandbox the RALLYE.EXE file and apply the track's manifesto to it.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.load_sandbox:
call Load_Sandbox_Data
cmp al,0
jne .load_palat
mov ah,9h
mov dx,err_sandbox
int 21h
jmp .exit

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; load the palat file. also check to see if there was an error loading it, and if so, exit.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.load_palat:
call Load_Palat_File
cmp al,0
jne .enable_mouse
mov ah,9h
mov dx,err_palat_load
int 21h
jmp .exit

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; enable the mouse. the routine will return 0 in ax if it failed.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.enable_mouse:
call Enable_Mouse
cmp ax,0
jne .got_mouse
mov dx,err_mouse_init                       ; if we failed to acquire the mouse, display an error message and exit.
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
;call Set_Timer_Interrupt_Handler

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; clear the screen and fill the video buffer with the ui's controls.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
call Reset_Screen_Buffer_13H
call Draw_Palette_Selector
call Draw_Palat_Selector
call Draw_Project_Title
call Draw_Current_Pala_ID
call Draw_Pala_Editor
call Save_Mouse_Cursor_Background       ; prevent a black box in the upper left corner of the screen on startup.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; draw a halo around the currently selected pala's thumbnail in the palat selector.
; on startup, its position is marked in prev_pala_thumb_offs.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
mov di,[prev_pala_thumb_offs]
mov eax,05050505h                       ; the frame's color.
call Draw_Pala_Thumb_Halo

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

    call Draw_Project_Title

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; exit if the user right-clicked the mouse.
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    test [mouse_buttons],10b                ; bit 1 is set if the right button was clicked.
    jnz .init_exit

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; get mouse position and button status. will place mouse x position in cx, and y position in dx. bx will hold mouse button status.
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    mov ecx,dword [mouse_pos_xy]
    mov dword [prev_mouse_pos_xy],ecx       ; save the mouse's location from last frame.
    mov ax,3
    int 33h
    shr cx,1                                ; divide x coordinate by 2.
    rol ecx,16                              ; move x coordinate into high bits of ecx.
    mov cx,dx                               ; put y coordinate into low bits of ecx.
    mov dword [mouse_pos_xy],ecx            ; save the mouse position for later use.
    mov word [mouse_buttons],bx             ; save mouse buttons' status for later use.

    call Redraw_Mouse_Cursor_Background     ; repaint the cursor's background at its position last frame.

    call Handle_Editor_Mouse_Move           ; process mouse movement in some way.
    call Handle_Editor_Mouse_Click          ; process the mouse click in some way.

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; if the mouse is at the upper border of the screen, print out how long it took to render the previous frame.
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    mov al,DEBUG_MODE
    cmp al,1
    jne .skip_fps_display
    movzx bx,[frame_time]
    mov cl,'g'
    mov di,628
    call Draw_Unsigned_Integer
    mov [frame_time],0

    .skip_fps_display:

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; print out the mouse's current coordinates.
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;cmp [mouse_inside_palat],1
    ;jne .skip_mouse_display
    ;mov dx,[mouse_pos_palat_xy]
    ;movzx bx,dl
    ;mov cl,'g'
    ;mov di,(SCREEN_W * 1) + 70
    ;call Draw_Unsigned_Integer_Long
    ;movzx bx,dh
    ;mov cl,'g'
    ;mov di,(SCREEN_W * 1) + 50
    ;call Draw_Unsigned_Integer_Long
    ;.skip_mouse_display:
    ;movzx bx,byte [mouse_pos_palette_y]
    ;mov cl,'g'
    ;mov di,(SCREEN_W * 1) + 20
    ;call Draw_Unsigned_Integer_Long

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; draw the mouse cursor.
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
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
;call Restore_Timer_Interrupt_Handler        ; make sure DOS gets its timer handler back.
call Set_Video_Mode_To_Text                 ; exit out of VGA mode 13h.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; save the palat data to disk.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
call Save_Palat_File
cmp al,1
je .exit
mov dx,str_cmd_argument_info
mov ah,9h
int 21h

.exit:
mov ah,4ch
mov al,0
int 21h

; end of program





segment @BASE_DATA
    free_conventional_memory dw 0           ; the amount of free conventional memory (in kb) at program startup.

    tmp_int_str db "m999",0                 ; a temporary buffer used when printing integers to the screen.

    ; mouse.
    mouse_pos_xy dd 0                       ; the x,y coordinates of the mouse cursor.
    prev_mouse_pos_xy dd 0                  ; the mouse's x,y coordinates in the previous frame.
    mouse_buttons dw 0                      ; mouse button status.

    mouse_inside_edit db 0                  ; set to 1 if the mouse is within the pala texture in the edit field.
    mouse_pos_edit_xy dw 0                  ; the position of the mouse cursor relative to the edit segment.

    mouse_inside_palette db 0               ; set to 1 if the mouse is within the color swatches in the color selector.
    mouse_pos_palette_y db 0                ; the position of the mouse cursor relative to the palette segment.

    mouse_inside_palat db 0                 ; set to 1 if the mouse is within the palat selector.
    mouse_pos_palat_xy dw 0                 ; the position of the mouse cursor relative to the palat segment.
    prev_pala_thumb_offs dw 2587            ; the pixel offset on the screen of the top left corner of the thumbnail of the previously selected pala.
                                            ; it's set by default to the 4th thumbnail.

    ; editing.
    magnification db 12                     ; by how much the current pala should be magnified.
    selected_pala db 3                      ; the index in the PALAT file of the pala we've selected for editing.
    selected_pala_offset dw 16*16*3         ; pre-computed offset from the start of the PALA file data for the currently selected pala.
    hovering_pala db 0                      ; the pala over which the mouse is hovering in the palat selector.
    pen_color db 5                          ; which palette index the pen is painting with.

    ; file handles.
    fh_project_file dw 0
    fh_sb_rallye_exe dw 0

    file_pala_data_start dd 0               ; the byte offset in the project's file where the palat file's data starts.

    ; track info.
    track_id db 0                               ; which track we have (0-7).
    palat_id db 0                               ; which palat file we use (0-1).
    track_palette_id db 0,0,0,0,1,2,0,3         ; which of the game's four palettes the given track uses.
    palette_offset dd 202d6h,20336h,20396h,203f6h ; the byte offset at which the xth palette begins in RALLYE.EXE.

    ; STRINGS
    ; error messages.
    err_sandbox db "ERROR: Failed to access sandboxed information. Exiting.",0ah,0dh
                db "   Make sure you've run rsed_ldr first.",0ah,0dh,"$"
    err_mouse_init db "ERROR: Failed to initialize the mouse. Exiting.",0ah,0dh
                   db "   Make sure your mouse is installed and that its driver is active.",0ah,0dh,"$"
    err_palat_load db "ERROR: Failed to load data from the project file. Exiting.",0ah,0dh,"$"
    err_low_memory db "ERROR: Not enough free conventional memory to run the program. Exiting.",0ah,0dh
                   db "   Try to have at least 200 KB of free memory.",0ah,0dh,"$"
    err_bad_cmd_line db "ERROR: Malformed command line argument. Exiting.",0ah,0dh,"$"

    ; ui messages.
    message_str db "cCURRENT PALA:    .",0
    project_name_str db "cDEBUG",0,0,0,0
    pala_file_str db "cPALAT.001",0         ; the name of the palat file we're editing. for cosmetic purposes.
    str_unsaved_changes db "f*",0           ; a little indicator shown next to the project name when there are unsaved changes.

    ; info messages.
    str_cmd_argument_info db "RallySportED Texture Editor v.7 / October 2017.",0ah,0dh
                          db "Expected command line usage: rsed_tex <track name>",0ah,0dh
                          db "The track name can be of up to eight ASCII characters from A-Z.",0ah,0dh,"$"

    ; file info.
    fn_project_file db "KLOROFYL\KLOROFYL.DTA",0,0,0,0 ; the name and path to the project file. this is changed later by the program to adjust to the project we want to open.
    fn_sb_rallye_exe db "~~LLYE.EXE",0      ; the name of the game's main executable, RALLYE.EXE, sandboxed to ~~LLYE.EXE.
    project_name db 0,0,0,0,0,0,0,0,0,"$"   ; the name of the project we're loading data from.
    project_name_len db 0                   ; the number of characters in the project name, excluding the null terminator.
    palat_file_name db "PALAT.001",0,0ah,0dh,"$" ; the name of the actual file we'll load the palat data from.
    project_file_name rb 22                 ; the name and path to the project file, which is 'proj_name\proj_name.xxx'.
    project_file_ext_offset dw 0            ; the offset in project_file_name where the file's 3-character extension begins.

    ; timer-related.
    int_8h_handler dd 10203040h             ; address of dos's interrupt handler. first word is the segment, second word is the address.
    frames_done db 0                        ; how many frames we've rendered. used for naive timing; loops over every 256 frames.
    seconds db 0
    timer_ticks db 0                        ; how many ticks we've counted. this gets reset when we've tallied enough for a full second.
    timer_seconds db 0
    timer_keepup db 0                       ; used to help the dos timer keep up with custom timer values.
    frame_time db 0

    tmp dd 0                                ; a few temporary storage bytes.

    include "text/font.inc"                 ; the character set for the text renderer.
    include "graphics/palette.inc"          ; the graphics palette.
    include "input/mouse/mouse_cursor.inc"  ; the mouse cursor image.

segment @BUFFER_1
    vga_buffer rb 0fa00h                    ; we draw into this buffer, then flip it onto the screen at the end of the frame.

segment @BUFFER_2
    pala_data rb PALA_BUFFER_SIZE           ; the texture pixel data loaded from the palat file is stored here.

    cursor_background rb (CURSOR_W * CURSOR_H) ; used to store the background of the mouse cursor, so we can erase the cursor without redrawing the whole screen.

