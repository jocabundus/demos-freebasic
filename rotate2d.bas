type VectorType
    x as double
    y as double
end type

declare function percentToX(x as double) as integer
declare function percentToY(y as double) as integer
declare sub putPixel(x as integer, y as integer, colr as integer = &hffffff)
declare sub drawLine(x0 as integer, y0 as integer, x1 as integer, y1 as integer, colr as integer = &hffffff)
declare sub drawVector(v as VectorType, colr as integer = &hff0000)
declare sub vectorToAngle(v as VectorType, a as double)
declare sub setZoom(z as double = 1.0)

dim shared as integer SCREEN_W, SCREEN_H, SCREEN_BPP
dim shared as integer CENTER_X, CENTER_Y
dim shared as double ZOOM = 1.0
CONST PI = 3.141592


screeninfo SCREEN_W, SCREEN_H, SCREEN_BPP
screenres SCREEN_W, SCREEN_H, SCREEN_BPP, , 1
CENTER_X = percentToX(50)
CENTER_Y = percentToY(50)

setZoom 99
drawLine -CENTER_X, 0, CENTER_X, 0, &h7f7f7f
drawLine 0, -CENTER_Y, 0, CENTER_Y, &h7f7f7f

dim as VectorType u, v, r

vectorToAngle(u, 30)
vectorToAngle(r, 45)

drawVector r
drawVector u, &h00ff00

dim x as double

x = u.x
u.x = u.x * r.x - u.y * r.y
u.y = x   * r.x + u.y * r.x

drawVector u, &h00ffff


sleep
end

sub setZoom(z as double = 1.0)
    
    ZOOM = z
    
end sub

sub vectorToAngle(v as VectorType, a as double)
    
    v.x = cos(a*PI/180)
    v.y = sin(a*PI/180)
    
end sub

function percentToX(x as double) as integer
    
    return int(x*0.01*SCREEN_W)
    
end function

function percentToY(y as double) as integer
    
    return int(y*0.01*SCREEN_H)
    
end function

sub putPixel(x as integer, y as integer, colr as integer = &hffffff)

    pset (CENTER_X+x, CENTER_Y-y), colr

end sub

sub drawLine(x0 as integer, y0 as integer, x1 as integer, y1 as integer, colr as integer = &hffffff)
    
    line (CENTER_X+x0, CENTER_Y-y0)-(CENTER_X+x1, CENTER_Y-y1), colr
    
end sub

sub drawVector(v as VectorType, colr as integer = &hff0000)
    
    dim as double x, y
    x = v.x * ZOOM
    y = v.y * ZOOM
    drawLine 0, 0, x, y, colr

end sub
