TITLE Multiplication

COMMENT !
	This program multiplies two integers (input in decimal, output in hex).
	Alexander Zhilyakov (http://56th.ru/), 2015
!

.386 ; This directive tells assembly to use Intel 80386 instruction set.
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
	instrn DB "input (in decimal)", 13, 10, 0
	outstrn DB "output (in hex)", 13, 10, 0

.DATA
	; Ininitialized data of the program.
	din DD ? ; input descriptor, 4 bytes
	dout DD ?
	len DD ? ; numb of output symbols

.CODE ; Section for code.
	main PROC
		; get input descriptor
		PUSH - 10
		CALL GetStdHandle@4
		MOV din, EAX

		; get output descriptor
		PUSH - 11
		CALL GetStdHandle@4
		MOV dout, EAX

		; get length of instrn(EAX)
		PUSH OFFSET instrn
		CALL lstrlenA@4

		PUSH 0; 5th parameter of WriteConsoleA@20
		PUSH OFFSET len; 4th
		PUSH EAX; 3rd(length of instrn)
		PUSH OFFSET instrn; 2nd
		PUSH dout; 1st
		CALL WriteConsoleA@20

		PUSH 0 ; exit code
		CALL ExitProcess@4
		main ENDP
	END main