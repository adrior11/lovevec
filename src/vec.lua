--[[
Vec - 2D Vector Library (Lua)

A lightweight module providing 2D vector creation, arithmetic, geometric operations,
and optional runtime diagnostics (type checking in debug mode).
--]]

---@class Vec
---@field x number X component
---@field y number Y component
local Vec = {}
Vec.__index = Vec

-- Module metadata
Vec._VERSION = "0.0.1"
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

---Construct a Vec from polar coordinates
---@param r number radius (non-negative)
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

---Squared length (avoids sqrt)
---@return number
function Vec:len2()
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
  return math.sqrt(self:len2())
end

---Return normalized copy
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

---Return scaled copy
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

---Rotate clock-wise around pivot (default origin) by radians, returning new Vec
---@param rad number
---@param pivot? Vec
---@return Vec
function Vec:rotate(rad, pivot)
  if Vec._DEBUG then
    assert_vec(self, "self")
    if type(rad) ~= "number" then
      error("rotate expects a number for angle", 2)
    end
    if pivot ~= nil then
      assert_vec(pivot, "pivot")
    end
  end
  pivot = pivot or Vec.new()
  local s, c = math.sin(rad), math.cos(rad)
  local t = self - pivot -- translated
  local rotated = Vec.new(t.x * c - t.y * s, -t.x * s + t.y * c)
  return rotated + pivot
end

---Rotate this Vec clock-wise in-place around pivot (default origin) by radians
---@param rad number
---@param pivot? Vec
---@return self
function Vec:rotate_mut(rad, pivot)
  local v = self:rotate(rad, pivot)
  self.x, self.y = v.x, v.y
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

---Distance to another Vec
---@param o Vec
---@return number
function Vec:distance(o)
  if Vec._DEBUG then
    assert_vec(self, "self")
  end
  return (self - o):length()
end

---Approximate equality
---@param o Vec
---@param eps? number - tolerance (default = 1e-9)
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
