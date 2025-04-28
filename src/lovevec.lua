--[[
lovevec - 2D vector helpers for Lua / LÖVE
--]]

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
Vec._DESCRIPTION = "2D Lua vector library with geometry, LÖVE helpers & debug checks"
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

-- Epsilon for floating-point comparisons (32-bit)
local EPS = 1e-7
Vec.EPS = EPS -- expose so users can tweak at runtime

-- Debug flag: when true, perform runtime type checks
---@type boolean
Vec._DEBUG = false

---Enable or disable debug mode (argument validation)
---@param enabled boolean
function Vec.enable_debug(enabled)
  Vec._DEBUG = enabled and true or false
end

-- Cache math functions to avoid table lookups
local cos, sin, abs, sqrt, floor, ceil, atan2 =
  math.cos, math.sin, math.abs, math.sqrt, math.floor, math.ceil, math.atan2

-- Internal helpers ------------------------------------------------------------

---@private
---@param v any
---@return boolean
local function is_vec(v)
  return getmetatable(v) == Vec
end

---@private
---@param v any
---@param fn string
---@param idx? number
local function assert_vec(v, fn, idx)
  if not is_vec(v) then
    error(string.format("bad argument #%d to '%s' (Vec expected, got %s)", idx or 1, fn, type(v)), 3)
  end
end

---@private
---@param n any
---@param fn string
---@param idx? number
local function assert_num(n, fn, idx)
  if type(n) ~= "number" then
    error(string.format("bad argument #%d to '%s' (number expected, got %s)", idx or 1, fn, type(n)), 3)
  end
end

---@private
---@return number
local function random()
  if love and love.math and love.math.random then
    return love.math.random()
  end
  return math.random()
end

---@private
---@param v number
---@param min number
---@param max number
---@return number
local function clamp(v, min, max)
  if Vec._DEBUG then
    assert_num(v, "clamp", 1)
    assert_num(min, "clamp", 2)
    assert_num(max, "clamp", 3)
  end
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

-- Construction ----------------------------------------------------------------

setmetatable(Vec, {
  __call = function(_, ...)
    return Vec.new(...)
  end,
  -- __metatable = false,
})

---Create a new Vec
---@param x? number X component (default = 0)
---@param y? number Y component (default = 0)
---@return Vec
function Vec.new(x, y)
  if Vec._DEBUG then
    if x ~= nil and type(x) ~= "number" then
      error("x must be a number", 2)
    end
    if y ~= nil and type(y) ~= "number" then
      error("y must be a number", 2)
    end
  end
  return setmetatable({ x = x or 0, y = y or 0 }, Vec)
end

function Vec.from_table(t)
  if Vec._DEBUG then
    if type(t) ~= "table" or #t < 2 then
      error("from_table expects {x,y}", 2)
    end
    assert_num(t[1], "from_table", 2)
    assert_num(t[2], "from_table", 3)
  end
  return Vec.new(t[1], t[2])
end

---Construct a Vec from polar coordinates in clock-wise order
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

---Creates a random Vec with a uniform distribution over the unit circle
---(Uses `love.math.random` if available, otherwise `math.random`)
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
  if r < Vec.EPS then
    return Vec.new()
  end
  return Vec.from_polar(r, random() * math.pi * 2)
end

-- Constants -------------------------------------------------------------------

Vec.zero = setmetatable({ x = 0, y = 0 }, Vec)
Vec.one = setmetatable({ x = 1, y = 1 }, Vec)
Vec.left = setmetatable({ x = -1, y = 0 }, Vec)
Vec.right = setmetatable({ x = 1, y = 0 }, Vec)
Vec.up = setmetatable({ x = 0, y = -1 }, Vec)
Vec.down = setmetatable({ x = 0, y = 1 }, Vec)

-- Core utilities --------------------------------------------------------------

---Create a shallow copy of this Vec
---@return Vec
function Vec:clone()
  return Vec.new(self.x, self.y)
end

---Return x and y components
---@return number, number
function Vec:unpack()
  return self.x, self.y
end

---Return a table with x and y components
---@return table
function Vec:to_table()
  return { self.x, self.y }
end

---Manhattan length (L1 norm)
---@return number
function Vec:length_manhattan()
  return abs(self.x) + abs(self.y)
end

---Squared length (avoids sqrt)
---@return number
function Vec:length_squared()
  return self.x * self.x + self.y * self.y
end

