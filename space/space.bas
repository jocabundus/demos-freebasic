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
#define rgb_r(c) (c shr 16 and &hff)
#define rgb_g(c) (c shr  8 and &hff)
#define rgb_b(c) (c        and &hff)
#define format_decimal(f, p) iif(f >= 0, " ", "-") + str(abs(fix(f))) + "." + str(int(abs(frac(f)) * 10^p))
#define clamp(value, min, max) iif(value < min, min, iif(value > max, max, value))

#macro array_append(arr, value)
    redim preserve arr(ubound(arr) + 1)
    arr(ubound(arr)) = value
#endmacro

const SEED = 1337
const NUM_PARTICLES = 1000
const FIELD_SIZE = 500

'=======================================================================
'= SCREEN STUFF
'=======================================================================
dim shared as integer SCREEN_W
dim shared as integer SCREEN_H
dim shared as integer SCREEN_DEPTH = 32
dim shared as integer SCREEN_PITCH
dim shared as double  SCREEN_ASPECT_X
dim shared as double  SCREEN_ASPECT_Y
dim shared as integer FULL_SCREEN = 1

screeninfo SCREEN_W, SCREEN_H, SCREEN_DEPTH
if screenres(SCREEN_W, SCREEN_H, SCREEN_DEPTH, 2, FULL_SCREEN) <> 0 then
    print "Failed to initialize graphics screen"
    sleep
    end
end if
screeninfo , , , , SCREEN_PITCH
SCREEN_ASPECT_X = SCREEN_W / SCREEN_H
SCREEN_ASPECT_Y = SCREEN_H / SCREEN_W

enum RenderType
    Solid
    Textured
    Wireframe
end enum
dim shared as integer RENDER_TYPE = RenderType.Solid

type PhongColor
    as double ambient = 0.5
    as double diffuse = 0.5
    as double specular = 0.5
    as double red, grn, blu
    declare constructor
    declare constructor(baseColor as integer)
    declare constructor(baseColor as integer, ambient as double, diffuse as double, specular as double)
    declare function applyAmbient(colr as integer, ambient as double) as integer
    declare function applyDiffuse(colr as integer, diffuse as double) as integer
    declare function applySpecular(colr as integer, N as Vector3, L as Vector3, V as Vector3) as integer
    declare function getRGB(colr as integer, byref r as integer, byref g as integer, byref b as integer) as PhongColor
end type
constructor PhongColor
end constructor
constructor PhongColor(baseColor as integer)
    this.red = rgb_r(baseColor) / 255
    this.grn = rgb_g(baseColor) / 255
    this.blu = rgb_b(baseColor) / 255
end constructor
constructor PhongColor(baseColor as integer, ambient as double, diffuse as double, specular as double)
    this.red = rgb_r(baseColor) / 255
    this.grn = rgb_g(baseColor) / 255
    this.blu = rgb_b(baseColor) / 255
    this.ambient  = ambient
    this.diffuse  = diffuse
    this.specular = specular
end constructor
function PhongColor.applyAmbient(colr as integer, ambient as double) as integer
    dim as integer r, g, b
    this.getRGB(colr, r, g, b)
    r += ambient * (1 - this.red)
    g += ambient * (1 - this.grn)
    b += ambient * (1 - this.blu)
    return rgb(r, g, b)
end function
function PhongColor.applyDiffuse(colr as integer, diffuse as double) as integer
    dim as integer r, g, b
    this.getRGB(colr, r, g, b)
    r += diffuse * (1 - this.red)
    g += diffuse * (1 - this.grn)
    b += diffuse * (1 - this.blu)
    return colr
end function
function PhongColor.applySpecular(colr as integer, N as Vector3, L as Vector3, V as Vector3) as integer
    dim as integer r, g, b
    this.getRGB(colr, r, g, b)
    dim as Vector3 H = (L + V) / (L + V).length
    dim as Vector3 A = (N + H)^(this.specular)
    
    return colr
end function
function PhongColor.getRGB(colr as integer, byref r as integer, byref g as integer, byref b as integer) as PhongColor
    r = (colr shr 16 and &hff)
    g = (colr shr  8 and &hff)
    b = (colr        and &hff)
    return this
