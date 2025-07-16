#include once "fbgfx.bi"
#include once "inc/vector3.bi"
#include once "inc/vector2.bi"
#include once "inc/orientation3.bi"
#include once "inc/cframe3.bi"
#include once "inc/mouse2.bi"
using FB

#define pi 3.1415926535
#define rad(degrees) degrees * PI/180
#define deg(radians) radians * 180/PI
#define myFormat(f) iif(f >= 0, " ", "-") + str(abs(fix(f))) + "." + str(int(abs(frac(f)) * 100))
#define rgb_r(c) (c shr 16 and &hff)
#define rgb_g(c) (c shr  8 and &hff)
#define rgb_b(c) (c        and &hff)

const SEED = 1337
const NUM_PARTICLES = 1000
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

'===============================================================================
'= FACE3
'===============================================================================
type Face3
    vertexIds(any) as integer
    normal as Vector3
    declare function addVertexId(vertexId as integer) as Face3
    declare static function calcNormal(vertexes() as Vector3) as Vector3
end type
function Face3.addVertexId(vertexId as integer) as Face3
    dim as integer n = ubound(vertexIds)
    redim preserve vertexIds(n + 1)
    vertexIds(n + 1) = vertexId
    return this
end function
static function Face3.calcNormal(vertexes() as Vector3) as Vector3
    dim as Vector3 a, b, c, normal
    dim as integer vertexCount = ubound(vertexes) + 1
    if vertexCount = 3 then
        a = vertexes(1)
        b = vertexes(2)
        c = vertexes(0)
        normal = (a - c).cross(b - c)
    elseif vertexCount > 3 then
        dim as integer ub = ubound(vertexes)
        for i as integer = 0 to ub
            a = iif(i < ub, vertexes(i + 1), vertexes( 0))
            b = iif(i >  0, vertexes(i - 1), vertexes(ub))
            c = vertexes(i)
            normal += (a - c).cross(b - c)
        next i
    end if
    return normal.unit
end function
'===============================================================================
'= MESH3
'===============================================================================
type Mesh3
    faces(any) as Face3
    vertexes(any) as Vector3
    sid as string
    declare function addFace(face as Face3) as Mesh3
    declare function addVertex(vertex as Vector3) as Mesh3
    declare function centerGeometry() as Mesh3
    declare function getVertex(vertexId as integer) as Vector3
end type
function Mesh3.addFace(face as Face3) as Mesh3
    dim as integer n = ubound(faces)
    redim preserve faces(n + 1) as Face3
    this.faces(n + 1) = face
    return this
end function
function Mesh3.addVertex(vertex as Vector3) as Mesh3
    dim as integer n = ubound(vertexes)
    redim preserve vertexes(n + 1) as Vector3
    vertexes(n + 1) = vertex
    return this
end function
function Mesh3.centerGeometry() as Mesh3
    dim as Vector3 average
    for i as integer = 0 to ubound(vertexes)
        average += vertexes(i)
    next i
    average /= ubound(vertexes)
    for i as integer = 0 to ubound(vertexes)
        vertexes(i) -= average
    next i
    return this
end function
function Mesh3.getVertex(vertexId as integer) as Vector3
    return this.vertexes(vertexId)
end function
'===============================================================================
'= OBJECT3
'===============================================================================
type Object3 extends CFrame3
    id as integer
    velocity as Vector3
    mesh as Mesh3
    declare function loadFile(filename as string) as integer
    declare function transform() as Object3
end type
sub string_split(subject as string, delim as string, pieces() as string)
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
        if s <> "" then
            index += 1: redim preserve pieces(index) as string
            pieces(index) = s
        end if
    wend
