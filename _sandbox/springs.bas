dim shared as integer SCREEN_W
dim shared as integer SCREEN_H
dim shared as integer SCREEN_DEPTH
dim shared as double  SCREEN_ASPECT_XY
dim shared as double  SCREEN_ASPECT_YX
dim shared as integer FULL_SCREEN = 1

screeninfo SCREEN_W, SCREEN_H, SCREEN_DEPTH
screenres SCREEN_W, SCREEN_H, SCREEN_DEPTH, 2, FULL_SCREEN
SCREEN_ASPECT_XY = SCREEN_W / SCREEN_H
SCREEN_ASPECT_YX = SCREEN_H / SCREEN_W

#define xMax SCREEN_ASPECT_XY
#define yMax 1

randomize

type Color3
    r as ubyte
    g as ubyte
    b as ubyte
    declare function getRandom() as integer
end type
function Color3.getRandom() as integer
    return rgb(255*int(rnd+.5),255*int(rnd+.5),255*int(rnd+.5))
end function

type Vector2
    x as double
    y as double
    declare constructor
    declare constructor(x as double, y as double)
end type
constructor Vector2
end constructor
constructor Vector2(x as double, y as double)
    this.x = x
    this.y = y
end constructor

enum Shape2
    None = 0
    DashedLineSegment
    DottedLineSegment
    Ellipse
    LineSegment
    Rectangle
end enum

type Object2
    private:
        _color3 as integer
        _position as Vector2
        _label as string
        _mass as double
        _shape as Shape2
        _size as Vector2
        declare function _getRandomColor () as integer
    public:
        declare constructor ()
        declare constructor _
        (_
            _label as string,_
            _shape as Shape2 = Shape2.Rectangle,_
            _size as Vector2,_
            _mass as double = 1,_
            _position as Vector2,_
            _color3 as integer = -1_
        )
        declare property color3 as integer
        declare property color3 (newColor3 as integer)
        declare property position as Vector2
        declare property position (newPosition as Vector2)
        declare property label as string
        declare property label (newLabel as string)
        declare property mass as double
        declare property mass (newMass as double)
        declare property shape as Shape2
        declare property shape (newShape as Shape2)
        declare property size as Vector2
        declare property size (newSize as Vector2)
        declare property btm as double
        declare property lft as double
        declare property rgt as double
        declare property top as double
        declare property x as double
        declare property y as double
        declare property w as double
        declare property h as double
        declare property aspect as double
        declare property radius as double
        declare sub drawNow ()
end type
constructor Object2 ()
    this._color3 = this._getRandomColor()
end constructor
constructor Object2 _
(_
    _label as string,_
    _shape as Shape2 = Shape2.Rectangle,_
    _size as Vector2,_
    _mass as double = 1,_
    _position as Vector2,_
    _color3 as integer = -1_
)
    this._label = _label
    this._shape = _shape
    this._size  = _size
    this._mass  = _mass
    this._position = _position
    this._color3 = iif(_color3 > -1, _color3, this._getRandomColor())
end constructor
function Object2._getRandomColor() as integer
    return rgb(255*int(rnd+.5),255*int(rnd+.5),255*int(rnd+.5))
end function
property Object2.color3 as integer: return this._color3: end property
property Object2.color3 (newColor3 as integer): this._color3 = color3: end property
property Object2.position as Vector2: return this._position: end property
property Object2.position (newPosition as Vector2): this._position = newPosition: end property
property Object2.label as string: return this._label: end property
property Object2.label (newLabel as string): this._label = newLabel: end property
property Object2.mass as double: return this._mass: end property
property Object2.mass (newMass as double): this._mass = newMass: end property
property Object2.shape as Shape2: return this._shape: end property
property Object2.shape (newShape as Shape2): this._shape = newShape: end property
property Object2.size as Vector2: return this._size: end property
property Object2.size (newSize as Vector2): this._size = newSize: end property
property Object2.btm as double: return this.top - this.h * 0.5: end property
property Object2.lft as double: return this.lft - this.w * 0.5: end property
property Object2.rgt as double: return this.lft + this.w * 0.5: end property
property Object2.top as double: return this.top + this.h * 0.5: end property
property Object2.x as double: return this.position.x: end property
property Object2.y as double: return this.position.y: end property
property Object2.w as double: return this.size.x: end property
property Object2.h as double: return this.size.y: end property
property Object2.aspect as double: return this.h / this.w: end property
property Object2.radius as double: return iif(this.w > this.h, this.w, this.h): end property
sub Object2.drawNow ()
    select case this._shape
    case Shape2.DashedLineSegment
        line (this.lft, this.top)-(this.rgt, this.btm), this._color3, , &b1111000000001111
    case Shape2.DottedLineSegment
        line (this.lft, this.top)-(this.rgt, this.btm), this._color3, , &b1100110011001100
    case Shape2.Ellipse
        circle (this.x, this.y), this.radius, this._color3, , , this.aspect
    case Shape2.LineSegment
        line (this.lft, this.top)-(this.rgt, this.btm), this._color3
    case Shape2.Rectangle
        line (this.lft, this.top)-(this.rgt, this.btm), this._color3, b
    end select
end sub

type Spring2 extends Object2
    displacement as double
end type
dim as Spring2 spring
dim as Object2 weight

dim as Object2 collection(any)
function addObjectToArray(o as Object2, collection() as Object2) as Object2
    dim as integer i = ubound(collection)+1
    redim preserve collection(i)
    collection(i) = o
    return o
end function



window(-SCREEN_ASPECT_XY, 1)-(SCREEN_ASPECT_XY, -1)

spring.position = Vector2(0, 2/3)
spring.size  = Vector2(1/5, 1/25)
spring.shape = Shape2.Ellipse

line (-xMax,  0)-( xMax,  0), &hc08080, , &b1111000000001111
line ( 0, -yMax)-( 0,  yMax), &h80c080, , &b1111000000001111
line (-.5, -.5)-(.5, .5), &hffffff
spring.drawNow()
sleep
end
