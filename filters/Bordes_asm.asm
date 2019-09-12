global Bordes_asm
section .rodata

%define SIZE_XMMS 16
%define PIXELS_IN_IT 16

msk_blanca_pcol: DB 0xFF, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
msk_blanca_ucol: DB 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xFF
msk_blanca: TIMES 16 DB 0xFF

section .text
Bordes_asm:

;Armo stackframe
  push rbp
  mov rbp, rsp

	push rbx
	push r14
	push r12
	push r13

	xor r10, r10

	mov r8d, r8d

	pxor xmm0, xmm0 ; registro que voy a usar para extender signo

.ciclo_alto_imagen:
	mov r14, rdi		; fila central
	lea r12, [r14 + r8] ; fila superior
	mov r13, r14
	sub r13, r8	; fila inferior
	mov rbx, rsi

	cmp ecx, r10d
	je .fin
	xor r9,r9

	.ciclo_ancho_imagen:
		cmp r9d, edx
		je .subir_fila

		;me fijo si estoy en la primera o ultima fila.
    	cmp r10d, 0
    	je .fila_blanca
    	lea r11d, [ecx - 1]
    	cmp r11d, r10d
    	je .fila_blanca

		movdqu xmm2, [r12] 		; xmm2 = central superior

		movdqu xmm8, [r13] 		; xmm8 = central inferior

		; me fijo si estoy en un caso borde (primera o ultima columna)
    	cmp r9d, 0
    	je .primera_columna

        movdqu xmm1, [r12 - 1]  ; xmm3 = diagonal superior izq
        movdqu xmm4, [r14 - 1]  ; xmm6 = central izq
        movdqu xmm7, [r13 - 1]  ; xmm9 = diagonal inferior izq

        jmp .cmp_ult_columna

    .primera_columna:
        ;Comparo para ver si es el remoto caso de que la img sea de 16x16
        lea r11d, [r9d + PIXELS_IN_IT]
        cmp r11d, edx
        je .16x16

        movdqu xmm15, [msk_blanca_pcol]
        ; Si no es el caso 16x16 entonces tampoco es la ultima fila
        movdqu xmm3, [r12 + 1]  ; xmm3 = diagonal superior der
        movdqu xmm6, [r14 + 1]  ; xmm4 = central intermedia der
        movdqu xmm9, [r13 + 1]  ; xmm9 = diagonal inferior der

        ; Tengo que poner 0's en las primeros pixeles
        movdqu xmm1, xmm2
        pslldq xmm1, 1          ; xmm1 = diagonal superior izq (con 0s en el primer byte)
        por xmm1, xmm15

        movdqu xmm4, [r14]
        pslldq xmm4, 1          ; xmm4 = central izq (con 0s en el primer byte)
        ;por xmm4, xmm15

        movdqu xmm7, xmm8
        pslldq xmm7, 1          ; xmm7 = diagonal inferior izq (con 0s en el primer byte)
        ;por xmm7, xmm15

        psrldq xmm2, 1
        pslldq xmm2, 1
        psrldq xmm3, 1
        pslldq xmm3, 1
        psrldq xmm6, 1
        pslldq xmm6, 1
        psrldq xmm8, 1
        pslldq xmm8, 1
        psrldq xmm9, 1
        pslldq xmm9, 1

        jmp .procesar

    .cmp_ult_columna:
    	lea r11d, [r9d + PIXELS_IN_IT]
    	cmp r11d, edx
    	je .ultima_columna

        movdqu xmm3, [r12 + 1]  ; xmm3 = diagonal superior der
        movdqu xmm6, [r14 + 1]  ; xmm4 = central intermedia der
        movdqu xmm9, [r13 + 1]  ; xmm9 = diagonal inferior der
        jmp .procesar

    .ultima_columna:
        movdqu xmm15, [msk_blanca_ucol]

        ; Tengo que poner 0's en los ultimos pixeles
        movdqu xmm3, xmm2
        psrldq xmm3, 1          ; xmm1 = diagonal superior der (con 0s en el ultimo byte)
        por xmm3, xmm15

        movdqu xmm6, [r14]
        psrldq xmm6, 1          ; xmm6 = central der (con 0s en el ultimo byte)

        movdqu xmm9, xmm8
        psrldq xmm9, 1          ; xmm7 = diagonal inferior der (con 0s en el ultimo byte)

        pslldq xmm1, 1
        psrldq xmm1, 1
        pslldq xmm2, 1
        psrldq xmm2, 1
        pslldq xmm4, 1
        psrldq xmm4, 1
        pslldq xmm7, 1
        psrldq xmm7, 1
        pslldq xmm8, 1
        psrldq xmm8, 1
        jmp .procesar

    .16x16:
        ; Tengo que poner 0's en los ultimos y primeros piexeles

        movdqu xmm1, xmm2
        pslldq xmm1, 2
        psrldq xmm1, 1          ; xmm1 = diagonal superior izq (con 0s en el primer y ultimo byte)

        movdqu xmm3, xmm2
        psrldq xmm3, 2
        pslldq xmm3, 1          ; xmm1 = diagonal superior der (con 0s en el ultimo y primer byte)

        movdqu xmm7, xmm8
        pslldq xmm7, 2
        psrldq xmm7, 1          ; xmm7 = diagonal inferior izq (con 0s en el primer y ultimo byte)

        movdqu xmm9, xmm8
        psrldq xmm9, 2
        pslldq xmm9, 1          ; xmm7 = diagonal inferior der (con 0s en el ultimo y primer byte)

        movdqu xmm6, [r14]
        movdqu xmm4, xmm6
        psrldq xmm6, 2
        pslldq xmm6, 1          ; xmm6 = central izq (con 0s en el ultimo y primer byte)

        pslldq xmm4, 2
        psrldq xmm4, 1          ; xmm4 = central der (con 0s en el ultimo y primer byte)

        psrldq xmm2, 1
        pslldq xmm2, 2
        psrldq xmm2, 1

        psrldq xmm8, 1
        pslldq xmm8, 2
        psrldq xmm8, 1

	.procesar:
    	; uso xmm12 y xmm13 para OPxh/l y xmm14 y xmm15 para OPyh/l
    	; sumo las esquinas
    	movdqu xmm10, xmm1
    	movdqu xmm11, xmm3
    	movdqu xmm12, xmm7
    	movdqu xmm13, xmm9

    	punpckhbw xmm1, xmm0 	; xmm1 = (0,0) h
    	punpcklbw xmm10, xmm0	; xmm10 = (0,0) l
    	punpckhbw xmm3, xmm0	; xmm3 = (0,2) h
    	punpcklbw xmm11, xmm0	; xmm11 = (0,2) l
    	punpckhbw xmm7, xmm0	; xmm7 = (2,0) h
    	punpcklbw xmm12, xmm0	; xmm12 = (2,0) l
    	punpckhbw xmm9, xmm0	; xmm9 = (2,2) h
    	punpcklbw xmm13, xmm0	; xmm13 = (2,2) l

    	; calculo en xmm9 y xmm13 OPx y en xmm14 y xmm15 OPy

    	; OPy (Suma esquinas)
    	movdqu xmm14, xmm9 		; OPy h = (2,2) h
    	movdqu xmm15, xmm13 	; OPy l = (2,2) l
    	psubw xmm14, xmm3		; OPy h = (2,2) - (0,2) h
    	psubw xmm15, xmm11		; OPy l = (2,2) - (0,2) l
    	psubw xmm14, xmm1		; OPy h = (2,2) - (0,2) - (0,0) h
    	psubw xmm15, xmm10		; OPy l = (2,2) - (0,2) - (0,0) l
    	paddw xmm14, xmm7		; OPy h = (2,2) - (0,2) - (0,0) + (2,0) h
    	paddw xmm15, xmm12		; OPy l = (2,2) - (0,2) - (0,0) + (2,0) l

    	; OPx (Suma esquinas)
    	psubw xmm9, xmm1  		; OPx h = (2,2) - (0,0) h
    	psubw xmm13, xmm10		; OPx l = (2,2) - (0,0) l
    	paddw xmm9, xmm3		; OPx h = (2,2) - (0,0) + (0,2) h
    	paddw xmm13, xmm11		; OPx l = (2,2) - (0,0) + (0,2) l
    	psubw xmm9, xmm7		; OPx h = (2,2) - (0,0) + (0,2) - (2,0) h
    	psubw xmm13, xmm12		; OPx l = (2,2) - (0,0) + (0,2) - (2,0) l

    	; muevo OPx (esquinas) high a xmm12 para estar ordenado
    	movdqu xmm12, xmm9
    	; entonces queda asi:
    	; xmm12 = OPx h (esquinas) y xmm13 OPx l (esquinas)
    	; xmm14 = OPy h (esquinas) y xmm15 OPy l (esquinas)

    	; Copio los centros
    	movdqu xmm1,  xmm2
    	movdqu xmm3,  xmm4
    	movdqu xmm5,  xmm6
    	movdqu xmm7,  xmm8

    	;Cada OP como mucho en peor caso es de tamaño W
    	;desempaqueto los centros para poder multiplicarlos por 2
    	punpckhbw xmm1, xmm0 ; (0,1) h
    	punpcklbw xmm2, xmm0 ; (0,1) l
    	punpckhbw xmm3, xmm0 ; (1,0) h
    	punpcklbw xmm4, xmm0 ; (1,0) l
    	punpckhbw xmm5, xmm0 ; (1,2) h
    	punpcklbw xmm6, xmm0 ; (1,2) l
    	punpckhbw xmm7, xmm0 ; (2,1) h
    	punpcklbw xmm8, xmm0 ; (2,1) l

    	psllw xmm1, 1 	; 2*(0,1) h
    	psllw xmm2, 1	; 2*(0,1) l
    	psllw xmm3, 1	; 2*(1,0) h
    	psllw xmm4, 1	; 2*(1,0) l
    	psllw xmm5, 1	; 2*(1,2) h
    	psllw xmm6, 1	; 2*(1,2) l
    	psllw xmm7, 1	; 2*(2,1) h
    	psllw xmm8, 1	; 2*(2,1) l

    	; sumo y resto 2*centros de OPx
    	psubw xmm12, xmm3	; OPx h = (2,2) - (0,0) + (0,2) - (2,0) - 2*(1,0) h
    	psubw xmm13, xmm4	; OPx l = (2,2) - (0,0) + (0,2) - (2,0) - 2*(1,0) l
    	paddw xmm12, xmm5	; OPx h = (2,2) - (0,0) + (0,2) - (2,0) - 2*(1,0) + 2*(1,2) h
    	paddw xmm13, xmm6	; OPx l = (2,2) - (0,0) + (0,2) - (2,0) - 2*(1,0) + 2*(1,2) l

    	; sumo y resto 2*centros de OPy
    	psubw xmm14, xmm1	; OPy l = (2,2) - (0,2) - (0,0) + (2,0) - 2*(0,1) h
    	psubw xmm15, xmm2	; OPy l = (2,2) - (0,2) - (0,0) + (2,0) - 2*(0,1) l
    	paddw xmm14, xmm7	; OPy l = (2,2) - (0,2) - (0,0) + (2,0) - 2*(0,1) + 2*(2,1) h
    	paddw xmm15, xmm8 	; OPy l = (2,2) - (0,2) - (0,0) + (2,0) - 2*(0,1) + 2*(2,1) l

    	pabsw xmm12, xmm12 		; |OPx h|
    	pabsw xmm13, xmm13		; |OPx l|
    	pabsw xmm14, xmm14		; |OPy h|
    	pabsw xmm15, xmm15		; |OPy l|
    	paddw xmm12, xmm14		; |OPx h| + |OPy h|
    	paddw xmm13, xmm15		; |OPx l| + |OPy l|
    	packuswb xmm13, xmm12 	; |OPx l| + |OPy l| = |OPxy| saturado sin signo => (si es |OPxy| > 255 queda 255, si no queda |OPxy|)

    	movdqu xmm5, xmm13

    	jmp .fin_ancho_imagen
	.fila_blanca:
    movdqu xmm5, [msk_blanca]

	.fin_ancho_imagen:
	    movdqu [rbx], xmm5

		add rbx, SIZE_XMMS
		add r14, SIZE_XMMS
		add r13, SIZE_XMMS
		add r12, SIZE_XMMS
		add r9d, PIXELS_IN_IT ; avanzo 16 pixeles

		jmp .ciclo_ancho_imagen

	.subir_fila:
	lea rdi, [rdi + r8]
	lea rsi, [rsi + r8]

	inc r10
	jmp .ciclo_alto_imagen

.fin:
	pop r13
	pop r12
	pop r14
	pop rbx
	pop rbp
	ret
