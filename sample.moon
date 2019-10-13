Turtlebot()\andThen({
  move.up, 
  place.down(), 
  move.up, 
  place.down()
})

----------------------------

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

buildUp = OperationStream.of({
  findNorth,
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

findNorth = OperationStream.repeatWhile(
  turn.left,
  -> self.facing != direction.North
)

aboutFace = OperationStream.of({turn.left, turn.left})

buildSingleCourse = OperationStream.repeat(
    move.forward,
    10
  )

buildWall = OperationStream.of({
  findNorth,
  autoDig(true),
  autoBuild(true),
  material("default:stone")
})\andThen(
  OperationStream.repeatFor(
    buildSingleCourse\andThen({
      move.up, 
      aboutFace
    }),
    4
  )
)

Turtlebot()\andThen(buildWall)


