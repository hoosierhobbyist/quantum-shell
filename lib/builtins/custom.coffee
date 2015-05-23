module.exports =
    list:
        '''
        atom clear history printenv shopt
        '''.split /\s+/

    '~clear': (tokens) ->
        if tokens[0] is 'clear'
            while element = @output.firstChild
                @output.removeChild element
            return 0
        else
            @errorStream.write "quantum-shell: clear: internal error - expected '#{tokens[0]}' to be 'clear'"
            return 1

    '~history': (tokens) ->
        if tokens[0] is 'history'
            len = @history.length - 1
            for i in [len..0] by -1
                j = @history.num - i - 1
                @dataStream.write "#{j}: #{@history[i]}"
            return 0
        else
            @errorStream.write "quantum-shell: history: internal error - expected '#{tokens[0]}' to be 'history'"
            return 1

    '~printenv': (tokens) ->
        if tokens[0] is 'printenv'
            if tokens.length is 1
                for own key, value of @env
                    @dataStream.write "#{key} = #{value}"
                return 0
            else
                if @env[tokens[1]]?
                    @dataStream.write @env[tokens[1]]
                    return 0
                else
                    @errorStream.write "quantum-shell: printenv: '#{tokens[1]}' no such environment variable"
                    return 1
        else
            @errorStream.write "quantum-shell: printenv: internal error - expected '#{tokens[0]}' to be 'printenv'"
            return 1

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
                        return 0
                    else
                        @errorStream.write "quantum-shell: atom: '#{command}' is not a valid command at target '#{selector}'"
                        return 1
                else
                    @errorStream.write "quantum-shell: atom: '#{selector}' is not a valid target"
                    return 1
            else
                @dataStream.write "Atom - The Hackable Text Editor!"
                return 0
        else
            @errorStream.write "quantum-shell: atom: internal error - expected '#{tokens[0]}' to be 'atom'"
            return 1