end function
'===============================================================================
'= FACE3
'===============================================================================
type Face3
    id as integer
    colr as integer = rgb(128+92*rnd, 128+92*rnd, 128+92*rnd)
    ambient as double = rnd
    diffuse as double = rnd
    specular as double = rnd
    position as Vector3
    normal as Vector3
    vertexIds(any) as integer
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
        for i as integer = 1 to ub - 1
            a = vertexes(0)
            b = vertexes(i)
            c = vertexes(i+1)
            normal += (b - a).cross(c - a)
        next i
    end if
    return normal.unit
end function
'===============================================================================
'= MESH3
'===============================================================================
type BspNode3
    as integer faceId = -1
    as BspNode3 ptr behind, infront
end type
type Mesh3
    bspRoot as BspNode3 ptr
    faces(any) as Face3
    vertexes(any) as Vector3
    sid as string
    declare function addFace(face as Face3) as Mesh3
    declare function addVertex(vertex as Vector3) as Mesh3
    declare function buildBsp() as Mesh3
    declare function centerGeometry() as Mesh3
    declare function generateBsp() as Mesh3
    declare function getFace(faceId as integer) as Face3
    declare function getVertex(vertexId as integer) as Vector3
    declare function paintFaces(colr as integer) as Mesh3
    declare function splitBsp(faceIds() as integer) as BspNode3 ptr
end type
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
    select case 0
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
    case 1 '- min area
        dim as double compare, comparator
        dim as Vector3 a, b, c
        nearest = getFace(faceIds(0))
        for i as integer = 0 to ubound(faceIds)
            face = getFace(faceIds(i))
            a = getVertex(face.vertexIds(0))
            b = getVertex(face.vertexIds(1))
            c = getVertex(face.vertexIds(2))
            compare = (b - a).cross(c - a).length
            if compare < comparator then
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
            compare = face.normal.cross(average - face.position).length
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
            if splitter.normal.dot(face.position - splitter.position) <= 0 then
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
function Mesh3.getVertex(vertexId as integer) as Vector3
    return this.vertexes(vertexId)
end function
function Mesh3.paintFaces(colr as integer) as Mesh3
    for i as integer = 0 to ubound(faces)
        faces(i).colr = colr
    next i
    return Mesh3
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
            index += 1: redim preserve pieces(index)
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
    mesh.buildBsp()
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
function worldToView(position as vector3, camera as CFrame3, skipTranslation as boolean = false) as Vector3
    if not skipTranslation then
        position -= camera.position
    end if
    return Vector3(_
        vector3_dot(camera.vRight  , position),_
        vector3_dot(camera.vUp     , position),_
        vector3_dot(camera.vForward, position) _
    )
end function

'=======================================================================
'= SCREEN TRANSFORM
'----------------------------------------------------------------------
'- Calculate FOV as tan(degrees/2)
'- Default (1) is 90 degrees
'=======================================================================
function viewToScreen(vp as vector3, fov as double = 1) as Vector2
    dim as Vector2 v2
    vp.z *= fov
    v2.x = (vp.x / vp.z) * 2
    v2.y = (vp.y / vp.z) * 2
    return v2
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
    r = clamp(rgb_r(colr) + int(shift), 0, 255)
    g = clamp(rgb_g(colr) + int(shift), 0, 255)
    b = clamp(rgb_b(colr) + int(shift), 0, 255)
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
                dim as double  d = clamp(1-sin((p - va).length), 0, 1)
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
                dim as double  d = clamp(1-sin((p - va).length), 0, 1)
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

type Vector2Int
    x as integer
    y as integer
    declare constructor ()
    declare constructor (x as integer, y as integer)
end type
constructor Vector2Int
end constructor
constructor Vector2Int (x as integer, y as integer)
    this.x = x
    this.y = y
end constructor
function mapPointToUV(x as double, y as double) as integer
    return &h808080 + int(x*64) xor int(y * 64)
end function
sub drawTexturedLine(a as Vector2Int, b as Vector2Int, c as Vector2, d as Vector2)

    dim as double u, v, uvLen, ustep, vstep
    dim as uinteger ptr pixel
    dim as integer abLen
    dim as any ptr buffer

    
    
    buffer = screenptr
    if buffer <> 0 then
        abLen = b.x - a.x
        u = c.x
        v = c.y
        ustep = (d.x - c.x) / abLen
        vstep = (d.y - c.y) / abLen
        uvLen = (c - d).length
        pixel = buffer + a.y * SCREEN_PITCH + a.x * 4
        
        screenlock
        for x as integer = 0 to abLen - 1
            *pixel = mapPointToUV(u, v)
            pixel += 1
            u += ustep
            v += vstep
        next x
        screenunlock
    end if

