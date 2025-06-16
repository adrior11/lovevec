--[[
lovevec – 2-D vector helpers for Lua / LÖVE
--]]

---@version >5.3, JIT
---@class Vec
---@field x number
---@field y number
---@operator len: number
---@operator add: Vec
---@operator sub: Vec
---@operator mul: Vec
---@operator div: Vec
---@operator unm: Vec
local Vec = {}
Vec.__index = Vec

-- Metadata
Vec._NAME = "lovevec"
Vec._VERSION = "dev"
Vec._DESCRIPTION = "2D Lua vector library with geometry, LÖVE helpers and debug checks"
Vec._URL = "https://github.com/adrior11/lovevec"
Vec._LICENSE = [[
    MIT License

    Copyright (c) 2025 Adrian Schneider

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
]]

---Epsilon for floating-point comparisons (32-bit).
---@type number
Vec._EPS = 1e-7

---Debug flag: when true, perform runtime type checks.
---@type boolean
Vec._DEBUG = false

---Enable or disable debug mode (argument validation).
---@param enabled boolean
function Vec.enable_debug(enabled)
  Vec._DEBUG = enabled and true or false
end

---Default string format for Vec instances.
---@type string
Vec._FMT = "Vec(%.2f, %.2f)"

---Change the default format used by `tostring(v)` / `v:format()`.
---@param fmt string printf-style format containing exactly two numeric slots.
---## Example
--[[
```lua
    local fmt = "Vec[%.0f;%.0f]"
    Vec.set_format(fmt)
    local v = Vec(1.4, 2.6)
    print(tostring(v)) -- Output: Vec[1;3]
```
]]
function Vec.set_format(fmt)
  if type(fmt) ~= "string" then
    error("set_format expects a string, got " .. type(fmt), 2)
  end
  Vec._FMT = fmt
end

-- Cache math functions to avoid table lookups
local cos, sin, abs, sqrt, floor, ceil, atan2, acos =
  math.cos, math.sin, math.abs, math.sqrt, math.floor, math.ceil, math.atan2, math.acos

-- Internal helpers ------------------------------------------------------------

---@package
---@param v any
---@return boolean
local function is_vec(v)
  return getmetatable(v) == Vec
end

---@package
---@param v any
---@param fn string
---@param idx? number
local function assert_vec(v, fn, idx)
  if not is_vec(v) then
    error(string.format("bad argument #%d to '%s' (Vec expected, got %s)", idx or 1, fn, type(v)), 3)
  end
end

---@package
---@param n any
---@param fn string
---@param idx? number
local function assert_num(n, fn, idx)
  if type(n) ~= "number" or n ~= n or n == math.huge or n == -math.huge then
    error(string.format("bad argument #%d to '%s' (finite number expected, got %s)", idx or 1, fn, tostring(n)), 3)
  end
end

---@package
---@return number
local function _random()
  if love and love.math and love.math.random then
    return love.math.random()
  end
  return math.random()
end

---@package
---@param v number
---@param min number
---@param max number
---@return number
local function _clamp(v, min, max)
  if min > max then
    error("min cannot be greater than max", 3)
  end
  if v < min then
    return min
  elseif v > max then
    return max
  else
    return v
  end
end

---@package
---@param n number
---@return number
local function _round(n)
  return n >= 0 and floor(n + 0.5) or ceil(n - 0.5)
end

-- Constructors ----------------------------------------------------------------

setmetatable(Vec, {
  __call = function(_, ...)
    return Vec.new(...)
  end,
  __metatable = false,
})

---Create a new Vec.
---@param x? number X component (default = 0)
---@param y? number Y component (default = 0)
---@return Vec
function Vec.new(x, y)
  if Vec._DEBUG then
    if x ~= nil then
      assert_num(x, "new", 1)
    end
    if y ~= nil then
      assert_num(y, "new", 2)
    end
  end
  return setmetatable({ x = x or 0, y = y or 0 }, Vec)
end

