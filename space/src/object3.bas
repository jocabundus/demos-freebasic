' -----------------------------------------------------------------------------
' Copyright (c) 2025 Joe King
' See main file or LICENSE for license and build info.
' -----------------------------------------------------------------------------
#include once "object3.bi"

#macro array_append(arr, value)
    redim preserve arr(ubound(arr) + 1)
    arr(ubound(arr)) = value
#endmacro

declare sub string_split(subject as string, delim as string, pieces() as string)
'==============================================================================
'= CONSTRUCTOR
'==============================================================================
constructor Object3
end constructor
constructor Object3(sid as string, filename as string = "")
    this.sid = sid
    if filename <> "" then
        this.loadFile(filename)
    end if
end constructor
'==============================================================================
'= PROPERTY
'==============================================================================
property Object3.position as Vector3
    return this.cframe.position
end property
property Object3.position(newPosition as Vector3)
    this.cframe.position = newPosition
end property
property Object3.orientation as Orientation3
    return this.cframe.orientation
end property
property Object3.orientation(newOrientation as Orientation3)
    this.cframe.orientation = newOrientation
end property
property Object3.forward as Vector3
    return this.cframe.forward
end property
property Object3.rightward as Vector3
    return this.cframe.rightward
end property
property Object3.upward as Vector3
    return this.cframe.upward
end property
'==============================================================================
'= METHOD
'==============================================================================
function Object3.loadFile(filename as string) as integer
    dim as string datum, pieces(any), subpieces(any), s, p
    dim as boolean calcNormals = true
    dim as integer f = freefile
    open filename for input as #f
        while not eof(f)
            line input #f, s
            string_split(s, " ", pieces())
            for i as integer = 0 to ubound(pieces)
                dim as string datum = pieces(i)
                select case datum
                    case "o"
                        mesh.sid = pieces(i + 1)
                        continue while
                    case "v"
                        mesh.addVertex(Vector3(_
                            val(pieces(1)),_
                            val(pieces(2)),_
                           -val(pieces(3)) _
                        ))
                    case "vn"
                        calcNormals = false
                        mesh.addNormal(Vector3(_
                            val(pieces(1)),_
                            val(pieces(2)),_
                           -val(pieces(3)) _
                        ))
                    case "vt"
                        mesh.addUV(Vector2(_
                            val(pieces(1)),_
                            val(pieces(2)) _
                        ))
                    case "f"
                        dim as integer normalId, uvId, vertexId
                        dim as Face3 face
                        for j as integer = 0 to ubound(pieces) - 1
                            normalId = -1
                            uvId     = -1
                            vertexId = -1
                            dim as string p = pieces(1 + j)
                            if instr(p, "/") then
                                string_split(p, "/", subpieces())
                                for k as integer = 0 to ubound(subpieces)
                                    if subpieces(k) <> "" then
                                        select case k
                                            case 0: vertexId = val(subpieces(k)) - 1
                                            case 1: uvId     = val(subpieces(k)) - 1
                                            case 2: normalId = val(subpieces(k)) - 1
                                        end select
                                    end if
                                next k
                            else
                                vertexId = val(pieces(1 + j)) - 1
                            end if
                            if vertexId > -1 then
                                face.addVertexId(vertexId)
                            end if
                            if uvId > -1 then
                                face.addUvId(uvId)
                            end if
                            if normalId > -1 then
                                face.normal = mesh.getNormal(normalId)
                            end if
                            print
                        next j
                        if calcNormals then
                            dim as Vector3 vertexes(any)
                            for j as integer = 0 to ubound(face.vertexIds)
                                vertexId = face.vertexIds(j)
                                array_append(vertexes, mesh.getVertex(vertexId))
                            next j
                            face.normal = Face3.calcNormal(vertexes())
                        end if
                        mesh.addFace(face)
                    case else
                        continue while
                end select
            next i
        wend
    close #1
    mesh.buildBsp()
    return 0
end function
function Object3.toWorld() as Object3
    dim as Object3 o = this
    for i as integer = 0 to ubound(mesh.vertexes)
        dim as Vector3 v = mesh.vertexes(i)
        o.mesh.vertexes(i) = rightward * v.x + upward * v.y + forward * v.z + this.position
    next i
    for i as integer = 0 to ubound(mesh.faces)
        dim as Vector3 n = mesh.faces(i).normal
        o.mesh.faces(i).normal = rightward * n.x + upward * n.y + forward * n.z
    next i
    return o
end function
function Object3.vectorToLocal(a as Vector3) as Vector3
    return Vector3(_
        dot(rightward, a),_
        dot(upward   , a),_
        dot(forward  , a) _
    )
end function

'==============================================================================
'= FUNCTION
'==============================================================================
private sub string_split(subject as string, delim as string, pieces() as string)
    dim as integer i, j, index = -1
    dim as string s
    i = 1
    while i > 0
        s = ""
        j = instr(i, subject, delim)
        if j then
            s = mid(subject, i, j-i)
            i = j+1
        else
            s = mid(subject, i)
            i = 0
        end if
        index += 1: redim preserve pieces(index)
        pieces(index) = s
    wend
end sub
