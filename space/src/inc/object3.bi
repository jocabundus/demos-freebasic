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
    callback as sub(byref o as Object3, byref camera as CFrame3, byref world as CFrame3, deltaTime as double)
    declare constructor ()
    declare constructor (sid as string, filename as string = "")
    declare property position as Vector3
    declare property position(newPosition as Vector3)
    declare property orientation as Orientation3
    declare property orientation(newOrientation as Orientation3)
    declare property forward as Vector3
    declare property rightward as Vector3
    declare property upward as Vector3
    declare function loadFile (filename as string) as integer
    declare function toWorld() as Object3
    declare function vectorToLocal(a as Vector3) as Vector3
end type