---Construct a Vec from a table (either array-style or key-style).
---If both presentations are given the named keys win.
---@param t table {number,number} or {x = number, y = number}
---@return Vec
---## Example
--[[
```lua
    local v1 = Vec.from_table({ 3, 4 }) -- array-style
    local v2 = Vec.from_table({ x = 5, y = 6 }) -- key-style
    local v3 = Vec.from_table({ 7, y = 8 }) -- mixed style
```
]]
function Vec.from_table(t)
  if Vec._DEBUG then
    if type(t) ~= "table" then
      error("from_table expects a table, got " .. type(t), 2)
    end
  end
  local x = t.x ~= nil and t.x or t[1]
  local y = t.y ~= nil and t.y or t[2]
  if Vec._DEBUG then
    assert_num(x, "from_table", 1)
    assert_num(y, "from_table", 2)
  end
  return Vec.new(x, y)
end

---Construct a Vec from polar coordinates in clock-wise order.
---(Assumes +y is down i.e., screen space in clockwise order)
---@param r number radius
---@param a number angle in radians
---@return Vec
function Vec.from_polar(r, a)
  if Vec._DEBUG then
    assert_num(r, "from_polar", 1)
    assert_num(a, "from_polar", 2)
  end
  return Vec.new(r * cos(a), r * sin(a))
end

---Construct a Vec from polar coordinates in degrees.
---(Assumes +y is down i.e., screen space)
---@param r number radius
---@param deg number angle in degrees
---@return Vec
function Vec.from_polar_deg(r, deg)
  if Vec._DEBUG then
    assert_num(r, "from_polar_deg", 1)
    assert_num(deg, "from_polar_deg", 2)
  end
  local rad = deg * math.pi / 180
  return Vec.from_polar(r, rad)
end

---Creates a random Vec with a uniform distribution on a circle.
---(Uses `love.math.random` if available, otherwise `math.random`)
---
---It utilizes its inner Vec._EPS to determine if the radius is effectively zero.
---You can adjust the precision by setting `Vec._EPS`.
---@param r? number radius (default = 1)
---@return Vec
function Vec.random(r)
  if Vec._DEBUG and r ~= nil then
    assert_num(r, "random")
  end
  r = r or 1
  if r < 0 then
    error("radius must be non-negative", 2)
  end
  if r < Vec._EPS then
    return Vec.new()
  end
  return Vec.from_polar(r, _random() * math.pi * 2)
end

---Accumulate multiple Vecs into a single Vec, allowing nil arguments.
---Useful for summing up multiple vectors, e.g., forces or velocities.
---@param ... Vec|nil
---@return Vec
--- ## Example
--[[
```lua
    local v1 = Vec(1, 2)
    local v2 = nil
    local v3 = Vec(5, 6)
    local result = Vec.acc(v1, v2, v3)  -- result = Vec(6, 8)
    local empty = Vec.acc()  -- empty = Vec(0, 0)
```
]]
function Vec.acc(...)
  local n = select("#", ...)
  if n == 0 then
    return Vec.new()
  end
  local x, y = 0, 0
  for i = 1, n do
    local v = select(i, ...)
    if v ~= nil then
      if Vec._DEBUG then
        assert_vec(v, "acc", i)
      end
      x = x + v.x
      y = y + v.y
    end
  end
  return Vec.new(x, y)
end

-- Constants -------------------------------------------------------------------

Vec.zero = Vec.new(0, 0)
Vec.one = Vec.new(1, 1)
Vec.left = Vec.new(-1, 0)
Vec.right = Vec.new(1, 0)
Vec.up = Vec.new(0, 1)
Vec.down = Vec.new(0, -1)

-- Core utilities --------------------------------------------------------------

---Return a string representation of this Vec.
---@param fmt? string If nil, uses `Vec._FMT`.
---@return string
function Vec:format(fmt)
  return string.format(fmt or Vec._FMT, self.x, self.y)
end

---Create a shallow copy of this Vec.
---@return Vec
function Vec:clone()
  return Vec.new(self.x, self.y)
end

---Return x and y components.
---@return number, number
function Vec:unpack()
  return self.x, self.y
end

---Return a table with x and y components.
---@return table
function Vec:to_table()
  return { self.x, self.y }
end

---Manhattan length (L1 norm).
---@return number
function Vec:length_manhattan()
  return abs(self.x) + abs(self.y)
end

---Squared length.
---@return number
function Vec:length_squared()
  return self.x * self.x + self.y * self.y
end

---Length (magnitude).
---@return number
function Vec:length()
  return sqrt(self.x * self.x + self.y * self.y)
end