end sub
function clamp_int(value as integer, min as integer, max as integer) as integer
    return iif(value < min, min, iif(value > max, max, value))
end function
sub drawTexturedTri(a as Vector2Int, b as Vector2Int, c as Vector2Int, mapFunc as function(x as double, y as double) as integer, quality as integer = 0)
    dim as integer q = 2^quality
    dim as integer w = q-1
    dim as integer colr = &hffffff
    dim as double ab, ac, bc
    dim as double abx, acx, bcx
    dim as double vab, vac, vbc
    dim as double vabx, vacx, vbcx
    if a.y > b.y then swap a, b
    if a.y > c.y then swap a, c
    if b.y > c.y then swap b, c
    clamp_int(a.y, 0, SCREEN_H-1)
    clamp_int(b.y, 0, SCREEN_H-1)
    clamp_int(c.y, 0, SCREEN_H-1)
    clamp_int(a.x, 0, SCREEN_W-1)
    clamp_int(b.x, 0, SCREEN_W-1)
    clamp_int(c.x, 0, SCREEN_W-1)
    if a.x = b.x or a.x = c.x or b.x = c.x then exit sub
    if a.y = b.y or a.y = c.y or b.y = c.y  then exit sub
    if (a.x-b.x)=0 or (a.x-c.x)=0 or (b.x-c.x)=0 then exit sub
    if (a.y-b.y)=0 or (a.y-c.y)=0 or (b.y-c.y)=0 then exit sub
    'a.y -= a.y and w
    'b.y -= b.y and w
    'c.y -= c.y and w
    ab = a.x
    ac = a.x
    bc = b.x
    abx = q*(b.x-a.x)/(b.y-a.y)
    acx = q*(c.x-a.x)/(c.y-a.y)
    bcx = q*(c.x-b.x)/(c.y-b.y)
    vab = 0
    vac = 0
    vbc = 0.5
    vabx = q/(b.y-a.y)
    vacx = q/(c.y-a.y)
    vbcx = q/(c.y-b.y)*0.5
    for i as integer = a.y to b.y step q
        if ab < 0 or ac >= SCREEN_W then continue for
        if i < 0 or i >= SCREEN_H then exit for
        drawTexturedLine(_
            Vector2Int(int(ab), i), Vector2Int(int(ac), i),_
            Vector2(0, vab), Vector2(1, vac) _
        )
        ab += abx
        ac += acx
        vab += vabx
        vac += vacx
    next i
    ac -= acx
    vac -= vacx
    for i as integer = b.y to c.y step q
        if bc < 0 or ac >= SCREEN_W then continue for
        if i < 0 or i >= SCREEN_H then exit for
        drawTexturedLine(_
            Vector2Int(int(bc), i), Vector2Int(int(ac), i),_
            Vector2(0, vbc), Vector2(1, vac) _
        )
        ac += acx
        bc += bcx
        vac += vabx
        vbc += vbcx
    next i
end sub
sub drawTri(a as Vector2Int, b as Vector2Int, c as Vector2Int, colr as integer, quality as integer = 0)
    dim as integer q = 2^quality
    dim as integer w = q-1
    dim as double ab, ac, bc
    dim as double abx, acx, bcx
    if a.y > b.y then swap a, b
    if a.y > c.y then swap a, c
    if b.y > c.y then swap b, c
    a.y -= a.y and w
    b.y -= b.y and w
    c.y -= c.y and w
    ab = a.x
    ac = a.x
    bc = b.x
    abx = q*(b.x-a.x)/(b.y-a.y)
    acx = q*(c.x-a.x)/(c.y-a.y)
    bcx = q*(c.x-b.x)/(c.y-b.y)
    for i as integer = a.y to b.y step q
        line (int(ab) - (int(ab) and w), i)-(int(ac) - (int(ac) and w), i+w), colr, bf
        ab += abx
        ac += acx
    next i
    ac -= acx
    for i as integer = b.y to c.y step q
        line (int(bc) - (int(bc) and w), i)-(int(ac) - (int(ac) and w), i+w), colr, bf
        ac += acx
        bc += bcx
    next i
