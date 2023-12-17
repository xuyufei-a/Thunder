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
include resource.inc

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

		m2m hMainWnd, [uMsg-4]
		invoke SetTimer, hMainWnd, 1, GAME_REFRESH_INTERVAL, NULL

		; tobedone  only game part finished, so start game when creating 
		mov gameStatus, GSTATUS_GAME
		invoke InitGame, 1

	.elseif uMsg == WM_KEYDOWN

	.elseif uMsg == WM_CLOSE

	.elseif uMsg == WM_DESTROY
		
	.elseif uMsg == WM_PAINT

	.endif
	ret
MenuProc ENDP
; ########################################################################
GameProc PROC hWin: DWORD, uMsg: DWORD, wParam: DWORD, lParam: DWORD
	; tobedone init keys	
	; mov rightKeyHold, True
	; mov enterKeyHold, True
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
			mov spacebarKeyHold, True
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
			mov spacebarKeyHold, False
		.elseif wParam == KEY_ENTER
			mov enterKeyHold, False
		.endif
	.elseif uMsg == WM_PAINT
		invoke DrawGameScene
	.elseif uMsg == WM_CLOSE


	.elseif uMsg == WM_DESTROY
		invoke PostQuitMessage, NULL

		; tobedone del created objects
	.elseif uMsg == WM_TIMER
		invoke SolveCollision
		invoke CalNextPos
		invoke EmitBullet
		;invoke GenerateEnemy
		invoke RedrawWindow, hMainWnd, NULL, NULL, 1
	.endif
				
	invoke DefWindowProc, hWin, uMsg, wParam, lParam
	ret
GameProc ENDP
; ########################################################################
SuspendProc PROC hWin: DWORD, uMsg: DWORD, wParam: DWORD, lParam: DWORD
	;.if uMsg == KEY_DOWN	
	



