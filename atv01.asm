; ----------------------------------------------------------------------------------------
; Writes "Hello, World" to the console using only system calls. Runs on 64-bit Linux only.
; To assemble and run:
;
;     nasm -felf64 atv01.asm && ld -s -o atv01.exe atv01.o && ./atv01.exe
;     A figura anterior mostra os objetos e os morfismos identificados
; ----------------------------------------------------------------------------------------

global    _start

MAX_STRING equ 127  ; tamanho máximo da string de entrada

section   .data
substringStartIndex:  db -1
substringLength:      db -1
stringLength:         dq 0
newLine:              db 10
inputBuffer:          TIMES MAX_STRING db 0
calcBuffer:           TIMES MAX_STRING db '*'
substring:            db  "mostra os objetos e os morfismos", 0

section   .bss

%macro regPusha  0
          push      rax
          push      rcx
          push      rdx
          push      rbx
          push      rsp
          push      rbp
          push      rsi
          push      rdi
%endmacro

%macro regPopa  0
          pop       rdi
          pop       rsi
          pop       rbp
          pop       rsp
          pop       rbx
          pop       rdx
          pop       rcx
          pop       rax
%endmacro

section   .text
_exit:
          push      rax
          mov       rax, 60                 ; system call for exit
          xor       rdi, rdi                ; exit code 0
          syscall                           ; invoke operating system to exit
          pop       rax
          ret

_start:   
          regPusha

          mov       rax, inputBuffer
          call      _getInput

          mov       rax, inputBuffer
          call      _stringLength
          call      _substringFind

          call      _substringRemove
          call      _substringInvert
          call      _substringConcat
          call      _substringAltern
          call      _substringNumber

          regPopa
          call      _exit

_getInput:
          regPusha
          mov       rsi, rax
          mov       rax, 0                  ; system call for write
          mov       rdi, 0                  ; file handle 1 is stdout
          mov       rdx, MAX_STRING         ; number of bytes
          syscall                           ; invoke operating system to do the write
          regPopa
          ret

_printNewLine:
          regPusha
          mov       rsi, newLine
          mov       rax, 1
          mov       rdi, 1
          mov       rdx, 1
          syscall
          regPopa
          ret

_print:
          regPusha

          mov       rdi, rax
          mov       rsi, rax

          mov       rax, 0
          mov       rcx, MAX_STRING         ; max lenght of string
          cld
          repne     scasb                   ; find AL (0), starting at [ES:EDI]
          
          add       rcx, 2
          sub       rcx, MAX_STRING
          neg       rcx
          mov       rdx, rcx

          mov       rax, 1                  ; system call for write
          mov       rdi, 1                  ; file handle 1 is stdout
          syscall                           ; invoke operating system to do the write
          regPopa
          ret

_stringLength:
          regPusha

          mov       rdi, rax

          mov       rax, 0
          mov       rcx, MAX_STRING         ; max lenght of string
          cld
          repne     scasb                   ; find AL (0), starting at [ES:EDI]

          add       rcx, 2
          sub       rcx, MAX_STRING
          neg       rcx

          mov       [stringLength], rcx

          regPopa
          ret

_stringCopy:
          regPusha

          cld
          rep       movsb                   ; Move (E)CX bytes from DS:[(E)SI] to ES:[(E)DI]
          
          regPopa
          ret

_substringFind:
          regPusha

          xor     rax, rax
          xor     rbx, rbx
          xor     rcx, rcx
          xor     rdx, rdx

          mov     cl, 0
          mov     dl, -1
          jmp     __search

  __next:
          inc     cl
          mov     dl, -1

  __search:
          inc     dl
          
          mov     al, [inputBuffer + rcx + rdx]
          mov     bl, [substring   + rdx]

          cmp     bl, 0
          je      __found

          cmp     al, 0
          je      __nFound

          cmp     bl, al
          je      __search
          jmp     __next

  __found:
          dec     dl
          cmp     dl, -1
          je      __nFound
          mov     [substringStartIndex], cl
          mov     [substringLength],     dl
          jmp     __endSearch

  __nFound:
          mov     dl, -1
          mov     [substringStartIndex], dl
          mov     [substringLength],     dl

  __endSearch:
          regPopa
          ret


_substringRemove:
          regPusha
          
          xor       rcx, rcx
          mov       rsi, inputBuffer
          mov       rdi, calcBuffer
          mov       cl, [substringStartIndex]
          call      _stringCopy

          xor       rcx, rcx
          add       rcx, inputBuffer
          add       cl, [substringStartIndex]
          add       cl, [substringLength]
          inc       cl
          mov       rsi, rcx
          
          xor       rcx, rcx
          add       rcx, calcBuffer
          add       cl, [substringStartIndex]
          mov       rdi, rcx
          
          xor       rcx, rcx
          add       cl, [stringLength]
          sub       cl, [substringStartIndex]
          sub       cl, [substringLength]
          call      _stringCopy

          xor       rcx, rcx
          add       cl, [stringLength]
          sub       cl, [substringLength]
          mov       al, 0x0
          mov       [calcBuffer + rcx], al
          xor       rcx, rcx

          mov       rax, calcBuffer
          call      _print
          call      _printNewLine

          regPopa
          ret


