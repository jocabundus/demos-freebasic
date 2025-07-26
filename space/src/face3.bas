' -----------------------------------------------------------------------------
' Copyright (c) 2025 Joe King
' See main file or LICENSE for license and build info.
' -----------------------------------------------------------------------------
#include once "face3.bi"

#macro array_append(arr, value)
    redim preserve arr(ubound(arr) + 1)
    arr(ubound(arr)) = value
#endmacro

function Face3.addUvId(uvId as integer) as Face3
    array_append(uvIds, uvId)
    return this
end function
function Face3.addVertexId(vertexId as integer) as Face3
    array_append(vertexIds, vertexId)
    return this
end function
static function Face3.calcNormal(vertexes() as Vector3) as Vector3
    dim as Vector3 a, b, c, normal
    dim as integer vertexCount = ubound(vertexes) + 1
    if vertexCount = 3 then
        a = vertexes(1)
        b = vertexes(2)
        c = vertexes(0)
        normal = cross(a-c, b-c)
    elseif vertexCount > 3 then
        dim as integer ub = ubound(vertexes)
        for i as integer = 1 to ub - 1
            a = vertexes(0)
            b = vertexes(i)
            c = vertexes(i+1)
            normal += cross(b-a, c-a)
        next i
    end if
    return normalize(normal)
end function
