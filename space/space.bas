#include once "fbgfx.bi"
#include once "vector3.bi"
#include once "vector2.bi"
#include once "orientation3.bi"
#include once "cframe3.bi"
#include once "mouse2.bi"
using FB

#define PI 3.1415926535
#define RADIANS(degrees) degrees * PI/180
#define DEGREES(radians) radians * 180/PI
#define myFormat(f) iif(f >= 0, " ", "-") + str(abs(fix(f))) + "." + str(int(abs(frac(f)) * 100))

const SEED = 1337
const NUM_PARTICLES = 2500
const FIELD_SIZE = 500

'=======================================================================
'= SCREEN STUFF
'=======================================================================
dim shared as integer SCREEN_W
dim shared as integer SCREEN_H
dim shared as integer SCREEN_DEPTH
dim shared as double  SCREEN_ASPECT_X
dim shared as double  SCREEN_ASPECT_Y
dim shared as integer FULL_SCREEN = 1

screeninfo SCREEN_W, SCREEN_H, SCREEN_DEPTH
screenres SCREEN_W, SCREEN_H, SCREEN_DEPTH, 2, FULL_SCREEN
SCREEN_ASPECT_X = SCREEN_W / SCREEN_H
SCREEN_ASPECT_Y = SCREEN_H / SCREEN_W

'=======================================================================
'= OBJECT3
'=======================================================================
type Face3
    vertexIndexes(2) as integer
    normal as Vector3
end type
type Object3
    sid as string
    position as Vector3
    orientation(0 to 2) as Vector3
    vertexes(any) as Vector3
    normals(any) as Vector3
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
                    dim as Vector3 vertexes(2)
                    redim preserve o.faces(n)
                    for i = 0 to 2
                        dim as integer vertexIndex
                        read vertexIndex
                        vertexIndex -= 1
                        o.faces(n).vertexIndexes(i) = vertexIndex
                        vertexes(i) = o.vertexes(vertexIndex)
                    next i
                    dim as Vector3 a, b
                    a = vertexes(1) - vertexes(0)
                    b = vertexes(2) - vertexes(0)
                    o.faces(n).normal = a.cross(b).unit
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
'= VIEW TRANSFORM
'=======================================================================
function vertexToView(v as vector3, camera as CFrame3, skipTranslation as boolean = false) as Vector3
    dim as Vector3 p = v
    if not skipTranslation then
         p -= camera.position
    end if
    return Vector3(_
        vector3_dot(camera.vRight  , -p),_
        vector3_dot(camera.vUp     , -p),_
        vector3_dot(camera.vForward, -p) _
    )
end function

'=======================================================================
'= SCREEN TRANSFORM
'=======================================================================
function viewToScreen(vp as vector3) as Vector2
    dim as Vector2 v2
    v2.x = (vp.x / vp.z) * 2
    v2.y = (vp.y / vp.z) * 2
    return v2
end function

'=======================================================================
'= PARTICLETYPE
'=======================================================================
type ParticleType
    position as Vector3
    color3 as integer
    declare constructor ()
    declare constructor (position as Vector3, color3 as integer)
end type
constructor ParticleType
end constructor
constructor ParticleType (position as Vector3, color3 as integer)
    this.position = position
    this.color3 = color3
end constructor

'=======================================================================
'= START
'=======================================================================
randomize 'SEED
window (-SCREEN_ASPECT_X, 1)-(SCREEN_ASPECT_X, -1)

dim as Mouse2 mouse
mouse.hide()
mouse.setMode(Mouse2Mode.Viewport)

dim as CFrame3 camera
dim as Object3 objectCollection(any)
object_collection_add("spaceship", objectCollection())

type PointLight
    position as Vector2
    color3 as integer
    intensity as double
    declare constructor ()
    declare constructor (position as Vector2, color3 as integer, intensity as double)
end type
constructor PointLight
end constructor
constructor PointLight(position as Vector2, color3 as integer, intensity as double)
    this.position = position
    this.color3 = color3
    this.intensity = intensity
end constructor

function clamp(value as double, min as double = 0, max as double = 1) as double
    return iif(value < min, min, iif(value > max, max, value))
end function

