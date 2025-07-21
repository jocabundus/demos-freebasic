#include once "vector3.bi"
type Orientation3
    matrix(0 to 2) as Vector3 = _
    {_
        type(1,  0,  0),_
        type(0,  1,  0),_
        type(0,  0,  1) _
    }
    declare constructor ()
    declare constructor (o0 as Vector3, o1 as Vector3, o2 as Vector3)
    declare property vForward as Vector3
    declare property vForward(newForward as Vector3)
    declare property vRight as Vector3
    declare property vRight(newRight as Vector3)
    declare property vUp as Vector3
    declare property vUp(newUp as Vector3)
    declare function lerped(goal as Orientation3, a as double=0.5) as Orientation3
    declare static function Look(forward as Vector3, worldUp as Vector3 = type(0, 1, 0)) as Orientation3
end type
'===============================================================================
'= CONSTRUCTOR
'===============================================================================
constructor Orientation3
end constructor
constructor Orientation3(o0 as Vector3, o1 as Vector3, o2 as Vector3)
    this.matrix(0) = o0
    this.matrix(1) = o1
    this.matrix(2) = o2
end constructor
'===============================================================================
'= OPERATOR
'===============================================================================
operator - (o as Orientation3) as Orientation3
    return Orientation3(-o.matrix(0), -o.matrix(1), -o.matrix(2))
end operator
operator * (a as Orientation3, b as Orientation3) as Orientation3
    return Orientation3(_
        dot(a.matrix(), b.matrix(0)),_
        dot(a.matrix(), b.matrix(1)),_
        dot(a.matrix(), b.matrix(2)) _
    )
end operator
operator * (a as Orientation3, b as Vector3) as Orientation3
    dim as Vector3 x, y, z
    dim as double radians
    for i as integer = 0 to 2
        select case i
            case Axis3.X: radians = b.x
            case Axis3.Y: radians = b.y
            case Axis3.Z: radians = b.z
        end select
        if radians then
            select case i
            case Axis3.X
                y = rotate(Vector3(0,1,0), radians, i)
                z = rotate(Vector3(0,0,1), radians, i)
                x = cross(y, z)
            case Axis3.Y
                z = rotate(Vector3(0,0,1), radians, i)
                x = rotate(Vector3(1,0,0), radians, i)
                y = cross(z, x)
            case Axis3.Z
                x = rotate(Vector3(1,0,0), radians, i)
                y = rotate(Vector3(0,1,0), radians, i)
                z = cross(x, y)
            end select
            a *= Orientation3(x, y, z)
        end if
    next i
    return a
end operator
'===============================================================================
'= PROPERTY
'===============================================================================
property Orientation3.vForward as Vector3            : return this.matrix(Axis3.Z)      : end property
property Orientation3.vForward(newForward as Vector3): this.matrix(Axis3.Z) = newForward: end property
property Orientation3.vRight as Vector3              : return this.matrix(Axis3.X)      : end property
property Orientation3.vRight(newRight as Vector3)    : this.matrix(Axis3.X) = newRight  : end property
property Orientation3.vUp as Vector3                 : return this.matrix(Axis3.Y)      : end property
property Orientation3.vUp(newUp as Vector3)          : this.matrix(Axis3.Y) = newUp     : end property
'===============================================================================
'= FUNCTION
'===============================================================================
function lerp overload(from as Orientation3, goal as Orientation3, a as double=0.5) as Orientation3
    return type(_
        lerp(from.matrix(0), goal.matrix(0), a),_
        lerp(from.matrix(1), goal.matrix(1), a),_
        lerp(from.matrix(2), goal.matrix(2), a) _
    )
end function
'===============================================================================
'= METHODS
'===============================================================================
function Orientation3.lerped(goal as Orientation3, a as double=0.5) as Orientation3
    return lerp(this, goal, a)
end function
function Orientation3.Look(forward as Vector3, worldUp as Vector3 = type(0, 1, 0)) as Orientation3
    dim as Vector3 rght, up
    forward = normalize(forward)
    rght = normalize(cross(forward, worldUp))
    up   = normalize(cross(forward, rght))
    return Orientation3(rght, up, forward)
end function
