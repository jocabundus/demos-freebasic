#include once "fbgfx.bi"
using FB

#define PI 3.1415926535
#define RADIANS(degrees) degrees * PI/180
#define DEGREES(radians) radians * 180/PI
#define myFormat(f) iif(f >= 0, " ", "-") + str(abs(fix(f))) + "." + str(int(abs(frac(f)) * 100))

const SEED = 1337
const NUM_PARTICLES = 1000
const FIELD_SIZE = 500
const AXIS_X = 0
const AXIS_Y = 1
const AXIS_Z = 2
const PLANE_YZ = 0
const PLANE_XZ = 1
const PLANE_XY = 2

'=======================================================================
'= SCREEN STUFF
'=======================================================================
dim shared as integer SCREEN_W
dim shared as integer SCREEN_H
dim shared as integer SCREEN_DEPTH
dim shared as double  SCREEN_ASPECT_XY
dim shared as double  SCREEN_ASPECT_YX
dim shared as integer FULL_SCREEN = 1

screeninfo SCREEN_W, SCREEN_H, SCREEN_DEPTH
screenres SCREEN_W, SCREEN_H, SCREEN_DEPTH, 2, FULL_SCREEN
SCREEN_ASPECT_XY = SCREEN_W / SCREEN_H
SCREEN_ASPECT_YX = SCREEN_H / SCREEN_W

'=======================================================================
'= VECTOR2INT
'=======================================================================
type Vector2Int
    x as integer
    y as integer
end type

'=======================================================================
'= VECTOR3
'=======================================================================
type Vector3
    x as double
    y as double
    z as double
end type
function vector_add overload(a as Vector3, b as Vector3) as Vector3
    dim v as Vector3
    v.x = a.x + b.x
    v.y = a.y + b.y
    v.z = a.z + b.z
    return v
end function
function vector_add overload(a as Vector3, b as Vector3, c as Vector3) as Vector3
    dim v as Vector3
    v.x = a.x + b.x + c.x
    v.y = a.y + b.y + c.y
    v.z = a.z + b.z + c.z
    return v
end function
function vector_sub overload(a as Vector3, b as Vector3) as Vector3
    dim v as Vector3
    v.x = a.x - b.x
    v.y = a.y - b.y
    v.z = a.z - b.z
    return v
end function
function vector_dot(a as Vector3, b as Vector3) as double
    return a.x*b.x + a.y*b.y + a.z*b.z
end function
function vector_from_axis_angle(angle as double, axis as integer = 2) as Vector3
    dim v as Vector3
    select case axis
    case 0
        v.y = cos(angle)
        v.z = sin(angle)
    case 1
        v.x = cos(angle)
        v.z = sin(angle)
    case else
        v.x = cos(angle)
        v.y = sin(angle)
    end select
    return v
end function
function vector_length(v as Vector3) as double
    return sqr(v.x*v.x + v.y*v.y + v.z*v.z)
end function
function vector_negate (a as Vector3) as Vector3
    dim v as Vector3
    v.x = -a.x
    v.y = -a.y
    v.z = -a.z
    return v
end function
function vector_rotate(a as Vector3, angle as double, axis as integer = 2) as Vector3
    dim v as Vector3
    dim as double rcos = cos(angle)
    dim as double rsin = sin(angle)
    select case axis
    case 0
        v.y = a.y * rcos + a.z * -rsin
        v.z = a.y * rsin + a.z *  rcos
    case 1
        v.x = a.x * rcos + a.z * -rsin
        v.z = a.x * rsin + a.z *  rcos
    case 2
        v.x = a.x * rcos + a.y * -rsin
        v.y = a.x * rsin + a.y *  rcos
    end select
    return v
end function
function vector_scale(a as Vector3, factor as double) as Vector3
    dim as Vector3 v
    v.x = a.x * factor
    v.y = a.y * factor
    v.z = a.z * factor
    return v
end function

'=======================================================================
'= OBJECT3
'=======================================================================
type Face3
    vertexIndexes(2) as integer
end type
type Object3
    sid as string
    position as Vector3
    orientation(0 to 2) as Vector3
    vertexes(any) as Vector3
    faces(any) as Face3
