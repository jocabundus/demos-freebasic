' -----------------------------------------------------------------------------
'  A Nameless 3D Polygonal Software Renderer & Rasterizer
'
'  Copyright (c) 2025 Joe King
'  Licensed under the MIT License.
'  See LICENSE file or https://opensource.org/licenses/MIT for details.
'
'
'  "It's six degrees of raw freedom!"
'      ~ Jimmy, 34 (Grand Rivers, KY)
'
'
'  Recommended build:
'    fbc64 %f -w all -gen gcc -O 3 -Wc -march=native
' -----------------------------------------------------------------------------

#include once "fbgfx.bi"
#include once "inc/object3.bi"
#include once "inc/cframe3.bi"
#include once "inc/mesh3.bi"
#include once "inc/vector2.bi"
#include once "inc/vector3.bi"
#include once "inc/mouse2.bi"
#include once "inc/helpers.bi"
#include once "inc/defines.bi"
using FB

#ifdef __FB_64BIT__
    #define _long_ longint
    #define _ulong_ ulongint
#else
    #define _long_ long
    #define _ulong_ ulong
#endif

const NUM_PARTICLES = 1000
const FIELD_SIZE = 500

'------------------------------------------------------------------------------
' SCREEN STUFF
'------------------------------------------------------------------------------
dim shared as _long_ SCREEN_W
dim shared as _long_ SCREEN_H
dim shared as _long_ SCREEN_DEPTH = 32
dim shared as _long_ SCREEN_BPP
dim shared as _long_ SCREEN_PITCH
dim shared as double  SCREEN_ASPECT_X
dim shared as double  SCREEN_ASPECT_Y
dim shared as integer FULL_SCREEN = 1
dim shared as integer WINDOW_X0, WINDOW_X1
dim shared as integer WINDOW_Y0, WINDOW_Y1

screeninfo SCREEN_W, SCREEN_H, SCREEN_DEPTH
if screenres(SCREEN_W, SCREEN_H, SCREEN_DEPTH, 2, FULL_SCREEN) <> 0 then
    print "Failed to initialize graphics screen"
    sleep
    end
end if
screeninfo SCREEN_W, SCREEN_H, SCREEN_DEPTH, SCREEN_BPP, SCREEN_PITCH
SCREEN_ASPECT_X = SCREEN_W / SCREEN_H
SCREEN_ASPECT_Y = SCREEN_H / SCREEN_W

WINDOW_X0 = -SCREEN_ASPECT_X
WINDOW_X1 =  SCREEN_ASPECT_X
WINDOW_Y0 =  1
WINDOW_Y1 = -1

enum RenderMode
    None
    Solid
    Textured
    Wireframe
end enum
dim shared as integer RENDER_MODE = RenderMode.Textured
dim shared as integer QUALITY = 2, MIN_QUALITY = 0, MAX_QUALITY = 5 '- 0 is best

enum AutoQuality
    None
    DistanceBased
    FpsBased
end enum
dim shared as integer AUTO_QUALITY = AutoQuality.DistanceBased


