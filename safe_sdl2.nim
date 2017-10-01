import sdl2, sdl2.ttf, sdl2.image

type
  SDLException = object of Exception

proc safeGetError*: cstring {.inline.} =
  result = getError()
  doAssert result != nil

template sdlFailIf(cond: typed, reason: string) =
  if cond: raise SDLException.newException(
    reason & ", SDL error: " & $safeGetError())

proc safeInit*(flags: cint) {.inline.} =
  sdlFailIf(not sdl2.init(flags)):
    "SDL2 initialization failed"

proc safeCreateWindow*(title: cstring; x, y, w, h: cint;
                   flags: uint32): WindowPtr {.inline.} =
  doAssert title != nil
  result = createWindow(title, x, y, w, h, flags)
  sdlFailIf result.isNil:
    "Window could not be created"

proc safeGetSurface*(window: WindowPtr): SurfacePtr {.inline.} =
  doAssert window != nil
  result = getSurface(window)
  sdlFailIf result.isNil:
    "Unable to get window surface"

proc safeLoadBMP*(file: string): SurfacePtr {.inline.} =
  doAssert file != nil
  result = loadBMP(file)
  sdlFailIf result.isNil:
    "Unable to load BMP image " & file

proc safeBlitSurface*(src: SurfacePtr; srcrect: ptr Rect; dst: SurfacePtr;
    dstrect: ptr Rect) {.inline.} =
  doAssert src != nil
  doAssert dst != nil
  sdlFailIf(not blitSurface(src, nil, dst, nil)):
    "Unable to blit an image to a surface"

proc safeUpdateSurface*(window: WindowPtr) {.inline.} =
  doAssert window != nil
  sdlFailIf(not updateSurface(window)):
    "Unable to update window surface"

proc safeDestroy*(surface: SurfacePtr) {.inline.} =
  doAssert surface != nil
  destroy(surface)

proc safeDestroy*(window: WindowPtr) {.inline.} =
  doAssert window != nil
  destroy(window)

proc safePollEvent*(event: var Event): Bool32 {.inline.} =
  return pollEvent(event)

proc safeQuit*() {.inline.} =
  sdl2.quit()

proc safeMapRGB* (format: ptr PixelFormat; r,g,b: uint8): uint32 {.inline.} =
  doAssert format != nil
  mapRGB(format, r, g, b)

proc safeFillRect*(dst: SurfacePtr; rect: ptr Rect; color: uint32) {.inline.} =
  doAssert dst != nil
  sdlFailIf(not fillRect(dst, rect, color)):
    "Unable to fill a rectangular area of a surface"

proc safeDelay*(ms: uint32) {.inline.} =
  delay(ms)

proc safeSetHint*(name: cstring, value: cstring) {.inline.} =
  doAssert name != nil
  doAssert value != nil
  sdlFailIf(not setHint(name, value)):
    "Unable to set some hinting-related SDL2 options"

proc safeCreateRenderer*(window: WindowPtr; index: cint; flags: cint): RendererPtr {.inline.} =
  doAssert window != nil
  result = createRenderer(window, index, flags)
  sdlFailIf result.isNil: "Renderer could not be created"

proc safeDestroy*(renderer: RendererPtr) {.inline.} =
  doAssert renderer != nil
  destroy(renderer)

