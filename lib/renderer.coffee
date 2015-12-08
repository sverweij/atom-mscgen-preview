mscgenjs    = null # Defer until used

scopeName2inputType =
  'source.msgenny': 'msgenny'
  'source.mscgen': 'mscgen'
  'source.ast': 'json'

exports.render = (pScript='', pElementId, pGrammar, pCallback) ->
  # TODO: get dependencies from npm
  mscgenjs ?= require './mscgen_js'

  lOptions =
    elementId: pElementId
    inputType: scopeName2inputType[pGrammar.scopeName] or 'xu'

  mscgenjs.renderMsc pScript, lOptions, pCallback
