QuantumShellView = require '../lib/quantum-shell-view'
QuantumShellModel = require '../lib/quantum-shell-model'

describe 'QuantumShellView', ->
    testDummy = null
    
    beforeEach ->
        testDummy = new QuantumShellModel()
        QuantumShellView testDummy
        spyOn(testDummy, 'process')
    afterEach ->
        testDummy.destroy()
    
    it "should attach the main div to the model", ->
        expect(testDummy.view).toBeDefined()
    
    it "should have a header field", ->
        expect(testDummy.view.querySelector('h1')).toBeDefined()
    
    it "should have an output field", ->
        expect(testDummy.view.querySelector('pre')).toBeDefined()
    
    it "should have an input field", ->
        expect(testDummy.view.querySelector('input')).toBeDefined()
    
    it "should have a working submit button", ->
        expect(testDummy.view.querySelector('button')).toBeDefined()
        expect(testDummy.view.querySelector('button').onclick).toBeDefined()
    
    it "should call model.process with the current input value", ->
        testDummy.view.querySelector('input').value = 'foo bar'
        testDummy.view.querySelector('button').click()
        expect(testDummy.process).toHaveBeenCalledWith 'foo bar'
        expect(testDummy.view.querySelector('input').value).toBe ''
