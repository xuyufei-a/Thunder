.386
.model flat, stdcall
option casemap: none

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
	ret
WinMain ENDP

; ########################################################################
WndProc PROC hWin: DWORD, uMsg: DWORD, wParam: DWORD, lParam: DWORD
	.if gameStatus == GSTATUS_MENU
		invoke MenuProc, hWin, uMsg, wParam, lParam
	.elseif gameStatus == GSTATUS_GAME
		invoke GameProc, hWin, uMsg, wParam, lParam
	.elseif gameStatus == GSTATUS_SUSPEND
		invoke SuspendProc, hWin, uMsg, wParam, lParam
	.endif
		
	; tobedone maybe close message should be deal in this function
	.if uMsg == WM_DESTROY
		invoke PostQuitMessage, 0
		invoke DestroyDC	
	.endif
	invoke DefWindowProc, hWin, uMsg, wParam, lParam

	ret
WndProc ENDP
; ########################################################################
MenuProc PROC hWin: DWORD, uMsg: DWORD, wParam: DWORD, lParam: DWORD
	.if uMsg == WM_CREATE
		invoke InitDC
		invoke SetTimer, hMainWnd, 1, GAME_REFRESH_INTERVAL, NULL

		; tobedone  only game part finished, so start game when creating 
		mov gameStatus, GSTATUS_GAME
		invoke InitGame, 2

	.elseif uMsg == WM_KEYDOWN

	.elseif uMsg == WM_CLOSE

	.elseif uMsg == WM_DESTROY
		
	.elseif uMsg == WM_PAINT

	.endif
	ret
MenuProc ENDP
; ########################################################################
GameProc PROC hWin: DWORD, uMsg: DWORD, wParam: DWORD, lParam: DWORD
	
	.if uMsg == WM_KEYDOWN
		.if wParam == KEY_A
			mov aKeyHold, True
		.elseif wParam == KEY_D
			mov dKeyHold, True
		.elseif wParam == KEY_LEFTARROW
		    mov leftKeyHold, True
		.elseif wParam == KEY_RIGHTARROW
			mov rightKeyHold, True	
		.elseif wParam == KEY_SPACEBAR
			mov spaceKeyHold, True
		.elseif wParam == KEY_ENTER
			mov enterKeyHold, True
		.elseif wParam == KEY_ESC
			mov gameStatus, GSTATUS_SUSPEND
		.endif
	.elseif uMsg == WM_KEYUP
		.if wParam == KEY_A
			mov aKeyHold, False
		.elseif wParam == KEY_D
			mov dKeyHold, False
		.elseif wParam == KEY_LEFTARROW
			mov leftKeyHold, False
		.elseif wParam == KEY_RIGHTARROW
			mov rightKeyHold, False
		.elseif wParam == KEY_SPACEBAR
			mov spaceKeyHold, False
		.elseif wParam == KEY_ENTER
			mov enterKeyHold, False
		.endif
	.elseif uMsg == WM_PAINT
		; tobedone how to paint the game
		
		invoke DrawGameScene
	.elseif uMsg == WM_CLOSE


	.elseif uMsg == WM_DESTROY
		invoke PostQuitMessage, NULL

		; tobedone del created objects
	.elseif uMsg == WM_TIMER
		invoke SolveCollision
		invoke CalNextPos
		invoke EmitBullet
	.endif
				
	invoke DefWindowProc, hWin, uMsg, wParam, lParam
	ret
