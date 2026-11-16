# AOC-Simulador-Heap-Allocator-ASM-
Trabalho da matéria de arquitetura de computadores do curso de sistemas de informação

# Simulador Visual de Heap Allocator em Assembly (16-bit DOS)

Projeto desenvolvido para a disciplina de **Arquitetura de Computadores** do curso de **Sistemas de Informação** da **Universidade Federal de Alagoas (UFAL)** — *Campus Arapiraca – Unidade Educacional Penedo*.

## 📋 Sobre o Projeto

Este repositório contém a implementação de um gerenciador de memória dinâmica (*Heap Allocator*) em baixo nível utilizando **Assembly x86 (16-bit)** para ambiente DOS (TASM/DOSBox). O objetivo principal é demonstrar na prática como sistemas operacionais e bibliotecas de tempo de execução gerenciam blocos de memória, lidam com a fragmentação externa e reaproveitam espaços liberados.

O simulador conta com um **visualizador ASCII em tempo real** que imprime no terminal o mapeamento completo da memória a cada operação de alocação (`malloc`) ou liberação (`free`).

### ⚙️ Arquitetura e Funcionalidades

* **Buffer Estático:** Heap simulado de **256 bytes** alocado diretamente na seção `.DATA`.
* **Estrutura de Metadados (Header):** Cada bloco possui um cabeçalho de **3 bytes**:
  * `2 bytes` (Word): Tamanho da área útil de dados do bloco.
  * `1 byte` (Byte): Status do bloco (`1` = Livre, `0` = Ocupado).
* **Algoritmo First-Fit (`my_malloc`):** Percorre a lista implícita de blocos a partir do início do heap e aloca o primeiro bloco livre que comporte o tamanho solicitado.
* **Divisão de Blocos (*Splitting*):** Quando o bloco livre encontrado é maior que o necessário (com sobra superior ao tamanho do cabeçalho), ele é fatiado em um bloco ocupado e um novo bloco livre remanescente.
* **Fusão de Blocos (*Coalescing*):** Ao liberar um bloco (`my_free`), o algoritmo varre o heap e funde blocos livres fisicamente adjacentes, mitigando a fragmentação externa.

---

## 🚀 Como Executar

Para compilar e executar o simulador, você precisará do **Turbo Assembler (TASM)**, **Turbo Linker (TLINK)** e de um emulador DOS (como **DOSBox**, **DOSBox-X** ou **js-dos**).

### Passo a passo no terminal DOS:

1. Compile o código-fonte para gerar o arquivo objeto (`.OBJ`):
   ```batch
   main.asm

2. Realize a linkedição para gerar o executável (.EXE):
tlink heap_visual.obj

3. Execute o programa:
main.exe

🖥️ Exemplo de Saída no Terminal
Durante a execução, o simulador exibe a transição dos blocos na memória passo a passo:

Plaintext
=== INICIANDO SIMULADOR VISUAL DE HEAP (256 BYTES) ===
--- MAPA DO HEAP NA MEMORIA ---
[ Tamanho: 253 | STATUS: LIVRE ] -> FIM DO HEAP

[ACAO] Solicitada alocacao de bytes.
--- MAPA DO HEAP NA MEMORIA ---
[ Tamanho: 40 | STATUS: OCUPADO ] -> [ Tamanho: 210 | STATUS: LIVRE ] -> FIM DO HEAP

[ACAO] Solicitada alocacao de bytes.
--- MAPA DO HEAP NA MEMORIA ---
[ Tamanho: 40 | STATUS: OCUPADO ] -> [ Tamanho: 60 | STATUS: OCUPADO ] -> [ Tamanho: 147 | STATUS: LIVRE ] -> FIM DO HEAP

[ACAO] Solicitada liberacao de bloco (Free).
--- MAPA DO HEAP NA MEMORIA ---
[ Tamanho: 40 | STATUS: LIVRE ] -> [ Tamanho: 60 | STATUS: OCUPADO ] -> [ Tamanho: 147 | STATUS: LIVRE ] -> FIM DO HEAP

👥 Equipe

- Sophia Maria Vieira Galvão

- Luiz Eduardo Cok Santos de Melo

- Jonh Farley Santos Silva

📚 Referências Bibliográficas

PATTERSON, David A.; HENNESSY, John L. Organização e Projeto de Computadores: A Interface Hardware/Software.

STALLINGS, William. Arquitetura e Organização de Computadores.
