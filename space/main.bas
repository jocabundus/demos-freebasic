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

#cmdline "-i inc/"
#cmdline "-i src/inc/"

#cmdline "-b src/mouse2.bas"
#cmdline "-b src/vector2.bas"
#cmdline "-b src/vector3.bas"
#cmdline "-b src/orientation3.bas"
#cmdline "-b src/cframe3.bas"
#cmdline "-b src/face3.bas"
#cmdline "-b src/mesh3.bas"
#cmdline "-b src/object3.bas"
#cmdline "-b src/colorspace.bas"
#cmdline "-b src/particle.bas"
#cmdline "-b src/helpers.bas"

#include once "fbgfx.bi"
#include once "mouse2.bi"
#include once "vector2.bi"
#include once "vector3.bi"
#include once "orientation3.bi"
#include once "cframe3.bi"
#include once "face3.bi"
#include once "mesh3.bi"
#include once "object3.bi"
#include once "colorspace.bi"
#include once "particle.bi"
#include once "helpers.bi"
#include once "defines.bi"
#include once "main.bi"
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
dim shared as ScreenMetaType ScreenMeta
dim shared as integer RENDER_MODE = RenderMode.Textured
dim shared as integer QUALITY = 3, MIN_QUALITY = 0, MAX_QUALITY = 5 '- 0 is best
dim shared as integer AUTO_QUALITY = AutoQuality.DistanceBased

dim as Mouse2 mouse
dim as Object3 objects(any)
dim as ParticleType particles(NUM_PARTICLES-1)

'------------------------------------------------------------------------------
' THY HOLY TRINITY
'------------------------------------------------------------------------------
    init     mouse, objects(), particles()
    main     mouse, objects(), particles()
    shutdown mouse
'------------------------------------------------------------------------------
'------------------------------------------------------------------------------
'------------------------------------------------------------------------------
end

sub init(byref mouse as Mouse2, objects() as Object3, particles() as ParticleType)
    randomize
    initScreen()
    mouse.hide()
    mouse.setMode(Mouse2Mode.Viewport)
    dim byref as Object3 anchor    = addObject(   "anchor", objects())
    dim byref as Object3 asteroid  = addObject( "asteroid", objects(), "data/mesh/rocks.obj")
    anchor.position = Vector3(1, 1, 1) * 2 * pi
    asteroid.callback = @animateAsteroid
    dim as Image32 image = type(64, 64)
    image.load("data/mesh/textures/asteroid64.bmp")
    asteroid.mesh.texture = image.buffer
    dim byref as Object3 spaceship = addObject("spaceship", objects(), "data/mesh/spaceship3.obj")
    spaceship.mesh.doubleSided = true
    spaceship.mesh.paintFaces(&hc0c0c0)
    dim as Image32 image2 = type(64, 64)
    dim as double a, b, u, v
    dim as long colr, value
    dim as long ubr, ubg, ubb
    for y as double = 0 to 63
        for x as double = 0 to 63
            a = x / 64
            b = y / 64
            u = sin(2*pi*a)
            v = cos(2*pi*a)
            colr  = ColorSpace2.SampleColor(Vector2(u, v)*(a+b), 3)
            value = -32 + (int(x) xor int(y))*2
            ubr = clamp(rgb_r(colr) + value, 0, 255)
            ubg = clamp(rgb_g(colr) + value, 0, 255)
            ubb = clamp(rgb_b(colr) + value, 0, 255)
            colr = rgb(ubr, ubg, ubb)
            image2.plotPixel(x, y, colr)
        next x
    next y
    spaceship.mesh.texture = image2.buffer
    for i as integer = 0 to ubound(particles)
        dim as ParticleType p = type(_
            Vector3(_
                FIELD_SIZE/2 * rnd*sin(2*pi*rnd),_
                FIELD_SIZE/2 * rnd*sin(2*pi*rnd),_
                FIELD_SIZE/2 * rnd*sin(2*pi*rnd) _
            ),_
            ColorSpace2.SampleColor(2*pi*rnd, rnd, 2)_
        )
        particles(i) = p
    next i
end sub

sub shutdown(mouse as Mouse2)
    mouse.Show()
end sub

