/* jshint nonstandard:true */
/* jshint node: true */

/* istanbul ignore else */
if ( typeof define !== 'function') {
    var define = require('amdefine')(module);
}

define([], function() {
    "use strict";

    function formatNumber(pNumber, pMaxWidth) {
        var lRetval = pNumber.toString();
        var lPosLeft = pMaxWidth - lRetval.length;
        for (var i = 0; i < lPosLeft; i++) {
            lRetval = " " + lRetval;
        }
        return lRetval;
    }

    function formatLine(pLine, pLineNo, pCol){
        var lRetval = formatNumber(pLineNo, 3) + " ";
        if (undefined !== pCol){
            lRetval += "<mark>" + underlineCol(pLine, pCol) + "</mark>";
        } else {
            lRetval += deHTMLize(pLine);
        }
        return lRetval;
    }

    function underlineCol(pLine, pCol){
        return pLine.split("").reduce(function(pPrev, pChar, pIndex){
            if (pIndex === pCol) {
                return pPrev + "<span style='text-decoration:underline'>" + deHTMLize(pChar) + "</span>";
            }
            return pPrev + deHTMLize(pChar);
        }, "");
    }

    /**
     * returns a 'sanitized' version of the passed
     * string. Sanitization is <em>very barebones</em> at the moment
     * - it replaces < by &lt; so the browser won't start interpreting it
     * as html. I'd rather use something standard for this, but haven't
     * found it yet... <span class='inline-block highlight-error'>Error</span>
     */
    function deHTMLize(pString){
        return pString.replace(/</g, "&lt;");
    }

    return {
        renderError: function renderError(pSource, pErrorLocation, pMessage){
            var lErrorIntro = !!pErrorLocation ?
                "<div class='error-wrap'><div class='block icon icon-flame highlight-error'>error on line " + pErrorLocation.start.line + ", column " + pErrorLocation.start.column + " - " + pMessage + "</div><pre class='code'>" :
                "<div class='error-wrap'><div class='block icon icon-alert highlight-error'>" + pMessage + "</div><pre class='code'>";

            pSource = !!pSource ? pSource: "";

            return pSource.split('\n').reduce(function(pPrev, pLine, pIndex) {
                if (!!pErrorLocation && pIndex === (pErrorLocation.start.line - 1)) {
                    return pPrev + formatLine(pLine, pIndex + 1, pErrorLocation.start.column - 1) + '\n';
                }
                return pPrev + formatLine(pLine, pIndex + 1) + '\n';
            }, lErrorIntro) + "</pre></div>";
        }
    };
});
/*
 This file is part of mscgen-preview

 mscgen-preview is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 mscgen-preview is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with mscgen-preview.  If not, see <http://www.gnu.org/licenses/>.
 */
