export class Turtlebot
  material: "default:dirt"
  autoDig: false
  autoBuild: false

  new: (operations = EmptyOperationStream) =>
    @operations = operations
  
  next: =>
    o, os = @operations\next!
    o, Turtlebot(os)

  andThen: (o) =>
    Turtlebot @operations\andThen(o)

{ :Turtlebot }