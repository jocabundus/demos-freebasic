#include "fbgfx.bi"
using FB

type VectorType
    x as double
    y as double
    z as double
    w as double
end type

type PolyType
    v(2) as VectorType
    colr as integer
end type

type OrientationType
    up as VectorType
    forward as VectorType
    starboard as VectorType
end type

type ObjectType
    polyIndex as integer
    polyCount as integer
    location as VectorType
    orientation as OrientationType
end type

enum ObjectIds
    Cube = 0
    Pyramid = 1
    Aeroplane = 2
end enum

declare function percentToX(x as double) as integer
declare function percentToY(y as double) as integer
declare sub putPixel(x as integer, y as integer, colr as integer = &hffffff)
declare sub drawLine(x0 as integer, y0 as integer, x1 as integer, y1 as integer, colr as integer = &hffffff)
declare sub drawVector(v as VectorType, colr as integer = &hff0000)
declare sub drawPoly(p as PolyType)
declare sub drawObject(o as ObjectType, polys() as PolyType)
declare sub transformObject overload(o as ObjectType, polys() as PolyType, callback as sub(byref p as PolyType, byval v as VectorType), v as VectorType)
declare sub transformObject overload(o as ObjectType, polys() as PolyType, callback as sub(byref p as PolyType, byref ori as OrientationType), byref ori as OrientationType)
declare sub cloneVector(v as VectorType, src as VectorType)
declare sub cloneObject(o as ObjectType, src as ObjectType, polys() as PolyType)
declare sub vectorToAngle(v as VectorType, a as double)
declare sub rotateX(v as VectorType, a as double)
declare sub rotateY(v as VectorType, a as double)
declare sub rotateZ(v as VectorType, a as double)
declare sub makeQuad(v as VectorType, w as double, x as double, y as double, z as double)
declare sub toQuat(byref v as VectorType)
declare sub mulQuads(byref v as VectorType, byref q as VectorType)
declare sub setZoom(z as double = 1.0)
declare sub cross2d(v as VectorType)

declare sub orientPoly(byref p as PolyType, byref o as OrientationType)
declare sub panPoly(byref p as PolyType, byval v as VectorType)
declare sub rotatePoly(byref p as PolyType, byval v as VectorType)
declare sub rotateVector(byref v as VectorType, byval rot as VectorType)
declare sub unitVector(byref v as VectorType)
declare sub crossVectors(u as VectorType, v as VectorType)

declare sub zeroVector(byref v as VectorType)
declare sub addVectors(byref v as VectorType, byref u as VectorType)
declare sub subVectors(byref v as VectorType, byref u as VectorType)
declare sub mulVector(byref v as VectorType, byval m as double)
declare sub mulVectors(byref v as VectorType, byref u as VectorType)

declare sub resetOrientation(byref o as OrientationType)
declare sub orientUp(byref o as OrientationType, w as double)
declare sub orientForward(byref o as OrientationType, w as double)
declare sub orientStarboard(byref o as OrientationType, w as double)

dim shared as integer SCREEN_W, SCREEN_H, SCREEN_BPP
dim shared as integer CENTER_X, CENTER_Y
dim shared as double ZOOM = 1.0
CONST PI = 3.141592
CONST FULLSCREEN = 0

dim shared camera as ObjectType

dim polys(99) as PolyType
dim objects(9) as ObjectType
dim polyCount as integer
dim as integer i, j, n

polyCount = 19
for i = 0 to polyCount-1
    for j = 0 to 2
        read polys(i).v(j).x, polys(i).v(j).y, polys(i).v(j).z
    next j
    read polys(i).colr
next i

dim as VectorType v, q
dim as PolyType p
dim as ObjectType o
dim as ObjectType ptr op

objects( ObjectIds.Cube ).polyIndex = 0
objects( ObjectIds.Cube ).polyCount = 12
objects( ObjectIds.Pyramid ).polyIndex = 12
objects( ObjectIds.Pyramid ).polyCount = 5
objects( ObjectIds.Aeroplane ).polyIndex = 17
objects( ObjectIds.Aeroplane ).polyCount = 2
objects( ObjectIds.Aeroplane ).location.y = -1

resetOrientation objects( ObjectIds.Cube ).orientation
resetOrientation objects( ObjectIds.Pyramid ).orientation
resetOrientation objects( ObjectIds.Aeroplane ).orientation


