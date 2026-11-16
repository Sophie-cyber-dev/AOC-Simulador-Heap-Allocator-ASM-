; ==============================================================================
; Simulador Visual de Heap Allocator (First-Fit + Coalescência) para TASM (16-bit)
; Versão Corrigida e Otimizada para Apresentação Acadêmica
; ==============================================================================

.MODEL SMALL
.STACK 200h

.DATA
    HEAP_SIZE       EQU 256       ; Tamanho total do heap simulado (bytes)
    HEADER_SIZE     EQU 3         ; 2 bytes (tamanho) + 1 byte (status: 1=Livre, 0=Ocupado)
    
    heap            db HEAP_SIZE dup(0)

    msg_init        db '=== INICIANDO SIMULADOR VISUAL DE HEAP (256 BYTES) ===$', 13, 10
    msg_m_acao      db 13, 10, '[ACAO] Solicitada alocacao de bytes.$', 13, 10
    msg_f_acao      db 13, 10, '[ACAO] Solicitada liberacao de bloco (Free).$', 13, 10
    msg_map_titulo  db '--- MAPA DO HEAP NA MEMORIA ---$', 13, 10
    msg_bloco_ini   db '[ Tamanho: $'
    msg_bloc_livre  db ' | STATUS: LIVRE ] -> $'
    msg_bloc_ocupa  db ' | STATUS: OCUPADO ] -> $'
    msg_FIM         db 'FIM DO HEAP$', 13, 10, '$'
    msg_err         db '[ERRO] Sem espaco suficiente no Heap.$', 13, 10

.CODE
main PROC
    mov ax, @data
    mov ds, ax
    mov es, ax

    ; 1. Mensagem inicial
    lea dx, msg_init
    call print_str

    ; 2. Inicializa o Heap
    call init_heap
    call print_heap_map     ; Mostra o heap totalmente livre

    ; 3. Alocação 1: malloc(40)
    lea dx, msg_m_acao
    call print_str
    mov ax, 40
    call my_malloc
    push di                 ; Salva ponteiro p1 na pilha
    call print_heap_map     ; Mostra o heap com o primeiro bloco ocupado

    ; 4. Alocação 2: malloc(60)
    lea dx, msg_m_acao
    call print_str
    mov ax, 60
    call my_malloc
    push di                 ; Salva ponteiro p2 na pilha
    call print_heap_map     ; Mostra o heap com dois blocos ocupados

    ; 5. Liberação (Free) do primeiro bloco (p1) para gerar fragmentação controlada
    lea dx, msg_f_acao
    call print_str
    pop ax                  ; Desempilha p2 temporariamente
    pop di                  ; Restaura p1 em DI
    call my_free            ; Libera p1 e dispara coalescência
    call print_heap_map     ; Mostra o heap reorganizado

    ; Encerra o programa adequadamente
    mov ah, 4Ch
    int 21h
main ENDP

; ------------------------------------------------------------------------------
; void init_heap()
; ------------------------------------------------------------------------------
init_heap PROC
    lea si, heap
    mov ax, HEAP_SIZE
    sub ax, HEADER_SIZE
    mov word ptr [si], ax       
    mov byte ptr [si + 2], 1    ; 1 = Livre
    ret
init_heap ENDP

; ------------------------------------------------------------------------------
; void* my_malloc(word size) -> Retorna ponteiro de dados em DI (ou 0 se erro)
; ------------------------------------------------------------------------------
my_malloc PROC
    push bx
    push cx
    push si
    push dx

    mov cx, ax                  ; CX = tamanho desejado pelo usuário
    lea si, heap                ; SI = início do heap
    mov bx, offset heap         
    add bx, HEAP_SIZE           ; BX = limite superior do heap

.search_loop:
    cmp si, bx
    jge .out_of_memory          ; Se SI >= limite, heap esgotado

    ; Verifica se o bloco está livre (Status == 1)
    mov al, byte ptr [si + 2]
    cmp al, 1
    jne .next_block

    ; Verifica se o bloco tem tamanho suficiente
    mov ax, word ptr [si]
    cmp ax, cx
    jl .next_block

    ; --- ENCONTROU BLOCO (FIRST-FIT) ---
    push ax                     ; Salva o tamanho atual do bloco livre
    sub ax, cx                  ; AX = sobra bruta (tamanho_atual - solicitado)
    
    cmp ax, HEADER_SIZE
    jle .allocate_exact         ; Se a sobra for menor que o cabeçalho, não compensa dividir

    ; --- SPLITTING (DIVISÃO DE BLOCOS) ---
    ; 1. Salva o tamanho original do bloco atual em DX
    mov dx, word ptr [si]

    ; 2. Ajusta o tamanho do bloco atual para o tamanho requisitado (CX)
    mov word ptr [si], cx

    ; 3. Calcula o endereço onde começa o novo bloco dividido:
    ;    Endereço do novo bloco = SI + HEADER_SIZE + CX
    push si
    add si, HEADER_SIZE
    add si, cx
    mov di, si                  ; DI guarda o endereço do novo bloco livre
    pop si

    ; 4. Calcula o tamanho do novo bloco livre:
    ;    Novo_Tamanho = Tamanho_Antigo - Tamanho_Solicitado - HEADER_SIZE
    pop ax                      ; Recupera tamanho original guardado na pilha
    sub ax, cx                  ; Subtrai o tamanho alocado
    sub ax, HEADER_SIZE         ; Desconta o cabeçalho do novo bloco

    ; 5. Configura o novo bloco dividido
    push si                     ; Protege SI atual
    mov si, di                  ; SI aponta para o novo bloco
    mov word ptr [si], ax       ; Grava o novo tamanho
    mov byte ptr [si + 2], 1    ; Marca o novo bloco como LIVRE (1)
    pop si                      ; Restaura SI

    jmp .allocate_finish