end sub
sub renderFaceSolid(byref face as Face3, byref mesh as Mesh3, byref camera as CFrame3, byref world as CFrame3)
    dim as Vector2 a, b, c, pixels(ubound(face.vertexIds))
    dim as Vector3 viewNormal, viewVertex(ubound(face.vertexIds))
    dim as Vector3 worldNormal, worldVertex
    dim as integer colr, cr, cg, cb
    dim as double dot, value
    cr = rgb_r(face.colr)
    cg = rgb_g(face.colr)
    cb = rgb_b(face.colr)
    dot = vector3_dot(face.normal, (world.vUp + camera.vForward).unit)
    value = 64 * dot
    colr = rgb(_
        clamp(cr+value, 0, 255),_
        clamp(cg+value, 0, 255),_
        clamp(cb+value, 0, 255) _
    )
    for i as integer = 0 to ubound(face.vertexIds)
        worldVertex   = mesh.getVertex(face.vertexIds(i))
        viewVertex(i) = worldToView(worldVertex, camera)
        if viewVertex(i).z < 1 then
            exit sub
        end if
    next i
    viewNormal = worldToView(face.normal, camera, true).unit
    if vector3_dot(viewVertex(0), viewNormal) > 0 then
        exit sub
    end if
    for i as integer = 0 to ubound(viewVertex)
        pixels(i) = viewToScreen(viewVertex(i))
    next i
    for i as integer = 1 to ubound(pixels) - 1
        a = pixels(0)
        b = pixels(i)
        c = pixels(i+1)
        a.x = pmap(a.x, 0): a.y = pmap(a.y, 1)
        b.x = pmap(b.x, 0): b.y = pmap(b.y, 1)
        c.x = pmap(c.x, 0): c.y = pmap(c.y, 1)
        window
        drawTri(_
            Vector2Int(a.x, a.y),_
            Vector2Int(b.x, b.y),_
            Vector2Int(c.x, c.y),_
            colr _
        )
        window (-SCREEN_ASPECT_X, 1)-(SCREEN_ASPECT_X, -1)
    next i
end sub
sub renderFaceTextured(byref face as Face3, byref mesh as Mesh3, byref camera as CFrame3, byref world as CFrame3)
    dim as Vector2 a, b, c, pixels(ubound(face.vertexIds))
    dim as Vector3 viewNormal, viewVertex(ubound(face.vertexIds))
    dim as Vector3 worldNormal, worldVertex
    dim as integer value, colr, cr, cg, cb
    dim as double dot
    cr = rgb_r(face.colr)
    cg = rgb_g(face.colr)
    cb = rgb_b(face.colr)
    dot = vector3_dot(face.normal, World.vUp)
    dot = vector3_dot(face.normal, (camera.position - face.position).unit)
    value = 64 * (-0.5 + dot)
    colr = rgb(_
        clamp(cr+value, 0, 255),_
        clamp(cg+value, 0, 255),_
        clamp(cb+value, 0, 255) _
    )
    for i as integer = 0 to ubound(face.vertexIds)
        worldVertex   = mesh.getVertex(face.vertexIds(i))
        viewVertex(i) = worldToView(worldVertex, camera)
        if viewVertex(i).z < 1 then
            exit sub
        end if
    next i
    viewNormal = worldToView(face.normal, camera, true).unit
    if vector3_dot(viewVertex(0), viewNormal) > 0 then
        exit sub
    end if
    for i as integer = 0 to ubound(viewVertex)
        pixels(i) = viewToScreen(viewVertex(i))
    next i
    for i as integer = 1 to ubound(pixels) - 1
        a = pixels(0)
        b = pixels(i)
        c = pixels(i+1)
        a.x = pmap(a.x, 0): a.y = pmap(a.y, 1)
        b.x = pmap(b.x, 0): b.y = pmap(b.y, 1)
        c.x = pmap(c.x, 0): c.y = pmap(c.y, 1)
        window
        drawTexturedTri(_
            Vector2Int(a.x, a.y),_
            Vector2Int(b.x, b.y),_
            Vector2Int(c.x, c.y),_
            @mapPointToUV _
        )
        window (-SCREEN_ASPECT_X, 1)-(SCREEN_ASPECT_X, -1)
    next i
