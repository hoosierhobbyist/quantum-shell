#node core
fs = require 'fs'
path = require 'path'
{exec, spawn} = require 'child_process'
#node modules
split = require 'split'
through = require 'through2'
_ = require 'underscore-plus'
#atom core
{CompositeDisposable} = require 'atom'
#builtins
time = require './util/time'
sh = require './builtins/sh'
bash = require './builtins/bash'
custom = require './builtins/custom'

#primary model class
class QuantumShellModel
    #class attributes
    version: require(path.join(__dirname, '../package.json'))['version']
    builtins: RegExp '(^' + sh.list.join('$|^') + '$|^' + bash.list.join('$|^') + '$|^' + custom.list.join('$|^') + '$)'

    constructor: (state = {}) ->
        #HTML escape transformation
        escape = (chunk, enc, callback) ->
            callback null, _.escape chunk.toString()

        #disposables
        @child = null
        @dataStream = through(escape)
        @errorStream = through(escape)

        #state attributes
        @history = state.history or []
        @history.pos = -1
        @history.dir = ''
        @history.temp = ''
        @commands = state.commands or null
        @fileNames = state.fileNames or null
        @aliases = state.aliases or {}
        @lwd = state.lwd or atom.config.get('quantum-shell.home')
        @pwd = state.pwd or atom.project.getPaths()[0] or atom.config.get('quantum-shell.home')
        @env = state.env or _.clone process.env

        #build a map of commands for tab-completion
        unless @commands?
            @commands = {}
            PATHS = (@env.PATH or @env.Path or '').split path.delimiter
            for PATH in PATHS
                fs.readdir PATH, (err, binaries) =>
                    if err then return console.error err
                    for binary in binaries
                        @commands[binary] = true
            for command in sh.list
                @commands[command] = true
            for command in bash.list
                @commands[command] = true
            for command in custom.list
                @commands[command] = true

        #build a map of fileNames for tab-completion
        unless @fileNames
            @fileNames = {}
            fs.readdir @pwd, (err, files) =>
                if err then return console.error err
                for file in files
                    @fileNames[file] = true


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

    serialize: ->
        pwd: @pwd
        lwd: @lwd
        env: @env
        history: @history
        aliases: @aliases
        commands: @commands
        fileNames: @fileNames

    destroy: ->
        @child?.kill()
        @dataStream.end()
        @errorStream.end()

    promptString: (input) ->
        input
            .replace(/\\\\/g, '\0')
            .replace(/\\s/g, 'quantum-shell')
            .replace(/\\u/g, atom.config.get('quantum-shell.user'))
            .replace(/\\v/g, @version.slice(0, @version.lastIndexOf('.')))
            .replace(/\\V/g, @version)
            .replace(/\\w/g, @pwd.replace(atom.config.get('quantum-shell.home'), '~'))
            .replace(/\\W/g, path.basename(@pwd.replace(atom.config.get('quantum-shell.home', '~'))))
            .replace(/\\d/g, time('\\d'))
            .replace(/\\t/g, time('\\t'))
            .replace(/\\T/g, time('\\T'))
            .replace(/\\@/g, time('\\@'))
            .replace(/\\A/g, time('\\A'))
            .replace('\0', '\\')

    process: (input) ->
        #tokenizer regular expression
        tokenizer = /('[^']+'|"[^"]+"|[^'"\s]+)/g

        #adjust the history queue
        @history.pos = -1
        @history.dir = ''
        @history.temp = ''
        unless input is @history[0]
            unless @history.unshift(input) <= atom.config.get('quantum-shell.maxHistory')
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
        if @builtins.test(tokens[0]) and atom.config.get('quantum-shell.enableBuiltins')
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
            @child = exec input, cwd: @pwd, env: @env, shell: atom.config.get('quantum-shell.shell')
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
            @child = spawn cmd, args, cwd: @pwd, env: @env, detached: true, shell: atom.config.get('quantum-shell.shell')
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
_.extend QuantumShellModel::, sh, bash, custom
delete QuantumShellModel::list
