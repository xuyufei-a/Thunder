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
	mov p1Plane.plane.rect.lx, PLAYER_PLANE_WIDTH
	mov p1Plane.plane.rect.ly, PLAYER_PLANE_HEIGHT
	
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
	local pPlane	 : DWORD
	local bullet	 : Bullet

	; enemy planes emit bullets
	m2m planeCount, planeQueueSize
	.while planeCount > 0
		invoke GetPlaneFront
		mov pPlane, eax
		invoke PopPlane

		mov esi, pPlane
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

			mov eax, ENEMY_EMIT_INTERVAL
		.endif
		mov [esi].nextEmitCountdown, eax	
	.endw

	; player planes emit bullets
	mov esi, offset p1Plane
	ASSUME esi: PTR PlayerPlane
	mov eax, [esi].plane.nextEmitCountdown
	.if [esi].health > 0
		dec eax
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
			
			mov eax, PLAYER_EMIT_INTERVAL
		.endif
		.endif
		mov [esi].plane.nextEmitCountdown, eax
	.endif

	mov esi, offset p2Plane
	ASSUME esi: PTR PlayerPlane
	mov eax, [esi].plane.nextEmitCountdown
	.if [esi].health > 0
		dec eax
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
			
			mov eax, PLAYER_EMIT_INTERVAL
		.endif
		.endif
		mov [esi].plane.nextEmitCountdown, eax
	.endif
	ret
EmitBullet ENDP
; ########################################################################
CheckIntersection PROC pRect1: DWORD, pRect2: DWORD
	local l1	: SDWORD
	local r1	: SDWORD
	local t1	: SDWORD
	local b1	: SDWORD
	local l2	: SDWORD
	local r2	: SDWORD
	local t2	: SDWORD
	local b2	: SDWORD

	mov eax, True

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
	.if esi > 0
		mov eax, False
	.endif

	mov esi, l2
	mov edi, r1
	sub esi, edi
	.if esi > 0
		mov eax, False
	.endif

	mov esi, t1
	mov edi, b2
	sub esi, edi
	.if esi > 0
		mov eax, False
	.endif

	mov esi, t2
	mov edi, b1
	sub esi, edi
	.if esi > 0
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
			.if [edi.health] == 0
			    jmp @F
			.endif

			invoke CheckIntersection, esi, edi
			.if eax == True
				invoke PushExplosion, edi
				mov flag, True
				dec [edi].health
				; tobedone relocate the rebirth point
				mov [edi].plane.rect.x, P1_BIRTH_POINT_X]
			.endif
		@@:
			mov edi, offset p2Plane
			ASSUME edi: PTR PlayerPlane

			.if flag == True
			    jmp @F
			.endif
			.if [edi.health] == 0
			    jmp @F
			.endif

			invoke CheckIntersection, esi, edi
			.if eax == True
				invoke PushExplosion, edi
				mov flag, True
				dec [edi].health
				; tobedone relocate the rebirth point
				mov [edi].plane.rect.x, P1_BIRTH_POINT_X]
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
	mov eax, True
	
	mov ebx, pRect
	ASSUME ebx: PTR MyRect

	mov esi, [ebx].x
	mov edi, [ebx].y

	.if esi > WINDOW_WIDTH
		mov eax, False
	.endif
	.if edi > WINDOW_HEIGHT
		mov eax, False
	.endif

	add esi, [ebx].lx
	add edi, [ebx].ly

	.if esi < 0
		mov eax, False
	.endif 
	.if edi < 0
		mov eax, False
	.endif

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

		dec bulletsCount
	.endw

	; loop iterate all the planes in the circular queue
	.while planesCount > 0
		invoke GetPlaneFront
		mov edi, eax
		ASSUME edi: PTR Plane
		invoke PopPlane

	; modify following code becase the variable are now SDWORD
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

		dec planesCount
	.endw

	; cal next position of the player plane

	mov edi, offset p1Plane
	ASSUME edi: PTR PlayerPlane
	
	.if aKeyHold == True
		mov eax, [edi].plane.rect.x
		sub eax, [edi].plane.xSpeed
		.if eax < 0
			mov eax, 0
		.endif
		mov [edi].plane.rect.x, eax
	.endif
	
	.if dKeyHold == True
		mov eax, [edi].plane.rect.x
		add eax, [edi].plane.xSpeed
		.if eax > WINDOW_WIDTH - PLAYER_PLANE_WIDTH
			mov eax, WINDOW_WIDTH - PLAYER_PLANE_WIDTH
		.endif
		mov [edi].plane.rect.x, eax
	.endif

	mov edi, offset p2Plane
	ASSUME edi: PTR PlayerPlane

	.if leftKeyHold == True
		mov eax, [edi].plane.rect.x
		sub eax, [edi].plane.xSpeed
		.if eax < 0
			mov eax, 0
		.endif
		mov [edi].plane.rect.x, eax
	.endif

	.if rightKeyHold == True
		mov eax, [edi].plane.rect.x
		add eax, [edi].plane.xSpeed
		.if eax > WINDOW_WIDTH - PLAYER_PLANE_WIDTH
			mov eax, WINDOW_WIDTH - PLAYER_PLANE_WIDTH
		.endif
		mov [edi].plane.rect.x, eax
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

	comment /*
	; draw enemy plane
	m2m planeCount, planeQueueSize
	.while planeCount > 0
		invoke GetPlaneFront
		mov pPlane, eax
		invoke PopPlane
		
		invoke StretchBlt, hMemDc, SDWORD PTR [pPlane+Plane.rect.x], SDWORD PTR [pPlane+Plane.rect.y],
						SDWORD PTR [pPlane+Plane.rect.lx], SDWORD PTR [pPlane+Plane.rect.ly], 
						[pPlane+Plane.hDcBmpMask], 0, 0, 
						SDWORD PTR [pPlane+Plane.lx], SDWORD PTR [pPlane+Plane.ly], SRCAND
		
		invoke StretchBlt, hMemDc, SDWORD PTR [pPlane+Plane.rect.x], SDWORD PTR [pPlane+Plane.rect.y],
						SDWORD PTR [pPlane+Plane.rect.lx], SDWORD PTR [pPlane+Plane.rect.ly], 
						[pPlane+Plane.hDcBmp], 0, 0, 
						SDWORD PTR [pPlane+Plane.lx], SDWORD PTR [pPlane+Plane.ly], SRCPAINT

		invoke PushPlane, pPlane
		dec planeCount
	.endw

	; draw player plane
	.if p1Plane.health > 0
		mov pPlane, offset p1Plane

		invoke StretchBlt, hMemDc, SDWORD PTR [pPlane+Plane.rect.x], SDWORD PTR [pPlane+Plane.rect.y],
						SDWORD PTR [pPlane+Plane.rect.lx], SDWORD PTR [pPlane+Plane.rect.ly], 
						[pPlane+Plane.hDcBmpMask], 0, 0, 
						SDWORD PTR [pPlane+Plane.lx], SDWORD PTR [pPlane+Plane.ly], SRCAND
		
		invoke StretchBlt, hMemDc, SDWORD PTR [pPlane+Plane.rect.x], SDWORD PTR [pPlane+Plane.rect.y],
						SDWORD PTR [pPlane+Plane.rect.lx], SDWORD PTR [pPlane+Plane.rect.ly], 
						[pPlane+Plane.hDcBmp], 0, 0, 
						SDWORD PTR [pPlane+Plane.lx], SDWORD PTR [pPlane+Plane.ly], SRCPAINT

	.endif
	.if p2Plane.health > 0
		mov pPlane, offset p2Plane

		invoke StretchBlt, hMemDc, SDWORD PTR [pPlane+Plane.rect.x], SDWORD PTR [pPlane+Plane.rect.y],
						SDWORD PTR [pPlane+Plane.rect.lx], SDWORD PTR [pPlane+Plane.rect.ly], 
						[pPlane+Plane.hDcBmpMask], 0, 0, 
						SDWORD PTR [pPlane+Plane.lx], SDWORD PTR [pPlane+Plane.ly], SRCAND
		
		invoke StretchBlt, hMemDc, SDWORD PTR [pPlane+Plane.rect.x], SDWORD PTR [pPlane+Plane.rect.y],
						SDWORD PTR [pPlane+Plane.rect.lx], SDWORD PTR [pPlane+Plane.rect.ly], 
						[pPlane+Plane.hDcBmp], 0, 0, 
						SDWORD PTR [pPlane+Plane.lx], SDWORD PTR [pPlane+Plane.ly], SRCPAINT
	.endif
	*/
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

	comment /*
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
		
		movsx left, SWORD PTR [pBullet+Bullet.rect.x]
		movsx top, SWORD PTR [pBullet+Bullet.rect.y]
		movsx eax, SWORD PTR [pBullet+Bullet.rect.lx]
		add eax, left
		mov right, eax
		movsx eax, SWORD PTR [pBullet+Bullet.rect.ly]
		add eax, top
		mov bottom, eax

		invoke Rectangle, hMemDc, left, top, right, bottom

		invoke PushBullet, pBullet
		dec bulletCount
	.endw

	invoke DeleteObject, enemyBulletBrush
	invoke DeleteObject, playerBulletBrush
	*/
	ret