function pickStarColor(a as double, m as double=1, variant as integer = 1) as integer
    dim as Vector2 va
    va = Vector2(a) * m
    dim as double r, g, b
    select case variant
        case 1
            dim as PointLight lights(3) = _
            {_
                type(Vector2(0/3*PI)/2, &hff0000, 1),_
                type(Vector2(2/3*PI)/2, &h00ff00, 1),_
                type(Vector2(4/3*PI)/2, &h0000ff, 1),_
                type(Vector2(0, 0)  , &hffffff, 1) _
            }
            for i as integer = 0 to ubound(lights)
                dim as Vector2 p = lights(i).position
                dim as integer c = lights(i).color3
                dim as double  m = lights(i).intensity
                dim as double  d = clamp(1-sin((p - va).length))
                r += int(d * m * (c shr 16 and &hff))
                g += int(d * m * (c shr  8 and &hff))
                b += int(d * m * (c        and &hff))
            next i
            return rgb(clamp(r,0,255), clamp(g,0,255), clamp(b,0,255))
        case 2
            dim as PointLight lights(4) = _
            {_
                type(Vector2(0/4*PI)*0, &hffffff, 1),_
                type(Vector2(0/4*PI)*1, &h0000ff, 1/2),_
                type(Vector2(2/4*PI)*1, &h0000ff, 1/2),_
                type(Vector2(4/4*PI)*1, &h0000ff, 1/2),_
                type(Vector2(6/4*PI)*1, &h0000ff, 1/2) _
            }
            for i as integer = 0 to ubound(lights)
                dim as Vector2 p = lights(i).position
                dim as integer c = lights(i).color3
                dim as double  m = lights(i).intensity
                dim as double  d = clamp(1-sin((p - va).length))
                r += int(d * m * (c shr 16 and &hff))
                g += int(d * m * (c shr  8 and &hff))
                b += int(d * m * (c        and &hff))
            next i
            return rgb(clamp(r,0,255), clamp(g,0,255), clamp(b,0,255))
    end select
    return rgb(int(256*r), int(256*g), int(256*b))
end function

dim as ParticleType particles(NUM_PARTICLES-1)
for i as integer = 0 to ubound(particles)
    dim as ParticleType p = type(_
        Vector3(_
            FIELD_SIZE/2 * rnd*sin(2*PI*rnd),_
            FIELD_SIZE/2 * rnd*sin(2*PI*rnd),_
            FIELD_SIZE/2 * rnd*sin(2*PI*rnd) _
        ),_
        pickStarColor(rnd*2*PI, rnd, 2)_
    )
    particles(i) = p
next i

sub renderObjects(objects() as Object3, camera as CFrame3)
    dim as Vector2 v2(2)
    for i as integer = 0 to ubound(objects)
        dim as Object3 o = objects(i)
        for j as integer = 0 to ubound(o.faces)
            dim as double surfaceCos
            dim as boolean isVisible = true
            dim as Face3 face = o.faces(j)
            for k as integer = 0 to 2
                dim as integer index = face.vertexIndexes(k)
                dim as Vector3 vertex = o.vertexes(index)
                dim as Vector3 vewtex = vertexToView(vertex, camera)
                if k = 0 then
                    surfaceCos = vector3_dot(face.normal, Vector3(0, 1, 0))
                    dim as Vector3 normal = vertexToView(face.normal, camera, true).unit
                    if vector3_dot(vewtex, normal) > 0 then
                        isVisible = false
                        exit for
                    end if
                end if
                v2(k) = viewToScreen(vewtex)
                if vewtex.z > -1 then
                    isVisible = false
                    exit for
                end if
            next k
            if isVisible then
                dim as Vector2 a, b, c
                if isVisible then
                    '~ dim as integer cr, cg, cb, colr
                    '~ cr = int(clamp(surfaceCos)*255)
                    '~ cg = int(clamp(surfaceCos)*255)
                    '~ cb = int(clamp(surfaceCos)*255)
                    '~ colr = rgb(cr, cg, cb)
                    dim as integer colr = &hffffff
                    a = v2(0)
                    b = v2(1)
                    c = v2(2)
                    line(a.x, a.y)-(b.x, b.y), colr
                    line(b.x, b.y)-(c.x, c.y), colr
                    line(c.x, c.y)-(a.x, a.y), colr
                end if
            end if
        next j
    next i
