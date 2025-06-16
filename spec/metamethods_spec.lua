local Vec = require("src.lovevec")
local assert = require("luassert")

describe("Metamethods", function()
  before_each(function()
    Vec.enable_debug(true)
  end)

  after_each(function()
    Vec.enable_debug(false)
  end)

  describe("metatable", function()
    it("should protect Vec's own metatable", function()
      assert.are.equal(false, getmetatable(Vec))
      assert.has_error(function()
        setmetatable(Vec, {})
      end, "cannot change a protected metatable")
    end)
  end)

  describe("tostring", function()
    it("should return a string representation of the Vec", function()
      local v = Vec(3, 4)
      assert.are.equal(tostring(v), "Vec(3.00, 4.00)")
    end)
  end)

  describe("len", function()
    it("should return the vector length with #", function()
      if _VERSION == "LUA 5.1" or jit then
        pending("Lua 5.1/LuaJIT ignores __len on tables")
      else
        local v = Vec(1, 0)
        assert.are.equal(#v, 1)
      end
    end)
  end)

  describe("add", function()
    it("should add two Vecs using the + operator", function()
      local v1 = Vec(1, 2)
      local v2 = Vec(3, 4)
      local result = v1 + v2
      assert.are.same(result, Vec(4, 6))
    end)
  end)

  describe("sub", function()
    it("should subtract two Vecs using the - operator", function()
      local v1 = Vec(5, 6)
      local v2 = Vec(3, 4)
      local result = v1 - v2
      assert.are.same(result, Vec(2, 2))
    end)
  end)

  describe("mul", function()
    it("should multiply a Vec by a Vec using the * operator", function()
      local v1 = Vec(2, 3)
      local v2 = Vec(4, 5)
      local result = v1 * v2
      assert.are.same(result, Vec(8, 15))
    end)
    it("should multiply a Vec by a scalar using the * operator", function()
      local v = Vec(2, 3)
      local result = v * 2
      assert.are.same(result, Vec(4, 6))
    end)
    it("should multiply a scalar by a Vec using the * operator", function()
      local v = Vec(2, 3)
      local result = 2 * v
      assert.are.same(result, Vec(4, 6))
    end)
    it("should error if multiplying a Vec by a non-Vec or non-number", function()
      local v = Vec(2, 3)
      assert.has_error(function()
        return v * {}
      end, "bad operands to '*' (expected (Vec,Vec), (Vec,number) or (number,Vec))")
    end)
  end)

  describe("div", function()
    it("should divide a Vec by a scalar using the / operator", function()
      local v = Vec(4, 6)
      local result = v / 2
      assert.are.same(result, Vec(2, 3))
    end)
    it("should error if dividing a Vec by zero", function()
      local v = Vec(4, 6)
      assert.has_error(function()
        return v / 0
      end, "division by zero")
    end)
    it("should error if dividing a Vec by a non-number", function()
      local v = Vec(4, 6)
      assert.has_error(function()
        return v / "str"
      end, "bad argument #2 to '__div' (finite number expected, got str)")
    end)
  end)

  describe("unm", function()
    it("should negate a Vec using the - operator", function()
      local v = Vec(3, 4)
      local result = -v
      assert.are.same(result, Vec(-3, -4))
    end)
  end)

  describe("eq", function()
    it("should compare two Vecs for equality using the == operator", function()
      local v1 = Vec(1, 2)
      local v2 = Vec(1, 2)
      local v3 = Vec(3, 4)
      assert.is_true(v1 == v2)
      assert.is_false(v1 == v3)
    end)
  end)

  describe("numeric indexing", function()
    it("should read x and y via [1] and [2]", function()
      local v = Vec(3, 4)
      assert.are.equal(v[1], 3)
      assert.are.equal(v[2], 4)
    end)

    it("should reflect changes to fields", function()
      local v = Vec(0, 0)
      v.x = 7
      v.y = 8
      assert.are.equal(v[1], 7)
      assert.are.equal(v[2], 8)
    end)

    it("should leave other keys untouched", function()
      local v = Vec(1, 2)
      v.extra = 99
      assert.are.equal(v.extra, 99)
    end)
  end)
end)
