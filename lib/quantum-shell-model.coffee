#node core
fs = require 'fs'
os = require 'os'
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
    commands: {}
    version: require(path.join(__dirname, '../package.json'))['version']
    builtins: RegExp '(^' + sh.list.join('$|^') + '$|^' + bash.list.join('$|^') + '$|^' + custom.list.join('$|^') + '$)'

    #populate commands hash
    paths = (process.env.PATH or process.env.Path or '').split path.delimiter
    for p in paths
        fs.readdir p, (err, binaries) =>
            if err then return console.error err
            for binary in binaries
                @::commands[binary] = true
    for command in sh.list
        @::commands[command] = true
    for command in bash.list
        @::commands[command] = true
    for command in custom.list
        @::commands[command] = true

    #DOM elements
    view: document.createElement 'div'
    title: document.createElement 'h1'
    btns: document.createElement 'div'
    controls: document.createElement 'span'
    icons: document.createElement 'span'
    addTerminal: document.createElement 'button'
    removeTerminal: document.createElement 'button'
    body: document.createElement 'div'
    input: document.createElement 'input'
    submit: document.createElement 'button'

    #assign ids
    @::view.id = 'quantum-shell'
    @::title.id = 'quantum-shell-title'
    @::btns.id = 'quantum-shell-btns'
    @::body.id = 'quantum-shell-body'
    @::input.id = 'quantum-shell-input'
    @::submit.id = 'quantum-shell-submit'

    #assign types
    @::input.type = 'text'
    @::submit.type = 'button'
    @::addTerminal.type = 'button'
    @::removeTerminal.type = 'button'

    #assign innerHTML
    @::submit.innerHTML = 'ENTER'
    @::title.innerHTML = "QUANTUM SHELL v-#{@::version}"

    #assign classes
    @::controls.classList.add 'btn-group'
    @::controls.classList.add 'inline-block-tight'
    @::icons.classList.add 'btn-group'
    @::icons.classList.add 'inline-block-tight'
    @::addTerminal.classList.add 'btn'
    @::addTerminal.classList.add 'btn-success'
    @::addTerminal.classList.add 'icon-plus'
    @::removeTerminal.classList.add 'btn'
    @::removeTerminal.classList.add 'btn-error'
    @::removeTerminal.classList.add 'icon-dash'

    #append children
    @::view.appendChild @::title
    @::view.appendChild @::btns
    @::view.appendChild @::body
    @::view.appendChild @::input
    @::view.appendChild @::submit
    @::btns.appendChild @::controls
    @::btns.appendChild @::icons
    @::controls.appendChild @::addTerminal
    @::controls.appendChild @::removeTerminal


    constructor: (state = {}) ->
        #HTML escape transformation
        escape = (chunk, enc, callback) ->
            callback null, _.escape chunk.toString()

        #disposables
        @child = null
        @dataStream = through(escape)
        @errorStream = through(escape)

        #DOM elements
        @icon = document.createElement 'button'
        @icon.model = this
        @icon.classList.add 'btn'
        @icon.classList.add 'btn-primary'
        @icon.classList.add 'icon-terminal'
        @icon.classList.add 'selected' if state.isActive
        @icons.appendChild @icon

        @output = document.createElement 'pre'
        @output.style.maxHeight = "#{atom.config.get 'quantum-shell.maxHeight'}px"
        @output.style.minHeight = "#{atom.config.get 'quantum-shell.minHeight'}px"
        @output.innerHTML =
            '''
            <div class='text-info'><em>Welcome to Quantum Shell!
            Github repository: <a href='http://github.com/sedabull/quantum-shell'>sedabull/quantum-shell</a>
            Written by Seth David Bullock (sedabull@gmail.com)
            All questions, comments, bug reports, and pull requests are welcome!</em></div>
            '''
        if state.isActive
            while @body.firstChild
                @body.removeChild @body.firstChild
            @body.appendChild @output

        #history data
        @history = state.history or []
        @history.pos = -1
        @history.dir = ''
        @history.temp = ''
        @history.num = state.historyNum or @history.length + 1
        if @history.length > maxHistory = atom.config.get 'quantum-shell.maxHistory'
            @history.splice maxHistory, Infinity

        #other attributes
        @pending = null
        @commandNum = 1
        @aliases = state.aliases or {}
        @lwd = state.lwd or atom.config.get('quantum-shell.home')
        @shell = state.shell or atom.config.get('quantum-shell.shell')
        @pwd = state.pwd or atom.project.getPaths()[0] or atom.config.get('quantum-shell.home')
        @env = state.env or _.clone process.env

        #return output to the user
        @dataStream.on 'data', (chunk) =>
            line = document.createElement 'div'
            line.innerHTML = chunk.toString()
            line.classList.add 'text-success'
            line.classList.add 'quantum-shell-data'
            @output.appendChild line
            @output.scrollTop = Number.MAX_VALUE
        @errorStream.on 'data', (chunk) =>
            line = document.createElement 'div'
            line.innerHTML = chunk.toString()
            line.classList.add 'text-error'
            line.classList.add 'quantum-shell-error'
            @output.appendChild line
            @output.scrollTop = Number.MAX_VALUE

        #log any internal errors
        @dataStream.on 'error', (error) ->
            console.log "QUANTUM SHELL DATA STREAM ERROR: #{error}"
        @errorStream.on 'error', (error) ->
            console.log "QUANTUM SHELL ERROR STREAM ERROR: #{error}"

    activate: ->
        @icon.classList.add 'selected'
        while @body.firstChild
            @body.removeChild @body.firstChild
        @body.appendChild @output

    deactivate: (clear = true) ->
        if @pending and clear
            clearTimeout @pending
        @icon.classList.remove 'selected'

    serialize: ->
        pwd: @pwd
        lwd: @lwd
        env: @env
        shell: @shell
        history: @history
        aliases: @aliases
        historyNum: @history.num

    destroy: ->
        @deactivate()
        @child?.kill 'SIGINT'
        @dataStream.end()
        @errorStream.end()

    promptString: (input) ->
        input
            .replace(/\\\\/g, '\0')
            .replace(/\\\$/g, if process.platform is 'win32' then '>' else (if process.getuid() then '$' else '#'))
            .replace(/\\!/g, @history.num)
            .replace(/\\#/g, @commandNum)
            .replace(/\\h/g, if '.' in  hn = os.hostname() then hn.slice(0, hn.indexOf('.')) else hn)
            .replace(/\\H/g, os.hostname())
            .replace(/\\s/g, path.basename(@shell))
            .replace(/\\u/g, atom.config.get('quantum-shell.user'))
            .replace(/\\v/g, @version.slice(0, @version.lastIndexOf('.')))
            .replace(/\\V/g, @version)
            .replace(/\\w/g, @pwd.replace(home = atom.config.get('quantum-shell.home'), (if process.platform is 'win32' then home else '~')))
            .replace(/\\W/g, path.basename(@pwd.replace(atom.config.get('quantum-shell.home', '~'))))
            .replace(/\\d/g, time('\\d'))
            .replace(/\\t/g, time('\\t'))
            .replace(/\\T/g, time('\\T'))
            .replace(/\\@/g, time('\\@'))
            .replace(/\\A/g, time('\\A'))
            .replace(/\\/g, (if process.platform is 'win32' then '\\' else ''))
            .replace('\0', '\\')

    process: (input) ->
        #tokenizer regular expression
        tokenizer = /('[^']+'|"[^"]+"|[^'"\s]+)/g

        #adjust icon display
        if @pending then clearTimeout @pending
        @setWarning()

        #adjust the history queue
        @commandNum += 1
        @history.pos = -1
        @history.dir = ''
        @history.temp = ''
        unless input is @history[0]
            @history.num += 1
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
                code = @['~' + builtin].call this, tokens
                unless code
                    @setSuccess()
                    @pending = setTimeout (=> @clearSuccess()), 3000
                else
                    @setError()
                    @pending = setTimeout (=> @clearError()), 3000
                if atom.config.get 'quantum-shell.debug'
                    atom.notifications.addInfo "quantum-shell: exit code - #{code}"
                    atom.notifications.addInfo "quantum-shell: exit signal - null"
            else
                @setError()
                @pending = setTimeout (=> @clearError()), 3000
                @errorStream.write "quantum-shell: builtin: [#{builtin}] has yet to be implemented"
                @errorStream.write "For more information please see the issue at http://github.com/sedabull/quantum-shell/issues/1"

        #pass command to os
        else
            @exec tokens.join ' '

    setWarning: ->
        @icon.classList.remove 'btn-primary'
        @icon.classList.remove 'btn-error'
        @icon.classList.remove 'btn-success'
        @icon.classList.add 'btn-warning'

    setError: ->
        @icon.classList.remove 'btn-primary'
        @icon.classList.remove 'btn-warning'
        @icon.classList.remove 'btn-success'
        @icon.classList.add 'btn-error'

    setSuccess: ->
        @icon.classList.remove 'btn-primary'
        @icon.classList.remove 'btn-warning'
        @icon.classList.remove 'btn-error'
        @icon.classList.add 'btn-success'

    clearWarning: ->
        @pending = null
        @icon.classList.remove 'btn-warning'
        @icon.classList.add 'btn-primary'

    clearError: ->
        @pending = null
        @icon.classList.remove 'btn-error'
        @icon.classList.add 'btn-primary'

    clearSuccess: ->
        @pending = null
        @icon.classList.remove 'btn-success'
        @icon.classList.add 'btn-primary'

    exec: (input) ->
        #prevent overriding existing child
        unless @child
            #new ChildProcess instance
            @child = exec input, cwd: @pwd, env: @env, shell: @shell
            #pipe newline seperated output back to the user
            @child.stdout.pipe(split()).pipe @dataStream, end: false
            @child.stderr.pipe(split()).pipe @errorStream, end: false
            #pipe exec error back to the user
            @child.on 'error', (error) =>
                @child.kill()
                @child = null
                @setError()
                @pending = setTimeout (=> @clearError()), 3000
                for line in error.toString().split /\r?\n/
                    @errorStream.write line
            #signal that another child can now be created
            @child.on 'exit', (code, signal) =>
                @child = null
                unless code
                    @setSuccess()
                    @pending = setTimeout (=> @clearSuccess()), 3000
                else
                    @setError()
                    @pending = setTimeout (=> @clearError()), 3000
                if atom.config.get 'quantum-shell.debug'
                    atom.notifications.addInfo "quantum-shell: exit code - #{code}"
                    atom.notifications.addInfo "quantum-shell: exit signal - #{signal}"

    spawn: (args) ->
        #prevent overriding existing child
        unless @child
            #seperate command
            cmd = args.shift()
            #new child process instance
            @child = spawn cmd, args, cwd: @pwd, env: @env, detached: true, shell: @shell
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
