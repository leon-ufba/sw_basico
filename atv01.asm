; ----------------------------------------------------------------------------------------
; Programa fazer operações com uma string definida. Feito para Linux x64.
; Para compilar e executar:
;     nasm -felf64 atv01.asm && ld -s -o atv01.exe atv01.o && ./atv01.exe
; O programa deve receber uma string como entrada:
;     A figura anterior mostra os objetos e os morfismos identificados
; ----------------------------------------------------------------------------------------

global    _start

MAX_STRING        equ 127  ; tamanho máximo da string

section   .data
substrStartIndex: db -1         ; índice inicial da substring
substrLength:     db -1         ; comprimento da substring
stringLength:     dq 0          ; comprimento da string
newLine:          db  10, 0     ; string para nova linha
inputBuffer:      TIMES MAX_STRING db 0         ; buffer para armazenar a string de entrada
calcBuffer:       TIMES MAX_STRING db '*'       ; buffer para armazenar a string resultante
substr:           db  "mostra os objetos e os morfismos", 0     ; substring a ser encontrada e modificada

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

        mov       rax, inputBuffer      ; move o endereço do buffer de entrada para rax
        call      _getInput             ; recebe a string do usuário

        mov       rax, inputBuffer      ; move o endereço do buffer de entrada para rax
        call      _stringLength         ; calcula o tamanho da string
        call      _substrFind           ; encontra o índice inicial da substring na string

        call      _substrRemove         ; remove a substring da string
        call      _substrInvert         ; inverte a substring na string
        call      _substrConcat         ; concatena a substring ao final da string
        call      _substrAltern         ; alterna a substring entre minúsculas e maiúsculas na string
        call      _substrNumber         ; troca as letras da substring por sua posição no alfabeto

        regPopa                         ; resgata os registradores
        call      _exit                 ; finaliza o programa

; recebe do usuário a string de entrada
_getInput:
        regPusha                        ; salva os registradores
        mov       rsi, rax              ; define o endereço de memória para receber a string
        mov       rax, 0                ; seleciona 0 para ler
        mov       rdi, 0                ; seleciona 0 para o stdin
        mov       rdx, MAX_STRING       ; quantidade de bytes
        syscall                         ; chamada dos sistema para ler do terminal
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

; calcula o tamanho da string terminada por '\0'
_stringLength:
        regPusha                        ; salva os registradores

        mov       rdi, rax              ; move o endereço da string em que ocorrerá a busca
        mov       rax, 0                ; valor para procurar
        mov       rcx, MAX_STRING       ; define o tamanho máximo de impressão da string
        cld                             ; procura no sentido crescente
        repne     scasb                 ; procura '\0' (AL == 0), usando [ES:EDI]

        ; calcula o tamanho da string
        add       rcx, 1
        sub       rcx, MAX_STRING
        neg       rcx
        dec       rcx

        mov       [stringLength], rcx   ; salva o tamanho da string

        regPopa                         ; resgata os registradores
        ret                             ; retorna da chamada

; copia uma string
_stringCopy:
        regPusha                        ; salva os registradores
        cld                             ; sentido crescente
        rep       movsb                 ; Move a quantidade de (E)CX bytes de DS:[(E)SI] para ES:[(E)DI]
        regPopa                         ; resgata os registradores
        ret                             ; retorna da chamada

; encontra a posição da substring na string
_substrFind:
        regPusha                        ; salva os registradores

        xor       rax, rax              ; zera o registrador
        xor       rbx, rbx              ; zera o registrador
        xor       rcx, rcx              ; zera o registrador
        xor       rdx, rdx              ; zera o registrador

        ; busca a substrig dentro da string até que todos os bytes sejam iguais
        mov       cl, 0                 ; inicia o contador em 0
        mov       dl, -1                ; inicia o índice em -1
        jmp       __search              ; pula para _search

  __next:
        inc       cl                    ; incrementa cl
        mov       dl, -1                ; reinicia dl para -1

  __search:
        inc       dl                    ; incrementa dl

        mov       al, [inputBuffer + rdx + rcx]
        mov       bl, [substr + rdx]

        ; verifica se chegou ao final da substring
        cmp       bl, 0
        je        __found

        ; verifica se chegou ao final da string
        cmp       al, 0
        je        __nFound

        ; compara um dos bytes da string com um da substring
        cmp       bl, al
        je        __search
        jmp       __next


  __found:                              ; caso encontre a substring
        cmp       dl, 0
        je        __nFound              ; caso a substring seja vazia
        mov       [substrStartIndex], cl
        mov       [substrLength],     dl
        jmp       __endSearch


  __nFound:                              ; caso não encontre a substring
        mov       dl, -1
        mov       [substrStartIndex], dl
        mov       [substrLength],     dl

  __endSearch:
        regPopa                         ; resgata os registradores
        ret                             ; retorna da chamada


