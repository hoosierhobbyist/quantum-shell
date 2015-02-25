#node core
path = require 'path'
{exec, spawn} = require 'child_process'
#node modules
split = require 'split'
through = require 'through2'
_ = require 'underscore-plus'
#atom core
{CompositeDisposable} = require 'atom'

#builtin commands
sh_builtins =
    '''
    \\. : break cd continue eval exec exit export getopts hash
    pwd readonly return shift test times trap umask unset
    '''.replace /\s+/g, '$|^'
bash_builtins =
    '''
    alias bind builtin caller command declare echo enable help let local
    logout mapfile printf read readarray source type typeset ulimit unalias
    '''.replace /\s+/g, '$|^'
custom_builtins =
    '''
    atom clear history printenv shopt
    '''.replace /\s+/g, '$|^'

#primary model class
class QuantumShellModel
    #class attributes
    maxHistory: 100
    user: process.env.USER or process.env.USERNAME
    home: process.env.HOME or process.env.HOMEPATH
    version: require(path.join(__dirname, '../package.json'))['version']
    builtins: RegExp '(^' + sh_builtins + '$|^' + bash_builtins + '$|^' + custom_builtins + '$)'

    constructor: (state = {}) ->
        #HTML escape transformation
        escape = (chunk, enc, callback) ->
            callback null, _.escape chunk.toString()
        #disposables
        @child = null
        @dataStream = through(escape)
        @errorStream = through(escape)
        @subscriptions = new CompositeDisposable()
        #state attributes
        @history = state.history or []
        @history.pos = -1
        @history.dir = ''
        @history.temp = ''
        @aliases = state.aliases or {}
        @lwd = state.lwd or @home
        @pwd = state.pwd or atom.project.path or @home
        @env = state.env or _.clone process.env

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
                @input ?= @view.querySelector '#quantum-shell-input'
                @output ?= @view.querySelector '#quantum-shell-output'
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
                @input ?= @view.querySelector '#quantum-shell-input'
                @output ?= @view.querySelector '#quantum-shell-output'
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
        #tokenizer regular expression
        tokenizer = /('[^']+'|"[^"]+"|[^'"\s]+)/g

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

        #tokenize input and expand aliases/environment variables
        tokens = input.match(tokenizer) or []
        for token, i in tokens
            for own key, expansion of @aliases when token is key
                tokens[i] = expansion.match tokenizer
        tokens = _.flatten tokens
        for token, i in tokens when /^\$/.test token
            tokens[i] = @env[token.slice(1)].match tokenizer
        tokens = _.flatten tokens
        tokens = _.compact tokens
        return if tokens.length is 0

        #builtin lookup
        if tokens[0].match @builtins
            builtin = tokens[0]
            if @['~' + builtin]?
                @['~' + builtin].call this, tokens
            else
                @errorStream.write "quantum-shell: builtin: [#{builtin}] has yet to be implemented"
                @errorStream.write "For more information please see the issue at http://github.com/sedabull/quantum-shell/issues/1"

        #pass command to os
        else
            @exec tokens.join ' '

    exec: (input) ->
        #prevent overriding existing child
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

    spawn: (args) ->
        #prevent overriding existing child
        unless @child
            #seperate command
            cmd = args.shift()
            #new child process instance
            @child = spawn cmd, args, cwd: @pwd, env: @env, detached: true
            #pipe newline seperated output back to the user
            @child.stdout.pipe(split()).pipe @dataStream, end: false
            @child.stderr.pipe(split()).pipe @errorStream, end: false
            #pipe spawn error back to the user
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

#mixin builtins and export
module.exports = QuantumShellModel
_.extend QuantumShellModel::, require('./builtins/sh'), require('./builtins/bash'), require('./builtins/custom')
