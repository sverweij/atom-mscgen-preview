mscgenjs    = null # Defer until used

exports.render = (pScript='', pElementId, pGrammar, pCallback) ->
  # TODO: get dependencies from npm
  mscgenjs ?= require './mscgen_js'

  lOptions =
    elementId: pElementId
    inputType: getInputLanguage pGrammar.scopeName

  mscgenjs.renderMsc pScript, lOptions, pCallback

scopeName2inputType =
  'source.msgenny': 'msgenny'
  'source.mscgen': 'mscgen'
  'source.ast': 'json'

getInputLanguage = (pScopeName) ->
  scopeName2inputType[pScopeName] or 'xu'
