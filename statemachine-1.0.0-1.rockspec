package = "statemachine"
version = "1.0.0-1"
source = {
  url = "https://github.com/kyleconroy/lua-state-machine/archive/v1.0.0.tar.gz",
  dir = "lua-state-machine-1.0.0"
}
description = {
   summary = "A finite state machine micro framework",
   detailed = [[
      This standalone module provides a finite state machine for your pleasure. 
   ]],
   homepage = "https://github.com/kyleconroy/lua-state-machine",
   license = "MIT/X11"
}
dependencies = {
   "lua >= 5.1"
}
build = {
  type = "builtin",
  modules = {
    ["statemachine"] = "statemachine.lua"
  },
  copy_directories = {}
}

