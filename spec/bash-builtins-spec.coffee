bash_builtins = require '../lib/builtins/bash'

describe "bash-builtins", ->
    testDummy = null

    beforeEach ->
        testDummy =
            dataStream:
                write: jasmine.createSpy()
            errorStream:
                write: jasmine.createSpy()

    describe "echo", ->
        it "should print an internal error if tokens[0] isnt 'echo'", ->
            bash_builtins['~echo'].call testDummy, ['garbage']
            expect(testDummy.errorStream.write).toHaveBeenCalled()
            expect(testDummy.errorStream.write.mostRecentCall.args[0]).toMatch /internal error/

        it "should otherwise reprint tokens[1]..tokens[n]", ->
            bash_builtins['~echo'].call testDummy, ['echo', 'this', 'is', 'a', 'foo', 'test']
            expect(testDummy.dataStream.write).toHaveBeenCalled()
            expect(testDummy.dataStream.write.mostRecentCall.args[0]).toBe 'this is a foo test'

    describe "alias", ->
        beforeEach ->
            testDummy.aliases = {}

        it "should print an internal error if tokens[0] isnt 'alias'", ->
            bash_builtins['~alias'].call testDummy, ['garbage']
            expect(testDummy.errorStream.write).toHaveBeenCalled()
            expect(testDummy.errorStream.write.mostRecentCall.args[0]).toMatch /internal error/

        it "should print an error message when trying to read a non-existant alias", ->
            bash_builtins['~alias'].call testDummy, ['alias', 'foo']
            expect(testDummy.errorStream.write).toHaveBeenCalled()
            expect(testDummy.errorStream.write.mostRecentCall.args[0]).toMatch /no such alias/

        it "should print an error message when there are only three tokens", ->
            bash_builtins['~alias'].call testDummy, ['alias', 'foo', 'bar']
            expect(testDummy.errorStream.write).toHaveBeenCalled()
            expect(testDummy.errorStream.write.mostRecentCall.args[0]).toMatch /invalid input/

        it "should print an error message if the third token isnt '='", ->
            bash_builtins['~alias'].call testDummy, ['alias', 'foo', 'gets', 'bar']
            expect(testDummy.errorStream.write).toHaveBeenCalled()
            expect(testDummy.errorStream.write.mostRecentCall.args[0]).toMatch /missing '='/

        it "should print all registered aliases if only one token is present", ->
            testDummy.aliases['foo'] = 'bar'
            testDummy.aliases['baz'] = 'quux'
            bash_builtins['~alias'].call testDummy, ['alias']
            expect(testDummy.dataStream.write.calls.length).toBe 2
            expect(testDummy.dataStream.write.calls[0].args[0]).toBe 'foo = bar'
            expect(testDummy.dataStream.write.calls[1].args[0]).toBe 'baz = quux'

        it "should print a registered alias if only two tokens are present", ->
            testDummy.aliases['foo'] = 'bar --baz --quux'
            bash_builtins['~alias'].call testDummy, ['alias', 'foo']
            expect(testDummy.dataStream.write).toHaveBeenCalledWith 'bar --baz --quux'

        it "should otherwise register the provided alias", ->
            bash_builtins['~alias'].call testDummy, ['alias', 'foo', '=', 'bar', '--baz', '--quux']
            expect(testDummy.aliases['foo']).toBe 'bar --baz --quux'

    describe "unalias", ->
        beforeEach ->
            testDummy.aliases = {}

        it "should print an internal error if tokens[0] isnt 'unalias'", ->
            bash_builtins['~unalias'].call testDummy, ['garbage']
            expect(testDummy.errorStream.write).toHaveBeenCalled()
            expect(testDummy.errorStream.write.mostRecentCall.args[0]).toMatch /internal error/

        it "should print an error when trying to remove a non-existant alias", ->
            bash_builtins['~unalias'].call testDummy, ['unalias', 'foo']
            expect(testDummy.errorStream.write).toHaveBeenCalled()
            expect(testDummy.errorStream.write.mostRecentCall.args[0]).toMatch /no such alias/

        it "should otherwise remove a registered alias", ->
            testDummy.aliases['foo'] = 'bar --baz --quux'
            bash_builtins['~unalias'].call testDummy, ['unalias', 'bar', '--baz', '--quux']
            expect(testDummy.aliases['foo']).toBeUndefined()
