Array = {
  empty: (t) ->
    for k, v in ipairs(t)
      return false
    true
  head: (t) -> t[1]
  tail: (t) -> [i for i in *t[2,]]
  prepend: (i, t) -> table.insert(copy(t), 1, i)
}
Type = {
  instanceOf: (o, t) ->
    if type(o) == t or (type(o) == "table" and o.__class and (o.__class.__name == t or (type(t) == "table" and o.__class.__name == t.__name)))
      true
    elseif type(o) == "table" and o.__parent != nil
      Type.instanceOf o.__parent, t
    else
      false
}

export class Operation
  new: (f) => @f = f
  exec: (t) => 
    minetest.debug("operation exec", DumpTable(t), DumpTable(@f))
    self.f(t)
  @of: (o) ->
    if Type.instanceOf(o, Operation)
      o
    elseif Type.instanceOf(o, 'function')
      Operation((t) ->
        minetest.debug("operation", DumpTable(t), DumpTable(o))
        o()
        t
      )
    else
      assert false, "Expected one of Operation or function, got #{type o}"

export EmptyOperation = Operation((a) => a)
export EmptyOperationStream
local ConcatOperationStream, IfOperationStream, SingleOperationStream, RepeatOperationStream, RepeatUntilOperationStream, RepeatWhileOperationStream

export class OperationStream
  -- returns (the next Operation, the new OperationsStream)
  next: => EmptyOperation, EmptyOperationStream
  
  complete: true

  andThen: (o) =>
    lhs = self
    rhs = OperationStream.of(o)
    minetest.debug("andthen", lhs.__class.__name, rhs.__class.__name)
    if lhs == EmptyOperationStream
      rhs
    elseif rhs == EmptyOperationStream
      lhs
    else
      OperationStream.concat(rhs, lhs)
   
  @empty: EmptyOperationStream
 
  @of: (o) -> 
    if Type.instanceOf(o, Operation)
      minetest.debug("of Operation")
      SingleOperationStream(o)
    elseif Type.instanceOf(o, OperationStream)
      minetest.debug("of OperationStream")
      o
    elseif Type.instanceOf(o, "table")
      for k, o in ipairs os
        assert Type.instanceOf(o, Operation) or Type.instanceOf(o, OperationStream), 
          "Expected Operation or OperationStream, got #{type o}"
      minetest.debug("of table", #os)
      ConcatOperationStream([OperationStream.of(item) for i, item in ipairs o])
    elseif Type.instanceOf(o, "function")
      minetest.debug("of function")
      SingleOperationStream(Operation.of(o))
    else
      assert false, "Expected one of Operation, OperationStream, table, or function, got #{type o}"
  
  @concat: (a, b) ->
    OperationStream.of({a, b})

  @iff: (f, a, b) ->
    if Type.instanceOf(f, "function")
      assert false, "f must be a function, got #{type o}"
    IfOperationStream(f, OperationStream.of(a), OperationStream.of(b))

  @repeatFor: (o, count) ->
    if Type.instanceOf(count, "number")
      assert false, "count must be a number, got #{type o}"
    RepeatOperationStream(OperationStream.of(o), count)
   
  @repeatWhile: (o, f) ->
    if Type.instanceOf(f, "function")
      assert false, "f must be a function, got #{type o}"
    RepeatWhileOperationStream(OperationStream.of(o), f)
    
  @repeatUntil: (o, f) ->
    if Type.instanceOf(f, "function")
      assert false, "f must be a function, got #{type o}"
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
    if Array.empty(@streams) or Array.head(@streams) == nil
      minetest.debug("ConcatOperationStream", "very empty", tostring(Array.empty(@streams)), tostring(Array.head(@streams)))
      return EmptyOperation, EmptyOperationStream
    nextOperation, hNext = (Array.head @streams)\next!
    tNext = Array.tail @streams
    if not hNext.complete
      minetest.debug("ConcatOperationStream", "still on head")
      nextOperation, ConcatOperationStream(Array.prepend(hNext, tNext))
    elseif not Array.empty tNext
      minetest.debug("ConcatOperationStream", "head complete")
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
    -- initialStream: internal use only
    new: (stream, f, initialStream) => 
      @stream = stream
      @f = f
      @initialStream = if initialStream != nil then initialStream else stream
    complete: false
    next: =>
      nextOperation, nextStream = @stream\next!
  
      if not nextStream.complete
        nextOperation, RepeatWhileOperationStream(nextStream, @f, @initialStream)
      elseif nextStream.complete
        if @f!
          nextOperation, RepeatWhileOperationStream(@initialStream, @f)
        else 
          nextOperation, EmptyOperationStream

class RepeatUntilOperationStream extends OperationStream
  -- stream: a single stream
  -- f: function returning a boolean
  -- initialStream: internal use only
  new: (stream, f, initialStream) => 
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