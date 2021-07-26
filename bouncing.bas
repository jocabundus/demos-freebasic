#include once "inc/bouncing.bi"

const SCREEN_W = 800
const SCREEN_H = 600

declare function angleToVector(angle as double = &hCafeBabe) as VectorType
declare function randposToVector(boundLft as double = 0, boundTop as double = 0, boundRgt as double = 0, boundBtm as double = 0) as VectorType

declare sub main()
declare function AddBall(position as VectorType ptr = 0, velocity as VectorType ptr = 0, radius as double = 1.0, colr as integer = &hffffff) as BallType ptr
declare function ballsIntersect(byref a as const BallType, byref b as const BallType) as boolean
declare function ballsNotIntersect(byref a as const BallType, byref b as const BallType) as boolean
declare sub bounce(byref a as BallType, byref b as BallType)
declare sub disentangle(byref a as BallType, byref b as BallType)
declare sub DrawBalls()
declare function totalMomentum() as double
declare sub renderFrame()

dim shared as BallType balls()

namespace Colors
    const Default  = &hffffff
    const Collider = &hffeeaa
    const Collided = &hff0000
    const Dodged   = &hffffff
end namespace

namespace Pauses
    const FpsDelay = 1/30
    const ShowCollision = 50
end namespace

main()
end

sub main()
    
    screenres SCREEN_W, SCREEN_H, 32, 2
    randomize timer
    
    dim as BallType ptr ball
    dim as BoundsType bounds
    dim as double tmr, seconds, nextFrameTime
    dim as integer i, j, k
    dim as boolean collided
    
    bounds.lft = 0: bounds.rgt = SCREEN_W
    bounds.top = 0: bounds.btm = SCREEN_H
    
    for i = 1 to 9
        ball = AddBall(0, 0, 30, Colors.Default)
        vectorMul(ball->velocity, 5)
    next i
    
    screenset 1, 0
    
    tmr = timer
    while inkey() <> chr(27)
        
        seconds = timer - tmr
        
        renderFrame()
        
        while timer < nextFrameTime: wend
        nextFrameTime = timer + Pauses.FpsDelay
        
        screencopy 1, 0
        
        
        collided = false
        for i = 0 to ubound(balls)
            ball = @balls(i)
            vectorAdd(ball->position, ball->velocity)
            
            if ball->lft < bounds.lft then reverse( ball->velocity.x ): ball->position.x = bounds.lft + ball->radius
            if ball->rgt > bounds.rgt then reverse( ball->velocity.x ): ball->position.x = bounds.rgt - ball->radius
            if ball->top < bounds.top then reverse( ball->velocity.y ): ball->position.y = bounds.top + ball->radius
            if ball->btm > bounds.btm then reverse( ball->velocity.y ): ball->position.y = bounds.btm - ball->radius
            
            for j = 0 to ubound(balls)
                if i = j then continue for
                if ballsIntersect(balls(i), balls(j)) then
                    disentangle(balls(i), balls(j))
                    bounce(balls(i), balls(j))
                    if ballsNotIntersect(balls(i), balls(j)) then
                        collided = true
                        for k = 0 to ubound(balls)
                            select case k
                                case i   : balls(k).colr = Colors.Collider
                                case j   : balls(k).colr = Colors.Collided
                                case else: balls(k).colr = Colors.Dodged
                            end select
                        next k
                        renderFrame()
                        screencopy 1, 0
                        sleep Pauses.ShowCollision
                        for k = 0 to ubound(balls)
                            balls(k).colr = Colors.Default
                        next k
                    end if
                end if
            next j
        next i
        
    wend
    
end sub

sub renderFrame()
    
    cls
    DrawBalls
    locate 1, 1: print totalMomentum
        
end sub

function AddBall(position as VectorType ptr = 0, velocity as VectorType ptr = 0, radius as double = 1.0, colr as integer = &hffffff) as BallType ptr
    
    dim as BallType ptr ball
    dim as integer index = ubound(balls) + 1
    
    redim preserve balls(index)
    ball = @balls(index)
    
    ball->position = iif(position, *position, randposToVector(0, 0, SCREEN_W, SCREEN_H))
    ball->velocity = iif(velocity, *velocity, angleToVector())
    ball->radius   = radius
    ball->colr     = colr
    
    dim as integer n
    do
        for n = 0 to index-1
            if (ball->position - balls(n).position).size() < (ball->radius + balls(n).radius) then
                ball->position = randposToVector(0, 0, SCREEN_W, SCREEN_H)
                continue do
            end if
        next n
        exit do
    loop
    
    return ball
    
end function

sub DrawBalls()
    
    dim as BallType ptr ball
    dim as integer n
    
    for n = 0 to ubound(balls)
        
        ball = @balls(n)
        
        if ball->colr = &hffffff then
            circle(ball->position.x, SCREEN_H-ball->position.y), ball->radius, ball->colr
        else
            circle(ball->position.x, SCREEN_H-ball->position.y), ball->radius, ball->colr, , , , F
        end if
        
    next n
    
end sub

function randposToVector(boundLft as double = 0, boundTop as double = 0, boundRgt as double = 0, boundBtm as double = 0) as VectorType
    
    dim as VectorType v
    dim as integer hasBounds = not ((boundLft = 0) and (boundTop = 0) and (boundRgt = 0) and (boundBtm = 0))
    
    if hasBounds then
        v.x = rnd() * abs(boundRgt - boundLft) + boundLft
        v.y = rnd() * abs(boundBtm - boundTop) + boundTop
    else
        v.x = rnd()
        v.y = rnd()
    end if
    
    return v
    
end function

function angleToVector(angle as double = &hCafeBabe) as VectorType
    
    dim as VectorType v
    
    angle = iif(angle = &hCafeBabe, 360*rnd(), angle)
    
    v.x = cos(angle * 3.141592653589793/180)
    v.y = sin(angle * 3.141592653589793/180)
    
    return v
    
end function

function ballsIntersect(byref a as const BallType, byref b as const BallType) as boolean
    
    return (a.position - b.position).size() < a.radius + b.radius
    
end function

function ballsNotIntersect(byref a as const BallType, byref b as const BallType) as boolean
    
    return not ballsIntersect(a, b)
    
end function

sub disentangle(byref a as BallType, byref b as BallType)
    
    dim as double t
    
    t = (a.radius + b.radius + b.position.size()) / (a.position - a.velocity).size()
    a.position -= a.velocity * t
    
end sub

sub bounce(byref a as BallType, byref b as BallType)
    
    dim as VectorType norm, forceA, forceB
    
    norm   = (a.position - b.position).unit()
    forceA = -norm * a.velocity.size() * abs(dot(a.velocity.unit(), norm))
    forceB =  norm * b.velocity.size() * abs(dot(b.velocity.unit(), norm))
    a.velocity += forceB
    a.velocity -= forceA
    b.velocity += forceA
    b.velocity -= forceB
    
    a.position += a.velocity
    b.position += b.velocity
    
end sub

function totalMomentum() as double
    
    dim as double total
    dim as integer n
    
    for n = 0 to ubound(balls)
        total += balls(n).velocity.size() * 1
    next n
    
    return total
    
end function
'*
'* size|posA - posB| = radA + radB
'*
'* size|posA - velA * t - posB| = radA + radB
'*
'* size|posA - velA| * t = radA + radB + size|posB|
'*
'* t = (radA + radB + size|posB|) / size|posA - velA|