end type
function object_read(sid as string) as Object3
    dim o as Object3
    restore
    dim as string datum, key
    while true
        read datum
        if datum = sid then
            o.sid = sid
            dim as double scale = 1
            while true
                read key
                select case key
                case "end"
                    exit while
                case "f"
                    dim as integer i, n = ubound(o.faces)+1
                    redim preserve o.faces(n)
                    for i = 0 to 2
                        read o.faces(n).vertexIndexes(i)
                        o.faces(n).vertexIndexes(i) -= 1
                    next i
                case "s"
                    read scale
                case "v"
                    dim as integer n = ubound(o.vertexes)+1
                    redim preserve o.vertexes(n)
                    read o.vertexes(n).x
                    read o.vertexes(n).y
                    read o.vertexes(n).z
                end select
            wend
            exit while
        end if
    wend
    return o
end function
function object_collection_add(sid as string, collection() as Object3) as Object3
    dim o as Object3 = object_read(sid)
    if o.sid = sid then
        dim as integer n = ubound(collection)
        redim preserve collection(n+1)
        collection(n+1) = o
    else
        error -2
    end if
    return o
end function

'=======================================================================
'= CAMERATYPE
'=======================================================================
type CameraType
    orientation(0 to 2) as Vector3 = _
    {_
        (1,  0,  0),_
        (0,  1,  0),_
        (0,  0, -1) _
    }
    position as Vector3
end type

'=======================================================================
'= VIEW TRANSFORM
'=======================================================================
function vertexToView(v as vector3, camera as CameraType) as Vector3
    dim as Vector3 p = vector_add(v, camera.position)
    dim as Vector3 vp = (_
        vector_dot(camera.orientation(AXIS_X), p),_
        vector_dot(camera.orientation(AXIS_Y), p),_
        vector_dot(camera.orientation(AXIS_Z), p) _
    )
    return vp
end function

'=======================================================================
'= SCREEN TRANSFORM
'=======================================================================
function viewToScreen(vp as vector3) as Vector2Int
    dim as Vector2Int v2
    'sp.x *= SCREEN_ASPECT_YX
    'sp.y *= SCREEN_ASPECT_XY
    v2.x = int((vp.x / vp.z) * SCREEN_W + SCREEN_W/2)
    v2.y = int((vp.y / vp.z) * SCREEN_H + SCREEN_H/2)
    v2.y = SCREEN_H - v2.y
    return v2
end function

'=======================================================================
'= PARTICLETYPE
'=======================================================================
type ParticleType
    position as Vector3
    color3 as integer
end type

'=======================================================================
'= BASEORIENTATION
'=======================================================================
dim as Vector3 baseOrientation(3) = _
    {_
        (1,  0,  0),_
        (0,  1,  0),_
        (0,  0,  1) _
    }

'=======================================================================
'= WORLDORIENTATION
'=======================================================================
dim as Vector3 worldOrientation(3) = _
    {_
        (1,  0,  0),_
        (0,  1,  0),_
        (0,  0, -1) _
    }

'=======================================================================
'= START
'=======================================================================
randomize SEED

dim as CameraType camera
dim as Object3 objectCollection(any)
object_collection_add("cube", objectCollection())

dim as ParticleType particles(NUM_PARTICLES-1)
for i as integer = 0 to ubound(particles)
    dim as ParticleType p = (_
        -FIELD_SIZE/2 + FIELD_SIZE * rnd,_
        -FIELD_SIZE/2 + FIELD_SIZE * rnd,_
        -FIELD_SIZE/2 + FIELD_SIZE * rnd, _
        rgb(16*(1+15*rnd)-1, 16*(1+15*rnd)-1, 16*(1+15*rnd)-1)_
    )
    particles(i) = p
next i

sub renderObjects(objects() as Object3, camera as CameraType)
    dim as Vector2Int v2(2)
    for i as integer = 0 to ubound(objects)
        dim as Object3 o = objects(i)
        for j as integer = 0 to ubound(o.faces)
            dim as boolean isVisible = false
            dim as Face3 face = o.faces(j)
            for k as integer = 0 to 2
                dim as integer index = face.vertexIndexes(k)
                dim as Vector3 vertex = o.vertexes(index)
                dim as Vector3 vewtex = vertexToView(vertex, camera)
                v2(k) = viewToScreen(vewtex)
                if vewtex.z < -1 then
                    isVisible = true
                end if
            next k
            if isVisible then
                for k as integer = 0 to ubound(v2)
                    dim as Vector2Int p = v2(k)
                    if k = 0 then
                        line(p.x, p.y)-(p.x, p.y), &hffffff
                    else
                        line -(p.x, p.y), &hffffff
                    end if
                next k
            end if
        next j
    next i
