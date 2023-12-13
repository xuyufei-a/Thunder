.386
.model flat, stdcall
option casemap: none

; 系统库
include windows.inc
include gdi32.inc
includelib gdi32.lib
include user32.inc
includelib user32.lib
include kernel32.inc
includelib kernel32.lib
include masm32.inc
includelib masm32.lib
include msvcrt.inc
includelib msvcrt.lib
include shell32.inc
includelib shell32.lib
include	 winmm.inc
includelib  winmm.lib

; 自定义库
include thunder.inc

;====================CODE===================
.code
WinMain PROC
	; put locals on stack

	local wc  :WNDCLASSEX
	local msg :MSG
	local wtx :DWORD
	local wty :DWORD
	
	; fill WNDCLASSEX structure with required variables


	; tobedone load a icon for the window
	invoke GetModuleHandle, NULL
	mov hInstance, eax

	invoke LoadIcon, hInstance, 101	; icon ID tobedone
	mov hIcon, eax

	szText szClassName, "thunder_class"

	mov wc.cbSize,			sizeof WNDCLASSEX
	mov wc.style,			CS_HREDRAW or CS_VREDRAW or CS_BYTEALIGNWINDOW
	mov wc.lpfnWndProc,		offset WndProc
	mov wc.cbClsExtra,		NULL
	mov wc.cbWndExtra,		NULL
	m2m wc.hInstance,		hInstance
	mov wc.hbrBackground,	COLOR_BTNFACE+1
	mov wc.lpszMenuName,	NULL
	mov wc.lpszClassName,	offset szClassName
	m2m wc.hIcon,			hIcon
		invoke LoadCursor, NULL, IDC_ARROW
	mov wc.hCursor,			eax
	m2m wc.hIconSm,			hIcon

	invoke RegisterClassEx, ADDR wc

	; centre window at following size
	
	invoke GetSystemMetrics, SM_CXSCREEN
	invoke TopXY, WINDOW_WIDTH, eax
	mov wtx, eax

	invoke GetSystemMetrics, SM_CYSCREEN
	invoke TopXY, WINDOW_HEIGHT, eax
	mov wty, eax

	invoke CreateWindowEx,	WS_EX_LEFT,
							ADDR szClassName,
							ADDR szDisplayName,
							WS_OVERLAPPED or WS_SYSMENU,
							wtx, wty, WINDOW_WIDTH, WINDOW_HEIGHT,
							NULL, NULL,
							hInstance, NULL

	mov hMainWnd, eax 

	invoke ShowWindow, hMainWnd, SW_SHOWNORMAL
	invoke UpdateWindow, hMainWnd


	; loop until postQuitMessage is sent

	StartLoop:
		invoke GetMessage, addr msg, NULL, 0, 0
		cmp eax, 0
		je ExitLoop
		invoke TranslateMessage, ADDR msg
		invoke DispatchMessage, ADDR msg
		jmp StartLoop

	ExitLoop:
		invoke ExitProcess, 0
WinMain ENDP

; ########################################################################
WndProc PROC hWin: DWORD, uMsg: DWORD, wParam: DWORD, lParam: DWORD
	invoke DefWindowProc, hWin, uMsg, wParam, lParam
	ret
	.if gameStatus == GSTATUS_MENU
		invoke MenuProc, hWin, uMsg, wParam, lParam
	.elseif gameStatus == GSTATUS_GAME
		invoke GameProc, hWin, uMsg, wParam, lParam
	.elseif gameStatus == GSTATUS_SUSPEND
		invoke SuspendProc, hWin, uMsg, wParam, lParam
	.endif
	
	ret


WndProc ENDP
; ########################################################################
MenuProc PROC hWin: DWORD, uMsg: DWORD, wParam: DWORD, lParam: DWORD
	




MenuProc ENDP
; ########################################################################
GameProc PROC hWin: DWORD, uMsg: DWORD, wParam: DWORD, lParam: DWORD
	




GameProc ENDP
; ########################################################################
SuspendProc PROC hWin: DWORD, uMsg: DWORD, wParam: DWORD, lParam: DWORD
	
	;.if 
	



SuspendProc ENDP
; ########################################################################

TopXY PROC wDim:DWORD, sDim:DWORD

    shr sDim, 1      ; divide screen dimension by 2
    shr wDim, 1      ; divide window dimension by 2
    mov eax, wDim    ; copy window dimension into eax
    sub sDim, eax    ; sub half win dimension from half screen dimension

    return sDim

TopXY ENDP

; #########################################################################

END WinMain
