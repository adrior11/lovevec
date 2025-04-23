std = "+lua54+luajit"

globals = {
  love = { read = true },
  Vec = { read = true },
}

files["src/?.lua"] = {
  std = "+lua54+luajit",
  unused_args = false,
  max_line_length = 120,
}

files["spec/?.lua"] = {
  std = "+lua54+luajit+busted",
}

ignore = {}
