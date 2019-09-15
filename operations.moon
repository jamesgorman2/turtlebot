
empty: (t) => next(t) == nil
head: (t) => [i for i in *t[1,1]]
tail: (t) => [i for i in *t[2,]]
prepend: (i, t) => table.insert(copy(t), 1, i)
instanceOf: (o, t) =>
  if type(o) == t
    true
  elseif o.__parent != nil
    instanceOf o.__parent, t
  else
    false


export class Operation
  new: (f) => @f = f
  exec: (t) => @f(t)

export EmptyOperation = Operation((a) => a)
export EmptyOperationStream

export class OperationStream
  -- returns (the next Operation, the new OperationsStream)
  next: => EmptyOperation, EmptyOperationStream
  
  complete: true

  andThen: (o) =>
    lhs = self
    rhs = @@of(o)
    
    if lhs == EmptyOperationStream
      rhs
    elseif rhs == EmptyOperationStream
      lhs
    else
      OperationStream.concat(rhs, lhs)
   
  @empty: EmptyOperationStream
 
  @of: (o) => 
    if instanceOf(o, Operation)
      SingleOperationStream(o)
    elseif instanceOf(o, OperationStream)
      o
    elseif type(o) == "table"
      for k, o in ipairs os
        assert instanceOf(o, Operation) or instanceOf(o, OperationStream), 
          "Expected Operation or OperationStream, got #{type o}"
      ConcatOperationStream([OperationStream.of(item) for i, item in ipairs o])
    elseif type(o) == "function"
      SingleOperationStream(Operation(o))
    else
      assert false, "Expected one of Operation, OperationStream, table, or function, got #{type o}"
  
  @concat: (a, b) =>
    OperationStream.of({a, b})

  @iff: (f, a, b) =>
    if type(f) != "function"
      assert false, "f must be a function, got #{type o}"
    IfOperationStream(f, OperationStream.of(a), OperationStream.of(b))

  @repeatFor: (o, count) =>
    if type(count) != "number"
      assert false, "count must be a number, got #{type o}"
    RepeatOperationStream(OperationStream.of(o), count)
   
  @repeatWhile: (o, f) =>
    if type(f) != "function"
      assert false, "f must be a function, got #{type o}"
    RepeatWhileOperationStream(OperationStream.of(o), f)
    
  @repeatUntil: (o, f) =>
    if type(f) != "function"
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
    nextOperation, hNext = (head @streams)\next!
    tNext = tail @streams
    if not hNext.complete
      nextOperation, ConcatOperationStream(prepend(hNext, tNext))
    elseif not empty t
      nextOperation, ConcatOperationStream(tNext)
    else
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