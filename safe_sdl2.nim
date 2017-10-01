import sdl2, sdl2.ttf, sdl2.image

type
  SDLException = object of Exception

var
  sdlInitialized, = false
  imageInitialized = false
  ttfInitIalized = false

proc safeGetError*: cstring not nil {.inline.} =
  let ret = getError()
  if ret.isNil or ret == "":
    raise SDLException.newException("Unable to get an SDL2 error!")
  else:
    return ret

template sdlFail(reason: string not nil) =
  raise SDLException.newException(
    reason & ", SDL error: " & $safeGetError())

template sdlFailIf(cond: typed, reason: string not nil) =
  if cond: sdlFail(reason)

proc safeInit*(flags: cint) {.inline.} =
  doAssert(not sdlInitialized)
  sdlFailIf(not sdl2.init(flags)):
    "SDL2 initialization failed"
  sdlInitialized = true

proc safeCreateWindow*(title: cstring not nil; x, y, w, h: cint;
                   flags: uint32): WindowPtr not nil {.inline.} =
  doAssert sdlInitialized
  let ret = createWindow(title, x, y, w, h, flags)
  if ret.isNil:
    sdlFail "Window could not be created"
  else:
    return ret

proc safeGetSurface*(window: WindowPtr): SurfacePtr not nil {.inline.} =
  doAssert sdlInitialized
  doAssert window != nil
  let ret = getSurface(window)
  if ret.isNil:
    sdlFail "Unable to get window surface"
  else:
    return ret

proc safeLoadBMP*(file: string not nil): SurfacePtr not nil {.inline.} =
  doAssert sdlInitialized
  let ret = loadBMP(file)
  if ret.isNil:
    sdlFail "Unable to load BMP image " & file
  else:
    return ret

proc safeBlitSurface*(src: SurfacePtr; srcrect: ptr Rect; dst: SurfacePtr;
    dstrect: ptr Rect) {.inline.} =
  doAssert sdlInitialized
  doAssert src != nil
  doAssert dst != nil
  sdlFailIf(not blitSurface(src, nil, dst, nil)):
    "Unable to blit an image to a surface"

proc safeUpdateSurface*(window: WindowPtr) {.inline.} =
  doAssert sdlInitialized
  doAssert window != nil
  sdlFailIf(not updateSurface(window)):
    "Unable to update window surface"

proc safeDestroy*(surface: var SurfacePtr) {.inline.} =
  doAssert sdlInitialized
  doAssert surface != nil
  destroy(surface)
  surface = nil

proc safeDestroy*(window: var WindowPtr) {.inline.} =
  doAssert sdlInitialized
  doAssert window != nil
  destroy(window)
  window = nil

proc safePollEvent*(event: var Event): Bool32 {.inline.} =
  doAssert sdlInitialized
  return pollEvent(event)

proc safeQuit*() {.inline.} =
  doAssert sdlInitialized
  sdl2.quit()
  sdlInitialized = false

proc safeMapRGB* (format: ptr PixelFormat; r,g,b: uint8): uint32 {.inline.} =
  doAssert sdlInitialized
  doAssert format != nil
  mapRGB(format, r, g, b)

proc safeFillRect*(dst: SurfacePtr; rect: ptr Rect; color: uint32) {.inline.} =
  doAssert sdlInitialized
  doAssert dst != nil
  sdlFailIf(not fillRect(dst, rect, color)):
    "Unable to fill a rectangular area of a surface"

proc safeDelay*(ms: uint32) {.inline.} =
  doAssert sdlInitialized
  delay(ms)

proc safeSetHint*(name: cstring not nil, value: cstring not nil) {.inline.} =
  doAssert sdlInitialized
  sdlFailIf(not setHint(name, value)):
    "Unable to set some hinting-related SDL2 options"

proc safeCreateRenderer*(window: WindowPtr; index: cint; flags: cint): RendererPtr not nil {.inline.} =
  doAssert sdlInitialized
  doAssert window != nil
  let ret = createRenderer(window, index, flags)
  if ret.isNil:
    sdlFail "Renderer could not be created"
  else:
    return ret

proc safeDestroy*(renderer: var RendererPtr) {.inline.} =
  doAssert sdlInitialized
  doAssert renderer != nil
  destroy(renderer)
  renderer = nil

