' -----------------------------------------------------------------------------
' Copyright (c) 2025 Joe King
' See main file or LICENSE for license and build info.
' -----------------------------------------------------------------------------
#include once "cframe3.bi"
#include once "mesh3.bi"
#include once "vector3.bi"

type Object3
    sid as string
    angular as Vector3
    cframe as CFrame3
    linear as Vector3
    mesh as Mesh3
    declare constructor ()
    declare constructor (sid as string, filename as string = "")
    declare property position as Vector3
    declare property position(newPosition as Vector3)
    declare property orientation as Orientation3
    declare property orientation(newOrientation as Orientation3)
    declare property vForward as Vector3
    declare property vRight as Vector3
    declare property vUp as Vector3
    declare function toWorld() as Object3
    declare function loadFile (filename as string) as integer
end type