---Length (magnitude)
---@return number
function Vec:length()
  return sqrt(self.x * self.x + self.y * self.y)
end

---Dot product
---@param o Vec
---@return number
function Vec:dot(o)
  if Vec._DEBUG then
    assert_vec(o, "dot")
  end
  return self.x * o.x + self.y * o.y
end

---Cross product (z-component)
---@param o Vec
---@return number
function Vec:cross(o)
  if Vec._DEBUG then
    assert_vec(o, "cross")
  end
  return self.x * o.y - self.y * o.x
end

---Return a normalized copy of this Vec
---@return Vec
function Vec:normalize()
  local len = self:length()
  if len < Vec.EPS then
    return Vec.new()
  end
  return Vec.new(self.x / len, self.y / len)
end

---Normalize in-place (no-op if near zero)
---@return self
function Vec:normalize_mut()
  local len = self:length()
  if len >= Vec.EPS then
    self.x = self.x / len
    self.y = self.y / len
  end
  return self
end

---Return a scaled copy of this Vec
---@param scalar number
---@return Vec
function Vec:scale(scalar)
  if Vec._DEBUG then
    if type(scalar) ~= "number" then
      error("scale expects a number")
    end
    if scalar ~= scalar or scalar == math.huge or scalar == -math.huge then
      error("scalar must be finite", 2)
    end
  end
  return Vec.new(self.x * scalar, self.y * scalar)
end

---Scale this Vec in-place
---@param scalar number
---@return self
function Vec:scale_mut(scalar)
  if Vec._DEBUG then
    if type(scalar) ~= "number" then
      error("scale_mut expects a number")
    end
    if scalar ~= scalar or scalar == math.huge or scalar == -math.huge then
      error("scalar must be finite", 2)
    end
  end
  self.x = self.x * scalar
  self.y = self.y * scalar
  return self
end

---Return a perpendicular copy of this Vec
--- (clock-wise, screen space where +y is down)
---@return Vec
function Vec:perp()
  return Vec(-self.y, self.x)
end

---Return the perpendicular of this Vec
--- (clock-wise, screen space where +y is down)
---@return Vec
function Vec:perp_mut()
  local x = self.x
  self.x = -self.y
  self.y = x
  return self
end

---Return the projection of this Vec onto another Vec
---@param o Vec
---@return Vec
function Vec:project(o)
  if Vec._DEBUG then
    assert_vec(o, "project")
  end
  local nn = o:length_squared()
  if nn < Vec.EPS then
    return Vec.new()
  end
  local s = self:dot(o) / nn
  return Vec(o.x * s, o.y * s)
end

---Project this Vec onto another Vec
---@param o Vec
---@return self
function Vec:project_mut(o)
  if Vec._DEBUG then
    assert_vec(o, "project_mut")
  end
  local nn = o:length_squared()
  if nn < Vec.EPS then
    self.x = 0
    self.y = 0
    return self
  end
  local s = self:dot(o) / nn
  self.x = o.x * s
  self.y = o.y * s
  return self
end

---Return the rejection of this Vec onto another Vec
---@param o Vec
---@return Vec
function Vec:reject(o)
  if Vec._DEBUG then
    assert_vec(o, "reject")
  end
  return self - self:project(o)
end

---Reject this Vec onto another Vec
---@param o Vec
---@return self
function Vec:reject_mut(o)
  if Vec._DEBUG then
    assert_vec(o, "reject_mut")
  end
  local proj = self:project(o)
  self.x = self.x - proj.x
  self.y = self.y - proj.y
  return self
end

---Clamp this Vec between two other Vecs
---@param min Vec
---@param max Vec
---@return Vec
function Vec:clamp(min, max)
  if Vec._DEBUG then
    assert_vec(min, "clamp", 2)
    assert_vec(max, "clamp", 3)
  end
  return Vec(clamp(self.x, min.x, max.x), clamp(self.y, min.y, max.y))
end

---Clamp this Vec in-place between two other
---@param min Vec
---@param max Vec
---@return self
function Vec:clamp_mut(min, max)
  if Vec._DEBUG then
    assert_vec(min, "clamp_mut", 2)
    assert_vec(max, "clamp_mut", 3)
  end
  self.x = clamp(self.x, min.x, max.x)
  self.y = clamp(self.y, min.y, max.y)
  return self
end

