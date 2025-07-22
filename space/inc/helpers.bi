' -----------------------------------------------------------------------------
' Copyright (c) 2025 Joe King
' See main file or LICENSE for license and build info.
' -----------------------------------------------------------------------------
#include once "defines.bi"
#include once "object3.bi"
#include once "cframe3.bi"
#include once "vector2.bi"
#include once "vector3.bi"

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

function pickStarColor overload(va as Vector2, variant as integer = 1) as integer
    dim as Vector2 vr, vg, vb
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
        case 3
            dim as PointLight lights(6) = _
            {_
                type(Vector2(4/4*PI)*0, &hffffff, 1),_
                type(Vector2(2/4*PI)*1, &h0000ff, 1),_
                type(Vector2(3/4*PI)*1, &h0000ff, 1),_
                type(Vector2(4/4*PI)*1, &h0000ff, 1),_
                type(Vector2(5/4*PI)*1, &h0000ff, 1),_
                type(Vector2(7/4*PI)*1/2, &hff0000, 1),_
                type(Vector2(1/4*PI)*1, &hffff00, 1) _
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
        case 4
            vr = Vector2(2*PI*1/1)
            vg = Vector2(2*PI*1/3)
            vb = Vector2(2*PI*2/3)
            r = clamp(sin(1-(vr - va).length), 0, 1)
            g = clamp(sin(1-(vg - va).length), 0, 1)
            b = clamp(sin(1-(vb - va).length), 0, 1)
        case 5
            vr = Vector2(2*PI*1/1)
            vg = Vector2(2*PI*1/3)
            vb = Vector2(2*PI*2/3)
            r = clamp(sin(2-(vr - va).length), 0, 1)
            g = clamp(sin(2-(vg - va).length), 0, 1)
            b = clamp(sin(2-(vb - va).length), 0, 1)
    end select
    return rgb(int(255*r), int(255*g), int(255*b))
end function

function pickStarColor(a as double, m as double=1, variant as integer = 1) as integer
    return pickStarColor(Vector2(a) * m, variant)
end function

function getOrientationStats(camera as CFrame3) as string
    dim as string stats(3, 3)
    for i as integer = 0 to 2
        dim as Vector3 o = camera.orientation.matrix(i)
        stats(i, 0) = format_decimal(o.x, 2)
        stats(i, 1) = format_decimal(o.y, 2)
        stats(i, 2) = format_decimal(o.z, 2)
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
    dim as string body = ""
    dim as string row  = space(roww)
    
    mid(row, 1+0*colw) = format_decimal(camera.position.x, 1)
    mid(row, 1+1*colw) = format_decimal(camera.position.y, 1)
    mid(row, 1+2*colw) = format_decimal(camera.position.z, 1)
    
    return body + row
end function

function object_collection_add(filename as String, collection() as Object3) as Object3 ptr
    dim as Object3 o
    if o.loadFile(filename) = 0 then
        dim as integer n = ubound(collection)
        redim preserve collection(n+1)
        collection(n+1) = o
        return @collection(n+1)
    end if
end function
