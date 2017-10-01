import
  sdl2, sdl2.image, sdl2.ttf,
  basic2d, strutils, times, math, strfmt, os, streams

import safe_sdl2

type
  Input {.pure.} = enum none, left, right, jump, restart, quit

  Collision {.pure.} = enum x, y, corner

  CacheLine = object
    texture: TexturePtr
    w, h: cint

  TextCache = ref object
    text: string
    cache: array[2, CacheLine]

  Time = ref object
    begin, finish, best: int

  Player = ref object
    texture: TexturePtr
    pos: Point2d
    vel: Vector2d
    time: Time

  Map = ref object
    texture: TexturePtr
    width, height: int
    tiles: seq[uint8]

  Game = ref object
    inputs: array[Input, bool]
    renderer: RendererPtr
    font: FontPtr
    player: Player
    map: Map
    camera: Vector2d

const
  windowSize: Point = (1280.cint, 720.cint)

  tilesPerRow = 16
  tileSize: Point = (64.cint, 64.cint)

  playerSize = vector2d(64, 64)

  air = 0
  start = 78
  finish = 110

proc renderTee(renderer: RendererPtr, texture: TexturePtr, pos: Point2d) =
  let
    x = pos.x.cint
    y = pos.y.cint

  var bodyParts: array[8, tuple[source, dest: Rect, flip: cint]] = [
    (rect(192,  64, 64, 32), rect(x-60,    y, 96, 48),
     SDL_FLIP_NONE),      # back feet shadow
    (rect( 96,   0, 96, 96), rect(x-48, y-48, 96, 96),
     SDL_FLIP_NONE),      # body shadow
    (rect(192,  64, 64, 32), rect(x-36,    y, 96, 48),
     SDL_FLIP_NONE),      # front feet shadow
    (rect(192,  32, 64, 32), rect(x-60,    y, 96, 48),
     SDL_FLIP_NONE),      # back feet
    (rect(  0,   0, 96, 96), rect(x-48, y-48, 96, 96),
     SDL_FLIP_NONE),      # body
    (rect(192,  32, 64, 32), rect(x-36,    y, 96, 48),
     SDL_FLIP_NONE),      # front feet
    (rect( 64,  96, 32, 32), rect(x-18, y-21, 36, 36),
     SDL_FLIP_NONE),      # left eye
    (rect( 64,  96, 32, 32), rect( x-6, y-21, 36, 36),
     SDL_FLIP_HORIZONTAL) # right eye
  ]

  for part in bodyParts.mitems:
    renderer.safeCopyEx(texture, part.source, part.dest, angle = 0.0,
                        center = nil, flip = part.flip)

proc renderMap(renderer: RendererPtr, map: Map, camera: Vector2d) =
  var
    clip = rect(0, 0, tileSize.x, tileSize.y)
    dest = rect(0, 0, tileSize.x, tileSize.y)

  for i, tileNr in map.tiles:
    if tileNr == 0: continue

    clip.x = cint(tileNr mod tilesPerRow) * tileSize.x
    clip.y = cint(tileNr div tilesPerRow) * tileSize.y
    dest.x = cint(i mod map.width) * tileSize.x - camera.x.cint
    dest.y = cint(i div map.width) * tileSize.y - camera.y.cint

    renderer.safeCopy(map.texture, unsafeAddr clip, unsafeAddr dest)

proc newTextCache: TextCache =
  new result

proc renderText(renderer: RendererPtr, font: FontPtr, text: string,
                x, y, outline: cint, color: Color): CacheLine =
  font.safeSetFontOutline(outline)
  let surface = font.safeRenderUtf8Blended(text.cstring, color)

  surface.safeSetSurfaceAlphaMod(color.a)

  result.w = surface.w
  result.h = surface.h
  result.texture = renderer.safeCreateTextureFromSurface(surface)

  surface.safeFreeSurface()

proc renderText(game: Game, text: string, x, y: cint, color: Color,
                tc: TextCache) =
  let passes = [(color: color(0, 0, 0, 64), outline: 2.cint),
                (color: color, outline: 0.cint)]

  if text != tc.text:
    for i in 0..1:
      if tc.cache[i].texture != nil:
        tc.cache[i].texture.safeDestroy()
      tc.cache[i] = game.renderer.renderText(
        game.font, text, x, y, passes[i].outline, passes[i].color)
    tc.text = text

  for i in 0..1:
    var source = rect(0, 0, tc.cache[i].w, tc.cache[i].h)
    var dest = rect(x - passes[i].outline, y - passes[i].outline,
                    tc.cache[i].w, tc.cache[i].h)
    game.renderer.safeCopyEx(tc.cache[i].texture, source, dest,
                             angle = 0.0, center = nil)