GameProc ENDP
; ########################################################################
InitGame PROC playerCount: DWORD
	invoke InitQueue	
	; init player 1	
	mov p1Plane.plane.rect.x, P1_BIRTH_POINT_X
	mov p1Plane.plane.rect.y, P1_BIRTH_POINT_Y
	mov p1Plane.plane.rect.width, PLAYER_PLANE_WIDTH
	mov p1Plane.plane.rect.height, PLAYER_PLANE_HEIGHT
	
	m2m p1Plane.plane.hDcBmp, hDcPlayerPlane1
	m2m p1Plane.plane.hDcBmpMask, hDcPlayerPlane1Mask
	mov p1Plane.plane.width, BMP_SIZE_PLAYER_WIDTH
	mov p1Plane.plane.height, BMP_SIZE_PLAYER_HEIGHT
	mov p1Plane.plane.nextEmitCountdown, PLAYER_EMIT_INTERVAL

	mov p1Plane.health, MAX_HEALTH
	
	; init player2
	mov p2Plane.plane.rect.x, P2_BIRTH_POINT_X
	mov p2Plane.plane.rect.y, P2_BIRTH_POINT_Y
	mov p2Plane.plane.rect.width, PLAYER_PLANE_WIDTH
	mov p2Plane.plane.rect.height, PLAYER_PLANE_HEIGHT
	
	m2m p2Plane.plane.hDcBmp, hDcPlayerPlane2
	m2m p2Plane.plane.hDcBmpMask, hDcPlayerPlane2Mask
	mov p2Plane.plane.width, BMP_SIZE_PLAYER_WIDTH
	mov p2Plane.plane.height, BMP_SIZE_PLAYER_HEIGHT
	mov p2Plane.plane.nextEmitCountdown, PLAYER_EMIT_INTERVAL

	.if playerCount > 1
		mov p2Plane.health, MAX_HEALTH
	.else
		mov p2Plane.health, 0
	.endif
	ret
InitGame ENDP
; ########################################################################
EmitBullet PROC
	local planeCount : DWORD
	local pPlane	 : DWORD
	local pBullet	 : DWORD

	; enemy planes emit bullets
	m2m planeCount, planeQueueSize
	.while planeCount > 0
		invoke GetPlaneFront
		mov pPlane, eax
		invoke PopPlane

		mov eax, [pPlane+PlayerPlane.Plane.nextEmitCountdown]
		dec eax
		.if eax == 0
			; tobedone init bullet position
			m2m [pBullet+Bullet.MyRect.x], [pPlane+Plane.MyRect.x]
			m2m [pBullet+Bullet.MyRect.y], [pPlane+Plane.MyRect.y]

			mov [pBullet+Bullet.MyRect.width], BULLET_WIDTH
			mov [pBullet+Bullet.MyRect.height], BULLET_HEIGHT
			mov [pBullet+Bullet.xSpeed], 0
			mov [pBullet+Bullet.ySpeed], SPEED_ENEMY_BULLET
			mov [pBullet+Bullet.color], BULLET_COLOR_ENEMY
			invoke PushBullet, pBullet

			mov eax, ENEMY_EMIT_INTERVAL
		.endif
		mov [pPlane+PlayerPlane.Plane.nextEmitCountdown], eax]	
	.endw

	; player planes emit bullets
	.if DWORD PTR [p1Plane+playerPlane.health] > 0
		dec [p1Plane+PlayerPlane.Plane.nextEmitCountdown]
		.if spacebarKeyHold == True
		.if DWORD PTR [p1Plane+PlayerPlane.Plane.nextEmitCountdown] <= 0
			; tobedone init bullet position
			m2m [pBullet+Bullet.MyRect.x], [p1Plane+PlayerPlane.MyRect.x]
			m2m [pBullet+Bullet.MyRect.y], [p1Plane+PlayerPlane.MyRect.y]

			mov [pBullet+Bullet.MyRect.width], BULLET_WIDTH
			mov [pBullet+Bullet.MyRect.height], BULLET_HEIGHT
			mov [pBullet+Bullet.xSpeed], 0
			mov [pBullet+Bullet.ySpeed], -SPEED_PLAYER_BULLET
			mov [pBullet+Bullet.color], BULLET_COLOR_PLAYER
			invoke PushBullet, pBullet
			
			mov DWORD PTR [p1Plane+PlayerPlane.Plane.nextEmitCountdown], PLAYER_EMIT_INTERVAL]
		.endif
		.endif
	.endif
	
	.if DWORD PTR [p2Plane+playerPlane.health] > 0
		dec [p2Plane+PlayerPlane.Plane.nextEmitCountdown]
		.if enterKeyHold == True
		.if DWORD PTR [p2Plane+PlayerPlane.Plane.nextEmitCountdown] <= 0
			; tobedone init bullet position
			m2m [pBullet+Bullet.MyRect.x], [p2Plane+PlayerPlane.MyRect.x]
			m2m [pBullet+Bullet.MyRect.y], [p2Plane+PlayerPlane.MyRect.y]

			mov [pBullet+Bullet.MyRect.width], BULLET_WIDTH
			mov [pBullet+Bullet.MyRect.height], BULLET_HEIGHT
			mov [pBullet+Bullet.xSpeed], 0
			mov [pBullet+Bullet.ySpeed], -BULLET_SPEED
			mov [pBullet+Bullet.color], BULLET_COLOR_PLAYER
			invoke PushBullet, pBullet
			
			mov DWORD PTR [p2Plane+PlayerPlane.Plane.nextEmitCountdown], PLAYER_EMIT_INTERVAL]
		.endif
		.endif
	.endif
	ret
