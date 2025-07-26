' -----------------------------------------------------------------------------
' Copyright (c) 2025 Joe King
' See main file or LICENSE for license and build info.
' -----------------------------------------------------------------------------
#include once "vector3.bi"

type Face3
    id as integer
    colr as integer = rgb(128+92*rnd, 128+92*rnd, 128+92*rnd)
    position as Vector3
    normal as Vector3
    uvIds(any) as integer
    vertexIds(any) as integer
    declare function addUvId(uvId as integer) as Face3
    declare function addVertexId(vertexId as integer) as Face3
    declare static function calcNormal(vertexes() as Vector3) as Vector3
end type
