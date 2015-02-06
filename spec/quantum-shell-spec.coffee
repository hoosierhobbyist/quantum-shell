QuantumShell = require '../lib/quantum-shell'

# Use the command `window:run-package-specs` (cmd-alt-ctrl-p) to run specs.
#
# To run a specific `it` or `describe` block add an `f` to the front (e.g. `fit`
# or `fdescribe`). Remove the `f` to unfocus the block.

describe "QuantumShell", ->
  [workspaceElement, activationPromise] = []

  beforeEach ->
    workspaceElement = atom.views.getView(atom.workspace)
    activationPromise = atom.packages.activatePackage('quantum-shell')

  describe "when the quantum-shell:toggle event is triggered", ->
    it "hides and shows the bottom panel", ->
      # Before the activation event the view is not on the DOM, and no panel
      # has been created
      expect(workspaceElement.querySelector('#quantum-shell')).not.toExist()

      # This is an activation event, triggering it will cause the package to be
      # activated.
      atom.commands.dispatch workspaceElement, 'quantum-shell:toggle'

      waitsForPromise ->
        activationPromise

      runs ->
        expect(workspaceElement.querySelector('#quantum-shell')).toExist()

        quantumShellElement = workspaceElement.querySelector('#quantum-shell')
        expect(quantumShellElement).toExist()

        quantumShellPanel = atom.workspace.panelForItem(quantumShellElement)
        expect(quantumShellPanel.isVisible()).toBe true
        atom.commands.dispatch workspaceElement, 'quantum-shell:toggle'
        expect(quantumShellPanel.isVisible()).toBe false

    it "hides and shows the view", ->
      # This test shows you an integration test testing at the view level.

      # Attaching the workspaceElement to the DOM is required to allow the
      # `toBeVisible()` matchers to work. Anything testing visibility or focus
      # requires that the workspaceElement is on the DOM. Tests that attach the
      # workspaceElement to the DOM are generally slower than those off DOM.
      jasmine.attachToDOM(workspaceElement)

      expect(workspaceElement.querySelector('#quantum-shell')).not.toExist()

      # This is an activation event, triggering it causes the package to be
      # activated.
      atom.commands.dispatch workspaceElement, 'quantum-shell:toggle'

      waitsForPromise ->
        activationPromise

      runs ->
        # Now we can test for view visibility
        quantumShellElement = workspaceElement.querySelector('#quantum-shell')
        expect(quantumShellElement).toBeVisible()
        atom.commands.dispatch workspaceElement, 'quantum-shell:toggle'
        expect(quantumShellElement).not.toBeVisible()
