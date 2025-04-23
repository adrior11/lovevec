stds = { "lua51", "luajit" }

globals = {
  love = { read = true },
  Vec = { read = true },
}

files["src/?.lua"] = {
  std = "+lua51+luajit",
  unused_args = false,
  max_line_length = 110,
}

files["spec/?.lua"] = {
  std = "+busted",
  -- globals = { stub = { read = true } },
}

files[".luacheckrc"].ignore = {}