---Dot product.
---@param o Vec
---@return number
function Vec:dot(o)
  if Vec._DEBUG then
    assert_vec(o, "dot")
  end
  return self.x * o.x + self.y * o.y
end

---Cross product (z-component).
---@param o Vec
---@return number
function Vec:cross(o)
  if Vec._DEBUG then
    assert_vec(o, "cross")
  end
  return self.x * o.y - self.y * o.x
end

---Return a normalized copy of this Vec.
---
---It utilizes its inner Vec._EPS to determine if the length is effectively zero.
---You can adjust the precision by setting `Vec._EPS`.
---@return Vec
function Vec:normalize()
  local len = self:length()
  if len < Vec._EPS then
    return Vec.new()
  end
  return Vec.new(self.x / len, self.y / len)
end

---Normalize in-place (no-op if near zero).
---
---It utilizes its inner Vec._EPS to determine if the length is effectively zero.
---You can adjust the precision by setting `Vec._EPS`.
---@return self
function Vec:normalize_()
  local len = self:length()
  if len >= Vec._EPS then
    self.x = self.x / len
    self.y = self.y / len
  end
  return self
end

---Return a perpendicular copy of this Vec.
---(Assumes +y is down i.e., screen space in clockwise order)
---@return Vec
function Vec:perp()
  return Vec.new(-self.y, self.x)
end

---Return the perpendicular of this Vec.
---(Assumes +y is down i.e., screen space in clockwise order)
---@return Vec
function Vec:perp_()
  local x = self.x
  self.x = -self.y
  self.y = x
  return self
end

---Return the projection of this Vec onto another Vec.
---
---It utilizes its inner Vec._EPS to determine if the length is effectively zero.
---You can adjust the precision by setting `Vec._EPS`.
---@param o Vec
---@return Vec
function Vec:project(o)
  if Vec._DEBUG then
    assert_vec(o, "project")
  end
  local nn = o:length_squared()
  if nn < Vec._EPS then
    return Vec.new()
  end
  local s = self:dot(o) / nn
  return Vec.new(o.x * s, o.y * s)
end

---Project this Vec onto another Vec.
---
---It utilizes its inner Vec._EPS to determine if the length is effectively zero.
---You can adjust the precision by setting `Vec._EPS`.
---@param o Vec
---@return self
function Vec:project_(o)
  if Vec._DEBUG then
    assert_vec(o, "project_")
  end
  local nn = o:length_squared()
  if nn < Vec._EPS then
    self.x = 0
    self.y = 0
    return self
  end
  local s = self:dot(o) / nn
  self.x = o.x * s
  self.y = o.y * s
  return self
end

---Return the rejection of this Vec onto another Vec.
---@param o Vec
---@return Vec
function Vec:reject(o)
  if Vec._DEBUG then
    assert_vec(o, "reject")
  end
  return self - self:project(o)
end

---Reject this Vec onto another Vec.
---@param o Vec
---@return self
function Vec:reject_(o)
  if Vec._DEBUG then
    assert_vec(o, "reject_")
  end
  local proj = self:project(o)
  self.x = self.x - proj.x
  self.y = self.y - proj.y
  return self
end

---Clamp this Vec between two other Vecs.
---@param min Vec
---@param max Vec
---@return Vec
function Vec:clamp(min, max)
  if Vec._DEBUG then
    assert_vec(min, "clamp", 1)
    assert_vec(max, "clamp", 2)
  end
  return Vec.new(_clamp(self.x, min.x, max.x), _clamp(self.y, min.y, max.y))
end

---Clamp this Vec in-place between two other.
---@param min Vec
---@param max Vec
---@return self
function Vec:clamp_(min, max)
  if Vec._DEBUG then
    assert_vec(min, "clamp_", 1)
    assert_vec(max, "clamp_", 2)
  end
  self.x = _clamp(self.x, min.x, max.x)
  self.y = _clamp(self.y, min.y, max.y)
  return self
end

---Limit this Vec to a maximum length.
---
---It utilizes its inner Vec._EPS to determine if the length is effectively zero.
---You can adjust the precision by setting `Vec._EPS`.
---@param maxlen number
---@return Vec
function Vec:limit(maxlen)
  if Vec._DEBUG then
    assert_num(maxlen, "limit")
  end
  if maxlen < Vec._EPS then
    return Vec.new()
  end
  local l = self:length()
  return l > maxlen and self:mul(maxlen / l) or self:clone()
