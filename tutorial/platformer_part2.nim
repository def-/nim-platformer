# https://hookrace.net/blog/writing-a-2d-platform-game-in-nim-with-sdl2/#2.-user-input

import sdl2

type
  SDLException = object of Exception

  Input {.pure.} = enum none, left, right, jump, restart, quit

  Game = ref object
    inputs: array[Input, bool]
    renderer: RendererPtr

template sdlFailIf(cond: typed, reason: string) =
  if cond: raise SDLException.newException(
    reason & ", SDL error: " & $getError())

proc newGame(renderer: RendererPtr): Game =
  new result
  result.renderer = renderer

proc toInput(key: Scancode): Input =
  case key
  of SDL_SCANCODE_A: Input.left
  of SDL_SCANCODE_D: Input.right
  of SDL_SCANCODE_SPACE: Input.jump
  of SDL_SCANCODE_R: Input.restart
  of SDL_SCANCODE_Q: Input.quit
  else: Input.none

proc handleInput(game: Game) =
  var event = defaultEvent
  while pollEvent(event):
    case event.kind
    of QuitEvent:
      game.inputs[Input.quit] = true
    of KeyDown:
      game.inputs[event.key.keysym.scancode.toInput] = true
    of KeyUp:
      game.inputs[event.key.keysym.scancode.toInput] = false
    else:
      discard

proc render(game: Game) =
  # Draw over all drawings of the last frame with the default color
  game.renderer.clear()
  # Show the result on screen
  game.renderer.present()

proc main =
  sdlFailIf(not sdl2.init(INIT_VIDEO or INIT_TIMER or INIT_EVENTS)):
    "SDL2 initialization failed"

  # defer blocks get called at the end of the procedure, even if an
  # exception has been thrown
  defer: sdl2.quit()

  sdlFailIf(not setHint("SDL_RENDER_SCALE_QUALITY", "2")):
    "Linear texture filtering could not be enabled"

  let window = createWindow(title = "Our own 2D platformer",
    x = SDL_WINDOWPOS_CENTERED, y = SDL_WINDOWPOS_CENTERED,
    w = 1280, h = 720, flags = SDL_WINDOW_SHOWN)
  sdlFailIf window.isNil: "Window could not be created"
  defer: window.destroy()

  let renderer = window.createRenderer(index = -1,
    flags = Renderer_Accelerated or Renderer_PresentVsync)
  sdlFailIf renderer.isNil: "Renderer could not be created"
  defer: renderer.destroy()

  # Set the default color to use for drawing
  renderer.setDrawColor(r = 110, g = 132, b = 174)

  var game = newGame(renderer)

  # Game loop, draws each frame
  while not game.inputs[Input.quit]:
    game.handleInput()
    game.render()

main()
