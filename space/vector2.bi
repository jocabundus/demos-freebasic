type Vector2
    x as double
    y as double
    z as double
    declare constructor()
    declare constructor(x as double, y as double)
    declare constructor(radians as double)
    declare operator += (a as Vector2)
    declare operator -= (a as Vector2)
    declare operator *= (d as double)
    declare operator /= (d as double)
    declare function cross(b as Vector2) as double
    declare function dot(b as Vector2) as double
    declare function length() as double
    declare function rotate(radians as double) as Vector2
    declare function toLeft() as Vector2
    declare function toRight() as Vector2
    declare function unit() as Vector2
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
operator - (a as Vector2) as Vector2
    return Vector2(-a.x, -a.y)
end operator
operator + (a as Vector2, b as Vector2) as Vector2
    return Vector2(a.x+b.x, a.y+b.y)
end operator
operator - (a as Vector2, b as Vector2) as Vector2
    return a + -b
end operator
operator * (a as Vector2, b as double) as Vector2
    return Vector2(a.x*b, a.y*b)
end operator
operator / (a as Vector2, b as double) as Vector2
    return Vector2(a.x/b, a.y/b)
end operator
function vector2_cross(a as Vector2, b as Vector2) as double
    return a.x*b.y - a.y*b.x
end function
function vector2_dot(a as Vector2, b as Vector2) as double
    return a.x*b.x + a.y*b.y
end function
function vector2_length(a as Vector2) as double
    return sqr(a.x*a.x + a.y*a.y)
end function
function vector2_rotate(a as Vector2, radians as double) as Vector2
    dim as double rcos = cos(radians)
    dim as double rsin = sin(radians)
    return Vector2(_
        a.x*rcos + a.y*-rsin,_
        a.x*rsin + a.y* rcos _
    )
end function
function vector2_to_left(a as Vector2) as Vector2
    return Vector2(-a.y, a.x)
end function
function vector2_to_right(a as Vector2) as Vector2
    return Vector2(a.y, -a.x)
end function
function vector2_unit(a as Vector2) as Vector2
    dim m as double = vector2_length(a)
    return Vector2(a.x/m, a.y/m)
end function
operator Vector2.+= (b as Vector2)
    this = this + b
end operator
operator Vector2.-= (b as Vector2)
    this = this - b
end operator
operator Vector2.*= (d as double)
    this = this * d
end operator
operator Vector2./= (d as double)
    this = this / d
end operator
function Vector2.cross(b as Vector2) as double
    return Vector2_cross(this, b)
end function
function Vector2.dot(b as Vector2) as double
    return Vector2_dot(this, b)
end function
function Vector2.length() as double
    return Vector2_length(this)
end function
function Vector2.rotate(radians as double) as Vector2
    return Vector2_rotate(this, radians)
end function
function Vector2.toLeft() as Vector2
    return vector2_to_left(this)
end function
function Vector2.toRight() as Vector2
    return vector2_to_right(this)
end function
function Vector2.unit() as Vector2
    return vector2_unit(this)
end function
