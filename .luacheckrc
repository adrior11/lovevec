std = "+lua54+luajit"

globals = {
  love = {
    read = true,
    fields = {
      math = {
        read = true,
        fields = {
          random = {
            read = true,
          },
        },
      },
    },
  },
  Vec = { read = true },
}

exclude_files = {
  ".luarocks/**",
  ".lua/**",
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
