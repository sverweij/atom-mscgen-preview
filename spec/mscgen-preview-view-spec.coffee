path              = require 'path'
fs                = require 'fs-plus'
temp              = require 'temp'
MscGenPreviewView = require '../lib/mscgen-preview-view'

describe "MscGenPreviewView", ->
  [preview, workspaceElement] = []

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

    it "recreates the preview when serialized/deserialized", ->
      newPreview = atom.deserializers.deserialize(preview.serialize())
      jasmine.attachToDOM(newPreview.element)
      expect(newPreview.getPath()).toBe preview.getPath()

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
      fs.copySync(fixturesPath, tempPath)
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

  describe "zoom functions", ->
    previewPaneItem = null

    beforeEach ->
      fixturesPath = path.join(__dirname, 'fixtures')
      tempPath = temp.mkdirSync('atom')
      fs.copySync(fixturesPath, tempPath)
      atom.project.setPaths([tempPath])

      jasmine.useRealClock()

      workspaceElement = atom.views.getView(atom.workspace)
      jasmine.attachToDOM(workspaceElement)

      waitsForPromise ->
        atom.workspace.open('subdir/序列圖.xu')
      runs ->
        atom.commands.dispatch workspaceElement, 'mscgen-preview:toggle'
      waitsFor ->
        previewPaneItem = atom.workspace.getPanes()[1].getActiveItem()

    it "3x mscgen-preview:zoom-in increases the image size by 30%", ->
      atom.commands.dispatch previewPaneItem.element, 'mscgen-preview:zoom-in'
      atom.commands.dispatch previewPaneItem.element, 'mscgen-preview:zoom-in'
      atom.commands.dispatch previewPaneItem.element, 'mscgen-preview:zoom-in'
      lSvg = previewPaneItem.imageContainer.find('svg')[0]
      expect(lSvg.style.zoom).toBe '1.3'

    it "2x mscgen-preview:zoom-out decreases the image size by 20%", ->
      atom.commands.dispatch previewPaneItem.element, 'mscgen-preview:zoom-out'
      atom.commands.dispatch previewPaneItem.element, 'mscgen-preview:zoom-out'
      lSvg = previewPaneItem.imageContainer.find('svg')[0]
      expect(lSvg.style.zoom).toBe '0.8'

    it "mscgen-preview:reset-zoom resets zoom after size change", ->
      atom.commands.dispatch previewPaneItem.element, 'mscgen-preview:zoom-out'
      atom.commands.dispatch previewPaneItem.element, 'mscgen-preview:reset-zoom'
      lSvg = previewPaneItem.imageContainer.find('svg')[0]
      expect(lSvg.style.zoom).toBe '1'

    it "mscgen-preview:reset-zoom resets zoom after zoom-to-fit", ->
      atom.commands.dispatch previewPaneItem.element, 'mscgen-preview:zoom-to-fit'
      atom.commands.dispatch previewPaneItem.element, 'mscgen-preview:reset-zoom'
      lSvg = previewPaneItem.imageContainer.find('svg')[0]
      expect(lSvg.style.zoom).toBe '1'
      expect(lSvg.getAttribute('width')).toBe '344'

    it "mscgen-preview:zoom-to-fit zooms to fit", ->
      atom.commands.dispatch previewPaneItem.element, 'mscgen-preview:zoom-to-fit'
      lSvg = previewPaneItem.imageContainer.find('svg')[0]
      expect(lSvg.style.zoom).toBe '1'
      expect(lSvg.getAttribute('width')).toBe '100%'

  describe "when core:save-as is triggered", ->
    beforeEach ->
      fixturesPath = path.join(__dirname, 'fixtures')
      tempPath = temp.mkdirSync('atom')
      fs.copySync(fixturesPath, tempPath)
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
        spyOn(atom.applicationDelegate, 'showSaveDialog').andReturn(outputPath)
        atom.commands.dispatch previewPaneItem.element, 'core:save-as'
      waitsFor ->
        fs.existsSync(outputPath)

      runs ->
        expect(fs.isFileSync(outputPath)).toBe true
        writtenFile = fs.readFileSync outputPath
        expect(writtenFile).toContain """<svg version="1.1" id="""
        expect(writtenFile).toContain "<tspan>Super API</tspan></text></g>"

    it "saves a PNG and opens it", ->
      outputPath = temp.path() + 'subdir/序列圖.png'
      previewPaneItem = null

      waitsForPromise ->
        atom.workspace.open('subdir/序列圖.xu')
      runs ->
        atom.commands.dispatch workspaceElement, 'mscgen-preview:toggle'
      waitsFor ->
        previewPaneItem = atom.workspace.getPanes()[1].getActiveItem()
      runs ->
        spyOn(atom.applicationDelegate, 'showSaveDialog').andReturn(outputPath)
        atom.commands.dispatch previewPaneItem.element, 'mscgen-preview:save-as-png'
      waitsFor ->
        fs.existsSync(outputPath)

      runs ->
        expect(fs.isFileSync(outputPath)).toBe true
        writtenFile = fs.readFileSync outputPath
        expect(writtenFile).toContain "PNG"