proc safeSetDrawColor*(renderer: RendererPtr; r, g, b: uint8, a = 255'u8) {.inline.} =
  doAssert sdlInitialized
  doAssert renderer != nil
  sdlFailIf(not setDrawColor(renderer, r, g, b, a)):
    "Unable to set drawing color"

proc safeClear*(renderer: RendererPtr) {.inline.} =
  doAssert sdlInitialized
  doAssert renderer != nil
  sdlFailIf(clear(renderer) != 0):
    "Unable to clear renderer"

proc safePresent*(renderer: RendererPtr) {.inline.} =
  doAssert sdlInitialized
  doAssert renderer != nil
  present(renderer)

proc safeCopyEx*(renderer: RendererPtr; texture: TexturePtr;
                 srcrect, dstrect: var Rect; angle: cdouble; center: ptr Point;
                 flip: RendererFlip = SDL_FLIP_NONE) {.inline.} =
  doAssert sdlInitialized
  doAssert renderer != nil
  doAssert texture != nil

  sdlFailIf(not copyEx(renderer, texture, srcrect, dstrect, angle, center, flip)):
    "Unable to copy texture data over to a renderer"

proc safeCopy*(renderer: RendererPtr; texture: TexturePtr;
                         srcrect, dstrect: ptr Rect) {.inline.} =
  doAssert sdlInitialized
  doAssert renderer != nil
  doAssert texture != nil
  doAssert srcrect != nil
  doAssert dstrect != nil

  sdlFailIf(not sdl2.copy(renderer, texture, srcrect, dstrect)):
    "Unable to copy texture data over to a renderer"

proc safeSetFontOutline*(font: FontPtr, outline: cint) {.inline.} =
  doAssert ttfInitIalized
  doAssert font != nil
  doAssert outline >= 0
  setFontOutline(font, outline)

proc safeRenderUtf8Blended*(font: FontPtr; text: cstring; fg: Color): SurfacePtr not nil {.inline.} =
  doAssert ttfInitIalized
  doAssert font != nil
  doAssert text != nil
  let ret = renderUtf8Blended(font, text, fg)
  if ret.isNil:
    sdlFail "Unable to render UTF8-blended text"
  else:
    return ret

proc safeSetSurfaceAlphaMod*(surface: SurfacePtr; alpha: uint8) {.inline.} =
  doAssert sdlInitialized
  doAssert surface != nil
  sdlFailIf(setSurfaceAlphaMod(surface, alpha) != 0):
    "Unable to set surface alpha"

proc safeCreateTextureFromSurface*(renderer: RendererPtr; surface: SurfacePtr): TexturePtr not nil {.inline.} =
  doAssert sdlInitialized
  doAssert renderer != nil
  doAssert surface != nil
  let ret = createTextureFromSurface(renderer, surface)
  if ret.isNil:
    sdlFail "Unable to render create texture from surface"
  else:
    return ret

proc safeFreeSurface*(surface: SurfacePtr) {.inline.} =
  doAssert sdlInitialized
  doAssert surface != nil
  freeSurface(surface)

proc safeDestroy*(texture: var TexturePtr) {.inline.} =
  doAssert sdlInitialized
  doAssert texture != nil
  destroy texture
  texture = nil

proc safeOpenFont*(file: cstring not nil; ptsize: cint): FontPtr {.inline.} =
  doAssert ttfInitIalized
  result = openFont(file, ptsize)
  sdlFailIf result.isNil: "Failed to load font"

proc safeLoadTexture*(renderer: RendererPtr; file: cstring not nil): TexturePtr not nil {.inline.} =
  doAssert sdlInitialized
  doAssert renderer != nil
  let ret = loadTexture(renderer, file)
  if ret.isNil:
    sdlFail "Failed to load texture"
  else:
    return ret

proc safeImageInit*(flags: cint = IMG_INIT_JPG or IMG_INIT_PNG) {.inline.} =
  doAssert sdlInitialized
  doAssert(not imageInitialized)
  sdlFailIf(image.init(flags) != flags):
    "SDL2 Image initialization failed"
  imageInitialized = true

proc safeImageQuit* {.inline.} =
  doAssert sdlInitialized
  doAssert imageInitialized
  image.quit()
  imageInitialized = false

proc safeTtfInit* {.inline.} =
  doAssert sdlInitialized
  doAssert(not ttfInitialized)
  sdlFailIf(ttfInit() == SdlError): "SDL2 TTF initialization failed"
  ttfInitialized = true

proc safeTtfQuit* {.inline.} =
  doAssert ttfInitialized
  ttfQuit()
  ttfInitialized = false

proc safeRwFromFile*(file: cstring; mode: cstring not nil): RWopsPtr not nil {.inline.} =
  doAssert sdlInitialized
  doassert file != nil
  let ret = rwFromFile(file, mode)
  if ret.isNil:
    sdlFail "Cannot create RWops from file"
  else:
    return ret

proc safeOpenFontRW*(src: ptr RWops; freesrc: cint; ptsize: cint): FontPtr not nil {.inline.} =
  doAssert ttfInitIalized
  doAssert src != nil
  doAssert ptsize >= 1
  let ret = openFontRW(src, freesrc, ptsize)
  if ret.isNil:
    sdlFail "Unable to read font from file"
  else:
    return ret

proc safeRwFromConstMem*(mem: pointer not nil; size: cint): RWopsPtr not nil {.inline.} =
  doAssert sdlInitIalized
  doAssert size >= 1
  let ret = rwFromConstMem(mem, size)
  if ret.isNil:
    sdlFail "Unable to read from const memory"
  else:
    return ret

proc safeLoadTexture_RW*(renderer: RendererPtr; src: RWopsPtr;
                         freesrc: cint): TexturePtr not nil {.inline.} =
  doAssert sdlInitIalized
  doAssert renderer != nil
  doAssert src != nil
  let ret = loadTexture_RW(renderer, src, freesrc)
  if ret.isNil:
    sdlFail "Unable to load a texture"
  else:
    return ret
