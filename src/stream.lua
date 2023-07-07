
local op = require 'operator'

local stream = {}

local empty_stream = {}

setmetatable (empty_stream, {
    __index = {
        totable = function (S, tbl) return tbl end,
        isempty = function (S) return true end,
    }
})

stream.empty = function () return empty_stream end

local stream_mt = {}

function stream.cons (h, t)

    if t then t = op.memoize (t) else t = stream.empty () end

    local S = { head = h, tail = t }
    setmetatable (S, stream_mt)

    return S
end

stream_mt.__call = function (S, n) for i = 1, n or 1 do S = S.tail (S) end return S end

stream_mt.__index = {

    isempty = function (S) return false end,
    totable = function (S, tbl) table.insert (tbl, S.head); return S ():totable (tbl) end,
    take = function (S, n)
        if n == 0 then return nil
        else return stream.cons (S.head, 
                         function () 
                            local m = n - 1
                            if m == 0 then return stream.empty ()
                            else return S ():take (m) end
                         end) 
        end
    end,
    map = function (S, f) return stream.cons (f (S.head), function () return S ():map (f) end) end,
    zip = function (S, R, f) return stream.cons (f (S.head, R.head), function () return S ():zip (R (), f) end) end,
    at = function (S, i) return S (i - 1).head end,
    filter = function (S, p)
        local v = S.head
        if p (v) then return stream.cons (v, function () return S ():filter (p) end)
        else return S ():filter (p) end

    end
}

function stream.zip_l (F, f) return function (FF) return F:zip (FF, f) end end
function stream.constant () return op.identity end
function stream.iterate (f) return function (S) return stream.cons (f (S.head), stream.iterate (f)) end end
function stream.from (by) return function (S) return stream.cons (S.head + by, stream.from (by)) end end
function stream.gibs (by) return function (F) return stream.cons (F.head + by, stream.zip_l (F, op.add)) end end



return stream