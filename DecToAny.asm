;				AOC - 2022
; Erick Lemmy dos Santos Oliveira 

; Implemente em linguagem Assembly 8086 (Emu8086) que realize a conversao da base decimal para outra qualquer.
; O sistema devera pedir duas informacoes:
; 1. Valor da BASE DE DESTINO (o valor entrado deve ser em decimal). São permitidas bases de 2 a 16;
; 2. Valor de ORIGEM em decimal (apenas digitos sao aceitos). Sao permitidos valores de 0 a 65535.

org 100h

jmp start

.data 
    store   db 16 dup(' '), '$'     ; ONDE O RESULTADO FICA SALVO 
	
	buffer  db 3,?, 3 dup(' ') 
	buffer2 db 6                    ; NUMERO MAXIMO DE DIGITOS PERMITIDOS (5)
            db ?                    ; NUMERO DE DIGITOS ENTRADOS
            db 6 dup (?)            ; DIGITOS ENTRADOS 
	
	msg1	db 0Dh, 0Ah, 0Dh, 0Ah, "| ----------------------------- CONVERSAO DE BASE ---------------------------- |", 0Dh, 0Ah, "$"
	msg2	db 0Dh, 0Ah,           ">>>> INDIQUE A BASE DE DESTINO   (2 A 16): $"	
	msg3	db 0Dh, 0Ah,           ">>>> DIGITE O VALOR DE ORIGEM (0 A 65535): $"	  
	msg4	db 0Dh, 0Ah,           ">>>> RESULTADO: $"	  
	exitMsg db 0Dh, 0Ah,           ">>>> DESEJA CONVERTER NOVAMENTE (S/n): $"
	endMsg  db 0Dh, 0Ah, 0Dh, 0Ah, "| ------------------------------ FIM DO PROGRAMA!! --------------------------- |$"
	inputErrMsg db 0Dh, 0Ah,       ">>>> INPUT INVALIDO (CARACTER OU VALOR NAO PERMITIDO)!!$"
    base    db 0Dh, 0Ah, 0Dh, 0Ah, "| ------------------------------ A BASE EH A MESMA!! ------------------------- |$"

.code 
start:			
    mov     AX, @data  
    mov     DS, AX
    
	mov		DX, offset msg1
	mov		AH, 9
	int		21h

	mov		DX, offset msg2
	mov		AH, 9
	int		21h
	
	call	get_input_base      
	call    convert_to_number_base   ; RETORNA O VALOR EM BX
    mov     CX, BX                   ; PASSA DE BX PARA CX
	
	; COMPARA SE O VALOR EH MENOR QUE 2
	cmp		CX, 2
	jb		inputValueError
	
	; COMPARA SE EH MAIOR QUE 16
	cmp		CX, 16
	ja		inputValueError       
    push    CX                      ; SALVA CX NA PILHA
      
input_msg:	  
	mov		DX, offset msg3
	mov		AH, 9					 
	int		21h		

get_input:
	call	get_input_origin
    call    convert_to_number_origin ; O RETORNO FICA EM BX
        
    pop     CX                      ; RECUPERA CX
    cmp     CX, 10                  ; VERIFICA A BASE EH 10
    je      same_base
    
    call    convert_base 
    jmp     exit
    
; input DESTINO:		   
get_input_base:  
	mov		DX, offset buffer
	mov		AH, 0Ah
	int     21h
	ret 
    
; input ORIGIN:		   
get_input_origin:
	mov		DX, offset buffer2
	mov		AH, 0Ah
	int     21h
    ret     
    
inputValueError:
	mov		DX, offset inputErrMsg
	mov		AH, 9
	int		21h		
	jmp		start    

; ================================================= CONVERSAO ===============================================
; CONVERTE A STRING DO INPUT PARA NUMERO (SALVA EM BX)
convert_to_number_base:      
    ; SI APONTA PARA O BIT MENOS SIGNIFICATIVO 
    mov     SI, offset buffer + 1 ; BUFFER 1 APENAS 2 DIGITOS (max 16)
    mov     CL, [SI]    ; NUMERO DE CARACTERES LIDO                                         
    mov     CH, 0       ; LIMPA CH
    add     SI, CX      ; SI APONTA PARA O MENOS SIGNIFICATIVO
    
    ; CONVERTE STRING
    mov     BX, 0
    mov     BP, 1       ; MULTIPLO DE 10 PARA CONVERTER
    jmp     repeat 
                                                          
