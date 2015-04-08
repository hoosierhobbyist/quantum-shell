path = require 'path'
{CompositeDisposable} = require 'atom'
QuantumShellView = require '../lib/quantum-shell-view'
QuantumShellModel = require '../lib/quantum-shell-model'

describe "QuantumShellModel", ->
    describe "prototype", ->
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
        afterEach ->
            testDummy.destroy()

        it "should return a model object", ->
            expect(testDummy instanceof QuantumShellModel).toBe true

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

        it "should have an aliases attribute", ->
            expect(testDummy.aliases).toBeDefined()
            expect(testDummy.aliases).toEqual {}

        it "should have a history attribute", ->
            expect(testDummy.history).toBeDefined()
            expect(testDummy.history).toEqual []

        it "should have a lwd attribute", ->
            expect(testDummy.lwd).toBeDefined()
            expect(testDummy.lwd).toEqual QuantumShellModel::home

        it "should have a pwd attribute", ->
            expect(testDummy.pwd).toBeDefined()
            expect(testDummy.pwd).toEqual atom.project.getPaths()[0] or QuantumShellModel::home

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
                PATH: __dirname

        beforeEach ->
            testDummy = new QuantumShellModel testState
        afterEach ->
            testDummy.destroy()

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
                PATH: __dirname
            commands: {}
            fileNames: {}

        beforeEach ->
            testDummy = new QuantumShellModel testState
        afterEach ->
            testDummy.destroy()

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
                    PATH: __dirname
                commands: {}
                fileNames: {}

    describe "::destroy", ->
        testDummy = null

        beforeEach ->
            testDummy = new QuantumShellModel()
            testDummy.child = {kill: ->}
            spyOn(testDummy.child, 'kill').andCallThrough()
            spyOn(testDummy.dataStream, 'end').andCallThrough()
            spyOn(testDummy.errorStream, 'end').andCallThrough()
            testDummy.destroy()

        it "should kill the child process", ->
            expect(testDummy.child.kill).toHaveBeenCalled()

        it "should close the data stream", ->
            expect(testDummy.dataStream.end).toHaveBeenCalled()

        it "should close the error stream", ->
            expect(testDummy.errorStream.end).toHaveBeenCalled()

    describe "::process", ->
        testDummy = null
        builtins = QuantumShellModel::builtins

        beforeEach ->
            QuantumShellModel::builtins = null
            testDummy = new QuantumShellModel()
            QuantumShellView testDummy
            spyOn(testDummy, 'exec')
            spyOn(testDummy, 'process').andCallThrough()
        afterEach ->
            QuantumShellModel::builtins = builtins
            testDummy.destroy()
            QuantumShellModel::maxHistory = 100

        it "should cache an input and an output reference", ->
            testDummy.process 'foo bar'
            expect(testDummy.input).toBeDefined()
            expect(testDummy.output).toBeDefined()

        it "should reset the history queue", ->
            testDummy.history.pos = 8
            testDummy.history.dir = 'garbage'
            testDummy.history.temp = 'more garbage'
            testDummy.process "foo bar"
            expect(testDummy.process).toHaveBeenCalled()
            expect(testDummy.history.pos).toBe -1
            expect(testDummy.history.dir).toBe ''
            expect(testDummy.history.temp).toBe ''
            expect(testDummy.history.length).toBe 1
            expect(testDummy.history[0]).toBe "foo bar"

        it "should record no more than ::maxHistory entries", ->
            QuantumShellModel::maxHistory = 1
            testDummy.process "foo"
            testDummy.process "bar"
            expect(testDummy.process.calls.length).toBe 2
            expect(testDummy.history.length).toBe 1
            expect(testDummy.history[0]).toBe "bar"

        it "should expand registered aliases", ->
            testDummy.aliases['foo'] = 'foo bar'
            testDummy.process 'foo test'
            expect(testDummy.exec).toHaveBeenCalledWith 'foo bar test'

        it "should not expand aliases conatined within substrings", ->
            testDummy.aliases['foo'] = 'foo bar'
            testDummy.process 'testfoo'
            expect(testDummy.exec).toHaveBeenCalledWith 'testfoo'

        it "should not expand aliases contained within single quotes", ->
            testDummy.aliases['foo'] = 'foo bar'
            testDummy.process "testing 'bar foo baz'"
            expect(testDummy.exec).toHaveBeenCalledWith "testing 'bar foo baz'"

        it "should not expand aliases contained within double quotes", ->
            testDummy.aliases['foo'] = 'foo bar'
            testDummy.process 'testing "bar foo baz"'
            expect(testDummy.exec).toHaveBeenCalledWith 'testing "bar foo baz"'

        it "should expand environment variables", ->
            testDummy.env['FOO'] = 'BAR'
            testDummy.process 'testing $FOO'
            expect(testDummy.exec).toHaveBeenCalledWith 'testing BAR'

        it "should not expand environment variables contained within substrings", ->
            testDummy.env['FOO'] = 'BAR'
            testDummy.process 'testing$FOO'
            expect(testDummy.exec).toHaveBeenCalledWith 'testing$FOO'

        it "should not expand environment variables contained within single quotes", ->
            testDummy.env['FOO'] = 'BAR'
            testDummy.process "this 'is a $FOO' test"
            expect(testDummy.exec).toHaveBeenCalledWith "this 'is a $FOO' test"

        it "should not expand environment variables contained within double quotes", ->
            testDummy.env['FOO'] = 'BAR'
            testDummy.process 'this is also a "$FOO test"'
            expect(testDummy.exec).toHaveBeenCalledWith 'this is also a "$FOO test"'

        it "should delegate to a builtin when available", ->
            QuantumShellModel::builtins = /^testing$/
            testing = jasmine.createSpy 'testing'
            QuantumShellModel::['~testing'] = testing
            testDummy.process 'testing 1 2 3'
            expect(testing).toHaveBeenCalledWith ['testing', '1', '2', '3']
            expect(testDummy.exec).not.toHaveBeenCalled()

    describe "::exec", ->
        dataSpy = null
        errorSpy = null
        testDummy = null

        beforeEach ->
            testDummy = new QuantumShellModel()
            testDummy.dataStream.on 'pipe', dataSpy = jasmine.createSpy 'dataSpy'
            testDummy.errorStream.on 'pipe', errorSpy = jasmine.createSpy 'errorSpy'
        afterEach ->
            testDummy.destroy()

        it "should create a child process instance", ->
            expect(testDummy.child).toBeNull()
            testDummy.exec 'node'
            expect(testDummy.child).not.toBeNull()

        it "should not override an existing process", ->
            testDummy.exec 'node'
            node = testDummy.child
            testDummy.exec 'coffee'
            expect(testDummy.child).toBe node

        it "should pipe the child's stdout to the data stream", ->
            testDummy.exec 'node'
            expect(dataSpy).toHaveBeenCalled()

        it "should pipe the child's stderr to the error stream", ->
            testDummy.exec 'node'
            expect(errorSpy).toHaveBeenCalled()
