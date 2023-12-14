;=========local prototypes========
	WinMain PROTO
	WndProc PROTO :DWORD, :DWORD, :DWORD, :DWORD
    TopXY PROTO   :DWORD, :DWORD

; proc function for different game status
	MenuProc PROTO :DWORD, :DWORD, :DWORD, :DWORD
	GameProc PROTO :DWORD, :DWORD, :DWORD, :DWORD
	SuspendProc PROTO :DWORD, :DWORD, :DWORD, :DWORD


;-------------function for GSTATUS_GAME status--------------
; function for painting
	DrawPlane PROTO :DWORD
	DrawBullet PROTO :DWORD
	DrawExplosion	PROTO: DWORD
	DrawBackground PROTO
	DrawGameScene PROTO

; function for logic, such as collision dectection, calculating next position
	; function used when timer expires
	CheckIlligal PROTO :RECT			; check if the rect is in the window
	CheckIntersection PROTO :RECT, :RECT
	SolveCollision PROTO				; remove bullets and planes that collide with others
	CalNextPos	PROTO					; iterate enemy planes queue and bullet queue, cal their next position

	; function used for iteract
	EmitBullet PROTO :DWORD				; the pamameter notify which player
	MovPlayerPlane PROTO :DWORD, :DWORD  ; the pamameters are PlayerPlane address and direction(left or right)	
	
	
	


;=========local struct define========
Bullet STRUCT
; position
    x			DWORD ?
	y			DWORD ?
	rect		RECT <>
; speed
	xSpeed		DWORD ?
	ySpeed		DWORD ?
; color, up to which camp it belongs
	color		DWORD ?
Bullet ENDS

Plane STRUCT
; position
	x			DWORD ?
	y			DWORD ?
	rect		RECT <>
; speed
	xSpeed		DWORD ?
	ySpeed		DWORD ?
; bmpimage
	hBmp		DWORD ?
	hBmpMask	DWORD ?
Plane ENDS
		
PlayerPlane STRUCT
	plane		Plane <>
	health		DWORD ?
PlayerPlane ENDS

Explosion STRUCT
; position 
	rect		RECT <>
; bmpimage
	hBmp		DWORD ?
	hBmpMask	DWORD ?
Explosion ENDS

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
True				EQU		1
False				EQU		0


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


; size of circular queue
QUEUE_SIZE			EQU		1024


.data 
szDisplayName	DB "Thunder"

hInstance		DWORD ?	; 创建当前进程的文件的句柄
hIcon			DWORD ?	; 当前窗口的图标
hMainWnd		DWORD ? ; 窗口的句柄

gameStatus		DWORD 1 ; 当前游戏所处的状态

; circular queue for bullets and planes
bullets		    Bullet QUEUE_SIZE dup(<>)
bulletQueueHead	DWORD ?
bulletQueueTail DWORD ?
planes			Plane QUEUE_SIZE dup(<>)   ; enemy planes
planeQueueHead	DWORD ?
planeQueueTail  DWORD ?

; player planes
p1Plane			PlayerPlane <>
p2Plane			PlayerPlane <>

; variables for interaction
aKeyHold			DWORD 0
dKeyHold			DWORD 0
spacebarKeyHold		DWORD 0
upKeyHold			DOWRD 0
downKeyHold			DOWRD 0
enterKeyHold		DWORD 0