SuspendProc ENDP
; ########################################################################
InitGame PROC playerCount: DWORD
	local plane :Plane 
	; init queues
	invoke InitQueue	

	mov plane.rect.x, 100
	mov plane.rect.y, 100
	mov plane.rect.lx, 100
	mov plane.rect.ly, 100
	mov plane.xSpeed, 0
	mov plane.ySpeed, 1
	mov plane.nextEmitCountdown, 10
	m2m plane.hDcBmp, hDcPlayerPlane1
	m2m plane.hDcBmpMask, hDcPlayerPlane1Mask
	mov plane.lx, BMP_SIZE_PLAYER_WIDTH
	mov plane.ly, BMP_SIZE_PLAYER_HEIGHT
	

	invoke PushPlane, ADDR plane

	; init random seed
	invoke GetTickCount
	mov randomSeed, eax

	; init player 1	
	mov p1Plane.plane.rect.x, P1_BIRTH_POINT_X
	mov p1Plane.plane.rect.y, P1_BIRTH_POINT_Y
	mov p1Plane.plane.rect.lx, PLAYER_PLANE_WIDTH
	mov p1Plane.plane.rect.ly, PLAYER_PLANE_HEIGHT
	mov p1Plane.plane.xSpeed, SPEED_PLAYER_X
	mov p1Plane.plane.ySpeed, SPEED_PLAYER_Y	
	
	m2m p1Plane.plane.hDcBmp, hDcPlayerPlane1
	m2m p1Plane.plane.hDcBmpMask, hDcPlayerPlane1Mask
	mov p1Plane.plane.lx, BMP_SIZE_PLAYER_WIDTH
	mov p1Plane.plane.ly, BMP_SIZE_PLAYER_HEIGHT
	mov p1Plane.plane.nextEmitCountdown, PLAYER_EMIT_INTERVAL

	mov p1Plane.health, MAX_HEALTH
	
	; init player2
	mov p2Plane.plane.rect.x, P2_BIRTH_POINT_X
	mov p2Plane.plane.rect.y, P2_BIRTH_POINT_Y
	mov p2Plane.plane.rect.lx, PLAYER_PLANE_WIDTH
	mov p2Plane.plane.rect.ly, PLAYER_PLANE_HEIGHT
	mov p2Plane.plane.xSpeed, SPEED_PLAYER_X
	mov p2Plane.plane.ySpeed, SPEED_PLAYER_Y	
	
	m2m p2Plane.plane.hDcBmp, hDcPlayerPlane2
	m2m p2Plane.plane.hDcBmpMask, hDcPlayerPlane2Mask
	mov p2Plane.plane.lx, BMP_SIZE_PLAYER_WIDTH
	mov p2Plane.plane.ly, BMP_SIZE_PLAYER_HEIGHT
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
	local bullet	 : Bullet
	
	; enemy planes emit bullets
	m2m planeCount, planeQueueSize
	.while planeCount > 0
		dec planeCount
		invoke GetPlaneFront
		mov esi, eax
		invoke PopPlane

		ASSUME esi: PTR Plane
		mov eax, [esi].nextEmitCountdown
		dec eax
		.if eax == 0
			m2m bullet.rect.x, [esi].rect.x
			m2m bullet.rect.y, [esi].rect.y

			mov bullet.rect.lx, BULLET_WIDTH
			mov bullet.rect.ly, BULLET_HEIGHT
			mov bullet.xSpeed, 0
			mov bullet.ySpeed, SPEED_ENEMY_BULLET
			mov bullet.color, BULLET_COLOR_ENEMY
			invoke PushBullet, ADDR bullet
			mov eax, [esi].rect.lx
			sub eax, EPSILON
			add bullet.rect.x, eax
			invoke PushBullet, ADDR bullet

			mov eax, ENEMY_EMIT_INTERVAL
		.endif
		mov [esi].nextEmitCountdown, eax	
		invoke PushPlane, esi
	.endw

	; player planes emit bullets
	mov esi, offset p1Plane
	ASSUME esi: PTR PlayerPlane
	mov eax, [esi].plane.nextEmitCountdown
	.if [esi].health > 0
		.if eax != 0
			dec eax
		.endif
		.if spacebarKeyHold == True
		.if eax <= 0
			; tobedone init bullet position
			m2m bullet.rect.x, [esi].plane.rect.x
			m2m bullet.rect.y, [esi].plane.rect.y

			mov bullet.rect.lx, BULLET_WIDTH
			mov bullet.rect.ly, BULLET_HEIGHT
			mov bullet.xSpeed, 0
			mov bullet.ySpeed, -SPEED_PLAYER_BULLET
			mov bullet.color, BULLET_COLOR_PLAYER
			invoke PushBullet, ADDR bullet
			mov eax, [esi].plane.rect.lx
			sub eax, EPSILON
			add bullet.rect.x, eax
			invoke PushBullet, ADDR bullet
			
			mov eax, PLAYER_EMIT_INTERVAL
		.endif
		.endif
		mov [esi].plane.nextEmitCountdown, eax
	.endif

	mov esi, offset p2Plane
	ASSUME esi: PTR PlayerPlane
	mov eax, [esi].plane.nextEmitCountdown
	ASSUME eax: SDWORD
	.if [esi].health > 0
		.if eax != 0
			dec eax
		.endif
		.if enterKeyHold == True
		.if eax <= 0
			; tobedone init bullet position
			m2m bullet.rect.x, [esi].plane.rect.x
			m2m bullet.rect.y, [esi].plane.rect.y

			mov bullet.rect.lx, BULLET_WIDTH
			mov bullet.rect.ly, BULLET_HEIGHT
			mov bullet.xSpeed, 0
			mov bullet.ySpeed, -SPEED_PLAYER_BULLET
			mov bullet.color, BULLET_COLOR_PLAYER
			invoke PushBullet, ADDR bullet
			mov eax, [esi].plane.rect.lx
			sub eax, EPSILON
			add bullet.rect.x, eax
			invoke PushBullet, ADDR bullet
			
			mov eax, PLAYER_EMIT_INTERVAL
		.endif
		.endif
		mov [esi].plane.nextEmitCountdown, eax
	.endif
	ret
