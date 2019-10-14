Array = {
  empty: (t) ->
    for k, v in ipairs(t)
      return false
    true
  head: (t) -> t[1]
  tail: (t) -> [i for i in *t[2,]]
  prepend: (i, t) ->
    tNew = {k,v for k,v in pairs t}
    table.insert(tNew, 1, i)
    tNew
}
local Type
Type = {
  moonObject: (o) ->
    type(o) == "table" and o.__class != nil and o.__class.__name != nil
  moonClass: (o) ->
    type(o) == "table" and o.__name != nil
  name: (o) ->
    if Type.moonObject(o)
      o.__class.__name
    elseif Type.moonClass(o)
      o.__name
    else
      type(o)
  parent: (o) ->
    if Type.moonObject(o)
      o.__class.__parent
    elseif Type.moonClass(o)
      o.__parent
    else
      nil
  instanceOf: (o, t) ->
    oName = Type.name(o)
    tName = if Type.moonClass(t) or Type.moonObject(t) then Type.name(t) else t
    if oName == tName
      true
    elseif type(o) == "table" and Type.parent(o) != nil
      Type.instanceOf Type.parent(o), t
    else
      false
}

export class Operation
  new: (f) => @f = f
  exec: (t) => 
    print("operation exec", DumpTable(t), DumpTable(@f))
    self.f(t)
  @of: (o) ->
    if Type.instanceOf(o, Operation)
      o
    elseif Type.instanceOf(o, 'function')
      Operation((t) ->
        print("operation", DumpTable(t), DumpTable(o))
        o()
        t
      )
    else
      assert false, "Expected one of Operation or function, got #{Type.name o}"

export EmptyOperation = Operation((a) -> a)
export EmptyOperationStream
local ConcatOperationStream, IfOperationStream, SingleOperationStream, RepeatOperationStream, RepeatUntilOperationStream, RepeatWhileOperationStream