end sub
sub renderFaceWireframe(byref face as Face3, byref mesh as Mesh3, byref camera as CFrame3, byref world as CFrame3, style as integer = &hffff)
    dim as Vector2 a, b, c, pixels(ubound(face.vertexIds))
    dim as Vector3 viewVertex(ubound(face.vertexIds))
    dim as Vector3 worldVertex
    dim as integer value, colr, cr, cg, cb
    dim as double dot
    cr = rgb_r(face.colr)
    cg = rgb_g(face.colr)
    cb = rgb_b(face.colr)
    dot = vector3_dot(face.normal, World.vUp)
    value = 64 * (-0.5 + dot)
    colr = rgb(_
        clamp(cr+value, 0, 255),_
        clamp(cg+value, 0, 255),_
        clamp(cb+value, 0, 255) _
    )
    for i as integer = 0 to ubound(face.vertexIds)
        worldVertex   = mesh.getVertex(face.vertexIds(i))
        viewVertex(i) = worldToView(worldVertex, camera)
        if viewVertex(i).z < 1 then
            exit sub
        end if
    next i
    for i as integer = 0 to ubound(viewVertex)
        pixels(i) = viewToScreen(viewVertex(i))
    next i
    for i as integer = 1 to ubound(pixels) - 1
        a = pixels(i-1)
        b = pixels(i)
        line(a.x, a.y)-(b.x, b.y), colr, , style
    next i
    a = pixels(ubound(pixels))
    b = pixels(0)
    line(a.x, a.y)-(b.x, b.y), colr
end sub
sub renderBspFaces(node as BspNode3 ptr, byref mesh as Mesh3, byref camera as CFrame3, byref world as CFrame3)
    if node = 0 then exit sub
    dim as Vector3 normal, vertex, vewtex
    dim as Face3 face
    dim as integer faceId = node->faceId
    dim as double dot
    if faceId >= 0 then
        face = mesh.getFace(faceId)
        dot = face.normal.dot(camera.position - face.position)
        if dot > 0 then
            renderBspFaces node->behind, mesh, camera, world
            renderBspFaces node->infront, mesh, camera, world
        else
            renderBspFaces node->infront, mesh, camera, world
            renderBspFaces node->behind, mesh, camera, world
        end if
        select case RENDER_TYPE
            case RenderType.Solid   : renderFaceSolid face, mesh, camera, world
            case RenderType.Textured: renderFaceTextured face, mesh, camera, world
            case RenderType.Wireframe
                if dot > 0 then
                    renderFaceWireframe face, mesh, camera, world
                else
                    renderFaceWireframe face, mesh, camera, world
                end if
        end select
    end if
end sub
sub renderObjects(objects() as Object3, byref camera as CFrame3, byref world as CFrame3)
    dim as Mesh3 mesh
    dim as Object3 o
    for i as integer = 0 to ubound(objects)
        o = objects(i)
        o.transform()
        mesh = o.mesh
        renderBspFaces mesh.bspRoot, mesh, camera, world
    next i
end sub
sub renderParticles(particles() as ParticleType, camera as CFrame3)
    dim as ParticleType particle
    dim as Vector2 coords
    dim as Vector3 vertex
    dim as double radius
    for i as integer = 0 to ubound(particles)
        particle = particles(i)
        vertex = worldToView(particle.position, camera)
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

sub printStringBlock(row as integer, col as integer, text as string, header as string = "", border as string = "", footer as string = "")
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
        locate row+1, col: print string(maxw, " ");
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
    if footer <> "" then
        locate row, col: print string(maxw, footer);
    end if
end sub

function getAxisNames() as string
    dim as string axisNames(2) = {"X", "Y", "Z"}
    dim as integer roww = 21
    dim as integer colw = 8
    dim as string body   = ""
    dim as string colhdr = "_____"
    dim as string row
    row = space(roww): for i as integer = 0 to 2: mid(row, 1+i*colw) = colhdr: next i: body += row + "$$"
    row = space(roww): for i as integer = 0 to 2: mid(row, 1+i*colw) = axisNames(i): next i: body += row + "$"
    row = space(roww): for i as integer = 0 to 2: mid(row, 1+i*colw) = colhdr: next i: body += row + "$$"
    return body + "$"
end function