end

---Limit this Vec in-place to a maximum length.
---
---It utilizes its inner Vec._EPS to determine if the length is effectively zero.
---You can adjust the precision by setting `Vec._EPS`.
---@param maxlen number
---@return self
function Vec:limit_(maxlen)
  if Vec._DEBUG then
    assert_num(maxlen, "limit_")
  end
  if maxlen < Vec._EPS then
    self.x = 0
    self.y = 0
    return self
  end
  local l = self:length()
  if l > maxlen then
    self:mul_(maxlen / l)
  end
  return self
end

---Linearly interpolate between this Vec and another Vec.
---@param o Vec
---@param t number interpolation factor (0 => self, 1 => o)
---@return Vec
function Vec:lerp(o, t)
  if Vec._DEBUG then
    assert_vec(o, "lerp", 1)
    assert_num(t, "lerp", 2)
  end
  return Vec.new(self.x + (o.x - self.x) * t, self.y + (o.y - self.y) * t)
end

---Linearly interpolate this Vec in-place towards another Vec.
---@param o Vec
---@param t number interpolation factor (0 => self, 1 => o)
---@return self
function Vec:lerp_(o, t)
  if Vec._DEBUG then
    assert_vec(o, "lerp_", 1)
    assert_num(t, "lerp_", 2)
  end
  self.x = self.x + (o.x - self.x) * t
  self.y = self.y + (o.y - self.y) * t
  return self
end

---Return a copy of this Vec rounded to the nearest integer.
---@return Vec
function Vec:round()
  return Vec.new(_round(self.x), _round(self.y))
end

---Round this Vec in-place to the nearest integer.
---@return self
function Vec:round_()
  self.x = _round(self.x)
  self.y = _round(self.y)
  return self
end

---Return a copy of this Vec rounded down to the nearest integer.
---@return Vec
function Vec:floor()
  return Vec.new(floor(self.x), floor(self.y))
end

---Round this Vec in-place down to the nearest integer.
---@return self
function Vec:floor_()
  self.x = floor(self.x)
  self.y = floor(self.y)
  return self
end

---Return a copy of this Vec rounded up to the nearest integer.
---@return Vec
function Vec:ceil()
  return Vec.new(ceil(self.x), ceil(self.y))
end

---Round this Vec in-place up to the nearest integer.
---@return self
function Vec:ceil_()
  self.x = ceil(self.x)
  self.y = ceil(self.y)
  return self
end

---Return a copy of this Vec with swapped x and y components.
---@return Vec
function Vec:swap()
  return Vec.new(self.y, self.x)
end

---Swap x and y components in-place.
---@return self
function Vec:swap_()
  self.x, self.y = self.y, self.x
  return self
end

---Return a copy of this Vec rotated around a pivot (default origin) by radians.
---(Assumes +y is down i.e., screen space in clockwise order)
---@param theta number
---@param pivot? Vec
---@return Vec
function Vec:rotate(theta, pivot)
  if Vec._DEBUG then
    assert_num(theta, "rotate", 1)
    if pivot ~= nil then
      assert_vec(pivot, "rotate", 2)
    end
  end
  pivot = pivot or Vec.zero
  local s, c = sin(theta), cos(theta)
  local tx, ty = self.x - pivot.x, self.y - pivot.y
  return Vec.new(tx * c - ty * s + pivot.x, -tx * s + ty * c + pivot.y)
end

---Rotate this Vec in-place around pivot (default origin) by radians.
---(Assumes +y is down i.e., screen space in clockwise order)
---@param theta number
---@param pivot? Vec
---@return self
function Vec:rotate_(theta, pivot)
  if Vec._DEBUG then
    assert_num(theta, "rotate_", 1)
    if pivot ~= nil then
      assert_vec(pivot, "rotate_", 2)
    end
  end
  pivot = pivot or Vec.zero
  local s, c = sin(theta), cos(theta)
  local tx, ty = self.x - pivot.x, self.y - pivot.y
  self.x = tx * c - ty * s + pivot.x
  self.y = -tx * s + ty * c + pivot.y
  return self
end

