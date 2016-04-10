path              = require 'path'
fs                = require 'fs-plus'
temp              = require 'temp'
wrench            = require 'wrench'
MscGenPreviewView = require '../lib/mscgen-preview-view'
{$}               = require 'atom-space-pen-views'

describe "MscGen preview package", ->
  [workspaceElement, preview] = []

  beforeEach ->
    fixturesPath = path.join(__dirname, 'fixtures')
    tempPath = temp.mkdirSync('atom')
    wrench.copyDirSyncRecursive(fixturesPath, tempPath, forceDelete: true)
    atom.project.setPaths([tempPath])

    jasmine.useRealClock()

    workspaceElement = atom.views.getView(atom.workspace)
    jasmine.attachToDOM(workspaceElement)

    waitsForPromise ->
      atom.packages.activatePackage("mscgen-preview")

    # TODO works well. But not when it's also in the program under test.
    # So now instead wer're having the language-mscgen snippets & grammars
    # included in the package.
    # waitsForPromise ->
    #   require('atom-package-deps').install(require('../package.json').name)

    # waitsForPromise ->
    #   atom.packages.activatePackage('language-mscgen')

  expectPreviewInSplitPane = ->
    runs ->
      expect(atom.workspace.getPanes()).toHaveLength 2

    waitsFor "mscgen preview to be created", ->
      preview = atom.workspace.getPanes()[1].getActiveItem()

    runs ->
      expect(preview).toBeInstanceOf(MscGenPreviewView)
      expect(preview.getPath()).toBe atom.workspace.getActivePaneItem().getPath()

  describe "when a preview has not been created for the file", ->
    it "displays a mscgen preview in a split pane", ->
      waitsForPromise -> atom.workspace.open("subdir/demo.mscgen")
      runs -> atom.commands.dispatch workspaceElement, 'mscgen-preview:toggle'
      expectPreviewInSplitPane()

      runs ->
        [editorPane] = atom.workspace.getPanes()
        expect(editorPane.getItems()).toHaveLength 1
        expect(editorPane.isActive()).toBe true

    describe "when the editor's path does not exist", ->
      it "splits the current pane to the right with a mscgen preview for the file", ->
        waitsForPromise -> atom.workspace.open("new.mscgen")
        runs -> atom.commands.dispatch workspaceElement, 'mscgen-preview:toggle'
        expectPreviewInSplitPane()

    describe "when the path contains a space", ->
      it "renders the preview", ->
        waitsForPromise -> atom.workspace.open("subdir/a test with filename spaces.msgenny")
        runs -> atom.commands.dispatch workspaceElement, 'mscgen-preview:toggle'
        expectPreviewInSplitPane()

    describe "when the path contains non-ASCII characters", ->
      it "renders the preview", ->
        waitsForPromise -> atom.workspace.open("subdir/序列圖.xu")
        runs -> atom.commands.dispatch workspaceElement, 'mscgen-preview:toggle'
        expectPreviewInSplitPane()

  describe "when a preview has been created for the file", ->
    beforeEach ->
      waitsForPromise -> atom.workspace.open("subdir/a test with filename spaces.msgenny")
      runs -> atom.commands.dispatch workspaceElement, 'mscgen-preview:toggle'
      expectPreviewInSplitPane()

    it "closes the existing preview when toggle is triggered a second time on the editor", ->
      atom.commands.dispatch workspaceElement, 'mscgen-preview:toggle'

      [editorPane, previewPane] = atom.workspace.getPanes()
      expect(editorPane.isActive()).toBe true
      expect(previewPane.getActiveItem()).toBeUndefined()

    it "closes the existing preview when toggle is triggered on it and it has focus", ->
      [editorPane, previewPane] = atom.workspace.getPanes()
      previewPane.activate()

      atom.commands.dispatch workspaceElement, 'mscgen-preview:toggle'
      expect(previewPane.getActiveItem()).toBeUndefined()

    describe "when the editor is modified", ->
      it "re-renders the preview", ->
        spyOn(preview, 'showLoading')

        mscEditor = atom.workspace.getActiveTextEditor()
        mscEditor.setText "a note a: made in Holland;"

        waitsFor ->
          preview.text().indexOf("a note a: made in Holland;") >= 0

        runs ->
          expect(preview.showLoading).not.toHaveBeenCalled()

      xit "invokes ::onDidChangeMsc listeners", ->
        mscEditor = atom.workspace.getActiveTextEditor()
        preview.onDidChangeMsc(listener = jasmine.createSpy('didChangeMscListener'))

        runs ->
          mscEditor.setText("a note a: made in Holland;")

        waitsFor "::onDidChangeMsc handler to be called", ->
          listener.callCount > 0

      describe "when the preview is in the active pane but is not the active item", ->
        it "re-renders the preview but does not make it active", ->
          mscEditor = atom.workspace.getActiveTextEditor()
          previewPane = atom.workspace.getPanes()[1]
          previewPane.activate()

          waitsForPromise ->
            atom.workspace.open()

          runs ->
            mscEditor.setText("a note a: made in Holland;")

          waitsFor ->
            preview.text().indexOf("a note a: made in Holland;") >= 0

          runs ->
            expect(previewPane.isActive()).toBe true
            expect(previewPane.getActiveItem()).not.toBe preview

      describe "when the preview is not the active item and not in the active pane", ->
        it "re-renders the preview and makes it active", ->
          mscEditor = atom.workspace.getActiveTextEditor()
          [editorPane, previewPane] = atom.workspace.getPanes()
          previewPane.splitRight(copyActiveItem: true)
          previewPane.activate()

          waitsForPromise ->
            atom.workspace.open()

          runs ->
            editorPane.activate()
            mscEditor.setText("a note a: made in Holland;")

          waitsFor ->
            preview.text().indexOf("a note a: made in Holland;") >= 0

          runs ->
            expect(editorPane.isActive()).toBe true
            expect(previewPane.getActiveItem()).toBe preview

      describe "when the liveUpdate config is set to false", ->
        it "only re-renders the mscgen when the editor is saved, not when the contents are modified", ->
          atom.config.set 'mscgen-preview.liveUpdate', false

          didStopChangingHandler = jasmine.createSpy('didStopChangingHandler')
          atom.workspace.getActiveTextEditor().getBuffer().onDidStopChanging didStopChangingHandler
          atom.workspace.getActiveTextEditor().setText('ch ch changes')

          waitsFor ->
            didStopChangingHandler.callCount > 0

          runs ->
            expect(preview.text()).not.toContain("ch ch changes")
            atom.workspace.getActiveTextEditor().save()

          waitsFor ->
            preview.text().indexOf("ch ch changes") >= 0

  describe "when the mscgen preview view is requested by file URI", ->
    it "opens a preview editor and watches the file for changes", ->
      waitsForPromise "atom.workspace.open promise to be resolved", ->
        atom.workspace.open("mscgen-preview://#{atom.project.getDirectories()[0].resolve('subdir/atest.mscgen')}")

      runs ->
        preview = atom.workspace.getActivePaneItem()
        expect(preview).toBeInstanceOf(MscGenPreviewView)

        spyOn(preview, 'renderMscText')
        preview.file.emitter.emit('did-change')

      waitsFor "mscgen to be re-rendered after file changed", ->
        preview.renderMscText.callCount > 0

  describe "when the editor's path changes on #win32 and #darwin", ->
    it "updates the preview's title", ->
      titleChangedCallback = jasmine.createSpy('titleChangedCallback')

      waitsForPromise -> atom.workspace.open("subdir/atest.mscgen")
      runs -> atom.commands.dispatch workspaceElement, 'mscgen-preview:toggle'

      expectPreviewInSplitPane()

      runs ->
        expect(preview.getTitle()).toBe 'atest.mscgen Preview'
        preview.onDidChangeTitle(titleChangedCallback)
        fs.renameSync(atom.workspace.getActiveTextEditor().getPath(), path.join(path.dirname(atom.workspace.getActiveTextEditor().getPath()), 'atest2.mscgen'))

      waitsFor ->
        preview.getTitle() is "atest2.mscgen Preview"

      runs ->
        expect(titleChangedCallback).toHaveBeenCalled()

  describe "when the URI opened does not have a mscgen-preview protocol", ->
    it "does not throw an error trying to decode the URI (regression)", ->
      waitsForPromise ->
        atom.workspace.open('%')

      runs ->
        expect(atom.workspace.getActiveTextEditor()).toBeTruthy()

  describe "sanitization", ->
    it "removes script tags and attributes that commonly contain inline scripts", ->
      waitsForPromise -> atom.workspace.open("subdir/puthaken.mscgen")
      runs -> atom.commands.dispatch workspaceElement, 'mscgen-preview:toggle'
      expectPreviewInSplitPane()

      runs ->
        expect(preview[0].innerHTML).toContain """<span style="text-decoration:underline">&lt;</span>puthaken&gt;spul&lt;/puthaken&gt;"""
        expect(preview[0].innerHTML).toContain """error on line 1, column 1"""
        expect(preview[0].innerHTML).toContain """Expected "msc", comment, lineend or whitespace but "&lt;" found."""

  describe "translations in buffers not associated to files", ->
    beforeEach ->
      waitsForPromise -> atom.packages.activatePackage("language-json")

    describe "when mscgen-preview:translate is triggered", ->
      it "does nothing when the current buffer is not mscgen-previewable", ->
        waitsForPromise -> atom.workspace.open()
        runs ->
          mscEditor = atom.workspace.getActiveTextEditor()
          mscEditor.setGrammar(atom.grammars.grammarForScopeName("source.json"))
          mscEditor.setText "Jan, Pier, Tjorus en Korneel. Die hebben baarden"
          atom.commands.dispatch workspaceElement, 'mscgen-preview:translate'
          expect(mscEditor.getText()).toBe "Jan, Pier, Tjorus en Korneel. Die hebben baarden"
          expect(mscEditor.getGrammar().scopeName).toBe "source.json"

      it "translates MscGen into MsGenny in the current buffer and switches the grammar", ->
        waitsForPromise -> atom.workspace.open()
        runs ->
          mscEditor = atom.workspace.getActiveTextEditor()
          mscEditor.setGrammar(atom.grammars.grammarForScopeName("source.mscgen"))
          mscEditor.setText """
          /* just a sample */
          msc {
            a,b,c;
            a =>b [label="label should be there", textcolor="red", url="url won't be there"];
            b >> a [label="spoken with truthiness"],
            b -> c;
          }
          """
          atom.commands.dispatch workspaceElement, 'mscgen-preview:translate'
          expect(mscEditor.getText()).toBe """
          /* just a sample */
          a, b, c;

          a => b : label should be there;
          b >> a : spoken with truthiness,
          b -> c;

          """
          expect(mscEditor.getGrammar().scopeName).toBe "source.msgenny"

      it "translates MsGenny into Xù in the current buffer and switches the grammar", ->
        waitsForPromise -> atom.workspace.open()
        runs ->
          mscEditor = atom.workspace.getActiveTextEditor()
          mscEditor.setGrammar(atom.grammars.grammarForScopeName("source.msgenny"))
          mscEditor.setText """
          /* just a sample */
          a, b, c;

          a => b : label should be there;
          b >> a : spoken with truthiness,
          b -> c;
          """
          atom.commands.dispatch workspaceElement, 'mscgen-preview:translate'
          expect(mscEditor.getText()).toBe """
          /* just a sample */
          msc {
            a,
            b,
            c;

            a => b [label="label should be there"];
            b >> a [label="spoken with truthiness"],
            b -> c;
          }
          """
          expect(mscEditor.getGrammar().scopeName).toBe "source.xu"
      it "formats MscGen in the current buffer", ->
        waitsForPromise -> atom.workspace.open()
        runs ->
          mscEditor = atom.workspace.getActiveTextEditor()
          mscEditor.setGrammar(atom.grammars.grammarForScopeName("source.mscgen"))
          mscEditor.setText """
          /* just a sample */
          msc {
            a,b,c;
            a =>b [label="label should be there",


            textcolor="red", url="url won't be there"];
            # comment that will disappear
            b     >> a [label="spoken with truthiness"],b->c;
          }
          """
          atom.commands.dispatch workspaceElement, 'mscgen-preview:auto-format'
          expect(mscEditor.getText()).toBe """/* just a sample */
          msc {
            a,
            b,
            c;

            a => b [label="label should be there", url="url won't be there", textcolor="red"];
            b >> a [label="spoken with truthiness"],
            b -> c;
          }
          """
          expect(mscEditor.getGrammar().scopeName).toBe "source.mscgen"

    describe "when mscgen-preview:abstract-syntax-tree is triggered in an unassociated buffer", ->
      it "translates the current program into json and switches the grammar", ->
        waitsForPromise -> atom.workspace.open()

        runs ->
          mscEditor = atom.workspace.getActiveTextEditor()
          mscEditor.setGrammar(atom.grammars.grammarForScopeName("source.msgenny"))
          mscEditor.setText "a;"
          atom.commands.dispatch workspaceElement, 'mscgen-preview:abstract-syntax-tree'
          expect(mscEditor.getText()).toBe """
          {
            "meta": {
              "extendedOptions": false,
              "extendedArcTypes": false,
              "extendedFeatures": false
            },
            "entities": [
              {
                "name": "a"
              }
            ]
          }
          """
          expect(mscEditor.getGrammar().scopeName).toBe "source.json"

  describe "when mscgen-preview:translate is triggered in a buffer associated to a file", ->
    beforeEach ->
      fixturesPath = path.join(__dirname, 'fixtures')
      tempPath     = temp.mkdirSync('atom')
      wrench.copyDirSyncRecursive(fixturesPath, tempPath, forceDelete: true)
      atom.project.setPaths([tempPath])

      workspaceElement = atom.views.getView(atom.workspace)
      jasmine.attachToDOM(workspaceElement)

    it "saves the MsGenny variant of the MscGen program and opens it", ->
      outputPath = temp.path() + 'subdir/序列圖.msgenny'

      waitsForPromise -> atom.workspace.open('subdir/序列圖.xu')
      runs ->
        spyOn(atom, 'showSaveDialogSync').andReturn(outputPath)
        atom.commands.dispatch workspaceElement, 'mscgen-preview:translate'
      waitsFor ->
        fs.existsSync(outputPath)
      runs ->
        expect(fs.isFileSync(outputPath)).toBe true
        writtenFile = fs.readFileSync outputPath, 'utf8'
        # console.log writtenFile
        expect(writtenFile).toContain """wordwraparcs=true;

        c : Consumer, api : Super API;

        c =>> api : GET /;
        api >> c : interfaces;
        c loop api : for each interface {
          c =>> api : GET interface;
          c alt api : Happy day {
            api >> c : 200: response;
            --- : error;
            api >> c : error;
          };
        };
        """
