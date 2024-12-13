[org 0x7c00]

; Variables
row: db 0  ; Current cursor row, starts at 0
line_buffer: times 128 db 0  ; A buffer for the current line

; Print the prompt "tynos>"
mov ah, 0x0E
mov al, 't'
int 0x10
mov al, 'y'
int 0x10
mov al, 'n'
int 0x10
mov al, 'o'
int 0x10
mov al, 's'
int 0x10
mov al, '>'
int 0x10

; bx = number of typed characters
; cx = current cursor column (starting after prompt, which is at column 6)
xor bx, bx
xor cx, cx
add cx, 6  ; After printing "tynos>" cursor is at column 6

; Initialize row to 8
mov byte [row], 8

input_loop:
    ; Wait for keystroke
    mov ah, 0x00
    int 0x16
    ; Now AL = ASCII code, AH = scan code

    ; Check for Enter (0x0D)
    cmp al, 0x0D
    je handle_enter

    ; Check for Backspace (0x08)
    cmp al, 0x08
    je handle_backspace

    ; Check if this is an extended key (AL=0 means extended)
    cmp al, 0x00
    jne check_printable
    ; Extended key pressed. Check AH for scan code:
    cmp ah, 0x4B  ; Left Arrow?
    je move_left
    cmp ah, 0x4D  ; Right Arrow?
    je move_right
    ; If other extended keys, ignore for now
    jmp input_loop

check_printable:
    ; Check if character is printable (>= 0x20)
    cmp al,0x20
    jb not_printable

    ; Printable character: store in line_buffer and print
    ; line_buffer[bx] = al
    mov di, bx       ; index = bx
    mov si, line_buffer
    add si, di
    mov [si], al

    ; Print the character
    mov ah,0x0E
    int 0x10

    ; Increment counts
    inc bx
    inc cx
    jmp input_loop

handle_enter:
    ; Print newline (CR+LF)
    mov ah,0x0E
    mov al,0x0D
    int 0x10
    mov al,0x0A
    int 0x10

    ; Increment row since we moved down a line
    mov al,[row]
    inc al
    mov [row],al

    ; Print the prompt on new line
    mov al, 't'
    int 0x10
    mov al, 'y'
    int 0x10
    mov al, 'n'
    int 0x10
    mov al, 'o'
    int 0x10
    mov al, 's'
    int 0x10
    mov al, '>'
    int 0x10

    ; Reset counts
    xor bx,bx
    xor cx,cx
    add cx,6

    ; Clear line_buffer
    mov di,0
    mov cx,128
.fill_buffer:
    mov si,line_buffer
    add si,di
    mov byte [si],0
    inc di
    loop .fill_buffer

    jmp input_loop

handle_backspace:
    cmp cx,6
    jle input_loop ; Don't erase prompt

    ; Remove the char before cx
    ; index = cx - 6 - 1
    

    jmp input_loop

not_printable:
    ; Ignore non-printable characters
    jmp input_loop

move_left:
    cmp cx,6
    jle input_loop  ; Can't go left past prompt
    dec cx
    ; Set cursor position using current row and cx
    mov ah,0x02
    mov bh,0
    mov dh,[row]    ; use current row
    mov dl,cl        ; DL = current column
    int 0x10
    jmp input_loop

move_right:
    ; Compare cx with 6 + bx, not bx
    mov ax, bx
    add ax, 6
    cmp cx, ax
    jge input_loop  ; Can't move right beyond typed chars (end of line)
    
    inc cx
    mov ah,0x02
    mov bh,0
    mov dh,[row]
    mov dl,cl
    int 0x10
    jmp input_loop


; Hang
jmp $

; Pad the sector to 512 bytes
times 510 - ($ - $$) db 0
dw 0xAA55

