{CompositeDisposable} = require 'atom'
QuantumShellModel = require './quantum-shell-model'

module.exports =
    panel: null
    model: null
    lastPane: null
    subscriptions: null

    activate: (state) ->
        @subscriptions = new CompositeDisposable()
        @model = 
            if state.modelState?
                atom.deserializers.deserialize state.modelState
            else
                new QuantumShellModel()
        @panel = atom.workspace.addBottomPanel(item: @model, visible: false)

        # Register command that toggles this view
        @subscriptions.add atom.commands.add 'atom-workspace', 'quantum-shell:toggle': => @toggle()

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
