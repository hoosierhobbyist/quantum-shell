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
    
    return model.view = main
