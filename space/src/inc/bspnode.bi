' -----------------------------------------------------------------------------
' Copyright (c) 2025 Joe King
' See main file or LICENSE for license and build info.
' -----------------------------------------------------------------------------

type BspNode3
    as integer faceId = -1
    as BspNode3 ptr behind, infront
end type
