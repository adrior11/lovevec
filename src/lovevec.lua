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

---Enable or disable debug mode (argument validation).
---@param enabled boolean
function Vec.enable_debug(enabled)
  Vec._DEBUG = enabled and true or false
end

-- Internal helpers ------------------------------------------------------------

---@private
---@param v any
---@return boolean
local function is_vec(v)
  return getmetatable(v) == Vec
end

---@private
---@param v any
---@param name? string
local function assert_vec(v, name)
  if not is_vec(v) then
    error((name or "value") .. " must be a Vec, got " .. type(v), 3)
  end
end

---@private
---@param n any
---@param name? string
local function assert_num(n, name)
  if type(n) ~= "number" then
    error((name or "value") .. " must be a number, got " .. type(n), 3)
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
    assert_num(v, "v")
    assert_num(min, "min")
    assert_num(max, "max")
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
    assert_num(t[1], "t[1]")
    assert_num(t[2], "t[2]")
  end
  return Vec.new(t[1], t[2])
end

---Construct a Vec from polar coordinates in clock-wise order
---@param r number radius
---@param a number angle in radians
---@return Vec
function Vec.from_polar(r, a)
  if Vec._DEBUG then
    assert_num(r, "r")
    assert_num(a, "a")
  end
  return Vec.new(r * math.cos(a), r * math.sin(a))
end

---Creates a random Vec with a uniform distribution over the unit circle
---(Uses `love.math.random` if available, otherwise `math.random`)
---@param r? number radius (default = 1)
---@return Vec
function Vec.random(r)
  if Vec._DEBUG and r ~= nil then
    assert_num(r, "r")
  end
  r = r or 1
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
  if Vec._DEBUG then
    assert_vec(self, "self")
  end
  return Vec.new(self.x, self.y)
end

---Return x and y components
---@return number, number
function Vec:unpack()
  if Vec._DEBUG then
    assert_vec(self, "self")
  end
  return self.x, self.y
end

---Return a table with x and y components
---@return table
function Vec:to_table()
  if Vec._DEBUG then
    assert_vec(self, "self")
  end
  return { self.x, self.y }
end

---Manhattan length (L1 norm)
---@return number
function Vec:length_manhattan()
  if Vec._DEBUG then
    assert_vec(self, "self")
  end
  return math.abs(self.x) + math.abs(self.y)
end

---Squared length (avoids sqrt)
---@return number
function Vec:length_squared()
  if Vec._DEBUG then
    assert_vec(self, "self")
  end
  return self.x * self.x + self.y * self.y
end

---Length (magnitude)
---@return number
function Vec:length()
  if Vec._DEBUG then
    assert_vec(self, "self")
  end
  return math.sqrt(self:length_squared())
end

---Dot product
---@param o Vec
---@return number
function Vec:dot(o)
  if Vec._DEBUG then
    assert_vec(self, "self")
    assert_vec(o, "other")
  end
  return self.x * o.x + self.y * o.y
end

---Cross product (z-component)
---@param o Vec
---@return number
function Vec:cross(o)
  if Vec._DEBUG then
    assert_vec(self, "self")
    assert_vec(o, "other")
  end
  return self.x * o.y - self.y * o.x
end

---Return a normalized copy of this Vec
---@return Vec
function Vec:normalize()
  if Vec._DEBUG then
    assert_vec(self, "self")
  end
  local len = self:length()
  if len < Vec.EPS then
    return Vec.new()
  end
  return Vec.new(self.x / len, self.y / len)
end

---Normalize in-place (no-op if near zero)
---@return self
function Vec:normalize_mut()
  if Vec._DEBUG then
    assert_vec(self, "self")
  end
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
    assert_vec(self, "self")
    if type(scalar) ~= "number" then
      error("scale expects a number", 2)
    end
  end
  return Vec.new(self.x * scalar, self.y * scalar)
end

---Scale this Vec in-place
---@param scalar number
---@return self
function Vec:scale_mut(scalar)
  if Vec._DEBUG then
    assert_vec(self, "self")
    if type(scalar) ~= "number" then
      error("scale_mut expects a number", 2)
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
  if Vec._DEBUG then
    assert_vec(self, "self")
  end
  return Vec(-self.y, self.x)
