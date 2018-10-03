const expectLegalHashComment = tokens => {
    expect(tokens[0]).toEqual({
        value: "#",
        scopes: ["source.xu", "comment.line.number-sign.xu", "punctuation.definition.comment.xu"]
    });
    expect(tokens[1].scopes).toEqual(["source.xu", "comment.line.number-sign.xu"]);
};

const expectLegalSlashComment = tokens => {
    expect(tokens[0]).toEqual({
        value: "//",
        scopes: ["source.xu", "comment.line.double-slash.xu", "punctuation.definition.comment.xu"]
    });
    expect(tokens[1].scopes).toEqual(["source.xu", "comment.line.double-slash.xu"]);
};

describe("Xù grammar", () => {
    let grammar = null;
    beforeEach(() => {
        waitsForPromise(() => atom.packages.activatePackage("mscgen-preview"));
        runs(() => grammar = atom.grammars.grammarForScopeName("source.xu"));
    });
    it("parses the grammar", () => {
        expect(grammar).toBeTruthy();
        expect(grammar.scopeName).toBe("source.xu");
    });
    describe("A simple, complete (but invalid) Xù script", () => {
        let lines = null;
        beforeEach(() => lines = grammar.tokenizeLines("# Smoke test\nmsc {\n/* options */\n  wordwraparcs=on, watermark=\"nice watermark\";\n\n# some entities\n  \"a\" [label=/* comment in a weird place */\"Entity A /* comment in a string*/ hscale\"],\n  label [label=abox];\n=\n// arcs\n  \"a\" =>> label [label=\"do something\"];\n  label >> \"a\" [label=\"done!\", linecolor=\"gray\"];\n\n  \"a\" => \"a\" [label=\"happiness & stuff\"],\n  label note label [label=\"Not sure what perspired there.\\n(perspired -> I mean happened)\"];\n  \"a\" abox label [label=\"angled box here\"];\n  a alt label [label=\"all is good\"] {\n    label >> a [label=\"Oh yeah!\"];\n    ---;\n    label >> a [label=\"Nope\", textcolour=\"red\"];\n  };\n}"));
        it("recognizes comments", () => {
            expectLegalHashComment(lines[5]);
            return expectLegalSlashComment(lines[9]);
        });
        it("recognizes the start token", () => {
            expect(lines[1][0]).toEqual({
                value: "msc ",
                scopes: ["source.xu", "storage.type.xu"]
            });
            return expect(lines[1][1]).toEqual({
                value: "{",
                scopes: ["source.xu", "storage.type.xu", "punctuation.definition.program.end.xu"]
            });
        });
        it("recognizes option keywords", () => expect(lines[3][1]).toEqual({
            value: "wordwraparcs",
            scopes: ["source.xu", "storage.modifier.xu"]
        }));
        it("recognizes option assignments", () => expect(lines[3][2]).toEqual({
            value: "=",
            scopes: ["source.xu", "storage.type.xu"]
        }));
        it("recognizes option constants", () => expect(lines[3][3]).toEqual({
            value: "on",
            scopes: ["source.xu", "constant.language.xu"]
        }));
        it("recognizes xu specific option keywords", () => expect(lines[3][6]).toEqual({
            value: "watermark",
            scopes: ["source.xu", "storage.modifier.xu"]
        }));
        describe("outside attribute blocks", () => {
            it("classifies attribute-like tokens as variables", () => expect(lines[7][1]).toEqual({
                value: "label",
                scopes: ["source.xu", "variable.identifier.xu"]
            }));
            it("classifies equals signs as illegal", () => expect(lines[8][0]).toEqual({
                value: "=",
                scopes: ["source.xu", "invalid.illegal.xu"]
            }));
            it("classifies identifier-like tokens (arc type here) as arc type", () => expect(lines[15][5]).toEqual({
                value: "abox",
                scopes: ["source.xu", "storage.type.xu"]
            }));
            it("classifies xu specific arc types as arc type", () => expect(lines[16][3]).toEqual({
                value: "alt",
                scopes: ["source.xu", "storage.type.xu"]
            }));
        });
        describe("within attribute blocks", () => {
            it("classifies attribute-like tokens as attributes", () => expect(lines[7][4]).toEqual({
                value: "label",
                scopes: ["source.xu", "keyword.operator.xu", "keyword.attribute.xu"]
            }));
            it("classifies equal signs as operator", () => expect(lines[7][5]).toEqual({
                value: "=",
                scopes: ["source.xu", "keyword.operator.xu", "storage.type.xu"]
            }));
            it("classifies identifier-like tokens (even when it's an arc type token) as strings", () =>
                expect(lines[7][6]).toEqual({
                    value: "abox",
                    scopes: ["source.xu", "keyword.operator.xu", "string.identifier.as.attribute.value.xu"]
                })
            );
            /* eslint max-nested-callbacks:0 */
            describe("within strings", () => {
                it("leaves comments and keywords as is", () => expect(lines[6][12]).toEqual({
                    value: "Entity A /* comment in a string*/ hscale",
                    scopes: ["source.xu", "keyword.operator.xu", "string.quoted.double.xu"]
                }));
                it("recognizes escaped characters", () => expect(lines[14][12]).toEqual({
                    value: "\\n",
                    scopes: [
                        "source.xu",
                        "keyword.operator.xu",
                        "string.quoted.double.xu",
                        "constant.character.escape.xu"
                    ]
                }));
            });
        });
    });
    describe("Outside msc {} scope", () => {
        it("treats single line hashmark comments as comments", () => {
            const tokens = grammar.tokenizeLine("# legal").tokens;
            expectLegalHashComment(tokens);
        });
        it("treats single line double slash comments as comments", () => {
            const tokens = grammar.tokenizeLine("// also legal").tokens;
            expectLegalSlashComment(tokens);
        });
        it("treats multi line comments as comments", () => {
            const lines = grammar.tokenizeLines(
                "/* multi line comments\n   outside msc blocks are super legal as wel\n */"
            );
            expect(lines[0][0]).toEqual({
                value: "/*",
                scopes: ["source.xu", "comment.block.xu", "punctuation.definition.comment.xu"]
            });
            expect(lines[0][1]).toEqual({
                value: " multi line comments",
                scopes: ["source.xu", "comment.block.xu"]
            });
            expect(lines[1][0]).toEqual({
                value: "   outside msc blocks are super legal as wel",
                scopes: ["source.xu", "comment.block.xu"]
            });
            expect(lines[2][0]).toEqual({
                value: " ",
                scopes: ["source.xu", "comment.block.xu"]
            });
            expect(lines[2][1]).toEqual({
                value: "*/",
                scopes: ["source.xu", "comment.block.xu", "punctuation.definition.comment.xu"]
            });
        });
        it("leaves spaces alone", () => {
            const tokens = grammar.tokenizeLine("            ").tokens;
            expect(tokens[0]).toEqual({
                value: "            ",
                scopes: ["source.xu"]
            });
        });
        it("declares everything else illegal", () => {
            const tokens = grammar.tokenizeLine("= not legal").tokens;
            expect(tokens[0]).toEqual({
                value: "=",
                scopes: ["source.xu", "invalid.illegal.xu"]
            });
        });
        it("declares stuff illegal that would be legal within msc {} scope", () => {
            const tokens = grammar.tokenizeLine("illegal box illegal;").tokens;
            expect(tokens[0]).toEqual({
                value: "i",
                scopes: ["source.xu", "invalid.illegal.xu"]
            });
        });
    });
});

/* global atom, waitsForPromise */
