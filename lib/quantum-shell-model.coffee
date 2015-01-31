split = require 'split'
through = require 'through2'
{Readable} = require 'stream'
{exec} = require 'child_process'
{CompositeDisposable} = require 'atom'
QuantumShellView = require './quantum-shell-view'

class QuantumShellModel
    constructor: (serializeState) ->
        @dataStream = through()
        @errorStream = through()
        @subscriptions = new CompositeDisposable()
        
        @dataStream.on 'data', (chunk) =>
            line = document.createElement 'div'
            line.innerHTML = chunk.toString()
            line.classList.add 'quantum-shell-data'
            @output.appendChild line
            @output.scrollTop = Infinity
        @errorStream.on 'data', (chunk) =>
            line = document.createElement 'div'
            line.innerHTML = chunk.toString()
            line.classList.add 'quantum-shell-error'
            @output.appendChild line
            @output.scrollTop = Infinity
        @dataStream.on 'error', (error) ->
            console.log "DATA STREAM ERROR: #{error}"
        @errorStream.on 'error', (error) ->
            console.log "ERROR STREAM ERROR: #{error}"
    
    serialize: ->
    
    destroy: ->
        @dataStream.end()
        @errorStream.end()
        subscriptions.dispose()
    
    exec: (input) ->
        child = exec input, cwd: process.PWD, env: process.env
        
        child.stdout.pipe(split()).pipe @dataStream, end: false
        child.stderr.pipe(split()).pipe @errorStream, end: false
        child.on 'error', (error) =>
            console.log "EXEC ERROR: #{error}"
            @errorStream.write error
        child.on 'exit', (code) ->
            console.log "EXEC EXIT CODE: #{code}"

atom.views.addViewProvider QuantumShellModel, QuantumShellView

module.exports = QuantumShellModel