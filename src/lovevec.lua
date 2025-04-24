--[[
lovevec - 2D Vector Library (Lua)

A lightweight module providing 2D vector creation, arithmetic, geometric operations,
and optional runtime diagnostics (type checking in debug mode).
--]]

---@class Vec
---@field x number X component
---@field y number Y component
local Vec = {}
Vec.__index = Vec

-- Module metadata
Vec._NAME = "lovevec"
Vec._VERSION = "0.0.5"
Vec._DESCRIPTION = "2D Lua vector library with arithmetic, geometry, and debug checks"
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

-- Epsilon for floating-point comparisons
local EPS = 1e-9

-- Debug flag: when true, perform runtime type checks
---@type boolean
Vec._DEBUG = false

---Enable or disable debug mode (argument validation).
---@param enabled boolean
function Vec.enable_debug(enabled)
  Vec._DEBUG = enabled and true or false
end

---Ensure value is a Vec
---@private
---@param v any
---@param name? string - parameter name for error messages
local function assert_vec(v, name)
  if getmetatable(v) ~= Vec then
    error((name or "value") .. " must be a Vec, got " .. type(v), 3)
  end
end

setmetatable(Vec, {
  __call = function(cls, ...)
    return cls.new(...)
  end,
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

---Construct a Vec from polar coordinates in clock-wise order
---@param r number radius ()
---@param a number angle in radians
---@return Vec
function Vec.from_polar(r, a)
  if Vec._DEBUG then
    if type(r) ~= "number" or type(a) ~= "number" then
      error("from_polar expects two numbers (r, a)", 2)
    end
  end
  return Vec(r * math.cos(a), r * math.sin(a))
end

---Creates a random Vec with a uniform distribution over the unit circle
---(Uses `love.math.random` if available, otherwise `math.random`)
---@return Vec
function Vec.random()
  local random = math.random
  if love and love.math then
    random = love.math.random
  end
  return Vec.from_polar(1, random() * math.pi * 2)
end

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

---Manhatten length (L1 norm)
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

---Return a normalized copy of this Vec
---@return Vec
function Vec:normalize()
  if Vec._DEBUG then
    assert_vec(self, "self")
  end
  local len = self:length()
  if len < EPS then
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
  if len >= EPS then
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

---Return a copy of this Vec rotated in clock-wise order around pivot (default origin) by radians
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
  pivot = pivot or Vec.new()
  local s, c = math.sin(theta), math.cos(theta)
  local tx, ty = self.x - pivot.x, self.y - pivot.y
  return Vec.new(tx * c - ty * s + pivot.x, -tx * s + ty * c + pivot.y)
end

---Rotate this Vec clock-wise in-place around pivot (default origin) by radians
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
  pivot = pivot or Vec.new()
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
  if nn < EPS then
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
  if nn >= EPS then
    local f = 2 * dn / nn
    self.x = self.x - f * n.x
    self.y = self.y - f * n.y
  end
  return self
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

---Manhatten distance to another Vec
---@param o Vec
---@return number
function Vec:distance_manhattan(o)
  if Vec._DEBUG then
    assert_vec(self, "self")
    assert_vec(o, "other")
  end
  return math.abs(self.x - o.x) + math.abs(self.y - o.y)
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

---Return the (unsigned) angle between this Vec and another Vec, in radians
---@param o Vec
---@return number
function Vec:angle(o)
  if Vec._DEBUG then
    assert_vec(self, "self")
    assert_vec(o, "other")
  end
  local len1 = self:length()
  local len2 = o:length()
  if len1 < EPS or len2 < EPS then
    return 0
  end
  local cos_a = self:dot(o) / (len1 * len2)
  cos_a = math.max(-1, math.min(1, cos_a))
  return math.acos(cos_a)
end

---Approximate equality
---@param o Vec
---@param eps? number tolerance (default = 1e-9)
---@return boolean
function Vec:equals(o, eps)
  if Vec._DEBUG then
    assert_vec(self, "self")
    assert_vec(o, "other")
  end
  eps = eps or EPS
  return math.abs(self.x - o.x) < eps and math.abs(self.y - o.y) < eps
end

function Vec.__tostring(v)
  return string.format("Vec(%.2f, %.2f)", v.x, v.y)
end

function Vec.__add(a, b)
  return Vec.new(a.x + b.x, a.y + b.y)
end

function Vec.__sub(a, b)
  return Vec.new(a.x - b.x, a.y - b.y)
end

function Vec.__mul(a, b)
  if type(a) == "number" and getmetatable(b) == Vec then
    return Vec.new(b.x * a, b.y * a)
  elseif type(b) == "number" and getmetatable(a) == Vec then
    return Vec.new(a.x * b, a.y * b)
  else
    error("Multiplication with Vec: one operand must be a number")
  end
end

function Vec.__div(a, b)
  if type(b) == "number" and getmetatable(a) == Vec then
    return Vec.new(a.x / b, a.y / b)
  else
    error("Division with Vec: divisor must be a number")
  end
end

function Vec.__unm(a)
  return Vec.new(-a.x, -a.y)
end

function Vec.__eq(a, b)
  return a:equals(b)
end

function Vec.__pairs(v)
  return next, v, nil
end
Vec.__ipairs = Vec.__pairs

return Vec
