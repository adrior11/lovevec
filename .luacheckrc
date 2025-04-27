std = "+lua54+luajit"

globals = {
  love = {
    read = true,
    fields = {
      graphics = {
        read = true,
        fields = {
          translate = {
            read = true,
          },
        },
      },
      math = {
        read = true,
        fields = {
          random = {
            read = true,
          },
        },
      },
      mouse = {
        read = true,
        fields = {
          getPosition = {
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
