;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Parses the command line to extract a single 1-8 character word.
;;;
;;; EXPECTS:
;;;     - ds to be the data segment in which the PSP and command line are stored.
;;; DESTROYS:
;;;     - ax, bx, cx, si, gs, ds
;;; RETURNS:
;;;     - al is set to 1 if the parsing succeeded, otherwise set to 0.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Parse_Command_Line:
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; parse the command line.
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    mov ax,ds
    mov gs,ax
    mov ax,@BASE_DATA
    mov ds,ax

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; get and test the command line length.
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    movzx cx,byte [gs:80h]                      ; total length of the command line string from the PSP.
    dec cx                                      ; we want to ignore the leading space in the string.
    mov ax,cx
    cmp ax,8
    jg .cmd_line_parse_fail                     ; we expect the project name to be at most 8 and at least 1 characters long.
    cmp ax,1
    jl .cmd_line_parse_fail

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; test the command line's formatting to make sure it's valid.
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    mov si,0
    mov bx,82h                                  ; start of the command line string.
    .cmd_space:
        mov al,[gs:bx]                          ; get the next character from the command line for testing and converting.
        cmp al,byte ' '
        je .cmd_line_parse_fail                 ; if we find any spaces, bail out.
        and al,11011111b                        ; convert the character to uppercase if it wasn't already.

        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        ; make sure there are only ASCII characters from A-Z.
        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        cmp al,'A'
        jl .cmd_line_parse_fail
        cmp al,'Z'
        jg .cmd_line_parse_fail

        mov [project_name+si],al                ; save the converted character in the project name string.
        mov [project_name_str+si+1],al                ; save the converted character in the printable project name string.
        inc si
        inc bx
        loop .cmd_space

    mov al,1
    jmp .cmd_line_parse_success

    .cmd_line_parse_fail:
    mov al,0

    .cmd_line_parse_success:

    ret