_substringInvert:
          regPusha
          
          xor       rcx, rcx
          mov       rsi, inputBuffer
          mov       rdi, calcBuffer
          mov       cl, [stringLength]
          call      _stringCopy

          xor       rcx, rcx
          add       cl, [stringLength]
          inc       cl
          mov       al, 0x0
          mov       [calcBuffer + rcx], al
          xor       rcx, rcx

          xor       rax, rax
          xor       rbx, rbx
          xor       rcx, rcx

          add       bl, [substringStartIndex]
          add       cl, [substringStartIndex]
          add       cl, [substringLength]

__invLoop:

          mov       al, [calcBuffer + rbx]
          mov       ah, [calcBuffer + rcx]

          mov       [calcBuffer + rbx], ah
          mov       [calcBuffer + rcx], al

          inc       bl
          dec       cl
          cmp       bl, cl
          jle       __invLoop

          mov       rax, calcBuffer
          call      _print
          call      _printNewLine

          regPopa
          ret

_substringConcat:
          regPusha
          
          xor       rcx, rcx
          mov       rsi, inputBuffer
          mov       rdi, calcBuffer
          mov       cl, [stringLength]
          inc       cl
          call      _stringCopy

          xor       rcx, rcx
          add       cl, [substringStartIndex]
          mov       rsi, inputBuffer
          add       rsi, rcx
          xor       rcx, rcx
          add       cl, [stringLength]
          mov       rdi, calcBuffer
          add       rdi, rcx
          xor       rcx, rcx
          mov       cl, [substringLength]
          inc       cl
          call      _stringCopy

          xor       rcx, rcx
          add       cl, [stringLength]
          add       cl, [substringLength]
          add       cl, 2
          mov       al, 0x0
          mov       [calcBuffer + rcx], al
          xor       rcx, rcx

          mov       rax, calcBuffer
          call      _print
          call      _printNewLine

          regPopa
          ret

_substringAltern:
          regPusha
          
          xor       rcx, rcx
          mov       rsi, inputBuffer
          mov       rdi, calcBuffer
          mov       cl, [stringLength]
          call      _stringCopy

          xor       rcx, rcx
          add       cl, [stringLength]
          inc       cl
          mov       al, 0x0
          mov       [calcBuffer + rcx], al
          xor       rcx, rcx

          xor       rax, rax
          xor       rbx, rbx
          xor       rcx, rcx

          add       bl, [substringStartIndex]
          add       cl, [substringStartIndex]
          add       cl, [substringLength]

__altLoop:
          mov       al, [calcBuffer + rbx]

          cmp       al, 0x20
          je        __altNext

          xor       al, 0x20
          mov       [calcBuffer + rbx], al

__altNext:
          add       bl, 2
          cmp       bl, cl
          jle       __altLoop

          mov       rax, calcBuffer
          call      _print
          call      _printNewLine

          regPopa
          ret



_substringNumber:
          regPusha
          
          xor       rcx, rcx
          mov       rsi, inputBuffer
          mov       rdi, calcBuffer
          mov       cl, [substringStartIndex]
          inc       cl
          call      _stringCopy

          xor       rcx, rcx
          add       cl, [substringStartIndex]
          add       cl, [substringLength]
          inc       cl
          mov       rsi, inputBuffer
          add       rsi, rcx
          xor       rcx, rcx
          add       cl, [substringStartIndex]
          add       cl, [substringLength]
          add       cl, [substringLength]
          add       cl, 2
          mov       rdi, calcBuffer
          add       rdi, rcx
          xor       rcx, rcx
          add       cl, [stringLength]
          sub       cl, [substringStartIndex]
          sub       cl, [substringLength]
          inc       cl
          call      _stringCopy

          xor       rcx, rcx
          add       cl, [stringLength]
          add       cl, [substringLength]
          add       cl, 2
          mov       al, 0x0
          mov       [calcBuffer + rcx], al
          xor       rcx, rcx

          xor       rax, rax
          xor       rbx, rbx
          xor       rcx, rcx
          xor       rdx, rdx

          add       bl, [substringStartIndex]
          add       cl, [substringStartIndex]
          add       cl, [substringLength]
          mov       dl, bl

__numLoop:
          mov       al, [inputBuffer + rbx]

          and       al, ~0x20

          cmp       al, 0x00
          je        __numCalc

          sub       al, 64

__numCalc:

          push      rbx
          mov       ah, 0
          mov       bl, 10
          div       bl
          add       ah, '0'
          add       al, '0'
          mov       [calcBuffer + rdx + 0], al 
          mov       [calcBuffer + rdx + 1], ah 
          pop       rbx

          add       bl, 1
          add       dl, 2
          cmp       bl, cl
          jle       __numLoop

          mov       rax, calcBuffer
          call      _print
          call      _printNewLine

          regPopa
          ret