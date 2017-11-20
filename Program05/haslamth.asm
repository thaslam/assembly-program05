TITLE RANDOM NUMBERS     (haslamth.asm)            
;EC: Program foating average.

; Author: Tom Haslam
; CS271 / Program #4                 Date: 11/19/2017
; Description: Program generates random number within a range, sorts, and displays median

INCLUDE Irvine32.inc

; constant definitions
   max_count            EQU         <200>
   min_count            EQU         <10>
.data
    program_title       BYTE        "Sorting Random Numbers     Programmed by Tom Haslam", 10, 0                ; store program title to output
    instructions        BYTE        "This program generates random numbers in the range [100 .. 999],", 10, \
                                    "displays the original list, sorts the list, and calculates the", 10, \
                                    "median value. Finally, it displays the list sorted in descending ", \
                                    "order.", 10, 10, 0                                                         ; store instructions for the program
    terminate           BYTE        "Good Bye!, press any key to exit.", 0                                      ; store exit message
    invalid_input       BYTE        "Out of range.  Try again.", 0                                              ; store error for invalid input
    prompt_count        BYTE        "Enter the numbers to generate [10 .. 200]: ", 0                            ; store input prompt text
    median_text         BYTE        "The median is ", 0                                                         ; store median output suffix
    spaces              BYTE        "     ", 0                                                                  ; store padding betweeen numbers
    count               DWORD       0
    random_numbers      DWORD       190 DUP(?)                                                                  ; store array to hold random numbers
.code
main PROC
call    Randomize                               ; init random number generator

; show program title in intro instructions
push    OFFSET program_title
push    OFFSET instructions
call    introduction

; collect input from the user
call    getUserData
mov     count, eax

; fill array with random numbers
push    OFFSET random_numbers
push    count
call    fillArray

call    Crlf

; show number of requested composite numbers
push    OFFSET random_numbers
push    count                                     
push    OFFSET spaces
call    displayList

; sort array
push    OFFSET random_numbers
push    count                                     
call    sortArray

call    Crlf

; determine median of sorted array
push    OFFSET random_numbers
push    count
push    OFFSET median_text
call    displayMedian

call    Crlf

; show number of requested composite numbers
push    OFFSET random_numbers
push    count                                     ; pass argument of input count to procedure
push    OFFSET spaces
call    displayList

; exit program but wait for user to press any key
call    farewell
main ENDP

displayList PROC
    push    ebp
    mov     ebp, esp
    mov     esi, [esp+16]                           ; offset of array pointer
    mov     ecx, [esp+12]                           ; array count
    mov     edi, [esp+8]                            ; padding between numbers
    sub     esp, 8                                  ; create locals
    mov     DWORD PTR [ebp - 4], 10                 ; total count per line
    mov     DWORD PTR [ebp - 8], 0                  ; line count
Print:
    mov     eax, [esi]
    call    WriteDec
    mov     edx, edi
    call    WriteString

    add     esi, 4
    inc     DWORD PTR [ebp - 8]
    
; check how many numbers we have written per line, if 10 start new line
    mov     edx, 0
    mov     eax, DWORD PTR [ebp - 8]
    mov     ebx, DWORD PTR [ebp - 4]
    div     ebx
    cmp     edx, 0
    je      LineBreak
    jmp     Continue

LineBreak:
    call    Crlf
    mov     DWORD PTR [ebp - 8], 0

 Continue:
    loop    Print
    mov     esp, ebp                            ; remove locals from stack
    pop     ebp
    ret     12
displayList ENDP

introduction PROC
    push    ebp
    mov     ebp, esp

; output title of the program
    mov     edx, [esp+12]
    call    WriteString
    call    Crlf

; output program instructions
    mov     edx, [esp+8] 
    call    WriteString

    pop     ebp
    ret     8
introduction ENDP
    
farewell PROC
    call    CrLf
    call    CrLf
    mov     edx, OFFSET terminate
    call    WriteString
    call	ReadChar
	exit	; exit to operating system
    ret
farewell ENDP

; procedure gets user input
getUserData PROC
PromptNumberInput:
    mov     edx, OFFSET prompt_count
    call    WriteString
    call    ReadInt
    push    eax
    call    validate
    cmp     eax, 0                                  ; check valid return flag, if 1 then invalid
    jle     PromptNumberInput
    ret

    validate PROC
        push    ebp
        mov     ebp, esp
        mov     eax, [esp+8]
        cmp     eax, max_count
        jg      ShowInvalidInputErrorMessage
        cmp     eax, min_count
        jl      ShowInvalidInputErrorMessage
        mov     eax, [esp+8]                        ; set eax to original number
        jmp     ExitProc                            ; jump to exit procedure
    ShowInvalidInputErrorMessage:
        mov     edx, OFFSET invalid_input
        call    WriteString
        call    Crlf
        mov     eax, 0                              ; set eax to zero to indicate invalid number    
    ExitProc:
        pop     ebp
        ret     4                                   ; cleanup the stack
    validate ENDP
getUserData ENDP

; procedure expects parameters array offset and count
sortArray PROC
    push    ebp
    mov     ebp, esp
    mov     esi, [esp+12]                           ; offset of array pointer
    mov     ecx, [esp+8]                            ; array count

Next:    
    mov     ebx, ecx                                ; store ecx in ebx because inner loop will use it
    mov     edi, esi                                ; set start offset of inner loop to current out loop offset
    mov     edx, edi                                ; set edx value as largest index
    
    InnerNext:
        mov     eax, [edi]
        cmp     eax, [edx]
        jg      SetLargest
        jmp     Continue
        
        SetLargest:
            mov     edx, edi
           ; mov     
        Continue:
            add     edi, 4
            loop    InnerNext

    mov     ecx, ebx                                ; restore ecx from ebx, inner loop finished

; swap the largest value with the current
    mov     eax, [edx]
    mov     ebx, [esi]
    mov     [edx], ebx
    mov     [esi], eax

    add     esi, 4
    loop    Next
    
    pop     ebp
    ret     8
sortArray ENDP

displayMedian PROC
    push    ebp
    mov     ebp, esp
    mov     esi, [esp+16]                           ; offset of array pointer

    mov     ecx, 2                                  ; prepare to divide by 2
    mov     edx, 0
    mov     eax, [esp+12]                           ; array count
    div     ecx

    cmp     edx, 0
    jne     SetMedianToMiddle                       ; if if have an odd number just use the middle number

; calculate average of two middle numbers if even count of numbers
    mov     ebx, 4
    mul     ebx
    add     esi, eax
    mov     eax, [esi]
    add     esi, 4
    add     eax, [esi]

    mov     ecx, 2                            
    mov     edx, 0
    div     ecx
    jmp     Return

SetMedianToMiddle:
    mov     ebx, 4
    mul     ebx
    add     esi, eax
    mov     eax, [esi]

Return:
    mov     edx, [esp+8]                            ; write label for median output value
    call    WriteString
    call    WriteDec
    call    Crlf
    pop     ebp
    ret     12
displayMedian ENDP

; procedure expects parameters array offset and count
fillArray PROC
    push    ebp
    mov     ebp, esp
    mov     esi, [esp+12]                           ; offset of array pointer
    mov     ecx, [esp+8]                            ; array count
Fill:
    mov     eax, 999                                ; set max range of 999
    sub     eax, 100                                ; set min range of 100
    inc     eax
    call    RandomRange                             ; geneate random number and store in eax register
    add     eax, 100
    mov     [esi], eax
    add     esi, 4
    loop    Fill
    pop     ebp
    ret     8
fillArray ENDP

END main
