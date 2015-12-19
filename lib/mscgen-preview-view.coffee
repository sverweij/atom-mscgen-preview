path = require 'path'

{Emitter, Disposable, CompositeDisposable, File} = require 'atom'
{$, $$$, ScrollView} = require 'atom-space-pen-views'
_                    = require 'underscore-plus'
fs                   = require 'fs-plus'
uuid                 = null

renderer             = null # Defer until used
errRenderer          = null # Defer until used
svgToRaster          = null # Defer until used

module.exports =
class MscGenPreviewView extends ScrollView
  @content: ->
    @div class: 'mscgen-preview native-key-bindings', tabindex: -1

  constructor: ({@editorId, @filePath}) ->
    super
    @emitter = new Emitter
    @disposables = new CompositeDisposable
    @loaded = false
    @svg = null

  attached: ->
    return if @isAttached
    @isAttached = true

    if @editorId?
      @resolveEditor(@editorId)
    else
      if atom.workspace?
        @subscribeToFilePath(@filePath)
      else
        @disposables.add atom.packages.onDidActivateInitialPackages =>
          @subscribeToFilePath(@filePath)

  serialize: ->
    deserializer: 'MscGenPreviewView'
    filePath: @getPath() ? @filePath
    editorId: @editorId

  destroy: ->
    @disposables.dispose()

  onDidChangeTitle: (callback) ->
    @emitter.on 'did-change-title', callback

  onDidChangeModified: (callback) ->
    # No op to suppress deprecation warning
    new Disposable

  onDidChangeMsc: (callback) ->
    @emitter.on 'did-change-mscgen', callback

  subscribeToFilePath: (filePath) ->
    @file = new File(filePath)
    @emitter.emit 'did-change-title'
    @handleEvents()
    @renderMsc()

  resolveEditor: (editorId) ->
    resolve = =>
      @editor = @editorForId(editorId)

      if @editor?
        @emitter.emit 'did-change-title' if @editor?
        @handleEvents()
        @renderMsc()
      else
        # The editor this preview was created for has been closed so close
        # this preview since a preview cannot be rendered without an editor
        atom.workspace?.paneForItem(this)?.destroyItem(this)

    if atom.workspace?
      resolve()
    else
      @disposables.add atom.packages.onDidActivateInitialPackages(resolve)

  editorForId: (editorId) ->
    for editor in atom.workspace.getTextEditors()
      return editor if editor.id?.toString() is editorId.toString()
    null

  handleEvents: ->
    @disposables.add atom.grammars.onDidAddGrammar => _.debounce((=> @renderMsc()), 250)
    @disposables.add atom.grammars.onDidUpdateGrammar _.debounce((=> @renderMsc()), 250)

    atom.commands.add @element,
      'core:move-up': =>
        @scrollUp()
      'core:move-down': =>
        @scrollDown()
      'core:save-as': (event) =>
        event.stopPropagation()
        @saveAs('svg')
      'mscgen-preview:save-as-png': (event) =>
        event.stopPropagation()
        @saveAs('png')
      'core:copy': (event) =>
        event.stopPropagation() if @copyToClipboard()
      'mscgen-preview:zoom-in': =>
        zoomLevel = parseFloat(@css('zoom')) or 1
        @css('zoom', zoomLevel + .1)
      'mscgen-preview:zoom-out': =>
        zoomLevel = parseFloat(@css('zoom')) or 1
        @css('zoom', zoomLevel - .1)
      'mscgen-preview:reset-zoom': =>
        @css('zoom', 1)

    changeHandler = =>
      @renderMsc()

      # TODO: Remove paneForURI call when ::paneForItem is released
      pane = atom.workspace.paneForItem?(this) ? atom.workspace.paneForURI(@getURI())
      if pane? and pane isnt atom.workspace.getActivePane()
        pane.activateItem(this)

    if @file?
      @disposables.add @file.onDidChange(changeHandler)
    else if @editor?
      @disposables.add @editor.getBuffer().onDidStopChanging ->
        changeHandler() if atom.config.get 'mscgen-preview.liveUpdate'
      @disposables.add @editor.onDidChangePath => @emitter.emit 'did-change-title'
      @disposables.add @editor.getBuffer().onDidSave ->
        changeHandler() unless atom.config.get 'mscgen-preview.liveUpdate'
      @disposables.add @editor.getBuffer().onDidReload ->
        changeHandler() unless atom.config.get 'mscgen-preview.liveUpdate'

  renderMsc: ->
    @showLoading() unless @loaded
    @getMscSource().then (source) => @renderMscText(source) if source?

  getMscSource: ->
    if @file?.getPath()
      @file.read()
    else if @editor?
      Promise.resolve(@editor.getText())
    else
      Promise.resolve(null)

  renderMscText: (text) ->
    uuid ?= require 'node-uuid'
    lElementId = uuid.v4()
    @html("<div id=#{lElementId}></div>")
    @svg = null # HACK
    renderer ?= require "./renderer"
    renderer.render text, lElementId, @getGrammar(), (error, svg) =>
      if error
        @showError(error)
      else
        @loading = false
        @loaded = true
        @svg = svg # HACK
        @emitter.emit 'did-change-mscgen'
        @originalTrigger('mscgen-preview:msc-changed')

  getSVG: (callback)->
    @getMscSource().then (source) =>
      return unless source?

      renderer.render source, @getPath(), @getGrammar(), callback

  getTitle: ->
    if @file?
      "#{path.basename(@getPath())} Preview"
    else if @editor?
      "#{@editor.getTitle()} Preview"
    else
      "Msc Preview"

  getIconName: ->
    "Msc"

  getURI: ->
    if @file?
      "mscgen-preview://#{@getPath()}"
    else
      "mscgen-preview://editor/#{@editorId}"

  getPath: ->
    if @file?
      @file.getPath()
    else if @editor?
      @editor.getPath()

  getGrammar: ->
    @editor?.getGrammar()

  getDocumentStyleSheets: -> # This function exists so we can stub it
    document.styleSheets

  showError: (error) ->
    errRenderer ?= require './err-renderer'

    @getMscSource().then (source) =>
      @html(errRenderer.renderError source, error.location, error.message) if source?

  showLoading: ->
    @loading = true
    @html $$$ ->
      @div class: 'msc-spinner', 'Loading msc\u2026'

  copyToClipboard: ->
    return false if @loading or not @svg

    atom.clipboard.write(@svg)

    true

  saveAs: (pOutputType) ->
    return if @loading or not @svg

    filePath = @getPath()
    if filePath
      filePath = path.join(
        path.dirname(filePath),
        path.basename(filePath, path.extname(filePath)),
      ).concat('.').concat(pOutputType)
    else
      filePath = 'untitled.'.concat(pOutputType)
      if projectPath = atom.project.getPaths()[0]
        filePath = path.join(projectPath, filePath)

    if outputFilePath = atom.showSaveDialogSync(filePath)
      if 'png' == pOutputType
        svgToRaster ?= require './svg-to-raster'
        fs.writeFileSync(outputFilePath, svgToRaster.transform @svg)
      else
        fs.writeFileSync(outputFilePath, @svg)
      atom.workspace.open(outputFilePath)

  isEqual: (other) ->
    @[0] is other?[0] # Compare DOM elements