EmitBullet ENDP
; ########################################################################
GenerateEnemy PROC
	local plane		 : Plane	
	local planeCount : DWORD
	local flag		 : DWORD

	invoke Random, REAL_WIDTH - MAX_ENEMY_PLANE_WIDTH
	mov plane.rect.x, eax
	mov plane.xSpeed, SPEED_ENEMY_X
	mov plane.ySpeed, SPEED_ENEMY_Y
	mov plane.nextEmitCountdown, ENEMY_EMIT_INTERVAL
	
	and eax, eax
	.if eax == 1
		mov plane.rect.y, -ENEMY_PLANE1_HEIGHT
		mov plane.rect.lx, ENEMY_PLANE1_WIDTH
		mov plane.rect.ly, ENEMY_PLANE1_HEIGHT
		m2m plane.hDcBmp, hDcEnemyPlane1
		m2m plane.hDcBmpMask, hDcEnemyPlane1Mask
		mov plane.lx, BMP_SIZE_ENEMY1_WIDTH
		mov plane.ly, BMP_SIZE_ENEMY1_HEIGHT
	.else
		mov plane.rect.y, -ENEMY_PLANE2_HEIGHT
		mov plane.rect.lx, ENEMY_PLANE2_WIDTH
		mov plane.rect.ly, ENEMY_PLANE2_HEIGHT
		m2m plane.hDcBmp, hDcEnemyPlane2
		m2m plane.hDcBmpMask, hDcEnemyPlane2Mask
		mov plane.lx, BMP_SIZE_ENEMY2_WIDTH
		mov plane.ly, BMP_SIZE_ENEMY2_HEIGHT
	.endif
	
	m2m planeCount, planeQueueSize
	mov flag, True
	.while planeCount > 0
		.break .if flag == False
		dec planeCount
		invoke GetPlaneFront
		mov esi, eax
		ASSUME esi: PTR Plane
		invoke PopPlane
		
		invoke CheckIntersection, esi, ADDR plane
		.if eax == False
			mov flag, False
		.endif
		
		invoke PushPlane, esi	
	.endw

	.if flag == True
		invoke PushPlane, ADDR plane
	.endif
	ret
GenerateEnemy ENDP
; ########################################################################
CheckIntersection PROC pRect1: DWORD, pRect2: DWORD
	local l1	 : SDWORD
	local r1	 : SDWORD
	local t1	 : SDWORD
	local b1	 : SDWORD
	local l2	 : SDWORD
	local r2 	 : SDWORD
	local t2	 : SDWORD
	local b2	 : SDWORD
	local tmpVal : SDWORD

	mov eax, True

	push esi
	push edi
	push ebx
	push ecx

	mov esi, pRect1
	ASSUME esi: PTR MyRect
	mov ecx, [esi].x
	mov ebx, [esi].y
	mov l1, ecx
	mov t1, ebx
	add ecx, [esi].lx
	mov r1, ecx
	add ebx, [esi].ly
	mov b1, ebx
	
	mov esi, pRect2
	ASSUME esi: PTR MyRect
	mov ecx, [esi].x
	mov ebx, [esi].y
	mov l2, ecx
	mov t2, ebx
	add ecx, [esi].lx
	mov r2, ecx
	add ebx, [esi].ly
	mov b2, ebx

	; check if the two rectangles intersect
	mov esi, l1
	mov edi, r2
	sub esi, edi
	mov tmpVal, esi
	.if tmpVal > 0
		mov eax, False
	.endif

	mov esi, l2
	mov edi, r1
	sub esi, edi
	mov tmpVal, esi
	.if tmpVal > 0
		mov eax, False
	.endif

	mov esi, t1
	mov edi, b2
	sub esi, edi
	mov tmpVal, esi
	.if tmpVal > 0
		mov eax, False
	.endif

	mov esi, t2
	mov edi, b1
	sub esi, edi
	mov tmpVal, esi
	.if tmpVal > 0
		mov eax, False
	.endif

	pop ecx
	pop ebx
	pop edi
	pop esi

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
	local bulletColor   : WORD
	local flag 		    : WORD

	m2m bulletsCount, bulletQueueSize

	.while bulletsCount > 0
		; get the bullet at the queue front
		invoke GetBulletFront
		mov esi, eax
		ASSUME esi: PTR Bullet
		invoke PopBullet
		m2m bulletColor, [esi].color
		mov flag, False									; flag to indicate if the bullet is deleted

		; iterate the planes and check collision
		.if bulletColor == BULLET_COLOR_PLAYER			; bullet belongs to player
			m2m planesCount, planeQueueSize
			.while planesCount > 0
				invoke GetPlaneFront
				mov edi, eax
				ASSUME edi: PTR Plane
				invoke PopPlane

				invoke CheckIntersection, esi, edi
				.if eax == True
					invoke PushExplosion, edi
					mov flag, True	
					; tobedone add score
				.endif

				.if flag == False
					invoke PushPlane, edi
				.endif 

				.break .if flag == True					; bullet can only hit one plane
				dec planesCount
			.endw
		.elseif bulletColor == BULLET_COLOR_ENEMY
			mov edi, offset p1Plane
			ASSUME edi: PTR PlayerPlane
			
			.if flag == True
			    jmp @F
			.endif
			.if [edi].health == 0
			    jmp @F
			.endif

			invoke CheckIntersection, esi, edi
			.if eax == True
				invoke PushExplosion, edi
				mov flag, True
				dec [edi].health
				; tobedone relocate the rebirth point
				mov [edi].plane.rect.x, P1_BIRTH_POINT_X
			.endif
		@@:
			mov edi, offset p2Plane
			ASSUME edi: PTR PlayerPlane

			.if flag == True
			    jmp @F
			.endif
			.if [edi].health == 0
			    jmp @F
			.endif

			invoke CheckIntersection, esi, edi
			.if eax == True
				invoke PushExplosion, edi
				mov flag, True
				dec [edi].health
				; tobedone relocate the rebirth point
				mov [edi].plane.rect.x, P1_BIRTH_POINT_X
			.endif
		@@:
		.endif

		; if there is no collison, push the bullet back
		.if flag == False
			invoke PushBullet, esi
		.endif 
		dec bulletsCount
	.endw

	ret
