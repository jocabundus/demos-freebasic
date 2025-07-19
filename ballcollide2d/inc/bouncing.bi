sub reverse(byref a as double)
    a = -a
end sub

type BoundsType
    lft as double
    rgt as double
    top as double
    btm as double
end type

type VectorType
    x as double
    y as double
    declare function add(d as double) as VectorType
    declare function subt(d as double) as VectorType
    declare function mul(d as double) as VectorType
    declare function div(d as double) as VectorType
    declare function add(v as VectorType) as VectorType
    declare function subt(v as VectorType) as VectorType
    declare function mul(v as VectorType) as VectorType
    declare function div(v as VectorType) as VectorType
    declare function port() as VectorType
    declare function starboard() as VectorType
    declare function size() as double
    declare function unit() as VectorType
end type
function VectorType.add (d as double) as VectorType: return type(this.x + d, this.y + d): end function
function VectorType.subt(d as double) as VectorType: return type(this.x - d, this.y - d): end function
function VectorType.mul (d as double) as VectorType: return type(this.x * d, this.y * d): end function
function VectorType.div (d as double) as VectorType: return type(this.x / d, this.y / d): end function
function VectorType.add (v as VectorType) as VectorType: return type(this.x + v.x, this.y + v.y): end function
function VectorType.subt(v as VectorType) as VectorType: return type(this.x - v.x, this.y - v.y): end function
function VectorType.mul (v as VectorType) as VectorType: return type(this.x * v.x, this.y * v.y): end function
function VectorType.div (v as VectorType) as VectorType: return type(this.x / v.x, this.y / v.y): end function
function VectorType.port() as VectorType     : return type(this.y, -this.x): end function
function VectorType.starboard() as VectorType: return type(-this.y, this.x): end function
function VectorType.size() as double
    dim as double x, y
    let(x, y) = this
    return sqr(x*x+y*y)
end function
function VectorType.unit() as VectorType
    dim as double m = this.size()
    return type(this.x / m, this.y / m)
end function

function dot(byref a as const VectorType, byref b as const VectorType) as double
    return a.x*b.x + a.y*b.y
end function

function magnitude(byref v as const VectorType) as double
    return sqr(v.x*v.x+v.y*v.y)
end function

function unit(byref v as const VectorType) as VectorType
    dim as double m = magnitude(v)
    return type(v.x / m, v.y / m)
end function

sub vectorCopy overload(byref _from as const VectorType, byref _to as VectorType):
    _to.x = _from.x
    _to.y = _from.y
end sub
function vectorClone overload(byref v as const VectorType) as VectorType
    dim as VectorType c
    vectorCopy v, c
    return c
end function
function vectorSize overload(byref v as const VectorType) as  double
    return sqr(v.x*v.x+v.y*v.y)
end function
function vectorDot overload(byref a as const VectorType, byref b as const VectorType) as double
    return a.x*b.x + a.y*b.y
end function

sub vectorClone(byref a as const VectorType, byref b as VectorType)
    vectorCopy a, b: vectorClone b
end sub
sub vectorSize(byref v as const VectorType, byref size as double)
    size = vectorSize(v)
end sub
sub vectorDot(byref a as const VectorType, byref b as const VectorType, byref dotp as double)
    dotp = vectorDot(a, b)
end sub

sub vectorAdd overload(byref a as VectorType, byval b as double): a.x += b: a.y += b: end sub
sub vectorSub overload(byref a as VectorType, byval b as double): a.x -= b: a.y -= b: end sub
sub vectorMul overload(byref a as VectorType, byval b as double): a.x *= b: a.y *= b: end sub
sub vectorDiv overload(byref a as VectorType, byval b as double): a.x /= b: a.y /= b: end sub
sub vectorAdd(byref a as VectorType, byref b as const VectorType): a.x += b.x: a.y += b.y: end sub
sub vectorSub(byref a as VectorType, byref b as const VectorType): a.x -= b.x: a.y -= b.y: end sub
sub vectorMul(byref a as VectorType, byref b as const VectorType): a.x *= b.x: a.y *= b.y: end sub
sub vectorDiv(byref a as VectorType, byref b as const VectorType): a.x /= b.x: a.y /= b.y: end sub
sub vectorAdd(byref a as const VectorType, byval b as double, byref c as VectorType): vectorCopy(a, c): vectorAdd(c, b): end sub
sub vectorSub(byref a as const VectorType, byval b as double, byref c as VectorType): vectorCopy(a, c): vectorSub(c, b): end sub
sub vectorMul(byref a as const VectorType, byval b as double, byref c as VectorType): vectorCopy(a, c): vectorMul(c, b): end sub
sub vectorDiv(byref a as const VectorType, byval b as double, byref c as VectorType): vectorCopy(a, c): vectorDiv(c, b): end sub
sub vectorAdd(byref a as const VectorType, byref b as const VectorType, byref c as VectorType): vectorCopy(a, c): vectorAdd(c, b): end sub
sub vectorSub(byref a as const VectorType, byref b as const VectorType, byref c as VectorType): vectorCopy(a, c): vectorSub(c, b): end sub
sub vectorMul(byref a as const VectorType, byref b as const VectorType, byref c as VectorType): vectorCopy(a, c): vectorMul(c, b): end sub
sub vectorDiv(byref a as const VectorType, byref b as const VectorType, byref c as VectorType): vectorCopy(a, c): vectorDiv(c, b): end sub
sub vectorRev(byref a as VectorType): a.x = -a.x: a.y = -a.y: end sub

