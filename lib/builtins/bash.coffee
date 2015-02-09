module.exports =
    _echo: (input) -> @dataStream.write input.slice 5
    
    _alias: (input) ->
        tokens = input.split /\s+/
        if tokens.length is 1
            for own key, expansion of @aliases
                @dataStream.write "#{key} = #{expansion}"
        else if tokens.length is 2
            if @aliases[tokens[1]]
                @dataStream.write @aliases[tokens[1]]
            else
                @errorStream.write "quantum-shell: alias: #{tokens[1]} no such alias"
        else
            if tokens[2] is '='
                key = tokens[1]
                expansion = tokens.slice(3).join(' ')
                @aliases[key] = expansion
            else
                @errorStream.write "quantum-shell: alias: missing '=' after alias name"
    
    _unalias: (input) ->
        for own key, expansion of @aliases
            input = input.replace expansion, key
        tokens = input.split /\s+/
        for token in tokens.slice(1)
            if @aliases[token]?
                delete @aliases[token]
            else
                @errorStream.write "quantum-shell: unalias: #{token} no such alias"