' -----------------------------------------------------------------------------
' Copyright (c) 2025 Joe King
' See main file or LICENSE for license and build info.
' -----------------------------------------------------------------------------
#define pi 3.1415926535
#define rad(degrees) degrees * PI/180
#define deg(radians) radians * 180/PI
#define rgb_r(c) (c shr 16 and &hff)
#define rgb_g(c) (c shr  8 and &hff)
#define rgb_b(c) (c        and &hff)
#define format_decimal(f, p) iif(f >= 0, " ", "-") + str(abs(fix(f))) + "." + str(int(abs(frac(f)) * 10^p))
#define clamp(value, min, max) iif(value < min, min, iif(value > max, max, value))
#define lerpexp(from, goal, a) lerp(from, goal, 1 - exp(-4.0 * a))

#macro array_append(arr, value)
    redim preserve arr(ubound(arr) + 1)
    arr(ubound(arr)) = value
#endmacro

#macro keydown(scanCode, waitVar, codeBlock)
    if multikey(scanCode) and waitVar = -1 then
        waitVar = scanCode
        codeBlock
    elseif not multikey(scanCode) and waitVar = scanCode then
        waitVar = -1
    end if
#endmacro