end sub
function Object3.loadFile(filename as string) as integer
    dim as string datum, pieces(any), s
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
                            val(pieces(3)) _
                        ))
                    case "f"
                        dim as integer index, n = ubound(pieces) - 1
                        dim as Vector3 vertexes(n)
                        dim as Face3 face
                        for j as integer = 0 to ubound(vertexes)
                            index = val(pieces(1 + j)) - 1
                            face.addVertexId(index)
                            vertexes(j) = mesh.getVertex(index)
                        next j
                        face.normal = Face3.calcNormal(vertexes())
                        mesh.addFace(face)
                    case else
                        continue while
                end select
            next i
        wend
    close #1
    return 0
end function
function Object3.transform() as Object3
    for i as integer = 0 to ubound(mesh.vertexes)
        dim as Vector3 v = mesh.vertexes(i)
        mesh.vertexes(i) = Vector3(_
            vector3_dot(vRight   , v),_
            vector3_dot(vUp      , v),_
            vector3_dot(vForward , v)_
        ) + this.position
    next i
    for i as integer = 0 to ubound(mesh.faces)
        dim as Vector3 n = mesh.faces(i).normal
        mesh.faces(i).normal = Vector3(_
            vector3_dot(vRight   , n),_
            vector3_dot(vUp      , n),_
            vector3_dot(vForward , n)_
        )
    next i
    return this
end function
function object_collection_add(filename as String, collection() as Object3) as Object3 ptr
    dim as Object3 o
    if o.loadFile(filename) = 0 then
        'o.centerGeometry()
        dim as integer n = ubound(collection)
        redim preserve collection(n+1)
        collection(n+1) = o
        return @collection(n+1)
    end if
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
        vector3_dot(camera.vRight  , p),_
        vector3_dot(camera.vUp     , p),_
        vector3_dot(camera.vForward, p) _
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

function clamp(value as double, min as double = 0, max as double = 1) as double
    return iif(value < min, min, iif(value > max, max, value))
end function

function clamp_int(value as integer, min as integer = 0, max as integer = 1) as integer
    return iif(value < min, min, iif(value > max, max, value))
end function

'=======================================================================
'= PARTICLETYPE
'=======================================================================
type ParticleType
    colr as integer
    position as Vector3
    twinkleAmp as double   = rnd * 32
    twinkleFreq as double  = rnd * 1
    twinklePhase as double = rnd * 2 * PI
    declare constructor ()
    declare constructor (position as Vector3, colr as integer)
    declare function getTwinkleColor() as integer
end type
constructor ParticleType
end constructor
constructor ParticleType (position as Vector3, colr as integer)
    this.position = position
    this.colr = colr
end constructor
function ParticleType.getTwinkleColor() as integer
    dim as integer r, g, b
    dim as double shift = _
    twinkleAmp * sin(2 * PI * frac(timer * twinkleFreq) + twinklePhase)
    r = clamp_int(rgb_r(colr) + int(shift), 0, 255)
    g = clamp_int(rgb_g(colr) + int(shift), 0, 255)
    b = clamp_int(rgb_b(colr) + int(shift), 0, 255)
    return rgb(r, g, b)
end function

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

sub renderObjects(objects() as Object3, camera as CFrame3, world as CFrame3)
    dim as Face3 face
    dim as Mesh3 mesh
    dim as Object3 o
    dim as Vector2 v2(any)
    dim as Vector3 normal, vertex, vewtex
    dim as double surfaceCos
    dim as boolean isVisible
    for i as integer = 0 to ubound(objects)
        o = objects(i)
        o.transform()
        mesh = o.mesh
        for j as integer = 0 to ubound(mesh.faces)
            isVisible = true
            face = mesh.faces(j)
            redim v2(ubound(face.vertexIds))
            for k as integer = 0 to ubound(face.vertexIds)
                vertex = mesh.getVertex(face.vertexIds(k))
                vewtex = vertexToView(vertex, camera)
                if k = 0 then
                    normal = vertexToView(face.normal, camera, true).unit
                    if vector3_dot(vewtex, normal) > 0 then
                        isVisible = false
                        exit for
                    end if
                end if
                v2(k) = viewToScreen(vewtex)
                if vewtex.z < 1 then
                    isVisible = false
                    exit for
                end if
            next k
            if isVisible then
                dim as Vector2 a, b, c
                if isVisible then
                    'surfaceCos = vector3_dot(face.normal, world.vUp)
                    '~ dim as integer cr, cg, cb, colr
                    '~ cr = int(clamp(surfaceCos)*255)
                    '~ cg = int(clamp(surfaceCos)*255)
                    '~ cb = int(clamp(surfaceCos)*255)
                    '~ colr = rgb(cr, cg, cb)
                    dim as integer colr = &hffffff
                    for k as integer = 0 to ubound(v2)
                        a = v2(k)
                        b = iif(k < ubound(v2), v2(k+1), v2(0))
                        line(a.x, a.y)-(b.x, b.y), colr
                    next k
                end if
            end if
        next j
    next i
