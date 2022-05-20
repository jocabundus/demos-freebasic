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

type ObjectType
    polyIndex as integer
    polyCount as integer
end type

enum ObjectIds
    Cube = 0
    Pyramid = 1
end enum

declare function percentToX(x as double) as integer
declare function percentToY(y as double) as integer
declare sub putPixel(x as integer, y as integer, colr as integer = &hffffff)
declare sub drawLine(x0 as integer, y0 as integer, x1 as integer, y1 as integer, colr as integer = &hffffff)
declare sub drawVector(v as VectorType, colr as integer = &hff0000)
declare sub drawPoly(p as PolyType)
declare sub drawObject(o as ObjectType, polys() as PolyType)
declare sub transformObject(o as ObjectType, polys() as PolyType, callback as sub(p as PolyType))
declare sub cloneObject(o as ObjectType, src as ObjectType, polys() as PolyType)
declare sub vectorToAngle(v as VectorType, a as double)
declare sub rotateX(v as VectorType, a as double)
declare sub rotateY(v as VectorType, a as double)
declare sub rotateZ(v as VectorType, a as double)
declare sub makeQuad(v as VectorType, w as double, x as double, y as double, z as double)
declare sub mulQuads(v as VectorType, q as VectorType)
declare sub setZoom(z as double = 1.0)
declare sub cross2d(v as VectorType)

declare sub rotatePoly(p as PolyType)

dim shared as integer SCREEN_W, SCREEN_H, SCREEN_BPP
dim shared as integer CENTER_X, CENTER_Y
dim shared as double ZOOM = 1.0
CONST PI = 3.141592

dim polys(99) as PolyType
dim objects(9) as ObjectType
dim polyCount as integer
dim as integer i, j, n

polyCount = 17
for i = 0 to polyCount-1
    for j = 0 to 2
        read polys(i).v(j).x, polys(i).v(j).y, polys(i).v(j).z
    next j
    read polys(i).colr
next i

objects( ObjectIds.Cube ).polyIndex = 0
objects( ObjectIds.Cube ).polyCount = 12
objects( ObjectIds.Pyramid ).polyIndex = 12
objects( ObjectIds.Pyramid ).polyCount = 5


screeninfo SCREEN_W, SCREEN_H, SCREEN_BPP
screenres SCREEN_W, SCREEN_H, SCREEN_BPP, 2, 1
screenset 1, 0
CENTER_X = percentToX(50)
CENTER_Y = percentToY(50)

setZoom 10

dim as VectorType v
dim as VectorType r
dim as PolyType p
dim as ObjectType o

dim shared as double t, a

a = 0
do
    cls
    drawLine -CENTER_X, 0, CENTER_X, 0, &h7f7f7f
    drawLine 0, -CENTER_Y, 0, CENTER_Y, &h7f7f7f
    
    cloneObject o, objects( ObjectIds.Pyramid ), polys()
    transformObject o, polys(), @rotatePoly
    drawObject o, polys()
    
    screensync
    screencopy
    
    't = timer+0.015: while timer < t: wend
    a += 1
    
    if inkey = chr(27) then exit do
loop
end

sub rotatePoly(p as PolyType)
    
    dim as VectorType q, rot, irot
    dim as integer n
    
    makeQuad(rot, a, 0, 0, 30): irot = rot
    irot.x = -irot.x: irot.y = -irot.y: irot.z = -irot.z
    
    for n = 0 to 2
        q = rot
        mulQuads(q, p.v(n)): mulQuads(q, irot)
        p.v(n) = q
    next n
    
end sub

sub makeQuad(v as VectorType, w as double, x as double, y as double, z as double)
    
    vectorToAngle(v, 0): rotateX(v, x): rotateY(v, y): rotateZ(v, z)
    w   = w * 0.5 * PI/180
    v.w = cos(w): v.x *= sin(w): v.y *= sin(w): v.z *= sin(w)
    
end sub

sub mulQuads(v as VectorType, q as VectorType)
    
    '[s + xi + yj + zk][t + ai +bj + ck]
    '
    '   st  + sai  + sbj  + sck
    ' + xti + xaii + xbij + xcik
    ' + ytj + yaji + ybjj + ycjk
    ' + ztk + zaki + zbjk + zckk
    '
    '   st  + sai  + sbj  + sck
    ' + xti - xa   + xbk  - xcj
    ' + ytj - yak  - yb   + yci
    ' + ztk + zaj  - zbi  - zc
    '
    ' st  - xa  - yb  - zc
    ' sai + xti + yci - zbi
    ' sbj - xcj + ytj + zaj
    ' sck + xbk - yak + ztk
    '
    ' w = st - xa - yb - zc
    ' x = sa + xt + yc - zb
    ' y = sb - xc + yt + za
    ' z = sc + xb - ya + zt
    
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
    
    '(x + y(i))(i)
    'x(i) + y(i^2)
    'x(i) - y
    
    v.x = -v.y
    v.y =  v.x
    
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

sub transformObject(o as ObjectType, polys() as PolyType, callback as sub(p as PolyType))
    
    dim as integer idx0, idx1
    dim as integer n
    
    idx0 = o.polyIndex
    idx1 = idx0 + o.polyCount
    for n = idx0 to idx1-1
        callback( polys(n) )
    next n
    
end sub

sub cloneObject(o as ObjectType, src as ObjectType, polys() as PolyType)
    
    dim as PolyType cp
    dim as integer n
    
    o.polyIndex = 50
    o.polyCount = src.polyCount
    
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
