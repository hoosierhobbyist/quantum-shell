util = require 'util'
{Transform} = require 'stream'

LineBuffer = (options) ->
    if not(this instanceof LineBuffer)
        return new LineBuffer options
    
    Transform.call this, options

util.inherits LineBuffer, Transform

LineBuffer::_transform = (chunk, encoding, callback) ->
    lines = chunk.toString().split '\n'
    for line in lines
        @emit 'line', line

module.exports = LineBuffer