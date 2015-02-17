custom_builtins = require '../lib/builtins/custom'

describe "custom-builtins", ->
    testDummy = null

    beforeEach ->
        testDummy =
            dataStream:
                write: jasmine.createSpy()
            errorStream:
                write: jasmine.createSpy()

    describe "clear", ->
        beforeEach ->
            testDummy.output = document.createElement 'div'

        it "should print an internal error if tokens[0] isnt 'clear'", ->
            custom_builtins['~clear'].call testDummy, ['garbage']
            expect(testDummy.errorStream.write).toHaveBeenCalled()
            expect(testDummy.errorStream.write.mostRecentCall.args[0]).toMatch /internal error/

        it "should otherwise remove all child nodes from the output div", ->
            for i in [0...99]
                testDummy.output.appendChild document.createElement 'p'
            custom_builtins['~clear'].call testDummy, ['clear']
            expect(testDummy.output.childNodes.length).toBe 0

    describe "history", ->
        beforeEach ->
            testDummy.history = []

        it "should print an internal error if tokens[0] isnt 'history'", ->
            custom_builtins['~history'].call testDummy, ['garbage']
            expect(testDummy.errorStream.write).toHaveBeenCalled()
            expect(testDummy.errorStream.write.mostRecentCall.args[0]).toMatch /internal error/

        it "should otherwise write every history entry to the data stream", ->
            for i in [0..99]
                testDummy.history.push 'foo'
            custom_builtins['~history'].call testDummy, ['history']
            expect(testDummy.dataStream.write.calls.length).toBe 99

    describe "printenv", ->
        beforeEach ->
            testDummy.env = {}

        it "should print an internal error if tokens[0] isnt 'printenv'", ->
            custom_builtins['~printenv'].call testDummy, ['garbage']
            expect(testDummy.errorStream.write).toHaveBeenCalled()
            expect(testDummy.errorStream.write.mostRecentCall.args[0]).toMatch /internal error/

        it "should print an error message when trying to read a non-existant environment variable", ->
            custom_builtins['~printenv'].call testDummy, ['printenv', 'FOO']
            expect(testDummy.errorStream.write).toHaveBeenCalled()
            expect(testDummy.errorStream.write.mostRecentCall.args[0]).toMatch /no such environment variable/

        it "should print all environment key/value pairs when there is only one token", ->
            testDummy.env['foo'] = 'FOO'
            testDummy.env['bar'] = 'BAR'
            testDummy.env['baz'] = 'BAZ'
            testDummy.env['quux'] = 'QUUX'
            custom_builtins['~printenv'].call testDummy, ['printenv']
            expect(testDummy.dataStream.write.calls.length).toBe 4
            expect(testDummy.dataStream.write.calls[0].args[0]).toBe 'foo = FOO'
            expect(testDummy.dataStream.write.calls[1].args[0]).toBe 'bar = BAR'
            expect(testDummy.dataStream.write.calls[2].args[0]).toBe 'baz = BAZ'
            expect(testDummy.dataStream.write.calls[3].args[0]).toBe 'quux = QUUX'

    describe "atom", ->
        beforeEach ->
            workspaceElement = atom.views.getView atom.workspace
            jasmine.attachToDOM workspaceElement

        it "should print an internal error if tokens[0] isnt 'atom'", ->
            custom_builtins['~atom'].call testDummy, ['garbage']
            expect(testDummy.errorStream.write).toHaveBeenCalled()
            expect(testDummy.errorStream.write.mostRecentCall.args[0]).toMatch /internal error/

        it "should print an error message if an invalid command was entered", ->
            custom_builtins['~atom'].call testDummy, ['atom', 'not-a-valid:command']
            expect(testDummy.errorStream.write).toHaveBeenCalled()
            expect(testDummy.errorStream.write.mostRecentCall.args[0]).toMatch /not a valid command/

        it "should print an error message if an invalid selector was entered", ->
            custom_builtins['~atom'].call testDummy, ['atom', 'not-a-valid-selector', 'not-a-valid:command']
            expect(testDummy.errorStream.write).toHaveBeenCalled()
            expect(testDummy.errorStream.write.mostRecentCall.args[0]).toMatch /not a valid target/

        it "should print a friendly greeting when only one token is present", ->
            custom_builtins['~atom'].call testDummy, ['atom']
            expect(testDummy.dataStream.write).toHaveBeenCalled()
            expect(testDummy.dataStream.write.mostRecentCall.args[0]).toMatch /Atom.*!/

        it "should otherwise dispatch the command to an appropriate target", ->
            dispatched = false
            disposable = atom.commands.onWillDispatch ->
                dispatched = true
            custom_builtins['~atom'].call testDummy, ['atom', 'window:toggle-full-screen']
            expect(dispatched).toBe true
            expect(testDummy.dataStream.write).toHaveBeenCalled()
            disposable.dispose()
            custom_builtins['~atom'].call testDummy, ['atom', 'window:toggle-full-screen']
