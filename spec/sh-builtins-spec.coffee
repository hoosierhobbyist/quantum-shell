path = require 'path'
sh_builtins = require '../lib/builtins/sh'

describe "sh-builtins", ->
    testDummy = null

    beforeEach ->
        testDummy =
            dataStream:
                write: jasmine.createSpy()
            errorStream:
                write: jasmine.createSpy()

    describe "pwd", ->
        beforeEach ->
            testDummy.pwd = '/present/working/directory'

        it "should print an internal error if tokens[0] isnt 'pwd'", ->
            sh_builtins['~pwd'].call testDummy, ['garbage']
            expect(testDummy.errorStream.write).toHaveBeenCalled()
            expect(testDummy.errorStream.write.mostRecentCall.args[0]).toMatch /internal error/

        it "should print the present working directory otherwise", ->
            sh_builtins['~pwd'].call testDummy, ['pwd']
            expect(testDummy.dataStream.write).toHaveBeenCalledWith '/present/working/directory'

    describe "export", ->
        beforeEach ->
            testDummy.env = {}

        it "should print an internal error if tokens[0] isnt 'export'", ->
            sh_builtins['~export'].call testDummy, ['garbage']
            expect(testDummy.errorStream.write).toHaveBeenCalled()
            expect(testDummy.errorStream.write.mostRecentCall.args[0]).toMatch /internal error/

        it "should print an error message if there are less than four tokens", ->
            sh_builtins['~export'].call testDummy, ['export', 'foo', 'bar']
            expect(testDummy.errorStream.write).toHaveBeenCalled()
            expect(testDummy.errorStream.write.mostRecentCall.args[0]).toMatch /invalid input/

        it "should print an error message if there are more than four tokens", ->
            sh_builtins['~export'].call testDummy, ['export', 'foo', 'bar', 'baz', 'quux']
            expect(testDummy.errorStream.write).toHaveBeenCalled()
            expect(testDummy.errorStream.write.mostRecentCall.args[0]).toMatch /invalid input/

        it "should print an error message if the third token isnt '='", ->
            sh_builtins['~export'].call testDummy, ['export', 'foo', 'gets', 'bar']
            expect(testDummy.errorStream.write).toHaveBeenCalled()
            expect(testDummy.errorStream.write.mostRecentCall.args[0]).toMatch /missing '='/

        it "should otherwise assign the key/value pair to this.env", ->
            sh_builtins['~export'].call testDummy, ['export', 'foo', '=', 'bar']
            expect(testDummy.env['foo']).toBe 'bar'

    describe "cd", ->
        beforeEach ->
            testDummy.input = {}
            testDummy.home = '/home/user'
            testDummy.pwd = __dirname
            testDummy.lwd = path.join __dirname, '../lib/builtins'

        it "should print an error message if tokens[0] isnt 'cd'", ->
            sh_builtins['~cd'].call testDummy, ['garbage']
            expect(testDummy.errorStream.write).toHaveBeenCalled()
            expect(testDummy.errorStream.write.mostRecentCall.args[0]).toMatch /internal error/

        it "should print an error message when trying to change to a restricted directory", ->
            runs ->
                sh_builtins['~cd'].call testDummy, ['cd', '/root']
            waitsFor(
                -> testDummy.errorStream.write.calls.length > 0
                "it should have tried to change directories", 1000)
            runs ->
                expect(testDummy.errorStream.write.mostRecentCall.args[0]).toMatch /permission denied/

        it "should print an error message when trying to change to a non-existant file", ->
            runs ->
                sh_builtins['~cd'].call testDummy, ['cd', 'nothing']
            waitsFor(
                -> testDummy.errorStream.write.calls.length > 0
                "it should have tried to change directories", 1000)
            runs ->
                expect(testDummy.errorStream.write.mostRecentCall.args[0]).toMatch /no such file/

        it "should print an error message when trying to change to a non-directory file", ->
            runs ->
                sh_builtins['~cd'].call testDummy, ['cd', 'sh-builtins-spec.coffee']
            waitsFor(
                -> testDummy.errorStream.write.calls.length > 0
                "it should have tried to change directories", 1000)
            runs ->
                expect(testDummy.errorStream.write.mostRecentCall.args[0]).toMatch /not a directory/

        it "should change to the home directory if no arguments are provided", ->
            sh_builtins['~cd'].call testDummy, ['cd']
            expect(testDummy.pwd).toBe '/home/user'
            expect(testDummy.lwd).toBe __dirname
            expect(testDummy.input.placeholder).toBeDefined()

        it "should change to the lwd if '-' is provided as the first argument", ->
            sh_builtins['~cd'].call testDummy, ['cd', '-']
            expect(testDummy.lwd).toBe __dirname
            expect(testDummy.pwd).toBe path.join __dirname, '../lib/builtins'
            expect(testDummy.input.placeholder).toBeDefined()

        it "should otherwise change to the provided directory relative to this.pwd", ->
            runs ->
                sh_builtins['~cd'].call testDummy, ['cd', '../lib']
            waitsFor(
                -> testDummy.input.placeholder?
                "it should have tried to change directories", 1000)
            runs ->
                expect(testDummy.lwd).toBe __dirname
                expect(testDummy.pwd).toBe path.join __dirname, '../lib'
