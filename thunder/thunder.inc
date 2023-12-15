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
	InitDC	PROTO
	DeleteDC PROTO
	DrawPlane PROTO
	DrawBullet PROTO
	DrawExplosion	PROTO
	DrawBackground PROTO
	DrawGameScene PROTO

; function for logic, such as collision dectection, calculating next position
	; function for initailize
	InitGame	PROTO	:DWORD				; pamameter is the number of players(1 or 2)
	; function used when timer expires
	CheckIlligal PROTO :DWORD				; check if the rect is in the window, parameter is the address of the rect
	CheckIntersection PROTO :DOWRD, :DWORD	; check if the two rects intersect, parameters are the address of the two rects
	SolveCollision PROTO					; remove bullets and planes that collide with others
	CalNextPos	PROTO						; iterate enemy planes queue and bullet queue, cal their next position

	; function used for iteract
	EmitBullet PROTO						; the pamameter notify which player
	
	
	; function to manipulate circular queue
	InitQueue PROTO
	PushBullet PROTO :DWORD
	PopBullet PROTO
	GetBulletFront PROTO
	PushPlane PROTO :DWORD
	PopPlane PROTO
	GetPlaneFront PROTO
	PushExplosion PROTO :DWORD
	PopExplosion PROTO
	GetExplosionFront PROTO

;=========local struct define========
MyRect STRUCT 
; position
	x		SWORD ?
	y		SWORD ?
; size
	width	SWORD ?
	height	SWORD ?
MyRect ENDS

Bullet STRUCT
; position
	rect		MyRect <>
; speed
	xSpeed		SWORD ?
	ySpeed		SWORD ?
; color, up to which camp it belongs
	color		D	WORD ?
Bullet ENDS

Plane STRUCT
; position
	rect		MyRect <>
; speed
	xSpeed		SWORD ?
	ySpeed		SWORD ?
; bmpimage
	hDcBmp		DWORD ?
	hDcBmpMask	DWORD ?
	width		SWORD ?
	height		SWORD ?
; the countdown for next emit bullet
	nextEmitCountdown	SWORD ?
Plane ENDS
		
PlayerPlane STRUCT
	plane		Plane <>
	health		DWORD ?
PlayerPlane ENDS

Explosion STRUCT
; position 
	rect		MyRect <>
; bmpimage
	hDcBmp		DWORD ?
	hDcBmpMask	DWROD ?
; remianing duration
	duration	DWORD ?
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


; bullet color, notify which camp it belongs
BULLET_COLOR_PLAYER	EQU		0x000000FF		 
BULLET_COLOR_ENEMY	EQU		0x00FF0000 



; some const for game logic

; time const
PLAYER_EMIT_INTERVAL	EQU		10
ENEMY_EMIT_INTERVAL		EQU		100
EXPLOSION_DURATION		EQU		10


; size const
PLAYER_PLANE_WIDTH		EQU		50


BULLET_WIDTH			EQU		5
BULLET_HEIGHT			EQU		10


; pos const 

P1_BIRTH_POINT_X		EQU		100
P2_BIRTH_POINT_X		EQU     200

.data 
szDisplayName	DB "Thunder"

hInstance		DWORD ?	; 创建当前进程的文件的句柄
hMainWnd		DWORD ? ; 窗口的句柄

gameStatus		DWORD 1 ; 当前游戏所处的状态


; game resource handles 
hIcon				DWORD ?	; 当前窗口的图标
hDc					DWORD ?	; 当前窗口的设备环境
hBmp				DWORD ?
hMemDc				DWORD ? ; 内存设备环境
hDcExplosion1		DWORD ?
hDcExplosion1Mask	DWORD ?
hDcPlayerPlane1		DWORD ?
hDcPlayerPlane1Mask	DWORD ?
hDcPlayerPlane2		DWORD ?
hDcPlayerPlane2Mask	DWORD ?
hDcEnemyPlane1		DWORD ?
hDcEnemyPlane1Mask	DWORD ?

; circular queue for bullets and planes
bullets				Bullet QUEUE_SIZE dup(<>)
bulletQueueHead		DWORD ?
bulletQueueTail		DWORD ?
bulletQueueSize		DWORD ?
planes				Plane QUEUE_SIZE dup(<>)   ; enemy planes
planeQueueHead		DWORD ?
planeQueueTail		DWORD ?
planeQueueSize		DWORD ?
explosions			Explosion QUEUE_SIZE dup(<>)
explosionQueueHead	DWORD ?
explosionQueueTail	DWORD ?
explosionQueueSize	DWORD ?

; player planes
p1Plane			PlayerPlane <>
p2Plane			PlayerPlane <>

; variables for interaction
aKeyHold			DWORD 0
dKeyHold			DWORD 0
spacebarKeyHold		DWORD 0
leftKeyHold			DOWRD 0
rightKeyHold		DOWRD 0
enterKeyHold		DWORD 0
