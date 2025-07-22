' -----------------------------------------------------------------------------
' Copyright (c) 2025 Joe King
' See main file or LICENSE for license and build info.
' -----------------------------------------------------------------------------
#ifdef __FB_64BIT__
    #define _long_ longint
#else
    #define _long_ long
#endif

enum Mouse2Event
    LeftDown = 0
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
enum Mouse2Mode
    Standard = 0
    Viewport
end enum
type Mouse2
private:
    _buttonsPrev as _long_
    _dragFromX as _long_
    _dragFromY as _long_
    _dragDeltaX as _long_
    _dragDeltaY as _long_
    _events(Mouse2Event.MAX_VALUE) as boolean
    _isVisible as boolean = true
    _mode as integer = Mouse2Mode.Standard
    _wheelPrev as _long_
    _wheelDelta as _long_
    _xPrev as _long_
    _xDelta as _long_
    _yPrev as _long_
    _yDelta as _long_
public:
    x as double
    y as double
    wheel as _long_
    buttons as _long_
    clipped as _long_
    status as _long_
    declare constructor ()
    declare constructor (initMode as integer)
    declare property deltaX         as _long_
    declare property deltaY         as _long_
    declare property dragX          as _long_
    declare property dragY          as _long_
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
    declare property wheelDelta     as _long_
    declare sub clip()
    declare sub unclip()
    declare sub hide()
    declare sub show()
    declare sub update()
    declare sub setMode(newMode as integer)
end type
constructor Mouse2
end constructor
constructor Mouse2(initMode as integer)
    _mode = initMode
end constructor
property Mouse2.deltaX         as _long_ : return _xDelta                         : end property
property Mouse2.deltaY         as _long_ : return _yDelta                         : end property
property Mouse2.dragX          as _long_ : return _dragDeltaX                     : end property
property Mouse2.dragY          as _long_ : return _dragDeltaY                     : end property
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
property Mouse2.wheelDelta     as _long_ : return _wheelDelta                     : end property
property Mouse2.visible        as boolean: return _isVisible                      : end property
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
sub Mouse2.setMode(newMode as integer)
    this._mode = newMode
end sub
sub Mouse2.update()
    dim as integer i, j
    status = getmouse(i, j, wheel, buttons, clipped)
    if status <> 0 then
        _wheelDelta = 0
        _xDelta = 0
        _yDelta = 0
        for i as integer = 0 to ubound(_events)
            _events(i) = false
        next i
    else
        x = i
        y = j
        if _mode = Mouse2Mode.Viewport then
            x = pmap(x, 2)
            y = pmap(y, 3)
        end if
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
                _xPrev = x
            else
                _xDelta = 0
            end if
            if _yPrev <> y then
                _yDelta = y - _yPrev
                _yPrev = y
            else
                _yDelta = 0
            end if
            _events(Mouse2Event.Move) = true
        else
            _xDelta = 0
            _yDelta = 0
            _events(Mouse2Event.Move) = false
        end if
        if leftClicked then
            _dragFromX = x
            _dragFromY = y
        elseif leftDown or leftReleased then
            _dragDeltaX = x - _dragFromX
            _dragDeltaY = y - _dragFromY
        else
            _dragDeltaX = 0
            _dragDeltaY = 0
        end if
    end if
end sub