end

---Return the perpendicular of this Vec
--- (clock-wise, screen space where +y is down)
---@return Vec
function Vec:perp_mut()
  if Vec._DEBUG then
    assert_vec(self, "self")
  end
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
    assert_vec(self, "self")
    assert_vec(o, "other")
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
    assert_vec(self, "self")
    assert_vec(o, "other")
  end
  local nn = o:length_squared()
  if nn < Vec.EPS then
    return self:clone()
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
    assert_vec(self, "self")
    assert_vec(o, "other")
  end
  return self - self:project(o)
end

---Reject this Vec onto another Vec
---@param o Vec
---@return self
function Vec:reject_mut(o)
  if Vec._DEBUG then
    assert_vec(self, "self")
    assert_vec(o, "other")
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
    assert_vec(self, "self")
    assert_vec(min, "min")
    assert_vec(max, "max")
  end
  return Vec(clamp(self.x, min.x, max.x), clamp(self.y, min.y, max.y))
end

---Clamp this Vec in-place between two other
---@param min Vec
---@param max Vec
---@return self
function Vec:clamp_mut(min, max)
  if Vec._DEBUG then
    assert_vec(self, "self")
    assert_vec(min, "min")
    assert_vec(max, "max")
  end
  self.x = clamp(self.x, min.x, max.x)
  self.y = clamp(self.y, min.y, max.y)
  return self
end

---Limit this Vec to a maximum length
---@param maxlen number
---@return Vec
function Vec:limit(maxlen)
  assert_num(maxlen, "maxlen")
  local l = self:length()
  return l > maxlen and self:scale(maxlen / l) or self:clone()
end

---Limit this Vec in-place to a maximum length
---@param maxlen number
---@return self
function Vec:limit_mut(maxlen)
  assert_num(maxlen)
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
    assert_vec(self, "self")
    assert_vec(o, "other")
    if type(t) ~= "number" then
      error("t must be a number", 2)
    end
  end
  return Vec.new(self.x + (o.x - self.x) * t, self.y + (o.y - self.y) * t)
end

---Linearly interpolate this Vec in-place towards another Vec
---@param o Vec
---@param t number interpolation factor (0 => self, 1 => o)
---@return self
function Vec:lerp_mut(o, t)
  if Vec._DEBUG then
    assert_vec(self, "self")
    assert_vec(o, "other")
    if type(t) ~= "number" then
      error("t must be a number", 2)
    end
  end
  self.x = self.x + (o.x - self.x) * t
  self.y = self.y + (o.y - self.y) * t
  return self
end

---Return a copy of this Vec rounded to the nearest integer
---@return Vec
function Vec:round()
  if Vec._DEBUG then
    assert_vec(self, "self")
  end
  return Vec(math.floor(self.x + 0.5), math.floor(self.y + 0.5))
end

---Round this Vec in-place to the nearest integer
---@return self
function Vec:round_mut()
  if Vec._DEBUG then
    assert_vec(self, "self")
  end
  self.x = math.floor(self.x + 0.5)
  self.y = math.floor(self.y + 0.5)
  return self
end

---Return a copy of this Vec rounded down to the nearest integer
---@return Vec
function Vec:floor()
  if Vec._DEBUG then
    assert_vec(self, "self")
  end
  return Vec(math.floor(self.x), math.floor(self.y))
end

---Round this Vec in-place down to the nearest integer
---@return self
function Vec:floor_mut()
  if Vec._DEBUG then
    assert_vec(self, "self")
  end
  self.x = math.floor(self.x)
  self.y = math.floor(self.y)
  return self
end

---Return a copy of this Vec rounded up to the nearest integer
---@return Vec
function Vec:ceil()
  if Vec._DEBUG then
    assert_vec(self, "self")
  end
  return Vec(math.ceil(self.x), math.ceil(self.y))
end