.allocate_exact:
    pop ax                      ; Limpa o valor guardado na pilha

.allocate_finish:
    ; Marca o bloco escolhido como OCUPADO (Status = 0)
    mov byte ptr [si + 2], 0    

    ; Retorna o ponteiro de dados exato em DI (SI + HEADER_SIZE)
    mov di, si
    add di, HEADER_SIZE
    jmp .done

.next_block:
    ; Avança para o próximo bloco físico: SI + HEADER_SIZE + tamanho_do_bloco
    mov ax, word ptr [si]
    add si, HEADER_SIZE
    add si, ax
    jmp .search_loop

.out_of_memory:
    lea dx, msg_err
    call print_str
    xor di, di                  ; Retorna NULL (DI = 0)

.done:
    pop dx
    pop si
    pop cx
    pop bx
    ret
my_malloc ENDP

; ------------------------------------------------------------------------------
; void my_free(word ptr) - Recebe o ponteiro de dados em DI
; ------------------------------------------------------------------------------
my_free PROC
    push si
    
    cmp di, 0
    je .free_exit

    ; Recua 3 bytes para encontrar o cabeçalho do bloco
    mov si, di
    sub si, HEADER_SIZE

    ; Marca o bloco como LIVRE (Status = 1)
    mov byte ptr [si + 2], 1

    ; Executa a coalescência para fundir vizinhos livres imediatamente
    call coalesce

.free_exit:
    pop si
    ret
my_free ENDP

; ------------------------------------------------------------------------------
; void coalesce() - Funde blocos livres consecutivos
; ------------------------------------------------------------------------------
coalesce PROC
    push si
    push bx
    push cx
    push dx

    lea si, heap
    mov bx, offset heap
    add bx, HEAP_SIZE

.coalesce_loop:
    ; Calcula o endereço do próximo bloco físico
    mov ax, word ptr [si]
    push si
    add si, HEADER_SIZE
    add si, ax
    mov dx, si                  ; DX = endereço do próximo bloco
    pop si                      

    cmp dx, bx                  ; Se ultrapassou o limite do heap, encerra
    jge .coalesce_done

    ; Verifica se o bloco atual está livre
    mov al, byte ptr [si + 2]
    cmp al, 1
    jne .coalesce_next

    ; Verifica se o próximo bloco também está livre
    push si
    mov si, dx                  
    mov ah, byte ptr [si + 2]
    pop si
    cmp ah, 1
    jne .coalesce_next

    ; --- FUSÃO DOS BLOCOS (COALESCENCE) ---
    ; Tamanho_Atual = Tam_Atual + Tam_Proximo + HEADER_SIZE
    mov ax, word ptr [si]
    push si
    mov si, dx
    mov cx, word ptr [si]       ; Tamanho do próximo bloco
    pop si
    
    add ax, cx
    add ax, HEADER_SIZE
    mov word ptr [si], ax       ; Atualiza o tamanho fundido no bloco atual
    
    ; Reinicia a varredura do mesmo SI para verificar fusões em cadeia
    jmp .coalesce_loop

.coalesce_next:
    mov ax, word ptr [si]
    add si, HEADER_SIZE
    add si, ax
    jmp .coalesce_loop

.coalesce_done:
    pop dx
    pop cx
    pop bx
    pop si
    ret
coalesce ENDP

; ------------------------------------------------------------------------------
; void print_heap_map() - Imprime graficamente os blocos do heap na tela
; ------------------------------------------------------------------------------
print_heap_map PROC
    push ax
    push bx
    push cx
    push si
    push dx

    lea dx, msg_map_titulo
    call print_str

    lea si, heap
    mov bx, offset heap
    add bx, HEAP_SIZE

.map_loop:
    cmp si, bx
    jge .map_end

    ; Imprime prefixo do bloco
    lea dx, msg_bloco_ini
    call print_str

    ; Imprime o tamanho do bloco formatado em decimal
    mov ax, word ptr [si]
    call print_number

    ; Verifica o status (Livre ou Ocupado)
    mov al, byte ptr [si + 2]
    cmp al, 1
    je .print_livre

    lea dx, msg_bloc_ocupa
    call print_str
    jmp .map_advance

.print_livre:
    lea dx, msg_bloc_livre
    call print_str

.map_advance:
    mov ax, word ptr [si]
    add si, HEADER_SIZE
    add si, ax
    jmp .map_loop

.map_end:
    lea dx, msg_FIM
    call print_str

    pop dx
    pop si
    pop cx
    pop bx
    pop ax
    ret
print_heap_map ENDP

; ------------------------------------------------------------------------------
; Função Auxiliar: Imprime número decimal contido em AX na tela do DOS
; ------------------------------------------------------------------------------
print_number PROC
    push ax
    push bx
    push cx
    push dx

    mov cx, 0
    mov bx, 10

.div_loop:
    xor dx, dx
    div bx
    push dx
    inc cx
    cmp ax, 0
    jne .div_loop

.print_loop:
    pop dx
    add dl, '0'
    mov ah, 02h
    int 21h
    loop .print_loop

    pop dx
    pop cx
    pop bx
    pop ax
    ret
print_number ENDP

; ------------------------------------------------------------------------------
; Função Auxiliar: Imprime string terminada em '$'
; ------------------------------------------------------------------------------
print_str PROC
    push ax
    mov ah, 09h
    int 21h
    pop ax
    ret
print_str ENDP

END main