---Return a copy of this Vec reflected against a normal Vec.
---
---It utilizes its inner Vec._EPS to determine if the length is effectively zero.
---You can adjust the precision by setting `Vec._EPS`.
---@param n Vec
---@return Vec
function Vec:reflect(n)
  if Vec._DEBUG then
    assert_vec(n, "reflect")
  end
  local dn = self:dot(n)
  local nn = n:length_squared()
  if nn < Vec._EPS then
    return self:clone()
  end
  local f = 2 * dn / nn
  return Vec.new(self.x - f * n.x, self.y - f * n.y)
end

---Reflect this Vec in-place against a normal Vec.
---
---It utilizes its inner Vec._EPS to determine if the length is effectively zero.
---You can adjust the precision by setting `Vec._EPS`.
---@param n Vec
---@return self
function Vec:reflect_(n)
  if Vec._DEBUG then
    assert_vec(n, "reflect_")
  end
  local dn = self:dot(n)
  local nn = n:length_squared()
  if nn >= Vec._EPS then
    local f = 2 * dn / nn
    self.x = self.x - f * n.x
    self.y = self.y - f * n.y
  end
  return self
end

---Distance to another Vec.
---@param o Vec
---@return number
function Vec:distance(o)
  if Vec._DEBUG then
    assert_vec(o, "distance")
  end
  return (self - o):length()
end

---Manhattan distance to another Vec.
---@param o Vec
---@return number
function Vec:distance_manhattan(o)
  if Vec._DEBUG then
    assert_vec(o, "distance_manhattan")
  end
  return abs(self.x - o.x) + abs(self.y - o.y)
end

---Return the angle between this Vec and another Vec, in radians.
---@param o Vec
---@return number
function Vec:angle(o)
  if Vec._DEBUG then
    assert_vec(o, "angle")
  end
  return atan2(self:cross(o), self:dot(o))
end

---Return the angle of this Vec with respect to the x-axis, in radians.
---@return number
function Vec:angle_of()
  return atan2(self.y, self.x)
end

---Return the unsigned angle between this Vec and another Vec, in radians.
---
---It utilizes its inner Vec._EPS to determine if the length is effectively zero.
---You can adjust the precision by setting `Vec._EPS`.
---@param o any
---@return number
function Vec:angle_to(o)
  if Vec._DEBUG then
    assert_vec(o, "angle_to")
  end
  local dot = self:dot(o)
  local len = self:length() * o:length()
  if len < Vec._EPS then
    return 0
  end
  -- clamp to avoid NaN from rounding errors
  local c = _clamp(dot / len, -1, 1)
  return acos(c)
end

---Approximate equality.
---@param o Vec
---@param eps? number tolerance (default = 1e-7)
---@return boolean
function Vec:eq(o, eps)
  if Vec._DEBUG then
    assert_vec(o, "eq", 1)
    if eps ~= nil then
      assert_num(eps, "eq", 2)
    end
  end
  eps = eps or Vec._EPS
  return abs(self.x - o.x) < eps and abs(self.y - o.y) < eps
end

---Exact component-wise check.
---@param o Vec
---@return boolean
function Vec:strict_eq(o)
  if Vec._DEBUG then
    assert_vec(o, "strict_eq", 1)
  end
  return self.x == o.x and self.y == o.y
end

-- Arithmetics ----------------------------------------------------------------

---Return a copy of this Vec added to another Vec.
---@param o Vec
---@return Vec
function Vec:add(o)
  if Vec._DEBUG then
    assert_vec(o, "add")
  end
  return Vec.new(self.x + o.x, self.y + o.y)
end

---Add this Vec in-place to another Vec.
---@param o Vec
---@return self
function Vec:add_(o)
  if Vec._DEBUG then
    assert_vec(o, "add_")
  end
  self.x = self.x + o.x
  self.y = self.y + o.y
  return self
end

---Return a copy of this Vec subtracted by another Vec.
---@param o Vec
---@return Vec
function Vec:sub(o)
  if Vec._DEBUG then
    assert_vec(o, "sub")
  end
  return Vec.new(self.x - o.x, self.y - o.y)
end

---Subtract this Vec in-place by another Vec.
---@param o Vec
---@return self
function Vec:sub_(o)
  if Vec._DEBUG then
    assert_vec(o, "sub_")
  end
  self.x = self.x - o.x
  self.y = self.y - o.y
  return self
end

