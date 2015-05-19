#quantum-shell view provider function
module.exports = (model) ->
    #create DOM elements
    main = document.createElement 'div'
    header = document.createElement 'h1'
    body = document.createElement 'div'
    btns = document.createElement 'div'
    output = document.createElement 'pre'
    input = document.createElement 'input'
    submit = document.createElement 'button'

    #assign appropriate ids
    main.id = 'quantum-shell'
    header.id = 'quantum-shell-header'
    body.id = 'quantum-shell-body'
    btns.id = 'quantum-shell-btns'
    output.id = 'quantum-shell-output'
    input.id = 'quantum-shell-input'
    submit.id = 'quantum-shell-submit'

    #append children to main
    main.appendChild header
    main.appendChild body
    main.appendChild input
    main.appendChild submit
    body.appendChild btns
    body.appendChild output

    #assign proper classes


    #set text to be displayed
    header.innerHTML = "QUANTUM SHELL v-#{model.version}"
    submit.innerHTML = 'ENTER'
    btns.innerHTML =
        '''
        <button class="btn btn-primary icon-terminal selected inline-block-tight"></button>
        <button class="btn btn-primary icon-terminal inline-block-tight"></button>
        <button class="btn btn-success icon-plus inline-block-tight"></button>
        '''
    output.innerHTML =
        '''
        <div class='text-info'><em>Welcome to Quantum Shell!
        Github repository: <a href='http://github.com/sedabull/quantum-shell'>sedabull/quantum-shell</a>
        Written by Seth David Bullock (sedabull@gmail.com)
        All questions, comments, bug reports, and pull requests are welcome!</em></div>
        '''

    #assign types to form elements
    input.type = 'text'
    submit.type = 'button'

    #communicate with the model
    submit.onclick = ->
        cmd = document.createElement 'div'
        cmd.classList.add 'text-info'
        cmd.classList.add 'quantum-shell-command'
        cmd.innerHTML = input.value
        output.appendChild cmd
        output.scrollTop = Infinity
        model.process input.value
        input.value = ''

    #attach view to model
    model.input = input
    model.submit = submit
    model.output = output
    model.view = main
