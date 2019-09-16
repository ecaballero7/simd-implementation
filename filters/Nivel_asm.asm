global Nivel_asm

section .rodata

%define filtro_alpa  0xFF000000

section .data
;Valores para setear 255
cmp_mask: times 4 DB  0xff, 0xff, 0xff, 0xff

%define N [rbp+16]

section .text
Nivel_asm:    
;void Nivel_asm()
;             rdi = uint8_t *src,
;             rsi = uint8_t *dst,
;             rdx = int width,
;             rcx = int height,
;             r8d = int src_row_size,
;             r9d = int dst_row_size),
;             rbp+16 = int N;
;}
  ;my stack frame
  push rbp
  mov rbp,rsp

  xor r8,r8               ;limpio r8 para iterar sobre colum
  mov r8d,edx             ;r8 = columnas   

  ;guardo las mascaras en los registros XMMx
  xor r9, r9
  inc r9d                 ;r9d = 1
  mov r11d, ecx           ;r11 = ecx (resguardo)
  mov cl, N
  shl r9d, cl             ;r9d = 1 << N = mask (word)
  pxor xmm10, xmm10
  pxor xmm7, xmm7 
  pinsrb xmm10, r9b, 00000000b ;;xmm10 = [0 | 0 | 0 ...| mask]byte
  pshufb xmm10, xmm7      
  ; pshufb xmm10, xmm10     ;xmm10 = [mask | mask | mask | mask | mask | mask | mask | mask]bytes
  ;quiero tener N's en cada componente (rgb)
  ; mask = 1 << n 

  movdqu xmm8, [cmp_mask] ;xmm8 = [255..]bytes
  pxor xmm7, xmm7         ;xmm7 = [0's]bytes
  mov ecx, r11d           ;recupero ecx

  xor r10,r10             ;inicio recorrido sobre fila r10 = 0
  ciclo_fila:
    cmp r10d,ecx          ;llegue al final de las filas?
    jge fin_ciclo
    xor r11,r11           ;inicializo columnas r11 = 0

    ciclo_columna:
      cmp r11d,r8d        ;llegue al final de la columna?
      jge fin_columna
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                        Estados de los registros                           ;
; xmm10 = [mask | mask | mask | mask] mask = 1 << N                         ;
; xmm7  = [0000 | 0000 | 0000 | 0000]                                       ;
; xmm8  = [255  | 255  | 255  | 255]                                        ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
          
iterando:;xmm1 == |P3|P2|P1|P0| 16 bytes
        movdqu xmm0, [rdi]        ;levanto 16 bytes - trabajo con 4 pixeles
        movdqu xmm2, xmm10      ;xmm2 = mascara  
        pand xmm2, xmm0         ;xmm2 = tengo 1 << N donde aplique
        pcmpgtb xmm2, xmm7      ;xmm2 = 1's donde cumple mask cc 0's

        pand xmm2, xmm8         ;xmm2 = seteo 255 en donde cumple mask, cc 0's
 
        movdqu [rsi], xmm2      ;pego en dst

      lea rdi,[rdi+16]  ;avanzo 4 pixeles src
      lea rsi,[rsi+16]  ;avanzo 4 pixeles dst
      add r11,4         ;aumento en 4 # de pixeles
      jmp ciclo_columna
    fin_columna:
    inc r10
    jmp ciclo_fila
  fin_ciclo:
  pop rbp
  ret