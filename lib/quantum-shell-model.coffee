#node core
fs = require 'fs'
path = require 'path'
{exec} = require 'child_process'
#node modules
split = require 'split'
through = require 'through2'
#atom core/modules
{CompositeDisposable} = require 'atom'
QuantumShellView = require './quantum-shell-view'

class QuantumShellModel
    #class attributes
    maxHistory: 100
    user: process.env.USER or process.env.USERNAME
    home: process.env.HOME or process.env.HOMEPATH
    version: atom.packages.getLoadedPackage('quantum-shell').metadata.version
    
    constructor: (state = {}) ->
        #disposables
        @child = null
        @dataStream = through()
        @errorStream = through()
        @subscriptions = new CompositeDisposable()
        #state attributes
        @history = state.history or []
        @pwd = state.pwd or atom.project.path or @home
        
        #return output to the user
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
        
        #log any internal errors
        @dataStream.on 'error', (error) ->
            console.log "QUANTUM SHELL DATA STREAM ERROR: #{error}"
        @errorStream.on 'error', (error) ->
            console.log "QUANTUM SHELL ERROR STREAM ERROR: #{error}"
    
    serialize: ->
        delete histroy.pos
        delete history.temp
        
        pwd: @pwd
        history: @history
    
    destroy: ->
        @child.kill() if @child?
        @dataStream.end()
        @errorStream.end()
        subscriptions.dispose()
    
    process: (input) ->
        #adjust the history queue
        @history.pos = -1
        @history.temp = ''
        unless input is @history[0]
            unless @history.unshift(input) <= @maxHistory
                @history.pop()
        #change directory logic
        if input.match /^cd\s+/
            newPWD = path.resolve @pwd, input.split(/\s+/)[1]
            fs.stat newPWD, (error, stats) =>
                if error
                    console.log "fs.stat error in quantum-shell cd program: #{error}"
                else
                    if stats.isDirectory()
                        @pwd = newPWD
                        @input.placeholder = "#{@user}@atom:#{@pwd.replace @home, '~'}$"
                    else
                        @errorStream.write "cd error: #{input.split(/\s+/)[1]} is not a directory"
        #execute command normally
        else
            @exec input
    
    exec: (input) ->
        unless @child
            #new ChildProcess instance
            @child = exec input, cwd: @pwd, env: process.env
            #pipe newline seperated output back to the user
            @child.stdout.pipe(split()).pipe @dataStream, end: false
            @child.stderr.pipe(split()).pipe @errorStream, end: false
            #pipe exec error back to the user
            @child.on 'error', (error) =>
                @child.kill()
                @child = null
                for line in error.toString().split('\n')
                    @errorStream.write line
            #log exit code and signal
            @child.on 'exit', (code, signal) =>
                @child = null
                console.log "EXEC EXIT CODE: #{code}"
                console.log "EXEC EXIT SIGNAL: #{signal}"

atom.views.addViewProvider QuantumShellModel, QuantumShellView

module.exports = QuantumShellModel
