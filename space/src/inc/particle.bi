' -----------------------------------------------------------------------------
' Copyright (c) 2025 Joe King
' See main file or LICENSE for license and build info.
' -----------------------------------------------------------------------------
#include once "vector3.bi"

type ParticleType
    colr as integer
    position as Vector3
    twinkleAmp as double
    twinkleFreq as double
    twinklePhase as double
    declare constructor ()
    declare constructor (position as Vector3, colr as integer)
    declare function getTwinkleColor () as integer
    declare sub randomizeTwinkle ()
end type