screeninfo SCREEN_W, SCREEN_H, SCREEN_BPP
if FULLSCREEN then
    screenres SCREEN_W, SCREEN_H, SCREEN_BPP, 2, 1
else
    SCREEN_W *= 0.6667: SCREEN_H *= 0.6667
    screenres SCREEN_W, SCREEN_H, SCREEN_BPP, 2, 0
end if
screenset 1, 0
CENTER_X = percentToX(50)
CENTER_Y = percentToY(50)

setZoom 10

dim shared as double t, a

zeroVector camera.location
resetOrientation camera.orientation

a = 0
do
    cls
    drawLine -CENTER_X, 0, CENTER_X, 0, &h7f7f7f
    drawLine 0, -CENTER_Y, 0, CENTER_Y, &h7f7f7f
    
    cloneObject o, objects( ObjectIds.Aeroplane ), polys()
    
    transformObject o, polys(), @orientPoly, o.orientation
    
    subVectors o.location, camera.location
    transformObject o, polys(), @panPoly, o.location
    
    transformObject o, polys(), @orientPoly, camera.orientation
    
    drawObject o, polys()
    
    'v.x = 0: v.y = 0:. v.z = 0
    'p.v(0) = v: p.v(1) = up     : p.v(2) = starboard: p.colr = &hff0000
    'panPoly p, o.location: drawPoly p
    'p.v(0) = v: p.v(1) = up     : p.v(2) = forward  : p.colr = &h00ff00
    'panPoly p, o.location: drawPoly p
    'p.v(0) = v: p.v(1) = forward: p.v(2) = starboard: p.colr = &h0000ff
    'panPoly p, o.location: drawPoly p
    
    screensync
    screencopy
    
    't = timer+0.015: while timer < t: wend
    a += 1
    op = @objects( ObjectIds.Aeroplane )
    
    if multikey(SC_ESCAPE) then exit do
    if multikey(SC_LSHIFT) then
        if multikey(SC_A) then
            camera.location.y += 0.1
        end if
        if multikey(SC_Z) then
            camera.location.y -= 0.1
        end if
        if multikey(SC_UP) then
            camera.location.z += 0.1
        end if
        if multikey(SC_DOWN) then
            camera.location.z -= 0.1
        end if
        if multikey(SC_LEFT) then
            camera.location.x -= 0.1
        end if
        if multikey(SC_RIGHT) then
            camera.location.x += 0.1
        end if
    else
        if multikey(SC_A) then
            orientUp camera.orientation, 1
        end if
        if multikey(SC_Z) then
            orientUp camera.orientation, -1
        end if
        if multikey(SC_UP) then
            orientStarboard camera.orientation, 1
        end if
        if multikey(SC_DOWN) then
            orientStarboard camera.orientation, -1
        end if
        if multikey(SC_LEFT) then
            orientForward camera.orientation, 1
        end if
        if multikey(SC_RIGHT) then
            orientForward camera.orientation, -1
        end if
    end if
loop
end

sub orientUp(byref o as OrientationType, w as double)
    
    o.up.w = w
    rotateVector o.forward  , o.up: unitVector o.forward
    rotateVector o.starboard, o.up: unitVector o.starboard
    
end sub

sub orientForward(byref o as OrientationType, w as double)
    
    o.forward.w = w
    rotateVector o.up       , o.forward: unitVector o.up
    rotateVector o.starboard, o.forward: unitVector o.starboard
    
end sub

sub orientStarboard(byref o as OrientationType, w as double)
    
    o.starboard.w = w
    rotateVector o.up     , o.starboard: unitVector o.up
    rotateVector o.forward, o.starboard: unitVector o.forward
    
end sub

sub panPoly(byref p as PolyType, byval v as VectorType)
    
    dim n as integer
    
    for n = 0 to 2
        addVectors p.v(n), v
    next n
    
end sub

sub zeroVector(byref v as VectorType)
    
    v.x = 0: v.y = 0: v.z = 0: v.w = 0
    
end sub

sub resetOrientation(byref o as OrientationType)
    
    o.up.w        = 0: o.up.x        = 0: o.up.y        = 1: o.up.z        = 0
    o.forward.w   = 0: o.forward.x   = 0: o.forward.y   = 0: o.forward.z   = 1
    o.starboard.w = 0: o.starboard.x = 1: o.starboard.y = 0: o.starboard.z = 0
    
