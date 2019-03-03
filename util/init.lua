local util = {}

function util.bool2int(b)
    return b and 1 or 0
end

function util.randf(lo, hi)
    lo = lo or 0
    hi = hi or 1
    return love.math.random() * (hi - lo) + lo
end

function util.unpackKeys(tbl, key, ...)
    if key ~= nil then
        return tbl[key], util.unpackKeys(tbl, ...)
    end
end

function util.valueInTable(value, tbl)
    for _, v in pairs(tbl) do
        if v == value then return true end
    end
    return false
end

function util.indexOf(val, list)
    for i = 1, #list do
        if list[i] == val then return i end
    end
    return nil
end

function util.inList(val, list)
    return util.indexOf(val, list) ~= nil
end

return util
