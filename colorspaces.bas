#include once "fbgfx.bi"
using FB
const PI = 3.131592
dim shared as integer SCREEN_W
dim shared as integer SCREEN_H
dim shared as integer SCREEN_DEPTH
dim shared as integer FULL_SCREEN = 0

screeninfo SCREEN_W, SCREEN_H, SCREEN_DEPTH
screenres iif(SCREEN_W < SCREEN_H, SCREEN_W, SCREEN_H)*0.8,_
          iif(SCREEN_W < SCREEN_H, SCREEN_W, SCREEN_H)*0.8,_
          SCREEN_DEPTH, 2, FULL_SCREEN
screenset 1, 0
window (-4/3, 4/3)-(4/3, -4/3)

enum Mouse2Event
    LeftDown
    LeftUp
    MiddleDown
    MiddleUp
    Move
    RightDown
    RightUp
    WheelChange
    __
    MAX_VALUE = __ - 1
end enum
type Mouse2
private:
    _buttonsPrev as long
    _dragFromX as long
    _dragFromY as long
    _dragDeltaX as long
    _dragDeltaY as long
    _events(Mouse2Event.MAX_VALUE) as boolean
    _isVisible as boolean
    _wheelPrev as long
    _wheelDelta as long
    _xPrev as long
    _xDelta as long
    _yPrev as long
    _yDelta as long
    _viewX as double
    _viewY as double
    _viewDeltaX as double
    _viewDeltaY as double
    _viewDragDeltaX as double
    _viewDragDeltaY as double
public:
    x as long
    y as long
    wheel as long
    buttons as long
    clipped as long
    status as long
    declare property deltaX         as long
    declare property deltaY         as long
    declare property dragX          as long
    declare property dragY          as long
    declare property leftClicked    as boolean
    declare property leftReleased   as boolean
    declare property leftDown       as boolean
    declare property leftUp         as boolean
    declare property middleClicked  as boolean
    declare property middleReleased as boolean
    declare property middleDown     as boolean
    declare property middleUp       as boolean
    declare property moved          as boolean
    declare property rightClicked   as boolean
    declare property rightReleased  as boolean
    declare property rightDown      as boolean
    declare property rightUp        as boolean
    declare property visible        as boolean
    declare property wheelChanged   as boolean
    declare property wheelDelta     as long
    declare property viewX          as double
    declare property viewY          as double
    declare property viewDeltaX     as double
    declare property viewDeltaY     as double
    declare property viewDragX      as double
    declare property viewDragY      as double
    declare sub clip()
    declare sub unclip()
    declare sub hide()
    declare sub show()
    declare sub update()
end type
property Mouse2.deltaX         as long   : return _xDelta                         : end property
property Mouse2.deltaY         as long   : return _yDelta                         : end property
property Mouse2.dragX          as long   : return _dragDeltaX                     : end property
property Mouse2.dragY          as long   : return _dragDeltaY                     : end property
property Mouse2.leftClicked    as boolean: return _events(Mouse2Event.LeftDown)   : end property
property Mouse2.leftReleased   as boolean: return _events(Mouse2Event.LeftUp)     : end property
property Mouse2.leftDown       as boolean: return iif(buttons and 1, true, false) : end property
property Mouse2.leftUp         as boolean: return iif(buttons and 1, false, true) : end property
property Mouse2.middleClicked  as boolean: return _events(Mouse2Event.MiddleDown) : end property
property Mouse2.middleReleased as boolean: return _events(Mouse2Event.MiddleUp)   : end property
property Mouse2.middleDown     as boolean: return iif(buttons and 4, true, false) : end property
property Mouse2.middleUp       as boolean: return iif(buttons and 4, false, true) : end property
property Mouse2.moved          as boolean: return _events(Mouse2Event.Move)       : end property
property Mouse2.rightClicked   as boolean: return _events(Mouse2Event.RightDown)  : end property
property Mouse2.rightReleased  as boolean: return _events(Mouse2Event.RightUp)    : end property
property Mouse2.rightDown      as boolean: return iif(buttons and 2, true, false) : end property
property Mouse2.rightUp        as boolean: return iif(buttons and 2, false, true) : end property
property Mouse2.wheelChanged   as boolean: return _events(Mouse2Event.WheelChange): end property
property Mouse2.wheelDelta     as long   : return _wheelDelta                     : end property
property Mouse2.visible        as boolean: return _isVisible                      : end property
property Mouse2.viewX          as double : return _viewX         : end property
property Mouse2.viewY          as double : return _viewY         : end property
property Mouse2.viewDeltaX     as double : return _viewDeltaX    : end property
property Mouse2.viewDeltaY     as double : return _viewDeltaY    : end property
property Mouse2.viewDragX      as double : return _viewDragDeltaX: end property
property Mouse2.viewDragY      as double : return _viewDragDeltaY: end property
sub Mouse2.clip()
    if clipped = 0 then
        clipped = 1
        setmouse , , , 1
    end if