end sub

sub orientPoly(byref p as PolyType, byref o as OrientationType)
    
    dim as VectorType u, v, w
    dim as integer n
    
    for n = 0 to 2
        u = o.up       : mulVector u, p.v(n).y
        v = o.forward  : mulVector v, p.v(n).z
        w = o.starboard: mulVector w, p.v(n).x
        p.v(n) = u
        addVectors p.v(n), v
        addVectors p.v(n), w
    next n
    
end sub

sub addVectors(byref v as VectorType, byref u as VectorType)
    
    v.x += u.x
    v.y += u.y
    v.z += u.z
    v.w += u.w
    
end sub

sub subVectors(byref v as VectorType, byref u as VectorType)
    
    v.x -= u.x
    v.y -= u.y
    v.z -= u.z
    v.w -= u.w
    
end sub

sub mulVector(byref v as VectorType, byval m as double)
    
    v.x *= m
    v.y *= m
    v.z *= m
    v.w *= m
    
end sub

sub mulVectors(byref v as VectorType, byref u as VectorType)
    
    v.x *= u.x
    v.y *= u.y
    v.z *= u.z
    v.w *= u.w
    
end sub

sub unitVector(byref v as VectorType)
    
    dim as double m
    
    m = sqr(v.x*v.x + v.y*v.y + v.z*v.z)
    if m > 0 then
        v.x /= m
        v.y /= m
        v.z /= m
    end if
    
end sub

sub rotateVector(byref v as VectorType, byval rot as VectorType)
    
    dim as VectorType irot
    
    irot = rot
    irot.x = -irot.x: irot.y = -irot.y: irot.z = -irot.z
    toQuat( rot ): toQuat( irot )
    mulQuads(rot, v): mulQuads(rot, irot)
    v = rot
    
end sub

sub rotatePoly(byref p as PolyType, byval rot as VectorType)
    
    dim as VectorType irot, r
    dim as integer n
    
    irot = rot
    irot.x = -irot.x: irot.y = -irot.y: irot.z = -irot.z
    toQuat( rot ): toQuat( irot )
    
    for n = 0 to 2
        r = rot
        mulQuads(r, p.v(n)): mulQuads(r, irot)
        p.v(n) = r
    next n
    
end sub

sub toQuat(byref v as VectorType)
    
    dim as double w
    
    w   = v.w * 0.5 * PI/180
    v.w = cos(w): v.x *= sin(w): v.y *= sin(w): v.z *= sin(w)
    
end sub

sub makeQuad(v as VectorType, w as double, x as double, y as double, z as double)
    
    vectorToAngle(v, 0): rotateZ(v, z): rotateY(v, y): rotateX(v, x)
    toQuat( v )
    
end sub

sub mulQuads(byref v as VectorType, byref q as VectorType)
    
    dim u as VectorType
    
    u.w = v.w*q.w - v.x*q.x - v.y*q.y - v.z*q.z
    u.x = v.w*q.x + v.x*q.w + v.y*q.z - v.z*q.y
    u.y = v.w*q.y - v.x*q.z + v.y*q.w + v.z*q.x
    u.z = v.w*q.z + v.x*q.y - v.y*q.x + v.z*q.w
    
    v.w = u.w: v.x = u.x: v.y = u.y: v.z = u.z
    
end sub

sub setZoom(z as double = 1.0)
    
    ZOOM = z
    
end sub

sub cross2d(v as VectorType)
    
    ' i( x + yi )
    ' xi + yii
    ' xi - y
    '
    ' x = -y
    ' y =  x
    
    v.x = -v.y
    v.y =  v.x
    
end sub