SolveCollision ENDP
; ########################################################################
CheckIllegal PROC pRect: DWORD
	local tmpVal  : SDWORD
	push esi
	push edi
	push ebx

	mov eax, True
	
	mov ebx, pRect
	ASSUME ebx: PTR MyRect

	mov esi, [ebx].x
	mov edi, [ebx].y
	mov tmpVal, esi
	.if tmpVal > REAL_WIDTH
		mov eax, False
	.endif
	mov tmpVal, edi
	.if tmpVal > REAL_HEIGHT
		mov eax, False
	.endif

	add esi, [ebx].lx
	mov tmpVal, esi
	.if tmpVal < 0
		mov eax, False
	.endif 
	add edi, [ebx].ly
	mov tmpVal, edi
	.if tmpVal < 0
		mov eax, False
	.endif
	
	pop ebx
	pop edi
	pop esi
	ret
CheckIllegal ENDP
; ########################################################################
CalNextPos PROC
	local bulletsCount	: DWORD	
	local planesCount	: DWORD

	m2m bulletsCount, bulletQueueSize
	m2m planesCount, planeQueueSize

	; loop iterate all the bullets in the circular queue
	.while bulletsCount > 0
		dec bulletsCount
		invoke GetBulletFront
		mov esi, eax
		ASSUME esi: PTR Bullet
		invoke PopBullet
	
		mov eax, [esi].rect.x
		add eax, [esi].xSpeed
		mov [esi].rect.x, eax
		mov eax, [esi].rect.y
		add eax, [esi].ySpeed
		mov [esi].rect.y, eax
		invoke CheckIllegal, esi
		.if eax == True
			invoke PushBullet, esi
		.endif
	.endw

	; loop iterate all the planes in the circular queue
	.while planesCount > 0
		dec planesCount
		invoke GetPlaneFront
		mov edi, eax
		ASSUME edi: PTR Plane
		invoke PopPlane

	; tobedone modify following code becase the variable are now SDWOR
		mov eax, [edi].rect.x
		add eax, [edi].xSpeed
		mov [edi].rect.x, eax
		mov eax, [edi].rect.y
		add eax, [edi].ySpeed
		mov [edi].rect.y, eax
		invoke CheckIllegal, edi
		.if eax == True
			invoke PushPlane, edi
		.endif
	.endw

	; cal next position of the player plane

	mov edi, offset p1Plane
	ASSUME edi: PTR PlayerPlane
	
	.if aKeyHold == True
		mov eax, [edi].plane.rect.x
		sub eax, [edi].plane.xSpeed
		mov [edi].plane.rect.x, eax
		.if [edi].plane.rect.x < 0
			mov [edi].plane.rect.x, 0
		.endif
	.endif
	
	.if dKeyHold == True
		mov eax, [edi].plane.rect.x
		add eax, [edi].plane.xSpeed
		.if eax > REAL_WIDTH - PLAYER_PLANE_WIDTH
			mov eax, REAL_WIDTH - PLAYER_PLANE_WIDTH
		.endif
		mov [edi].plane.rect.x, eax
	.endif

	mov edi, offset p2Plane
	ASSUME edi: PTR PlayerPlane

	.if leftKeyHold == True
		mov eax, [edi].plane.rect.x
		sub eax, [edi].plane.xSpeed
		mov [edi].plane.rect.x, eax
		.if [edi].plane.rect.x < 0
			mov [edi].plane.rect.x, 0
		.endif
	.endif

	.if rightKeyHold == True
		mov eax, [edi].plane.rect.x
		add eax, [edi].plane.xSpeed
		.if eax > REAL_WIDTH - PLAYER_PLANE_WIDTH
			mov eax, REAL_WIDTH - PLAYER_PLANE_WIDTH
		.endif
		mov [edi].plane.rect.x, eax
	.endif
	ret
