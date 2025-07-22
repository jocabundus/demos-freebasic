' -----------------------------------------------------------------------------
' Copyright (c) 2025 Joe King
' See main file or LICENSE for license and build info.
' -----------------------------------------------------------------------------
type Vector2
    x as double
    y as double
    declare constructor()
    declare constructor(x as double, y as double)
    declare constructor(radians as double)
    declare function length() as double
    declare function lerped(goal as Vector2, a as double=0.5) as Vector2
    declare function normalized() as Vector2
    declare function rotated(radians as double) as Vector2
    declare function rotatedLeft() as Vector2
    declare function rotatedRight() as Vector2
end type
constructor Vector2
end constructor
constructor Vector2(x as double, y as double)
    this.x = x
    this.y = y
end constructor
constructor Vector2(radians as double)
    this.x = cos(radians)
    this.y = sin(radians)
end constructor
operator abs (a as Vector2) as Vector2
    return type(abs(a.x), abs(a.y))
end operator
operator int (a as Vector2) as Vector2
    return type(int(a.x), int(a.y))
end operator
operator = (a as Vector2, b as Vector2) as boolean
    return a.x=b.x and a.y=b.y
end operator
operator <> (a as Vector2, b as Vector2) as boolean
    return a.x<>b.x or a.y<>b.y
end operator
operator - (a as Vector2) as Vector2
    return type(-a.x, -a.y)
end operator
operator + (a as Vector2, b as Vector2) as Vector2
    return type(a.x+b.x, a.y+b.y)
end operator
operator - (a as Vector2, b as Vector2) as Vector2
    return a + -b
end operator
operator * (a as Vector2, b as Vector2) as Vector2
    return type(a.x*b.x, a.y*b.y)
end operator
operator * (a as Vector2, b as double) as Vector2
    return type(a.x*b, a.y*b)
end operator
operator * (a as double, b as Vector2) as Vector2
    return b * a
end operator
operator / (a as Vector2, b as Vector2) as Vector2
    return type(a.x/b.x, a.y/b.y)
end operator
operator / (a as Vector2, b as double) as Vector2
    return type(a.x/b, a.y/b)
end operator
operator \ (a as Vector2, b as Vector2) as Vector2
    return int(a) / int(b)
end operator
operator \ (a as Vector2, b as double) as Vector2
    return int(a) / int(b)
end operator
operator ^ (a as Vector2, e as double) as Vector2
    return type(a.x^e, a.y^e)
end operator
function cross overload(a as Vector2, b as Vector2) as double
    return a.x*b.y - a.y*b.x
end function
function dot overload(a as Vector2, b as Vector2) as double
    return a.x*b.x + a.y*b.y
end function
function dot overload(a() as Vector2, b as Vector2) as Vector2
    return a(0)*b.x + a(1)*b.y
end function
function dot overload(a() as Vector2, b() as Vector2) as Vector2
    return a(0)*b(0) + a(1)*b(1)
end function
function lerp overload(from as Vector2, goal as Vector2, a as double = 0.5) as Vector2
    a = iif(a < 0, 0, iif(a > 1, 1, a))
    return type(_
        from.x + (goal.x - from.x) * a,_
        from.y + (goal.y - from.y) * a _
    )
end function
function magnitude overload(a as Vector2) as double
    return sqr(a.x*a.x + a.y*a.y)
end function
function normalize overload(a as Vector2) as Vector2
    return a / magnitude(a)
end function
function rotate overload(a as Vector2, radians as double) as Vector2
    dim as double rcos = cos(radians)
    dim as double rsin = sin(radians)
    return type(_
        a.x*rcos + a.y*-rsin,_
        a.x*rsin + a.y* rcos _
    )
end function
function rotate_left overload(a as Vector2) as Vector2
    return type(-a.y, a.x)
end function
function rotate_right overload(a as Vector2) as Vector2
    return type(a.y, -a.x)
end function
function Vector2.length() as double
    return magnitude(this)
end function
function Vector2.lerped(goal as Vector2, a as double=0.5) as Vector2
    return lerp(this, goal, a)
end function
function Vector2.normalized() as Vector2
    return normalize(this)
end function
function Vector2.rotated(radians as double) as Vector2
    return rotate(this, radians)
end function
function Vector2.rotatedLeft() as Vector2
    return rotate_left(this)
end function
function Vector2.rotatedRight() as Vector2
    return rotate_right(this)
end function
