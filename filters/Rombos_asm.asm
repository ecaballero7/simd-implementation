global Rombos_asm

section .rodata
;PIXEL ALFA|ROJO|VERDE|AZUL
%define filtro_alpa 0xFF000000

mask_alpha: dd 0xFF000000, 0xFF000000, 0xFF000000, 0xFF000000

mask_j: dd 0x00
		dd 0x01
		dd 0x02
		dd 0x03

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
; 
mask_2: times 4 dd 2
; -1
mask_neg: times 4 dd -1

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

	xor r9, r9
	mov r9d, 64 					;r9 = size
	xor r8,r8
	mov r8d,edx 					;r8= columnas		

	;guardo las mascaras en los registros XMMx
	movdqu xmm15,[mask_alpha]		;xmm15 = [ff0000|ff0000|ff0000|ff0000]
	movdqu xmm14,[mask_32] 			;xmm14 = size>>1|size>>1|size>>1| size>>1
	movdqu xmm13,[mask_neg] 		;xmm13 = [-1 	|  -1   |  -1   |  -1
	movdqu xmm12, [mask_j]		    ;xmm12 = [3		|   2 	|   1 	|   0
	movdqu xmm11, [mask_4] 			;xmm11 = 
	pxor xmm10, xmm10 				;xmm10 =  0		|	0	|	0 	| 	0

	movdqu xmm9, [shuffle_1]
	movdqu xmm8, [shuffle_2]

	xor r10,r10 				;r10=0, cargo como fila inicial
	ciclo_fila:
		cmp r10d,ecx 			;me fijo si llegue al final de las filas
		jge fin_loop
		xor r11,r11				;inicializo columnas en cero
		
		mov rax,r10 			;calc mod i
		xor rdx,rdx
		div r9 					;rdx=(i%size)
	    
	    ;int ii = ((size>>1)-(i%size)) > 0 ? ((size>>1)-(i%size)) : -((size>>1)-(i%size));

		movq xmm1,rdx 			  		;xmm1 = [   0   |    0   |    0   | i%size]
		PSHUFD xmm1,xmm1,00000000b		;xmm1 = [i%size | i%size | i%size | i%size]
		movdqu xmm2, xmm14 				;xmm2 = [size>>1| size>>1| size>>1| size>>1]
		psubd xmm2, xmm1 		  		;xmm2 = [(size>>1)-(i%size) | (size>>1)-(i%size) | (size>>1)-(i%size) | (size>>1)-(i%size)]
		movdqu xmm3, xmm2 				;xmm3 = [(size>>1)-(i%size) | (size>>1)-(i%size) | (size>>1)-(i%size) | (size>>1)-(i%size)]
		pcmpgtd xmm3, xmm10 			;xmm3 = 1's donde ((size>>1)-(i%size)) > 0 cc 0's
		movdqu xmm4, xmm3 				;xmm4 = xmm3
		pandn xmm3, xmm2 				;xmm3 = 
		PMULLD xmm3, xmm13
		pand xmm4, xmm2
		por xmm3, xmm2
		movdqu xmm7, xmm3 				;xmm7 = [ii | ii | ii | ii]


		ciclo_columna:
			cmp r11d,r8d 				;me fijo si llegue al final de la columna
			jge fin_ciclo_columa

	        ;int jj = ((size>>1)-(j%size)) > 0 ? ((size>>1)-(j%size)) : -((size>>1)-(j%size));
	        ;int x = (ii+jj-(size>>1)) > (size>>4) ? 0 : 2*(ii+jj-(size>>1));

			movq xmm2,r11 				;xmm2 = [0		| 0 	| 0		| j]
			PSHUFD xmm2, xmm2, 00000000b;xmm2 = [j 		| j 	| j		| j]
			PADDD xmm2, xmm12 			;xmm2 = [j+3	| j+2	| j+1	| j]	
			movdqu xmm3, xmm2 			;xmm3 = [j+3	| j+2	| j+1	| j]
			CVTDQ2PS xmm3, xmm3 		;xmm3 = [j+3.00	| j+2.00| j+1.00| j.00] convierto a float de single presicion
			CVTSI2SS xmm6, r9 			;xmm6 = [00		|	00  |  00	| size.0] en float
			PSHUFD xmm6, xmm6, 00000000b;xmm6 = [size.0 | size.0| size.0| size.0]
			DIVPS xmm3, xmm6 			;xmm3 = [j+3/size | j+2/size | j+1/size | j/size] en float
			CVTPS2DQ xmm3, xmm3 		;convierto a int
			PMULLD xmm3, xmm6 			;xmm3 = 
			PSUBD xmm2, xmm3 		    ;xmm2 = [(j+3)%size |(j+2)%size |(j+1)%size |j%size]
			movdqu xmm3, xmm14 		    ;xmm3 = [size>>1	| size>>1	| size>>1	| size>>1]
			PSUBD xmm3, xmm2 			;xmm3 = [(size>>1)-(j%size)....]
			movdqu xmm4, xmm3 			;xmm4 = xmm3
			pcmpgtd xmm4, xmm10 		;xmm4 = tengo 1's donde ((size>>1)-(j%size)) > 0  y 0's caso contrario
			movdqu xmm5, xmm4 			;xmm4 = xmm5
			pandn xmm5, xmm3 			;xmm5 = filtro los casos en donde son negativos y me los quedo en xmm5
			pand xmm4, xmm3 			;xmm4 = valores positivos
			PMULLD xmm5, xmm13
			por xmm4, xmm5 				;xmm4 = [jj | jj | jj | jj]


			PADDD xmm4, xmm7 			;xmm4 = [ii+jj | ii+jj | ii+jj | ii+jj]
			psubd xmm4, xmm14 			;xmm4 = [ii+jj-(size>>1) | ii+jj-(size>>1) | ii+jj-(size>>1) | ii+jj-(size>>1)]
			movdqu xmm5, xmm4 			;xmm5 = xmm4
			pcmpgtd xmm5, xmm11			;xmm5 = tengo 1's donde (ii+jj-(size>>1)) > (size>>4) cc 0's
			movdqu xmm6, xmm5 			;xmm6 = xmm5
			pand xmm5, xmm10 			;xmm5 = 0's si (ii+jj-(size>>1)) > (size>>4)
			movdqu xmm3, [mask_2]
			PMULLD xmm4, xmm3   		;xmm4 = xmm4 * 2
			pandn xmm6, xmm4 			;xmm6 = si (ii+jj-(size>>1) < (size>>4)
			por xmm5, xmm6 				;xmm5 = [x3   | x2   | x1   | x0]

			movdqu xmm1, [rdi] 			;xmm0 = [a3r3g3b3 | a2r2g2b2 | a1r1g1b1 |a0r0g0b0]
			;convierto de byte a word
			PMOVZXBW xmm0,xmm1			;xmm1 = [a1r1g1b1 		| 		a0r0g0b0]
			punpckhbw xmm1, xmm10 		;xmm0 = [a3r3g3b3 	 	| 		a2r2g2b2]


            movdqu xmm6,xmm5	;xmm6= [x3 	|x2	    |x1   	|x0]   
			PSHUFB xmm5,xmm8 	;xmm2= [0   |x1		|x1		|x1		|0		|x0		|x0		|x0]
			PSHUFB xmm6,xmm9 	;xmm3= [0	|x3 	|x3		|x3		|0		|x2		|x2		|x2]   

			PADDW xmm0, xmm5
			PADDW xmm1, xmm6

			PACKUSWB xmm0,xmm1  ;xmm0= a3   |r3+x3 	|g3+x3 	|b3+x3 	|a2  	|r2+x2 	|g2+x2 	|b2+x2|	0    |a1		|x1		|x1		|0		|x0		|x0		|x0

			;por xmm0,xmm15 		;xmm0= seteo mask_alpha en las posiciones de a

			movdqu [rsi],xmm0	;guardo 4 pixeles procesados
			lea rdi,[rdi+16] 	;avanzo 4 pixeles el origen
			lea rsi,[rsi+16] 	;avanzo 4 pixeles el destino
			add r11,4 			;aumento la cantidad de procesados en 4
			jmp ciclo_columna
		fin_ciclo_columa:
		inc r10
		jmp ciclo_fila
	fin_loop:
	pop rbp
	ret
