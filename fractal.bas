declare function fractal(x as double, z as double, d as double) as double
const SCREEN_W = 1280
const SCREEN_H = 720


screenres SCREEN_W, SCREEN_H, 32

dim as double x, z, f
dim as integer sx, sz

for sz = 0 to SCREEN_H-1
    for sx = 0 to SCREEN_W-1
        x = sx / SCREEN_W - 0.5
        z = sz / SCREEN_H - 0.5
        f = iif(x <> 0, fractal(x, z, 1), 0)
        pset (sx, sz), rgb(f, f, f)
    next sx
next sz

sleep
end

function fractal(x as double, z as double, d as double) as double
    if d > 2 then return d
    return fractal(x, z, d * d + x)
end function