CalNextPos ENDP
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
	; tobedone bug, reserve registers
	.if bulletQueueSize == QUEUE_SIZE
		ret
	.endif
	push esi
	push edi
	push ecx

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
	
	pop ecx
	pop edi
	pop esi
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

	push ecx
	mov eax, bulletQueueHead
	mov ecx, sizeof Bullet
	mul ecx
	add eax, offset bulletQueue
	pop ecx
	ret
GetBulletFront ENDP
; ########################################################################
PushPlane PROC pPlane:DWORD
	.if planeQueueSize == QUEUE_SIZE
		ret
	.endif

	push ecx
	push esi
	push edi 
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
	pop edi
	pop esi
	pop ecx
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

	push ecx
	mov eax, planeQueueHead
	mov ecx, sizeof Plane
	mul ecx
	add eax, offset planeQueue
	pop ecx
	ret
GetPlaneFront ENDP
; ########################################################################
PushExplosion PROC pRect:DWORD
	.if explosionQueueSize == QUEUE_SIZE
		ret
	.endif

	push ecx
	push esi
	push edi
	; move the source ptr to esi and the destination ptr to edi
	mov eax, explosionQueueTail
	mov ecx, sizeof Explosion
	mul ecx
	add eax, offset explosionQueue
	ASSUME eax: PTR Explosion

	; init other members for a new explosion
	mov [eax].duration, EXPLOSION_DURATION
	m2m [eax].hDcBmp, hDcExplosion1
	m2m [eax].hDcBmpMask, hDcExplosion1Mask
	mov [eax].lx, BMP_SIZE_BOOM_SIZE
	mov [eax].ly, BMP_SIZE_BOOM_SIZE
	; tobedone more variety of explosin


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
	push edi
	push esi
	push ecx
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

	push ecx
	mov eax, explosionQueueHead
	mov ecx, sizeof Explosion
	mul ecx
	add eax, offset explosionQueue
	pop ecx
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
	local ps	:PAINTSTRUCT

	invoke DrawBackground
	invoke DrawExplosion
	invoke DrawPlane
	invoke DrawBullet

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

	; draw enemy plane
	m2m planeCount, planeQueueSize
	.while planeCount > 0
		invoke GetPlaneFront
		mov esi, eax
		ASSUME esi: PTR Plane
		invoke PopPlane
		
		invoke StretchBlt, hMemDc,[esi].rect.x, [esi].rect.y,
						[esi].rect.lx, [esi].rect.ly, 
						[esi].hDcBmpMask, 0, 0, 
						[esi].lx, [esi].ly, SRCAND

		invoke StretchBlt, hMemDc,[esi].rect.x, [esi].rect.y,
						[esi].rect.lx, [esi].rect.ly, 
						[esi].hDcBmp, 0, 0, 
						[esi].lx, [esi].ly, SRCPAINT
		
		invoke PushPlane, esi
		dec planeCount
	.endw

	
	; draw player plane
	.if p1Plane.health > 0
		mov esi , offset p1Plane
		ASSUME esi: PTR PlayerPlane

		invoke StretchBlt, hMemDc,[esi].plane.rect.x, [esi].plane.rect.y,
						[esi].plane.rect.lx, [esi].plane.rect.ly, 
						[esi].plane.hDcBmpMask, 0, 0, 
						[esi].plane.lx, [esi].plane.ly, SRCAND

		invoke StretchBlt, hMemDc,[esi].plane.rect.x, [esi].plane.rect.y,
						[esi].plane.rect.lx, [esi].plane.rect.ly, 
						[esi].plane.hDcBmp, 0, 0, 
						[esi].plane.lx, [esi].plane.ly, SRCPAINT
	.endif
	.if p2Plane.health > 0
		mov esi , offset p2Plane
		ASSUME esi: PTR PlayerPlane

		invoke StretchBlt, hMemDc,[esi].plane.rect.x, [esi].plane.rect.y,
						[esi].plane.rect.lx, [esi].plane.rect.ly, 
						[esi].plane.hDcBmpMask, 0, 0, 
						[esi].plane.lx, [esi].plane.ly, SRCAND

		invoke StretchBlt, hMemDc,[esi].plane.rect.x, [esi].plane.rect.y,
						[esi].plane.rect.lx, [esi].plane.rect.ly, 
						[esi].plane.hDcBmp, 0, 0, 
						[esi].plane.lx, [esi].plane.ly, SRCPAINT
	.endif
	ret
