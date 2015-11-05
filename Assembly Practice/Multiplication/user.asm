TITLE Multiplication

COMMENT !
	This program multiplies two integers (input in decimal, output in hex).
	Alexander Zhilyakov (http://56th.ru/), 2015
!

.386 ; This directive tells assembly to use Intel 80386 instruction set. тест
.MODEL FLAT, STDCALL  

COMMENT !
	.MODEL is an assemby directive that specifies memory model of the program.Under win32, there’s only one model, FLAT model.
	The memory is a large continuous space of 4 GB.
	STDCALL tells MASM about parameter passing convention.It passes parameters from right to left, the callee procedure is responsible for stack balancing after the call.
	
	Logical segments:
!

EXTERN  GetStdHandle@4: PROC
EXTERN  WriteConsoleA@20: PROC
EXTERN  CharToOemA@8: PROC
EXTERN  ReadConsoleA@20: PROC
EXTERN  ExitProcess@4: PROC
EXTERN  lstrlenA@4: PROC
EXTERN  wsprintfA : PROC

.CONST	; Declaration of constants used by the program.
	outStrn DB "input (in decimal)", 13, 10, 0
	outStrnA DB "1st number: ", 0
	outStrnB DB "2nd number: ", 0
	outStrnErr DB "Do you know what 'decimal' mean? Try again:", 13, 10, 0
	outStrnResult DB " (output in hex)", 13, 10, 0
	minus DB "-", 0
	ten DD 10
	hex DD 16
	
.DATA
	; Ininitialized data of the program.
	din DD ? ; input descriptor, 4 bytes
	dout DD ?
	len DD ?
	lenA DD ? ; numb of output symbols of A (A is the first number in decimal)
	bufA DB 200 DUP (?) ; buffer for A, 200 bytes 
	lenB DD ?
	bufB DB 200 DUP (?)
	A DD ?
	B DD ?
	lenAB DD ?
	bufAB DB 200 DUP (?) ; buffer for A*B, 200 bytes 
	f1 DB 0 ; f1 = 1 if A < 0, f1 = 0 otherwise 
	f2 DB 0
	
.CODE ; Section for code.
	main PROC
		; get input descriptor
		PUSH -10
		CALL GetStdHandle@4
		MOV din, EAX
		; get output descriptor
		PUSH -11
		CALL GetStdHandle@4
		MOV dout, EAX
		
		COMMENT !
		---------
			1. Getting input (numbers A and B as strings)
		---------
		!

		; get length of outStrn (EAX)
		PUSH OFFSET outStrn
		CALL lstrlenA@4
		PUSH 0; 5th parameter of WriteConsoleA@20
		PUSH OFFSET len; 4th
		PUSH EAX; 3rd (length of outStrn)
		PUSH OFFSET outStrn; 2nd
		PUSH dout; 1st
		CALL WriteConsoleA@20
REENTER:
		; get length of outStrnA (EAX)
		PUSH OFFSET outStrnA
		CALL lstrlenA@4
		PUSH 0; 5th parameter of WriteConsoleA@20
		PUSH OFFSET len; 4th
		PUSH EAX; 3rd (length of outStrn)
		PUSH OFFSET outStrnA; 2nd
		PUSH dout; 1st
		CALL WriteConsoleA@20
		
		; get 1st number (string)
		PUSH 0;
		PUSH OFFSET lenA ; numb of entered symbols (for one, if strn A = "234", then lenA = 3) 
		PUSH 200;
		PUSH OFFSET bufA
		PUSH din;
		CALL ReadConsoleA@20

		; get length of outStrnB (EAX)
		PUSH OFFSET outStrnB
		CALL lstrlenA@4
		PUSH 0; 5th parameter of WriteConsoleA@20
		PUSH OFFSET len; 4th
		PUSH EAX; 3rd (length of outStrn)
		PUSH OFFSET outStrnB; 2nd
		PUSH dout; 1st
		CALL WriteConsoleA@20
		
		; get 2st number (string)
		PUSH 0;
		PUSH OFFSET lenB ; numb of entered symbols (for one, if strn A = "234", then lenA = 3) 
		PUSH 200;
		PUSH OFFSET bufB
		PUSH din;
		CALL ReadConsoleA@20
		
		COMMENT !
		---------
			2. Converting strings to decimal numbers
		---------
		!
		
		; A
		MOV ECX, lenA ; save length of A to ECX
		SUB ECX, 2 ; 13 and 0 don’t count
		MOV ESI, OFFSET bufA ; save the beginning of the string to ESI
		XOR EAX, EAX ; make EAX / EBX empty to store sums
		XOR EBX, EBX
		MOV BL, [ESI] ; take the first symbol
		CMP BL, '-'
		JNE CONVERT1_CONTINUE ; if number is positive
		MOV f1, 1 ; A < 0
		INC ESI ; go to the next symbol
		DEC ECX ; dec cycle counter
CONVERT1: 
		MOV BL, [ESI] ; take the next symbol
CONVERT1_CONTINUE:
		CMP BL, '0' ; if our digit is not in [0, 9], then go to ERR	
		JB ERR		 
		CMP BL, '9'
		JA ERR					
		SUB BL, '0' ; sub '0' symbol
		MUL ten ; multiply by 10 (move to next digit)
		ADD EAX, EBX ; add our digit to sum
		INC ESI	; go to next symbol
		LOOP CONVERT1 ; next iteration
		MOV A, EAX
		; B
		MOV ECX, lenB
		SUB ECX, 2
		MOV ESI, OFFSET bufB
		XOR EAX, EAX
		XOR EBX, EBX
		MOV BL, [ESI]
		CMP BL, '-'
		JNE CONVERT2_CONTINUE
		MOV f2, 1
		INC ESI
		DEC ECX
CONVERT2:
		MOV BL, [ESI]
CONVERT2_CONTINUE :
		CMP BL, '0'
		JB ERR
		CMP BL, '9'
		JA ERR
		SUB BL, '0'
		MUL ten
		ADD EAX, EBX
		INC ESI
		LOOP CONVERT2
		MOV B, EAX

		COMMENT !
		---------
			3. Convert A * B to hex
		!
		
		; multiply B (EAX) and A, save result to EAX
		MUL A
		; convert to hex
		XOR ECX, ECX
CONVERT_HEX:
		INC ECX
		DIV hex
		PUSH EDX
		CMP AX, 0
		JE CONVERT_HEX_END 
		JMP CONVERT_HEX
CONVERT_HEX_END:
		; convert to string
		MOV ESI, OFFSET bufAB
GET_HEX_STRING:
		POP EBX
		CMP EBX, 9
		JLE LESS_THEN_10
		ADD EBX, 7 ; ASCII
LESS_THEN_10:
		ADD EBX, '0'
		MOV [ESI], EBX
		INC ESI
		LOOP GET_HEX_STRING
		; display result
		MOV AH, f1
		MOV AL, f2
		CMP AH, AL
		JE POSITIVE
		PUSH 0
		PUSH OFFSET len
		PUSH 1
		PUSH OFFSET minus
		PUSH dout
		CALL WriteConsoleA@20
POSITIVE:
		PUSH OFFSET bufAB
		CALL lstrlenA@4
		PUSH 0
		PUSH OFFSET len
		PUSH EAX
		PUSH OFFSET bufAB
		PUSH dout
		CALL WriteConsoleA@20
		PUSH OFFSET outStrnResult
		CALL lstrlenA@4
		PUSH 0
		PUSH OFFSET len
		PUSH EAX
		PUSH OFFSET outStrnResult
		PUSH dout
		CALL WriteConsoleA@20
		PUSH 0 ; exit code
		CALL ExitProcess@4
ERR:
		; get length of outStrnErr (EAX)
		PUSH OFFSET outStrnErr
		CALL lstrlenA@4
		PUSH 0; 5th parameter of WriteConsoleA@20
		PUSH OFFSET len; 4th
		PUSH EAX ; 3rd (length of outStrn)
		PUSH OFFSET outStrnErr; 2nd
		PUSH dout; 1st
		CALL WriteConsoleA@20
		JMP REENTER
	main ENDP
	END main