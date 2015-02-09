module.exports =
    _clear: ->
        while element = @output.firstChild
            @output.removeChild element
        return
    
    _history: ->
        for line, i in @history.reverse() when i < @history.length - 1
            @dataStream.write "#{i}: #{line}"
        @history.reverse()
    
    _printenv: (input) ->
        tokens = input.split /\s+/
        if tokens.length is 1
            for own key, value of @env
                @dataStream.write "#{key} = #{value}"
        else
            if @env[tokens[1]]?
                @dataStream.write @env[tokens[1]]
        return
    
    _atom: (input) ->
        tokens = input.split /\s+/
        if tokens.length > 1
            if tokens.length < 3
                command = tokens[1]
                selector = 'atom-workspace'
            else
                command = tokens[2]
                selector = tokens[1]
            
            if target = document.querySelector selector
                if atom.commands.dispatch target, command
                    setTimeout (=> @input.focus()), 100
                    @dataStream.write "quantum-shell: atom: command '#{command}' was dispatched to target '#{selector}'"
                else
                    @errorStream.write "quantum-shell: atom: '#{command}' is not a valid command at target '#{selector}'"
            else
                @errorStream.write "quantum-shell: atom: '#{selector}' is not a valid target"