proc safeSetDrawColor*(renderer: RendererPtr; r, g, b: uint8, a = 255'u8) {.inline.} =
  doAssert renderer != nil
  sdlFailIf(not setDrawColor(renderer, r, g, b, a)):
    "Unable to set drawing color"

proc safeClear*(renderer: RendererPtr) {.inline.} =
  doAssert renderer != nil
  sdlFailIf(clear(renderer) != 0):
    "Unable to clear renderer"

proc safePresent*(renderer: RendererPtr) {.inline.} =
  doAssert renderer != nil
  present(renderer)

proc safeCopyEx*(renderer: RendererPtr; texture: TexturePtr;
                 srcrect, dstrect: var Rect; angle: cdouble; center: ptr Point;
                 flip: RendererFlip = SDL_FLIP_NONE) {.inline.} =
  doAssert renderer != nil
  doAssert texture != nil

  sdlFailIf(not copyEx(renderer, texture, srcrect, dstrect, angle, center, flip)):
    "Unable to copy texture data over to a renderer"

proc safeCopy*(renderer: RendererPtr; texture: TexturePtr;
                         srcrect, dstrect: ptr Rect) {.inline.} =

  doAssert renderer != nil
  doAssert texture != nil
  doAssert srcrect != nil
  doAssert dstrect != nil

  sdlFailIf(not sdl2.copy(renderer, texture, srcrect, dstrect)):
    "Unable to copy texture data over to a renderer"

proc safeSetFontOutline*(font: FontPtr, outline: cint) {.inline.} =
  doAssert font != nil
  doAssert outline >= 0
  setFontOutline(font, outline)

proc safeRenderUtf8Blended*(font: FontPtr; text: cstring; fg: Color): SurfacePtr {.inline.} =
  doAssert font != nil
  doAssert text != nil
  result = renderUtf8Blended(font, text, fg)
  sdlFailIf result.isNil: "Unable to render UTF8-blended text"

proc safeSetSurfaceAlphaMod*(surface: SurfacePtr; alpha: uint8) {.inline.} =
  doAssert surface != nil
  sdlFailIf(setSurfaceAlphaMod(surface, alpha) != 0):
    "Unable to set surface alpha"

proc safeCreateTextureFromSurface*(renderer: RendererPtr; surface: SurfacePtr): TexturePtr {.inline.} =
  doAssert renderer != nil
  doAssert surface != nil
  result = createTextureFromSurface(renderer, surface)
  sdlFailIf result.isNil: "Unable to render create texture from surface"

proc safeFreeSurface*(surface: SurfacePtr) {.inline.} =
  doAssert surface != nil
  freeSurface(surface)

proc safeDestroy*(texture: TexturePtr) {.inline.} =
  doAssert texture != nil
  destroy texture

proc safeOpenFont*(file: cstring; ptsize: cint): FontPtr {.inline.} =
  doAssert file != nil
  result = openFont(file, ptsize)
  sdlFailIf result.isNil: "Failed to load font"

proc safeLoadTexture*(renderer: RendererPtr; file: cstring): TexturePtr {.inline.} =
  doAssert renderer != nil
  doAssert file != nil
  result = loadTexture(renderer, file)
  sdlFailIf result.isNil: "Failed to load texture"

proc safeImageInit*(flags: cint = IMG_INIT_JPG or IMG_INIT_PNG) {.inline.} =
  sdlFailIf(image.init(flags) != flags):
    "SDL2 Image initialization failed"

proc safeImageQuit* {.inline.} =
  image.quit()

proc safeTtfInit* {.inline.} =
  sdlFailIf(ttfInit() == SdlError): "SDL2 TTF initialization failed"

proc safeTtfQuit* {.inline.} =
  ttfQuit()

proc safeRwFromFile*(file: cstring; mode: cstring): RWopsPtr {.inline.} =
  doAssert file != nil
  doAssert mode != nil
  result = rwFromFile(file, mode)
  sdlFailIf result.isNil: "Cannot create RWops from file"

proc safeOpenFontRW*(src: ptr RWops; freesrc: cint; ptsize: cint): FontPtr {.inline.} =
  doAssert src != nil
  doAssert ptsize >= 1
  result = openFontRW(src, freesrc, ptsize)
  sdlFailIf result.isNil: "Unable to read font from file"

proc safeRwFromConstMem*(mem: pointer; size: cint): RWopsPtr {.inline.} =
  doAssert mem != nil
  doAssert size >= 1
  result = rwFromConstMem(mem, size)
  sdlFailIf result.isNil: "Unable to read from const memory"

proc safeLoadTexture_RW*(renderer: RendererPtr; src: RWopsPtr;
                         freesrc: cint): TexturePtr {.inline.} =
  doAssert renderer != nil
  doAssert src != nil
  result = loadTexture_RW(renderer, src, freesrc)
  sdlFailIf result.isNil: "Unable to load a texture"