end sub

sub renderParticles(particles() as ParticleType, camera as CFrame3)
    dim as ParticleType particle
    dim as Vector2 coords
    dim as Vector3 vertex
    dim as double radius
    for i as integer = 0 to ubound(particles)
        particle = particles(i)
        vertex = vertexToView(particle.position, camera)
        if vertex.z > 1 then
            coords = viewToScreen(vertex)
            radius = abs(1/vertex.z) * 0.2
            circle(coords.x, coords.y), radius, particle.getTwinkleColor()
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
    for r as double = start-2*PI-stp/4 to 2*PI step stp
        if r >= 0 then
            circle(0, 0), fr, reticleColor, r, r+stp/2
        end if
    next r
    '- draw directionol arrow
    dim as double sz
    dim as integer colr = arrowColor
    dim as Vector2 a, b
    if mouse.buttons > 0 then
        sz = fr/4
        a = m.unit*fr*1.15
        b = a.unit.port*sz
        line(a.x, a.y)-step(b.x, b.y), colr
        b = b.unit.starboard.rotate(rad(-30))*sz*2
        line -step(b.x, b.y), colr
        b = b.unit.rotate(rad(-120))*sz*2
        line -step(b.x, b.y), colr
        b = b.unit.rotate(rad(-120))*sz
        line -step(b.x, b.y), colr
    end if

    '- draw mouse cursor
    dim as ulong ants = &b11000011110000111100001111000011 shr int(frac(timer*1.5)*16)
    a = m
    sz = 0.076
    b = Vector2(rad(-75))*sz
    line(a.x, a.y)-step(b.x, b.y), &hf0f0f0, , ants
    b = b.rotate(rad(105))*0.8
    line -step(b.x, b.y), &hf0f0f0, , ants
    line -(a.x, a.y), &hf0f0f0, , ants
end sub

'=======================================================================
'= START
'=======================================================================
randomize 'SEED
window (-SCREEN_ASPECT_X, 1)-(SCREEN_ASPECT_X, -1)

dim as Mouse2 mouse
mouse.hide()
mouse.setMode(Mouse2Mode.Viewport)

dim as CFrame3 camera, world
dim as Object3 objectCollection(any)
dim as Object3 ptr spaceship = object_collection_add("mesh/spaceship-quads.obj", objectCollection())
dim as Object3 ptr controlObject, focusObject

controlObject = spaceship
focusObject = spaceship

dim as double rotateSpeed = 1
dim as double translateSpeed = 15
dim as double speedBoost = 2
screenset 1, 0

dim as double  fpsTimeStart = timer
dim as integer fps, frameCount

dim as double frameTimeStart = 0
dim as double frameTimeEnd   = 0

dim as Vector3 movement, targetMovement
dim as Vector3 rotation, targetRotation
dim as CFrame3 targetCamera

dim as Vector3 targetVelocity
dim as Orientation3 targetOrientation