operator - (byref v as const VectorType) as VectorType: return type(-v.x, -v.y): end operator
operator + (byref a as const VectorType, byval b as double) as VectorType: return type(a.x+b, a.y+b): end operator
operator - (byref a as const VectorType, byval b as double) as VectorType: return type(a.x-b, a.y-b): end operator
operator * (byref a as const VectorType, byval b as double) as VectorType: return type(a.x*b, a.y*b): end operator
operator / (byref a as const VectorType, byval b as double) as VectorType: return type(a.x/b, a.y/b): end operator
operator + (byref a as const VectorType, byref b as const VectorType) as VectorType: return type(a.x+b.x, a.y+b.y): end operator
operator - (byref a as const VectorType, byref b as const VectorType) as VectorType: return type(a.x-b.x, a.y-b.y): end operator
operator * (byref a as const VectorType, byref b as const VectorType) as VectorType: return type(a.x*b.x, a.y*b.y): end operator
operator / (byref a as const VectorType, byref b as const VectorType) as VectorType: return type(a.x/b.x, a.y/b.y): end operator

sub vectorUnit overload(byref v as VectorType)
    dim as double size = vectorSize(v): vectorDiv v, size
end sub
sub vectorUnit(byref a as const VectorType, byref b as VectorType)
    vectorCopy a, b: vectorUnit b
end sub

sub vectorLeft overload(byref v as VectorType)
    dim as double x, y
    x = v.y: y = -v.x
    v.x = x: v.y =  y
end sub
sub vectorRight overload(byref v as VectorType)
    dim as double x, y
    x = -v.y: y = v.x
    v.x =  x: v.y = y
end sub
sub vectorLeft(byref a as const VectorType, byref b as VectorType)
    vectorCopy a, b
    vectorLeft b
end sub
sub vectorRight(byref a as const VectorType, byref b as VectorType)
    vectorCopy a, b
    vectorRight b
end sub

sub vectorCopy(byref _from as const VectorType, _to() as VectorType)
    dim as integer n: for n = lbound(_to) to ubound(_to): vectorCopy(_from, _to(n)): next n
end sub
sub vectorUnit(v() as VectorType)
    dim as integer n: for n = lbound(v) to ubound(v): vectorUnit v(n): next n
end sub
sub vectorAdd(a() as VectorType, byval b as double)
    dim as integer n: for n = lbound(a) to ubound(a): vectorAdd a(n), b: next n
end sub
sub vectorSub(a() as VectorType, byval b as double)
    dim as integer n: for n = lbound(a) to ubound(a): vectorSub a(n), b: next n
end sub
sub vectorMul(a() as VectorType, byval b as double)
    dim as integer n: for n = lbound(a) to ubound(a): vectorMul a(n), b: next n
end sub
sub vectorDiv(a() as VectorType, byval b as double)
    dim as integer n: for n = lbound(a) to ubound(a): vectorDiv a(n), b: next n
end sub

sub vectorAdd(a() as VectorType, b() as VectorType)
    dim as integer n: for n = lbound(a) to ubound(a): vectorAdd a(n), b(n): next n
end sub

type BallType
    position as VectorType
    velocity as VectorType
    radius as double
    mass  as double
    spin  as double
    angle as double
    colr  as integer
    declare property lft() as double
    declare property rgt() as double
    declare property top() as double
    declare property btm() as double
end type
property BallType.lft() as double: return this.position.x - radius: end property
property BallType.rgt() as double: return this.position.x + radius: end property
property BallType.top() as double: return this.position.y - radius: end property
property BallType.btm() as double: return this.position.y + radius: end property
