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

#builtin commands
sh_builtins = 
    '''
    : \\. break cd continue eval exec exit export getopts hash
    pwd readonly return shift test times trap umask unset
    '''.replace /\s+/g, '$|^'
bash_builtins =
    '''
    alias bind builtin caller command declare echo enable help let local
    logout mapfile printf read readarray source type typeset ulimit unalias
    '''.replace /\s+/g, '$|^'
other_builtins =
    '''
    atom clear history printenv
    '''.replace /\s+/g, '$|^'

_builtins = RegExp '(^' + sh_builtins + '$|^' + bash_builtins + '$|^' + other_builtins + '$)'

#primary model class
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
        @aliases = state.aliases or {}
        @history = state.history or []
        @lwd = state.lwd or ''
        @pwd = state.pwd or atom.project.path or @home
        @env = state.env or Object.create null
        unless state.env?
            @env[k] = v for own k, v of process.env
            #@env.SUDO_ASKPASS = '/usr/bin/gksudo'
        
        #return output to the user
        @dataStream.on 'data', (chunk) =>
            line = document.createElement 'div'
            line.innerHTML = chunk.toString()
            line.classList.add 'text-success'
            line.classList.add 'quantum-shell-data'
            @output.appendChild line
            @output.scrollTop = Infinity
        @errorStream.on 'data', (chunk) =>
            line = document.createElement 'div'
            line.innerHTML = chunk.toString()
            line.classList.add 'text-error'
            line.classList.add 'quantum-shell-error'
            @output.appendChild line
            @output.scrollTop = Infinity
        
        #log any internal errors
        @dataStream.on 'error', (error) ->
            console.log "QUANTUM SHELL DATA STREAM ERROR: #{error}"
        @errorStream.on 'error', (error) ->
            console.log "QUANTUM SHELL ERROR STREAM ERROR: #{error}"
        
        #event subscriptions
        @subscriptions.add atom.commands.add(
            '#quantum-shell'
            'quantum-shell:kill-process'
            => 
                if @child?
                    @child.kill()
                    @child = null
        )#end kill-process command
        @subscriptions.add atom.commands.add(
            '#quantum-shell-input'
            'quantum-shell:submit'
            => @view.querySelector('#quantum-shell-submit').click()
        )#end submit command
        @subscriptions.add atom.commands.add(
            '#quantum-shell-input'
            'quantum-shell:history-back'
            => 
                if @history.pos?
                    if @history.dir is 'forward'
                        @history.dir = 'back'
                        @history.pos += 1
                    if @history.pos == -1
                        @history.dir = 'back'
                        @history.temp = @input.value
                        @history.pos = 0
                    if @history.pos < @history.length
                        @history.dir = 'back'
                        @input.value = @history[@history.pos]
                        @history.pos += 1
        )#end history-back command
        @subscriptions.add atom.commands.add(
            '#quantum-shell-input'
            'quantum-shell:history-forward'
            =>
                if @history.pos?
                    if @history.dir is 'back'
                        @history.dir = 'forward'
                        @history.pos -= 1
                    if @history.pos > 0
                        @history.dir = 'forward'
                        @history.pos -= 1
                        @input.value = @history[@history.pos]
                    else if @history.pos is 0
                        @history.dir = ''
                        @history.pos = -1
                        @input.value = @history.temp
                        @history.temp = ''
        )#end history-forward command
    
    serialize: ->
        pwd: @pwd
        lwd: @lwd
        env: @env
        history: @history
        aliases: @aliases
    
    destroy: ->
        @child?.kill()
        @dataStream.end()
        @errorStream.end()
        @subscriptions.dispose()
    
    process: (input) ->
        #cache input/output references
        @input ?= @view.querySelector '#quantum-shell-input'
        @output ?= @view.querySelector '#quantum-shell-output'
        
        #adjust the history queue
        @history.pos = -1
        @history.dir = ''
        @history.temp = ''
        unless input is @history[0]
            unless @history.unshift(input) <= @maxHistory
                @history.pop()
        
        #expand aliases/environment variables
        for own key, expansion of @aliases
            input = input.replace key, expansion
        while enVar = input.match /\$\w+/
            input = input.replace enVar[0], @env[enVar[0].slice(1)]
        
        #builtin lookup
        if builtin = input.split(/\s+/)[0].match(_builtins)
            builtin = builtin[0]
            if @['_' + builtin]?.call?
                @['_' + builtin].call this, input
            else
                @errorStream.write "quantum-shell: builtin: [#{builtin}] has yet to be implemented"
                @errorStream.write "For more information please see the relevant issue <a class='text-warning' href='http://github.com/sedabull/quantum-shell/issues/1'>here</a>"
        
        #pass command to os
        else
            @exec input
    
    exec: (input) ->
        #prevent spawning new child while one is running
        unless @child
            #new ChildProcess instance
            @child = exec input, cwd: @pwd, env: @env
            #pipe newline seperated output back to the user
            @child.stdout.pipe(split()).pipe @dataStream, end: false
            @child.stderr.pipe(split()).pipe @errorStream, end: false
            #pipe exec error back to the user
            @child.on 'error', (error) =>
                @child.kill()
                @child = null
                for line in error.toString().split /\r?\n/
                    @errorStream.write line
            #signal that another child can now be created
            @child.on 'exit', (code, signal) =>
                @child = null
                if atom.inDevMode()
                    console.log "QUANTUM SHELL EXIT CODE: #{code}"
                    console.log "QUANTUM SHELL EXIT SIGNAL: #{signal}"
    
    #builtins
    _pwd: -> @dataStream.write @pwd
    _echo: (input) -> @dataStream.write input.slice 5
    _clear: ->
        while element = @output.firstChild
            @output.removeChild element
        return
    _history: ->
        for line, i in @history.reverse() when i < @history.length - 1
            @dataStream.write "#{i}: #{line}"
        @history.reverse()
    _printenv: (input) ->
        tokens = input.split /\s+/
        if tokens.length is 1
            for own key, value of @env
                @dataStream.write "#{key} = #{value}"
        else
            if @env[tokens[1]]?
                @dataStream.write @env[tokens[1]]
        return
    _cd: (input) ->
        tokens = input.split(/\s+/)
        
        if tokens.length is 1
            @lwd = @pwd
            @pwd = @home
            @input.placeholder = "#{@user}@atom:~$"
        else if tokens[1] is '-'
            [@pwd, @lwd] = [@lwd, @pwd]
            @input.placeholder = "#{@user}@atom:#{@pwd.replace @home, '~'}$"
        else if tokens[1].match /^-./
            @errorStream.write "quantum-shell: cd: invalid option"
        else
            newPWD = path.resolve @pwd, tokens[1].replace '~', @home
            fs.exists newPWD, (itExists) =>
                if itExists
                    fs.stat newPWD, (error, stats) =>
                        if error
                            console.log "QUANTUM SHELL CD ERROR: #{error}"
                        else
                            if stats.isDirectory()
                                try
                                    exec 'ls', cwd: newPWD, env: @env
                                    @lwd = @pwd
                                    @pwd = newPWD
                                    @input.placeholder = "#{@user}@atom:#{@pwd.replace @home, '~'}$"
                                catch error
                                    if error.errno is 'EACCES'
                                        @errorStream.write "quantum-shell: cd: #{tokens[1]} permission denied"
                                    else
                                        console.log "QUANTUM SHELL CD ERROR: #{error}"
                            else
                                @errorStream.write "quantum-shell: cd: #{tokens[1]} is not a directory"
                else
                    @errorStream.write "quantum-shell: cd: no such file or directory"
    _export: (input) ->
        tokens = input.split /\s+/
        if tokens.length is 1
            @_printenv input
        else if tokens.length > 2
            if tokens[2] is '='
                enVar = tokens[1]
                value = tokens.slice(3).join(' ')
                @env[enVar] = value
            else
                @errorStream.write "quantum-shell: export: missing '=' after environment variable name"
    _alias: (input) ->
        tokens = input.split /\s+/
        if tokens.length is 1
            for own key, expansion of @aliases
                @dataStream.write "#{key} = #{expansion}"
        else if tokens.length is 2
            if @aliases[tokens[1]]
                @dataStream.write @aliases[tokens[1]]
            else
                @errorStream.write "quantum-shell: alias: #{tokens[1]} no such alias"
        else
            if tokens[2] is '='
                key = tokens[1]
                expansion = tokens.slice(3).join(' ')
                @aliases[key] = expansion
            else
                @errorStream.write "quantum-shell: alias: missing '=' after alias name"
    _unalias: (input) ->
        for own key, expansion of @aliases
            input = input.replace expansion, key
        tokens = input.split /\s+/
        for token in tokens.slice(1)
            if @aliases[token]?
                delete @aliases[token]
            else
                @errorStream.write "quantum-shell: unalias: #{token} no such alias"
    
    #special builtins
    _atom: (input) ->
        tokens = input.split /\s+/
        if tokens.length > 1
            if tokens.length < 3
                command = tokens[1]
                selector = 'atom-workspace'
            else
                command = tokens[2]
                selector = tokens[1]
            
            if target = document.querySelector selector
                if atom.commands.dispatch target, command
                    setTimeout (=> @input.focus()), 100
                    @dataStream.write "quantum-shell: atom: command '#{command}' was dispatched to target '#{selector}'"
                else
                    @errorStream.write "quantum-shell: atom: '#{command}' is not a valid command at target '#{selector}'"
            else
                @errorStream.write "quantum-shell: atom: '#{selector}' is not a valid target"
#register view provider
module.exports = QuantumShellModel
atom.views.addViewProvider QuantumShellModel, QuantumShellView