EmitBullet ENDP
; ########################################################################
CheckIntersection PROC pRect1: DWORD, pRect2: DWORD
	local l1	: SWORD
	local r1	: SWORD
	local t1	: SWORD
	local b1	: SWORD
	local l2	: SWORD
	local r2	: SWORD
	local t2	: SWORD
	local b2	: SWORD

	mov eax, True

	mov si, SWORD PTR [pRect1+MyRect.x]
	mov di, SWORD PTR [pRect1+MyRect.y]
	mov l1, si
	mov t1, di
	add si, SWORD PTR [pRect1+MyRect.width]
	add di, SWORD PTR [pRect1+MyRect.height]
	mov r1, si
	mov b1, di

	mov si, SWORD PTR [pRect2+MyRect.x]
	mov di, SWORD PTR [pRect2+MyRect.y]
	mov l2, si
	mov t2, di
	add si, SWORD PTR [pRect2+MyRect.width]
	add di, SWORD PTR [pRect2+MyRect.height]
	mov r2, si
	mov b2, di

	mov si, l1
	mov di, r2
	sub si, di
	.if si > 0
		mov eax, False
	.endif

	mov si, l2
	mov di, r1
	sub si, di
	.if si > 0
		mov eax, False
	.endif

	mov si, t1
	mov di, b2
	sub si, di
	.if si > 0
		mov eax, False
	.endif

	mov si, t2
	mov di, b1
	sub si, di
	.if si > 0
		mov eax, False
	.endif
	ret
CheckIntersection ENDP
; ########################################################################
SolveCollision PROC
; -----------------------
; solve collision between bullets and planes, enemy planes and player planes

; iterate the bullets queue and check if there is any collision beteen the plane
; if the bullet belones to the player, then check if there is any collision between
; the enemy plane and the bullet; if the bullet belongs to the enemy, then check if there is any
; collision between the player plane and bullet
; if there is a collision, then delete the bullet and the plane,
; and add an explosion to the corresponding place

	local bulletsCount	: DWORD
	local planesCount	: DWORD
	local pBullet		: DWORD
	local pPlane		: DWORD
	local bulletColor   : WORD
	local flag 		    : WORD

	m2m bulletsCount, bulletQueueSize

	.while bulletsCount > 0
		; get the bullet at the queue front
		invoke GetBulletFront
		mov pBullet, eax
		invoke PopBullet
		m2m bulletColor, DWORD PTR [pBullet+Bullet.color]
		mov flag, False									; flag to indicate if the bullet is deleted
		

		; iterate the planes and check collision
		.if bulletColor == BULLET_COLOR_PLAYER			; bullet belongs to player

			m2m planesCount, planeQueueSize
			.while planesCount > 0
				invoke GetPlaneFront
				mov pPlane, eax
				invoke PopPlane

				invoke CheckIntersection, pBullet, pPlane
				.if eax == True
					invoke PushExplosion, pPlane
					mov flag, True	
					; tobedone add score
				.endif

				.if flag == False
					invoke PushPlane, pPlane
				.endif 

				.break .if flag == True					; bullet can only hit one plane
				dec planesCount
			.endw
		.elseif bulletColor == BULLET_COLOR_ENEMY
			m2m pPlane, offset p1Plane
			
			.if flag == True
			    jmp @F
			.endif
			mov eax, [pPlane+PlayerPlane.health]
			.if eax == 0
			    jmp @F
			.endif

			invoke CheckIntersection, pBullet, pPlane	
			.if eax == True
				invoke PushExplosion, pPlane
				mov flag, True
				dec [pPlane+PlayerPlane.health]
				; tobedone relocate the rebirth point
				mov [pPlane+PlayerPlane.Plane.MyRect.x], P1_BIRTH_POINT_X
			.endif
		@@:
			m2m pPlane, offset p2Plane
			
			.if flag == True
			    jmp @F
			.endif
			mov eax, [pPlane+PlayerPlane.health]
			.if eax == 0
			    jmp @F
			.endif

			invoke CheckIntersection, pBullet, pPlane	
			.if eax == True
				invoke PushExplosion, pPlane
				mov flag, True
				dec [pPlane+PlayerPlane.health]
				mov [pPlane+PlayerPlane.Plane.MyRect.x], P2_BIRTH_POINT_X
			.endif
		@@:
		.endif

		; if there is no collison, push the bullet back
		.if flag == False
			invoke PushBullet, pBullet
		.endif 
		dec bulletsCount
	.endw

	ret