sub initScreen()
    ScreenMeta.readSettings()
    ScreenMeta.flags = GFX_FULLSCREEN
    ScreenMeta.pages = 2
    if ScreenMeta.applySettings() then
        print "Failed to initialize graphics screen"
        sleep
        end
    end if
    ScreenMeta.readSettings()
    dim as double ratiow = ScreenMeta.ratiow
    dim as double ratioh = ScreenMeta.ratioh
    ScreenMeta.setView(-ratiow, 1, ratiow, -1)
    ScreenMeta.applyView()
    screenset 1, 0
end sub

'=======================================================================
'= WORLD TRANSFORM
'=======================================================================
function localToWorld overload(position as vector3, world as CFrame3) as Vector3
    return Vector3(_
        dot(world.rightward, position),_
        dot(world.upward   , position),_
        dot(world.forward  , position) _
    )
end function

'=======================================================================
'= VIEW TRANSFORM
'=======================================================================
function worldToView(position as vector3, camera as CFrame3, skipTranslation as boolean = false) as Vector3
    if not skipTranslation then
        position -= camera.position
    end if
    return Vector3(_
        dot(camera.rightward, position),_
        dot(camera.upward   , position),_
        dot(camera.forward  , position) _
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

sub drawTexturedTri(a as Vector2, b as Vector2, c as Vector2, uva as Vector2, uvb as Vector2, uvc as Vector2, texture as Image32)
    dim as _long_ bpp = ScreenMeta.bpp, pitch = ScreenMeta.pitch
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
    if toplft.x >= ScreenMeta.w then exit sub
    if toplft.y >= ScreenMeta.h then exit sub
    if btmrgt.x < 0 then exit sub
    if btmrgt.y < 0 then exit sub
    if toplft.x < 0 then toplft.x = 0
    if toplft.y < 0 then toplft.y = 0
    if btmrgt.x >= ScreenMeta.w then btmrgt.x = ScreenMeta.w-1
    if btmrgt.y >= ScreenMeta.h then btmrgt.y = ScreenMeta.h-1
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
                *pixel = texture.getPixel(u, v)
                pixel += 1
            next x
            rowStart += pitch
        next
        screenunlock
    end if
end sub
sub drawTexturedTriLowQ(a as Vector2, b as Vector2, c as Vector2, uva as Vector2, uvb as Vector2, uvc as Vector2, texture as Image32, quality as integer = 0)
    dim as _long_ bpp = ScreenMeta.bpp, pitch = ScreenMeta.pitch
    dim as _long_ imgPitch, imgBpp, imgw, imgh
    dim as any ptr buffer = screenptr, row, start
    dim as any ptr imgBuffer, imgRowStart, imgPixelStart
    dim as ulong ptr pixel, imgPixel
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
    if toplft.x >= ScreenMeta.w then exit sub
    if toplft.y >= ScreenMeta.h then exit sub
    if btmrgt.x < 0 then exit sub
    if btmrgt.y < 0 then exit sub
    if toplft.x < 0 then toplft.x = 0
    if toplft.y < 0 then toplft.y = 0
    if btmrgt.x >= ScreenMeta.w then btmrgt.x = ScreenMeta.w-1
    if btmrgt.y >= ScreenMeta.h then btmrgt.y = ScreenMeta.h-1
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
    imageinfo imgBuffer, imgw, imgh, imgBpp, imgPitch, imgPixelStart
    start = buffer + y0*pitch + x0*bpp
    if buffer <> 0 and imgBuffer <> 0 then
        screenlock
        imgRowStart = imgPixelStart
        for y as integer = y0 to y1 step q
            imgPixel = imgRowStart
            for x as integer = x0 to x1 step q
                p = Vector2(x, y)
                u = 1-dot(p-a, sau) * sal: if u < 0 or u > 1 then imgPixel += 1: continue for
                v = 1-dot(p-b, sbu) * sbl: if v < 0 or v > 1 then imgPixel += 1: continue for
                w = 1-dot(p-c, scu) * scl: if w < 0 or w > 1 then imgPixel += 1: continue for
                n = (uva*u + uvb*v + uvc*w)/3
                *imgPixel = texture.getPixel(u, v)
                imgPixel += 1
            next x
            imgRowStart += imgPitch
        next
        row = start
        imgRowStart = imgPixelStart
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
    cr = rgb_r(face.colr)
    cg = rgb_g(face.colr)
    cb = rgb_b(face.colr)
    dt = dot(face.normal, world.upward)
    value = 80 * dt
    colr = rgb(_
        clamp(cr+value, 0, 255),_
        clamp(cg+value, 0, 255),_
        clamp(cb+value, 0, 255) _
    )
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
        ScreenMeta.resetView()
        drawTriSolid(_
            Vector2(a.x, a.y),_
            Vector2(b.x, b.y),_
            Vector2(c.x, c.y),_
            colr _
        )
        ScreenMeta.applyView()
    next i
end sub
sub renderFaceTextured(byref face as Face3, byref mesh as Mesh3, byref camera as CFrame3, byref world as CFrame3)
    dim as Vector2 a, b, c, pixels(ubound(face.vertexIds)), uvs(ubound(face.vertexIds))
    dim as Vector3 viewNormal, viewVertex(ubound(face.vertexIds))
    dim as Vector3 worldNormal, worldVertex
    dim as Image32 texture, shadedTexture
    dim as any ptr srcRow, dstRow
    dim as ulong ptr src, dst
    dim as ulong colr
    dim as long ubr, ubg, ubb
    dim as long value
    dim as double dt
    
    for i as integer = 0 to ubound(face.vertexIds)
        worldVertex   = mesh.getVertex(face.vertexIds(i))
        viewVertex(i) = worldToView(worldVertex, camera)
        if viewVertex(i).z <= 0 then '- closer allow because draw sub clips
            exit sub
        end if
    next i
    
    if not mesh.doubleSided then
        viewNormal = normalize(worldToView(face.normal, camera, true))
        if dot(viewVertex(0), viewNormal) > 0 then
            exit sub
        end if
    end if
    
    dt = dot(face.normal, world.upward)
    value = 80 * (-0.5 + dt)
    texture.readInfo(mesh.texture)
    shadedTexture = type(texture.w, texture.h)
    srcRow = texture.pixdata
    dstRow = shadedTexture.pixdata
    for y as integer = 0 to texture.h-1
        src = srcRow
        dst = dstRow
        for x as integer = 0 to texture.w-1
            colr = *src
            ubr = rgb_r(colr)
            ubg = rgb_g(colr)
            ubb = rgb_b(colr)
            colr = rgb(_
                clamp(ubr+value, 0, 255),_
                clamp(ubg+value, 0, 255),_
                clamp(ubb+value, 0, 255) _
            )
            *dst = colr
            src += 1
            dst += 1
        next x
        srcRow  += texture.pitch
        dstRow += shadedTexture.pitch
    next y
    
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
        ScreenMeta.resetView()
        if QUALITY = 0 then
            drawTexturedTri(_
                Vector2(a.x, a.y),_
                Vector2(b.x, b.y),_
                Vector2(c.x, c.y),_
                uvs(0), uvs(i), uvs(i+1),_
                shadedTexture _
            )
        else
            drawTexturedTriLowQ(_
                Vector2(a.x, a.y),_
                Vector2(b.x, b.y),_
                Vector2(c.x, c.y),_
                uvs(0), uvs(i), uvs(i+1),_
                shadedTexture,_
                QUALITY _
            )
        end if
        ScreenMeta.applyView()
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
            case RenderMode.Textured
                if ubound(face.uvIds) >= 0 and mesh.texture <> 0 then
                    renderFaceTextured face, mesh, camera, world
                else
                    renderFaceSolid face, mesh, camera, world
                end if
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
    dim as Object3 o
    dim as Mesh3 mesh
    dim as Face3 face
    dim as Vector3 v
    dim as double dist
    for i as integer = 0 to ubound(objects)
        o = objects(i).toWorld()
        mesh = o.mesh
        if AUTO_QUALITY = AutoQuality.DistanceBased then
            dist = (o.cframe.position - camera.position).length
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
        renderBspFaces mesh.bspRoot, mesh, camera, world
    next i
end sub
sub renderParticles(particles() as ParticleType, byref camera as CFrame3)
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
sub animateObjects(objects() as Object3, byref camera as CFrame3, byref world as CFrame3, deltaTime as double)
    for i as integer = 0 to ubound(objects)
        dim byref o as Object3 = objects(i)
        o.cframe *= CFrame3(o.linear * deltaTime, o.angular * deltaTime)
        if o.callback then
            o.callback(o, camera, world, deltaTime)
        end if
    next i
end sub

sub animateAsteroid(byref o as Object3, byref camera as CFrame3, byref world as CFrame3, deltaTime as double)
    dim as CFrame3 cf
    dim as Vector3 origin = Vector3.Zero
    if o.position = origin then
        o.angular = Vector3.Randomized() * 0.5
        o.position = Vector3.Randomized() * (20 + 30*rnd)
    else
        cf.position = o.position
        cf.lookAt(origin, world.upward)
        o.cframe.position += normalize(cf.rightward - cf.upward) * deltaTime
    end if
end sub

'==============================================================================
'= START
'==============================================================================
sub main(byref mouse as Mouse2, objects() as Object3, particles() as ParticleType)

    dim as CFrame3 world
    dim as CFrame3 camera
    dim as double  deltaTime, frameStartTime
    dim as integer keyWait = -1
    dim as integer navMode = NavigationMode.Orbit
    dim as boolean resetMode = true
    
    dim byref as Object3 anchor    = getObjectBySid("anchor", objects())
    dim byref as Object3 spaceship = getObjectBySid("spaceship", objects())
    dim byref as Object3 asteroid  = getObjectBySid("asteroid", objects())
    dim byref as Object3 active    = spaceship

    frameStartTime = timer
    while not multikey(SC_ESCAPE)

        select case navMode
            case NavigationMode.Fly   : handleFlyInput    active, mouse, camera, world, deltaTime, resetMode
            case NavigationMode.Follow: handleFollowInput active, mouse, camera, world, deltaTime, resetMode
            case NavigationMode.Orbit : handleOrbitInput  active, mouse, camera, world, deltaTime, resetMode
        end select
        resetMode = false

        animateObjects objects(), camera, world, deltaTime
        renderFrame    camera, world, objects(), particles()
        renderUI       mouse, camera, world, navMode, deltaTime
        printDebugInfo active.cframe
        
        '~ for i as integer = 0 to ubound(objects)
            '~ dim as Object3 o = objects(i)
            '~ dim as Vector3 p, v(2)
            '~ dim as Vector2 a, b
            '~ p = worldToView(o.position, camera)
            '~ if p.z > 1 then
                '~ v(0) = worldToView(o.position + o.rightward * pi, camera)
                '~ v(1) = worldToView(o.position + o.upward    * pi, camera)
                '~ v(2) = worldToView(o.position + o.forward   * pi, camera)
                '~ a = viewToScreen(p)
                '~ for j as integer = 0 to ubound(v)
                    '~ b = viewToScreen(v(j))
                    '~ line (a.x, a.y)-(b.x, b.y), iif(j = 0, &hff0000, iif(j = 1, &h00ff00, &h0000ff)), , &hcccc
                    '~ draw string (b.x, b.y), iif(j = 0, "X", iif(j = 1, "Y", "Z"))
                '~ next j
                '~ draw string (a.x, a.y), o.sid
            '~ end if
        '~ next i
        
        screencopy 1, 0

        deltaTime      = timer - frameStartTime
        frameStartTime = timer

        mouse.update

        if RENDER_MODE = RenderMode.Textured then
            if multikey(SC_F1) then QUALITY = 0: AUTO_QUALITY = AutoQuality.None
            if multikey(SC_F2) then QUALITY = 1: AUTO_QUALITY = AutoQuality.None
            if multikey(SC_F3) then QUALITY = 2: AUTO_QUALITY = AutoQuality.None
            if multikey(SC_F4) then QUALITY = 3: AUTO_QUALITY = AutoQuality.None
            if multikey(SC_F5) then QUALITY = 4: AUTO_QUALITY = AutoQuality.None
            if multikey(SC_F6) then QUALITY = 5: AUTO_QUALITY = AutoQuality.None
        end if

        if multikey(SC_O) then active.cframe = CFrame3()
        if multikey(SC_X) then active.cframe.orientation = Orientation3() * Vector3(pi/2, 0, 0)
        if multikey(SC_Y) then active.cframe.orientation = Orientation3() * Vector3(0, pi/2, 0)
        if multikey(SC_Z) then active.cframe.orientation = Orientation3() * Vector3(0, 0, pi/2)

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

        keydown(SC_1, keyWait, navMode = NavigationMode.Fly   : @active = @anchor   : resetMode = true)
        keydown(SC_2, keyWait, navMode = NavigationMode.Follow: @active = @spaceship: resetMode = true)
        keydown(SC_3, keyWait, navMode = NavigationMode.Orbit : @active = @spaceship: resetMode = true)

        if multikey(SC_CONTROL) <> 0 or mouse.middleDown then
            camera.lookAt(spaceship.position, spaceship.upward)
        end if
    wend
end sub

sub renderFrame(byref camera as CFrame3, byref world as CFrame3, objects() as Object3, particles() as ParticleType)
    dim as CFrame3 cam = camera
    if multikey(SC_BACKSPACE) then cam.orientation *= Vector3(0, rad(180), 0)
    cls
    renderParticles(particles(), cam)
    renderObjects(objects(), cam, world)
end sub

sub renderUI(byref mouse as Mouse2, byref camera as CFrame3, byref world as CFrame3, navMode as NavigationMode, deltaTime as double)
    if navMode = NavigationMode.Fly then
        drawReticle mouse
    end if
    drawMouseCursor mouse
end sub

sub drawReticle(byref mouse as Mouse2, reticleColor as integer = &h808080, arrowColor as integer = &hd0b000)
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
end sub

sub drawMouseCursor(byref mouse as Mouse2)
    dim as ulong ants = &b11000011110000111100001111000011 shr int(frac(timer*1.5)*16)
    dim as Vector2 m = type(mouse.x, mouse.y)
    dim as Vector2 a = m, b
    dim as double r = 0.076
    b = Vector2(rad(-75))*r
    line(a.x, a.y)-step(b.x, b.y), &hf0f0f0, , ants
    b = b.rotated(rad(105))*0.8
    line -step(b.x, b.y), &hf0f0f0, , ants
    line -(a.x, a.y), &hf0f0f0, , ants
end sub

sub fpsUpdate (byref fps as integer)
    static as double fpsResetTime = -1
    static as integer frameCount
    frameCount += 1
    if fpsResetTime = -1 then
        fpsResetTime = timer + 1
    elseif timer > fpsResetTime then
        fpsResetTime = timer + 1
        fps = frameCount
        frameCount = 0
    end if
end sub


sub printDebugInfo(byval cframe as CFrame3)

    printStringBlock( 1, 1, getOrientationStats(cframe), "ORIENTATION", "_", "")
    printStringBlock(10, 1,    getLocationStats(cframe),    "LOCATION", "_", "")

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

    '~ buffer = space(21)
    '~ mid(buffer, 1) = format_decimal(speedFactor, 1)
    '~ row += 5
    '~ printStringBlock(row, 1, buffer, "SPEED FACTOR", "_", "")

    static as integer fps
    fpsUpdate fps
    buffer = space(21)
    mid(buffer, 1) = format_decimal(fps, 1)
    row += 5
    printStringBlock(row, 1, buffer, "FPS", "_", "")
end sub

sub handleFlyInput(byref active as Object3, byref mouse as Mouse2, byref camera as CFrame3, byref world as CFrame3, deltaTime as double, resetMode as boolean = false)

    dim as Vector3 angularGoal, linearGoal
    dim as double mx, my
    
    if resetMode then
        active.cframe = camera
    end if

    mx = mouse.x
    my = mouse.y * ScreenMeta.ratiow
    mx *= 1.5
    my *= 1.5

    if mouse.leftDown then
        angularGoal.y  = mx
        angularGoal.x -= my
    elseif mouse.rightDown then
        dim as Vector2 m = type(mx, my)
        m = rotate(m, atan2(angularGoal.z, angularGoal.x))
        angularGoal.x -= my
        angularGoal.z -= mx
    end if

    if multikey(SC_D     ) then linearGoal.x =  1
    if multikey(SC_A     ) then linearGoal.x = -1
    if multikey(SC_SPACE ) then linearGoal.y =  1
    if multikey(SC_LSHIFT) then linearGoal.y = -1
    if multikey(SC_W     ) then linearGoal.z =  1
    if multikey(SC_S     ) then linearGoal.z = -1

    if multikey(SC_UP   ) then angularGoal.x =  1
    if multikey(SC_DOWN ) then angularGoal.x = -1
    if multikey(SC_RIGHT) then angularGoal.y =  1
    if multikey(SC_LEFT ) then angularGoal.y = -1
    if multikey(SC_E    ) then angularGoal.z =  1
    if multikey(SC_Q    ) then angularGoal.z = -1

    if linearGoal.length > 0 then
        linearGoal = normalize(dot(camera.orientation.matrix(), linearGoal)) * 15
    end if
    
    active.linear  = lerpexp(active.linear, linearGoal, deltaTime)
    active.angular = lerpexp(active.angular, angularGoal, deltaTime)
    camera = active.cframe
end sub

sub handleFollowInput(byref active as Object3, byref mouse as Mouse2, byref camera as CFrame3, byref world as CFrame3, deltaTime as double, resetMode as boolean = false)

    dim as Vector3 angularGoal, linearGoal
    
    static as integer keyWait = -1
    static as Vector3 distances(4) = {_
        type(0,  2,  8),_
        type(0,  3, 12),_
        type(0,  6, 24),_
        type(0, 15, 36),_
        type(0, 24, 96)_
    }
    static as integer distanceId = 0

    if resetMode then
        distanceId = 0
    end if

    if multikey(SC_2) and keyWait = -1 then
        keyWait = SC_2
        distanceId += 1
        if distanceId > ubound(distances) then
            distanceId = lbound(distances)
        end if
    elseif not multikey(SC_2) and keyWait = SC_2 then
        keyWait = -1
    end if

    if multikey(SC_D     ) then linearGoal.x =  1
    if multikey(SC_A     ) then linearGoal.x = -1
    if multikey(SC_SPACE ) then linearGoal.y =  1
    if multikey(SC_LSHIFT) then linearGoal.y = -1
    if multikey(SC_W     ) then linearGoal.z =  1
    if multikey(SC_S     ) then linearGoal.z = -1

    if multikey(SC_UP   ) then angularGoal.x =  1
    if multikey(SC_DOWN ) then angularGoal.x = -1
    if multikey(SC_RIGHT) then angularGoal.y =  1
    if multikey(SC_LEFT ) then angularGoal.y = -1
    if multikey(SC_E    ) then angularGoal.z = -1
    if multikey(SC_Q    ) then angularGoal.z =  1

    if linearGoal.length > 0 then
        linearGoal = normalize(_
            active.rightward * linearGoal.x + _
            active.upward    * linearGoal.y + _
            active.forward   * linearGoal.z _
        )
    end if
    
    angularGoal.z += -angularGoal.y

    active.linear  = lerpexp(active.linear, linearGoal*50, deltaTime*0.3)
    active.angular = lerpexp(active.angular, angularGoal*1.5, deltaTime)

    dim as Vector3 followDistance = distances(distanceId)
    dim as CFrame3 cameraGoal = type(_
        active.position - active.forward * followDistance.z + active.upward * followDistance.y,_
        active.orientation)
    camera = lerpexp(camera, cameraGoal, deltaTime*3)
end sub

sub handleOrbitInput(byref active as Object3, byref mouse as Mouse2, byref camera as CFrame3, byref world as CFrame3, deltaTime as double, resetMode as boolean = false)

    static as Vector3 offset, upward

    if resetMode then
        active.angular = Vector3.Randomized()
        offset = Vector3.Randomized() * (15 + 30*rnd)
        camera.position = active.position + active.vectorToLocal(offset)
        upward = Vector3.Randomized()
    end if
    
    camera.lookAt(active.position, upward)
    if mouse.leftDown then
        camera.position += camera.rightward * mouse.dragX * deltaTime * 30
        camera.position += camera.upward * mouse.dragY * deltaTime * 30
    else
        camera.position -= camera.rightward * deltaTime * 3
    end if
    
end sub
