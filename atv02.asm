; ----------------------------------------------------------------------------------------
; Writes "Hello, World" to the console using only system calls. Runs on 64-bit Linux only.
; To assemble and run:
;
;     nasm -felf64 atv02.asm && ld -s -o atv02.exe atv02.o && ./atv02.exe
; ----------------------------------------------------------------------------------------

global    _start

MAX_STRING          equ 127  ; tamanho máximo da string
DISCS               equ   4  ; quantidade de discos
INDEX_DISC          equ  13  ; índice na string da mensagem
INDEX_FROM          equ  18  ; índice na string da mensagem
INDEX_TO            equ  25  ; índice na string da mensagem
INDEX_A             equ   1  ; índice na string da mensagem
INDEX_B             equ  11  ; índice na string da mensagem
INDEX_C             equ  21  ; índice na string da mensagem

section   .data
newLine:            db  10, 0
towers:             db  4, 3, 2, 1, 0, 0, 0, 0, 0, 0, 0, 0
commands:           db  0, 0, 0
msgStart:           db  "[", 0
msgEnd:             db  "]", 0
msgMiddle:          db  "] [", 0
msgSpace:           db  " ", 0
msgBckSpc:          db  8, 0
msgInt:             db  0
message:            db  "Mova o disco * de * para *", 0
initial:            db  "Estado inicial das torres:", 0

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

          mov       rax, initial
          call      _print
          call      _printTowers
          mov       rax, newLine
          call      _print
          call      _print

          mov       rax, 0
          call      _hanoi
          mov       rax, newLine
          call      _print
          
          mov       rax, initial
          call      _print
          call      _printTowers
          mov       rax, newLine
          call      _print
          call      _print

          mov       rax, 1
          call      _hanoi

          regPopa
          call      _exit

_hanoi:
          regPusha

          mov       rdx, rax
          mov       rcx, 0
          mov       rbx, 1
          shl       rbx, DISCS
          sub       rbx, 1
  __loop:
          add       rcx, 1

          mov       rax, rcx
          call      _from

          mov       rax, rcx
          call      _to

          call      _moveDisc

          mov       rax, message
          call      _print

          call      _printTowers

          mov       rax, newLine
          call      _print

          cmp       rcx, rbx
          jl        __loop
          regPopa
          ret

_from:
          push      rax
          push      rbx

          mov       rbx, rax
          sub       rax, 1
          and       rax, rbx

          xor       rbx, rbx
          mov       bl, 3
          div       bl

          cmp       rdx, 0
          je        __fFirst

          mov       bl, ah
          xor       rax, rax
          mov       al, bl
          add       al, 1
          xor       rbx, rbx
          mov       bl, 3
          div       bl

  __fFirst:

          mov       [commands + 0], ah
          add       ah, 'A'
          mov       [message + INDEX_FROM], ah

          pop       rbx
          pop       rax
          ret

_to:
          push      rax
          push      rbx

          mov       rbx, rax
          sub       rax, 1
          or        rax, rbx
          add       rax, 1

          xor       rbx, rbx
          mov       bl, 3
          div       bl

          cmp       rdx, 0
          je        __tFirst

          mov       bl, ah
          xor       rax, rax
          mov       al, bl
          add       al, 1
          xor       rbx, rbx
          mov       bl, 3
          div       bl

  __tFirst:
          mov       [commands + 1], ah
          add       ah, 'A'
          mov       [message + INDEX_TO], ah

          pop       rbx
          pop       rax
          ret

_moveDisc:
          regPusha

          xor       rax, rax
          mov       al, [commands + 0]
          mov       bl, DISCS
          mul       bl
          mov       bl, al

          xor       rax, rax
          mov       al, bl
          add       rax, 4

  __findSrc:
          sub       rax, 1
          mov       bl, [towers + rax]
          cmp       bl, 0
          je        __findSrc
          mov       [commands + 2], bl
          add       bl, '0'
          mov       [message + INDEX_DISC], bl
          mov       bl, 0
          mov       [towers + rax], bl


          xor       rax, rax
          mov       al, [commands + 1]
          mov       bl, DISCS
          mul       bl
          mov       bl, al

          xor       rax, rax
          mov       al, bl
          sub       rax, 1
  __findDest:
          add       rax, 1
          mov       bl, [towers + rax]
          cmp       bl, 0
          jne       __findDest
          mov       bl, [commands + 2]
          mov       [towers + rax], bl

          regPopa

          ret

_printTowers:
          regPusha

          mov       rax, msgSpace
          call      _print
          mov       rax, msgStart
          call      _print

          
          mov       rcx, -1
  _towersLoop1:
          add       rcx, 1
          mov       rbx, -1
          mov       rdx, DISCS
          sub       rdx, 1
          mov       rax, msgSpace
          call      _print
  _towersLoop2:
          add       rbx, 1
          xor       rax, rax
          mov       al, DISCS
          mul       cl
          xor       ah, ah
          add       al, bl
          mov       al, [towers + rax]
          add       al, '0'
          mov       [msgInt], al
          call      _printInt

          mov       rax, msgSpace
          call      _print

          cmp       rbx, rdx
          jl        _towersLoop2

          mov       rax, msgMiddle
          call      _print

          cmp       rcx, 2
          jl        _towersLoop1

          mov       rax, msgBckSpc
          call      _print
          call      _print
          call      _print

          mov       rax, msgEnd
          call      _print
          mov       rax, msgSpace
          call      _print
          call      _print

          regPopa
          ret

_printInt:
          regPusha
          mov       rsi, msgInt
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
          
          add       rcx, 1
          sub       rcx, MAX_STRING
          neg       rcx
          mov       rdx, rcx

          mov       rax, 1                  ; system call for write
          mov       rdi, 1                  ; file handle 1 is stdout
          syscall                           ; invoke operating system to do the write
          regPopa
          ret
