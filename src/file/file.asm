;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Handles loading from and saving to files on disk.
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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