end sub
sub Mouse2.unclip()
    if clipped = 1 then
        clipped = 0
        setmouse , , , 0
    end if
end sub
sub Mouse2.hide()
    if _isVisible = true then
        _isVisible = false
        setmouse , , 0
    end if
end sub
sub Mouse2.show()
    if _isVisible = false then
        _isVisible = true
        setmouse , , 1
    end if
end sub
sub Mouse2.update()
    status = getmouse(x, y, wheel, buttons, clipped)
    if status <> 0 then
        _wheelDelta = 0
        _xDelta = 0
        _yDelta = 0
        _viewDeltaX = 0
        _viewDeltaY = 0
        for i as integer = 0 to ubound(_events)
            _events(i) = false
        next i
    else
        _viewX = pmap(x, 2)
        _viewY = pmap(y, 3)
        if _buttonsPrev <> buttons then
            if buttons and 1 <> _buttonsPrev and 1 then
                _events(Mouse2Event.LeftDown) = iif(buttons and 1, true, false)
                _events(Mouse2Event.LeftUp  ) = iif(buttons and 1, false, true)
            end if
            if buttons and 4 <> _buttonsPrev and 2 then
                _events(Mouse2Event.RightDown) = iif(buttons and 2, true, false)
                _events(Mouse2Event.RightUp  ) = iif(buttons and 2, false, true)
            end if
            if buttons and 2 <> _buttonsPrev and 4 then
                _events(Mouse2Event.MiddleDown) = iif(buttons and 4, true, false)
                _events(Mouse2Event.MiddleUp  ) = iif(buttons and 4, false, true)
            end if
            _buttonsPrev = buttons
        else
            _events(Mouse2Event.LeftDown)   = false
            _events(Mouse2Event.LeftUp)     = false
            _events(Mouse2Event.MiddleDown) = false
            _events(Mouse2Event.MiddleUp)   = false
            _events(Mouse2Event.RightDown)  = false
            _events(Mouse2Event.RightUp)    = false
        end if
        if _wheelPrev <> wheel then
            _wheelDelta = wheel - _wheelPrev
            _wheelPrev = wheel
            _events(Mouse2Event.WheelChange) = true
        else
            _wheelDelta = 0
            _events(Mouse2Event.WheelChange) = false
        end if
        if _xPrev <> x or _yPrev <> y then
            if _xPrev <> x then
                _xDelta = x - _xPrev
                _viewDeltaX = _viewX - pmap(_xPrev, 2)
                _xPrev = x
            else
                _xDelta = 0
                _viewDeltaX = 0
            end if
            if _yPrev <> y then
                _yDelta = y - _yPrev
                _viewDeltaY = _viewY - pmap(_yPrev, 3)
                _yPrev = y
            else
                _yDelta = 0
                _viewDeltaY = 0
            end if
            _events(Mouse2Event.Move) = true
        else
            _xDelta = 0
            _yDelta = 0
            _viewDeltaX = 0
            _viewDeltaY = 0
            _events(Mouse2Event.Move) = false
        end if
        if leftClicked then
            _dragFromX = x
            _dragFromY = y
        elseif leftDown or leftReleased then
            _dragDeltaX = x - _dragFromX
            _dragDeltaY = y - _dragFromY
            _viewDragDeltaX = _viewX - pmap(_dragFromX, 2)
            _viewDragDeltaY = _viewY - pmap(_dragFromY, 3)
        else
            _dragDeltaX = 0
            _dragDeltaY = 0
            _viewDragDeltaX = 0
            _viewDragDeltaY = 0
        end if
    end if
