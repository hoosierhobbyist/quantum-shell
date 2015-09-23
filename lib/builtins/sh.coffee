fs = require 'fs'
path = require 'path'
{exec} = require 'child_process'
checkPerm = require '../util/checkPerm'
{U_EX, G_EX, W_EX} = checkPerm

module.exports =
    list:
        '''
        \\. : break chdir cd continue eval exec exit export getopts
        hash pwd readonly return shift test times trap umask unset
        '''.split /\s+/

    '~pwd': (tokens) ->
        if tokens[0] is 'pwd'
            @dataStream.write @pwd
            return 0
        else
            @errorStream.write "quantum-shell: pwd: internal error - expected '#{tokens[0]}' to be 'pwd'"
            return 1

    '~export': (tokens) ->
        if tokens[0] is 'export'
            if tokens.length != 4
                @errorStream.write "quantum-shell: export: invalid input"
                return 1
            else
                if tokens[2] is '='
                    @env[tokens[1]] = tokens[3]
                    return 0
                else
                    @errorStream.write "quantum-shell: export: missing '=' after environment variable name"
                    return 1
        else
            @errorStream.write "quantum-shell: export: internal error - expected '#{tokens[0]} to be 'export'"
            return 1

    '~cd': (tokens) ->
        if tokens[0] is 'cd' or tokens[0] is 'chdir'
            if tokens.length is 1
                @lwd = @pwd
                @pwd = atom.config.get('quantum-shell.home')
                return 0
            else if tokens[1] is '-'
                [@pwd, @lwd] = [@lwd, @pwd]
                return 0
            else
                dir = path.resolve @pwd, tokens[1].replace '~', atom.config.get('quantum-shell.home')
                try
                    stats = fs.statSync dir
                    if stats.isDirectory()
                        if process.platform is 'win32'
                            try
                                ls = exec "dir", cwd: dir, env: @env
                                [@lwd, @pwd] = [@pwd, dir]
                                return 0
                            catch error
                                if error.errno is 'EACCES'
                                    @errorStream.write "quantum-shell: cd: #{tokens[1]} permission denied"
                                    return 1
                                else
                                    console.log "QUANTUM SHELL CD ERROR: #{error}"
                                    return 1
                        else if checkPerm(stats.mode, W_EX) or
                        (stats.uid is process.getuid() and checkPerm(stats.mode, U_EX)) or
                        (stats.gid in process.getgroups() and checkPerm(stats.mode, G_EX))
                            [@lwd, @pwd] = [@pwd, dir]
                            return 0
                        else
                            @errorStream.write "quantum-shell: cd: #{tokens[1]}: permission denied"
                            return 1
                    else
                        @errorStream.write "quantum-shell: cd: #{tokens[1]}: not a directory"
                        return 1
                catch error
                    if error.code is 'ENOENT'
                        @errorStream.write "quantum-shell: cd: #{tokens[1]}: no such file or directory"
                    else
                        atom.notifications.addError "quantum-shell: cd: unexpected error",
                            detail: error.stack
                    return 1
        else
            @errorStream.write "quantum-shell: cd: internal error - expected '#{tokens[0]}' to be 'cd'"
            return 1

module.exports['~chdir'] = module.exports['~cd']
