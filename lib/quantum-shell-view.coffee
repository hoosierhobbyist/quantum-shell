module.exports = (model) ->
    main = document.createElement 'div'
    header = document.createElement 'h1'
    output = document.createElement 'pre'
    input = document.createElement 'input'
    submit = document.createElement 'button'
    
    main.id = 'quantum-shell'
    header.id = 'quantum-shell-header'
    output.id = 'quantum-shell-output'
    input.id = 'quantum-shell-input'
    submit.id = 'quantum-shell-submit'
    
    main.appendChild header
    main.appendChild output
    main.appendChild input
    main.appendChild submit
    
    header.innerHTML = "QUANTUM SHELL v-#{model.version}"
    input.placeholder = "#{model.user}@atom:#{model.pwd.replace model.home, '~'}$"
    submit.innerHTML = 'ENTER'
    output.innerHTML = 
        '''
        <em>Welcome to Quantum Shell!
        Written by Seth David Bullock (sedabull@gmail.com)
        Github repository: http://github.com/sedabull/quantum-shell
        All questions, comments, bug reports, and pull requests are welcome!</em>
        '''
    
    input.type = 'text'
    submit.type = 'button'
    
    submit.onclick = ->
        cmd = document.createElement 'div'
        cmd.classList.add 'quantum-shell-command'
        cmd.innerHTML = input.value
        output.appendChild cmd
        output.scrollTop = Infinity
        model.process input.value
        input.value = ''
    
    model.subscriptions.add atom.commands.add(
        '#quantum-shell'
        'quantum-shell:kill-process'
        -> model.child.kill()
    )#end kill-process command
    model.subscriptions.add atom.commands.add(
        '#quantum-shell-input'
        'quantum-shell:submit'
        -> submit.click()
    )#end submit command
    model.subscriptions.add atom.commands.add(
        '#quantum-shell-input'
        'quantum-shell:backspace'
        -> input.value = input.value.slice 0, -1
    )#end backspace command
    model.subscriptions.add atom.commands.add(
        '#quantum-shell-input'
        'quantum-shell:history-back'
        => 
            if model.history.pos?
                if model.history.pos == -1
                    model.history.temp = input.value
                    model.history.pos = 0
                if model.history.pos < model.history.length
                    input.value = model.history[model.history.pos]
                    model.history.pos += 1
    )#end history-back command
    model.subscriptions.add atom.commands.add(
        '#quantum-shell-input'
        'quantum-shell:history-forward'
        =>
            if model.history.pos?
                if model.history.pos > 0
                    model.history.pos -= 1
                    input.value = model.history[model.history.pos]
                else if model.history.pos is 0
                    model.history.pos = -1
                    input.value = model.history.temp
                    model.history.temp = ''
    )#end history-forward command
    
    model.input = input
    model.output = output
    return main
