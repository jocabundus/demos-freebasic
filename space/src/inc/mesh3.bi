' -----------------------------------------------------------------------------
' Copyright (c) 2025 Joe King
' See main file or LICENSE for license and build info.
' -----------------------------------------------------------------------------
#include once "defines.bi"
#include once "vector2.bi"
#include once "vector3.bi"

type BspNode3
    as integer faceId = -1
    as BspNode3 ptr behind, infront
end type

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

type Mesh3
    bspRoot as BspNode3 ptr
    doubleSided as boolean = false
    faces(any) as Face3
    normals(any) as Vector3
    vertexes(any) as Vector3
    uvs(any) as Vector2
    sid as string
    declare function addFace(face as Face3) as Mesh3
    declare function addNormal(normal as Vector3) as Mesh3
    declare function addUV(uv as Vector2) as Mesh3
    declare function addVertex(vertex as Vector3) as Mesh3
    declare function buildBsp() as Mesh3
    declare function centerGeometry() as Mesh3
    declare function generateBsp() as Mesh3
    declare function getFace(faceId as integer) as Face3
    declare function getNormal(normalId as integer) as Vector3
    declare function getUV(uvId as integer) as Vector2
    declare function getVertex(vertexId as integer) as Vector3
    declare function paintFaces(colr as integer) as Mesh3
    declare function splitBsp(faceIds() as integer) as BspNode3 ptr
end type
