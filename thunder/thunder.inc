; =========C prototypes===========
	strlen PROTO C :DWORD

;=========local prototypes========
	WinMain PROTO
	WndProc PROTO :DWORD, :DWORD, :DWORD, :DWORD
    TopXY PROTO   :DWORD, :DWORD

; proc function for different game status
	MenuProc PROTO :DWORD, :DWORD, :DWORD, :DWORD
	GameProc PROTO :DWORD, :DWORD, :DWORD, :DWORD
	SuspendProc PROTO :DWORD, :DWORD, :DWORD, :DWORD
	GameoverProc PROTO :DWORD, :DWORD, :DWORD, :DWORD

;=========four main type funcitons: sound, paint, logic and data structrue========
; function for sound
	EmitSound PROTO 	; parameter is the sound resource id
	ExplosionSound PROTO
; function for painting
	InitDC	PROTO
	DestroyDC PROTO

	DrawBackground PROTO
	DrawPlane PROTO
	DrawBullet PROTO
	DrawExplosion	PROTO
	DrawGameInfo PROTO

	DrawGameScene PROTO
	DrawSuspendScene PROTO
	DrawGameoverScene PROTO
	DrawMenuScene PROTO

; function for logic, such as collision dectection, calculating next position
	; function to generate random number
	Random PROTO :DWORD	; parameter is the limit of random number, return value is the random number
	; function for initailize
	InitGame	PROTO	:DWORD				; pamameter is the number of players(1 or 2)

	; function used when timer expires
	; tool function
	CheckIlligal PROTO :DWORD				; check if the rect is in the window, parameter is the address of the rect
	CheckIntersection PROTO :DWORD, :DWORD	; check if the two rects intersect, parameters are the address of the two rects
	AddNewExplosion PROTO :DWORD            ; parameter is the address of the rect, this function complete the initialization of the explosion and push it into the queue
	ClearKeys		PROTO :DWORD		

	; main function
	SolveCollision PROTO					; remove bullets and planes that collide with others
	CalNextPos	PROTO						; iterate enemy planes queue and bullet queue, cal their next position
	GenerateEnemy PROTO						; generate enemy planes
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



;===========local macros=============

	szText MACRO Name, TEXTEQU: VARARG
		LOCAL	lbl
			jmp lbl
				Name db TEXTEQU, 0
			lbl:
		ENDM

	m2m MACRO M1, M2
		push M2
		pop M1
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
GAME_REFRESH_INTERVAL	EQU		30

; game status

GSTATUS_MENU		EQU		0
GSTATUS_GAME		EQU		1
GSTATUS_SUSPEND		EQU		2
GSTATUS_GAMEOVER	EQU		3

; menu select
P1_MODE				EQU		0
P2_MODE				EQU		1
QUIT_MODE			EQU		2

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
; size of buffer	
BUFFER_SIZE			EQU		1024

; bullet color, notify which camp it belongs
BULLET_COLOR_PLAYER	EQU		0000FF00H
BULLET_COLOR_ENEMY	EQU		000000FFH



; some const for game logic

; num const
MAX_HEALTH				EQU		3

; time const
PLAYER_EMIT_INTERVAL	EQU		10
ENEMY_EMIT_INTERVAL		EQU		100
EXPLOSION_DURATION		EQU		10
ENEMY_INTERVAL			EQU		3
REBIRTH_INTERVAL		EQU		100
FREEZE_INTERVAL			EQU		20


; size const
PLAYER_PLANE_WIDTH		EQU		60
PLAYER_PLANE_HEIGHT		EQU		50

MAX_ENEMY_PLANE_WIDTH	EQU		80
ENEMY_PLANE1_WIDTH		EQU		80
ENEMY_PLANE1_HEIGHT		EQU		64
ENEMY_PLANE2_WIDTH		EQU		60
ENEMY_PLANE2_HEIGHT		EQU		90

BULLET_WIDTH			EQU		5
BULLET_HEIGHT			EQU		10

HEART_WIDTH				EQU		30
HEART_HEIGHT			EQU		30

EPSILON					EQU		7

TEXT_WIDTH				EQU		200
TEXT_HEIGHT				EQU		40

; pos const 

REAL_HEIGHT				EQU		441
REAL_WIDTH				EQU		624
P1_BIRTH_POINT_X		EQU		100
P1_BIRTH_POINT_Y		EQU		REAL_HEIGHT - PLAYER_PLANE_HEIGHT
P2_BIRTH_POINT_X		EQU     450
P2_BIRTH_POINT_Y		EQU		REAL_HEIGHT - PLAYER_PLANE_HEIGHT

; speed const 
SPEED_PLAYER_X			EQU		10
SPEED_PLAYER_Y			EQU		0
SPEED_ENEMY_X			EQU		0
SPEED_ENEMY_Y			EQU		2
SPEED_PLAYER_BULLET		EQU		10
SPEED_ENEMY_BULLET		EQU		5


