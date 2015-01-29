module.exports =
class QuantumShellTerminal
    constructor: (serializeState = {}) ->
        @history = serializeState.history ? []
        @aliases = serializeState.aliases ? []
        @pwd = serializeState.pwd ? process.env.PWD
        @homeDir = serializeState.homeDir ? process.env.HOME