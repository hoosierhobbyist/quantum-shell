module.exports =
    '~echo': (tokens) ->
        if tokens[0] is 'echo'
            @dataStream.write tokens.slice(1).join ' '
        else
            @errorStream.write "quantum-shell: echo: internal error - expected '#{tokens[0]}' to be 'echo'"
    
    '~alias': (tokens) ->
        if tokens[0] is 'alias'
            if tokens.length is 1
                for own key, expansion of @aliases
                    @dataStream.write "#{key} = #{expansion}"
            else if tokens.length is 2
                if @aliases[tokens[1]]
                    @dataStream.write @aliases[tokens[1]]
                else
                    @errorStream.write "quantum-shell: alias: '#{tokens[1]}' no such alias"
            else if tokens.length >= 4
                if tokens[2] is '='
                    @aliases[tokens[1]] = tokens.slice(3).join ' '
                else
                    @errorStream.write "quantum-shell: alias: missing '=' after alias name"
            else
                @errorStream.write "quantum-shell: alias: invalid input"
        else
            @errorStream.write "quantum-shell: alias: internal error - expected '#{tokens[0]}' to be 'alias'"
    
    '~unalias': (tokens) ->
        if tokens[0] is 'unalias'
            input = tokens.slice(1).join ' '
            for own key, expansion of @aliases
                input = input.replace expansion, key
            tokens = input.split /\s+/
            for token in tokens
                if @aliases[token]?
                    delete @aliases[token]
                else
                    @errorStream.write "quantum-shell: unalias: #{token} no such alias"
        else
            @errorStream.write "quantum-shell: unalias: internal error - expected '#{tokens[0]}' to be 'unalias'"
