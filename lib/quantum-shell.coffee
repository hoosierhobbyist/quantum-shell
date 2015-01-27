QuantumShellView = require './quantum-shell-view'
{CompositeDisposable} = require 'atom'

module.exports = QuantumShell =
  quantumShellView: null
  modalPanel: null
  subscriptions: null

  activate: (state) ->
    @quantumShellView = new QuantumShellView(state.quantumShellViewState)
    @modalPanel = atom.workspace.addModalPanel(item: @quantumShellView.getElement(), visible: false)

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'quantum-shell:toggle': => @toggle()

  deactivate: ->
    @modalPanel.destroy()
    @subscriptions.dispose()
    @quantumShellView.destroy()

  serialize: ->
    quantumShellViewState: @quantumShellView.serialize()

  toggle: ->
    console.log 'QuantumShell was toggled!'

    if @modalPanel.isVisible()
      @modalPanel.hide()
    else
      @modalPanel.show()
