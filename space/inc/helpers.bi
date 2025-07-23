' -----------------------------------------------------------------------------
' Copyright (c) 2025 Joe King
' See main file or LICENSE for license and build info.
' -----------------------------------------------------------------------------
#include once "object3.bi"
#include once "cframe3.bi"
#include once "vector2.bi"

declare function getOrientationStats(camera as CFrame3) as string
declare function getLocationStats(camera as CFrame3) as string
declare function object_collection_add(filename as String, collection() as Object3) as Object3 ptr
declare sub printSafe(row as integer, col as integer, text as string, bounds() as integer)
declare sub printStringBlock(row as integer, col as integer, text as string, header as string = "", border as string = "", footer as string = "")
declare function getObjectBySid(sid as string, objects() as Object3) byref as Object3