DrawBullet ENDP
; #########################################################################
DrawExplosion PROC
	local explosionCount	: DWORD
	local pExplosion		: DWORD

	comment /*
	m2m explosionCount, explosionQueueSize
	.while explosionCount > 0
		dec explosionCount
		invoke GetExplosionFront
		mov pExplosion, eax
		invoke PopExplosion

		dec [pExplosion+Explosion.duration]
		.continue .if [pExplosion+Explosion.duration] == 0	; it the explosion expires
		
		invoke StretchBlt, hMemDc, 
						[pExplosion+Explosion.MyRect.x], [pExplosion+Explosion.MyRect.y], 
						[pExplosion+Explosion.MyRect.lx], [pExplosion+Explosion.MyRect.ly], 
						[pExplosion+Explosion.hDcBmpMask],
						0, 0,
						BMP_SIZE_BOOM_SIZE, BMP_SIZE_BOOM_SIZE, SRCAND

		invoke StretchBlt, hMemDc, 
						[pExplosion+Explosion.MyRect.x], [pExplosion+Explosion.MyRect.y], 
						[pExplosion+Explosion.MyRect.lx], [pExplosion+Explosion.MyRect.ly], 
						[pExplosion+Explosion.hDcBmpMask],
						0, 0,
						BMP_SIZE_BOOM_SIZE, BMP_SIZE_BOOM_SIZE, SRCPAINT

		invoke PushExplosion, pExplosion
	.endw
	*/
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
	
	; tobedone bug
	; invoke FillRect	hDc, ADDR wndRect, brush
	
	; tobedone may be a picture background
	
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
