#include once "vector3.bi"
#include once "orientation3.bi"
type CFrame3
    _position as Vector3
    _orientation as Orientation3
    declare constructor ()
    declare constructor (_position as Vector3)
    declare constructor (_position as Vector3, _orientation as Orientation3)
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
end type
constructor CFrame3
end constructor
constructor CFrame3(_position as Vector3)
    this._position = _position
end constructor
constructor CFrame3(_position as Vector3, _orientation as Orientation3)
    this._position    = _position
    this._orientation = _orientation
end constructor
property CFrame3.position as Vector3                        : return this._position               : end property
property CFrame3.position(newPosition as Vector3)           : this._position = newPosition        : end property
property CFrame3.orientation as Orientation3                : return this._orientation            : end property
property CFrame3.orientation(axis as integer) as Vector3    : return this.orientation.matrix(axis): end property
property CFrame3.orientation(newOrientation as Orientation3): this._orientation = newOrientation  : end property
property CFrame3.vForward as Vector3: return this.orientation.vForward: end property
property CFrame3.vRight as Vector3  : return this.orientation.vRight : end property
property CFrame3.vUp as Vector3     : return this.orientation.vUp    : end property
operator + (cf as CFrame3, p as Vector3) as CFrame3
    return CFrame3(cf.position + p, cf.orientation)
end operator
operator - (cf as CFrame3, p as Vector3) as CFrame3
    return CFrame3(cf.position - p, cf.orientation)
end operator