end sub

type Vector2
    x as double
    y as double
    declare constructor ()
    declare constructor (radians as double)
    declare constructor (x as double, y as double)
    declare property length as double
    declare function rotate(radians as double) as Vector2
    declare function unit() as Vector2
end type
constructor Vector2
end constructor
constructor Vector2 (radians as double)
    this.x = cos(radians)
    this.y = sin(radians)
end constructor
constructor Vector2 (x as double, y as double)
    this.x = x
    this.y = y
end constructor
operator - (a as Vector2) as Vector2
    return Vector2(-a.x, -a.y)
end operator
operator + (a as Vector2, b as Vector2) as Vector2
    return Vector2(a.x + b.x, a.y + b.y)
end operator
operator - (a as Vector2, b as Vector2) as Vector2
    return a + -b
end operator
operator * (a as Vector2, d as double) as Vector2
    return Vector2(a.x * d, a.y * d)
end operator
operator / (a as Vector2, d as double) as Vector2
    return Vector2(a.x / d, a.y / d)
end operator
property Vector2.length() as double
    return sqr(x*x+y*y)
end property
function Vector2.rotate(radians as double) as Vector2
    dim as double rcos = cos(radians)
    dim as double rsin = sin(radians)
    return Vector2(_
        x*rcos + y*-rsin,_
        x*rsin + y* rcos _
    )
end function
function Vector2.unit() as Vector2
    return this / this.length
end function

function clamp(value as double, min as double = 0, max as double = 1) as double
    return iif(value < min, min, iif(value > max, max, value))
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

