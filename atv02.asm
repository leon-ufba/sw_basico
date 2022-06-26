; ----------------------------------------------------------------------------------------
; Programa que mostra os passos para solução das Torres de Hanoi. Feito para Linux x64.
; Para compilar e executar:
;     nasm -felf64 atv02.asm && ld -s -o atv02.exe atv02.o && ./atv02.exe
; ----------------------------------------------------------------------------------------

global    _start

MAX_STRING        equ 127  ; tamanho máximo da string
DISCS             equ   4  ; quantidade de discos
INDEX_DISC        equ  13  ; índice na string da mensagem
INDEX_FROM        equ  18  ; índice na string da mensagem
INDEX_TO          equ  25  ; índice na string da mensagem
INDEX_A           equ   1  ; índice na string da mensagem
INDEX_B           equ  11  ; índice na string da mensagem
INDEX_C           equ  21  ; índice na string da mensagem

section   .data
newLine:          db  10, 0                                     ; string para nova linha
towers:           db  4, 3, 2, 1, 0, 0, 0, 0, 0, 0, 0, 0        ; array que armazena as os discos de hanoi
commands:         db  0, 0, 0                                   ; array que indica o próximo passo da solução (from, to, disc)
msgStart:         db  "[", 0                                    ; string para imprimir "["
msgEnd:           db  "]", 0                                    ; string para imprimir "]"
msgMiddle:        db  "] [", 0                                  ; string para imprimir "] ["
msgSpace:         db  " ", 0                                    ; string para imprimir um espaço
msgBckSpc:        db  8, 0                                      ; string para imprimir um backspace
msgInt:           db  0                                         ; byte para imprimir um inteiro
message:          db  "Mova o disco * de * para *", 0           ; string para imprimir o passo
initial:          db  "Estado inicial das torres:", 0           ; string para imprimir o estado inicial

section   .bss

; macro para salvar registradores na pilha
%macro regPusha   0
        push      rax
        push      rcx
        push      rdx
        push      rbx
        push      rsp
        push      rbp
        push      rsi
        push      rdi
%endmacro

; macro para salvar buscar da pilha
%macro regPopa    0
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

; finaliza o programa
_exit:
        push      rax
        mov       rax, 60               ; chamada do sistema para finalizar o programa
        xor       rdi, rdi              ; exit code 0
        syscall                         ; solicita ao sistema operacional para finalizar
        pop       rax
        ret                             ; retorna da chamada

; ponto de entrada do programa
_start:   
        regPusha                        ; salva os registradores

        ; imprime a pensagem inicial
        mov       rax, initial
        call      _print
        call      _printTowers

        ; imprime duas quebras de lina
        mov       rax, newLine
        call      _print
        call      _print

        ; calcula os passos da solução das Torres de Hanoi (A para B)
        mov       rax, 0
        call      _hanoi
        
        ; imprime uma quebra de lina
        mov       rax, newLine
        call      _print
        
        ; imprime a pensagem inicial
        mov       rax, initial
        call      _print
        call      _printTowers
        
        ; imprime duas quebras de lina
        mov       rax, newLine
        call      _print
        call      _print

        ; calcula os passos da solução das Torres de Hanoi (B para C)
        mov       rax, 1
        call      _hanoi

        regPopa                         ; resgata os registradores
        call      _exit                 ; finaliza o programa

; imprime um inteiro n; para (0 <= n <= 9)
_printInt:
        regPusha                        ; salva os registradores
        mov       rsi, msgInt           ; resgata a memória de msgInt
        mov       rdx, 1                ; quantidade de 1 byte
        mov       rax, 1                ; seleciona 1 para escrever
        mov       rdi, 1                ; seleciona 1 para o stdout
        syscall                         ; chamada dos sistema para imprimir na tela
        regPopa                         ; resgata os registradores
        ret                             ; retorna da chamada