_substrRemove:
        regPusha                        ; salva os registradores

        ; copia a parte da string antes da substring para o calcBuffer
        xor       rcx, rcx
        mov       rsi, inputBuffer
        mov       rdi, calcBuffer
        mov       cl, [substrStartIndex]
        call      _stringCopy

        ; copia a parte da string após a substring para o calcBuffer
        ; calcula a posição de origem no inputBuffer
        xor       rcx, rcx
        mov       rcx, inputBuffer
        add       cl, [substrStartIndex]
        add       cl, [substrLength]
        mov       rsi, rcx
        ; calcula a posição de destino no calcBuffer
        xor       rcx, rcx
        add       rcx, calcBuffer
        add       cl, [substrStartIndex]
        mov       rdi, rcx
        ; calcula a quantidade de bytes a serem copiados e copia
        xor       rcx, rcx
        add       cl, [stringLength]
        sub       cl, [substrStartIndex]
        sub       cl, [substrLength]
        call      _stringCopy

        ; insere '\0' ao final da do resultado
        xor       rcx, rcx
        add       cl, [stringLength]
        sub       cl, [substrLength]
        mov       al, 0x0
        mov       [calcBuffer + rcx], al
        xor       rcx, rcx

        ; imprime o resultado
        mov       rax, calcBuffer
        call      _print
        ; imprime uma nova linha
        mov       rax, newLine
        call      _print

        regPopa                         ; resgata os registradores
        ret                             ; retorna da chamada


_substrInvert:
        regPusha                        ; salva os registradores

        ; copia a string para o calcBuffer
        xor       rcx, rcx
        mov       rsi, inputBuffer
        mov       rdi, calcBuffer
        mov       cl, [stringLength]
        call      _stringCopy

        xor       rax, rax              ; zera o registrador
        xor       rbx, rbx              ; zera o registrador
        xor       rcx, rcx              ; zera o registrador

        add       bl, [substrStartIndex] ; inicio da substring
        add       cl, [substrStartIndex]
        add       cl, [substrLength]
        dec       cl                     ; fim da substring

  __invLoop:
        ; troca os valores a partir das estremidades
        mov       al, [calcBuffer + rbx]
        mov       ah, [calcBuffer + rcx]

        mov       [calcBuffer + rbx], ah
        mov       [calcBuffer + rcx], al

        ; loop até que os índices se encontrem
        inc       bl
        dec       cl
        cmp       bl, cl
        jle       __invLoop

        ; insere '\0' ao final da do resultado
        xor       rcx, rcx
        add       cl, [stringLength]
        mov       al, 0x0
        mov       [calcBuffer + rcx], al
        xor       rcx, rcx

        mov       rax, calcBuffer
        call      _print

        mov       rax, newLine
        call      _print

        regPopa                         ; resgata os registradores
        ret                             ; retorna da chamada

_substrConcat:
        regPusha                        ; salva os registradores

        ; copia a string para o calcBuffer
        xor       rcx, rcx
        mov       rsi, inputBuffer
        mov       rdi, calcBuffer
        mov       cl, [stringLength]
        call      _stringCopy

        ; copia a substring para o final do calcBuffer
        ; calcula a posição de origem no inputBuffer
        xor       rcx, rcx
        add       cl, [substrStartIndex]
        mov       rsi, inputBuffer
        add       rsi, rcx
        ; calcula a posição de destino no calcBuffer
        xor       rcx, rcx
        add       cl, [stringLength]
        mov       rdi, calcBuffer
        add       rdi, rcx
        ; calcula a quantidade de bytes a serem copiados e copia
        xor       rcx, rcx
        mov       cl, [substrLength]
        call      _stringCopy

        ; insere '\0' ao final da do resultado
        xor       rcx, rcx
        add       cl, [stringLength]
        add       cl, [substrLength]
        mov       al, 0x0
        mov       [calcBuffer + rcx], al
        xor       rcx, rcx

        ; imprime o resultado
        mov       rax, calcBuffer
        call      _print
        ; imprime uma nova linha
        mov       rax, newLine
        call      _print

        regPopa                         ; resgata os registradores
        ret                             ; retorna da chamada

