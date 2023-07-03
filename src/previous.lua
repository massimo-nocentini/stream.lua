
local op = require 'operator'

local stream_mt = {}

local empty_stream = {}

setmetatable (empty_stream, {
    __index = {
        totable = function (S, tbl) return tbl end,
    }
})

local function isempty (S) return S == empty_stream end

local function cons (h, t)

    if t then t = op.memoize (t) else t = empty_stream end

    local S = { head = h, tail = t }
    setmetatable (S, stream_mt)

    return S
end

stream_mt.__call = function (S, ...) return S.tail (S, ...) end

stream_mt.__index = {

    totable = function (S, tbl)
        table.insert (tbl, S.head)
        return S ():totable (tbl)
    end,
    take = function (S, n)

        if n == 0 then return nil
        else return cons (S.head, 
                         function () 
                            local m = n - 1
                            if m == 0 then return empty_stream
                            else return S ():take (m) end
                         end) 
        end
    end,
    map = function (S, f) return cons (f (S.head), function () return S ():map (f) end) end,
    zip = function (S, R, f) return cons (f (S.head, R.head), function () return S ():zip (R (), f) end) end,
    at = function (S, i)

        while i > 1 do 
            S = S ()
            i = i - 1
        end

        return S.head
    end,
    filter = function (S, p)
        local v = S.head
        if p (v) then return cons (v, function () return S ():filter (p) end)
        else return S ():filter (p) end

    end
}

local function iterate (f)
    return function (v)
        return cons (v, function (S) return iterate (f) (f (S.head)) end) 
    end 
end

local function constant (v) return cons (v, op.identity) end

local function from (v, by) return cons (v, function (S) return from (S.head + by, by) end) end

local C = os.clock ()

local ones = constant (1)

local fibs = cons (0, function (F) return cons (F.head + 1, function (FF) return F:zip (FF, op.add) end) end)

print (ones.head)
print (ones ().head)

local tbl = ones:take (10):totable {}

op.print_table (tbl)

local S = from (4, -1):map (function (v) if v == 0 then error 'cannot divide by 0' else return 1 / v end end):take (4)

print '---'
print (S.head)
print (S ().head)
print (S () ().head)
print (S () () ().head)
print (S:at (4))
print '---'

op.print_table (S:totable {})

op.print_table (fibs:take(30):totable {})

print (fibs:at (30))

local nats = iterate (op.add_r (1)) (0)
op.print_table (nats:take(30):totable {})


local function P (S)
    return cons (S.head, function (R) return P (S ():filter (function (n) return n % R.head > 0 end)) end)
end

local primes = P (from (2, 1))

op.print_table (primes:take(500):totable {})

print ('seconds: ', os.clock () - C)