SolveCollision ENDP
; ########################################################################
CheckIllegal PROC pRect: DWORD
	mov eax, True
	mov si, SWORD PTR [pRect+MyRect.x]
	mov di, SWORD PTR [pRect+MyRect.y]
	
	.if si < 0
		mov eax, False
	.elseif di < 0
		mov eax, False
	.endif

	add si, WORD PTR [pRect+MyRect.width]
	add di, WORD PTR [pRect+MyRect.height]

	.if si > WINDOW_WIDTH
		mov eax, False
	.elseif di > WINDOW_HEIGHT
		mov eax, False
	.endif

	ret
CheckIllegal ENDP
; ########################################################################
CalNextPos PROC
	local bulletsCount	: DWORD	
	local planesCount	: DWORD
	local pBullet		: DWORD
	local pPlane		: DWORD

	m2m bulletsCount, bulletQueueSize
	m2m planesCount, planeQueueSize

	; loop iterate all the bullets in the circular queue
	.while bulletsCount > 0
		invoke GetBulletFront
		mov pBullet, eax
		invoke PopBullet

		mov ax, SWORD PTR [pBullet+Bullet.rect.x]
		add ax, SWORD PTR [pBullet+Bullet.xSpeed]
		mov SWORD PTR [pBullet+Bullet.rect.x], ax
		mov ax, SWORD PTR [pBullet+Bullet.rect.y]
		add ax, SWORD PTR [pBullet+Bullet.ySpeed]
		mov SWORD PTR [pBullet+Bullet.rect.y], ax
		invoke CheckIllegal, pBullet
		.if eax == True
			invoke PushBullet, pBullet
		.endif

		dec bulletsCount
	.endw

	; loop iterate all the planes in the circular queue
	.while planesCount > 0
		invoke GetPlaneFront
		mov pPlane, eax
		invoke PopPlane

		mov ax, SWORD PTR [pPlane+Plane.rect.x]
		add ax, SWORD PTR [pPlane+Plane.xSpeed]
		mov SWORD PTR [pPlane+Plane.rect.x], ax
		mov ax, SWORD PTR [pPlane+Plane.rect.y]
		add ax, SWORD PTR [pPlane+Plane.ySpeed]
		mov SWORD PTR [pPlane+Plane.rect.y], ax
		invoke CheckIllegal, pPlane
		.if eax == True
			invoke PushPlane, pPlane
		.endif

		dec planesCount
	.endw

	; cal player plane's next position
	
	.if aKeyHold == True
		mov ax, SWORD PTR [p1Plane+PlayerPlane.rect.x]
		sub ax, SWORD PTR [p1Plane+PlayerPlane.plane.xSpeed]
		.if ax < 0
			mov ax, 0
		.endif
		mov SWORD PTR [p1Plane+PlayerPlane.rect.x], ax
	.endif
	
	.if dKeyHold == True
		mov ax, SWORD PTR [p1Plane+PlayerPlane.rect.x]
		add ax, SWORD PTR [p1Plane+PlayerPlane.plane.xSpeed]
		.if ax + PLAYER_PLANE_WIDTH > WINDOW_WIDTH
			mov ax, WINDOW_WIDTH - PLAYER_PLANE_WIDTH
		.endif
		mov SWORD PTR [p1Plane+PlayerPlane.rect.x], ax
	.endif
	; tobedone unknown bug for different size hint if I don't specify the size of the variable
	.if leftKeyHold == True
		mov ax, SWORD PTR [p2Plane+PlayerPlane.rect.x]
		sub ax, SWORD PTR [p2Plane+PlayerPlane.plane.xSpeed]
		.if ax < 0
			mov ax, 0
		.endif
		mov SWORD PTR [p2Plane+PlayerPlane.rect.x], ax
	.endif

	.if rightKeyHold == True
		mov ax, SWORD PTR [p2Plane+PlayerPlane.rect.x]
		add ax, SWORD PTR [p2Plane+PlayerPlane.plane.xSpeed]
		.if ax + PLAYER_PLANE_WIDTH > WINDOW_WIDTH
			mov ax, WINDOW_WIDTH - PLAYER_PLANE_WIDTH
		.endif
		mov SWORD PTR [p2Plane+PlayerPlane.rect.x], ax
	.endif
	ret
