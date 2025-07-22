' -----------------------------------------------------------------------------
' Copyright (c) 2025 Joe King
' See main file or LICENSE for license and build info.
' -----------------------------------------------------------------------------
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
    declare function lerped(goal as CFrame3, a as double=0.5) as CFrame3
    declare function lookAt(target as CFrame3, worldUp as Vector3 = type(0, 1, 0)) as CFrame3
    declare function lookAt(target as Vector3, worldUp as Vector3 = type(0, 1, 0)) as CFrame3
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
operator + (a as CFrame3, b as CFrame3) as CFrame3
    return CFrame3(a.position + b.position, a.orientation)
end operator
operator + (a as CFrame3, b as Vector3) as CFrame3
    return CFrame3(a.position + b, a.orientation)
end operator
operator - (a as CFrame3, b as CFrame3) as CFrame3
    return CFrame3(a.position - b.position, a.orientation)
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
function lerp overload(from as CFrame3, goal as CFrame3, a as double = 0.5) as CFrame3
    return type(_
        lerp(from.position, goal.position, a),_
        lerp(from.orientation, goal.orientation, a) _
    )
end function
'===============================================================================
'= METHODS
'===============================================================================
function CFrame3.lerped(goal as CFrame3, a as double=0.5) as CFrame3
    return lerp(this, goal, a)
end function
function CFrame3.lookAt(target as CFrame3, worldUp as Vector3 = type(0, 1, 0)) as CFrame3
    return CFrame3(position, Orientation3.Look(target.position - position, worldUp))
end function
function CFrame3.lookAt(target as Vector3, worldUp as Vector3 = type(0, 1, 0)) as CFrame3
    return CFrame3(position, Orientation3.Look(target - position, worldUp))
end function
