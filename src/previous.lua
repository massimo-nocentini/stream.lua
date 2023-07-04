
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

stream_mt.__call = function (S, n, ...) for i = 1, n or 1 do S = S.tail (S, ...) end return S end

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
    at = function (S, i) return S (i - 1).head end,
    filter = function (S, p)
        local v = S.head
        if p (v) then return cons (v, function () return S ():filter (p) end)
        else return S ():filter (p) end

    end
}

local function zip_l (F, f) return function (FF) return F:zip (FF, f) end end

local function constant () return op.identity end
local function iterate (f) return function (S) return cons (f (S.head), iterate (f)) end end
local function from (by) return function (S) return cons (S.head + by, from (by)) end end
local function gibs (by) return function (F) return cons (F.head + by, zip_l (F, op.add)) end end

local C = os.clock ()

local ones = cons (1, constant ())

local fibs = cons (0, gibs (1))

print (ones.head)
print (ones ().head)

local tbl = ones:take (10):totable {}

op.print_table (tbl)

local S = cons (4, from (-1)):map (function (v) if v == 0 then error 'cannot divide by 0' else return 1 / v end end):take (4)

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

local nats = cons (0, iterate (op.add_r (1)))
op.print_table (nats:take(30):totable {})


local function sieve (S)
    local P = function (R) return sieve (S ():filter (function (n) return n % R.head > 0 end)) end
    return cons (S.head, P)
end

local primes = sieve (cons (2, from (1)))

op.print_table (primes:take(500):totable {})

print ('seconds: ', os.clock () - C)