export class OperationStream
  -- returns (the next Operation, the new OperationsStream)
  next: => EmptyOperation, EmptyOperationStream
  
  complete: true

  andThen: (o) =>
    lhs = self
    rhs = OperationStream.of(o)
    print("andthen", lhs.__class.__name, rhs.__class.__name)
    if lhs == EmptyOperationStream
      print("andThen", "rhs only")
      rhs
    elseif rhs == EmptyOperationStream
      print("andThen", "lhs only")
      lhs
    else
      print("andThen", "concat")
      OperationStream.concat(lhs, rhs)
   
  @empty: EmptyOperationStream
 
  @of: (o) -> 
    if Type.instanceOf(o, Operation)
      print("of Operation")
      SingleOperationStream(o)
    elseif Type.instanceOf(o, OperationStream)
      print("of OperationStream")
      o
    elseif Type.instanceOf(o, "table")
      for k, item in ipairs o
        assert Type.instanceOf(item, Operation) or Type.instanceOf(item, OperationStream), "Expected Operation or OperationStream, got #{Type.name item}"
      print("of table", #o)
      ConcatOperationStream([OperationStream.of(item) for i, item in ipairs o])
    elseif Type.instanceOf(o, "function")
      print("of function")
      SingleOperationStream(Operation.of(o))
    else
      assert false, "Expected one of Operation, OperationStream, table, or function, got #{Type.name o}"
  
  @concat: (a, b) ->
    OperationStream.of({a, b})

  @iff: (f, a, b) ->
    if not Type.instanceOf(f, "function")
      assert false, "f must be a function, got #{Type.name f}"
    IfOperationStream(f, OperationStream.of(a), OperationStream.of(b))

  @repeatFor: (o, count) ->
    if not Type.instanceOf(count, "number")
      assert false, "count must be a number, got #{Type.name count}"
    RepeatOperationStream(OperationStream.of(o), count)
   
  @repeatWhile: (o, f) ->
    if not Type.instanceOf(f, "function")
      assert false, "f must be a function, got #{Type.name f}"
    RepeatWhileOperationStream(OperationStream.of(o), f)
    
  @repeatUntil: (o, f) ->
    if not Type.instanceOf(f, "function")
      assert false, "f must be a function, got #{Type.name f}"
    RepeatUntilOperationStream(OperationStream.of(o), f)
   
EmptyOperationStream = OperationStream!

class SingleOperationStream extends OperationStream
  new: (o) => @operation = o
  complete: false
  next: =>
    @operation, EmptyOperationStream
    
class ConcatOperationStream extends OperationStream
  -- streams: list of OperationStreams
  new: (streams) => @streams = streams
  complete: false
  next: =>
    minetest.debug("ConcatOperationStream", tostring(#@streams), DumpTable(@streams))
    if Array.empty(@streams) or Array.head(@streams) == nil
      minetest.debug("ConcatOperationStream", "very empty", tostring(Array.empty(@streams)), tostring(Array.head(@streams)))
      return EmptyOperation, EmptyOperationStream
    nextOperation, hNext = (Array.head @streams)\next!
    tNext = Array.tail @streams
    if not hNext.complete
      minetest.debug("ConcatOperationStream", "still on head", DumpTable(hNext))
      minetest.debug("ConcatOperationStream", "--", DumpTable(tNext))
      nextOperation, ConcatOperationStream(Array.prepend(hNext, tNext))
    elseif not Array.empty tNext
      minetest.debug("ConcatOperationStream", "head complete", tostring(#tNext))
      nextOperation, ConcatOperationStream(tNext)
    else
      minetest.debug("ConcatOperationStream", "complete")
      nextOperation, EmptyOperationStream

class IfOperationStream extends OperationStream
  new: (f, a, b) =>
    @f = f
    @a = a
    @b = b
  complete: false
  next: =>
    if @f!
      @a\next!
    else
      @b\next!

class RepeatOperationStream extends OperationStream
  -- stream: a single stream
  -- count: the number of iterations
  -- initialStream: internal use only
  new: (stream, count, initialStream) => 
    @stream = stream
    @count = count
    @initialStream = if initialStream != nil then initialStream else stream
  complete: false
  next: =>
    nextOperation, nextStream = @stream\next!

    if not nextStream.complete
      nextOperation, RepeatOperationStream(nextStream, @count, @initialStream)
    elseif nextStream.complete
      if @count <=1
        nextOperation, EmptyOperationStream
      else 
        nextOperation, RepeatOperationStream(@initialStream, @count - 1)

class RepeatWhileOperationStream extends OperationStream
  -- stream: a single stream
  -- f: function returning a boolean
  -- initialStream: internal use only; the seed stream
  -- skipTest: internal use only; true if we are draining the stream within a loop
  new: (stream, f, initialStream, skipTest) => 
    @stream = stream
    @f = f
    @initialStream = if initialStream != nil then initialStream else stream
    @skipTest = if skipTest != nil then skipTest else false
  complete: false
  next: =>
    minetest.debug("while", tostring(@skipTest), tostring(@f!))
    if @skipTest or @f!
      minetest.debug("while", "next stream")
      nextOperation, nextStream = @stream\next!  
      if nextStream.complete
        minetest.debug("while", "stream complete")
        nextOperation, RepeatWhileOperationStream(@initialStream, @f)
      else
        minetest.debug("while", "stream continue")
        nextOperation, RepeatWhileOperationStream(nextStream, @f, @initialStream, true)
    else 
      minetest.debug("while","complete")
      EmptyOperation, EmptyOperationStream
      
class RepeatUntilOperationStream extends OperationStream
  -- stream: a single stream
  -- f: function returning a boolean
  -- initialStream: internal use only; the seed stream
  new: (stream, f, initialStream, skipTest) => 
    @stream = stream
    @f = f
    @initialStream = if initialStream != nil then initialStream else stream
  complete: false
  next: =>
    nextOperation, nextStream = @stream\next!

    if not nextStream.complete
      nextOperation, RepeatUntilOperationStream(nextStream, @f, @initialStream)
    elseif nextStream.complete
      if @f!
        nextOperation, EmptyOperationStream
      else 
        nextOperation, RepeatUntilOperationStream(@initialStream, @f)
      
{
  :Operation,
  :EmptyOperation,
  :OperationStream,
  :EmptyOperationStream
}