-----------------------------------------------------------------------
-- vec_bench.lua  –  measure debug-flag overhead
-----------------------------------------------------------------------
local Vec = require("src.lovevec")

local ITER = 1000000 -- 1e6 iterations ≈ 40-100 ms on LuaJIT

local function bench(flag)
  Vec.enable_debug(flag)
  collectgarbage()
  collectgarbage() -- clear any cruft

  local t0 = os.clock()
  local acc = Vec.zero -- running sum keeps work “alive”

  for _ = 1, ITER do
    local v = Vec.random(10) -- alloc + trig
    acc = acc + v:normalize() -- dot math, create result Vec
  end

  local dt = os.clock() - t0
  return dt, acc
end

-- warm up JIT first (LuaJIT only)
bench(false)

local t_dbg, _ = bench(true)
local t_rel, _ = bench(false)

print(string.format("ITERATIONS      : %d", ITER))
print(string.format("DEBUG  ON  time : %.3f sec", t_dbg))
print(string.format("DEBUG  OFF time : %.3f sec", t_rel))
print(string.format("Relative cost (ON/OFF)        : %.1f%%", (t_dbg / t_rel - 1) * 100))
