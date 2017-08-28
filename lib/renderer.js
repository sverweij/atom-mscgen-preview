"use babel";

let mscgenjs = null;

const scopeName2inputType = {
    'source.msgenny': 'msgenny',
    'source.mscgen': 'mscgen',
    'source.xu': 'xu',
    'source.json': 'json'
};

exports.scopeName2inputType = scopeName2inputType;

exports.render = function(pScript = "", pElementId, pGrammar, pCallback) {
    if (mscgenjs === null) {
        mscgenjs = require('mscgenjs');
    }
    const lOptions = {
        elementId: pElementId,
        inputType: scopeName2inputType[pGrammar.scopeName] || 'xu',
        mirrorEntitiesOnBottom: atom.config.get('mscgen-preview.mirrorEntities'),
        additionalTemplate: atom.config.get('mscgen-preview.cannedStyleTemplate'),
        regularArcTextVerticalAlignment: atom.config.get('mscgen-preview.regularArcTextVerticalAlignment')
    };
    return mscgenjs.renderMsc(pScript, lOptions, pCallback);
};

exports.translate = function(pScript = "", pScopeFrom, pScopeTo, pCallback) {
    if (mscgenjs === null) {
        mscgenjs = require('mscgenjs/index-lazy');
    }
    const lOptions = {
        inputType: scopeName2inputType[pScopeFrom] || 'msgenny',
        outputType: scopeName2inputType[pScopeTo] || 'xu'
    };
    return mscgenjs.translateMsc(pScript, lOptions, pCallback);
};

/* global atom */
