# Mini-Grep em MIPS (MARS)
# - Lê um TEXTO e um PADRÃO
# - Procura TODAS as ocorrências do padrão no texto (case-insensitive)
# - Imprime a posição de cada ocorrência e o total encontrado

.data
prompt_texto:   .asciiz "Digite o texto: "
prompt_padrao:  .asciiz "\nDigite o padrao: "
msg_resultado:  .asciiz "\nTotal de ocorrencias: "
msg_ocorrencia: .asciiz "\nOcorrencia na posicao: "
quebra_linha:   .asciiz "\n"

texto:   .space 256        # buffer para o texto
padrao:  .space 128        # buffer para o padrao

.text
.globl main

###########################################################
# main
###########################################################
main:
    #######################################################
    # Ler o TEXTO
    #######################################################
    li  $v0, 4              # print_string
    la  $a0, prompt_texto
    syscall

    li  $v0, 8              # read_string
    la  $a0, texto
    li  $a1, 256
    syscall

    #######################################################
    # Ler o PADRÃO
    #######################################################
    li  $v0, 4
    la  $a0, prompt_padrao
    syscall

    li  $v0, 8
    la  $a0, padrao
    li  $a1, 128
    syscall

    #######################################################
    # Calcular comprimento do TEXTO (sem '\n')
    #######################################################
    la  $a0, texto
    jal str_len_no_newline
    move $s0, $v0           # s0 = text_len

    #######################################################
    # Calcular comprimento do PADRAO (sem '\n')
    #######################################################
    la  $a0, padrao
    jal str_len_no_newline
    move $s1, $v0           # s1 = pat_len

    # Se padrao vazio ou maior que o texto, não há ocorrências
    blez $s1, sem_ocorrencias
    blt  $s0, $s1, sem_ocorrencias

    #######################################################
    # Busca de todas as ocorrencias (for i = 0..text_len-pat_len)
    #######################################################
    li  $t0, 0              # i = 0 (índice no texto)
    li  $s2, 0              # s2 = contador de ocorrencias

loop_externo:
    # Se i > text_len - pat_len, termina
    sub $t1, $s0, $s1       # t1 = text_len - pat_len
    bgt $t0, $t1, fim_busca

    li  $t2, 0              # j = 0 (índice no padrao)
    li  $t3, 1              # flag_match = 1 (assume que casa)

loop_interno:
    # Se j >= pat_len, verificamos se manteve "match"
    bge $t2, $s1, achou_match

    ###################################################
    # Carregar texto[i + j]
    ###################################################
    la  $t4, texto
    add $t5, $t0, $t2       # t5 = i + j
    add $t4, $t4, $t5       # &texto[i+j]
    lb  $t6, 0($t4)         # t6 = texto[i+j]

    ###################################################
    # Carregar padrao[j]
    ###################################################
    la  $t7, padrao
    add $t7, $t7, $t2       # &padrao[j]
    lb  $t8, 0($t7)         # t8 = padrao[j]

    ###################################################
    # Converter ambos para MAIÚSCULO (se forem 'a'..'z')
    ###################################################
    # texto[i+j]
    li  $t9, 'a'
    blt $t6, $t9, skip_conv_texto
    li  $t9, 'z'
    bgt $t6, $t9, skip_conv_texto
    addi $t6, $t6, -32      # t6 = t6 - 32 => maiúsculo
skip_conv_texto:

    # padrao[j]
    li  $t9, 'a'
    blt $t8, $t9, skip_conv_padrao
    li  $t9, 'z'
    bgt $t8, $t9, skip_conv_padrao
    addi $t8, $t8, -32      # t8 = t8 - 32 => maiúsculo
skip_conv_padrao:

    ###################################################
    # Comparar caracteres
    ###################################################
    bne $t6, $t8, nao_casa  # se diferentes, não casa

    # Se iguais, j++ e continua
    addi $t2, $t2, 1
    j    loop_interno

nao_casa:
    li  $t3, 0              # flag_match = 0
    j   avancar_i

achou_match:
    # Aqui j >= pat_len. Só conta se flag_match ainda for 1
    beq $t3, $zero, avancar_i

    # Incrementa contador de ocorrencias
    addi $s2, $s2, 1

    # Imprime posicao da ocorrencia (i, base 0)
    li  $v0, 4
    la  $a0, msg_ocorrencia
    syscall

    li  $v0, 1
    move $a0, $t0           # posição i (0-based)
    syscall

    # Quebra de linha
    li  $v0, 4
    la  $a0, quebra_linha
    syscall

avancar_i:
    addi $t0, $t0, 1        # i++
    j    loop_externo

fim_busca:
    # Imprime total de ocorrencias
    li  $v0, 4
    la  $a0, msg_resultado
    syscall

    li  $v0, 1
    move $a0, $s2
    syscall

    li  $v0, 4
    la  $a0, quebra_linha
    syscall

    # Encerrar programa
    li  $v0, 10
    syscall

sem_ocorrencias:
    li  $s2, 0
    j   fim_busca

###########################################################
# str_len_no_newline
# Calcula o comprimento de uma string até '\0' ou '\n'
# Entrada:  $a0 = endereço da string
# Saída:    $v0 = comprimento (int)
###########################################################
str_len_no_newline:
    li  $t0, 0              # contador = 0

len_loop:
    lb  $t1, 0($a0)         # t1 = *str

    beq $t1, $zero, len_fim # se '\0'
    li  $t2, 10             # '\n' = 10 em ASCII
    beq $t1, $t2, len_fim   # se '\n', para (ignoramos o enter)

    addi $t0, $t0, 1        # contador++
    addi $a0, $a0, 1        # avança ponteiro
    j    len_loop

len_fim:
    move $v0, $t0
    jr   $ra
