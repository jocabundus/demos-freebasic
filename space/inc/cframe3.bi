#include once "vector3.bi"
#include once "orientation3.bi"
type CFrame3
    position as Vector3
    orientation as Orientation3
    declare constructor ()
    declare constructor (position as Vector3)
    declare constructor (position as Vector3, orientation as Orientation3)
    declare constructor (orientation as Orientation3)
    declare property vForward as Vector3
    declare property vForward(newForward as Vector3)
    declare property vRight as Vector3
    declare property vRight(newRight as Vector3)
    declare property vUp as Vector3
    declare property vUp(newUp as Vector3)
    declare function lerp(goal as CFrame3, a as double=0.5) as CFrame3
end type
'===============================================================================
'= CONSTRUCTOR
'===============================================================================
constructor CFrame3
end constructor
constructor CFrame3(position as Vector3)
    this.position = position
end constructor
constructor CFrame3(orientation as Orientation3)
    this.orientation = orientation
end constructor
constructor CFrame3(position as Vector3, orientation as Orientation3)
    this.position    = position
    this.orientation = orientation
end constructor
'===============================================================================
'= OPERATOR
'===============================================================================
operator + (a as CFrame3, b as Vector3) as CFrame3
    return CFrame3(a.position + b, a.orientation)
end operator
operator - (a as CFrame3, b as Vector3) as CFrame3
    return a + -b
end operator
operator * (a as CFrame3, b as CFrame3) as CFrame3
    return CFrame3(a.position + b.position, a.orientation * b.orientation)
end operator
operator * (a as CFrame3, b as Orientation3) as CFrame3
    return CFrame3(a.position, a.orientation * b)
end operator
operator * (a as CFrame3, b as Vector3) as CFrame3
    return CFrame3(a.position, a.orientation * b)
end operator
'===============================================================================
'= PROPERTY
'===============================================================================
property CFrame3.vForward as Vector3: return this.orientation.vForward: end property
property CFrame3.vRight as Vector3  : return this.orientation.vRight : end property
property CFrame3.vUp as Vector3     : return this.orientation.vUp    : end property
'===============================================================================
'= FUNCTION
'===============================================================================
function cframe3_lerp(from as CFrame3, goal as CFrame3, a as double = 0.5) as CFrame3
    return type(_
        vector3_lerp(from.position, goal.position, a),_
        orientation3_lerp(from.orientation, goal.orientation, a) _
    )
end function
'===============================================================================
'= METHODS
'===============================================================================
function CFrame3.lerp(goal as CFrame3, a as double=0.5) as CFrame3
    return cframe3_lerp(this, goal, a)
end function
