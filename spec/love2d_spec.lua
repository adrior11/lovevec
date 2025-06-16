-- Stub for LÖVE framework
_G.love = {
  math = {
    random = function()
      return math.random()
    end,
  },
  mouse = {
    getPosition = function()
      return 10, 20
    end,
  },
  graphics = {
    translate = function() end,
  },
}

local Vec = require("src.lovevec")
local assert = require("luassert")
local spy = require("luassert.spy")

describe("LÖVE bridges", function()
  describe("random", function()
    it("should use love.math.random to create a Vec if available", function()
      local v = Vec.random()
      assert.is_true(math.abs(v:length() - 1) < Vec._EPS)
      assert.is_true(v.x >= -1 and v.x <= 1)
      assert.is_true(v.y >= -1 and v.y <= 1)
    end)
  end)
  describe("from_mouse", function()
    it("should return a Vec with mouse position", function()
      local v = Vec.from_mouse()
      assert.are.same(v, Vec(10, 20))
    end)
  end)

  describe("mouse_distance", function()
    it("should return the distance from the mouse to a given Vec", function()
      local v = Vec(0, 0)
      local dist = Vec.mouse_distance(v)
      local expected_dist = Vec(10, 20):length()
      assert.are.equal(dist, expected_dist)
    end)
  end)

  describe("translate", function()
    it("calls love.graphics.translate with x and y", function()
      local v = Vec(12, 34)

      love.graphics.translate = spy.new(function() end)

      v:translate()

      assert.spy(love.graphics.translate).was.called(1)
      assert.spy(love.graphics.translate).was.called_with(12, 34)
    end)
  end)
end)
