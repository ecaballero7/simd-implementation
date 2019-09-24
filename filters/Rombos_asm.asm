global Rombos_asm
section .data
size: dq 64
halfsize: dq 32
casobordesuperior: dw 64, 64, 64, 64, 63, 63, 63, 63
phalfsize: times 8 dw 32
pfullsize: times 8 dw 64
alfa: dw 0, 0, 0, 255, 0, 0, 0, 255
section .rodata
%define NULL 0
section .text
Rombos_asm:
;uint8_t *src,		→ rdihis instruction can be used with a LOCK prefix to allow the instruction to be executed atomically.
;uint8_t *dst,		→ rsi
;int width,			→ edx
;int height,		→ ecx
;int src_row_size,	→ r8d
;int dst_row_size	→ r9d
push rbp
mov rbp, rsp
push r12
push r13
push r14
push r15
mov r8, rsi
mov r9, rdi 		;rdi = src
mov r10d, edx		;width = r10 = edx
mov r11d, ecx 		;height = r11 = ecx
xor r12, r12		;contador altura
xor r13, r13		;contador anchura
mov r14, [size] 	
mov r15, [halfsize]

movdqu xmm2, [phalfsize]	;todos los componentes de xmm2 son 32
movdqu xmm5, [pfullsize]	;todos los componentes de xmm5 son 64
movdqu xmm9, [alfa]			;mascara alfa

pxor xmm3, xmm3 
pxor xmm4, xmm4				;xmm4 = operador ii
pxor xmm0, xmm0 			;xmm0 = operador jj
.altura:
	cmp r12d, ecx
	je .fin 
	xor r13, r13 					;anchura de nueva fila empieza de cero
	mov rax, r12					;calculo i mod size 		
	xor rdx, rdx					;zero rdx para poder hacer div
	div r14							; r12 / 64 

	movd xmm4, edx					;xmm4 = |?|?|?|i%64|
	pshufd xmm4, xmm4, 00000000b	;xmm4 = |i%64|i%64|i%64|i%64|
	packusdw xmm4, xmm4				;xmm4 = |i%64|i%64|i%64|i%64|i%64|i%64|i%64|i%64|

	psubw xmm4, xmm2				;xmm4 = |(i%64)-32|(i%64)-32|(i%64)-32|(i%64)-32|
	pabsw xmm4, xmm4				;xmm4 = |abs((i%64)-32)|.....
	;hasta aqui xmm4 = ii
	.anchura:	
		;calculo jj
		pxor xmm0, xmm0
		mov rax, r13					;calculo j mod size 		
		xor rdx, rdx					;zero rdx para poder hacer div
		div r14							; r13 / 64 	
		pinsrw xmm0, edx, 0h
		pinsrw xmm0, edx, 1h
		pinsrw xmm0, edx, 2h
		pinsrw xmm0, edx, 3h
		inc r13
		mov rax, r13					;calculo j mod size 		
		xor rdx, rdx					;zero rdx para poder hacer div
		div r14							; r13 / 64 
		pinsrw xmm0, edx, 4h
		pinsrw xmm0, edx, 5h
		pinsrw xmm0, edx, 6h
		pinsrw xmm0, edx, 7h
		inc r13
		psubw xmm0, xmm2				;xmm4 = |(i%64)-32|(i%64)-32|(i%64)-32|(i%64)-32|
		pabsw xmm0, xmm0
		
		;calculo x = ii+jj-(size/2)) > (size/16) ? 0 : 2*(ii+jj-(size/2))
		movdqu xmm6, xmm4 	;xmm6 = xmm4 = ii
		paddw xmm6, xmm0	;xmm6 = ii + jj
		psubw xmm6, xmm2 	;xmm6 = ii + jj - 32
		movdqu xmm7, xmm5 	;xmm7 = xmm5 = 64
		psrlw xmm7, 4 		; 64 >> 4 = 4
		pcmpgtw xmm7, xmm6 	;si xmm7[0..15] = 4 > xmm6[0..15] → xmm7[0..15] = ffff sino xmm7[0..15]=0
		;pxor xmm7, xmm6		;ej: pxor( 0101 1010, 0000 1111 ) = 0101 0101
		pand xmm7, xmm6 	;	 pand( 0101 0101, 0101 1010 ) = 0101 0000
			;en xmm7 esta ii - (size/2)) > (size/16) ? 0 : (ii+jj-(size/2))
			;hago shift a la izquierda de un bit para que quede ii+jj-(size/2)) > (size/16) ? 0 : 2*(ii+jj-(size/2))
		psllw xmm7, 1 
		movq xmm8, [r9]		;levanto de memoria 2 pixeles
		add r9, 8 			;incremento el puntero de donde levanto memoria en 2 pixeles
		
		pxor xmm6, xmm6 	;xmm6 = 0
		punpcklbw xmm8, xmm6;paso los packed bytes de xmm8 a packed words en xmm8
		paddw xmm8,xmm7 	;sumo el operador x a cada componente de los 2 pixeles que traje
		por xmm8, xmm9
		packuswb xmm8, xmm8 ;paso los componentes de word a byte (sobra la mitad del registro)
		movq [r8], xmm8 	;guardo en memoria 
 		add r8, 8 			;incremento el puntero a memoria en 2 pixeles
		cmp r13d, r10d 		;comparo el contador de anchura por el ancho
		jne .anchura 		;si ya recorri toda una fila no salto a anchura de nuevo
				
	;paddw xmm3, xmm0 		;xmm3 = |(altura % 64) +1 |..|..|(altura % 64) +1|
	inc r12					;complete una fila, incremento contador altura
	jmp .altura
.fin:
pop r15
pop r14
pop r13
pop r12
pop rbp

ret
