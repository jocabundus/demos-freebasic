' -----------------------------------------------------------------------------
' Copyright (c) 2025 Joe King
' See main file or LICENSE for license and build info.
' -----------------------------------------------------------------------------
#include once "face3.bi"
#include once "vector2.bi"
#include once "vector3.bi"
#include once "bspnode.bi"

type Mesh3
    bspRoot as BspNode3 ptr
    doubleSided as boolean = false
    faces(any) as Face3
    normals(any) as Vector3
    texture as any ptr
    vertexes(any) as Vector3
    uvs(any) as Vector2
    sid as string
    declare function addFace(face as Face3) as integer
    declare function addNormal(normal as Vector3) as integer
    declare function addUV(uv as Vector2) as integer
    declare function addVertex(vertex as Vector3) as integer
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
