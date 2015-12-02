path = require 'path'

{Emitter, Disposable, CompositeDisposable, File} = require 'atom'
{$, $$$, ScrollView} = require 'atom-space-pen-views'
Grim                 = require 'grim'
_                    = require 'underscore-plus'
fs                   = require 'fs-plus'
uuid                 = null

renderer = require './renderer'
errRender = null # Defer until used

module.exports =
class MscGenPreviewView extends ScrollView
  @content: ->
    @div class: 'mscgen-preview native-key-bindings', tabindex: -1

  constructor: ({@editorId, @filePath}) ->
    super
    @emitter = new Emitter
    @disposables = new CompositeDisposable
    @loaded = false

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
    renderer.render text, lElementId, @getGrammar(), (error, domFragment) =>
      if error
        @showError(error)
      else
        @loading = false
        @loaded = true
        # @html(domFragment)
        @emitter.emit 'did-change-mscgen'
        @originalTrigger('mscgen-preview:msc-changed')

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

  getTextEditorStyles: ->
    textEditorStyles = document.createElement("atom-styles")
    textEditorStyles.initialize(atom.styles)
    textEditorStyles.setAttribute "context", "atom-text-editor"
    document.body.appendChild textEditorStyles

    # Extract style elements content
    Array.prototype.slice.apply(textEditorStyles.childNodes).map (styleElement) ->
      styleElement.innerText

  getMscPreviewCSS: ->
    markdowPreviewRules = []
    ruleRegExp = /\.mscgen-preview/
    cssUrlRefExp = /url\(atom:\/\/mscgen-preview\/assets\/(.*)\)/

    for stylesheet in @getDocumentStyleSheets()
      if stylesheet.rules?
        for rule in stylesheet.rules
          # We only need `.Msc-review` css
          markdowPreviewRules.push(rule.cssText) if rule.selectorText?.match(ruleRegExp)?

    markdowPreviewRules
      .concat(@getTextEditorStyles())
      .join('\n')
      .replace(/atom-text-editor/g, 'pre.editor-colors')
      .replace(/:host/g, '.host') # Remove shadow-dom :host selector causing problem on FF
      .replace cssUrlRefExp, (match, assetsName, offset, string) -> # base64 encode assets
        assetPath = path.join __dirname, '../assets', assetsName
        originalData = fs.readFileSync assetPath, 'binary'
        base64Data = new Buffer(originalData, 'binary').toString('base64')
        "url('data:image/jpeg;base64,#{base64Data}')"

  showError: (error) ->
    # TODO: properly dreg in and/ or use atom native error handling
    errRender ?= require './mscgen_js/ui/embedding/error-rendering'

    @html(errRender.renderError error.sourceMsc, error.location, error.message)

    # @html $$$ ->
      # @h2 'Previewing Msc Failed'
      # @h3 failureMessage if failureMessage?
      # @span

  showLoading: ->
    @loading = true
    @html $$$ ->
      @div class: 'msc-spinner', 'Loading msc\u2026'

  isEqual: (other) ->
    @[0] is other?[0] # Compare DOM elements

if Grim.includeDeprecatedAPIs
  MscGenPreviewView::on = (eventName) ->
    if eventName is 'mscgen-preview:msc-changed'
      Grim.deprecate("Use MscGenPreviewView::onDidChangeMsc instead of the 'mscgen-preview:msc-changed' jQuery event")
    super