'[w + xi + yj + zk][a + bi + cj + dk]
'   wa  + wbi  + wcj  +  wdk
' + xia + xbii + xcij + xdik
' + yaj + ybji + ycjj + ydjk
' + zak + zbki + zckj + zdkk
'
'   wa  + wbi  + wcj  + wdk
' + xai - xb   + xck  - xdj
' + yaj - ybk  - yc   + ydi
' + zak + zbj  - zci  - zd
'
' 1( wa - xb - yc - zd )
' i( wb + xa + yd - zc )
' j( wc - xd + ya + zb )
' k( wd + xc - yb + za )
sub crossVectors(u as VectorType, v as VectorType)
    
    ' 1( 10 - xb - yc - zd )
    ' i( 1b + x0 + yd - zc )
    ' j( 1c - xd + y0 + zb )
    ' k( 1d + xc - yb + z0 )
    '
    ' 1(  0 - xb - yc - zd )
    ' i(  b +  0 + yd - zc )
    ' j(  c - xd +  0 + zb )
    ' k(  d + xc - yb +  0 )
    '
    ' -1( xb + yc + zd )
    '  i(  b + yd - zc )
    '  j(  c - xd + zb )
    '  k(  d + xc - yb )
    '
    ' x = b + yd - zc
    ' y = c - xd + za
    ' z = d + xc - ya
    
    dim as VectorType a, b, p, r
    
    a = u: unitVector( a )
    b = v: unitVector( b )
    
    p.x = (a.x + b.x) * 0.5
    p.y = (a.y + b.y) * 0.5
    p.z = (a.z + b.z) * 0.5
    p.w = 0
    
    r.x = a.x - b.x
    r.y = a.y - b.y
    r.z = a.z - b.z
    r.w = 90
    
    rotateVector p, r
    unitVector( p )
    
    v = p
    
end sub

sub rotateX(v as VectorType, a as double)
    
    dim r as VectorType
    dim z as double
    
    vectorToAngle(r, a)
    
    z = v.z
    v.z = v.z * r.x - v.y * r.y
    v.y = z   * r.y + v.y * r.x
    
end sub

sub rotateY(v as VectorType, a as double)
    
    dim r as VectorType
    dim x as double
    
    vectorToAngle(r, a)
    
    x = v.x
    v.x = v.x * r.x - v.z * r.y
    v.z = x   * r.y + v.z * r.x
    
end sub

sub rotateZ(v as VectorType, a as double)
    
    dim r as VectorType
    dim x as double
    
    vectorToAngle(r, a)
    
    x = v.x
    v.x = v.x * r.x - v.y * r.y
    v.y = x   * r.y + v.y * r.x
    
end sub

sub vectorToAngle(v as VectorType, a as double)
    
    v.x = cos(a*PI/180)
    v.y = sin(a*PI/180)
    v.z = 0
    v.w = 1
    
end sub

function percentToX(x as double) as integer
    
    return int(x*0.01*SCREEN_W)
    
end function

function percentToY(y as double) as integer
    
    return int(y*0.01*SCREEN_H)
    
end function

sub putPixel(x as integer, y as integer, colr as integer = &hffffff)

    pset (CENTER_X+x, CENTER_Y-y), colr

end sub

sub drawLine(x0 as integer, y0 as integer, x1 as integer, y1 as integer, colr as integer = &hffffff)
    
    line (CENTER_X+x0, CENTER_Y-y0)-(CENTER_X+x1, CENTER_Y-y1), colr
    
end sub

sub drawVector(v as VectorType, colr as integer = &hff0000)
    
    dim as double x, y, z
    z = ZOOM + v.z
    if z = 0 then
        x = v.x
        y = v.y
    else
        x = v.x/z
        y = v.y/z
    end if
    x *= SCREEN_H
    y *= SCREEN_H
    drawLine 0, 0, x, y, colr

end sub

sub drawPoly(p as PolyType)
    
    dim as VectorType ptr v
    dim as double x, y, z
    dim as double a, b, c, d
    dim as integer n
    
    for n = 0 to 2
        v = @p.v(n)
        z = ZOOM + v->z
        if z = 0 then
            x = v->x
            y = v->y
        else
            x = v->x/z
            y = v->y/z
        end if
        x *= SCREEN_H
        y *= SCREEN_H
        select case n
        case 0
            a = x: b = y
        case 1
            drawLine a, b, x, y, p.colr
            c = x: d = y
        case 2
            drawLine c, d, x, y, p.colr
            drawLine x, y, a, b, p.colr
        end select
    next n
    
    dim as VectorType u, norm
    dim as integer drawNormal = 0
    
    if drawNormal then
        u.x = (p.v(0).x + p.v(1).x + p.v(2).x) / 3
        u.y = (p.v(0).y + p.v(1).y + p.v(2).y) / 3
        u.z = (p.v(0).z + p.v(1).z + p.v(2).z) / 3
        c = ZOOM + u.z
        a = (u.x / iif(c <> 0, c, 1)) * SCREEN_H
        b = (u.y / iif(c <> 0, c, 1)) * SCREEN_H
        norm = p.v(0): crossVectors( norm, p.v(1) )
        u.x += norm.x: u.y += norm.y: u.z += norm.z
        z = ZOOM + u.z
        x = (u.x / iif(c <> 0, z, 1)) * SCREEN_H
        y = (u.y / iif(c <> 0, z, 1)) * SCREEN_H
        drawLine a, b, x, y, &hffff00
    end if