function getOrientationStats(camera as CFrame3) as string
    dim as string stats(3, 3)
    for i as integer = 0 to 2
        dim as Vector3 o = camera.orientation.matrix(i)
        stats(0, i) = format_decimal(o.x, 2)
        stats(1, i) = format_decimal(o.y, 2)
        stats(2, i) = format_decimal(o.z, 2)
    next i
    dim as integer roww = 21
    dim as integer colw = 8
    dim as string body   = ""
    dim as string row
    for i as integer = 0 to 2
        dim as string row = space(roww)
        for j as integer = 0 to 2
            mid(row, 1+j*colw) = stats(i, j)
        next j
        body += row + iif(i < 2, "$$", "")
    next i
    return body
end function

function getLocationStats(camera as CFrame3) as string
    dim as string axisNames(2) = {"X", "Y", "Z"}
    dim as integer roww = 21
    dim as integer colw = 8
    dim as string body   = ""
    dim as string row
    dim as string colhdr = "_____"
    'row = space(roww): for i as integer = 0 to 2: mid(row, 1+i*colw) = axisNames(i): next i: body += row + "$"
    'row = space(roww): for i as integer = 0 to 2: mid(row, 1+i*colw) = colhdr: next i: body += row + "$$"
    row = space(roww)
    mid(row, 1+0*colw) = format_decimal(camera.position.x, 1)
    mid(row, 1+1*colw) = format_decimal(camera.position.y, 1)
    mid(row, 1+2*colw) = format_decimal(camera.position.z, 1)
    return body + row
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

dim as CFrame3 cam, camera, world
dim as Object3 objectCollection(any)
dim as Object3 ptr spaceship = object_collection_add("mesh/spaceship-quads.obj", objectCollection())
dim as Object3 ptr controlObject, focusObject

'camera.orientation *= Vector3(0, rad(180), 0)

spaceship->mesh.paintFaces(&hc0c0c0)

controlObject = spaceship
focusObject = spaceship

dim as double rotateSpeed = 1
dim as double translateSpeed = 15
dim as double speedBoost = 2
screenset 1, 0

dim as double  fpsTimeStart = timer
dim as integer fps, frameCount

dim as double frameTimeStart = timer
dim as double frameTimeEnd   = 0

dim as Vector3 movement, targetMovement
dim as Vector3 rotation, targetRotation
dim as Vector3 angular, targetAngular, targetVelocity
dim as Vector3 cameraFollowDistance
dim as CFrame3 targetCamera
dim as Vector3 ptr lookAt = 0
dim as boolean lookBackwards = false

enum NavigationMode
    Fly    = 0
    Follow = 1
end enum
dim as integer navMode = NavigationMode.Fly

