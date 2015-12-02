mscgenjs    = null # Defer until used
gennyParser = null # Defer until used
mscParser   = null # Defer until used
xuParser    = null # Defer until used
mscRender   = null # Defer until used

exports.render = (text='', elementId, grammar, callback) ->
  # TODO: get dependencies from npm
  mscgenjs ?= require './mscgen_js'
  mscRender ?= mscgenjs.getGraphicsRenderer()

  parse text, grammar, (pError, pAST) ->
    return callback(pError) if pError?

    mscRender.clean elementId, window
    mscRender.renderAST pAST, text, elementId, window
    return callback(null, document.getElementById(elementId).innerHTML)

determineParser = (pGrammar) ->
  # TODO: get dependencies from npm
  mscgenjs ?= require './mscgen_js'
  if pGrammar.scopeName == 'source.msgenny'
    gennyParser ?= mscgenjs.getParser 'msgenny'
    return gennyParser
  if pGrammar.scopeName == 'source.mscgen'
    mscParser ?= mscgenjs.getParser 'mscgen'
    return mscParser
  else # probably source.xu, but if not, the xu parser is the
       # safest option because it also covers mscgen
    xuParser ?= mscgenjs.getParser 'xu'
    return xuParser

parse = (text, grammar, callback) ->
  try
    callback(null, determineParser(grammar).parse(text))
  catch error
    # HACK
    error.sourceMsc = text
    # TODO: Atom native error handling
    return callback(error)
