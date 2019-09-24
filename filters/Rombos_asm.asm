global Rombos_asm
section .data
dsize: dq 128
size: dq 64
halfsize: dq 32
incremento: times 8 dw 0x1
zerouno: dw 0, 0, 0, 0, 1, 1, 1, 1
casobordesuperior: dw 64, 64, 64, 64, 63, 63, 63, 63
phalfsize: times 8 dw 32
pfullsize: times 8 dw 64
alfa: times 4 dd 255
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
mov r8, [dsize]
mov r9, rdi 		; rdi = src
xor r10, r10 		;es el modulo de la altura con 64
xor r11, r11		;es el modulo de la anchura con 64
xor r12, r12		;contador altura
xor r13, r13		;contador anchura
mov r14, [size] 	
mov r15, [halfsize]

movdqu xmm0, [incremento]
movdqu xmm1, [zerouno]
movdqu xmm2, [phalfsize]	;todos los componentes de xmm2 son 32
movdqu xmm5, [pfullsize]	;todos los componentes de xmm5 son 64
movdqu xmm9, [casobordesuperior]	;primeros 4 componentes 32, resto 0

pxor xmm3, xmm3 
pxor xmm4, xmm4
mov r10, r15
dec r10
movdqu xmm4, xmm2
.altura:
	cmp r12d, ecx
	je .fin 
	xor r13, r13 		;anchura de nueva fila empieza de cero
	cmp r10, r14 		;veo si contador altura % 64 > 0
	je .cont0
	cmp r10, r15		;cont < 32?
	jge .decRest
	paddw xmm4, xmm0
	jmp .cont
	.decRest:
	psubw xmm4, xmm0
	jmp .cont
	.cont0:
	xor r10, r10
	jmp .altura
	.cont:
	;psubw xmm4, xmm2
	pabsw xmm4, xmm4 
	;jge .decii
	;.incii:
	;	movdqu xmm4, xmm2 	;xmm4 = |32|32|32|32|
	;	psubw xmm4, xmm3	;xmm4 = |32 - (altura % 64)|..|..|32 - (altura % 64)|
	;	paddw xmm3, xmm0 	;xmm3 = |altura % 64 + 1|..|..|altura % 64 +1|
	;	jmp .anchura
	;.decii:
	;	cmp r10, r8 		;veo si contador resto = 128
	;	jne .decii_1
	;		xor r10, r10
	;		jmp .incii
	;	.decii_1:
	;	movdqu xmm4, xmm2 	;xmm4 = |32|32|32|32|
	;	psubw xmm3, xmm0 	;xmm3 = |altura % 64 - 1|..|..|altura % 64 -1|
	;	psubw xmm4, xmm3	;xmm4 = |32 - (altura % 64)|..|..|32 - (altura % 64)|
	;hasta aqui xmm4 = ii
	.anchura:	
		;cmp r11, r14		;veo si el contador de anchura % 64 >= 63
		;;calculo operador jj = ((size/2)-(j%size)) > 0 ? ((size/2)-(j%size)) : -((size/2)-(j%size));
		;	;xmm6 va a ser jj
		;	.prmEtapa:			;aca pongo el contador del primer pixel en 0, incremento el del segundo que estaba en cero por segetapa
		;	cmp r11, NULL		;veo si el contador de anchura == 0
		;	jne .segEtapa
		;	movdqu xmm6, xmm1	;xmm6 = |0|0|0|0|1|1|1|1|
		;	jmp .continua
		;	.segEtapa:			;aca me fijo si el contador/resto 64 llega a 62, cuyo caso pongo el contador del 2 pixel en 63
		;	inc r11
		;	cmp r11, r14 		;contador + 1 < 63 ? calculo jj normalmente : pongo 63 contador segundo pixel, 64 el primero
		;	dec r11				;retorno r11 valor orish. dec no afecta flags (?methinks)
		;	jne .terEtapa		;calculo jj normalmente
		;	movdqu xmm6, xmm9 	;xmm6 = |64|64|64|64|63|63|63|63|
		;	xor r11, r11 		; reset del contador / resto
		;	jmp .continua
		;	.terEtapa:			;en esta parte me fijo si tengo que decrementar o incrementar el contador/resto
		;	cmp r11, r15 		;contador/resto <= 32? incremento : decremento
		;	jge .decr
		;	.incr:
		;	paddw xmm6, xmm0




			

		.continua:
		;calculo x = ii+jj-(size/2)) > (size/16) ? 0 : 2*(ii+jj-(size/2))
			;xmm4 = |abs(32 - (altura % 64))|..|..|abs(32 - (altura % 64))|
		movdqu xmm6, xmm4 	;xmm6 = xmm4 = ii
		psubw xmm6, xmm2 	;xmm6 = ii - 32
		movdqu xmm7, xmm5 	;xmm7 = xmm5 = 64
		psrlw xmm7, 4 		; 64 >> 4 = 4
		pcmpgtw xmm7, xmm6 	;si xmm7[0..15] = 4 > xmm6[0..15] → xmm7[0..15] = ffff sino xmm7[0..15]=0
		;pxor xmm7, xmm6		;ej: pxor( 0101 1010, 0000 1111 ) = 0101 0101
		pand xmm7, xmm6 	;	 pand( 0101 0101, 0101 1010 ) = 0101 0000
			;en xmm7 esta ii - (size/2)) > (size/16) ? 0 : (ii+jj-(size/2))
			;hago shift a la izquierda de un bit para que quede ii-(size/2)) > (size/16) ? 0 : 2*(ii+jj-(size/2))
		psllw xmm7, 1 
		movq xmm8, [r9]		;levanto de memoria 2 pixeles
		add r9, 8 			;incremento el puntero de donde levanto memoria en 2 pixeles
		add r13, 2 			;incremento el contador de anchura en 2 pixeles
		pxor xmm6, xmm6 	;xmm6 = 0
		punpcklbw xmm8, xmm6;paso los packed bytes de xmm8 a packed words en xmm8
		paddw xmm8,xmm7 	;sumo el operador x a cada componente de los 2 pixeles que traje
;PACKUSWB — Pack with Unsigned Saturation
		packuswb xmm8, xmm8 ;paso los componentes de word a byte (sobra la mitad del registro)
		movq [rsi], xmm8 	;guardo en memoria 
 		add rsi, 8 			;incremento el puntero a memoria en 2 pixeles
		cmp r13d, edx 		;comparo el contador de anchura por el ancho
		jne .anchura 		;si ya recorri toda una fila no salto a anchura de nuevo

	inc r10 				
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
