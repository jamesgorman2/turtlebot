-- A short tower
Turtlebot()\andThen({
  move.up, 
  place.down(), 
  move.up, 
  place.down()
})

----------------------------
-- Command composition
Turtlebot()\andThen({
  move.up
})\andThen({
  place.down()
})\andThen({
  move.up
})\andThen({
  place.down()
})

----------------------------
-- A tall tower using a loop
buildUp = OperationStream.of({
  autoDig(true),
  autoBuild(true),
  material("default:stone")
})\andThen(
  OperationStream.repeatFor(
    move.up,
    20
  )
)

Turtlebot()\andThen(buildUp)

------------
-- Build a wall
findDirection = (dir) -> OperationStream.repeatWhile(
  turn.left,
  -> self.facing() != dir
)

aboutFace = OperationStream.of({turn.left, turn.left})

buildSingleCourse = (width) -> OperationStream.repeatFor(
    move.forward,
    width
  )

buildWall = (dir, width, height) -> OperationStream.of({
  findDirection(dir),
  autoDig(true),
  autoBuild(true),
  material("default:stone")
})\andThen(
  OperationStream.repeatFor(
    buildSingleCourse(width)\andThen({
      place.down(), -- since we're floating!
      move.up, 
      aboutFace
    }),
    height
  )
)

Turtlebot()\andThen(
  buildWall(direction.South, 10, 4)
)


