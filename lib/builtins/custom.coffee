module.exports =
    '~clear': (tokens) ->
        if tokens[0] is 'clear'
            while element = @output.firstChild
                @output.removeChild element
        else
            @errorStream.write "quantum-shell: clear: internal error - expected '#{tokens[0]}' to be 'clear'"
    
    '~history': (tokens) ->
        if tokens[0] is 'history'
            for line, i in @history.reverse() when i < @history.length - 1
                @dataStream.write "#{i}: #{line}"
            @history.reverse()
        else
            @errorStream.write "quantum-shell: history: internal error - expected '#{tokens[0]}' to be 'history'"
    
    '~printenv': (tokens) ->
        if tokens[0] is 'printenv'
            if tokens.length is 1
                for own key, value of @env
                    @dataStream.write "#{key} = #{value}"
            else
                if @env[tokens[1]]?
                    @dataStream.write @env[tokens[1]]
                else
                    @errorStream.write "quantum-shell: printenv: '#{tokens[1]}' no such environment variable"
        else
            @errorStream.write "quantum-shell: printenv: internal error - expected '#{tokens[0]}' to be 'printenv'"
    
    '~atom': (tokens) ->
        if tokens[0] is 'atom'
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
            else
                @dataStream.write "Atom - The Hackable Text Editor!"
        else
            @errorStream.write "quantum-shell: atom: internal error - expected '#{tokens[0]}' to be 'atom'"
