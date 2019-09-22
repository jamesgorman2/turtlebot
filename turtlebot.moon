export class Turtlebot
  new: (
    operations = EmptyOperationStream,
    material = "default:dirt",
    autoDig = false,
    autoBuild = false
  ) =>
    @operations = operations
    @material = material
    @autoDig = autoDig
    @autoBuild =autoBuild
  
  next: =>
    o, os = @operations\next!
    o, Turtlebot(os, @material, @autoDig, @autoBuild)

  andThen: (o) =>
    Turtlebot(@operations\andThen(o), @material, @autoDig, @autoBuild)

  complete: => @operations.complete

  setAutoDig: (b) =>
    Turtlebot(@operations, @material, b, @autoBuild)

  setAutoBuild: (b) =>
    Turtlebot(@operations, @material, @autoDig, b)

  setMaterial: (m) =>
    Turtlebot(@operations, m, @autoDig, @autoBuild)
      

{ :Turtlebot }