---Limit this Vec to a maximum length
---@param maxlen number
---@return Vec
function Vec:limit(maxlen)
  if Vec._DEBUG then
    assert_num(maxlen, "limit")
  end
  if maxlen < Vec.EPS then
    return Vec.new()
  end
  local l = self:length()
  return l > maxlen and self:scale(maxlen / l) or self:clone()
end

---Limit this Vec in-place to a maximum length
---@param maxlen number
---@return self
function Vec:limit_mut(maxlen)
  if Vec._DEBUG then
    assert_num(maxlen, "limit_mut")
  end
  if maxlen < Vec.EPS then
    self.x = 0
    self.y = 0
    return self
  end
  local l = self:length()
  if l > maxlen then
    self:scale_mut(maxlen / l)
  end
  return self
end

---Linearly interpolate between this Vec and another Vec
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

---Linearly interpolate this Vec in-place towards another Vec
---@param o Vec
---@param t number interpolation factor (0 => self, 1 => o)
---@return self
function Vec:lerp_mut(o, t)
  if Vec._DEBUG then
    assert_vec(o, "lerp_mut", 1)
    assert_num(t, "lerp_mut", 2)
  end
  self.x = self.x + (o.x - self.x) * t
  self.y = self.y + (o.y - self.y) * t
  return self
end

---Return a copy of this Vec rounded to the nearest integer
---@return Vec
function Vec:round()
  return Vec(floor(self.x + 0.5), floor(self.y + 0.5))
end

---Round this Vec in-place to the nearest integer
---@return self
function Vec:round_mut()
  self.x = floor(self.x + 0.5)
  self.y = floor(self.y + 0.5)
  return self
end

---Return a copy of this Vec rounded down to the nearest integer
---@return Vec
function Vec:floor()
  return Vec(floor(self.x), floor(self.y))
end

---Round this Vec in-place down to the nearest integer
---@return self
function Vec:floor_mut()
  self.x = floor(self.x)
  self.y = floor(self.y)
  return self
end

---Return a copy of this Vec rounded up to the nearest integer
---@return Vec
function Vec:ceil()
  return Vec(ceil(self.x), ceil(self.y))
end

---Round this Vec in-place up to the nearest integer
---@return self
function Vec:ceil_mut()
  self.x = ceil(self.x)
  self.y = ceil(self.y)
  return self
end

---Return a copy of this Vec rotated (clock-wise, screen space where +y is down)
--- around a pivot (default origin) by radians
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

---Rotate this Vec in-place (clock-wise, screen space where +y is down)
--- around pivot (default origin) by radians
---@param theta number
---@param pivot? Vec
---@return self
function Vec:rotate_mut(theta, pivot)
  if Vec._DEBUG then
    assert_num(theta, "rotate_mut", 1)
    if pivot ~= nil then
      assert_vec(pivot, "pivot", 2)
    end
  end
  pivot = pivot or Vec.zero
  local s, c = sin(theta), cos(theta)
  local tx, ty = self.x - pivot.x, self.y - pivot.y
  self.x = tx * c - ty * s + pivot.x
  self.y = -tx * s + ty * c + pivot.y
  return self
end

---Return a copy of this Vec reflected against a normal Vec
---@param n Vec
---@return Vec
function Vec:reflect(n)
  if Vec._DEBUG then
    assert_vec(n, "reflect")
  end
  local dn = self:dot(n)
  local nn = n:length_squared()
  if nn < Vec.EPS then
    return self:clone()
  end
  local f = 2 * dn / nn
  return Vec.new(self.x - f * n.x, self.y - f * n.y)
end

---Reflect this Vec in-place against a normal Vec
---@param n Vec
---@return self
function Vec:reflect_mut(n)
  if Vec._DEBUG then
    assert_vec(n, "reflect_mut")
  end
  local dn = self:dot(n)
  local nn = n:length_squared()
  if nn >= Vec.EPS then
    local f = 2 * dn / nn
    self.x = self.x - f * n.x
    self.y = self.y - f * n.y
  end
  return self
end

---Distance to another Vec
---@param o Vec
---@return number
function Vec:distance(o)
  if Vec._DEBUG then
    assert_vec(o, "distance")
  end
  return (self - o):length()
end

---Manhattan distance to another Vec
---@param o Vec
---@return number
function Vec:distance_manhattan(o)
  if Vec._DEBUG then
    assert_vec(o, "distance_manhattan")
  end
  return abs(self.x - o.x) + abs(self.y - o.y)
end

