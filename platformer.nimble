# Package

version       = "1.0"
author        = "Dennis Felsing"
description   = "An example 2D platform game with SDL2"
license       = "MIT"

bin           = @["platformer"]

# Dependencies

requires "nim >= 0.10.0"
requires "sdl2 >= 1.1"
requires "strfmt >= 0.6"

task tests, "Compile all tutorial steps":
  for i in 1..9:
    exec "nim c tutorial/platformer_part" & $i
