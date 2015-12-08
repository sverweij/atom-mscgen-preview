path = require 'path'
fs = require 'fs-plus'
temp = require 'temp'
wrench = require 'wrench'
MscGenPreviewView = require '../lib/mscgen-preview-view'

describe "MscGenPreviewView", ->
  [file, preview, workspaceElement] = []

  beforeEach ->
    filePath = atom.project.getDirectories()[0].resolve('subdir/asample.mscgen')
    preview = new MscGenPreviewView({filePath})
    jasmine.attachToDOM(preview.element)

    waitsForPromise ->
      atom.packages.activatePackage("mscgen-preview")

  afterEach ->
    preview.destroy()

  describe "::constructor", ->
    it "shows a loading spinner and renders the mscgen", ->
      preview.showLoading()
      expect(preview.find('.msc-spinner')).toExist()

      waitsForPromise ->
        preview.renderMsc()

  describe "serialization", ->
    newPreview = null

    afterEach ->
      newPreview?.destroy()

    # TDOO deserialization not implemented
    xit "recreates the preview when serialized/deserialized", ->
      newPreview = atom.deserializers.deserialize(preview.serialize())
      jasmine.attachToDOM(newPreview.element)
      expect(newPreview.getPath()).toBe preview.getPath()

    it "does not recreate a preview when the file no longer exists", ->
      filePath = path.join(temp.mkdirSync('mscgen-preview-'), 'foo.msgenny')
      fs.writeFileSync(filePath, '# Hi')

      preview.destroy()
      preview = new MscGenPreviewView({filePath})
      serialized = preview.serialize()
      fs.removeSync(filePath)

      newPreview = atom.deserializers.deserialize(serialized)
      expect(newPreview).toBeUndefined()

    it "serializes the editor id when opened for an editor", ->
      preview.destroy()

      waitsForPromise ->
        atom.workspace.open('new.mscgen')

      runs ->
        preview = new MscGenPreviewView({editorId: atom.workspace.getActiveTextEditor().id})

        jasmine.attachToDOM(preview.element)
        expect(preview.getPath()).toBe atom.workspace.getActiveTextEditor().getPath()

        newPreview = atom.deserializers.deserialize(preview.serialize())
        jasmine.attachToDOM(newPreview.element)
        expect(newPreview.getPath()).toBe preview.getPath()

  describe "when core:copy is triggered", ->
    beforeEach ->
      fixturesPath = path.join(__dirname, 'fixtures')
      tempPath = temp.mkdirSync('atom')
      wrench.copyDirSyncRecursive(fixturesPath, tempPath, forceDelete: true)
      atom.project.setPaths([tempPath])

      jasmine.useRealClock()

      workspaceElement = atom.views.getView(atom.workspace)
      jasmine.attachToDOM(workspaceElement)
      atom.clipboard.write "initial clipboard content"

    it "writes the rendered SVG to the clipboard", ->
      previewPaneItem = null

      waitsForPromise ->
        atom.workspace.open('subdir/序列圖.xu')
      runs ->
        atom.commands.dispatch workspaceElement, 'mscgen-preview:toggle'
      waitsFor ->
        previewPaneItem = atom.workspace.getPanes()[1].getActiveItem()
      runs ->
        atom.commands.dispatch previewPaneItem.element, 'core:copy'
      waitsFor ->
        atom.clipboard.read() isnt "initial clipboard content"

      runs ->
        expect(atom.clipboard.read()).toContain """<svg version="1.1" id="""
        expect(atom.clipboard.read()).toContain "<tspan>Super API</tspan></text></g>"

  describe "when core:save-as is triggered", ->
    beforeEach ->
      fixturesPath = path.join(__dirname, 'fixtures')
      tempPath = temp.mkdirSync('atom')
      wrench.copyDirSyncRecursive(fixturesPath, tempPath, forceDelete: true)
      atom.project.setPaths([tempPath])

      jasmine.useRealClock()

      workspaceElement = atom.views.getView(atom.workspace)
      jasmine.attachToDOM(workspaceElement)

    it "saves an SVG and opens it", ->
      outputPath = temp.path() + 'subdir/序列圖.svg'
      previewPaneItem = null

      waitsForPromise ->
        atom.workspace.open('subdir/序列圖.xu')
      runs ->
        atom.commands.dispatch workspaceElement, 'mscgen-preview:toggle'
      waitsFor ->
        previewPaneItem = atom.workspace.getPanes()[1].getActiveItem()
      runs ->
        spyOn(atom, 'showSaveDialogSync').andReturn(outputPath)
        atom.commands.dispatch previewPaneItem.element, 'core:save-as'
      waitsFor ->
        fs.existsSync(outputPath)

      runs ->
        expect(fs.isFileSync(outputPath)).toBe true
        writtenFile = fs.readFileSync outputPath
        expect(writtenFile).toContain """<svg version="1.1" id="""
        expect(writtenFile).toContain "<tspan>Super API</tspan></text></g>"