template renderTextCached(game: Game, text: string, x, y: cint, color: Color) =
  block:
    var tc {.global.} = newTextCache()
    game.renderText(text, x, y, color, tc)

proc restartPlayer(player: Player) =
  player.pos = point2d(170, 500)
  player.vel = vector2d(0, 0)
  player.time.begin = -1
  player.time.finish = -1

proc newTime: Time not nil =
  new result
  result.finish = -1
  result.best = -1

proc newPlayer(texture: TexturePtr): Player not nil =
  new result
  result.texture = texture
  result.time = newTime()
  result.restartPlayer()

proc newMap(texture: TexturePtr, map: Stream): Map not nil =
  new result
  result.texture = texture
  result.tiles = @[]

  var line = ""
  while map.readLine(line):
    var width = 0
    for word in line.split(' '):
      if word == "": continue
      let value = parseUInt(word)
      if value > uint(uint8.high):
        raise ValueError.newException(
          "Invalid value in map: " & word)
      result.tiles.add value.uint8
      inc width

    if width == 0: continue
    if result.width > 0 and result.width != width:
      raise ValueError.newException(
        "Incompatible line length in map: " & $width)
    result.width = width
    inc result.height

const dataDir = "data"

when defined(embedData):
  template readRW(filename: string): ptr RWops not nil =
    const file = staticRead(dataDir / filename)
    safeRwFromConstMem(file.cstring, file.len)

  template readStream(filename: string): Stream not nil =
    const file = staticRead(dataDir / filename)
    newStringStream(file)
else:
  let fullDataDir = getAppDir() / dataDir

  template readRW(filename: string): ptr RWops not nil =
    safeRwFromFile(cstring(fullDataDir / filename), "r")

  template readStream(filename: string): Stream not nil=
    var stream = newFileStream(fullDataDir / filename)
    if stream.isNil: raise ValueError.newException(
      "Cannot open file stream:" & fullDataDir / filename)
    stream

proc newGame(renderer: RendererPtr): Game not nil =
  new result
  result.renderer = renderer

  result.font = safeOpenFontRW(
    readRW("DejaVuSans.ttf"), freesrc = 1, 28)

  result.player = newPlayer(renderer.safeLoadTexture_RW(
    readRW("player.png"), freesrc = 1))
  result.map = newMap(renderer.safeLoadTexture_RW(
    readRW("grass.png"), freesrc = 1),
    readStream("default.map"))

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
  while safePollEvent(event):
    case event.kind
    of QuitEvent:
      game.inputs[Input.quit] = true
    of KeyDown:
      game.inputs[event.key.keysym.scancode.toInput] = true
    of KeyUp:
      game.inputs[event.key.keysym.scancode.toInput] = false
    else:
      discard

proc formatTime(ticks: int): string =
  let mins = (ticks div 50) div 60
  let secs = (ticks div 50) mod 60
  interp"${mins:02}:${secs:02}"

proc formatTimeExact(ticks: int): string =
  let cents = (ticks mod 50) * 2
  interp"${formatTime(ticks)}:${cents:02}"

proc render(game: Game, tick: int) =
  # Draw over all drawings of the last frame with the default color
  game.renderer.safeClear()
  # Actual drawing here
  game.renderer.renderTee(game.player.texture, game.player.pos - game.camera)
  game.renderer.renderMap(game.map, game.camera)

  let time = game.player.time
  const white = color(255, 255, 255, 255)
  if time.begin >= 0:
    game.renderTextCached(formatTime(tick - time.begin), 50, 100, white)
  elif time.finish >= 0:
    game.renderTextCached("Finished in: " & formatTimeExact(time.finish),
      50, 100, white)
  if time.best >= 0:
    game.renderTextCached("Best time: " & formatTimeExact(time.best),
      50, 150, white)

  # Show the result on screen
  game.renderer.safePresent()

proc getTile(map: Map, x, y: int): uint8 =
  let
    nx = clamp(x div tileSize.x, 0, map.width - 1)
    ny = clamp(y div tileSize.y, 0, map.height - 1)
    pos = ny * map.width + nx

  map.tiles[pos]

proc getTile(map: Map, pos: Point2d): uint8 =
  map.getTile(pos.x.round.int, pos.y.round.int)

proc isSolid(map: Map, x, y: int): bool =
  map.getTile(x, y) notin {air, start, finish}

proc isSolid(map: Map, point: Point2d): bool =
  map.isSolid(point.x.round.int, point.y.round.int)

