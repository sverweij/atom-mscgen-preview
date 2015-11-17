path = require 'path'
fs = require 'fs-plus'
temp = require 'temp'
MscGenPreviewView = require '../lib/mscgen-preview-view'

describe "MscGenPreviewView", ->
  [file, preview, workspaceElement] = []

  beforeEach ->
    filePath = atom.project.getDirectories()[0].resolve('subdir/asample.mscgen')
    preview = new MscGenPreviewView({filePath})
    jasmine.attachToDOM(preview.element)

    waitsForPromise ->
      atom.packages.activatePackage("mscgen-preview")

    waitsForPromise ->
      require('atom-package-deps').install(require('../package.json').name)
        .then ->
          atom.packages.activatePackage('language-mscgen')

  afterEach ->
    preview.destroy()

  describe "::constructor", ->
    it "shows a loading spinner and renders the mscgen", ->
      preview.showLoading()
      expect(preview.find('.msc-spinner')).toExist()

      waitsForPromise ->
        preview.renderMsc()

    it "shows an error message when there is an error", ->
      error =
        sourceMsc: "weird source"
        location:
          start:
            line: 13
            column: 37
        message: "Listen carefully. I only say this once."
        
      preview.showError(error)
      expect(preview.text()).toContain "# ERROR on line 13, column 37 - Listen carefully. I only say this once."

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
