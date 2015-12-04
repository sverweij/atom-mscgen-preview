url = require 'url'
fs = require 'fs-plus'

MscGenPreviewView = null # Defer until used

createMscGenPreviewView = (state) ->
  MscGenPreviewView ?= require './mscgen-preview-view'
  new MscGenPreviewView(state)

isMscGenPreviewView = (object) ->
  MscGenPreviewView ?= require './mscgen-preview-view'
  object instanceof MscGenPreviewView

module.exports =
  config:
    liveUpdate:
      type: 'boolean'
      default: true
      description: 'Re-render the preview as the contents of the source changes, without requiring the source buffer to be saved. If disabled, the preview is re-rendered only when the buffer is saved to disk.'
    openPreviewInSplitPane:
      type: 'boolean'
      default: true
      description: 'Open the preview in a split pane. If disabled, the preview is opened in a new tab in the same pane.'

  activate: ->
    # TODO: this works. However, when running apm test (who're using the same
    # trick) :zap: "Could not resolve 'language-mscgen' to a package path"
    #
    # require('atom-package-deps').install(require('../package.json').name)
    #
    # So instead language-mscgen (grammar, snippets) is included integrally
    # in the package.
    # It'll additionally need a package-deps array in package.json:
    #  "package-deps": [
    #    "language-mscgen"
    #],

    atom.deserializers.add
      name: 'MscGenPreviewView'
      deserialize: (state) ->
        if state.editorId or fs.isFileSync(state.filePath)
          createMscGenPreviewView(state)

    atom.commands.add 'atom-workspace',
      'mscgen-preview:toggle': =>
        @toggle()

    # previewFile = @previewFile.bind(this)
    # atom.commands.add '.tree-view .file .name[data-name$=\\.mscgen]', 'mscgen-preview:preview-file', previewFile

    atom.workspace.addOpener (uriToOpen) ->
      try
        {protocol, host, pathname} = url.parse(uriToOpen)
      catch error
        return

      return unless protocol is 'mscgen-preview:'

      try
        pathname = decodeURI(pathname) if pathname
      catch error
        return

      if host is 'editor'
        createMscGenPreviewView(editorId: pathname.substring(1))
      else
        createMscGenPreviewView(filePath: pathname)

  toggle: ->
    if isMscGenPreviewView(atom.workspace.getActivePaneItem())
      atom.workspace.destroyActivePaneItem()
      return

    editor = atom.workspace.getActiveTextEditor()
    return unless editor?

    grammars = [
      'source.mscgen'
      'source.xu'
      'source.msgenny'
    ]
    return unless editor.getGrammar().scopeName in grammars

    @addPreviewForEditor(editor) unless @removePreviewForEditor(editor)

  uriForEditor: (editor) ->
    "mscgen-preview://editor/#{editor.id}"

  removePreviewForEditor: (editor) ->
    uri = @uriForEditor(editor)
    previewPane = atom.workspace.paneForURI(uri)
    if previewPane?
      previewPane.destroyItem(previewPane.itemForURI(uri))
      true
    else
      false

  addPreviewForEditor: (editor) ->
    uri = @uriForEditor(editor)
    previousActivePane = atom.workspace.getActivePane()
    options =
      searchAllPanes: true
    if atom.config.get('mscgen-preview.openPreviewInSplitPane')
      options.split = 'right'
    atom.workspace.open(uri, options).then (mscgenPreviewView) ->
      if isMscGenPreviewView(mscgenPreviewView)
        previousActivePane.activate()

  # previewFile: ({target}) ->
  #   filePath = target.dataset.path
  #   return unless filePath
  #
  #   for editor in atom.workspace.getTextEditors() when editor.getPath() is filePath
  #     @addPreviewForEditor(editor)
  #     return
  #
  #   atom.workspace.open "mscgen-preview://#{encodeURI(filePath)}", searchAllPanes: true
