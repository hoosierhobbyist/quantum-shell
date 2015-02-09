path = require 'path'
QuantumShellModel = require '../lib/quantum-shell-model'

describe "QuantumShellModel", ->
    describe "prototype", ->
        userName = null
        homePath = null
        verNum = null
        
        beforeEach ->
            userName = process.env.USER or process.env.USERNAME
            homePath = process.env.HOME or process.env.HOMEPATH
            verNum = require(path.join(__dirname, '../package.json'))['version']
        
        it "should have a maxHistory attribute", ->
            expect(QuantumShellModel::maxHistory).toBeDefined()
            expect(QuantumShellModel::maxHistory).toBe 100
        
        it "should have a user attribute", ->
            expect(QuantumShellModel::user).toBeDefined()
            expect(QuantumShellModel::user).toBe userName
        
        it "should have a home attribute", ->
            expect(QuantumShellModel::home).toBeDefined()
            expect(QuantumShellModel::home).toBe homePath
        
        it "should have a version attribute", ->
            expect(QuantumShellModel::version).toBeDefined()
            expect(QuantumShellModel::version).toBe verNum
        
        it "should have a serialize method", ->
            expect(QuantumShellModel::serialize).toBeDefined()
            expect(QuantumShellModel::serialize instanceof Function).toBe true
        
        it "should have a destroy method", ->
            expect(QuantumShellModel::destroy).toBeDefined()
            expect(QuantumShellModel::destroy instanceof Function).toBe true
        
        it "should have a process method", ->
            expect(QuantumShellModel::process).toBeDefined()
            expect(QuantumShellModel::process instanceof Function).toBe true
        
        it "should have an exec method", ->
            expect(QuantumShellModel::exec).toBeDefined()
            expect(QuantumShellModel::exec instanceof Function).toBe true
    
    describe "constructor, without state", ->
        testDummy = null
        
        beforeEach ->
            testDummy = new QuantumShellModel()
        
        it "should return a model object", ->
            expect(testDummy).not.toBeNull()
            expect(testDummy.__proto__).toBe QuantumShellModel::
        
        it "should have a child attribute", ->
            expect(testDummy.child).toBeDefined()
            expect(testDummy.child).toBeNull()
        
        it "should have a dataStream attribute", ->
            expect(testDummy.dataStream).toBeDefined()
            expect(testDummy.dataStream.listeners('data').length).toBe 1
            expect(testDummy.dataStream.listeners('error').length).toBe 1
        
        it "should have an errorStream attribute", ->
            expect(testDummy.errorStream).toBeDefined()
            expect(testDummy.errorStream.listeners('data').length).toBe 1
            expect(testDummy.errorStream.listeners('error').length).toBe 1
        
        it "should have a subscriptions attribute", ->
            expect(testDummy.subscriptions).toBeDefined()
            expect(testDummy.subscriptions.disposables.length).toBe 4
        
        it "should have an aliases attribute", ->
            expect(testDummy.aliases).toBeDefined()
            expect(testDummy.aliases).toEqual {}
        
        it "should have a history attribute", ->
            expect(testDummy.history).toBeDefined()
            expect(testDummy.history).toEqual []
        
        it "should have a lwd attribute", ->
            expect(testDummy.lwd).toBeDefined()
            expect(testDummy.lwd).toBe ''
        
        it "should have a pwd attribute", ->
            expect(testDummy.pwd).toBeDefined()
            expect(testDummy.pwd).toBe atom.project.path or QuantumShellModel::home
        
        it "should have an env attribute", ->
            expect(testDummy.env).toBeDefined()
            expect(testDummy.env).toEqual process.env
    
    describe "constructor, with state", ->
        testDummy = null
        testState =
            aliases:
                'one': 1
                'two': 2
            history: [
                'one'
                'two'
            ]
            lwd: 'last/working/directory'
            pwd: 'present/working/directory'
            env:
                foo: 'bar'
                baz: 'quux'
        
        beforeEach ->
            testDummy = new QuantumShellModel testState
        
        it "should set aliases to serialized state", ->
            expect(testDummy.aliases).toBe testState.aliases
        
        it "should set history to serialized state", ->
            expect(testDummy.history).toBe testState.history
        
        it "should set lwd to serialized state", ->
            expect(testDummy.lwd).toBe testState.lwd
        
        it "should set pwd to serialized state", ->
            expect(testDummy.pwd).toBe testState.pwd
        
        it "should set env to serialized state", ->
            expect(testDummy.env).toBe testState.env
    
    describe "::serialize", ->
        testDummy = null
        testState =
            aliases:
                'one': 1
                'two': 2
            history: [
                'one'
                'two'
            ]
            lwd: 'last/working/directory'
            pwd: 'present/working/directory'
            env:
                foo: 'bar'
                baz: 'quux'
        
        beforeEach ->
            testDummy = new QuantumShellModel testState
        
        it "should return the original state when there have been no changes", ->
            expect(testDummy.serialize()).toEqual testState
        
        it "should reflect run-time changes", ->
            testDummy.aliases['three'] = 3
            testDummy.history.push 'three'
            testDummy.lwd = 'present/working/directory'
            testDummy.pwd = 'last/working/directory'
            testDummy.env.foo = 'barr'
            testDummy.env.short = 'long'
            expect(testDummy.serialize()).toEqual
                aliases:
                    'one': 1
                    'two': 2
                    'three': 3
                history: [
                    'one'
                    'two'
                    'three'
                ]
                lwd: 'present/working/directory'
                pwd: 'last/working/directory'
                env:
                    foo: 'barr'
                    baz: 'quux'
                    short: 'long'
    
    describe "::destroy", ->
        testDummy = null
        
        beforeEach ->
            testDummy = new QuantumShellModel()
            testDummy.child = {kill: ->}
            spyOn(testDummy.child, 'kill')
            spyOn(testDummy.dataStream, 'end')
            spyOn(testDummy.errorStream, 'end')
            spyOn(testDummy.subscriptions, 'dispose')
            testDummy.destroy()
        
        it "should kill the child process", ->
            expect(testDummy.child.kill).toHaveBeenCalled()
        
        it "should end the dataStream", ->
            expect(testDummy.dataStream.end).toHaveBeenCalled()
        
        it "should end the errorStream", ->
            expect(testDummy.errorStream.end).toHaveBeenCalled()
        
        it "should dispose of the subscriptions", ->
            expect(testDummy.subscriptions.dispose).toHaveBeenCalled()