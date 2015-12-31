mscgenjs    = null # Defer until used

scopeName2inputType  =
  'source.msgenny' : 'msgenny'
  'source.mscgen'  : 'mscgen'
  'source.xu'      : 'xu'
  'source.ast'     : 'json'

exports.scopeName2inputType = scopeName2inputType

exports.render = (pScript='', pElementId, pGrammar, pCallback) ->
  mscgenjs ?= require 'mscgenjs'

  lOptions =
    elementId: pElementId
    inputType: scopeName2inputType[pGrammar.scopeName] or 'xu'

  mscgenjs.renderMsc pScript, lOptions, pCallback

exports.translate = (pScript='', pScopeFrom, pScopeTo, pCallback) ->
  mscgenjs ?= require 'mscgenjs'

  lOptions =
    inputType: scopeName2inputType[pScopeFrom] or 'msgenny'
    outputType: scopeName2inputType[pScopeTo] or 'xu'

  mscgenjs.translateMsc pScript, lOptions, pCallback