---Return the angle between this Vec and another Vec, in radians
---@param o Vec
---@return number
function Vec:angle(o)
  if Vec._DEBUG then
    assert_vec(o, "angle")
  end
  return atan2(self:cross(o), self:dot(o))
end

---Return the angle of this Vec with respect to the x-axis, in radians
---@return number
function Vec:angle_of()
  return atan2(self.y, self.x)
end

---Approximate equality
---@param o Vec
---@param eps? number tolerance (default = 1e-7)
---@return boolean
function Vec:equals(o, eps)
  if Vec._DEBUG then
    assert_vec(o, "equals", 1)
    if eps ~= nil then
      assert_num(eps, "equals", 2)
    end
  end
  eps = eps or Vec.EPS
  return abs(self.x - o.x) < eps and abs(self.y - o.y) < eps
end

-- Arithmetics ----------------------------------------------------------------

---Return a copy of this Vec added to another Vec
---@param o Vec
---@return Vec
function Vec:add(o)
  if Vec._DEBUG then
    assert_vec(o, "add")
  end
  return Vec.new(self.x + o.x, self.y + o.y)
end

---Add this Vec in-place to another Vec
---@param o Vec
---@return self
function Vec:add_mut(o)
  if Vec._DEBUG then
    assert_vec(o, "add_mut")
  end
  self.x = self.x + o.x
  self.y = self.y + o.y
  return self
end

---Return a copy of this Vec subtracted by another Vec
---@param o Vec
---@return Vec
function Vec:sub(o)
  if Vec._DEBUG then
    assert_vec(o, "sub")
  end
  return Vec.new(self.x - o.x, self.y - o.y)
end

---Subtract this Vec in-place by another Vec
---@param o Vec
---@return self
function Vec:sub_mut(o)
  if Vec._DEBUG then
    assert_vec(o, "sub_mut")
  end
  self.x = self.x - o.x
  self.y = self.y - o.y
  return self
end

---Return a copy of this Vec multiplied by a Vec or number
---@param o Vec | number
---@return Vec
function Vec:mul(o)
  if is_vec(o) then
    return Vec.new(self.x * o.x, self.y * o.y)
  elseif type(o) == "number" then
    return Vec.new(self.x * o, self.y * o)
  else
    error(string.format("bad argument #1 to 'mul' (Vec or number expected, got %s)", type(o)), 2)
  end
end

---Multiply this Vec in-place by a Vec or number
---@param o Vec | number
---@return self
function Vec:mul_mut(o)
  if is_vec(o) then
    self.x = self.x * o.x
    self.y = self.y * o.y
  elseif type(o) == "number" then
    self.x = self.x * o
    self.y = self.y * o
  else
    error(string.format("bad argument #1 to 'mul_mut' (Vec or number expected, got %s)", type(o)), 2)
  end
  return self
end

---Return a copy of this Vec divided by a number
---@param o number
---@return Vec
function Vec:div(o)
  if Vec._DEBUG then
    assert_num(o, "div")
  end
  if abs(o) < Vec.EPS then
    error("division by zero", 2)
  end
  return Vec.new(self.x / o, self.y / o)
end

---Divide this Vec in-place by a number
---@param o number
---@return self
function Vec:div_mut(o)
  if Vec._DEBUG then
    assert_num(o, "div_mut")
  end
  if abs(o) < Vec.EPS then
    error("division by zero", 2)
  end
  self.x = self.x / o
  self.y = self.y / o
  return self
end

-- LÖVE bridges ---------------------------------------------------------------

if love then
  function Vec.from_mouse()
    return Vec(love.mouse.getPosition())
  end

  function Vec:mouse_distance()
    return self:distance(Vec.from_mouse())
  end

  function Vec:translate()
    love.graphics.translate(self.x, self.y)
  end
end

-- Metamethods ----------------------------------------------------------------

function Vec.__tostring(v)
  return string.format("Vec(%.2f, %.2f)", v.x, v.y)
end

function Vec.__len(v)
  return sqrt(v.x * v.x + v.y * v.y)
end

function Vec.__add(a, b)
  return a:add(b)
end

function Vec.__sub(a, b)
  return a:sub(b)
end

function Vec.__mul(a, b)
  if not is_vec(a) then
    return b:mul(a)
  end
  return a:mul(b)
end

function Vec.__div(a, b)
  return a:div(b)
end

function Vec.__unm(v)
  return Vec.new(-v.x, -v.y)
end

function Vec.__eq(a, b)
  return a:equals(b)
end

return Vec