---Round this Vec in-place up to the nearest integer
---@return self
function Vec:ceil_mut()
  if Vec._DEBUG then
    assert_vec(self, "self")
  end
  self.x = math.ceil(self.x)
  self.y = math.ceil(self.y)
  return self
end

---Return a copy of this Vec rotated (clock-wise, screen space where +y is down)
--- around a pivot (default origin) by radians
---@param theta number
---@param pivot? Vec
---@return Vec
function Vec:rotate(theta, pivot)
  if Vec._DEBUG then
    assert_vec(self, "self")
    if type(theta) ~= "number" then
      error("rotate expects a number for angle", 2)
    end
    if pivot ~= nil then
      assert_vec(pivot, "pivot")
    end
  end
  pivot = pivot or Vec.zero
  local s, c = math.sin(theta), math.cos(theta)
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
    assert_vec(self, "self")
    if type(theta) ~= "number" then
      error("rotate_mut expects a number for angle", 2)
    end
    if pivot ~= nil then
      assert_vec(pivot, "pivot")
    end
  end
  pivot = pivot or Vec.zero
  local s, c = math.sin(theta), math.cos(theta)
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
    assert_vec(self, "self")
    assert_vec(n, "normal")
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
    assert_vec(self, "self")
    assert_vec(n, "normal")
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
    assert_vec(self, "self")
    assert_vec(o, "other")
  end
  return (self - o):length()
end

---Manhattan distance to another Vec
---@param o Vec
---@return number
function Vec:distance_manhattan(o)
  if Vec._DEBUG then
    assert_vec(self, "self")
    assert_vec(o, "other")
  end
  return math.abs(self.x - o.x) + math.abs(self.y - o.y)
end

---Return the angle between this Vec and another Vec, in radians
---@param o Vec
---@return number
function Vec:angle(o)
  if Vec._DEBUG then
    assert_vec(self, "self")
    assert_vec(o, "other")
  end
  return math.atan2(self:cross(o), self:dot(o))
end

---Return the angle of this Vec with respect to the x-axis, in radians
---@return number
function Vec:angle_of()
  if Vec._DEBUG then
    assert_vec(self, "self")
  end
  return math.atan2(self.y, self.x)
end

---Approximate equality
---@param o Vec
---@param eps? number tolerance (default = 1e-7)
---@return boolean
function Vec:equals(o, eps)
  if Vec._DEBUG then
    assert_vec(self, "self")
    assert_vec(o, "other")
  end
  eps = eps or Vec.EPS
  return math.abs(self.x - o.x) < eps and math.abs(self.y - o.y) < eps
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
  assert_vec(v, "self")
  return string.format("Vec(%.2f, %.2f)", v.x, v.y)
end

function Vec.__len(v)
  assert_vec(v, "self")
  return v:length()
end

function Vec.__add(a, b)
  if not (is_vec(a) and is_vec(b)) then
    error("Vec addition: both operands must be Vec")
  end
  return Vec.new(a.x + b.x, a.y + b.y)
end

function Vec.__sub(a, b)
  if not (is_vec(a) and is_vec(b)) then
    error("Vec subtraction: both operands must be Vec")
  end
  return Vec.new(a.x - b.x, a.y - b.y)
end

function Vec.__mul(a, b)
  if is_vec(a) and is_vec(b) then
    return Vec(a.x * b.x, a.y * b.y)
  elseif type(a) == "number" and is_vec(b) then
    return Vec.new(b.x * a, b.y * a)
  elseif type(b) == "number" and is_vec(a) then
    return Vec.new(a.x * b, a.y * b)
  else
    error("Vec multiplication: expected (vec,vec) or (vec,number) or (number,vec)")
  end
end

function Vec.__div(a, b)
  if is_vec(a) and type(b) == "number" then
    return Vec.new(a.x / b, a.y / b)
  end
  error("Vec division: left operand must be Vec and divisor a number")
end

function Vec.__unm(v)
  return Vec.new(-v.x, -v.y)
end

function Vec.__eq(a, b)
  return a:equals(b)
end

function Vec.__pairs(v)
  return next, v, nil
end
Vec.__ipairs = Vec.__pairs

return Vec
