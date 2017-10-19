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
;;;     - pala_data to be a buffer we can read PALA_BUFFER_SIZE bytes into
;;;     - gs to point to the segment holding the pala_data buffer
;;; DESTROYS:
;;;     (- unknown)
;;; RETURNS:
;;;     (- unknown)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Load_Palat_File2:
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
    mov eax,dword[fs:file_pala_data_start]

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
;;; Loads 65024 bytes from the PALAT file into a buffer in memory.
;;;
;;; EXPECTS:
;;;     - palat_file_name to give a zero-terminated file name to load from.
;;;     - pala_data to be a buffer we can read PALA_BUFFER_SIZE bytes into
;;;     - gs to point to the segment holding the pala_data buffer
;;; DESTROYS:
;;;     - ax, bx, cx, dx
;;; RETURNS:
;;;     - al set to 1 if loading succeeded, 0 if failed.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Load_Palat_File:
    push ds

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; open the file for reading.
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    mov dx,palat_file_name
    mov ah,3dh
    mov al,0                                ; set to open for reading.
    int 21h                                 ; obtain file handle (goes into ax).
    jc .open_failed                         ; the carry flag will be set on load failure.

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; read from the file.
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    mov bx,ax                               ; pass the file handle to bx.
    mov ax,gs                               ;
    mov ds,ax                               ;
    mov dx,pala_data                        ; prepare the correct segment and address to read into.
    mov cx,PALA_BUFFER_SIZE                 ; how many bytes to read.
    mov ah,3fh
    int 21h

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; test for read errors.
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    jc .read_failed                         ; the carry flag will be set on read failure.
    cmp ax,PALA_BUFFER_SIZE                 ; ax == number of bytes that were read.
    jne .read_failed                        ; assume failure if we didn't read exactly the number of bytes we wanted.

    mov al,1                                ; otherwise, mark as a successful loading.
    jmp .success

    .open_failed:
    .read_failed:
    mov al,0                                ; mark as a failed loading.

    .success:
    pop ds

    ret
