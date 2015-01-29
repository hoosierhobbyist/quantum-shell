{CompositeDisposable} = require 'atom'
Terminal = require './quantum-shell-terminal'
QuantumShellView = require './quantum-shell-view'

class QuantumShellModel
    subscriptions: new CompositeDisposable()
    
    constructor: (serializeState) ->
    
    serialize: ->
    
    destroy: ->
        subscriptions.dispose()

atom.views.addViewProvider QuantumShellModel, QuantumShellView

module.exports = QuantumShellModel