; imprime uma string terminada por '\0'
_print:
        regPusha                        ; salva os registradores
        mov       rsi, rax              ; define o endereço de memória da string para imprimir

        mov       rdi, rax              ; move o endereço da string em que ocorrerá a busca
        mov       rax, 0                ; valor para procurar
        mov       rcx, MAX_STRING       ; define o tamanho máximo de impressão da string
        cld                             ; procura no sentido crescente
        repne     scasb                 ; procura '\0' (AL == 0), usando [ES:EDI]
        
        ; calcula a quantidade de bytes a serem impressos
        add       rcx, 1
        sub       rcx, MAX_STRING
        neg       rcx
        mov       rdx, rcx

        mov       rax, 1                ; seleciona 1 para escrever
        mov       rdi, 1                ; seleciona 1 para o stdout
        syscall                         ; chamada dos sistema para imprimir na tela

        regPopa                         ; resgata os registradores
        ret                             ; retorna da chamada

; calcula os passos para solução das Torres de Hanoi
_hanoi:
        regPusha                        ; salva os registradores

        mov       rdx, rax              ; recebe em rax (0 => A para B, 1 => B para C)
        mov       rcx, 0                ; contador inicia em 0
        mov       rbx, 1
        shl       rbx, DISCS            ; define o limite do loop para (1 << DISCS), ou seja, 2^(DISCS)
        sub       rbx, 1
  __loop:
        add       rcx, 1                ; adiciona 1 ao contador

        mov       rax, rcx              ; passa rcx como parâmetro de _from, através de rax
        call      _from

        mov       rax, rcx              ; passa rcx como parâmetro de _to, através de rax
        call      _to

        call      _moveDisc             ; movimenta os discos nas torres

        mov       rax, message          ; imprime o passo da solução
        call      _print

        call      _printTowers          ; imprime o array das torres

        mov       rax, newLine          ; imprime uma nova linha
        call      _print

        cmp       rcx, rbx
        jl        __loop                ; loop se rcx < rbx, ou seja, rcx < 2^(DISCS)
        regPopa                         ; resgata os registradores
        ret                             ; retorna da chamada

; indica de qual torre deve ser retirado o próximo disco
_from:
        push      rax                   ; salva o registrador na pilha
        push      rbx                   ; salva o registrador na pilha

        ; calcula rax = (rax & (rax - 1)) % 3 ;
        mov       rbx, rax
        sub       rax, 1
        and       rax, rbx

        xor       rbx, rbx
        mov       bl, 3
        div       bl                    ; AH armazera o resto da divisão

        cmp       rdx, 0                ; verifica se é (A para B) ou (B para C)
        je        __fFirst

        ; caso seja (B para C) soma 1 às variáveis e calcula o novo resto da divisão por 3
        mov       bl, ah
        xor       rax, rax
        mov       al, bl
        add       al, 1
        xor       rbx, rbx
        mov       bl, 3
        div       bl

  __fFirst:
        ; atualiza na memória o FROM tanto no commands, quanto no message
        mov       [commands + 0], ah
        add       ah, 'A'               ; adiciona 'A' para compatibilizar com o valor ASCII
        mov       [message + INDEX_FROM], ah

        pop       rbx                   ; resgata o registrador da pilha
        pop       rax                   ; resgata o registrador da pilha
        ret                             ; retorna da chamada

; indica para qual torre deve ser colocado o próximo disco
_to:
        push      rax                   ; salva o registrador na pilha
        push      rbx                   ; salva o registrador na pilha

        ; calcula rax = ((rax | (rax - 1)) + 1) % 3;
        mov       rbx, rax
        sub       rax, 1
        or        rax, rbx
        add       rax, 1

        xor       rbx, rbx
        mov       bl, 3
        div       bl                    ; AH armazera o resto da divisão

        cmp       rdx, 0                ; verifica se é (A para B) ou (B para C)
        je        __tFirst

        ; caso seja (B para C) soma 1 às variáveis e calcula o novo resto da divisão por 3
        mov       bl, ah
        xor       rax, rax
        mov       al, bl
        add       al, 1
        xor       rbx, rbx
        mov       bl, 3
        div       bl

  __tFirst:
        ; atualiza na memória o TO tanto no commands, quanto no message
        mov       [commands + 1], ah
        add       ah, 'A'               ; adiciona 'A' para compatibilizar com o valor ASCII
        mov       [message + INDEX_TO], ah

        pop       rbx                   ; resgata o registrador da pilha
        pop       rax                   ; resgata o registrador da pilha
        ret                             ; retorna da chamada

