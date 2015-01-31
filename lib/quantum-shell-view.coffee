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
    
    header.innerHTML = "QUANTUM SHELL v-#{atom.packages.getLoadedPackage('quantum-shell').metadata.version}"
    input.placeholder = "#{process.env.USER}@atom:#{process.env.PWD.replace(process.env.HOME, '~')}$"
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
        value = input.value
        input.value = ''
        cmd = document.createElement 'span'
        cmd.classList.add 'quantum-shell-command'
        cmd.innerHTML = value + '\n'
        output.appendChild cmd
        output.scrollTop = Infinity
        model.exec value
    
    model.subscriptions.add atom.commands.add '#quantum-shell-input', 'quantum-shell:submit', -> submit.click()
    model.subscriptions.add atom.commands.add '#quantum-shell-input', 'quantum-shell:backspace', -> input.value = input.value.slice 0, -1
    
    model.output = output
    return main