convert_to_number_origin:      
    mov     SI, offset buffer2 + 1 ; BUFFER2 CABE ATEH 5 DIGITOS (max 65535)
    mov     CL, [SI]                                          
    mov     CH, 0 
    add     SI, CX 
    
    mov     BX, 0
    mov     BP, 1    

repeat:         
    ; CONVERTE CARACTERE                     
    mov     AL, [SI]    ; CARACTER 
    sub     AL, 48      ; CONVERTE ASCII CARACTER PARA DIGITO 
    
    ; VERIFICA SE O INPUT EH VALIDO (ENTRE 0 E 9)
    cmp     AL, 9
    ja      inputValueError
    
    cmp     AL, 0
    jb      inputValueError
    
    mov     AH, 0        
    mul     BP          ; AX*BP = DX:AX
    add     BX, AX      ; ADICIONA RESULTADO EM BX  
    cmp     BX, AX
    jc      inputValueError
    
    ; AUMENTA MULTIPLO DE 10 (1, 10, 100...).
    mov     AX, BP
    mov     BP, 10
    mul     BP          ; AX*10 = DX:AX.
    mov     BP, AX      ; NOVO MULTIPLO DE 10   
    
    ; VERIFICA SE TERMINOU
    dec     SI          ; PROXIMO DIGITO 
    loop    repeat      ; REPETE ATE CX = 0 
    ret 

convert_base: 
    mov		DX, offset msg4
	mov		AH, 9
	int		21h	

    mov     AX, BX                ; PASSA DE BX PARA AX (PARA DIVIDIR DX:AX/BX)
    xor     BH, BH                ; RESETA BH
    mov     BL, CL                ; PASSA A BASE PARA BL

	mov     SI, 15            ; NUMERO MAXIMO DE DIVISOES PARA TER TODOS OS BITS	           
    divide:
        xor   DX, DX          ; RESETA DX 
        div   BX
        
        cmp   DL, 9
        ja    above_ten
        
        add   DL, 48          ; CONVERTE PRA ASCII DNV
    continue:
        mov   store[SI], DL   ; CONCATENA O RESULTADO EM STORE
        
        dec   SI
        cmp   AX, 1           ; CONFERE SE DEU 1
        je    print        
        
        cmp   AX, 0           ; CONFERE SE DEU 0
        jne   divide
        je    print

; SE ACIMA DE 10 ENTAO SOMA 55 PARA TER 'A' - 'F'
above_ten:
    add     DL, 55
    jmp     continue
    
; ==================================================== PRINT ================================================                   
print:                      
    mov     DL, AL          ; PRINTA O RESULTADO DO ULTIMO RESTO DE TRAS PARA FRENTE
    add     DL, 48          ; CONVERTE PRA ASC

    mov     store[SI], DL   ; MOSTRA OS VALORES SALVOS ANTERIORMENTE

    mov     DX, offset store
    mov     AH, 9
    int     21h
    jmp     exit  
 
 same_base:
    mov		DX, offset base
	mov		AH, 9
	int		21h           

	jmp     exit 
            
; ============================================= TERMINA O PROGRAMA ==========================================   
exit:				
	mov		DX, offset exitMsg
	mov		AH, 9
	int		21h		
    
    mov     SI, 0           ; P/ PERCORRER AS POSICOES
    mov     CX, 15          ; CAPACIDADE DO BUFFER   
    reset_buffer:           ; RESETAR O BUFFER PARA A PROXIMA EXECUCAO
        mov     store[SI], 0000h
        inc     SI
        loop    reset_buffer
        
	mov		AH, 1
	int		21h
	cmp		AL, 'S'         ; compara se o input eh igual a S MAISCULO ou nao
	je		start           ; qualquer input != S eh um nao e fecha o jogo 
    
    cmp		AL, 's'         ; compara se o input eh igual a S MINUSCULO ou nao
	je		start           ; qualquer input != S eh um nao e fecha o jogo  
	
	mov		DX, offset endMsg
	mov		AH, 9
	int		21h	
	
	mov     AH, 4Ch         ; FINALIZA O PROGRAMA
    int     21h
