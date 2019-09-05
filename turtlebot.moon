class Turtlebot
  @start: Turtlebot!
  
  material: "default:dirt"
  autoDig: false
  autoBuild: false

  new: (operations = EmptyOperationStream) =>
    @operations = operations
  
  next: =>
    o, os = @operations.next!
    o, Turtlebot(os)

  then: (o) =>
    Turtlebot @operations\then(o)
  