end sub

sub drawObject(o as ObjectType, polys() as PolyType)
    
    dim as PolyType p
    dim as integer idx0, idx1
    dim as integer n
    
    idx0 = o.polyIndex
    idx1 = idx0 + o.polyCount
    for n = idx0 to idx1-1
        p = polys(n)
        drawPoly p
    next n
    
end sub

sub transformObject(o as ObjectType, polys() as PolyType, callback as sub(byref p as PolyType, byval v as VectorType), v as VectorType)
    
    dim as integer idx0, idx1
    dim as integer n
    
    idx0 = o.polyIndex
    idx1 = idx0 + o.polyCount
    for n = idx0 to idx1-1
        callback( polys(n), v )
    next n
    
end sub

sub transformObject(o as ObjectType, polys() as PolyType, callback as sub(byref p as PolyType, byref o as OrientationType), byref ori as OrientationType)
    
    dim as integer idx0, idx1
    dim as integer n
    
    idx0 = o.polyIndex
    idx1 = idx0 + o.polyCount
    for n = idx0 to idx1-1
        callback( polys(n), ori )
    next n
    
end sub

sub cloneVector(v as VectorType, src as VectorType)
    
    v.x = src.x
    v.y = src.y
    v.z = src.z
    v.w = src.w
    
end sub

sub cloneObject(o as ObjectType, src as ObjectType, polys() as PolyType)
    
    dim as PolyType cp
    dim as integer n
    
    o.polyIndex = 50
    o.polyCount = src.polyCount
    cloneVector o.location, src.location
    cloneVector o.orientation.up       , src.orientation.up
    cloneVector o.orientation.forward  , src.orientation.forward
    cloneVector o.orientation.starboard, src.orientation.starboard
    
    for n = 0 to o.polyCount-1
        cp = polys(src.polyIndex+n)
        polys(o.polyIndex+n) = cp
    next n
    
end sub

'data -1,-1,  +1,-1,  -1,+1
'data -1,+1,  +1,-1,  +1,+1

'=======================================================================
'= CUBE
'=======================================================================
' top
data -1,+1,-1,  +1,+1,-1,  -1,+1,+1, &hffff00
data -1,+1,+1,  +1,+1,-1,  +1,+1,+1, &hffff00
' bottom
data -1,-1,-1,  +1,-1,-1,  -1,-1,+1, &h00ffff
data -1,-1,+1,  +1,-1,-1,  +1,-1,+1, &h00ffff
' left
data -1,+1,-1,  -1,-1,-1,  -1,+1,+1, &hffff00
data -1,+1,+1,  -1,-1,-1,  -1,-1,+1, &hffff00
' right
data +1,+1,-1,  +1,-1,-1,  +1,+1,+1, &h00ffff
data +1,+1,+1,  +1,-1,-1,  +1,-1,+1, &h00ffff
' back
data -1,+1,-1,  +1,+1,-1,  -1,-1,-1, &hffff00
data -1,-1,-1,  +1,+1,-1,  +1,-1,-1, &hffff00
' front
data -1,+1,+1,  +1,+1,+1,  -1,-1,+1, &h00ffff
data -1,-1,+1,  +1,+1,+1,  +1,-1,+1, &h00ffff

'=======================================================================
'= PYRAMID
'=======================================================================
data  0,+1, 0,  +1,-1,-1,  +1,-1,+1, &hffffff
data  0,+1, 0,  +1,-1,-1,  -1,-1,-1, &h7f7f7f
data  0,+1, 0,  -1,-1,-1,  -1,-1,+1, &hffffff
data  0,+1, 0,  +1,-1,+1,  -1,-1,+1, &hffffff
data -.25,-1,-.5, 0,-1,+.5, +.25,-1,-.5, &hff0000

'=======================================================================
'= AEROPLANE
'=======================================================================
data 0,0,1, 1,0,-1, -1,0,-1, &hdfdfdf
data 0,0,1, 0,1,-1,  0,0,-1, &hdfdfdf
