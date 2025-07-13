#include once "vector3.bi"
type Orientation3
    const AXIS_X = 0
    const AXIS_Y = 1
    const AXIS_Z = 2
    matrix(0 to 2) as Vector3 = _
    {_
        type(1,  0,  0),_
        type(0,  1,  0),_
        type(0,  0, -1) _
    }
    declare property vForward as Vector3
    declare property vForward(newForward as Vector3)
    declare property vRight as Vector3
    declare property vRight(newRight as Vector3)
    declare property vUp as Vector3
    declare property vUp(newUp as Vector3)
    declare function rotate(axisRotations as Vector3) as Orientation3
end type
property Orientation3.vForward as Vector3            : return this.matrix(AXIS_Z)     : end property
property Orientation3.vForward(newForward as Vector3): this.matrix(AXIS_Z) = newForward: end property
property Orientation3.vRight as Vector3              : return this.matrix(AXIS_X)     : end property
property Orientation3.vRight(newRight as Vector3)    : this.matrix(AXIS_X) = newRight : end property
property Orientation3.vUp as Vector3                 : return this.matrix(AXIS_Y)     : end property
property Orientation3.vUp(newUp as Vector3)          : this.matrix(AXIS_Y) = newUp    : end property
function Orientation3.rotate(axisRotations as Vector3) as Orientation3
    dim as double radians
    dim as Orientation3 o = this
    for i as integer = 0 to 2
        select case i
            case AXIS_X: radians = axisRotations.x
            case AXIS_Y: radians = axisRotations.y
            case AXIS_Z: radians = axisRotations.z
        end select
        if radians then
            dim as Vector3 vR = o.vRight
            dim as Vector3 vU = o.vUp
            dim as Vector3 vF = o.vForward
            dim as Vector3 x, y, z
            select case i
            case AXIS_X
                y = vector3_rotate(Vector3(0,1,0), radians, i)
                z = vector3_rotate(Vector3(0,0,1), radians, i)
                x = vector3_cross(y, z)
            case AXIS_Y
                z = vector3_rotate(Vector3(0,0,1), radians, i)
                x = vector3_rotate(Vector3(1,0,0), radians, i)
                y = vector3_cross(z, x)
            case AXIS_Z
                x = vector3_rotate(Vector3(1,0,0), radians, i)
                y = vector3_rotate(Vector3(0,1,0), radians, i)
                z = vector3_cross(x, y)
            end select
            o.vForward = ((vR*z.x + vU*z.y + vF*z.z).unit)
            o.vUp      = ((vR*y.x + vU*y.y + vF*y.z).unit)
            o.vRight   = ((vR*x.x + vU*x.y + vF*x.z).unit)
        end if
    next i
    return o
end function
