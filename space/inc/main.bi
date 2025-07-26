' -----------------------------------------------------------------------------
' Copyright (c) 2025 Joe King
' See main file or LICENSE for license and build info.
' -----------------------------------------------------------------------------
#include once "object3.bi"
#include once "cframe3.bi"
#include once "mouse2.bi"

enum AutoQuality
    None
    DistanceBased
    FpsBased
end enum

enum NavigationMode
    Fly
    Follow
    Orbit
end enum

enum RenderMode
    None
    Solid
    Textured
    Wireframe
end enum

type ScreenMetaType
    as _long_  bpp
    as _long_  depth
    as string  driver
    as _long_  flags
    as _long_  pages
    as _long_  pitch
    as _long_  rate
    as double  ratioh
    as double  ratiow
    as double  viewbtm
    as double  viewlft
    as double  viewrgt
    as double  viewtop
    as _long_  w, h
    declare function applySettings() as integer
    declare function applyView() as ScreenMetaType
    declare function readSettings() as ScreenMetaType
    declare function resetView() as ScreenMetaType
    declare function setView(lft as double, top as double, rgt as double, btm as double) as ScreenMetaType
end type
function ScreenMetaType.applySettings() as integer
    return screenres(w, h, depth, pages, flags, rate)
end function
function ScreenMetaType.applyView() as ScreenMetaType
    window (viewlft, viewtop)-(viewrgt, viewbtm)
    return this
end function
function ScreenMetaType.readSettings() as ScreenMetaType
    screeninfo w, h, depth, bpp, pitch, rate, driver
    ratiow = w / h
    ratioh = h / w
    return this
end function
function ScreenMetaType.resetView() as ScreenMetaType
    window
    return this
end function
function ScreenMetaType.setView(lft as double, top as double, rgt as double, btm as double) as ScreenMetaType
    this.viewlft = lft
    this.viewtop = top
    this.viewrgt = rgt
    this.viewbtm = btm
    return this
end function

type Image32
    as any ptr buffer
    as _long_  bpp
    as _long_  pitch
    as any ptr pixdata
    as _long_  w, h
    declare constructor        ()
    declare constructor        (w as _long_, h as _long_)
    declare function create    (w as _long_, h as _long_) as Image32
    declare function getPixel  (x as _long_, y as _long_) as ulong
    declare function getPixel  (x as double, y as double) as ulong
    declare function load      (filename as string) as Image32
    declare function readInfo  (imageBuffer as any ptr) as Image32
    declare function plotPixel (x as _long_, y as _long_, colr as ulong) as Image32
end type
constructor Image32
end constructor
constructor Image32(w as _long_, h as _long_)
    this.create(w, h)
end constructor
function Image32.create(w as _long_, h as _long_) as Image32
    this.buffer = imagecreate(w, h)
    return this.readInfo(this.buffer)
end function
function Image32.getPixel(x as _long_, y as _long_) as ulong
    dim as long ptr pixel = this.pixdata + this.pitch * y + x
    return *pixel
end function
function Image32.getPixel(x as double, y as double) as ulong
    dim as long ptr pixel
    dim as long offset
    offset = this.pitch * int(this.h * y) + this.bpp * int(this.w * x)
    pixel = this.pixdata + offset
    return *pixel
end function
function Image32.readInfo(imageBuffer as any ptr) as Image32
    this.buffer = imageBuffer
    imageinfo this.buffer, this.w, this.h, this.bpp, this.pitch, this.pixdata
    return this
end function
function Image32.load(filename as string) as Image32
    bload filename, this.buffer
    return this
end function
function Image32.plotPixel(x as _long_, y as _long_, colr as ulong) as Image32
    dim as ulong ptr pixel
    dim as integer offset
    offset = this.pitch * y + this.bpp * x
    pixel = this.pixdata + offset
    *pixel = colr
    return this
end function

declare sub init       (byref mouse as Mouse2, objects() as Object3, particles() as ParticleType)
declare sub initScreen ()
declare sub main       (byref mouse as Mouse2, objects() as Object3, particles() as ParticleType)
declare sub shutdown   (byref mouse as Mouse2)

declare sub handleFlyInput    (byref active as Object3, byref mouse as Mouse2, byref camera as CFrame3, byref world as CFrame3, deltaTime as double, resetMode as boolean = false)
declare sub handleFollowInput (byref active as Object3, byref mouse as Mouse2, byref camera as CFrame3, byref world as CFrame3, deltaTime as double, resetMode as boolean = false)
declare sub handleOrbitInput  (byref active as Object3, byref mouse as Mouse2, byref camera as CFrame3, byref world as CFrame3, deltaTime as double, resetMode as boolean = false)

declare sub drawMouseCursor (byref mouse as Mouse2)
declare sub drawReticle     (byref mouse as Mouse2, reticleColor as integer = &h808080, arrowColor as integer = &hd0b000)
declare sub fpsUpdate       (byref fps as integer)
declare sub printDebugInfo  (byval cframe as CFrame3)
declare sub renderFrame     (byref camera as CFrame3, byref world as CFrame3, objects() as Object3, particles() as ParticleType)
declare sub renderUI        (byref mouse as Mouse2, byref camera as CFrame3, byref world as CFrame3, navMode as NavigationMode, deltaTime as double)

declare sub animateAsteroid(byref o as Object3, byref camera as CFrame3, byref world as CFrame3, deltaTime as double)