_substrAltern:
        regPusha                        ; salva os registradores

        ; copia a string para o calcBuffer
        xor       rcx, rcx
        mov       rsi, inputBuffer
        mov       rdi, calcBuffer
        mov       cl, [stringLength]
        call      _stringCopy

        xor       rax, rax              ; zera o registrador
        xor       rbx, rbx              ; zera o registrador
        xor       rcx, rcx              ; zera o registrador
        xor       rdx, rdx              ; zera o registrador

        add       bl, [substrStartIndex] ; inicio da substring
        add       cl, [substrStartIndex]
        add       cl, [substrLength]
        dec       cl                     ; fim da substring

        mov       dl, 1                 ; booleano para verificar se a letra deve ser alterada

  __altLoop:
        ; recebe a letra
        mov       al, [calcBuffer + rbx]
        ; pula caso seja espaço
        cmp       al, 0x20
        je        __altNext
        ; alterna entre modificar ou deixar minúscula
        cmp       dl, 0
        je        __altChange
        ; converte para maiúscula e salva
        xor       al, 0x20
        mov       [calcBuffer + rbx], al

  __altChange:
        xor       dl, 1                 ; inverte o estado do booleano

  __altNext:
        ; loop até o final da substring no calcBuffer
        add       bl, 1
        cmp       bl, cl
        jle       __altLoop

        ; insere '\0' ao final da do resultado
        xor       rcx, rcx
        add       cl, [stringLength]
        mov       al, 0x0
        mov       [calcBuffer + rcx], al
        xor       rcx, rcx

        ; imprime o resultado
        mov       rax, calcBuffer
        call      _print
        ; imprime uma nova linha
        mov       rax, newLine
        call      _print

        regPopa                         ; resgata os registradores
        ret                             ; retorna da chamada



_substrNumber:
        regPusha                        ; salva os registradores

        ; copia a parte da string antes da substring para o calcBuffer
        xor       rcx, rcx
        mov       rsi, inputBuffer
        mov       rdi, calcBuffer
        mov       cl, [substrStartIndex]
        call      _stringCopy

        ; copia a parte da string após a substring para o calcBuffer
        ; calcula a posição de origem no inputBuffer
        xor       rcx, rcx
        add       cl, [substrStartIndex]
        add       cl, [substrLength]
        mov       rsi, inputBuffer
        add       rsi, rcx
        ; calcula a posição de destino no calcBuffer (cada letra da substring virará dois dígitos)
        xor       rcx, rcx
        mov       rcx, calcBuffer
        add       cl, [substrStartIndex]
        add       cl, [substrLength]
        add       cl, [substrLength]
        mov       rdi, rcx
        ; calcula a quantidade de bytes a serem copiados e copia
        xor       rcx, rcx
        add       cl, [stringLength]
        sub       cl, [substrStartIndex]
        sub       cl, [substrLength]
        call      _stringCopy

        xor       rax, rax              ; zera o registrador
        xor       rbx, rbx              ; zera o registrador
        xor       rcx, rcx              ; zera o registrador
        xor       rdx, rdx              ; zera o registrador

        add       bl, [substrStartIndex] ; inicio da substring
        add       cl, [substrStartIndex]
        add       cl, [substrLength]
        dec       cl                     ; fim da substring
        mov       dl, bl                 ; contador de 2 em 2 caracteres

  __numLoop:
        mov       al, [inputBuffer + rbx]
        and       al, ~0x20              ; transforma em minúscula

        cmp       al, 0x00              ; caracteres de espaço viram 00
        je        __numCalc

        sub       al, 64                ; convert letras ASCII em números a partir do 1

  __numCalc:

        push      rbx                   ; salva o registrador
        xor       ah, ah                ; zera o registrador
        mov       bl, 10
        div       bl                    ; realiza divisão por 10 => AL == dezenas, AH == unidades
        add       al, '0'               ; adiciona '0' para compatibilizar com o valor ASCII
        add       ah, '0'               ; adiciona '0' para compatibilizar com o valor ASCII
        mov       [calcBuffer + rdx + 0], al ; preenche o calcBuffer (dezenas)
        mov       [calcBuffer + rdx + 1], ah ; preenche o calcBuffer (unidades)
        pop       rbx                   ; recupera o registrador

        ; loop até o final da substring no calcBuffer
        add       bl, 1                 ; adiciona 1 ao contador de caracteres
        add       dl, 2                 ; adicoina 2 ao contador de dígitos impressos
        cmp       bl, cl
        jle       __numLoop

        ; insere '\0' ao final da do resultado
        xor       rcx, rcx
        add       cl, [stringLength]
        add       cl, [substrLength]
        mov       al, 0x0
        mov       [calcBuffer + rcx], al
        xor       rcx, rcx

        ; imprime o resultado
        mov       rax, calcBuffer
        call      _print
        ; imprime uma nova linha
        mov       rax, newLine
        call      _print

        regPopa                         ; resgata os registradores
        ret                             ; retorna da chamada