DrawPlane ENDP
; #########################################################################
DrawBullet PROC
	local bulletCount		: DWORD
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
		mov esi, eax
		ASSUME esi: PTR Bullet
		invoke PopBullet
		
		.if [esi].color == BULLET_COLOR_ENEMY
			invoke SelectObject, hMemDc, enemyBulletBrush
		.elseif [esi].color == BULLET_COLOR_PLAYER
			invoke SelectObject, hMemDc, playerBulletBrush
		.endif
		
		m2m left, [esi].rect.x
		m2m top, [esi].rect.y
		mov eax, [esi].rect.lx
		add eax, left
		mov right, eax
		mov eax, [esi].rect.ly
		add eax, top
		mov bottom, eax

		invoke Rectangle, hMemDc, left, top, right, bottom

		invoke PushBullet, esi
		dec bulletCount
	.endw

	invoke DeleteObject, enemyBulletBrush
	invoke DeleteObject, playerBulletBrush
	ret
DrawBullet ENDP
; #########################################################################
DrawExplosion PROC
	local explosionCount	: DWORD

	m2m explosionCount, explosionQueueSize
	.while explosionCount > 0
		dec explosionCount
		invoke GetExplosionFront
		mov esi, eax
		ASSUME esi: PTR Explosion
		invoke PopExplosion

		dec [esi].duration
		.continue .if [esi].duration == 0	; it the explosion expires
		
		invoke StretchBlt, hMemDc, 
						[esi].rect.x, [esi].rect.y,
						[esi].rect.lx, [esi].rect.ly,
						[esi].hDcBmpMask, 0, 0,
						[esi].lx, [esi].ly, SRCAND
		
		invoke StretchBlt, hMemDc, 
						[esi].rect.x, [esi].rect.y,
						[esi].rect.lx, [esi].rect.ly,
						[esi].hDcBmp, 0, 0,
						[esi].lx, [esi].ly, SRCPAINT

		invoke PushExplosion, esi
	.endw
	ret
DrawExplosion ENDP
; #########################################################################
DrawBackground PROC
	local wndRect		:RECT

	invoke GetDC, hMainWnd
	mov hDc, eax
	
	invoke BitBlt, hMemDc, 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT, hDcBackground, 0, 0, SRCCOPY	
	
	invoke ReleaseDC, hMainWnd, hDc
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

	; create a background DC
	invoke CreateCompatibleDC, hDc
	mov hDcBackground, eax
    invoke LoadBitmap, hInstance, BMP_BACKGROUND
	mov hBmp, eax
	invoke SelectObject, hDcBackground, hBmp
	invoke DeleteObject, hBmp

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
	; enemy1
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

	; enemy2
	invoke CreateCompatibleDC, hDc
	mov hDcEnemyPlane2, eax
	invoke LoadBitmap, hInstance, BMP_ENEMY2
	mov hBmp, eax
	invoke SelectObject, hDcEnemyPlane2, hBmp
	invoke DeleteObject, hBmp

	invoke CreateCompatibleDC, hDc
	mov hDcEnemyPlane2Mask, eax
	invoke LoadBitmap, hInstance, BMP_ENEMY2_MASK
	mov hBmp, eax
	invoke SelectObject, hDcEnemyPlane2Mask, hBmp
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
Random PROC		limit: DWORD
	mov eax, randomSeed
	mov edx, RANDOM_A
	mul edx
	add eax, RANDOM_C
	mov randomSeed, eax

	mov edx, 0
	div limit
	mov eax, edx
	ret
Random ENDP
; #########################################################################

END WinMain
