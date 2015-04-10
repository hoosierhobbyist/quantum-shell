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
                console.log "QUANTUM SHELL: no matches for tab-completion"

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
                for own fileName of @model.fileNames
                    if RegExp('^' + lastToken, 'i').test fileName
                        tabMatches.push fileName
            @tabCompletion()
