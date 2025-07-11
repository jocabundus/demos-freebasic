type Vector3
    x as double
    y as double
    z as double
    declare constructor()
    declare constructor(x as double, y as double, z as double)
    declare operator += (a as Vector3)
    declare operator -= (a as Vector3)
    declare operator *= (d as double)
    declare operator /= (d as double)
    declare function cross(b as Vector3) as Vector3
    declare function dot(b as Vector3) as double
    declare function length() as double
    declare function rotate(radians as double, axis as integer = 2) as Vector3
    declare function unit() as Vector3
end type
constructor Vector3
end constructor
constructor Vector3(x as double, y as double, z as double)
    this.x = x
    this.y = y
    this.z = z
end constructor
operator - (a as Vector3) as Vector3
    return Vector3(-a.x, -a.y, -a.z)
end operator
operator + (a as Vector3, b as Vector3) as Vector3
    return Vector3(a.x+b.x, a.y+b.y, a.z+b.z)
end operator
operator - (a as Vector3, b as Vector3) as Vector3
    return a + -b
end operator
operator * (a as Vector3, b as double) as Vector3
    return Vector3(a.x*b, a.y*b, a.z*b)
end operator
operator / (a as Vector3, b as double) as Vector3
    return Vector3(a.x/b, a.y/b, a.z/b)
end operator
function vector3_cross(a as Vector3, b as Vector3) as Vector3
    return Vector3(_
        a.y*b.z - a.z*b.y,_
        a.z*b.x - a.x*b.z,_
        a.x*b.y - a.y*b.x _
    )
end function
function vector3_dot(a as Vector3, b as Vector3) as double
    return a.x*b.x + a.y*b.y + a.z*b.z
end function
function vector3_length(a as Vector3) as double
    return sqr(a.x*a.x + a.y*a.y + a.z*a.z)
end function
function vector3_rotate(a as Vector3, radians as double, axis as integer = 2) as Vector3
    dim v as Vector3
    dim as double rcos = cos(radians)
    dim as double rsin = sin(radians)
    select case axis
    case 0
        v.y = a.y * rcos + a.z * -rsin
        v.z = a.y * rsin + a.z *  rcos
    case 1
        v.x = a.x * rcos + a.z * -rsin
        v.z = a.x * rsin + a.z *  rcos
    case 2
        v.x = a.x * rcos + a.y * -rsin
        v.y = a.x * rsin + a.y *  rcos
    end select
    return v
end function
function vector3_unit(a as Vector3) as Vector3
    dim m as double = vector3_length(a)
    return Vector3(a.x/m, a.y/m, a.z/m)
end function
operator Vector3.+= (b as Vector3)
    this = this + b
end operator
operator Vector3.-= (b as Vector3)
    this = this - b
end operator
operator Vector3.*= (d as double)
    this = this * d
end operator
operator Vector3./= (d as double)
    this = this / d
end operator
function Vector3.cross(b as Vector3) as Vector3
    return vector3_cross(this, b)
end function
function Vector3.dot(b as Vector3) as double
    return vector3_dot(this, b)
end function
function Vector3.length() as double
    return vector3_length(this)
end function
function Vector3.rotate(radians as double, axis as integer = 2) as Vector3
    return vector3_rotate(this, radians, axis)
end function
function Vector3.unit() as Vector3
    return vector3_unit(this)
end function
