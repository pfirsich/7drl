local m = {}

function m.intervalsOverlap(aMin, aMax, bMin, bMax)
    return not (bMin > aMax or aMin > bMax)
end

function m.intervalIntersection(aMin, aMax, bMin, bMax)
    -- cases:
    -- aMin aMax bMin bMax // no overlap -> empty
    -- bMin bMax aMin aMax // no overlap -> empty
    -- aMin bMin bMax aMax // fully enclosed -> bMin, bMax
    -- bMin aMin aMax bMax // fully enclosed -> aMin, aMax
    -- aMin bMin aMax bMax // -> bMin, aMax
    -- bMin aMin bMax aMax // -> aMin, bMax
    if bMin > aMax or aMin > bMax then
        return 1, -1 -- return a non-valid interval with upper - lower < 0
    else
        return math.max(aMin, bMin), math.min(aMax, bMax)
    end
end

local function minMax(a, b)
    return math.min(a, b), math.max(a, b)
end

-- what to return if ray is inside the box?
-- what if the ray hits the box only with t < 0?
function m.castRayIntoAABB(x, y, z, dx, dy, dz, minX, minY, minZ, maxX, maxY, maxZ)
    -- minX <= x + dx * t <= maxX
    local t1X = (minX - x) / dx
    local t2X = (maxX - x) / dx
    local tMinX, tMaxX = minMax(t1X, t2X)

    local t1Y = (minY - y) / dy
    local t2Y = (maxY - y) / dy
    local tMinY, tMaxY = minMax(t1Y, t2Y)

    local t1Z = (minZ - z) / dz
    local t2Z = (maxZ - z) / dz
    local tMinZ, tMaxZ = minMax(t1Z, t2Z)

    local tMin, tMax = m.intervalIntersection(tMinX, tMaxX, tMinY, tMaxY)
    tMin, tMax = m.intervalIntersection(tMin, tMax, tMinZ, tMaxZ)

    -- the intersection of the t ranges is non-empty => there is a t for which the ray is inside the aab on all axes
    if tMax - tMin >= 0 then
        return tMin
    else
        return nil
    end
end

-- ray: (x, y, z) + t * (dx, dy, dz)
-- circle: center = (cx, cy, cz), radius r
-- https://www.scratchapixel.com/lessons/3d-basic-rendering/minimal-ray-tracer-rendering-simple-shapes/ray-sphere-intersection
function m.castRayIntoSphere(x, y, z, dx, dy, dz, cx, cy, cz, r)
    local rx, ry, rz = x - cx, y - cy, z - cz

    local a = dx*dx + dy*dy + dz*dz
    local b = 2 * (rx*dx + ry*dy + rz*dz)
    local c = rx*rx + ry*ry + rz*dz - r*r

    local D = b*b - 4*a*c
    if D < 0 then
        return nil
    else
        local t0 = (-b + math.sqrt(D)) / (2*a)
        local t1 = (-b - math.sqrt(D)) / (2*a)
        return math.min(t0, t1)
    end
end

function m.clamp(x, lo, hi)
    return math.max(lo, math.min(hi, x))
end

function m.inRange(x, lo, hi)
    return x > lo and x < hi
end

function m.minAbs(a, b)
    return math.abs(a) < math.abs(b) and a or b
end

function m.cylinderAABBIntersection(cx, cy, cz, r, h, minX, minY, minZ, maxX, maxY, maxZ)
    if m.intervalsOverlap(cy - h/2, cy + h/2, minY, maxY) then
        -- 2 dimensional problem
        local mtvYpos = maxY - cy + h/2 -- cy - h/2 + mtvY = maxY
        local mtvYneg = minY - cy - h/2 -- cy + h/2 + mtvY = minY
        local mtvY = m.minAbs(mtvYpos, mtvYneg)
        if m.inRange(cx, minX, maxX) and m.inRange(cz, minZ, maxZ) then
            return 0, mtvYpos, 0
        else
            local closestX = m.clamp(cx, minX, maxX)
            local closestZ = m.clamp(cz, minZ, maxZ)
            -- this bugs out when relX == relZ == 0, but this is not easy to fix, because how do I figure out in which direction to push the cylinder?
            -- I think I should decide based on which face the cylinder is in (minX -> push to -x, etc.)
            -- this breaks when we are between two boxes (which is mostly the case when rel is 0) though, therefore return 0, 0, 0 for now
            local relX, relZ = cx - closestX, cz - closestZ
            local relLen = math.sqrt(relX*relX + relZ*relZ) + 1e-8
            local dist = relLen - r
            if dist < 0 then
                if math.abs(mtvY) < math.abs(dist) then
                    return 0, mtvY, 0
                else
                    return relX / relLen * -dist, 0, relZ / relLen * -dist
                end
            end
        end
    end
    return nil
end

return m
