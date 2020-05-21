# author: Ethosa
import
  ../thirdparty/opengl,

  ../core/vector2,
  ../core/rect2,
  ../core/anchor,
  ../core/input,
  ../core/enums,
  ../core/color,

  ../nodes/node,
  control


type
  ScrollObj* = object of ControlObj
    thumb_y_has_mouse*, thumb_x_has_mouse*: bool
    thumb_width*, thumb_height*: float
    viewport_w*, viewport_h*: float
    viewport_x*, viewport_y*: float
    thumb_color*: ColorRef
    back_color*: ColorRef
  ScrollPtr* = ptr ScrollObj


proc Scroll*(name: string, variable: var ScrollObj): ScrollPtr =
  nodepattern(ScrollObj)
  controlpattern()
  variable.rect_size.x = 256
  variable.rect_size.y = 256
  variable.viewport_h = 256
  variable.viewport_w = 256
  variable.viewport_x = 0
  variable.viewport_y = 0
  variable.thumb_width = 8
  variable.thumb_height = 8
  variable.back_color = Color(0, 0, 0, 128)
  variable.thumb_color = Color(0, 0, 0, 128)
  variable.thumb_y_has_mouse = false
  variable.thumb_x_has_mouse = false

proc Scroll*(obj: var ScrollObj): ScrollPtr {.inline.} =
  Scroll("Scroll", obj)


method addChild*(self: ScrollPtr, other: NodePtr) =
  if self.children.len() == 0:
    self.children.add(other)
    other.parent = self

method dublicate*(self: ScrollPtr, obj: var ScrollObj): ScrollPtr {.base.} =
  obj = self[]
  obj.addr

method resize*(canvas: ScrollPtr, w, h: GLfloat) =
  canvas.rect_size.x = w
  canvas.rect_size.y = h

method draw*(self: ScrollPtr, w, h: GLfloat) =
  self.calcGlobalPosition()
  let
    x = -w/2 + self.global_position.x
    y = h/2 - self.global_position.y

  glColor4f(self.background_color.r, self.background_color.g, self.background_color.b, self.background_color.a)
  glRectf(x, y, x+self.viewport_w, y-self.viewport_h)

  if self.children.len() > 0:
    var child = self.children[0]
    self.resize(child.rect_size.x, child.rect_size.y)
    let
      hback_w = self.viewport_w
      vback_h = self.viewport_h
      thumb_h = self.viewport_h * (self.viewport_h / self.rect_size.y)
      thumb_w = self.viewport_w * (self.viewport_w / self.rect_size.x)
      thumb_x = self.viewport_w * (self.viewport_x / self.rect_size.x)
      thumb_y = self.viewport_h * (self.viewport_y / self.rect_size.y)
    child.position.x = -self.viewport_x
    child.position.y = -self.viewport_y

    if self.viewport_h < self.rect_size.y:
      # Back:
      glColor4f(self.back_color.r, self.back_color.g, self.back_color.b, self.back_color.a)
      glRectf(x + self.viewport_w - self.thumb_width, y, x+self.viewport_w, y-self.viewport_h)

      # Thumb:
      glColor4f(self.thumb_color.r, self.thumb_color.g, self.thumb_color.b, self.thumb_color.a)
      glRectf(x + self.viewport_w - self.thumb_width, y - thumb_y, x+self.viewport_w, y - thumb_y - thumb_h)

  # Press
  if self.pressed:
    self.press(last_event.x, last_event.y)

method scrollBy*(self: ScrollPtr, x, y: float) {.base.} =
  if x + self.viewport_x + self.viewport_w < self.rect_size.x and x + self.viewport_x > 0:
    self.viewport_x += x
  elif x < 0:
    self.viewport_x = 0
  elif x > 0:
    self.viewport_x = self.rect_size.x - self.viewport_w

  if y + self.viewport_y + self.viewport_h < self.rect_size.y and y + self.viewport_y > 0:
    self.viewport_y += y
  elif y < 0:
    self.viewport_y = 0
  elif y > 0:
    self.viewport_y = self.rect_size.y - self.viewport_h

method handle*(self: ScrollPtr, event: InputEvent, mouse_on: var NodePtr) =
  procCall self.ControlPtr.handle(event, mouse_on)

  let
    mouse_in = Rect2(self.global_position, Vector2(self.viewport_w, self.viewport_h)).hasPoint(event.x, event.y)
    hback_w = self.viewport_w
    vback_h = self.viewport_h
    thumb_h = self.viewport_h * (self.viewport_h / self.rect_size.y)
    thumb_w = self.viewport_w * (self.viewport_w / self.rect_size.x)
    thumb_x = self.viewport_w * (self.viewport_x / self.rect_size.x)
    thumb_y = self.viewport_h * (self.viewport_y / self.rect_size.y)
    mouse_in_y = Rect2(
        self.global_position.x + self.viewport_w - self.thumb_width,
        self.global_position.y + thumb_y,
        self.thumb_width,
        thumb_h
      ).hasPoint(event.x, event.y)

  if mouse_in:
    if event.kind == KEYBOARD:
      if event.key_cint in pressed_keys_cints:  # Special chars
        if event.key_cint == K_UP:
          self.scrollBy(0, -40)
        elif event.key_cint == K_DOWN:
          self.scrollBy(0, 40)
  if (mouse_in_y and mouse_pressed) or self.thumb_y_has_mouse:
    self.thumb_y_has_mouse = true
    self.scrollBy(0, -event.yrel)
  if not mouse_pressed and self.thumb_y_has_mouse:
    self.thumb_y_has_mouse = false