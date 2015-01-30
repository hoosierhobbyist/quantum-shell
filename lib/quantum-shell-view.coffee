module.exports = (model) ->
    main = document.createElement 'div'
    header = document.createElement 'h1'
    output = document.createElement 'div'
    form = document.createElement 'form'
    input = document.createElement 'input'
    submit = document.createElement 'button'
    
    main.id = 'quantum-shell-main'
    header.id = 'quantum-shell-header'
    output.id = 'quantum-shell-output'
    form.id = 'quantum-shell-form'
    input.id = 'quantum-shell-input'
    submit.id = 'quantum-shell-submit'
    
    main.classList.add 'quantum-shell'
    main.appendChild header
    main.appendChild output
    main.appendChild form
    form.appendChild input
    form.appendChild submit
    
    header.innerHTML = "QUANTUM SHELL v-#{atom.packages.getLoadedPackage('quantum-shell').metadata.version}"
    input.placeholder = "#{process.env.USER}@atom:#{process.env.PWD.replace(process.env.HOME, '~')}$"
    submit.innerHTML = 'ENTER'
    output.innerHTML = 
        '''
        <em>
        Welcome to Quantum Shell!<br />
        Written by Seth David Bullock (sedabull@gmail.com)<br />
        Github repository: http://github.com/sedabull/quantum-shell<br />
        All questions, comments, bug reports, and pull requests are welcome!<br />
        </em>
        '''
    
    input.type = 'text'
    submit.type = 'button'
    
    submit.onclick = ->
        value = input.value
        input.value = ''
        p = document.createElement 'p'
        p.classList.add 'quantum-shell-command'
        p.innerHTML = value
        output.appendChild p
        output.scrollTop = Infinity
        model.exec value
    
    model.subscriptions.add atom.commands.add '#quantum-shell-input', 'quantum-shell:submit', -> submit.click()
    model.subscriptions.add atom.commands.add '#quantum-shell-input', 'quantum-shell:backspace', -> input.value = input.value.slice 0, -1
    
    model.output = output
    return main