end sub

sub renderParticles(particles() as ParticleType, camera as CFrame3)
    for i as integer = 0 to ubound(particles)
        dim as ParticleType particle = particles(i)
        dim as Vector3 vp = vertexToView(particle.position, camera)
        if vp.z < -1 then
            dim as Vector2 sp = viewToScreen(vp)
            dim as double size = abs(1/vp.z) * 0.2
            if size > 0 then
                'line(sp.x-size, sp.y-size)-(sp.x+size, sp.y+size), particle.color3, bf
                circle(sp.x, sp.y), size, particle.color3
                'circle(sp.x, sp.y), 0.004, particle.color3
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

function getOrientationStats(camera as CFrame3) as string
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

sub renderUI(mouse as Mouse2, reticleColor as integer = &h808080, arrowColor as integer = &hd0b000)
    dim as Vector2 m = type(mouse.x, mouse.y)
    '- draw center circle
    dim as double fr = 0.11
    dim as double stp = PI/3
    dim as double start = atan2(m.y, m.x)
    if start < 0 then start += 2*PI
    for rad as double = start-2*PI-stp/4 to 2*PI step stp
        if rad >= 0 then
            circle(0, 0), fr, reticleColor, rad, rad+stp/2
        end if
    next rad
    '- draw directionol arrow
    dim as double sz
    dim as integer colr = arrowColor
    dim as Vector2 a, b
    if mouse.buttons > 0 then
        sz = fr/4
        a = m.unit*fr*1.15
        b = a.unit.toLeft()*sz
        line(a.x, a.y)-step(b.x, b.y), colr
        b = b.unit.toRight().rotate(radians(-30))*sz*2
        line -step(b.x, b.y), colr
        b = b.unit.rotate(radians(-120))*sz*2
        line -step(b.x, b.y), colr
        b = b.unit.rotate(radians(-120))*sz
        line -step(b.x, b.y), colr
    end if

    '- draw mouse cursor
    dim as ulong ants = &b11000011110000111100001111000011 shr int(frac(timer*1.5)*16)
    a = m
    sz = 0.076
    b = Vector2(radians(-75))*sz
    line(a.x, a.y)-step(b.x, b.y), &hf0f0f0, , ants
    b = b.rotate(radians(105))*0.8
    line -step(b.x, b.y), &hf0f0f0, , ants
    line -(a.x, a.y), &hf0f0f0, , ants
end sub

dim as double rotateSpeed = 1
dim as double translateSpeed = 15
dim as double shiftBoost = 2
screenset 1, 0

dim as double frameTimeStart = 0
dim as double frameTimeEnd   = 0

dim as Vector3 movement, targetMovement
dim as Vector3 rotation, targetRotation

setmouse pmap(0, 0), pmap(0, 1)
while true
    if multikey(SC_ESCAPE) then
        exit while
    end if

    cls
    renderObjects(objectCollection(), camera)
    renderParticles(particles(), camera)

    dim as string s = getOrientationStats(camera)
    printStringBlock(1, 1, s, "ORIENTATION", "_")

    mouse.update
    renderUI mouse

    screencopy 1, 0
    dim as double deltaTime = timer - frameTimeStart
    dim as double deltaRotate = deltaTime * rotateSpeed
    dim as double deltaTranslate = deltaTime * translateSpeed
    frameTimeStart = timer

    if multikey(SC_LSHIFT) or multikey(SC_RSHIFT) then
        deltaRotate *= shiftBoost
        deltaTranslate *= shiftBoost
    end if

    targetMovement = Vector3(0, 0, 0)
    targetRotation = Vector3(0, 0, 0)

    if mouse.leftDown then
        targetRotation.y -= mouse.x
        targetRotation.x -= mouse.y
    end if
    if mouse.middleDown then
        targetMovement.x += mouse.x
        targetMovement.y += mouse.y
    elseif mouse.rightDown then
        dim as Vector2 m = type(mouse.x, mouse.y)
        m = m.rotate(atan2(targetRotation.z, targetRotation.x))
        targetRotation.x -= mouse.y
        targetRotation.z -= mouse.x
    end if

    if multikey(SC_D) then targetMovement.x += 1
    if multikey(SC_A) then targetMovement.x -= 1
    if multikey(SC_Q) then targetMovement.y += 1
    if multikey(SC_Z) then targetMovement.y -= 1
    if multikey(SC_W) then targetMovement.z += 1
    if multikey(SC_S) then targetMovement.z -= 1

    if multikey(SC_UP   ) then targetRotation.x -= 1
    if multikey(SC_DOWN ) then targetRotation.x += 1
    if multikey(SC_RIGHT) then targetRotation.y -= 1
    if multikey(SC_LEFT ) then targetRotation.y += 1
    if multikey(SC_CONTROL) then
        if multikey(SC_RIGHT) then targetRotation.z -= 1
        if multikey(SC_LEFT ) then targetRotation.z += 1
    end if

    targetMovement = (_
        + targetMovement.x * camera.vRight   _
        + targetMovement.y * camera.vUp      _
        + targetMovement.z * camera.vForward _
    ) * deltaTranslate

    targetRotation *= deltaRotate
    
    if targetMovement.length > 1 then targetMovement = targetMovement.unit
    if targetRotation.length > 1 then targetRotation = targetRotation.unit
    movement = movement.lerp(targetMovement, deltaTime)
    rotation = rotation.lerp(targetRotation, deltaTime)
    camera += movement
    camera.orientation = camera.orientation.rotate(rotation)
