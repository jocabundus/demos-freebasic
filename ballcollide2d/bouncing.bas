#include once "inc/bouncing.bi"

const SCREEN_W = 800
const SCREEN_H = 640

declare function vectorFromDegrees(degrees as double = &hCafeBabe) as VectorType
declare function vectorFromRadians(radians as double = &hCafeBabe) as VectorType
declare function vectorFromRandPos(boundLft as double = 0, boundTop as double = 0, boundRgt as double = 0, boundBtm as double = 0) as VectorType

declare sub main()
declare function AddBall(position as VectorType ptr = 0, velocity as VectorType ptr = 0, mass as double = 1.0, radius as double = 1.0, colr as integer = &hffffff) as BallType ptr
declare function ballsIntersect(byref a as const BallType, byref b as const BallType) as boolean
declare function ballsNotIntersect(byref a as const BallType, byref b as const BallType) as boolean
declare sub bounce(byref a as BallType, byref b as BallType)
declare sub disentangle(byref a as BallType, byref b as BallType)
declare sub DrawBalls()
declare function totalMomentum() as double
declare sub renderFrame()

dim shared as BallType balls()

const PI = 3.141592653589793

namespace Colors
    const Default  = &hffffff
    const Collider = &hffeeaa
    const Collided = &hff0000
    const Dodged   = &hffffff
    const Spoke    = &hd3d3d3
end namespace

namespace Pauses
    const FpsDelay = 1/60
    const ShowCollision = 25
end namespace

main()
end

sub main()
    
    screenres SCREEN_W, SCREEN_H, 32, 2
    window (0, SCREEN_H-1)-(SCREEN_W-1, 0)
    randomize timer
    
    dim as BallType ptr ball
    dim as BoundsType bounds
    dim as double seconds, nextFrameTime, radius
    dim as integer i, j, k
    
    bounds.lft = 0: bounds.rgt = SCREEN_W
    bounds.top = 0: bounds.btm = SCREEN_H
    
    for i = 1 to 15
        radius = int(40 * rnd()) + 15
        ball = AddBall()
        ball->radius = radius
        ball->mass = int(radius / 2)
        ball->velocity *= 3
        ball->colr = Colors.Default
    next i
    
    screenset 1, 0
    
    while inkey() <> chr(27)
        
        renderFrame()
        
        while timer < nextFrameTime: wend
        seconds = timer - nextFrameTime
        nextFrameTime = timer + Pauses.FpsDelay
        
        screencopy 1, 0
        
        
        for i = 0 to ubound(balls)
            ball = @balls(i)
            vectorAdd(ball->position, ball->velocity)
            ball->angle += ball->spin
            while ball->angle >= PI*2: ball->angle -= PI*2: wend
            while ball->angle <  0   : ball->angle += PI*2: wend
            
            if ball->lft < bounds.lft then reverse( ball->velocity.x ): ball->position.x = bounds.lft + ball->radius
            if ball->rgt > bounds.rgt then reverse( ball->velocity.x ): ball->position.x = bounds.rgt - ball->radius
            if ball->top < bounds.top then reverse( ball->velocity.y ): ball->position.y = bounds.top + ball->radius
            if ball->btm > bounds.btm then reverse( ball->velocity.y ): ball->position.y = bounds.btm - ball->radius
            
            for j = 0 to ubound(balls)
                if i = j then continue for
                if ballsIntersect(balls(i), balls(j)) then
                    disentangle(balls(i), balls(j))
                    if ballsNotIntersect(balls(i), balls(j)) then
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
                    bounce(balls(i), balls(j))
                end if
            next j
        next i
        
    wend
    
end sub

sub renderFrame()
    
    cls
    
    DrawBalls
    
    locate 1, 1
    print using "##.##"; totalMomentum
    
end sub

function AddBall(position as VectorType ptr = 0, velocity as VectorType ptr = 0, mass as double = 1.0, radius as double = 1.0, colr as integer = &hffffff) as BallType ptr
    
    dim as BallType ptr ball
    dim as integer index = ubound(balls) + 1
    
    redim preserve balls(index)
    ball = @balls(index)
    
    ball->position = iif(position, *position, vectorFromRandPos(0, 0, SCREEN_W, SCREEN_H))
    ball->velocity = iif(velocity, *velocity, vectorFromRadians())
    ball->mass     = mass
    ball->radius   = radius
    ball->colr     = colr
    
    dim as integer n
    do
        for n = 0 to index-1
            if (ball->position - balls(n).position).size() <= (ball->radius + balls(n).radius) then
                ball->position = vectorFromRandPos(0, 0, SCREEN_W, SCREEN_H)
                continue do
            end if
        next n
        exit do
    loop
    
    return ball
    
end function

sub DrawBalls()
    
    dim as BallType ptr ball
    dim as VectorType center, radius
    dim as integer n
    
    for n = 0 to ubound(balls)
        
        ball   = @balls(n)
        center = ball->position
        
        if ball->colr = &hffffff then
            circle(center.x, center.y), ball->radius, ball->colr
        else
            circle(center.x, center.y), ball->radius, ball->colr, , , , F
        end if
        
        circle(center.x, center.y), ball->radius*0.8, Colors.Spoke, ball->angle+1.33*PI, ball->angle+(1.33+1)*PI
        circle(center.x, center.y), ball->radius*0.5, Colors.Spoke, ball->angle+(0.1+0.67)*PI, ball->angle+(0.9+0.67)*PI
        circle(center.x, center.y), ball->radius*0.2, Colors.Spoke, ball->angle+(0.2)*PI, ball->angle+(0.8)*PI
        
    next n
    
end sub

function vectorFromRandPos(boundLft as double = 0, boundTop as double = 0, boundRgt as double = 0, boundBtm as double = 0) as VectorType
    
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

function vectorFromDegrees(degrees as double = &hCafeBabe) as VectorType
    
    dim as VectorType angle
    
    degrees = iif(degrees = &hCafeBabe, 360*rnd(), degrees)
    
    angle.x = cos(degrees * PI/180)
    angle.y = sin(degrees * PI/180)
    
    return angle
    
end function

function vectorFromRadians(radians as double = &hCafeBabe) as VectorType
    
    dim as VectorType angle
    
    radians = iif(radians = &hCafeBabe, 2*rnd(), radians)
    
    angle.x = cos(radians * PI)
    angle.y = sin(radians * PI)
    
    return angle
    
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
    
    dim as VectorType norm, force
    dim as double mag
    
    '* spin
    norm   = (b.position - a.position).unit().port()
    mag    = a.velocity.size() * a.mass * (dot(a.velocity.unit(),  norm)) _
           + b.velocity.size() * b.mass * (dot(b.velocity.unit(), -norm))
    a.spin -= mag / (a.mass*a.radius*PI*2)
    b.spin += mag / (b.mass*b.radius*PI*2)
    
    '* reflection
    norm   = (b.position - a.position).unit()
    mag    = a.velocity.size() * a.mass * (dot(a.velocity.unit(),  norm)) _
           + b.velocity.size() * b.mass * (dot(b.velocity.unit(), -norm))
    force  = norm * mag
    a.velocity -= force / a.mass
    b.velocity += force / b.mass
    
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