CalNextPos ENDP
; ########################################################################
SuspendProc PROC hWin: DWORD, uMsg: DWORD, wParam: DWORD, lParam: DWORD
	
	



SuspendProc ENDP
; ########################################################################
InitQueue PROC
	mov bulletQueueHead, 0
	mov bulletQueueTail, 0
	mov bulletQueueSize, 0
	mov planeQueueHead, 0
	mov planeQueueTail, 0
	mov planeQueueSize, 0
	mov explosionQueueHead, 0
	mov explosionQueueTail, 0
	mov explosionQueueSize, 0
	ret
InitQueue ENDP
; ########################################################################
PushBullet PROC pBullet:DWORD
	.if bulletQueueSize == QUEUE_SIZE
		ret
	.endif

	; move the source ptr to esi and the destination ptr to edi
	mov eax, bulletQueueTail
	mov ecx, sizeof Bullet
	mul ecx
	add eax, offset bulletQueue

	; use rep movsb to copy the bullet to the queue
	mov esi, pBullet
	mov edi, eax
	cld
	rep movsb
	
	; update the tail and size
	inc bulletQueueSize
	inc bulletQueueTail
	.if bulletQueueTail == QUEUE_SIZE
		mov bulletQueueTail, 0
	.endif
	ret
PushBullet ENDP
; ########################################################################
PopBullet PROC
	.if bulletQueueSize == 0
		ret
	.endif
	
	dec bulletQueueSize
	inc bulletQueueHead
	.if bulletQueueHead == QUEUE_SIZE
		mov bulletQueueHead, 0
	.endif
	ret
PopBullet ENDP
; ########################################################################
GetBulletFront PROC
    ;-------------warning-----------------
	; this function will not check if the queue is empty

	mov eax, bulletQueueHead
	mov ecx, sizeof Bullet
	mul ecx
	add eax, offset bulletQueue
	ret
GetBulletFront ENDP
; ########################################################################
PushPlane PROC pPlane:DWORD
	.if planeQueueSize == QUEUE_SIZE
		ret
	.endif

	; move the source ptr to esi and the destination ptr to edi
	mov eax, planeQueueTail
	mov ecx, sizeof Plane
	mul ecx
	add eax, offset planeQueue

	; use rep movsb to copy the plane to the queue
	mov esi, pPlane
	mov edi, eax
	cld
	rep movsb
	
	; update the tail and size
	inc planeQueueSize
	inc planeQueueTail
	.if planeQueueTail == QUEUE_SIZE
		mov planeQueueTail, 0
	.endif
	ret
PushPlane ENDP
; ########################################################################
PopPlane PROC
	.if planeQueueSize == 0
		ret
	.endif
	
	dec planeQueueSize
	inc planeQueueHead
	.if planeQueueHead == QUEUE_SIZE
		mov planeQueueHead, 0
	.endif
	ret
PopPlane ENDP
; ########################################################################
GetPlaneFront PROC
	;-------------warning-----------------
	; this function will not check if the queue is empty

	mov eax, planeQueueHead
	mov ecx, sizeof Plane
	mul ecx
	add eax, offset planeQueue
	ret