wend
setmouse , , 1
end

'=======================================================================
'= DATA
'=======================================================================
data 9
data "cube"
data "s",  10
data "v",  1,  1, -1
data "v",  1, -1, -1
data "v",  1,  1,  1
data "v",  1, -1,  1
data "v", -1,  1, -1
data "v", -1, -1, -1
data "v", -1,  1,  1
data "v", -1, -1,  1
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

data "spaceship"
data "v", 2.000000, 0.250000, -1.000000
data "v", 1.500000, 1.500000, 4.000000
data "v", 1.500000, 0.500000, 4.000000
data "v", -1.945922, 0.977856, -0.996525
data "v", -2.000000, 0.250000, -1.000000
data "v", -1.500000, 1.500000, 4.000000
data "v", -1.500000, 0.500000, 4.000000
data "v", 1.000000, -0.500000, -3.000000
data "v", -1.000000, -0.500000, -3.000000
data "v", 1.000000, 0.000000, -3.000000
data "v", -1.000000, 0.000000, -3.000000
data "v", -4.000000, 0.250000, 0.500000
data "v", -4.000000, 0.250000, 2.000000
data "v", -4.000000, 0.750000, 2.000000
data "v", -4.000000, 0.750000, 0.500000
data "v", 4.000000, 0.750000, 0.500000
data "v", 4.000000, 0.250000, 0.500000
data "v", 4.000000, 0.750000, 2.000000
data "v", 4.000000, 0.250000, 2.000000
data "v", -1.500000, 0.000000, 1.000000
data "v", 0.000000, -0.500000, -1.000000
data "v", 1.500000, 0.000000, 1.000000
data "v", 0.000000, 0.000000, 2.741200
data "v", -2.518813, -0.022215, 0.676867
data "v", 2.518813, -0.022215, 0.676867
data "v", 0.000000, 2.500000, 3.000000
data "v", -1.743595, 1.497457, 0.907487
data "v", 0.000000, 1.250000, -2.000000
data "v", -0.000000, 2.232334, 4.925400
data "v", -1.000000, 0.500000, 5.250000
data "v", -1.500000, 1.000000, 5.250000
data "v", 1.500000, 1.000000, 5.250000
data "v", 0.000000, 0.500000, 4.500000
data "v", -1.000000, 1.000000, 6.000000
data "v", 1.000000, 1.000000, 6.000000
data "v", 0.000000, 1.750000, 6.000000
data "v", 0.008196, 0.035187, 6.063925
data "v", 0.000000, 0.770043, 7.525838
data "v", -0.000000, 0.216650, 6.688897
data "v", -1.250000, 1.187500, 7.500000
data "v", 1.250000, 1.187500, 7.500000
data "v", -0.662020, 2.007978, 3.233271
data "v", -1.000000, 2.000000, 5.000000
data "v", -0.500000, 1.750000, 6.000000
data "v", -0.625000, 1.562500, 7.500000
data "v", 0.649679, 2.014331, 3.264472
data "v", 1.000000, 2.000000, 5.000000
data "v", 0.500000, 1.750000, 6.000000
data "v", 0.625000, 1.562500, 7.500000
data "v", 1.945922, 0.977856, -0.996525
data "v", 1.740592, 1.499280, 0.911932
data "v", 0.000000, 2.035285, 0.170850
data "v", -1.085742, 2.120719, 1.742460
data "v", 1.140913, 2.077799, 1.634414
data "v", 0.375000, 2.500000, 2.000000
data "v", -0.375000, 2.500000, 2.000000
data "f", 6, 53, 27
data "f", 3, 22, 25
data "f", 3, 18, 2
data "f", 1, 10, 50
data "f", 11, 8, 9
data "f", 5, 11, 9
data "f", 21, 9, 8
data "f", 28, 10, 11
data "f", 14, 12, 13
data "f", 27, 15, 14
data "f", 5, 15, 4
data "f", 7, 14, 13
data "f", 16, 19, 17
data "f", 1, 16, 17
data "f", 51, 18, 16
data "f", 20, 23, 7
data "f", 21, 20, 5
data "f", 21, 22, 23
data "f", 8, 1, 21
data "f", 21, 5, 9
data "f", 5, 20, 24
data "f", 20, 7, 24
data "f", 7, 13, 24
data "f", 13, 12, 24
data "f", 12, 5, 24
data "f", 22, 1, 25
data "f", 1, 17, 25
data "f", 17, 19, 25
data "f", 19, 3, 25
data "f", 26, 55, 56
data "f", 28, 51, 50
data "f", 28, 27, 52
data "f", 46, 29, 47
data "f", 3, 33, 23
data "f", 47, 32, 2
data "f", 30, 37, 34
data "f", 43, 34, 44
data "f", 30, 34, 31
data "f", 29, 48, 47
data "f", 40, 38, 45
data "f", 36, 49, 48
data "f", 34, 39, 40
data "f", 34, 45, 44
data "f", 38, 39, 41
data "f", 36, 45, 38
data "f", 29, 44, 36
data "f", 42, 29, 26
data "f", 35, 49, 41
data "f", 47, 35, 32
data "f", 52, 53, 56
data "f", 2, 54, 46
data "f", 28, 4, 27
data "f", 28, 52, 51
data "f", 14, 6, 27
data "f", 51, 2, 18
data "f", 11, 4, 28
data "f", 50, 10, 28
data "f", 51, 52, 54
data "f", 54, 55, 46
data "f", 54, 52, 55
data "f", 56, 53, 42
data "f", 52, 27, 53
data "f", 39, 38, 40
data "f", 32, 3, 2
data "f", 7, 31, 6
data "f", 42, 6, 43
data "f", 33, 7, 23
data "f", 52, 56, 55
data "f", 26, 56, 42
data "f", 6, 42, 53
data "f", 22, 3, 23
data "f", 3, 19, 18
data "f", 1, 8, 10
data "f", 11, 10, 8
data "f", 5, 4, 11
data "f", 14, 15, 12
data "f", 5, 12, 15
data "f", 7, 6, 14
data "f", 16, 18, 19
data "f", 1, 50, 16
data "f", 21, 23, 20
data "f", 21, 1, 22
data "f", 26, 46, 55
data "f", 3, 37, 33
data "f", 46, 26, 29
data "f", 46, 47, 2
data "f", 30, 33, 37
data "f", 43, 31, 34
data "f", 29, 36, 48
data "f", 37, 32, 35
data "f", 35, 41, 39
data "f", 39, 34, 37
data "f", 37, 35, 39
data "f", 36, 38, 49
data "f", 34, 40, 45
data "f", 41, 49, 38
data "f", 36, 44, 45
data "f", 29, 43, 44
data "f", 42, 43, 29
data "f", 35, 48, 49
data "f", 47, 48, 35
data "f", 2, 51, 54
data "f", 27, 4, 15
data "f", 16, 50, 51
data "f", 32, 37, 3
data "f", 7, 30, 31
data "f", 6, 31, 43
data "f", 33, 30, 7
data "end"
