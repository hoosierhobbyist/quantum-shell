QuantumShellModel = require './quantum-shell-model'
{CompositeDisposable} = require 'atom'

module.exports = QuantumShell =
    panel: null
    model: null
    lastPane: null
    subscriptions: null

    activate: (state) ->
        @model = new QuantumShellModel(state.quantumShellState)
        @panel = atom.workspace.addBottomPanel(item: @model, visible: false)

        # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
        @subscriptions = new CompositeDisposable

        # Register command that toggles this view
        @subscriptions.add atom.commands.add 'atom-workspace', 'quantum-shell:toggle': => @toggle()

    deactivate: ->
        @panel.destroy()
        @model.destroy()
        @subscriptions.dispose()

    serialize: ->
        quantumShellState: @quantumShellModel.serialize()

    toggle: ->
        console.log "quantum-shell:toggle"
        if @panel.isVisible()
            @panel.hide()
            @lastPane.activate()
        else
            @lastPane = atom.workspace.getActivePane()
            @panel.show()
            document.querySelector('#quantum-shell-input').focus()