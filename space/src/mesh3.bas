' -----------------------------------------------------------------------------
' Copyright (c) 2025 Joe King
' See main file or LICENSE for license and build info.
' -----------------------------------------------------------------------------
#include once "mesh3.bi"

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

function Mesh3.addFace(face as Face3) as Mesh3
    dim as Vector3 vertexSum
    dim as integer vertexId
    if ubound(face.vertexIds) >= 0 then
        for i as integer = 0 to ubound(face.vertexIds)
            vertexId   = face.vertexIds(i)
            vertexSum += getVertex(vertexId)
        next i
        face.position = vertexSum / (ubound(face.vertexIds) + 1)
    end if
    face.id = ubound(faces) + 1
    array_append(faces, face)
    return this
end function
'~ function Mesh3.getAverageTextureFaceColor() as integer
    '~ dim as Mesh3 mesh = spaceship->mesh
    '~ dim as Face3 face
    '~ dim as Vector2 uv(2)
    '~ dim as integer colr, r, g, b, n
    '~ dim as double rsum, gsum, bsum
    '~ for i as integer = 0 to ubound(mesh.faces)
        '~ face = mesh.faces(i)
        '~ uv(0) = mesh.getUv(face.uvIds(0))
        '~ for j as integer = 1 to ubound(face.uvIds)-1
            '~ uv(1) = mesh.getUv(face.uvIds(j))
            '~ uv(2) = mesh.getUv(face.uvIds(j+1))
            '~ for k as integer = 0 to ubound(uv)
                '~ colr = uvToColor(uv(k).x, uv(k).y)
                '~ rsum += rgb_r(colr)/255
                '~ gsum += rgb_g(colr)/255
                '~ bsum += rgb_b(colr)/255
                '~ n += 1
            '~ next k
        '~ next j
        '~ r = int(255*(rsum/n))
        '~ g = int(255*(gsum/n))
        '~ b = int(255*(bsum/n))
        '~ spaceship->mesh.faces(i).colr = rgb(r, g, b)
    '~ next i
'~ end function
function Mesh3.addNormal(normal as Vector3) as Mesh3
    array_append(normals, normal)
    return this
end function
function Mesh3.addUV(uv as Vector2) as Mesh3
    array_append(uvs, uv)
    return this
end function
function Mesh3.addVertex(vertex as Vector3) as Mesh3
    array_append(vertexes, vertex)
    return this
end function
function Mesh3.centerGeometry() as Mesh3
    dim as Vector3 average
    for i as integer = 0 to ubound(vertexes)
        average += vertexes(i)
    next i
    average /= (ubound(vertexes) + 1)
    for i as integer = 0 to ubound(vertexes)
        vertexes(i) -= average
    next i
    return this
end function
function Mesh3.buildBsp() as Mesh3
    dim as integer faceIds(any)
    if ubound(vertexes) >= 0 then
        for i as integer = 0 to ubound(faces)
            array_append(faceIds, faces(i).id)
        next i
        bspRoot = splitBsp(faceIds())
    end if
    return this
end function
function Mesh3.splitBsp(faceIds() as integer) as BspNode3 ptr
    dim as BspNode3 ptr node
    dim as Face3 face, behind, infront, nearest, splitter
    dim as integer backId =- -1, frontId = -1, backs(any), fronts(any)
    dim as Vector3 average, backSum, frontSum, rootSum

    if ubound(faceIds) = -1 then return 0

    node = new BspNode3
    select case 1
    case 0 '- average vertex point
        for i as integer = 0 to ubound(faceIds)
            face = getFace(faceIds(i))
            rootSum += face.position
        next i
        average = rootSum / (ubound(faceIds) + 1)
        
        nearest = getFace(faceIds(0))
        for i as integer = 1 to ubound(faceIds)
            face = getFace(faceIds(i))
            if (face.position - average).length < (nearest.position - average).length then
                nearest = face
            end if
        next i
    case 1 '- max area
        dim as double compare, comparator
        dim as Vector3 a, b, c
        nearest = getFace(faceIds(0))
        for i as integer = 0 to ubound(faceIds)
            face = getFace(faceIds(i))
            a = getVertex(face.vertexIds(0))
            b = getVertex(face.vertexIds(1))
            c = getVertex(face.vertexIds(2))
            compare = cross(b - a, c - a).length
            if compare > comparator then
                comparator = compare
                nearest = face
            end if
        next i
    case 2 '- min area between average and normal
        for i as integer = 0 to ubound(faceIds)
            face = getFace(faceIds(i))
            rootSum += face.position
        next i
        average = rootSum / (ubound(faceIds) + 1)
        
        dim as double compare, comparator
        dim as Vector3 a, b, c
        nearest = getFace(faceIds(0))
        for i as integer = 0 to ubound(faceIds)
            face = getFace(faceIds(i))
            compare = cross(face.normal, average - face.position).length
            if compare < comparator then
                comparator = compare
                nearest = face
            end if
        next i
    end select
    
    node->faceId = nearest.id
    splitter = getFace(nearest.id)
    for i as integer = 0 to ubound(faceIds)
        face = getFace(faceIds(i))
        if face.id <> splitter.id then
            if dot(splitter.normal, face.position - splitter.position) <= 0 then
                array_append(backs, face.id)
                backSum += face.position
            else
                array_append(fronts, face.id)
                frontSum += face.position
            end if
        end if
    next i

    if ubound(backs) >= 0 then
        average = backSum / (ubound(backs) + 1)
        backId  = backs(0)
        behind  = getFace(backId)
        for i as integer = 1 to ubound(backs)
            face = getFace(backs(i))
            if (face.position - average).length < (behind.position - average).length then
                backId = face.id
            end if
        next i
    end if
    if ubound(fronts) >= 0 then
        average = frontSum / (ubound(fronts) + 1)
        frontId = fronts(0)
        infront = getFace(frontId)
        for i as integer = 1 to ubound(fronts)
            face = getFace(fronts(i))
            if (face.position - average).length < (infront.position - average).length then
                frontId = face.id
            end if
        next i
    end if

    if backId >= 0 then
        node->behind  = splitBsp(backs())
    end if
    if frontId >= 0 then
        node->infront = splitBsp(fronts())
    end if
    
    return node
end function
function Mesh3.getFace(faceId as integer) as Face3
if faceId > ubound(this.faces) then
    print faceId
    sleep
    end
end if
    return this.faces(faceId)
end function
function Mesh3.getNormal(normalId as integer) as Vector3
    return this.normals(normalId)
end function
function Mesh3.getUV(uvId as integer) as Vector2
    return this.uvs(uvId)
end function
function Mesh3.getVertex(vertexId as integer) as Vector3
    return this.vertexes(vertexId)
end function
function Mesh3.paintFaces(colr as integer) as Mesh3
    for i as integer = 0 to ubound(faces)
        faces(i).colr = colr
    next i
    return Mesh3
end function