GetPlaneFront ENDP
; ########################################################################
PushExplosion PROC pRect:DWORD
	.if explosionQueueSize == QUEUE_SIZE
		ret
	.endif

	; move the source ptr to esi and the destination ptr to edi
	mov eax, explosionQueueTail
	mov ecx, sizeof Explosion
	mul ecx
	add eax, offset explosionQueue

	; init duration for a new explosion
	mov DWORD PTR [eax+Explosion.duration], EXPLOSION_DURATION

	; use rep movsb to copy the rect to the queue
	mov ecx, sizeof MyRect
	mov esi, pRect
	mov edi, eax
	cld
	rep movsb
	
	; update the tail and size
	inc explosionQueueSize
	inc explosionQueueTail
	.if explosionQueueTail == QUEUE_SIZE
		mov explosionQueueTail, 0
	.endif
	ret
PushExplosion ENDP
; ########################################################################
PopExplosion PROC
	.if explosionQueueSize == 0
		ret
	.endif
	
	dec explosionQueueSize
	inc explosionQueueHead
	.if explosionQueueHead == QUEUE_SIZE
		mov explosionQueueHead, 0
	.endif
	ret
PopExplosion ENDP
; ########################################################################
GetExplosionFront PROC
	;-------------warning-----------------
	; this function will not check if the queue is empty

	mov eax, explosionQueueHead
	mov ecx, sizeof Explosion
	mul ecx
	add eax, offset explosionQueue
	ret
GetExplosionFront ENDP
; ########################################################################
TopXY PROC wDim:DWORD, sDim:DWORD

    shr sDim, 1      ; divide screen dimension by 2
    shr wDim, 1      ; divide window dimension by 2
    mov eax, wDim    ; copy window dimension into eax
    sub sDim, eax    ; sub half win dimension from half screen dimension

    return sDim

TopXY ENDP
; #########################################################################
DrawGameScene PROC
	;local ps	:PAINTSTRUCT

	invoke DrawBackground
	invoke DrawPlane
	invoke DrawBullet
	invoke DrawExplosion

	; tobedone maybe add beginpaint and endpaint
	invoke BeginPaint, hMainWnd, ADDR ps
	mov hDc, eax

	invoke BitBlt, hDc, 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT, hMemDc, 0, 0, SRCCOPY

	invoke EndPaint, hMainWnd, ADDR ps

	; need to realease DC?
	ret
DrawGameScene ENDP
; #########################################################################
DrawPlane PROC
	local planeCount : DWORD
	local pPlane	 : DWORD

	; draw enemy plane
	m2m planeCount, planeQueueSize
	.while planeCount > 0
		invoke GetPlaneFront
		mov pPlane, eax
		invoke PopPlane
		
		invoke StrenchBlt, hMemDc, [pPlane+Plane.MyRect.x], [pPlane+Plane.MyRect.y],
						[pPlane+Plane.MyRect.width], [pPlane+Plane.MyRect.height], 
						[pPlane+Plane.hDcBmpMsk], 0, 0, 
						[pPlane+Plane.width], [pPlane+Plane.height], SRCSAND
		
		invoke StrenchBlt, hMemDc, [pPlane+Plane.MyRect.x], [pPlane+Plane.MyRect.y],
						[pPlane+Plane.MyRect.width], [pPlane+Plane.MyRect.height], 
						[pPlane+Plane.hDcBmp], 0, 0, 
						[pPlane+Plane.width], [pPlane+Plane.height], SRCSPAND

		invoke PushPlane, pPlane
		dec planeCount
	.endw

	; draw player plane
	.if p1Plane.health > 0
		mov pPlane, offset p1Plane

		invoke StrenchBlt, hMemDc, [pPlane+Plane.MyRect.x], [pPlane+Plane.MyRect.y],
						[pPlane+Plane.MyRect.width], [pPlane+Plane.MyRect.height], 
						[pPlane+Plane.hDcBmpMsk], 0, 0, 
						[pPlane+Plane.width], [pPlane+Plane.height], SRCSAND
		
		invoke StrenchBlt, hMemDc, [pPlane+Plane.MyRect.x], [pPlane+Plane.MyRect.y],
						[pPlane+Plane.MyRect.width], [pPlane+Plane.MyRect.height], 
						[pPlane+Plane.hDcBmp], 0, 0, 
						[pPlane+Plane.width], [pPlane+Plane.height], SRCSPAND
	.endif
	.if p2Plane.health > 0
		mov pPlane, offset p2Plane

		invoke StrenchBlt, hMemDc, [pPlane+Plane.MyRect.x], [pPlane+Plane.MyRect.y],
						[pPlane+Plane.MyRect.width], [pPlane+Plane.MyRect.height], 
						[pPlane+Plane.hDcBmpMsk], 0, 0, 
						[pPlane+Plane.width], [pPlane+Plane.height], SRCSAND
		
		invoke StrenchBlt, hMemDc, [pPlane+Plane.MyRect.x], [pPlane+Plane.MyRect.y],
						[pPlane+Plane.MyRect.width], [pPlane+Plane.MyRect.height], 
						[pPlane+Plane.hDcBmp], 0, 0, 
						[pPlane+Plane.width], [pPlane+Plane.height], SRCSPAND
	.endif
	ret
