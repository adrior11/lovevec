---@diagnostic disable: missing-fields, param-type-mismatch
local Vec = require("src.lovevec")
local assert = require("luassert")

describe("Vec", function()
  describe("construction", function()
    it("defaults to zero vector when no args", function()
      local v = Vec()
      assert.are.equal(0, v.x)
      assert.are.equal(0, v.y)
    end)

    it("accepts x and y parameters", function()
      local v = Vec(3, 4)
      assert.are.equal(3, v.x)
      assert.are.equal(4, v.y)
    end)

    it("from_polar constructs correct Cartesian components", function()
      local r, a = 5, math.pi / 4
      local v = Vec.from_polar(r, a)
      assert.is_true(v:equals(Vec(r * math.cos(a), r * math.sin(a))))
    end)

    it("random constructs unit vector", function()
      local EPS = 1e-9
      local v = Vec.random()
      assert.is_true(v:length() >= 1 - EPS)
      assert.is_true(v:length() < 1 + EPS)
    end)
  end)

  describe("cloning and unpacking", function()
    it("clone returns an independent copy", function()
      local v1 = Vec(1, 2)
      local v2 = v1:clone()
      assert.is_true(v1 == v2)
      v2.x = 10
      assert.are.equal(1, v1.x)
      assert.are.equal(10, v2.x)
    end)

    it("unpack returns x and y", function()
      local x, y = Vec(7, 8):unpack()
      assert.are.equal(7, x)
      assert.are.equal(8, y)
    end)
  end)

  describe("length calculations", function()
    it("len2 returns squared length", function()
      local v = Vec(2, 3)
      assert.are.equal(13, v:len2())
    end)

    it("length returns magnitude", function()
      local v = Vec(3, 4)
      assert.are.equal(5, v:length())
    end)

    it("distance returns correct Euclidean distance", function()
      local v1 = Vec(0, 0)
      local v2 = Vec(3, 4)
      assert.are.equal(5, v1:distance(v2))
    end)
  end)

  describe("normalization and scaling", function()
    it("normalize returns new normalized vector", function()
      local v = Vec(3, 4)
      local w = v:normalize()
      assert.is_true(w:equals(Vec(0.6, 0.8)))
      assert.is_true(v:equals(Vec(3, 4)))
    end)

    it("normalize returns a zero vector when self has zero length", function()
      local v = Vec(0, 0)
      local z = v:normalize()
      assert.is_true(z:equals(Vec(0, 0)))
      assert.is_false(rawequal(v, z))
    end)

    it("normalize_mut scales to unit length", function()
      local v = Vec(3, 4):clone()
      v:normalize_mut()
      assert.is_true(v:equals(Vec(0.6, 0.8)))
    end)

    it("scale returns new scaled vector", function()
      local v = Vec(1, 2)
      local s = v:scale(3)
      assert.are.equal(3, s.x)
      assert.are.equal(6, s.y)
    end)

    it("scale_mut scales vector in-place", function()
      local v = Vec(2, 3)
      v:scale_mut(2)
      assert.are.equal(4, v.x)
      assert.are.equal(6, v.y)
    end)
  end)

  describe("rotation", function()
    it("rotate rotates clockwise around origin", function()
      local v = Vec(1, 0)
      local rotated = v:rotate(math.pi / 2)
      assert.is_true(rotated:equals(Vec(0, -1)))
    end)

    it("rotate around a pivot", function()
      local pivot = Vec(1, 1)
      local v = Vec(2, 1)
      local rotated = v:rotate(math.pi / 2, pivot)
      assert.is_true(rotated:equals(Vec(1, 0)))
    end)

    it("rotate_mut modifies in-place", function()
      local v = Vec(0, 1)
      v:rotate_mut(math.pi)
      assert.is_true(v:equals(Vec(0, -1)))
    end)
  end)

  describe("dot product and arithmetic operators", function()
    it("dot returns correct value", function()
      local v1 = Vec(1, 2)
      local v2 = Vec(3, 4)
      assert.are.equal(11, v1:dot(v2))
    end)

    it("addition and subtraction produce correct vectors", function()
      local a, b = Vec(1, 2), Vec(3, 4)
      assert.is_true((a + b) == Vec(4, 6))
      assert.is_true((b - a) == Vec(2, 2))
    end)

    it("multiplication by scalar works both ways", function()
      local v = Vec(2, 3)
      assert.is_true((v * 4) == Vec(8, 12))
      assert.is_true((4 * v) == Vec(8, 12))
    end)

    it("division by scalar works", function()
      local v = Vec(8, 12)
      assert.is_true((v / 4) == Vec(2, 3))
    end)

    it("unary minus negatescomponents", function()
      local v = Vec(5, -6)
      local n = -v
      ---@diagnostic disable-next-line: undefined-field
      assert.are.equal(-5, n.x)
      ---@diagnostic disable-next-line: undefined-field
      assert.are.equal(6, n.y)
    end)

    it("equality operator uses approximate comparison", function()
      local a = Vec(1, 2)
      local b = Vec(1 + 1e-10, 2 - 1e-10)
      assert.is_true(a == b)
    end)

    it("pairs iterates over x and y fields", function()
      local v = Vec(9, 10)
      local t = {}
      for k, val in pairs(v) do
        t[k] = val
      end
      assert.are.equal(9, t.x)
      assert.are.equal(10, t.y)
    end)
  end)

  describe("angle", function()
    it("is zero for identical vectors", function()
      local a = Vec(3, 4)
      assert.are.equal(0, a:angle(a))
    end)

    it("is π/2 for orthogonal vectors", function()
      local x = Vec(1, 0)
      local y = Vec(0, 1)
      assert.are.equal(math.pi / 2, x:angle(y))
      assert.are.equal(math.pi / 2, y:angle(x))
    end)

    it("is π for opposite vectors", function()
      local u = Vec(1, 0)
      local v = Vec(-1, 0)
      assert.are.equal(math.pi, u:angle(v))
    end)

    it("returns zero if either vector is zero", function()
      local zero = Vec(0, 0)
      local v = Vec(5, 1)
      assert.are.equal(0, zero:angle(v))
      assert.are.equal(0, v:angle(zero))
    end)
  end)

  describe("string representation", function()
    it("tostring formats to two decimals", function()
      local s = tostring(Vec(1, 2))
      assert.are.equal("Vec(1.00, 2.00)", s)
    end)
  end)

  describe("error handling in debug mode", function()
    before_each(function()
      Vec.enable_debug(true)
    end)
    after_each(function()
      Vec.enable_debug(false)
    end)

    it("errors when creating with non-numeric x", function()
      assert.has_error(function()
        Vec.new("a", 0)
      end, "x must be a number")
    end)

    it("errors when creating with non-numeric y", function()
      assert.has_error(function()
        Vec.new(0, "b")
      end, "y must be a number")
    end)

    it("errors when scaling with non-number", function()
      local v = Vec(1, 1)
      assert.has_error(function()
        v:scale("s")
      end, "scale expects a number")
      assert.has_error(function()
        v:scale_mut("s")
      end, "scale_mut expects a number")
    end)

    it("errors when rotating with non-number angle", function()
      local v = Vec(1, 1)
      assert.has_error(function()
        v:rotate("r")
      end, "rotate expects a number for angle")
      assert.has_error(function()
        v:rotate_mut("r")
      end, "rotate_mut expects a number for angle")
    end)

    it("errors on invalid multiplication", function()
      local a, b = Vec(1, 1), Vec(2, 2)
      assert.has_error(function()
        return a * b
      end, "Multiplication with Vec: one operand must be a number")
    end)

    it("errors on invalid division", function()
      local a, b = Vec(1, 1), Vec(2, 2)
      assert.has_error(function()
        return a / b
      end, "Division with Vec: divisor must be a number")
    end)

    it("from_polar errors when r or a are not numbers", function()
      assert.has_error(function()
        Vec.from_polar("r", 1)
      end, "from_polar expects two numbers (r, a)")
      assert.has_error(function()
        Vec.from_polar(1, "a")
      end, "from_polar expects two numbers (r, a)")
    end)

    describe("all methods guard against self", function()
      local cases = {
        { "clone", Vec.clone },
        { "unpack", Vec.unpack },
        { "len2", Vec.len2 },
        { "length", Vec.length },
        { "normalize", Vec.normalize },
        { "normalize_mut", Vec.normalize_mut },
      }

      for _, case in ipairs(cases) do
        local name, fn = case[1], case[2]
        it(("%s() should error when self is not a Vec"):format(name), function()
          assert.has_error(function()
            fn({})
          end, "self must be a Vec, got table")
        end)
      end
    end)

    it("scale_mut errors on bad self before checking scalar", function()
      assert.has_error(function()
        Vec.scale_mut({}, 10)
      end, "self must be a Vec, got table")
    end)

    it("rotate errors on bad pivot", function()
      local v = Vec(1, 1)
      assert.has_error(function()
        v:rotate(0, {})
      end, "pivot must be a Vec, got table")
      assert.has_error(function()
        v:rotate_mut(0, {})
      end)
    end)

    it("dot errors on bad self or bad other", function()
      local good = Vec(0, 0)
      assert.has_error(function()
        Vec.dot({}, good)
      end, "self must be a Vec, got table")
      assert.has_error(function()
        good:dot({})
      end, "other must be a Vec, got table")
    end)

    it("distance errors on bad self", function()
      assert.has_error(function()
        Vec.distance({}, Vec())
      end, "self must be a Vec, got table")
    end)

    it("angle errors on bad self", function()
      local good = Vec(1, 1)
      assert.has_error(function()
        Vec.angle({}, good)
      end, "self must be a Vec, got table")
      assert.has_error(function()
        good.angle({})
      end, "self must be a Vec, got table")
    end)

    it("equals errors on bad self or other", function()
      local good = Vec(0, 0)
      assert.has_error(function()
        Vec.equals({}, good)
      end, "self must be a Vec, got table")
      assert.has_error(function()
        good:equals({})
      end, "other must be a Vec, got table")
    end)
  end)
end)