---Return a copy of this Vec multiplied by a scalar.
---@param scalar number
---@return Vec
function Vec:mul(scalar)
  if Vec._DEBUG then
    assert_num(scalar, "mul")
  end
  return Vec.new(self.x * scalar, self.y * scalar)
end

---Multiply this Vec in-place by a scalar.
---@param scalar number
---@return self
function Vec:mul_(scalar)
  if Vec._DEBUG then
    assert_num(scalar, "mul_")
  end
  self.x = self.x * scalar
  self.y = self.y * scalar
  return self
end

---Return a copy of this Vec multiplied by another Vec component-wise.
---@param o Vec
---@return Vec
function Vec:mulv(o)
  if Vec._DEBUG then
    assert_vec(o, "mulv")
  end
  return Vec.new(self.x * o.x, self.y * o.y)
end

---Multiply this Vec in-place by another Vec component-wise.
---@param o Vec
---@return Vec
function Vec:mulv_(o)
  if Vec._DEBUG then
    assert_vec(o, "mulv_")
  end
  self.x = self.x * o.x
  self.y = self.y * o.y
  return self
end

---Return a copy of this Vec divided by a number.
---@param o number
---@return Vec
function Vec:div(o)
  if Vec._DEBUG then
    assert_num(o, "div")
  end
  if o == 0 then
    error("division by zero", 2)
  end
  return Vec.new(self.x / o, self.y / o)
end

---Divide this Vec in-place by a number.
---@param o number
---@return self
function Vec:div_(o)
  if Vec._DEBUG then
    assert_num(o, "div_")
  end
  if o == 0 then
    error("division by zero", 2)
  end
  self.x = self.x / o
  self.y = self.y / o
  return self
end

---Return a copy of this Vec negated (multiplied by -1).
---@return Vec
function Vec:neg()
  return Vec.new(-self.x, -self.y)
end

---Negate this Vec in-place (multiply by -1).
---@return self
function Vec:neg_()
  self.x = -self.x
  self.y = -self.y
  return self
end

-- LÖVE bridges ---------------------------------------------------------------

if love then
  ---Create a Vec from the current mouse position.
  ---@return Vec
  function Vec.from_mouse()
    return Vec(love.mouse.getPosition())
  end

  ---Get the distance from this Vec to the current mouse position.
  ---@return number
  function Vec:mouse_distance()
    return self:distance(Vec.from_mouse())
  end

  ---Translate the current coordinate system relative to this Vec.
  function Vec:translate()
    love.graphics.translate(self.x, self.y)
  end
end

-- Metamethods ----------------------------------------------------------------

---@param v Vec
function Vec.__tostring(v)
  return v:format()
end

---@version >5.2
---@param v Vec
function Vec.__len(v)
  return v:length()
end

---@param a Vec
---@param b Vec
function Vec.__add(a, b)
  return a:add(b)
end

---@param a Vec
---@param b Vec
function Vec.__sub(a, b)
  return a:sub(b)
end

---@param a Vec
---@param b number
function Vec.__mul(a, b)
  if is_vec(a) and is_vec(b) then
    return a:mulv(b)
  elseif is_vec(a) and type(b) == "number" then
    if Vec._DEBUG then
      assert_num(b, "__mul", 2)
    end
    return a:mul(b)
  elseif type(a) == "number" and is_vec(b) then
    if Vec._DEBUG then
      assert_num(a, "__mul", 1)
    end
    ---@diagnostic disable-next-line: undefined-field
    return b:mul(a)
  else
    error("bad operands to '*' (expected (Vec,Vec), (Vec,number) or (number,Vec))", 2)
  end
end

---@param a Vec
---@param b number
function Vec.__div(a, b)
  if Vec._DEBUG then
    assert_num(b, "__div", 2)
  end
  return a:div(b)
end

---@param v Vec
function Vec.__unm(v)
  return v:neg()
end

---@param a Vec
---@param b Vec
function Vec.__eq(a, b)
  return a:strict_eq(b)
end

do
  -- override __index to allow Vec[1] and Vec[2] for x and y for convenience sugar
  local old_index = Vec.__index
  function Vec.__index(tbl, key)
    if key == 1 then
      return rawget(tbl, "x")
    end
    if key == 2 then
      return rawget(tbl, "y")
    end
    return old_index[key]
  end
end

return Vec
