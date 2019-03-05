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

function util.equal(a, b)
    if type(a) == type(b) then
        local t = type(a)
        if t == "table" then
            for k, v in pairs(a) do
                if not util.equal(b[k], v) then
                    return false
                end
            end
            return true
        else
            return a == b
        end
    else
        return false
    end
end

function util.keys(tbl)
    local keys = {}
    for k, v in pairs(tbl) do
        table.insert(keys, k)
    end
    return keys
end

function util.randomChoice(list)
    return list[love.math.random(1, #list)]
end

function util.shuffleList(list)
    for i = 1, #list - 1 do
        local j = love.math.random(i, #list)
        list[i], list[j] = list[j], list[i]
    end
end

function util.tableDeepCopy(tbl)
    if type(tbl) == "table" then 
        local ret = {}
        for k, v in pairs(tbl) do 
            ret[k] = util.tableDeepCopy(v)
        end
    else
        return v
    end
end

return util
