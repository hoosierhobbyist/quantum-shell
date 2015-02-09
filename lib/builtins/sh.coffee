fs = require 'fs'
path = require 'path'
{exec} = require 'child_process'

module.exports =
    _pwd: -> @dataStream.write @pwd
    
    _export: (input) ->
        tokens = input.split /\s+/
        if tokens.length is 1
            @_printenv input
        else if tokens.length > 2
            if tokens[2] is '='
                enVar = tokens[1]
                value = tokens.slice(3).join(' ')
                @env[enVar] = value
            else
                @errorStream.write "quantum-shell: export: missing '=' after environment variable name"
    
    _cd: (input) ->
        tokens = input.split(/\s+/)
        
        if tokens.length is 1
            @lwd = @pwd
            @pwd = @home
            @input.placeholder = "#{@user}@atom:~$"
        else if tokens[1] is '-'
            [@pwd, @lwd] = [@lwd, @pwd]
            @input.placeholder = "#{@user}@atom:#{@pwd.replace @home, '~'}$"
        else if tokens[1].match /^-./
            @errorStream.write "quantum-shell: cd: invalid option"
        else
            newPWD = path.resolve @pwd, tokens[1].replace '~', @home
            fs.stat newPWD, (error, stats) =>
                if error
                    if error.code is 'ENOENT'
                        @errorStream.write "quantum-shell: cd: no such file or directory"
                    else
                        console.log "QUANTUM SHELL CD ERROR: #{error}"
                else
                    if stats.isDirectory()
                        try
                            exec 'ls', cwd: newPWD, env: @env
                            @lwd = @pwd
                            @pwd = newPWD
                            @input.placeholder = "#{@user}@atom:#{@pwd.replace @home, '~'}$"
                        catch error
                            if error.errno is 'EACCES'
                                @errorStream.write "quantum-shell: cd: #{tokens[1]} permission denied"
                            else
                                console.log "QUANTUM SHELL CD ERROR: #{error}"
                    else
                        @errorStream.write "quantum-shell: cd: #{tokens[1]} is not a directory"