DrawPlane ENDP
; #########################################################################
DrawBullet PROC
	local bulletCount		: DWORD
	local pBullet			: DWORD
	local enemyBulletBrush	: DWORD
	local playerBulletBrush : DWORD
	local left				: SDWORD
	local top				: SDWORD
	local right				: SDWORD	
	local bottom			: SDWORD

	invoke CreateSolidBrush, BULLET_COLOR_ENEMY
	mov enemyBulletBrush, eax
	invoke CreateSolidBrush, BULLET_COLOR_PLAYER
	mov playerBulletBrush, eax

	m2m bulletCount, bulletQueueSize
	.while bulletCount > 0
		invoke GetBulletFront
		mov pBullet, eax
		invoke PopBullet
		
		.if DWORD PTR [pBullet+Bullet.color] == BULLET_COLOR_ENEMY
			invoke SelectObject, hMemDc, enemyBulletBrush
		.elseif DWORD PTR [pBullet+Bullet.color] == BULLET_COLOR_PLAYER
			invoke SelectObject, hMemDc, playerBulletBrush
		.endif
		
		movsx left, SWORD PTR [pBullet+Bullet.MyRect.x]
		movsx top, SWORD PTR [pBullet+Bullet.MyRect.y]
		movsx eax, SWORD PTR [pBullet+Bullet.MyRect.width]
		add eax, left
		mov right, eax
		movsx eax, SWORD PTR [pBullet+Bullet.MyRect.height]
		add eax, top
		mov bottom, eax

		invoke Rectangle, hMemDc, left, top, right, bottom

		invoke PushBullet, pBullet
		dec bulletCount
	.endw

	invoke DeleteObject, enemyBulletBrush
	invoke DeleteObject, playerBulletBrush
	ret
DrawBullet ENDP
; #########################################################################
DrawExplosion PROC
	local explosionCount	: DWORD
	local pExplosion		: DWORD

	m2m explosionCount, explosionQueueSize
	.while explosionCount > 0
		dec explosionCount
		invoke GetExplosionFront
		mov pExplosion, eax
		invoke PopExplosion

		dec [pExplosion+Explosion.duration]
		.continue .if [pExplosion+Explosion.duration] == 0	; it the explosion expires
		
		invoke StrenchBlt, hMemDc, 
						[pExplosion+Explosion.MyRect.x], [pExplosion+Explosion.MyRect.y], 
						[pExplosion+Explosion.MyRect.width], [pExplosion+Explosion.MyRect.height], 
						[pExplosion+Explosion.hDcBmpMask],
						0, 0,
						BMP_SIZE_BOOM_SIZE, BMP_SIZE_BOOM_SIZE, SRCAND

		invoke StrenchBlt, hMemDc, 
						[pExplosion+Explosion.MyRect.x], [pExplosion+Explosion.MyRect.y], 
						[pExplosion+Explosion.MyRect.width], [pExplosion+Explosion.MyRect.height], 
						[pExplosion+Explosion.hDcBmpMask],
						0, 0,
						BMP_SIZE_BOOM_SIZE, BMP_SIZE_BOOM_SIZE, SRCPAINT

		invoke PushExplosion, pExplosion
	.endw
	ret
