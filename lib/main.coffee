url      = require 'url'
fs       = require 'fs-plus'
path     = require 'path'
renderer = null

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
      order: 1
      description: 'Re-render the preview as the contents of the source changes, without requiring the source buffer to be saved. If disabled, the preview is re-rendered only when the buffer is saved to disk.'
    openPreviewInSplitPane:
      type: 'boolean'
      default: true
      order: 2
      description: 'Open the preview in a split pane. If disabled, the preview is opened in a new tab in the same pane.'
    mirrorEntities:
      type: 'boolean'
      default: false
      order: 3
      description: 'Mirror entities on the chart\'s bottom'
    styleAdditions:
      title: 'Style Additions'
      type: 'string'
      default: ''
      order: 4
      description: '**Experimental!** Additional (CSS) styles to use for rendering the graphics. We\'d _love_ to hear your [feedback](https://github.com/sverweij/atom-mscgen-preview/issues/new?title=Feedback%20on%20\'additional%20styles\':&body=...) on this feature.'
      enum: [
        '',
        '/* lazy */ text.entity-text{font-weight:bold;text-decoration:none;}text.return-text{font-style:italic}path.note{fill:#FFFFCC}rect.label-text-background{opacity:0.9}line.comment,rect.inline_expression,.inline_expression_divider,.inline_expression_label{stroke:grey}',
        '/* bare */ line{stroke-width:1px}line.arc{stroke-width:2px}rect.entity{stroke:none}text.entity-text{text-decoration:none}.inline_expression{stroke-width:1px}.inline_expression_divider{stroke-width: 1px} .inline_expression_label{stroke-width: 1px}',
        '/* swan */ line{stroke:#00A1DE}text{fill:#005B82}rect.entity,rect.box,path.box{fill:#00A1DE;stroke:#00A1DE;}text.box-text{fill:white}text.entity-text{font-weight:bold;fill:white;text-decoration:none;}text.return-text{font-style:italic}path.note{fill:#E77B2F;stroke:white}line.comment,rect.inline_expression,.inline_expression_divider,path.inline_expression_label{fill:white}',
        '/* pegasse */ line{stroke:rgba(0, 43, 84, 1)}text{fill:rgba(0, 43, 84, 1)}rect.entity,rect.box,path.box{fill:rgba(0, 43, 84, 1);stroke:rgba(0, 43, 84, 1);}text.box-text{fill:white}text.entity-text{font-weight:bold;fill:white;text-decoration:none;}text.return-text{font-style:italic}path.note{fill:rgba(255, 50, 0, 1);stroke:white}line.comment,rect.inline_expression,.inline_expression_divider,path.inline_expression_label{fill:white}'

      ]


  activate: ->
    atom.deserializers.add
      name: 'MscGenPreviewView'
      deserialize: (state) ->
        if state.editorId or fs.isFileSync(state.filePath)
          createMscGenPreviewView(state)

    atom.commands.add 'atom-workspace',
      'mscgen-preview:toggle': =>
        @toggle()
      'mscgen-preview:translate': =>
        @translate()
      'mscgen-preview:abstract-syntax-tree': =>
        @translate('source.json')
      'mscgen-preview:auto-format': =>
        @autoFormat()

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

  isActionable: ->
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

    return editor

  translate: (pScopeName)->
    return unless editor = @isActionable()

    autoTranslations =
      'source.mscgen' : 'source.msgenny'
      'source.xu'     : 'source.msgenny'
      'source.msgenny': 'source.xu'

    toScope = pScopeName or autoTranslations[editor.getGrammar().scopeName] or 'source.xu'

    renderer ?= require "./renderer"
    renderer.translate editor.getText(), editor.getGrammar().scopeName, toScope, (error, result) ->
      if error
        console.error error
      else
        filePath = editor.getPath()
        if filePath
          filePath = path.join(
            path.dirname(filePath),
            path.basename(filePath, path.extname(filePath)),
          ).concat('.').concat(renderer.scopeName2inputType[toScope] or 'xu')
          if outputFilePath = atom.showSaveDialogSync(filePath)
            fs.writeFileSync(outputFilePath, result)
            atom.workspace.open(outputFilePath)
        else # just a buffer => replace contents & swap grammar
          editor.setGrammar(atom.grammars.grammarForScopeName(toScope))
          editor.setText(result)

  autoFormat: ->
    return unless editor = @isActionable()
    renderer ?= require "./renderer"
    renderer.translate editor.getText(), editor.getGrammar().scopeName, editor.getGrammar().scopeName, (error, result) ->
      if error
        console.error error
      else
        editor.setText(result)

  toggle: ->
    return unless editor = @isActionable()
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