; num const for generate random number
RANDOM_A				EQU		1664525
RANDOM_C				EQU		11

;=========local struct define========
MyRect STRUCT 
; position
	x		SDWORD ?
	y		SDWORD ?
; size
	lx		SDWORD ?
	ly		SDWORD ?
MyRect ENDS

Bullet STRUCT
; position
	rect		MyRect <>
; speed
	xSpeed		SDWORD ?
	ySpeed		SDWORD ?
; color, up to which camp it belongs
	color		DWORD ?
Bullet ENDS

Plane STRUCT
; position
	rect		MyRect <>
; speed
	xSpeed		SDWORD ?
	ySpeed		SDWORD ?
; bmpimage
	hDcBmp		DWORD ?
	hDcBmpMask	DWORD ?
	lx			SDWORD ?
	ly			SDWORD ?
; the countdown for next emit bullet
	nextEmitCountdown	SDWORD ?
Plane ENDS
		
PlayerPlane STRUCT
	plane		Plane <>
	health		SDWORD ?
	rebirthDuration	SDWORD ?
PlayerPlane ENDS

Explosion STRUCT
; position 
	rect		MyRect <>
; bmpimage
	hDcBmp		DWORD ?
	hDcBmpMask	DWORD ?
	lx			SDWORD ?
	ly			SDWORD ?
; remianing duration
	duration	SDWORD ?
Explosion ENDS

; ===================data========================
.data 

hInstance		DWORD ?	; 创建当前进程的文件的句柄
hMainWnd		DWORD ? ; 窗口的句柄

gameStatus		DWORD GSTATUS_MENU ; 当前游戏所处的状态


; game resource handles 
hIcon				DWORD ?	; 当前窗口的图标
hDc					DWORD ?	; 当前窗口的设备环境
hBmp				DWORD ?
hMemDc				DWORD ? ; 内存设备环境
hDcBlack			DWORD ? ; a black background
hDcBackground		DWORD ?
hDcExplosion1		DWORD ?
hDcExplosion1Mask	DWORD ?
hDcExplosion2		DWORD ?
hDcExplosion2Mask	DWORD ?
hDcExplosion3		DWORD ?
hDcExplosion3Mask	DWORD ?
hDcPlayerPlane1		DWORD ?
hDcPlayerPlane1Mask	DWORD ?
hDcPlayerPlane2		DWORD ?
hDcPlayerPlane2Mask	DWORD ?
hDcEnemyPlane1		DWORD ?
hDcEnemyPlane1Mask	DWORD ?
hDcEnemyPlane2		DWORD ?
hDcEnemyPlane2Mask	DWORD ?
hDcHeart			DWORD ?
hDcHeartMask		DWORD ?
hFont50				DWORD ?
hFont30				DWORD ?
hFont20				DWORD ?

; circular queue for bullets and planes
bulletQueue			Bullet QUEUE_SIZE dup(<>)
bulletQueueHead		DWORD ?
bulletQueueTail		DWORD ?
bulletQueueSize		DWORD ?
planeQueue			Plane QUEUE_SIZE dup(<>)   ; enemy planes
planeQueueHead		DWORD ?
planeQueueTail		DWORD ?
planeQueueSize		DWORD ?
explosionQueue		Explosion QUEUE_SIZE dup(<>)
explosionQueueHead	DWORD ?
explosionQueueTail	DWORD ?
explosionQueueSize	DWORD ?

; player planes
p1Plane			PlayerPlane <>
p2Plane			PlayerPlane <>

; variables for interaction
aKeyHold			DWORD ?
dKeyHold			DWORD ?
spacebarKeyHold		DWORD ?
leftKeyHold			DWORD ?
rightKeyHold		DWORD ?
enterKeyHold		DWORD ?


; random number seed
randomSeed			DWORD ?


; game info
enemyCountdown		DWORD ?
score				DWORD ?	

; text strings
szDisplayName	DB "Thunder"
stringBuffer	DB BUFFER_SIZE dup(?)
formatNumber	DB "%d", 0
formatGameover  DB "Game over, your score is %d.", 0
hintText		DB "Press q to quit.", 0
HINT_TEXT_LEN	EQU $ - hintText
pauseText		DB "Pause, press q to quit, press c to continue", 0
PAUSE_TEXT_LEN	EQU $ - pauseText

menuText		DB "Thunder", 0 
MENU_TEXT_LEN	EQU $ - menuText
p1Text			DB "1 player ", 0
P1_TEXT_LEN		EQU $ - p1Text
p2Text			DB "2 players", 0
P2_TEXT_LEN		EQU $ - p2Text
quitText		DB "Quit", 0
QUIT_TEXT_LEN	EQU $ - quitText

selectMenu		SDWORD P1_MODE
