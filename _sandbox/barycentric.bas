#define clamp(value, min, max) iif(value < min, min, iif(value > max, max, value))

dim shared as integer xres = 800
dim shared as integer yres = 800
screenres xres, yres, 32

function xmap(x as double) as integer
    return xres*(1 + x)\2
end function
function ymap(y as double) as integer
    return yres*(1 - y)\2
end function

type Vector2
    x as double
    y as double
    declare function dot(b as Vector2) as double
    declare function length() as double
    declare function unit() as Vector2
end type
operator - (a as Vector2) as Vector2
    return type(-a.x, -a.y)
end operator
operator + (a as Vector2, b as Vector2) as Vector2
    return type(a.x+b.x, a.y+b.y)
end operator
operator + (a as Vector2, b as double) as Vector2
    return type(a.x+b, a.y+b)
end operator
operator - (a as Vector2, b as Vector2) as Vector2
    return a + -b
end operator
operator - (a as Vector2, b as double) as Vector2
    return a + -b
end operator
operator * (a as Vector2, b as double) as Vector2
    return type(a.x*b, a.y*b)
end operator
operator / (a as Vector2, b as double) as Vector2
    return type(a.x/b, a.y/b)
end operator
function Vector2.dot(a as Vector2) as double
    return x*a.x + y*a.y
end function
function Vector2.length() as double
    return sqr(x*x + y*y)
end function
function Vector2.unit() as Vector2
    return this / length
end function

dim as Vector2 A, B, C
dim as double _a, _b, _c
window (-1, 1)-(1, -1)
line (-1, 0)-(1, 0), &h808080, , &hf0f0
line (0, -1)-(0, 1), &h808080, , &hf0f0

A.x =  0
A.y =  1/2
B.x = -1/2
B.y = -1/3
C.x =  1/2
C.y = -1/3

line(A.x, A.y)-(B.x, B.y), &hff0000
line(B.x, B.y)-(C.x, C.y), &h00ff00
line(C.x, C.y)-(A.x, A.y), &h0000ff

dim as integer lft = xmap(iif(A.x < B.x, iif(A.x < C.x, A.x, C.x), iif(B.x < C.x, B.x, C.x)))
dim as integer rgt = xmap(iif(A.x > B.x, iif(A.x > C.x, A.x, C.x), iif(B.x > C.x, B.x, C.x)))
dim as integer top = ymap(iif(A.y > B.y, iif(A.y > C.y, A.y, C.y), iif(B.y > C.y, B.y, C.y)))
dim as integer btm = ymap(iif(A.y < B.y, iif(A.y < C.y, A.y, C.y), iif(B.y < C.y, B.y, C.y)))
line (lft, top)-(rgt, btm), &hffffff, b, &hdddd
dim as integer red, grn, blu
dim as double u, v, w
dim as Vector2 sideA, sideB, sideC
dim as Vector2 p
A = type(xmap(A.x), ymap(A.y))
B = type(xmap(B.x), ymap(B.y))
C = type(xmap(C.x), ymap(C.y))
dim as Vector2 bas, pro
bas = (C-B).unit: pro = A-B: sideA = B + bas * pro.dot(bas) - A
bas = (A-C).unit: pro = B-C: sideB = C + bas * pro.dot(bas) - B
bas = (B-A).unit: pro = C-A: sideC = A + bas * pro.dot(bas) - C
dim as double colors(2, 2) = {_
    {1, 1, 1},_
    {1, 1, 0},_
    {0, 0, 1}}
window
screenlock
for y as integer = top to btm
    for x as integer = lft to rgt
        p = type<Vector2>(x, y)
        u = 1-(p-A).dot(sideA.unit) / sideA.length
        v = 1-(p-B).dot(sideB.unit) / sideB.length
        w = 1-(p-C).dot(sideC.unit) / sideC.length
        if u < 0 or v < 0 or w < 0 then continue for
        if u > 1 or v > 1 or w > 1 then continue for
        red = int(255 * (u*colors(0,0)+v*colors(1,0)+w*colors(2,0)))
        grn = int(255 * (u*colors(0,1)+v*colors(1,1)+w*colors(2,1)))
        blu = int(255 * (u*colors(0,2)+v*colors(1,2)+w*colors(2,2)))
        pset (x, y), rgb(red, grn, blu)
    next x
next y
screenunlock
sleep
end