function pickColor(a as double, m as double=1, variant as integer=0) as integer
    dim as Vector2 vr, vg, vb, va
    vr = Vector2(2*PI*1/1)
    vg = Vector2(2*PI*1/3)
    vb = Vector2(2*PI*2/3)
    va = Vector2(a) * m
    dim as double r, g, b
    select case variant
        case 1
            r = clamp(1-(vr - va).length)
            g = clamp(1-(vg - va).length)
            b = clamp(1-(vb - va).length)
        case 2
            r = clamp(sin(1-(vr - va).length))
            g = clamp(sin(1-(vg - va).length))
            b = clamp(sin(1-(vb - va).length))
        case 3
            r = clamp(cos(2-(vr - va).length))
            g = clamp(cos(2-(vg - va).length))
            b = clamp(cos(2-(vb - va).length))
        case 4
            r = clamp(sin((vr - va).length))
            g = clamp(sin((vg - va).length))
            b = clamp(sin((vb - va).length))
        case 5
            r = clamp(sin(2-(vr - va).length))
            g = clamp(sin(2-(vg - va).length))
            b = clamp(sin(2-(vb - va).length))
        case 6
            dim as PointLight lights(3) = _
            {_
                type(Vector2(0/3*PI)/2, &hff0000, 1),_
                type(Vector2(2/3*PI)/2, &h00ff00, 1),_
                type(Vector2(4/3*PI)/2, &h0000ff, 1),_
                type(Vector2(0, 0)    , &hffffff, 1) _
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
        case 7
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
        case 8
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
                dim as double  d = clamp(1-sin((p - va).length))
                r += int(d * m * (c shr 16 and &hff))
                g += int(d * m * (c shr  8 and &hff))
                b += int(d * m * (c        and &hff))
            next i
            return rgb(clamp(r,0,255), clamp(g,0,255), clamp(b,0,255))
    end select
    return rgb(int(256*r), int(256*g), int(256*b))
end function

dim as integer first = 1, last = 8, variant = 1
dim as integer key, keyWait
dim as double rotations(last)
dim as double lastFrameTime = timer
dim as Mouse2 mouse
while true
    cls
    locate 1, 1: color &hffffff: print str(variant)
    dim as double dx = abs(pmap(0,2))-abs(pmap(1,2))
    dim as double dy = abs(pmap(0,3))-abs(pmap(1,3))
    for y as integer = -1 to 7 '- 0 skips the first pixel, bug?
        for x as integer = 0 to 7
            dim as integer c = point(pmap(x, 2), pmap(y, 3))
            line((1-dx*44)+x*dx*8, 1-y*dy*8)-step(dx*7, -dy*7), c, bf
        next x
    next y
    dim as double stp = 1/50
    for y as double = 1 to -1 step -stp
        for x as double = -1 to 1 step stp
            dim as double m = sqr(x*x+y*y)
            if m <= 1 then
                dim as Vector2 v = type(x, y).rotate(rotations(variant))
                dim as double d = atan2(v.y, v.x): if d < 0 then d += 2*PI
                dim as integer c = pickColor(d, m, variant)
                line(x, y)-step(stp, -stp), c, bf
            end if
        next x
    next y
    mouse.update()
    dim as integer c = point(pmap(mouse.x, 2), -pmap(mouse.y, 2)) '- another bug?
    dim as string sr, sg, sb
    sr = str(c shr 16 and &hff)
    sg = str(c shr 8 and &hff)
    sb = str(c and &hff)
    'sr = string(3-len(sr), "-") + sr
    'sg = string(3-len(sg), "-") + sg
    'sb = string(3-len(sb), "-") + sb
    locate 1, 1: print "RGB " + sr + "," + sg + "," + sb
    locate 3, 1: print "HEX #" + hex(c, 6)
    for y as integer = -1 to 3*8-1 '- 0 skips the first pixel, bug?
        for x as integer = 0 to 20*8-1
            dim as integer c = point(pmap(x, 2), pmap(y, 3))
            line(-4/3+dx*16+x*dx*3, 4/3-dy*32-y*dy*3)-step(dx*2, -dy*2), c, bf
        next x
    next y
    line (-4/3, 4/3)-(-0, 4/3-dy*24), 0, bf
    screencopy 1, 0
    dim as double delta = timer - lastFrameTime: lastFrameTime = timer
    if multikey(keyWait) then
        continue while
    else
        keyWait = 0
    end if
    dim as integer validKeys(18) = {_
        SC_ENTER,_
        SC_BACKSLASH,_
        SC_LEFT,_
        SC_RIGHT,_
        SC_UP,_
        SC_DOWN,_
        SC_R,_
        SC_BACKSPACE,_
        SC_DELETE,_
        SC_1,_
        SC_2,_
        SC_3,_
        SC_4,_
        SC_5,_
        SC_6,_
        SC_7,_
        SC_8,_
        SC_9,_
        SC_ESCAPE _
    }
    key = 0
    for i as integer = 0 to ubound(validKeys)
        if multikey(validKeys(i)) then
            key = validKeys(i)
            exit for
        end if
    next i
    select case key
        case SC_ESCAPE
            exit while
        case SC_ENTER, SC_UP
            variant += 1
            if variant > last then variant = last
            keyWait = key
        case SC_BACKSLASH, SC_DOWN
            variant -= 1
            if variant < first then variant = first
            keyWait = key
        case SC_1 to SC_9
            dim as integer v = 1 + key - SC_1
            if v >= first and v <= last then
                variant = v
            end if
            keyWait = key
        case SC_LEFT
            dim as double a = rotations(variant) - delta*PI/2
            rotations(variant) = a
        case SC_RIGHT
            dim as double a = rotations(variant) + delta*PI/2
            rotations(variant) = a
        case SC_R, SC_BACKSPACE, SC_DELETE
            rotations(variant) = 0
    end select
    if mouse.LeftDown then
        dim as Vector2 a = type(mouse.viewX, mouse.viewY)
        dim as Vector2 b = type(mouse.viewDeltaX, mouse.viewDeltaY)
        dim as Vector2 c = a - b
        if b.length > 0 then
            rotations(variant) += a.x*c.y - a.y*c.x
        end if
    end if
    if mouse.RightClicked then
        rotations(variant) = 0
    end if
    if mouse.wheelChanged then
        variant += mouse.wheelDelta
        if variant < first then variant = first
        if variant > last then variant = last
    end if
wend
end