proc onGround(map: Map, pos: Point2d, size: Vector2d): bool =
  let size = size * 0.5
  result =
    map.isSolid(point2d(pos.x - size.x, pos.y + size.y + 1)) or
    map.isSolid(point2d(pos.x + size.x, pos.y + size.y + 1))

proc testBox(map: Map, pos: Point2d, size: Vector2d): bool =
  let size = size * 0.5
  result =
    map.isSolid(point2d(pos.x - size.x, pos.y - size.y)) or
    map.isSolid(point2d(pos.x + size.x, pos.y - size.y)) or
    map.isSolid(point2d(pos.x - size.x, pos.y + size.y)) or
    map.isSolid(point2d(pos.x + size.x, pos.y + size.y))

proc moveBox(map: Map, pos: var Point2d, vel: var Vector2d,
             size: Vector2d): set[Collision] {.discardable.} =
  let distance = vel.len
  let maximum = distance.int

  if distance < 0:
    return

  let fraction = 1.0 / float(maximum + 1)

  for i in 0 .. maximum:
    var newPos = pos + vel * fraction

    if map.testBox(newPos, size):
      var hit = false

      if map.testBox(point2d(pos.x, newPos.y), size):
        result.incl Collision.y
        newPos.y = pos.y
        vel.y = 0
        hit = true

      if map.testBox(point2d(newPos.x, pos.y), size):
        result.incl Collision.x
        newPos.x = pos.x
        vel.x = 0
        hit = true

      if not hit:
        result.incl Collision.corner
        newPos = pos
        vel = vector2d(0, 0)

    pos = newPos

proc physics(game: Game) =
  if game.inputs[Input.restart]:
    game.player.restartPlayer()

  let ground = game.map.onGround(game.player.pos, playerSize)

  if game.inputs[Input.jump]:
    if ground:
      game.player.vel.y = -21

  let direction = float(game.inputs[Input.right].int -
                        game.inputs[Input.left].int)

  game.player.vel.y += 0.75
  if ground:
    game.player.vel.x = 0.5 * game.player.vel.x + 4.0 * direction
  else:
    game.player.vel.x = 0.95 * game.player.vel.x + 2.0 * direction
  game.player.vel.x = clamp(game.player.vel.x, -8, 8)

  game.map.moveBox(game.player.pos, game.player.vel, playerSize)

proc moveCamera(game: Game) =
  const halfWin = float(windowSize.x div 2)
  when defined(fluidCamera):
    let dist = game.camera.x - game.player.pos.x + halfWin
    game.camera.x -= 0.05 * dist
  elif defined(innerCamera):
    let
      leftArea  = game.player.pos.x - halfWin - 100
      rightArea = game.player.pos.x - halfWin + 100
    game.camera.x = clamp(game.camera.x, leftArea, rightArea)
  else:
    game.camera.x = game.player.pos.x - halfWin

proc logic(game: Game, tick: int) =
  let time = addr game.player.time
  case game.map.getTile(game.player.pos)
  of start:
    time.begin = tick
  of finish:
    if time.begin >= 0:
      time.finish = tick - time.begin
      time.begin = -1
      if time.best < 0 or time.finish < time.best:
        time.best = time.finish
  else: discard

proc main =
  safe_sdl2.safeInit(INIT_VIDEO or INIT_TIMER or INIT_EVENTS)

  # defer blocks get called at the end of the procedure, even if an
  # exception has been thrown
  defer: safe_sdl2.safeQuit()

  safeSetHint("SDL_RENDER_SCALE_QUALITY", "2")

  const imgFlags: cint = IMG_INIT_PNG
  safeImageInit(imgFlags)
  defer: safeImageQuit()

  safeTtfInit()
  defer: safeTtfQuit()

  var window = safeCreateWindow(title = "Our own 2D platformer",
    x = SDL_WINDOWPOS_CENTERED, y = SDL_WINDOWPOS_CENTERED,
    w = windowSize.x, h = windowSize.y, flags = SDL_WINDOW_SHOWN)
  defer: window.safeDestroy()

  var renderer = window.safeCreateRenderer(index = -1,
    flags = Renderer_Accelerated or Renderer_PresentVsync)
  defer: renderer.safeDestroy()

  # Set the default color to use for drawing
  renderer.safeSetDrawColor(r = 110, g = 132, b = 174)

  var
    game = newGame(renderer)
    startTime = epochTime()
    lastTick = 0

  # Game loop, draws each frame
  while not game.inputs[Input.quit]:
    game.handleInput()

    let newTick = int((epochTime() - startTime) * 50)
    for tick in lastTick+1 .. newTick:
      game.physics()
      game.moveCamera()
      game.logic(tick)
    lastTick = newTick

    game.render(lastTick)

main()
