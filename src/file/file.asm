;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Handles loading from and saving to files on disk.
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Loads 65024 bytes from the project's .dta file into a buffer in memory.
;;;
;;; EXPECTS:
;;;     - fn_project_file to give a zero-terminated file name to load from.
;;;     - pala_data to be a buffer we can read PALA_BUFFER_SIZE bytes into.
;;;     - gs to point to the segment holding the pala_data buffer.
;;;     - fs to be a copy of ds, the general data segment.
;;; DESTROYS:
;;;     (- unknown)
;;; RETURNS:
;;;     (- unknown)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Load_Palat_File:
    push ds                                 ; prepare to temporarily switch segments.

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; open the project's .dta file.
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    xor cx,cx
    mov dx,fn_project_file                  ; file name.
    mov ah,3dh                              ; set to open.
    mov al,0010b                            ; read/write.
    int 21h                                 ; do it.
    jc .exit_fail                           ; error-checking (the cf flag will be set by int 21h if there was an error).
    mov [fh_project_file],ax                ; save the file handle.

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; switch to the segment that holds the palat data buffer we want to read into.
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    mov ax,gs
    mov ds,ax

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; seek to where the palat file starts.
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    mov bx,[fs:fh_project_file]
    mov si,2                                ; the palat file is the 3rd file in the project's .dta file, so skip the first 2.
    .seek_to_kierros:
        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        ; get the length of the next file.
        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        mov dx,pala_data                        ; we use the palat data buffer as temporary storage here.
        mov ah,3fh
        mov cx,4                                ; 4 bytes == long int.
        int 21h
        jc .exit_fail                         ; error-checking (the cf flag will be set by int 21h if there was an error).
        test dword [pala_data],0ffff0000h       ; make sure the data length isn't >ffffh.
        jnz .exit_fail

        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        ; seek to the end of that file.
        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        mov cx,0
        mov dx,word [pala_data]
        mov ax,4201h                            ; set to move file position, offset from current position.
        int 21h                                 ; move file position.
        jc .exit_fail                         ; error-checking (the cf flag will be set by int 21h if there was an error).

        sub si,1
        jnz .seek_to_kierros

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; save the file position where the palat data starts.
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    mov word[fs:file_pala_data_start],ax
    mov word[fs:file_pala_data_start+2],dx

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; read in the palat file's data.
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    .read:
    ; get the length of the palat file.
    mov dx,pala_data                        ; we use the palat data buffer as temporary storage here.
    mov ah,3fh
    mov cx,4                                ; 4 bytes == long int.
    int 21h                                 ; read in the length of the palat data.
    jc .exit_fail                           ; error-checking (the cf flag will be set by int 21h if there was an error).
    test dword [pala_data],0ffff0000h       ; make sure the data length isn't >ffffh.
    jnz .exit_fail
    ; read in the palat data.
    mov dx,pala_data
    mov ah,3fh
    mov cx,PALA_BUFFER_SIZE                 ; how many bytes to read.
    int 21h
    jc .exit_fail                           ; error-checking (the cf flag will be set by int 21h if there was an error).
    cmp ax,PALA_BUFFER_SIZE                 ; make sure we read just the right number of bytes.
    jne .exit_fail

    jmp .exit_success

    .exit_fail:
    mov al,0
    jmp .exit

    .exit_success:
    mov al,1
    jmp .exit

    .exit:
    pop ds
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Saves 65024 bytes of palat data to the project's .dta file.
;;;
;;; EXPECTS:
;;;     - fn_project_file to give a zero-terminated file name to load from.
;;;     - pala_data to be a buffer we can read PALA_BUFFER_SIZE bytes into.
;;;     - gs to point to the segment holding the pala_data buffer.
;;;     - fs to be a copy of ds, the general data segment.
;;; DESTROYS:
;;;     (- unknown)
;;; RETURNS:
;;;     (- unknown)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Save_Palat_File:
    push ds                                 ; prepare to temporarily switch segments.

    mov bx,[fh_project_file]                ; get the project's file handle. we assume the handle is already open.

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; switch to the segment that holds the palat data buffer we want to read into.
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    mov ax,gs
    mov ds,ax

int 3
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; write the palat data into the project's .dta file.
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; seek to the start of the data.
    mov eax,[fs:file_pala_data_start]       ; get the byte offset in the .dta file where the palat data begins.
    add eax,4                               ; skip the long int describing the following data's length.
    mov dx,ax                               ; dx = the least significant bit of the offset.
    shr eax,16                              ; move the most significant byte to ax.
    mov cx,ax                               ; cx = the most significant bit of the offset.
    mov ax,4200h                            ; set to move file position, offset from beginning.
    int 21h                                 ; seek.
    jc .exit_fail                           ; error-checking (the cf flag will be set by int 21h if there was an error).
    ; write the data.
    mov cx,PALA_BUFFER_SIZE                 ; set to write the entire palat buffer.
    mov dx,pala_data
    mov ah,40h
    int 21h                                 ; write
    jc .exit_fail                           ; error-checking (the cf flag will be set by int 21h if there was an error).

    jmp .exit_success

    .exit_fail:
    mov al,0
    jmp .exit

    .exit_success:
    mov al,1
    jmp .exit

    .exit:
    pop ds
    ret
