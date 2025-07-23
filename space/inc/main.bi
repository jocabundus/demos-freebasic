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
declare sub printDebugInfo  (byref active as Object3)
declare sub renderFrame     (byref camera as CFrame3, byref world as CFrame3, objects() as Object3, particles() as ParticleType)
declare sub renderUI        (byref mouse as Mouse2, byref camera as CFrame3, byref world as CFrame3, deltaTime as double)