end sub

sub renderParticles(particles() as ParticleType, camera as CameraType)
    for i as integer = 0 to ubound(particles)
        dim as ParticleType particle = particles(i)
        dim as Vector3 vp = vertexToView(particle.position, camera)
        if vp.z < -1 then
            dim as Vector2Int sp = viewToScreen(vp)
            dim as integer size = abs(int(SCREEN_W / vp.z)\2)
            if size > 1 then
                line(sp.x-size, sp.y-size)-(sp.x+size, sp.y+size), particle.color3, b
            elseif size > 0 then
                pset(sp.x, sp.y), particle.color3
            end if
        end if
    next i
end sub

sub printSafe(row as integer, col as integer, text as string, bounds() as integer)
    dim as integer clip0 = 1, clip1 = len(text)
    if row >= bounds(0) and row <= bounds(2) then
        if col+len(text) >= bounds(1) and col <= bounds(3) then
            if col < bounds(1) then
                clip0 += bounds(1) - col
                clip1 -= bounds(1) - col
            end if
            if col + clip1 > bounds(3) then
                clip1 -= (col + clip1) - bounds(3)
            end if
            locate row, col + (clip0 - 1)
            print mid(text, clip0, clip1);
        end if
    end if
end sub

sub printStringBlock(row as integer, col as integer, text as string, header as string = "", border as string = "")
    dim as integer i = 1, j, maxw
    dim as string s
    while i > 0
        j = instr(i, text, "$")
        if j then
            s = mid(text, i, j-i)
            i = j+1
        else
            s = mid(text, i)
            i = 0
        end if
        if len(s) > maxw then
            maxw = len(s)
        end if
    wend
    if header <> "" then
        dim as string buffer = string(maxw, iif(border <> "", border, " "))
        mid(buffer, 1) = header
        locate   row, col: print buffer;
        locate row+1, col: print space(maxw);
        row += 2
    end if
    i = 1
    while i > 0
        j = instr(i, text, "$")
        if j then
            s = mid(text, i, j-i)
            i = j+1
        else
            s = mid(text, i)
            i = 0
        end if
        if s = "" then
            s = space(maxw)
        end if
        locate row, col: print s;
        row += 1
    wend
    if border <> "" then
        locate row, col: print string(maxw, border);
    end if
end sub

function getOrientationStats(camera as CameraType) as string
    dim as string axisNames(2) = {"X", "Y", "Z"}
    dim as string stats(3, 3)
    for i as integer = 0 to 2
        dim as Vector3 o = camera.orientation(i)
        stats(0, i) = myFormat(o.x)
        stats(1, i) = myFormat(o.y)
        stats(2, i) = myFormat(o.z)
    next i
    dim as integer roww = 21
    dim as integer colw = 8
    dim as string body   = ""
    dim as string colhdr = "_____"
    dim as string row
    row = space(roww): for i as integer = 0 to 2: mid(row, 1+i*colw) = axisNames(i): next i: body += row + "$"
    row = space(roww): for i as integer = 0 to 2: mid(row, 1+i*colw) = colhdr: next i: body += row + "$$"
    for i as integer = 0 to 2
        dim as string row = space(21)
        for j as integer = 0 to 2
            mid(row, 1+j*colw) = stats(i, j)
        next j
        body += row + iif(i < 2, "$$", "$")
    next i
    return body
end function

dim as double speed = 30
dim as double shiftBoost = 2
screenset 1, 0

dim as double frameTimeStart = 0
dim as double frameTimeEnd   = 0

