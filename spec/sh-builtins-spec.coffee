sh_builtins = require '../lib/builtins/sh'

describe "sh_builtins", ->
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
            expect(testDummy.errorStream.write.args[0]).toMatch /internal error/
        
        it "should print the present working directory otherwise", ->
            sh_builtins['~pwd'].call testDummy, ['pwd']
            expect(testDummy.dataStream.write).toHaveBeenCalledWith '/present/working/directory'
    
    describe "export", ->
        beforeEach ->
            testDummy.env = {}
        
        it "should print an internal error if tokens[0] isnt 'export'", ->
            sh_builtins['~export'].call testDummy, ['garbage']
            expect(testDummy.errorStream.write).toHaveBeenCalled()
            expect(testDummy.errorStream.write.args[0]).toMatch /internal error/
        
        it "should print an error message if there are less than four tokens", ->
            sh_builtins['~export'].call testDummy, ['export', 'foo', 'bar']
            expect(testDummy.errorStream.write).toHaveBeenCalled()
            expect(testDummy.errorStream.write.args[0]).toMatch /invalid input/
        
        it "should print an error message if there are more than four tokens", ->
            sh_builtins['~export'].call testDummy, ['export', 'foo', 'bar', 'baz', 'quux']
            expect(testDummy.errorStream.write).toHaveBeenCalled()
            expect(testDummy.errorStream.write.args[0]).toMatch /invalid input/
        
        it "should print an error message if the third token isnt '='", ->
            sh_builtins['~export'].call testDummy, ['export', 'foo', 'gets', 'bar']
            expect(testDummy.errorStream.write).toHaveBeenCalled()
            expect(testDummy.errorStream.write.args[0]).toMatch /missing '='/
        
        it "should otherwise assign the key/value pair to this.env", ->
            sh_builtins['~export'].call testDummy, ['export', 'foo', '=', 'bar']
            expect(testDummy.env['foo']).toBe 'bar'
    
    describe "cd", ->
        beforeEach ->
            testDummy.input = {}
            testDummy.home = '/home/user'
            testDummy.pwd = '/present/working/directory'
            testDummy.lwd = '/last/working/directory'
        
        it "should print an error message if tokens[0] isnt 'cd'", ->
            sh_builtins['~cd'].call testDummy, ['garbage']
            expect(testDummy.errorStream.write).toHaveBeenCalled()
            expect(testDummy.errorStream.write.args[0]).toMatch /internal error/
        
        it "should change to the home directory if no arguments are provided", ->
            sh_builtins['~cd'].call testDummy, ['cd']
            expect(testDummy.pwd).toBe '/home/user'
            expect(testDummy.lwd).toBe '/present/working/directory'
            expect(testDummy.input.placeholder).toBeDefined()
        
        it "should change to the lwd if '-' is provided as the first argument", ->
            sh_builtins['~cd'].call testDummy, ['cd', '-']
            expect(testDummy.pwd).toBe '/last/working/directory'
            expect(testDummy.lwd).toBe '/present/working/directory'
            expect(testDummy.input.placeholder).toBeDefined()
        
        #TODO find a way to test asynchronous directory changes, or change to fs.statsSync
