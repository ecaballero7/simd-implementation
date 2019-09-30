global Rombos_asm

section .rodata
;pixel alpha, seteo alfa
mask_alpha: dd 0xFF000000, 0xFF000000, 0xFF000000, 0xFF000000
;mascara para sumar a las iteraciones sobre columna: j+0, j+1, j+2, j+3 (proceso 4 pixeles)
mask_j: dd 0x00, 0x01, 0x02, 0x03

;mascara para desempaquetar a word
shuffle_1:	db 0x00,0x01,0x00,0x01
			db 0x00,0x01,0xFF,0xFF
			db 0x04,0x05,0x04,0x05
			db 0x04,0x05,0xFF,0xFF

shuffle_2:	db 0x08,0x09,0x08,0x09
			db 0x08,0x09,0xFF,0xFF
			db 0x0C,0x0D,0x0C,0x0D
			db 0x0C,0x0D,0xFF,0xFF

section .data
; size >> 1 = size/2
mask_32: times 4 dd 32
; size >> 4 = size/16 
mask_4: times 4 dd 4

mask_2: times 4 dd 2

section .text
Rombos_asm: 
;	 void Manchas_c(
; 	uint8_t *src, RDI = src
; 	uint8_t *dst, RSI = dst
; 	int width,	RDX = width
; 	int height,	RCX = height
; 	int src_row_size,	R8 = src_row_size
; 	int dst_row_size,	R9 = dst_row_size
; {	
	;armo el stack frame
	push rbp
	mov rbp,rsp
	push rbx
	sub rsp, 8

	xor r9, r9
	mov r9d, 64 					;r9 = size
	xor r8,r8
	mov r8d,edx 					;r8= columnas		

	;guardo las mascaras en los registros XMMx
	movdqu xmm15, [mask_alpha]		;xmm15 = [ff0000 |ff0000 |ff0000 | ff0000]
	movdqu xmm14, [mask_32]			;xmm14 = [size>>1|size>>1|size>>1| size>>1]
	movdqu xmm13, [mask_2] 			;xmm13 = [2		|   2   |   2   |   2]
	movdqu xmm12, [mask_j]		    ;xmm12 = [3		|   2 	|   1 	|   0]
	movdqu xmm11, [mask_4] 			;xmm11 = [4 	|   4   |   4   |   4]
	pxor xmm10,   xmm10				;xmm10 = [0		|	0	|	0 	| 	0]

	movdqu xmm9, [shuffle_1]
	movdqu xmm8, [shuffle_2]

	xor r10,r10 					;r10=0, fila inicial
	ciclo_fila:
		cmp r10d,ecx 				;finalice el recorrido de las filas?
		jge fin_loop
		xor r11,r11					;columnas en cero
		
		mov rax,r10 				;calculo i mod size
		xor rdx,rdx
		div r9 						;rdx=(i%size)
	    
	    ;int ii = ((size>>1)-(i%size)) > 0 ? ((size>>1)-(i%size)) : -((size>>1)-(i%size));
		movq xmm1,rdx 			  		;xmm1 = [   0   |    0   |    0   | i%size]
		PSHUFD xmm1,xmm1,00000000b		;xmm1 = [i%size | i%size | i%size | i%size]
		movdqu xmm2, xmm14 				;xmm2 = [size>>1| size>>1| size>>1| size>>1]
		psubd xmm2, xmm1 		  		;xmm2 = [(size>>1)-(i%size) | (size>>1)-(i%size) | (size>>1)-(i%size) | (size>>1)-(i%size)]
		PABSD xmm2, xmm2 				;xmm4 = ABS[(size>>1)-(i%size) |  (size>>1)-(i%size)   |  (size>>1)-(i%size)   |  (size>>1)-(i%size)]
		movdqu xmm7, xmm2 				;xmm7 = [ii | ii | ii | ii]

		xor rbx, rbx 					;contador 0..63 - 0..63 
		
		ciclo_columna:
			cmp r11d,r8d 				;me fijo si llegue al final de la columna
			jge fin_ciclo_columa

	        ;int jj = ((size>>1)-(j%size)) > 0 ? ((size>>1)-(j%size)) : -((size>>1)-(j%size));
	        ;se que el ancho de las imágenes es siempre > 16pxs y múltiplo de 8pxs
	        cmp rbx, 63				 	;si llegue a 64, vuelvo a 0 
	        jl .seguir 					;rbx <= 63
	        pxor xmm2, xmm2 			;xmm0 = 0....0
		    xor rbx, rbx 				;rbx = 0
			.seguir:
			movq xmm2, rbx 				;xmm2 = [x   | x  |  x  | 0]
			PSHUFD xmm2, xmm2, 00000000b;xmm2 = [j 	 | j  |  j  | j]			
	        PADDD xmm2, xmm12 			;xmm6 = [(j+3)%size |(j+2)%size |(j+1)%size |j%size]       	
			movdqu xmm3, xmm14 		    ;xmm3 = [size>>1	| size>>1	| size>>1	| size>>1]
			PSUBD xmm3, xmm2 			;xmm3 = [(size>>1)-(j%size)....]
			PABSD xmm4, xmm3 			;xmm4 = me quedo con valores positivos. 

			PADDD xmm4, xmm7 			;xmm4 = [ii+jj | ii+jj | ii+jj | ii+jj]
			psubd xmm4, xmm14 			;xmm4 = [ii+jj-(size>>1) | ii+jj-(size>>1) | ii+jj-(size>>1) | ii+jj-(size>>1)]
			movdqu xmm5, xmm4 			;xmm5 = xmm4
			pcmpgtd xmm5, xmm11			;xmm5 = tengo 1's donde (ii+jj-(size>>1)) > (size>>4) cc 0's
			movdqu xmm6, xmm5 			;xmm6 = xmm5
			pand xmm5, xmm10 			;xmm5 = 0's si (ii+jj-(size>>1)) > (size>>4)
			movdqu xmm3, xmm13
			PMULLD xmm4, xmm3   		;xmm4 = xmm4 * 2
			pandn xmm6, xmm4 			;xmm6 = si (ii+jj-(size>>1) < (size>>4)
			por xmm5, xmm6 				;xmm5 = [x3   | x2   | x1   | x0]

			movdqu xmm1, [rdi] 			;xmm0 = [a3r3g3b3 | a2r2g2b2 | a1r1g1b1 |a0r0g0b0]
			;convierto de byte a word
			PMOVZXBW xmm0,xmm1			;xmm1 = [a1r1g1b1 	| 		a0r0g0b0]
			punpckhbw xmm1, xmm10 		;xmm0 = [a3r3g3b3 	| 		a2r2g2b2]
	        
	        ;int x = (ii+jj-(size>>1)) > (size>>4) ? 0 : 2*(ii+jj-(size>>1));
            movdqu xmm6,xmm5			;xmm6 = [x3  |x2	|x1   	|x0]   
			PSHUFB xmm5,xmm8 			;xmm5 = [0   |x1	|x1		|x1		|0		|x0		|x0		|x0]
			PSHUFB xmm6,xmm9 			;xmm6 = [0	 |x3 	|x3		|x3		|0		|x2		|x2		|x2]   

			PADDW xmm0, xmm6
			PADDW xmm1, xmm5

			PACKUSWB xmm0,xmm1  		;xmm0 = [a3|r3+x3|g3+x3|b3+x3 	a2|r2+x2|g2+x2|b2+x2 ....]

			por xmm0,xmm15 				;xmm0= seteo mask_alpha en las posiciones de a

			movdqu [rsi],xmm0	;pego los 4 pixeles procesados
			lea rdi,[rdi+16] 	;avanzo 4 pxs en el origen
			lea rsi,[rsi+16] 	;avanzo 4 pxs en destino
			add r11,4 			;aumento la cantidad de procesados en 4
			add rbx, 4 			;++4 en resto de (0..63)
			jmp ciclo_columna
		fin_ciclo_columa:
		inc r10
		jmp ciclo_fila
	fin_loop:
	add rsp, 8
	pop rbx
	pop rbp
	ret
