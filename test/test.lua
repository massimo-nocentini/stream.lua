

local lu = require 'luaunit'
local stream = require 'stream'

local ones = stream.cons (1, stream.constant ())
local fibs = stream.cons (0, stream.gibs (1))


Test_stream = {}

function Test_stream:test_ones ()

    lu.assertEquals (ones.head, 1)
    lu.assertEquals (ones ().head, 1)
    lu.assertEquals (ones:take (10):totable {}, {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, })
end


local S = stream.cons (4, stream.from (-1)):map (function (v) if v == 0 then error 'cannot divide by 0' else return 1 / v end end):take (4)

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

local nats = stream.cons (0, stream.iterate (op.add_r (1)))
op.print_table (nats:take(30):totable {})


local function sieve (S)
    local P = function (R) return sieve (S ():filter (function (n) return n % R.head > 0 end)) end
    return stream.cons (S.head, P)
end

local primes = sieve (stream.cons (2, stream.from (1)))

op.print_table (primes:take(500):totable {})





local C = os.clock ()

local ret = lu.LuaUnit.run()

print ('seconds: ', os.clock () - C)

os.exit(ret)