fs = require 'fs'
path = require 'path'
{CompositeDisposable} = require 'atom'
QuantumShellView = require './quantum-shell-view'
QuantumShellModel = require './quantum-shell-model'

lastPane = null
tabInput = null
tabMatches = []
tabMatches.index = 0

module.exports =
    panel: null
    model: null
    subscriptions: null
    config:
        maxHistory:
            type: 'integer'
            minimum: 0
            default: 100
            title: 'Maximum History'
            description: 'The maximum number of commands that will be saved before the oldest are deleted'
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
            default: process.env.SHELL ? '/bin/bash'
            title: 'Shell Name'
            description: 'The shell you would like to execute all non-builtin commands'
        enableBuiltins:
            type: 'boolean'
            default: true
            title: 'Enable Builtins'
            description: 'Enable and give precedence to custom quantum-shell builtin commands'

    activate: (state = {}) ->
        #setup subscriptions
        @subscriptions = new CompositeDisposable()
        @subscriptions.add atom.views.addViewProvider QuantumShellModel, QuantumShellView
        @subscriptions.add atom.commands.add 'atom-workspace', 'quantum-shell:toggle', => @toggle()
        @subscriptions.add atom.commands.add '#quantum-shell', 'quantum-shell:kill-process', => @killProcess()
        @subscriptions.add atom.commands.add '#quantum-shell-input',
            'quantum-shell:submit': => @model.submit.click()
            'quantum-shell:history-back': => @historyBack()
            'quantum-shell:history-forward': => @historyForward()
            'quantum-shell:tab-completion': => @tabCompletion()

        #instantiate model and panel
        @model = new QuantumShellModel state.modelState
        @panel = atom.workspace.addBottomPanel item: @model, visible: false

    deactivate: ->
        @panel.destroy()
        @model.destroy()
        @subscriptions.dispose()

    serialize: ->
        modelState: @model.serialize()

    toggle: ->
        if @panel.isVisible()
            @panel.hide()
            lastPane.activate()
        else
            lastPane = atom.workspace.getActivePane()
            @panel.show()
            @model.input.focus()

    killProcess: ->
        if @model.child?
            @model.child.kill()
            @model.child = null
            @model.errorStream.write '^C'

    historyBack: ->
        if @model.history.dir is 'forward'
            @model.history.dir = 'back'
            @model.history.pos += 1
        if @model.history.pos == -1
            @model.history.dir = 'back'
            @model.history.temp = @model.input.value
            @model.history.pos = 0
        if @model.history.pos < @model.history.length
            @model.history.dir = 'back'
            @model.input.value = @model.history[@model.history.pos]
            @model.history.pos += 1

    historyForward: ->
        if @model.history.dir is 'back'
            @model.history.dir = 'forward'
            @model.history.pos -= 1
        if @model.history.pos > 0
            @model.history.dir = 'forward'
            @model.history.pos -= 1
            @model.input.value = @model.history[@model.history.pos]
        else if @model.history.pos is 0
            @model.history.dir = ''
            @model.history.pos = -1
            @model.input.value = @model.history.temp
            @model.history.temp = ''

    tabCompletion: ->
        if tabInput == @model.input.value
            if tabMatches.length
                unless /\s+/.test tabInput
                    tabInput = tabMatches[tabMatches.index]
                    @model.input.value = tabInput
                else
                    lastToken = tabInput.match(/('[^']+'|"[^"]+"|[^'"\s]+)/g).pop()
                    index = tabInput.lastIndexOf lastToken
                    tabInput = tabInput.slice 0, index
                    tabInput += tabMatches[tabMatches.index]
                    @model.input.value = tabInput

                if tabMatches.index < tabMatches.length - 1
                    tabMatches.index += 1
                else
                    tabMatches.index = 0
            else
                atom.notifications.addWarning "quantum-shell: no matches for tab-completion"

        else
            tabInput = @model.input.value
            tabMatches = []
            tabMatches.index = 0
            unless /\s+/.test tabInput
                for own command of @model.commands
                    if RegExp('^' + tabInput, 'i').test command
                        tabMatches.push command
            else
                lastToken = tabInput.match(/('[^']+'|"[^"]+"|[^'"\s]+)/g).pop()
                if RegExp(path.sep).test lastToken
                    try
                        fileNames = fs.readdirSync path.dirname path.resolve @model.pwd, lastToken
                        prefix = lastToken.slice 0, lastToken.lastIndexOf(path.sep) + 1
                        for fileName in fileNames
                            if RegExp('^' + path.basename(lastToken), 'i').test fileName
                                tabMatches.push prefix + fileName
                    catch err
                        console.error err
                else
                    for own fileName of @model.fileNames
                        if RegExp('^' + lastToken, 'i').test fileName
                            tabMatches.push fileName
            @tabCompletion()
