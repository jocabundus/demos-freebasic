' -----------------------------------------------------------------------------
' Copyright (c) 2025 Joe King
' See main file or LICENSE for license and build info.
' -----------------------------------------------------------------------------
#include once "cframe3.bi"
#include once "mesh3.bi"
#include once "vector3.bi"

type Object3 extends CFrame3
    id as integer
    velocity as Vector3
    mesh as Mesh3
    world as CFrame3
    declare function loadFile(filename as string) as integer
    declare function toWorld() as Object3
end type
