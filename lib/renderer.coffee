gennyParser = null # Defer until used
mscParser   = null # Defer until used
xuParser    = null # Defer until used
mscRender   = null # Defer until used

exports.render = (text='', elementId, grammar, callback) ->
  # TODO: get dependencies from npm
  mscRender ?= require './mscgen_js/render/graphics/renderast'
  
  parse text, grammar, (pError, pAST) ->
    return callback(pError) if pError?
    
    mscRender.clean elementId, window
    mscRender.renderAST pAST, text, elementId, window

determineParser = (pGrammar) ->
  # TODO: get dependencies from npm
  if pGrammar.scopeName == 'source.msgenny'
    gennyParser ?= require './mscgen_js/parse/msgennyparser_node'
    return gennyParser
  if pGrammar.scopeName == 'source.mscgen'
    mscParser ?= require './mscgen_js/parse/mscgenparser_node'
    return mscParser
  else # probably source.xu, but if not the safest option because it also covers mscgen
    xuParser ?= require './mscgen_js/parse/xuparser_node'
    return xuParser

parse = (text, grammar, callback) ->
  try
    callback(null, determineParser(grammar).parse(text))
  catch error
    # HACK
    error.sourceMsc = text
    # TODO: Atom native error handling
    return callback(error)