while true
    if multikey(SC_ESCAPE) then
        exit while
    end if

    cls
    renderObjects(objectCollection(), camera)
    renderParticles(particles(), camera)

    dim as string s = getOrientationStats(camera)
    printStringBlock(1, 1, s, "ORIENTATION", "_")
    
    screencopy 1, 0

    dim as double delta = timer - frameTimeStart
    frameTimeStart = timer

    delta *= speed
    if multikey(SC_LSHIFT) then
        delta *= shiftBoost
    end if
    
    if multikey(SC_A) then
        camera.position = vector_sub(camera.position, vector_scale(camera.orientation(AXIS_X), delta))
    elseif multikey(SC_D) then
        camera.position = vector_add(camera.position, vector_scale(camera.orientation(AXIS_X), delta))
    elseif multikey(SC_W) then
        camera.position = vector_add(camera.position, vector_scale(camera.orientation(AXIS_Z), delta))
    elseif multikey(SC_S) then
        camera.position = vector_sub(camera.position, vector_scale(camera.orientation(AXIS_Z), delta))
    elseif multikey(SC_Q) then
        camera.position = vector_add(camera.position, vector_scale(camera.orientation(AXIS_Y), delta))
    elseif multikey(SC_Z) then
        camera.position = vector_sub(camera.position, vector_scale(camera.orientation(AXIS_Y), delta))
    end if

    dim as Vector3 vR = camera.orientation(AXIS_X)
    dim as Vector3 vU = camera.orientation(AXIS_Y)
    dim as Vector3 vF = camera.orientation(AXIS_Z)
    dim as double turnDelta = 0
    if not multikey(SC_CONTROL) then
        if multikey(SC_RIGHT) then
            turnDelta =  delta
        elseif multikey(SC_LEFT) then
            turnDelta = -delta
        end if
    end if
    if turnDelta <> 0 then
        dim as Vector3 x1 = vector_rotate(baseOrientation(AXIS_X), radians(turnDelta), PLANE_XZ)
        dim as Vector3 z1 = vector_rotate(baseOrientation(AXIS_Z), radians(turnDelta), PLANE_XZ)
        camera.orientation(AXIS_X) = vector_add(_
            vector_scale(vR, x1.x),_
            vector_scale(vU, x1.y),_
            vector_scale(vF, x1.z) _
        )
        camera.orientation(AXIS_Z) = vector_add(_
            vector_scale(vR, z1.x),_
            vector_scale(vU, z1.y),_
            vector_scale(vF, z1.z) _
        )
    end if

    turnDelta = 0
    if multikey(SC_CONTROL) then
        if multikey(SC_RIGHT) then
            turnDelta =  delta
        elseif multikey(SC_LEFT) then
            turnDelta = -delta
        end if
    end if
    if turnDelta <> 0 then
        dim as Vector3 x1 = vector_rotate(baseOrientation(AXIS_X), radians(turnDelta), PLANE_XY)
        dim as Vector3 y1 = vector_rotate(baseOrientation(AXIS_Y), radians(turnDelta), PLANE_XY)
        camera.orientation(AXIS_X) = vector_add(_
            vector_scale(vR, x1.x),_
            vector_scale(vU, x1.y),_
            vector_scale(vF, x1.z) _
        )
        camera.orientation(AXIS_Y) = vector_add(_
            vector_scale(vR, y1.x),_
            vector_scale(vU, y1.y),_
            vector_scale(vF, y1.z) _
        )
    end if

    turnDelta = 0
    if multikey(SC_UP) then
        turnDelta =  delta
    elseif multikey(SC_DOWN) then
        turnDelta = -delta
    end if
    if turnDelta <> 0 then
        dim as Vector3 y1 = vector_rotate(baseOrientation(AXIS_Y), radians(turnDelta), PLANE_YZ)
        dim as Vector3 z1 = vector_rotate(baseOrientation(AXIS_Z), radians(turnDelta), PLANE_YZ)
        camera.orientation(AXIS_Y) = vector_add(_
            vector_scale(vR, y1.x),_
            vector_scale(vU, y1.y),_
            vector_scale(vF, y1.z) _
        )
        camera.orientation(AXIS_Z) = vector_add(_
            vector_scale(vR, z1.x),_
            vector_scale(vU, z1.y),_
            vector_scale(vF, z1.z) _
        )
    end if
wend
sleep
end

'=======================================================================
'= DATA
'=======================================================================
data 9
data "cube"
data "s",  10
data "v",  1.000000,  1.000000, -1.000000
data "v",  1.000000, -1.000000, -1.000000
data "v",  1.000000,  1.000000,  1.000000
data "v",  1.000000, -1.000000,  1.000000
data "v", -1.000000,  1.000000, -1.000000
data "v", -1.000000, -1.000000, -1.000000
data "v", -1.000000,  1.000000,  1.000000
data "v", -1.000000, -1.000000,  1.000000
data "f", 5, 3, 1
data "f", 3, 8, 4
data "f", 7, 6, 8
data "f", 2, 8, 6
data "f", 1, 4, 2
data "f", 5, 2, 6
data "f", 5, 7, 3
data "f", 3, 7, 8
data "f", 7, 5, 6
data "f", 2, 4, 8
data "f", 1, 3, 4
data "f", 5, 1, 2
data "end"
