{CompositeDisposable} = require 'atom'
QuantumShellView = require './quantum-shell-view'
QuantumShellModel = require './quantum-shell-model'

module.exports =
    panel: null
    model: null
    lastPane: null
    subscriptions: null

    activate: (state = {}) ->
        #instansiate package variables
        @subscriptions = new CompositeDisposable()
        @subscriptions.add atom.views.addViewProvider QuantumShellModel, QuantumShellView
        @subscriptions.add atom.commands.add 'atom-workspace', 'quantum-shell:toggle': => @toggle()
        
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
            @lastPane.activate()
        else
            @lastPane = atom.workspace.getActivePane()
            @panel.show()
            document.querySelector('#quantum-shell-input').focus()
