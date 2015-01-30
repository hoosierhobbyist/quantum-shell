{exec} = require 'child_process'
{CompositeDisposable} = require 'atom'
Terminal = require './quantum-shell-terminal'
QuantumShellView = require './quantum-shell-view'
LineBuffer = require './quantum-shell-line-buffer'

class QuantumShellModel
    subscriptions: new CompositeDisposable()
    
    constructor: (serializeState) ->
        @dataStream = new LineBuffer
        @errorStream = new LineBuffer
        
        @dataStream.on 'line', (line) =>
            p = document.createElement 'p'
            p.innerHTML = line + '<br />'
            p.classList.add 'quantum-shell-data'
            @output.appendChild p
            @output.scrollTop = Infinity
        @errorStream.on 'line', (line) =>
            p = document.createElement 'p'
            p.innerHTML = line + '<br />'
            p.classList.add 'quantum-shell-error'
            @output.appendChild p
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
        
        child.stdout.pipe @dataStream, end: false
        child.stderr.pipe @errorStream, end: false
        child.on 'error', (error) =>
            console.log "EXEC ERROR: #{error}"
            @errorStream.write error
        child.on 'exit', (code) ->
            console.log "EXEC EXIT CODE: #{code}"

atom.views.addViewProvider QuantumShellModel, QuantumShellView

module.exports = QuantumShellModel