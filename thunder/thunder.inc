

;=========local prototypes========
	WinMain PROTO
	WndProc PROTO :DWORD, :DWORD, :DWORD, :DWORD
    TopXY PROTO   :DWORD, :DWORD

; proc function for different game status
	MenuProc PROTO :DWORD, :DWORD, :DWORD, :DWORD
	GameProc PROTO :DWORD, :DWORD, :DWORD, :DWORD
	SuspendProc PROTO :DWORD, :DWORD, :DWORD, :DWORD


; function for painting





; function for logic, such as collision detection, calulating next position

;===========local macros=============

	szText MACRO Name, TEXTEQU: VARARG
		LOCAL	lbl
			jmp lbl
				Name db TEXTEQU, 0
			lbl:
		ENDM

	m2m MACRO M1, M2
		push M2
		push M1
	ENDM

	return MACRO arg
		mov eax, arg
		ret
	ENDM
	

;=======local const=========

WINDOW_WIDTH		EQU		640
WINDOW_HEIGHT		EQU		480

; game status

GSTATUS_MENU		EQU		0
GSTATUS_GAME		EQU		1
GSTATUS_SUSPEND		EQU		2


; key value

KEY_C				EQU		67
KEY_Q				EQU		81
KEY_ESC				EQU		27
KEY_UPARROW			EQU		38
KEY_DOWNARROW		EQU		40
KEY_LEFTARROW		EQU		37
KEY_RIGHTARROW		EQU		39
KEY_SPACEBAR		EQU		32
KEY_A				EQU		65
KEY_S				EQU		83
KEY_D				EQU		68
KEY_W				EQU		87
KEY_ENTER			EQU		13




.data 
hInstance		DWORD ?	; 创建当前进程的文件的句柄
hIcon			DWORD ?	; 当前窗口的图标
hMainWnd		DWORD ? ; 窗口的句柄


gameStatus		DWORD 1 ; 当前游戏所处的状态

; const 
szDisplayName	DB "Thunder"