DrawExplosion ENDP
; #########################################################################
DrawBackground PROC
	local brush		:DWORD
	local wndRect	:RECT

	invoke GetDC, hMainWnd
	mov hDc, eax
	; »­ÉÏºÚÉ«±³¾°
	invoke CreateSolidBrush, COLOR_BLACK
	mov brush, eax
	invoke GetClientRect, hMainWnd, ADDR wndRect
	
	invoke FillRect	hDc, ADDR wndRect, brush
	
	; tobedone may be a picture background
	
	invoke RealeaseDC, hMainWnd, hDc
	ret
DrawBackground ENDP
; #########################################################################
InitDC PROC 
	; this function create memory DC and DCs for resources
    ; they should be delete when program exit

	; get system DC
	invoke GetDC, hMainWnd
	mov hDc, eax

	; create a memory DC
	invoke CreateCompatibleDC, hDc
	mov hMemDc, eax
	invoke CreateCompatibleBitmap, hDc, WINDOW_WIDTH, WINDOW_HEIGHT
	mov hBmp, eax
	invoke SelectObject, hMemDc, hBmp
	invoke DeleteObject, hBmp

	; create resource DC

	; explosion and its mask
	invoke CreateCompatibleDC, hDc
	mov hDcExplosion1, eax
    invoke LoadBitmap, hInstance, BMP_BOOM1
	mov hBmp, eax
	invoke SelectObject, hDcExplosion1, hBmp
	invoke DeleteObject, hBmp

	invoke CreateCompatibleDC, hDc
	mov hDcExplosion1Mask, eax
	invoke LoadBitmap, hInstance, BMP_BOOM1_MASK
	mov hBmp, eax
	invoke SelectObject, hDcExplosion1Mask, hBmp
	invoke DeleteObject, hBmp

	; enemy plane and its mask
	invoke CreateCompatibleDC, hDc
	mov hDcEnemyPlane1, eax
	invoke LoadBitmap, hInstance, BMP_ENEMY1
	mov hBmp, eax
	invoke SelectObject, hDcEnemyPlane1, hBmp
	invoke DeleteObject, hBmp

	invoke CreateCompatibleDC, hDc
	mov hDcEnemyPlane1Mask, eax
	invoke LoadBitmap, hInstance, BMP_ENEMY1_MASK
	mov hBmp, eax
	invoke SelectObject, hDcEnemyPlane1Mask, hBmp
	invoke DeleteObject, hBmp

	; player plane and its mask
	; palyer1
	invoke CreateCompatibleDC, hDc
	mov hDcPlayerPlane1, eax
	invoke LoadBitmap, hInstance, BMP_PLAYER1
	mov hBmp, eax
	invoke SelectObject, hDcPlayerPlane1, hBmp
	invoke DeleteObject, hBmp

	invoke CreateCompatibleDC, hDc
	mov hDcPlayerPlane1Mask, eax
	invoke LoadBitmap, hInstance, BMP_PLAYER1_MASK
	mov hBmp, eax
	invoke SelectObject, hDcPlayerPlane1Mask, hBmp
	invoke DeleteObject, hBmp

	; player2
	invoke CreateCompatibleDC, hDc
	mov hDcPlayerPlane2, eax
	invoke LoadBitmap, hInstance, BMP_PLAYER2
	mov hBmp, eax
	invoke SelectObject, hDcPlayerPlane2, hBmp
	invoke DeleteObject, hBmp

	invoke CreateCompatibleDC, hDc
	mov hDcPlayerPlane2Mask, eax
	invoke LoadBitmap, hInstance, BMP_PLAYER2_MASK
	mov hBmp, eax
	invoke SelectObject, hDcPlayerPlane2Mask, hBmp
	invoke DeleteObject, hBmp

	invoke ReleaseDC, hMainWnd, hDc
	ret
InitDC ENDP
; #########################################################################
DestroyDC PROC
	; tobedone
	ret
DestroyDC ENDP
; #########################################################################

END WinMain
