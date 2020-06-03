# --- Test 35. Event handlers with macros. --- #
import nodesnim


Window("test35")

var
  mainscene: SceneObj
  main = Scene("Main", mainscene)
  btn: ButtonObj
  node = Button(btn)

node.setText("Hello")
node.setAnchor(0.5, 0.5, 0.5, 0.5)


node@ready:
  echo "hello!"

node@input(event):
  if event.isInputEventMouseButton() and event.pressed:
    echo "clicked"

node@on_click(x, y):
  node.setText("clicked in " & $x & "," & $y & ".")


main.addChild(node)
addMainScene(main)
windowLaunch()