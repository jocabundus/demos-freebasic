type Vector3
    x as double
    y as double
    z as double
    declare constructor()
    declare constructor(x as double, y as double, z as double)
    declare function cross(b as Vector3) as Vector3
    declare function dot(b as Vector3) as double
    declare function length() as double
    declare function lerp(goal as Vector3, a as double=0.5) as Vector3
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
operator abs (a as Vector3) as Vector3
    return type(abs(a.x), abs(a.y), abs(a.z))
end operator
operator int (a as Vector3) as Vector3
    return type(int(a.x), int(a.y), int(a.z))
end operator
operator - (a as Vector3) as Vector3
    return type(-a.x, -a.y, -a.z)
end operator
operator + (a as Vector3, b as Vector3) as Vector3
    return type(a.x+b.x, a.y+b.y, a.z+b.z)
end operator
operator - (a as Vector3, b as Vector3) as Vector3
    return a + -b
end operator
operator * (a as Vector3, b as Vector3) as Vector3
    return type(a.x*b.x, a.y*b.y, a.z*b.z)
end operator
operator * (a as Vector3, b as double) as Vector3
    return type(a.x*b, a.y*b, a.z*b)
end operator
operator * (a as double, b as Vector3) as Vector3
    return b * a
end operator
operator / (a as Vector3, b as Vector3) as Vector3
    return type(a.x/b.x, a.y/b.y, a.z/b.z)
end operator
operator / (a as Vector3, b as double) as Vector3
    return type(a.x/b, a.y/b, a.z/b)
end operator
operator \ (a as Vector3, b as Vector3) as Vector3
    return int(a) / int(b)
end operator
operator \ (a as Vector3, b as double) as Vector3
    return int(a) / int(b)
end operator
operator ^ (a as Vector3, e as double) as Vector3
    return type(a.x^e, a.y^e, a.z^e)
end operator
function vector3_cross(a as Vector3, b as Vector3) as Vector3
    return type(_
        a.y*b.z - a.z*b.y,_
        a.z*b.x - a.x*b.z,_
        a.x*b.y - a.y*b.x _
    )
end function
function vector3_dot overload(a as Vector3, b as Vector3) as double
    return a.x*b.x + a.y*b.y + a.z*b.z
end function
function vector3_dot overload(a() as Vector3, b as Vector3) as Vector3
    return a(0)*b.x + a(1)*b.y + a(2)*b.z
end function
function vector3_dot overload(a() as Vector3, b() as Vector3) as Vector3
    return a(0)*b(0) + a(1)*b(1) + a(2)*b(2)
end function
function vector3_exp(a as Vector3, power as double) as Vector3
    return a * exp(power)
end function
function vector3_length(a as Vector3) as double
    return sqr(a.x*a.x + a.y*a.y + a.z*a.z)
end function
function vector3_lerp(from as Vector3, goal as Vector3, a as double = 0.5) as Vector3
    a = iif(a < 0, 0, iif(a > 1, 1, a))
    a = 1 - exp(-4.0 * a)
    return type(_
        from.x + (goal.x - from.x) * a,_
        from.y + (goal.y - from.y) * a,_
        from.z + (goal.z - from.z) * a _
    )
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
        v.z = a.z * rcos + a.x * -rsin
        v.x = a.z * rsin + a.x *  rcos
    case 2
        v.x = a.x * rcos + a.y * -rsin
        v.y = a.x * rsin + a.y *  rcos
    end select
    return v
end function
function vector3_unit(a as Vector3) as Vector3
    dim m as double = vector3_length(a)
    return type(a.x/m, a.y/m, a.z/m)
end function
function Vector3.cross(b as Vector3) as Vector3
    return vector3_cross(this, b)
end function
function Vector3.dot(b as Vector3) as double
    return vector3_dot(this, b)
end function
function Vector3.length() as double
    return vector3_length(this)
end function
function Vector3.lerp(goal as Vector3, a as double=0.5) as Vector3
    return vector3_lerp(this, goal, a)
end function
function Vector3.rotate(radians as double, axis as integer = 2) as Vector3
    return vector3_rotate(this, radians, axis)
end function
function Vector3.unit() as Vector3
    return vector3_unit(this)
end function