; movimenta os discos no array que representa as torres
_moveDisc:
        regPusha                        ; salva os registradores

        xor       rax, rax              ; rax = 0
        mov       al, [commands + 0]    ; recebe o índice da torre de origem
        mov       bl, DISCS             ; recebe a quantidade de discos
        mul       bl                    ; multiplica os valores para obter o offset no array de torres
        mov       bl, al                ; armazena o resultado em bl

        xor       rax, rax              ; rax = 0
        mov       al, bl                ; armazena o resultado em al
        add       rax, DISCS            ; pesquisa a partir do topo de cada torre

  __findSrc:
        ; pesquisa em cada torre a partir do topo até encontrar valor diferente de 0
        sub       rax, 1                ; subtrai 1 de rax
        mov       bl, [towers + rax]
        cmp       bl, 0
        je        __findSrc

        ; quando encontra, armazena esse valor para indicar qual disco deve ser movido
        mov       [commands + 2], bl
        add       bl, '0'               ; adiciona '0' para compatibilizar com o valor ASCII
        mov       [message + INDEX_DISC], bl

        ; limpa a posição da memória que continha o disco movimentado
        mov       bl, 0
        mov       [towers + rax], bl

        xor       rax, rax              ; rax = 0
        mov       al, [commands + 1]    ; recebe o índice da torre de destino
        mov       bl, DISCS             ; recebe a quantidade de discos
        mul       bl                    ; multiplica os valores para obter o offset no array de torres
        mov       bl, al                ; armazena o resultado em bl

        xor       rax, rax              ; rax = 0
        mov       al, bl                ; armazena o resultado em al
        sub       rax, 1                ; pesquisa a partir da base de cada torre

  __findDest:
        ; pesquisa em cada torre a partir da base até encontrar valor igual a 0
        add       rax, 1                ; adiciona 1 em rax
        mov       bl, [towers + rax]
        cmp       bl, 0
        jne       __findDest
        
        ; quando encontra, armazena o disco movimentado na torre de destino
        mov       bl, [commands + 2]
        mov       [towers + rax], bl

        regPopa                         ; resgata os registradores
        ret                             ; retorna da chamada

; imprime a memória que armazena os discos nas torres
_printTowers:
        regPusha                        ; salva os registradores

        ; imprime um espaço
        mov       rax, msgSpace
        call      _print

        ; imprime um "["
        mov       rax, msgStart
        call      _print

        mov       rcx, -1               ; inicia o contador do loop1 em -1
  _towersLoop1:                         ; loop entre torres
        add       rcx, 1                ; adiciona 1 ao contador do loop1
        mov       rbx, -1               ; inicia o contador do loop2 em -1
        mov       rdx, DISCS            ; limite para o contador loop2
        sub       rdx, 1                ; subtrai 1 do contador loop2
        mov       rax, msgSpace         ; imprime um espaço
        call      _print
  _towersLoop2:                         ; loop entre discos
        add       rbx, 1                ; adiciona 1 ao contador do loop2

        ; calcula o offset da torre
        xor       rax, rax              ; zera o valor de rax
        mov       al, DISCS
        mul       cl

        ; calcula o índice no array
        xor       ah, ah                ; zera o valor de ah
        add       al, bl                ; adiciona o índice do disco ao offset da torre
        mov       al, [towers + rax]    ; resgata o valor da memória das torres
        add       al, '0'               ; adiciona '0' para compatibilizar com o valor ASCII
        mov       [msgInt], al          ; imprime o valor inteiro
        call      _printInt

        ; imprime um espaço
        mov       rax, msgSpace
        call      _print

        ; loop2 enquanto (rbx < rdx), ou seja, rbx < (DISCS - 1)
        cmp       rbx, rdx
        jl        _towersLoop2

        ; imprime "] ["
        mov       rax, msgMiddle
        call      _print

        ; loop1 enquanto (rcx < 2), ou seja, percorre as 3 torres
        cmp       rcx, 2
        jl        _towersLoop1

        ; apaga 3 caracteres impressos a mais ("] [")
        mov       rax, msgBckSpc
        call      _print
        call      _print
        call      _print

        ; imprime um "]"
        mov       rax, msgEnd
        call      _print
        
        ; imprime um espaço
        mov       rax, msgSpace
        call      _print
        call      _print

        regPopa                         ; resgata os registradores
        ret                             ; retorna da chamada