setmouse pmap(0, 0), pmap(0, 1)
while true
    if multikey(SC_ESCAPE) then
        exit while
    end if

    cls
    renderObjects(objectCollection(), camera, world)
    renderParticles(particles(), camera)

    dim as string s = getOrientationStats(camera)
    printStringBlock(1, 1, s, "ORIENTATION", "_")

    mouse.update
    renderUI mouse

    dim as Object3 focus = *focusObject

    frameCount += 1
    if timer - fpsTimeStart >= 1 then
        fps = frameCount
        fpsTimeStart = timer
        frameCount = 0
    end if
    
    locate 14, 1
    print "FPS " + str(fps)
    
    screencopy 1, 0
    dim as double deltaTime = timer - frameTimeStart
    dim as double deltaRotate = deltaTime * rotateSpeed
    dim as double deltaTranslate = deltaTime * translateSpeed

    frameTimeStart = timer

    if multikey(SC_CONTROL) then
        deltaRotate *= speedBoost
        deltaTranslate *= speedBoost
    end if

    targetMovement = Vector3(0, 0, 0)
    targetRotation = Vector3(0, 0, 0)

    
    'targetCamera = (focus - focus.vForward * 12 + focus.vUp * 3) '->rotate(camera)
    '~ camera.position = Vector3(0, 3, 12) '(focus - focus.vForward * 12 + focus.vUp * 3) '->rotate(camera)

    '~ if multikey(SC_W) then targetVelocity =  translateSpeed * focus.vForward
    '~ if multikey(SC_S) then targetVelocity = -translateSpeed * focus.vForward
    '~ if multikey(SC_LEFT  ) then targetOrientation = focus.orientation.rotate(Vector3(0, 0, -radians(10)))
    '~ if multikey(SC_RIGHT ) then targetOrientation = focus.orientation.rotate(Vector3(0, 0,  radians(10)))
    '~ if multikey(SC_UP    ) then targetOrientation = focus.orientation.rotate(Vector3(-radians(10), 0, 0))
    '~ if multikey(SC_DOWN  ) then targetOrientation = focus.orientation.rotate(Vector3( radians(10), 0, 0))
    '~ if multikey(SC_END   ) then targetOrientation = focus.orientation.rotate(Vector3(0, -radians(10), 0))
    '~ if multikey(SC_DELETE) then targetOrientation = focus.orientation.rotate(Vector3(0,  radians(10), 0))

    '~ focus.velocity = focus.velocity.lerp(targetVelocity, deltaTime)
    '~ focus.position = focus.position + focus.velocity * deltaTime

    '~ focus.orientation = focus.orientation.lerp(targetOrientation, deltaTime)

    '~ *focusObject = focus

    dim as double mx, my
    mx = mouse.x
    my = mouse.y * SCREEN_ASPECT_X
    if mouse.leftDown then
        targetRotation.y -= mx
        targetRotation.x -= my
    end if
    if mouse.middleDown then
        targetMovement.x += mx
        targetMovement.y += my
    elseif mouse.rightDown then
        dim as Vector2 m = type(mx, my)
        m = m.rotate(atan2(targetRotation.z, targetRotation.x))
        targetRotation.x -= my
        targetRotation.z -= mx
    end if

    if multikey(SC_D     ) then targetMovement.x += 1
    if multikey(SC_A     ) then targetMovement.x -= 1
    if multikey(SC_SPACE ) then targetMovement.y += 1
    if multikey(SC_LSHIFT) then targetMovement.y -= 1
    if multikey(SC_W     ) then targetMovement.z += 1
    if multikey(SC_S     ) then targetMovement.z -= 1

    if multikey(SC_UP   ) then targetRotation.x -= 1
    if multikey(SC_DOWN ) then targetRotation.x += 1
    if multikey(SC_RIGHT) then targetRotation.y -= 1
    if multikey(SC_LEFT ) then targetRotation.y += 1
    if multikey(SC_Q    ) then targetRotation.z += 1
    if multikey(SC_E    ) then targetRotation.z -= 1

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
    'camera = camera.lerp(targetCamera, deltaTime)
    'rotation = rotation.lerp(targetRotation, deltaTime)
    'focus.orientation = focus.orientation.rotate(rotation)
    '*focusObject = focus
wend
setmouse , , 1
end
