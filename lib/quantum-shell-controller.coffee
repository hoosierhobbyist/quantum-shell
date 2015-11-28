fs = require 'fs'
os = require 'os'
path = require 'path'
{CompositeDisposable} = require 'atom'
QuantumShellModel = require './quantum-shell-model'

#closures
PS_ID = null
lastPane = null
tabInput = null
tabMatches = []
tabMatches.index = 0
switchTerminals = ->
    unless @model is QuantumShellController.activeModel
        @model.activate()
        QuantumShellController.activeModel.deactivate false
        QuantumShellController.activeModel = @model
        QuantumShellController.activeModel.input.focus()
        QuantumShellController.activeModel.output.scrollTop = Number.MAX_VALUE

module.exports = QuantumShellController =
    models: []
    panel: null
    activeModel: null
    subscriptions: null
    config:
        debug:
            type: 'boolean'
            default: false
            title: 'Debug Child Processes'
            description: 'When checked, standard atom notifications will appear indicating a process\'s exit code and signal'
        home:
            type: 'string'
            default: os.homedir()
            title: 'Home Directory'
            description: 'You\'re home directory. It will be replaced by a \'~\' in the prompt string and used as the default argument to the \'cd\' command.'
        user:
            type: 'string'
            default: if process.platform is 'win32' then process.env.USERNAME else process.env.USER or 'user'
            title: 'User Name'
            description: 'You\'re user name. \'\\u\' in the prompt string will expand into this value.'
        maxHistory:
            type: 'integer'
            minimum: 0
            default: 100
            title: 'Maximum History'
            description: 'The maximum number of commands that will be saved before the oldest are deleted'
        maxTerminals:
            type: 'integer'
            minimum: 1
            default: 10
            title: 'Maximum Terminals'
            description: 'Trying to create terminals beyond this limit will create a notification error'
        maxHeight:
            type: 'integer'
            minimum: 0
            default: 250
            title: 'Maximum Height'
            description: 'The maximum height, in pixels, of the shell output div'
        minHeight:
            type: 'integer'
            minimum: 0
            default: 25
            title: 'Minimum Height'
            description: 'The minimum height, in pixels, of the shell output div'
        shell:
            type: 'string'
            default: if process.platform is 'win32' then 'cmd' else process.env.SHELL or '/bin/sh'
            title: 'Shell Name'
            description: 'The shell you would like to execute all non-builtin commands. You must create a new terminal to start using it.'
        PS:
            type: 'string'
            default: if process.platform is 'win32' then '\\w\\$' else '\\u@atom:\\w\\$'
            title: 'Prompt String'
            description: 'The string that will act as a placeholder for the input field. Supports basic bash-like expansion (\\!,\\@,\\#,\\$,\\A,\\d,\\h,\\H,\\t,\\T,\\s,\\u,\\v,\\V,\\w,\\W,\\\\)'
        enableBuiltins:
            type: 'boolean'
            default: true
            title: 'Enable Builtins'
            description: 'Enable and give precedence to custom quantum-shell builtin commands (highly recommended)'

    activate: (state = {}) ->
        #handle issues from older versions of quantum-shell
        if state.modelState?
            state.modelState.isActive = true
            state.models = [state.modelState]
        if atom.config.get('quantum-shell.shell') is 'cmd.exe'
            atom.config.set 'quantum-shell.shell', ''
            atom.config.set 'quantum-shell.user', ''
            atom.config.set 'quantum-shell.home', ''
        #setup event handlers
        QuantumShellModel::submit.onclick = =>
            cmd = document.createElement 'div'
            cmd.classList.add 'text-info'
            cmd.classList.add 'quantum-shell-command'
            cmd.innerHTML = @activeModel.input.value
            @activeModel.output.appendChild cmd
            @activeModel.output.scrollTop = Number.MAX_VALUE
            @activeModel.process @activeModel.input.value
            @activeModel.input.value = ''
        QuantumShellModel::addTerminal.onclick = =>
            if @models.length < atom.config.get 'quantum-shell.maxTerminals'
                @models.push new QuantumShellModel {isActive: true}
                @activeModel.deactivate false
                @activeModel = @models[@models.length-1]
                @activeModel.icon.onclick = switchTerminals
            else
                atom.notifications.addError "quantum-shell: Terminal limit reached",
                    detail: 'To change this value go to\nSettings>Packages>quantum-shell>MaxTerminals'
            @activeModel.input.focus()
        QuantumShellModel::removeTerminal.onclick = =>
            if @models.length > 1
                index = @models.indexOf @activeModel
                @activeModel.icons.removeChild @activeModel.icon
                @activeModel.destroy()
                if index < @models.length - 1
                    @models[index+1].activate()
                    @activeModel = @models[index+1]
                else
                    @models[@models.length-2].activate()
                    @activeModel = @models[@models.length-2]
                @models.splice index, 1
                @activeModel.output.scrollTop = Number.MAX_VALUE
            else
                atom.notifications.addError "quantum-shell: There must always be at least one terminal"
            @activeModel.input.focus()

        #setup commands
        @subscriptions = new CompositeDisposable()
        @subscriptions.add atom.commands.add 'atom-workspace',
            'quantum-shell:toggle', => @toggle()
        @subscriptions.add atom.commands.add '#quantum-shell-input',
            'quantum-shell:submit': => @activeModel.submit.click()
            'quantum-shell:history-back': => @historyBack()
            'quantum-shell:history-forward': => @historyForward()
            'quantum-shell:tab-completion': => @tabCompletion()
            'quantum-shell:kill-process': => @killProcess()

        #instantiate models and panel
        if state.models
            for modelState, index in state.models
                @models.push new QuantumShellModel modelState
                @models[index].icon.onclick = switchTerminals
                if modelState.isActive
                    @activeModel = @models[index]
        if @models.length is 0
            @models.push new QuantumShellModel {isActive: true}
            @activeModel = @models[0]
            @activeModel.icon.onclick = switchTerminals
        @activeModel = @models[0] unless @activeModel?
        @panel = atom.workspace.addBottomPanel item: @activeModel.view, visible: false

        #observe changes
        @subscriptions.add atom.config.observe 'quantum-shell.maxHeight', (value) =>
            for model in @models
                model.output.style.maxHeight = "#{value}px"
        @subscriptions.add atom.config.observe 'quantum-shell.minHeight', (value) =>
            for model in @models
                model.output.style.minHeight = "#{value}px"
        @subscriptions.add atom.config.observe 'quantum-shell.maxHistory', (value) =>
            for model in @models
                if model.history.length > value
                    model.history.splice value, Infinity

    deactivate: ->
        @panel.destroy()
        @subscriptions.dispose()
        if PS_ID then clearInterval PS_ID
        for model in @models
            model.destroy()

    serialize: ->
        models: @models.map (model) =>
            ref = model.serialize()
            if model is @activeModel
                ref.isActive = true
            else
                ref.isActive = false
            return ref

    toggle: ->
        if @panel.isVisible()
            @panel.hide()
            lastPane.activate()
            clearInterval PS_ID
        else
            lastPane = atom.workspace.getActivePane()
            @panel.show()
            @activeModel.input.focus()
            PS_ID = setInterval (=> @activeModel.input.placeholder = @activeModel.promptString(atom.config.get('quantum-shell.PS'))), 100

    killProcess: ->
        if @activeModel.child?
            @activeModel.child.kill 'SIGINT'
            @activeModel.child = null
            @activeModel.errorStream.write '^C'

    historyBack: ->
        if @activeModel.history.dir is 'forward'
            @activeModel.history.dir = 'back'
            @activeModel.history.pos += 1
        if @activeModel.history.pos == -1
            @activeModel.history.dir = 'back'
            @activeModel.history.temp = @activeModel.input.value
            @activeModel.history.pos = 0
        if @activeModel.history.pos < @activeModel.history.length
            @activeModel.history.dir = 'back'
            @activeModel.input.value = @activeModel.history[@activeModel.history.pos]
            @activeModel.history.pos += 1

    historyForward: ->
        if @activeModel.history.dir is 'back'
            @activeModel.history.dir = 'forward'
            @activeModel.history.pos -= 1
        if @activeModel.history.pos > 0
            @activeModel.history.dir = 'forward'
            @activeModel.history.pos -= 1
            @activeModel.input.value = @activeModel.history[@activeModel.history.pos]
        else if @activeModel.history.pos is 0
            @activeModel.history.dir = ''
            @activeModel.history.pos = -1
            @activeModel.input.value = @activeModel.history.temp
            @activeModel.history.temp = ''

    tabCompletion: ->
        if tabInput == @activeModel.input.value
            if tabMatches.length
                unless /\s+/.test tabInput
                    tabInput = tabMatches[tabMatches.index]
                    @activeModel.input.value = tabInput
                else
                    lastToken = tabInput.match(/('[^']+'|"[^"]+"|[^'"\s]+)/g).pop()
                    index = tabInput.lastIndexOf lastToken
                    tabInput = tabInput.slice 0, index
                    tabInput += tabMatches[tabMatches.index]
                    @activeModel.input.value = tabInput

                if tabMatches.index < tabMatches.length - 1
                    tabMatches.index += 1
                else
                    tabMatches.index = 0
            else
                atom.notifications.addWarning "quantum-shell: no matches for tab-completion"

        else
            tabInput = @activeModel.input.value
            tabMatches = []
            tabMatches.index = 0
            unless /\s+/.test tabInput
                for own command of @activeModel.commands
                    if RegExp('^' + tabInput, 'i').test command
                        tabMatches.push command
            else
                lastToken = tabInput.match(/('[^']+'|"[^"]+"|[^'"\s]+)/g).pop()
                if RegExp(path.sep).test lastToken
                    try
                        directory = path.dirname path.resolve @activeModel.pwd, lastToken
                        fileNames = fs.readdirSync directory
                        prefix = lastToken.slice 0, lastToken.lastIndexOf(path.sep) + 1
                        for fileName in fileNames
                            if RegExp("^#{path.basename(lastToken)}", 'i').test fileName
                                tabMatches.push prefix + fileName
                    catch err
                        console.error err
                else
                    try
                        fileNames = fs.readdirSync @activeModel.pwd
                        for fileName in fileNames
                            if RegExp("^#{lastToken}", 'i').test fileName
                                tabMatches.push fileName
                    catch err
                        console.error err
            @tabCompletion()