setmouse pmap(0, 0), pmap(0, 1)
while true
    if multikey(SC_ESCAPE) then
        exit while
    end if

    cls
    dim as Object3 focus = *focusObject
    
    cam = camera
    if lookBackwards then
        cam.orientation *= Vector3(0, rad(180), 0)
    end if
    renderParticles(particles(), cam)
    renderObjects(objectCollection(), cam, world)

    printStringBlock( 1, 1, getOrientationStats(camera), "ORIENTATION", "_", "")
    printStringBlock(10, 1,    getLocationStats(camera),    "LOCATION", "_", "")
    

    mouse.update
    renderUI mouse

    frameCount += 1
    if timer - fpsTimeStart >= 1 then
        fps = frameCount
        fpsTimeStart = timer
        frameCount = 0
    end if

    dim as string buffer = space(21)
    mid(buffer, 1) = format_decimal(fps, 1)
    printStringBlock(15, 1, buffer, "FPS", "_", "")
    
    screencopy 1, 0
    dim as double deltaTime = timer - frameTimeStart
    dim as double deltaRotate = deltaTime * rotateSpeed
    dim as double deltaTranslate = deltaTime * translateSpeed

    frameTimeStart = timer

    if multikey(SC_CONTROL) then
        deltaRotate *= speedBoost
        deltaTranslate *= speedBoost
    end if

    if multikey(SC_PAGEDOWN) then
        lookBackwards = true
    else
        lookBackwards = false
    end if

    if multikey(SC_1) or multikey(SC_6) then
        navMode = NavigationMode.Fly
        lookAt  = iif(multikey(SC_6), @focus.position, 0)
    elseif multikey(SC_2) or _
           multikey(SC_3) or _
           multikey(SC_4) or _
           multikey(SC_5) then
        navMode = NavigationMode.Follow
        lookAt  = 0
        if multikey(SC_2) then cameraFollowDistance = Vector3(0,  3, 12)
        if multikey(SC_3) then cameraFollowDistance = Vector3(0,  6, 24)
        if multikey(SC_4) then cameraFollowDistance = Vector3(0,  9, 32)
        if multikey(SC_5) then cameraFollowDistance = Vector3(0, 12, 48)
    elseif multikey(SC_7) then
        RENDER_TYPE = RenderType.Wireframe
    elseif multikey(SC_8) then
        RENDER_TYPE = RenderType.Solid
    elseif multikey(SC_9) then
        RENDER_TYPE = RenderType.Textured
    end if

    targetMovement = Vector3(0, 0, 0)
    targetRotation = Vector3(0, 0, 0)

    select case navMode
    case NavigationMode.Fly
        dim as double mx, my
        mx = mouse.x
        my = mouse.y * SCREEN_ASPECT_X
        mx *= 1.2
        my *= 1.2
        if mouse.leftDown then
            targetRotation.y  = mx
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

        if multikey(SC_D     ) then targetMovement.x =  1
        if multikey(SC_A     ) then targetMovement.x = -1
        if multikey(SC_SPACE ) then targetMovement.y =  1
        if multikey(SC_LSHIFT) then targetMovement.y = -1
        if multikey(SC_W     ) then targetMovement.z =  1
        if multikey(SC_S     ) then targetMovement.z = -1

        if multikey(SC_UP   ) then targetRotation.x =  1
        if multikey(SC_DOWN ) then targetRotation.x = -1
        if multikey(SC_RIGHT) then targetRotation.y =  1
        if multikey(SC_LEFT ) then targetRotation.y = -1
        if multikey(SC_E    ) then targetRotation.z =  1
        if multikey(SC_Q    ) then targetRotation.z = -1

        if targetMovement.length > 0 then
            targetMovement = vector3_dot(camera.orientation.matrix(), targetMovement).unit
        end if
        'if targetRotation.length > 1 then
        '    targetRotation = targetRotation.unit
        'end if
        movement = movement.lerp(targetMovement, deltaTime)
        rotation = rotation.lerp(targetRotation, deltaTime)
        camera += movement * deltaTranslate
        camera.orientation *= rotation * deltaRotate
        if lookAt then
            camera.orientation = Orientation3().look(focus.position - camera.position)
        end if
    case NavigationMode.Follow
        if multikey(SC_D     ) then targetMovement.x =  1
        if multikey(SC_A     ) then targetMovement.x = -1
        if multikey(SC_SPACE ) then targetMovement.y =  1
        if multikey(SC_LSHIFT) then targetMovement.y = -1
        if multikey(SC_W     ) then targetMovement.z =  1
        if multikey(SC_S     ) then targetMovement.z = -1
        
        if multikey(SC_UP   ) then targetRotation.x =  1
        if multikey(SC_DOWN ) then targetRotation.x = -1
        if multikey(SC_RIGHT) then targetRotation.y =  1
        if multikey(SC_LEFT ) then targetRotation.y = -1
        if multikey(SC_E    ) then targetRotation.z =  1
        if multikey(SC_Q    ) then targetRotation.z = -1

        targetVelocity = targetVelocity.lerp(vector3_dot(focus.orientation.matrix(), targetMovement*10), deltaTime/10)
        targetAngular = targetAngular.lerp(targetRotation*2, deltaTime/15)
        
    end select

    focus.velocity = focus.velocity.lerp(targetVelocity, deltaTime)
    focus.position += focus.velocity * deltaTranslate
    angular = angular.lerp(targetAngular, deltaTime)
    focus.orientation *= angular * deltaRotate
    *focusObject = focus

    if navMode = NavigationMode.Follow then
        targetCamera = (_
              focus _
            - focus.vForward _
            * iif(lookBackwards, -cameraFollowDistance.z - 3, cameraFollowDistance.z) _
            + focus.vUp * cameraFollowDistance.y _
        )
        'targetCamera.orientation = targetCamera.orientation.look(focus.position - camera.position)
        camera       = camera.lerp(targetCamera, deltaTime*3)
    end if
wend
mouse.Show()
end