'=======================================================================
'= VIEW TRANSFORM
'=======================================================================
function worldToView(position as vector3, camera as CFrame3, skipTranslation as boolean = false) as Vector3
    if not skipTranslation then
        position -= camera.position
    end if
    return Vector3(_
        dot(camera.vRight  , position),_
        dot(camera.vUp     , position),_
        dot(camera.vForward, position) _
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

dim shared as integer texSize = 64
dim shared as uinteger texture(texSize-1, texSize-1)
dim as double a, b, u, v
for y as double = 0 to texSize-1
    for x as double = 0 to texSize-1
        a = x / texSize
        b = y / texSize
        u = sin(a*2*PI)
        v = cos(a*2*PI)
        texture(x, y) = pickStarColor(Vector2(u, v)*(a+b)*3.9, 4)
    next x
next y
function uvToColor(u as double, v as double) as uinteger
    return texture(int(texSize * u), int(texSize * v))
end function
sub drawTexturedTri(a as Vector2, b as Vector2, c as Vector2, uva as Vector2, uvb as Vector2, uvc as Vector2, mapFunc as function(x as double, y as double) as integer, quality as integer = 0)
    dim as _long_ bpp = SCREEN_BPP, pitch = SCREEN_PITCH
    dim as any ptr buffer, rowStart
    dim as ulong ptr pixel
    dim as Vector2 sideA, sideB, sideC
    dim as Vector2 toplft, btmrgt
    dim as Vector2 sau, sbu, scu
    dim as Vector2 bas, pro, p, n
    dim as integer x0, x1, y0, y1
    dim as double sal, sbl, scl
    dim as double u, v, w
    toplft.x = iif(a.x < b.x, iif(a.x < c.x, a.x, c.x), iif(b.x < c.x, b.x, c.x))
    toplft.y = iif(a.y < b.y, iif(a.y < c.y, a.y, c.y), iif(b.y < c.y, b.y, c.y))
    btmrgt.x = iif(a.x > b.x, iif(a.x > c.x, a.x, c.x), iif(b.x > c.x, b.x, c.x))
    btmrgt.y = iif(a.y > b.y, iif(a.y > c.y, a.y, c.y), iif(b.y > c.y, b.y, c.y))
    if toplft.x >= SCREEN_W then exit sub
    if toplft.y >= SCREEN_H then exit sub
    if btmrgt.x < 0 then exit sub
    if btmrgt.y < 0 then exit sub
    if toplft.x < 0 then toplft.x = 0
    if toplft.y < 0 then toplft.y = 0
    if btmrgt.x >= SCREEN_W then btmrgt.x = SCREEN_W-1
    if btmrgt.y >= SCREEN_H then btmrgt.y = SCREEN_H-1
    bas = normalize(c-b): pro = a-b: sideA = b + bas * dot(pro, bas) - a
    bas = normalize(a-c): pro = b-c: sideB = c + bas * dot(pro, bas) - b
    bas = normalize(b-a): pro = c-a: sideC = a + bas * dot(pro, bas) - c
    sau = sideA.normalized: sbu = sideB.normalized: scu = sideC.normalized
    sal = 1/sideA.length: sbl = 1/sideB.length: scl = 1/sideC.length
    x0 = int(toplft.x): x1 = int(btmrgt.x)
    y0 = int(toplft.y): y1 = int(btmrgt.y)
    buffer = screenptr
    if buffer <> 0 then
        rowStart = buffer + y0*pitch + x0*bpp
        screenlock
        for y as integer = y0 to y1
            pixel = rowStart
            for x as integer = x0 to x1
                p = Vector2(x, y)
                u = 1-dot(p-a, sau) * sal: if u < 0 or u > 1 then pixel += 1: continue for
                v = 1-dot(p-b, sbu) * sbl: if v < 0 or v > 1 then pixel += 1: continue for
                w = 1-dot(p-c, scu) * scl: if w < 0 or w > 1 then pixel += 1: continue for
                n = (uva*u + uvb*v + uvc*w)/3
                *pixel = uvToColor(n.x, n.y)
                pixel += 1
            next x
            rowStart += pitch
        next
        screenunlock
    end if
end sub
sub drawTexturedTriLowQ(a as Vector2, b as Vector2, c as Vector2, uva as Vector2, uvb as Vector2, uvc as Vector2, mapFunc as function(x as double, y as double) as integer, quality as integer = 0)
    dim as _long_ bpp = SCREEN_BPP, pitch = SCREEN_PITCH
    dim as _long_ imgPitch, imgBpp, imgw, imgh
    dim as any ptr buffer = screenptr, row, start
    dim as any ptr imgBuffer, imgRowStart, imgPixelDataStart
    dim as ulong ptr imgPixel, pixel
    dim as integer q = 2^quality
    dim as Vector2 sideA, sideB, sideC
    dim as Vector2 toplft, btmrgt
    dim as Vector2 sau, sbu, scu
    dim as Vector2 bas, pro, p, n
    dim as integer x0, x1, y0, y1
    dim as double sal, sbl, scl
    dim as double u, v, w
    toplft.x = iif(a.x < b.x, iif(a.x < c.x, a.x, c.x), iif(b.x < c.x, b.x, c.x))
    toplft.y = iif(a.y < b.y, iif(a.y < c.y, a.y, c.y), iif(b.y < c.y, b.y, c.y))
    btmrgt.x = iif(a.x > b.x, iif(a.x > c.x, a.x, c.x), iif(b.x > c.x, b.x, c.x))
    btmrgt.y = iif(a.y > b.y, iif(a.y > c.y, a.y, c.y), iif(b.y > c.y, b.y, c.y))
    if toplft.x >= SCREEN_W then exit sub
    if toplft.y >= SCREEN_H then exit sub
    if btmrgt.x < 0 then exit sub
    if btmrgt.y < 0 then exit sub
    if toplft.x < 0 then toplft.x = 0
    if toplft.y < 0 then toplft.y = 0
    if btmrgt.x >= SCREEN_W then btmrgt.x = SCREEN_W-1
    if btmrgt.y >= SCREEN_H then btmrgt.y = SCREEN_H-1
    bas = normalize(c-b): pro = a-b: sideA = b + bas * dot(pro, bas) - a
    bas = normalize(a-c): pro = b-c: sideB = c + bas * dot(pro, bas) - b
    bas = normalize(b-a): pro = c-a: sideC = a + bas * dot(pro, bas) - c
    sau = sideA.normalized: sbu = sideB.normalized: scu = sideC.normalized
    sal = 1/sideA.length: sbl = 1/sideB.length: scl = 1/sideC.length
    x0 = int(toplft.x): x1 = int(btmrgt.x)
    y0 = int(toplft.y): y1 = int(btmrgt.y)
    x0 = (x0 \ q) * q
    x1 = (x1 \ q) * q
    y0 = (y0 \ q) * q
    y1 = (y1 \ q) * q
    imgw = (x1-x0+q)\q
    imgh = (y1-y0+q)\q
    imgBuffer = imagecreate(imgw, imgh)
    imageinfo imgBuffer, imgw, imgh, imgBpp, imgPitch, imgPixelDataStart
    start = buffer + y0*pitch + x0*bpp
    if buffer <> 0 and imgBuffer <> 0 then
        screenlock
        imgRowStart = imgPixelDataStart
        for y as integer = y0 to y1 step q
            imgPixel = imgRowStart
            for x as integer = x0 to x1 step q
                p = Vector2(x, y)
                u = 1-dot(p-a, sau) * sal: if u < 0 or u > 1 then imgPixel += 1: continue for
                v = 1-dot(p-b, sbu) * sbl: if v < 0 or v > 1 then imgPixel += 1: continue for
                w = 1-dot(p-c, scu) * scl: if w < 0 or w > 1 then imgPixel += 1: continue for
                n = (uva*u + uvb*v + uvc*w)/3
                *imgPixel = uvToColor(n.x, n.y)
                imgPixel += 1
            next x
            imgRowStart += imgPitch
        next
        row = start
        imgRowStart = imgPixelDataStart
        for i as integer = y0 to y1-q step q '- remove -q in future - band-aid for crash bug with very low quality
            for y as integer = 0 to q-1
                pixel = row
                imgPixel = imgRowStart
                for j as integer = x0 to x1 step q
                    if *imgPixel <> &hffff00ff then
                        for x as integer = 0 to q-1: *pixel = *imgPixel: pixel += 1: next x
                    else
                        pixel += q
                    end if
                    imgPixel += 1
                next j
                row += pitch
            next y
            imgRowStart += imgPitch
        next i
        screenunlock
        imagedestroy(imgBuffer)
    end if
end sub
sub drawTriSolid(a as Vector2, b as Vector2, c as Vector2, colr as integer)
    dim as double ab, ac, bc
    dim as double abx, acx, bcx
    dim as double bma0, cma0, cmb0
    dim as double bma1, cma1, cmb1
    dim as integer y0, y1, z0, z1
    if a.y > b.y then swap a, b
    if a.y > c.y then swap a, c
    if b.y > c.y then swap b, c
    ab = a.x
    ac = a.x
    bc = b.x
    bma0 = b.x-a.x: cma0 = c.x-a.x: cmb0 = c.x-b.x
    bma1 = b.y-a.y: cma1 = c.y-a.y: cmb1 = c.y-b.y
    abx = bma0/bma1
    acx = cma0/cma1
    bcx = cmb0/cmb1
    y0 = int(a.y): y1 = y0 + int(b.y-a.y)
    z0 = int(b.y): z1 = z0 + int(c.y-b.y)
    for i as integer = y0 to y1
        line (int(ab), i)-(int(ac), i), colr
        ab += abx
        ac += acx
    next i
    ac -= acx
    for i as integer = z0 to z1
        line (int(bc), i)-(int(ac), i), colr
        ac += acx
        bc += bcx
    next i
end sub
sub renderFaceSolid(byref face as Face3, byref mesh as Mesh3, byref camera as CFrame3, byref world as CFrame3)
    dim as Vector2 a, b, c, pixels(ubound(face.vertexIds))
    dim as Vector3 viewNormal, viewVertex(ubound(face.vertexIds))
    dim as Vector3 worldNormal, worldVertex
    dim as integer colr, cr, cg, cb
    dim as double dt, value
    cr = rgb_r(face.colr)
    cg = rgb_g(face.colr)
    cb = rgb_b(face.colr)
    dt = dot(face.normal, normalize(world.vUp + camera.vForward))
    value = 64 * dt
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
    if not mesh.doubleSided then
        viewNormal = normalize(worldToView(face.normal, camera, true))
        if dot(viewVertex(0), viewNormal) > 0 then
            exit sub
        end if
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
        drawTriSolid(_
            Vector2(a.x, a.y),_
            Vector2(b.x, b.y),_
            Vector2(c.x, c.y),_
            colr _
        )
        window (WINDOW_X0, WINDOW_Y0)-(WINDOW_X1, WINDOW_Y1)
    next i
end sub
sub renderFaceTextured(byref face as Face3, byref mesh as Mesh3, byref camera as CFrame3, byref world as CFrame3)
    dim as Vector2 a, b, c, pixels(ubound(face.vertexIds)), uvs(ubound(face.vertexIds))
    dim as Vector3 viewNormal, viewVertex(ubound(face.vertexIds))
    dim as Vector3 worldNormal, worldVertex
    dim as integer value, colr, cr, cg, cb
    dim as double dt
    cr = rgb_r(face.colr)
    cg = rgb_g(face.colr)
    cb = rgb_b(face.colr)
    dt = dot(face.normal, World.vUp)
    dt = dot(face.normal, normalize(camera.position - face.position))
    value = 64 * (-0.5 + dt)
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
    if not mesh.doubleSided then
        viewNormal = normalize(worldToView(face.normal, camera, true))
        if dot(viewVertex(0), viewNormal) > 0 then
            exit sub
        end if
    end if
    for i as integer = 0 to ubound(viewVertex)
        pixels(i) = viewToScreen(viewVertex(i))
        uvs(i) = mesh.getUV(face.uvIds(i))
    next i
    for i as integer = 1 to ubound(pixels) - 1
        a = pixels(0)
        b = pixels(i)
        c = pixels(i+1)
        a.x = pmap(a.x, 0): a.y = pmap(a.y, 1)
        b.x = pmap(b.x, 0): b.y = pmap(b.y, 1)
        c.x = pmap(c.x, 0): c.y = pmap(c.y, 1)
        window
        if QUALITY = 0 then
            drawTexturedTri(_
                Vector2(a.x, a.y),_
                Vector2(b.x, b.y),_
                Vector2(c.x, c.y),_
                uvs(0), uvs(i), uvs(i+1),_
                @uvToColor _
            )
        else
            drawTexturedTriLowQ(_
                Vector2(a.x, a.y),_
                Vector2(b.x, b.y),_
                Vector2(c.x, c.y),_
                uvs(0), uvs(i), uvs(i+1),_
                @uvToColor,_
                QUALITY _
            )
        end if
        window (WINDOW_X0, WINDOW_Y0)-(WINDOW_X1, WINDOW_Y1)
    next i
end sub
sub renderFaceWireframe(byref face as Face3, byref mesh as Mesh3, byref camera as CFrame3, byref world as CFrame3, colr as integer = &hd0d0d0, style as integer = &hffff)
    dim as Vector2 a, b, c, pixels(ubound(face.vertexIds))
    dim as Vector3 viewVertex(ubound(face.vertexIds))
    dim as Vector3 worldVertex
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
    for i as integer = 0 to ubound(pixels)-1
        a = pixels(i)
        b = pixels(i+1)
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
    dim as double dt
    if faceId >= 0 then
        face = mesh.getFace(faceId)
        dt = dot(face.normal, camera.position - face.position)
        if dt > 0 then
            renderBspFaces node->behind, mesh, camera, world
            renderBspFaces node->infront, mesh, camera, world
        else
            renderBspFaces node->infront, mesh, camera, world
            renderBspFaces node->behind, mesh, camera, world
        end if
        select case RENDER_MODE
            case RenderMode.Solid   : renderFaceSolid face, mesh, camera, world
            case RenderMode.Textured: renderFaceTextured face, mesh, camera, world
            case RenderMode.Wireframe
                if dt > 0 then
                    renderFaceWireframe face, mesh, camera, world
                else
                    renderFaceWireframe face, mesh, camera, world, , &hc0c0
                end if
        end select
    end if
end sub
sub renderObjects(objects() as Object3, byref camera as CFrame3, byref world as CFrame3)
    dim as Mesh3 mesh
    dim as Object3 o
    dim as double dist
    for i as integer = 0 to ubound(objects)
        o = objects(i)
        o.transform()
        if AUTO_QUALITY = AutoQuality.DistanceBased then
            dist = (o.position - camera.position).length
            select case dist
                case is < exp(0): QUALITY = 5
                case is < exp(1): QUALITY = 4
                case is < exp(2): QUALITY = 3
                case is < exp(3): QUALITY = 2
                case is < exp(4): QUALITY = 1
                case else: QUALITY = 0
            end select
            QUALITY = iif(QUALITY < MIN_QUALITY, MIN_QUALITY, iif(QUALITY > MAX_QUALITY, MAX_QUALITY, QUALITY))
        end if
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
        a = normalize(m)*fr*1.15
        b = normalize(a).rotatedLeft()*sz
        line(a.x, a.y)-step(b.x, b.y), colr
        b = normalize(b).rotatedRight().rotated(rad(-30))*sz*2
        line -step(b.x, b.y), colr
        b = normalize(b).rotated(rad(-120))*sz*2
        line -step(b.x, b.y), colr
        b = normalize(b).rotated(rad(-120))*sz
        line -step(b.x, b.y), colr
    end if

    '- draw mouse cursor
    dim as ulong ants = &b11000011110000111100001111000011 shr int(frac(timer*1.5)*16)
    a = m
    sz = 0.076
    b = Vector2(rad(-75))*sz
    line(a.x, a.y)-step(b.x, b.y), &hf0f0f0, , ants
    b = b.rotated(rad(105))*0.8
    line -step(b.x, b.y), &hf0f0f0, , ants
    line -(a.x, a.y), &hf0f0f0, , ants
end sub

'=======================================================================
'= START
'=======================================================================
randomize
window (WINDOW_X0, WINDOW_Y0)-(WINDOW_X1, WINDOW_Y1)

dim as Mouse2 mouse
mouse.hide()
mouse.setMode(Mouse2Mode.Viewport)

dim as CFrame3 cam, camera, world
dim as Object3 objectCollection(any)
'dim as Object3 ptr spaceship = object_collection_add("mesh/spaceship-tris.obj", objectCollection())
'dim as Object3 ptr spaceship = object_collection_add("mesh/spaceship-quads.obj", objectCollection())
dim as Object3 ptr spaceship = object_collection_add("mesh/spaceship3.obj", objectCollection())
'dim as Object3 ptr spaceship = object_collection_add("mesh/spaceship3-tris.obj", objectCollection())
dim as Object3 ptr controlObject, focusObject

'camera.orientation *= Vector3(0, rad(180), 0)

spaceship->mesh.doubleSided = true
spaceship->mesh.paintFaces(&hc0c0c0)

camera.position = spaceship->position + normalize(Vector3(-1+2*rnd,rnd,-1+2*rnd)) * (15+30*rnd)
camera = camera.lookAt(spaceship->position)

controlObject = spaceship
focusObject = spaceship

dim as double rotateSpeed    = 1
dim as double translateSpeed = 1
dim as double speedFactor    = 10
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

dim as CFrame3 ptr statsframe = @camera
dim as CFrame3 ptr orbitTarget

dim as integer keyWait = -1

enum NavigationMode
    Fly
    FollowClose
    OrbitTarget
    FollowNear
    FollowMid
    FollowFar
    FollowVeryFar
end enum
dim as integer navMode = NavigationMode.OrbitTarget
orbitTarget = focusObject
angular = normalize(Vector3(rnd,rnd,rnd))/10
targetAngular = angular

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

    if navMode = NavigationMode.Fly then
        statsframe = @camera
    else
        statsframe = focusObject
    end if

    mouse.update
    frameCount += 1
    if timer - fpsTimeStart >= 1 then
        fps = frameCount
        fpsTimeStart = timer
        frameCount = 0
    end if

    if RENDER_MODE <> RenderMode.None and navMode <> NavigationMode.OrbitTarget then
        printStringBlock( 1, 1, getOrientationStats(*statsframe), "ORIENTATION", "_", "")
        printStringBlock(10, 1,    getLocationStats(*statsframe),    "LOCATION", "_", "")

        
        if navMode <> NavigationMode.OrbitTarget then
            renderUI mouse
        end if
        

        dim as integer row = 15
        dim as string buffer = space(21)
        select case RENDER_MODE
            case RenderMode.Solid    : mid(buffer, 2) = "Solid"
            case RenderMode.Textured : mid(buffer, 2) = "Texture"
            case RenderMode.Wireframe: mid(buffer, 2) = "Wireframe"
        end select
        printStringBlock(row, 1, buffer, "RENDER MODE", "_", "")

        if RENDER_MODE = RenderMode.Textured then
            buffer = space(21)
            mid(buffer,  2) = str(QUALITY+1)
            mid(buffer,  4) = iif(AUTO_QUALITY = AutoQuality.DistanceBased, "=automatic=", "=manual=")
            row += 5
            printStringBlock(row, 1, buffer, "QUALITY", "_", "")
        end if

        buffer = space(21)
        mid(buffer, 1) = format_decimal(speedFactor, 1)
        row += 5
        printStringBlock(row, 1, buffer, "SPEED FACTOR", "_", "")

        buffer = space(21)
        mid(buffer, 1) = format_decimal(fps, 1)
        row += 5
        printStringBlock(row, 1, buffer, "FPS", "_", "")
    end if
    
    screencopy 1, 0
    dim as double deltaTime = timer - frameTimeStart
    dim as double deltaRotate = deltaTime * rotateSpeed
    dim as double deltaTranslate = deltaTime * translateSpeed

    frameTimeStart = timer

    if multikey(SC_PAGEUP  ) or multikey(SC_PLUS) or multikey(SC_EQUALS) then
        speedFactor = clamp(speedFactor + 3*deltaTime, 1, 50)
    elseif multikey(SC_PAGEDOWN) or multikey(SC_MINUS) then
        speedFactor = clamp(speedFactor - 3*deltaTime, 1, 50)
    end if
    speedFactor = clamp(speedFactor + 2*mouse.wheelDelta, 1, 50)
    deltaRotate = deltaTime * rotateSpeed
    deltaTranslate = deltaTime * speedFactor

    if multikey(SC_BACKSPACE) then
        lookBackwards = true
    else
        lookBackwards = false
    end if

    lookAt = 0
    if multikey(SC_CONTROL) <> 0 or mouse.middleDown then
        lookAt = @focus.position
    end if

    if RENDER_MODE = RenderMode.Textured then
        if multikey(SC_F1) then QUALITY = 0: AUTO_QUALITY = AutoQuality.None
        if multikey(SC_F2) then QUALITY = 1: AUTO_QUALITY = AutoQuality.None
        if multikey(SC_F3) then QUALITY = 2: AUTO_QUALITY = AutoQuality.None
        if multikey(SC_F4) then QUALITY = 3: AUTO_QUALITY = AutoQuality.None
        if multikey(SC_F5) then QUALITY = 4: AUTO_QUALITY = AutoQuality.None
        if multikey(SC_F6) then QUALITY = 5: AUTO_QUALITY = AutoQuality.None
    end if

    if multikey(SC_TAB) and keyWait = -1 then
        keyWait = SC_TAB
        select case RENDER_MODE
            case RenderMode.None
                RENDER_MODE = RenderMode.Wireframe
            case RenderMode.Solid
                RENDER_MODE = RenderMode.Textured
                AUTO_QUALITY = AutoQuality.DistanceBased
            case RenderMode.Textured
                RENDER_MODE = RenderMode.None
            case RenderMode.Wireframe
                RENDER_MODE = RenderMode.Solid
        end select
    elseif not multikey(SC_TAB) and keyWait = SC_TAB then
        keyWait = -1
    end if

    if multikey(SC_1) then
        navMode = NavigationMode.Fly
    end if
    if multikey(SC_3) then
        navMode = NavigationMode.OrbitTarget
        angular = normalize(Vector3(rnd,rnd,rnd))/10
        targetAngular = angular
    end if
    
    if multikey(SC_2) and keyWait = -1 then
        keyWait = SC_2
        select case navMode
            case NavigationMode.FollowVeryFar, NavigationMode.Fly
                navMode = NavigationMode.FollowClose
            case NavigationMode.FollowClose
                navMode = NavigationMode.FollowNear
            case NavigationMode.FollowNear
                navMode = NavigationMode.FollowMid
            case NavigationMode.FollowMid
                navMode = NavigationMode.FollowFar
            case NavigationMode.FollowFar
                navMode = NavigationMode.FollowVeryFar
        end select
    elseif not multikey(SC_2) and keyWait = SC_2 then
        keyWait = -1
    end if

    select case navMode
        case NavigationMode.FollowClose  : cameraFollowDistance = Vector3(0, 2, 8)
        case NavigationMode.FollowNear   : cameraFollowDistance = Vector3(0, 3, 12)
        case NavigationMode.FollowMid    : cameraFollowDistance = Vector3(0, 6, 24)
        case NavigationMode.FollowFar    : cameraFollowDistance = Vector3(0, 15, 36)
        case NavigationMode.FollowVeryFar: cameraFollowDistance = Vector3(0, 24, 96)
    end select

    targetMovement = Vector3(0, 0, 0)
    targetRotation = Vector3(0, 0, 0)

    select case navMode
    case NavigationMode.Fly
        dim as double mx, my
        mx = mouse.x
        my = mouse.y * SCREEN_ASPECT_X
        mx *= 1.5
        my *= 1.5
        if mouse.leftDown then
            targetRotation.y  = mx
            targetRotation.x -= my
        elseif mouse.rightDown then
            dim as Vector2 m = type(mx, my)
            m = rotate(m, atan2(targetRotation.z, targetRotation.x))
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
            targetMovement = normalize(dot(camera.orientation.matrix(), targetMovement))
        end if
        'if targetRotation.length > 1 then
        '    targetRotation = targetRotation.unit
        'end if
        movement = lerpexp(movement, targetMovement, deltaTime)
        rotation = lerpexp(rotation, targetRotation, deltaTime)
        camera += movement * deltaTranslate
                
        camera.orientation *= rotation * deltaRotate
        if lookAt then
            camera = camera.lookAt(*lookAt)
        end if
    case NavigationMode.OrbitTarget
        camera = camera.lookAt(focus, focus.Orientation.vUp)
        camera.position += cross(world.vUp, normalize(focus.position - camera.position)) * deltaTime * 3
    case else
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

        targetVelocity = lerpexp(targetVelocity, dot(focus.orientation.matrix(), targetMovement*10), deltaTime/10)
        targetAngular = lerpexp(targetAngular, targetRotation*2, deltaTime/15)
        
    end select

    focus.velocity = lerpexp(focus.velocity, targetVelocity, deltaTime)
    focus.position += focus.velocity * deltaTranslate
    angular = lerpexp(angular, targetAngular, deltaTime)
    focus.orientation *= angular * deltaRotate
    'focus.orientation *= Vector3(0, .1, 0) * deltaRotate
    *focusObject = focus

    if navMode <> NavigationMode.Fly and navMode <> NavigationMode.OrbitTarget then
        targetCamera = (_
              focus _
            - focus.vForward _
            * iif(lookBackwards, -cameraFollowDistance.z - 3, cameraFollowDistance.z) _
            + focus.vUp * cameraFollowDistance.y _
        )
        camera = lerpexp(camera, targetCamera, deltaTime * 3)
    end if
wend
mouse.Show()
end
