#include once "vector3.bi"
#include once "orientation3.bi"
type CFrame3
    _position as Vector3
    _orientation as Orientation3
    declare constructor ()
    declare constructor (_position as Vector3)
    declare constructor (_position as Vector3, _orientation as Orientation3)
    declare constructor (_orientation as Orientation3)
    declare property orientation as Orientation3
    declare property orientation(axis as integer) as Vector3
    declare property orientation(newOrientation as Orientation3)
    declare property position as Vector3
    declare property position(newPosition as Vector3)
    declare property vForward as Vector3
    declare property vForward(newForward as Vector3)
    declare property vRight as Vector3
    declare property vRight(newRight as Vector3)
    declare property vUp as Vector3
    declare property vUp(newUp as Vector3)
    declare function lerp(goal as CFrame3, a as double=0.5) as CFrame3
    declare function rotate(axisRotations as Vector3) as CFrame3
    declare function rotate(cf as CFrame3) as CFrame3
    declare function rotate(o as Orientation3) as CFrame3
end type
'===============================================================================
'= OPERATOR
'===============================================================================
operator + (cf as CFrame3, p as Vector3) as CFrame3
    cf.position = cf.position + p
    return cf
end operator
operator - (cf as CFrame3, p as Vector3) as CFrame3
    return CFrame3(cf.position - p, cf.orientation)
end operator
operator * (cf as CFrame3, axisRotations as Vector3) as CFrame3
    return cf.rotate(axisRotations)
end operator
operator * (a as CFrame3, b as CFrame3) as CFrame3
    return (a + b.position).rotate(b)
end operator
operator * (cf as CFrame3, o as Orientation3) as CFrame3
    cf.orientation = cf.orientation.rotate(o)
    return cf
end operator
'===============================================================================
'= FUNCTION
'===============================================================================
function cframe3_rotate overload(cf as CFrame3, axisRotations as Vector3) as CFrame3
    cf.orientation = cf.orientation.rotate(axisRotations)
    return cf
end function
function cframe3_rotate overload(cf as CFrame3, o as Orientation3) as CFrame3
    cf.orientation = cf.orientation.rotate(o)
    return cf
end function
function cframe3_rotate overload(a as CFrame3, b as CFrame3) as CFrame3
    a.orientation = a.orientation.rotate(b.orientation)
    return a
end function
function cframe3_lerp(from as CFrame3, goal as CFrame3, a as double = 0.5) as CFrame3
    a = iif(a < 0, 0, iif(a > 1, 1, a))
    a = 1 - exp(-4.0 * a)
    return type(_
        vector3_lerp(from.position, goal.position, a),_
        from.orientation _
    )
end function
'===============================================================================
'= CONSTRUCTOR
'===============================================================================
constructor CFrame3
end constructor
constructor CFrame3(_position as Vector3)
    this._position = _position
end constructor
constructor CFrame3(_position as Vector3, _orientation as Orientation3)
    this._position    = _position
    this._orientation = _orientation
end constructor
constructor CFrame3(_orientation as Orientation3)
    this._orientation = _orientation
end constructor
'===============================================================================
'= PROPERTY
'===============================================================================
property CFrame3.position as Vector3                        : return this._position                : end property
property CFrame3.position(newPosition as Vector3)           : this._position = newPosition         : end property
property CFrame3.orientation as Orientation3                : return this._orientation             : end property
property CFrame3.orientation(axis as integer) as Vector3    : return this._orientation.matrix(axis): end property
property CFrame3.orientation(newOrientation as Orientation3): this._orientation = newOrientation   : end property
property CFrame3.vForward as Vector3: return this.orientation.vForward: end property
property CFrame3.vRight as Vector3  : return this.orientation.vRight : end property
property CFrame3.vUp as Vector3     : return this.orientation.vUp    : end property
'===============================================================================
'= METHODS
'===============================================================================
function CFrame3.rotate(axisRotations as Vector3) as CFrame3
    dim as CFrame3 cf = this
    cf.orientation = cf.orientation.rotate(axisRotations)
    return cf
end function
function CFrame3.rotate(cf as CFrame3) as CFrame3
    return this.rotate(cf.orientation)
end function
function CFrame3.rotate(o as Orientation3) as CFrame3
    dim as CFrame3 cf = this
    cf.orientation = cf.orientation.rotate(o)
    return cf
end function
function CFrame3.lerp(goal as CFrame3, a as double=0.5) as CFrame3
    return cframe3_lerp(this, goal, a)
end function
