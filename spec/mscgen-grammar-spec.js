"use babel";

const expectLegalHashComment = tokens => {
    expect(tokens[0]).toEqual({
        value: "#",
        scopes: ["source.mscgen", "comment.line.number-sign.mscgen", "punctuation.definition.comment.mscgen"]
    });
    expect(tokens[1].scopes).toEqual(["source.mscgen", "comment.line.number-sign.mscgen"]);
};

const expectLegalSlashComment = tokens => {
    expect(tokens[0]).toEqual({
        value: "//",
        scopes: ["source.mscgen", "comment.line.double-slash.mscgen", "punctuation.definition.comment.mscgen"]
    });
    expect(tokens[1].scopes).toEqual(["source.mscgen", "comment.line.double-slash.mscgen"]);
};

describe("MscGen grammar", () => {
    let grammar = null;
    beforeEach(() => {
        waitsForPromise(() => atom.packages.activatePackage("mscgen-preview"));
        runs(() => grammar = atom.grammars.grammarForScopeName("source.mscgen"));
    });
    it("parses the grammar", () => {
        expect(grammar).toBeTruthy();
        expect(grammar.scopeName).toBe("source.mscgen");
    });
    describe("A simple, complete (but invalid) MscGen script", () => {
        let lines = null;
        beforeEach(() => lines =
            grammar.tokenizeLines("# Smoke test\nmsc {\n/* options */\n  wordwraparcs=on;\n\n# some entities\n  \"a\" [label=/* comment in a weird place */\"Entity A /* comment in a string*/ hscale\"],\n  label [label=abox];\n=\n// arcs\n  \"a\" =>> label [label=\"do something\"];\n  label >> \"a\" [label=\"done!\", linecolor=\"gray\"];\n\n  \"a\" => \"a\" [label=\"happiness & stuff\"],\n  label note label [label=\"Not sure what perspired there.\\n(perspired -> I mean happened)\"];\n  \"a\" abox label [label=\"angled box here\"];\n}"));
        it("recognizes comments", () => {
            expectLegalHashComment(lines[5]);
            expectLegalSlashComment(lines[9]);
        });
        it("recognizes the start token", () => {
            expect(lines[1][0]).toEqual({
                value: "msc ",
                scopes: ["source.mscgen", "storage.type.mscgen"]
            });
            expect(lines[1][1]).toEqual({
                value: "{",
                scopes: ["source.mscgen", "storage.type.mscgen", "punctuation.definition.program.end.mscgen"]
            });
        });
        it("recognizes option keywords", () => expect(lines[3][1]).toEqual({
            value: "wordwraparcs",
            scopes: ["source.mscgen", "storage.modifier.mscgen"]
        }));
        it("recognizes option assignments", () => expect(lines[3][2]).toEqual({
            value: "=",
            scopes: ["source.mscgen", "storage.type.mscgen"]
        }));
        it("recognizes option constants", () => expect(lines[3][3]).toEqual({
            value: "on",
            scopes: ["source.mscgen", "constant.language.mscgen"]
        }));
        describe("outside attribute blocks", () => {
            it("classifies attribute-like tokens as variables", () => expect(lines[7][1]).toEqual({
                value: "label",
                scopes: ["source.mscgen", "variable.identifier.mscgen"]
            }));
            it("classifies equals signs as illegal", () => expect(lines[8][0]).toEqual({
                value: "=",
                scopes: ["source.mscgen", "invalid.illegal.mscgen"]
            }));
            it("classifies identifier-like tokens (arc type here) as arc type", () => expect(lines[15][5]).toEqual({
                value: "abox",
                scopes: ["source.mscgen", "storage.type.mscgen"]
            }));
        });
        describe("within attribute blocks", () => {
            it("classifies attribute-like tokens as attributes", () => expect(lines[7][4]).toEqual({
                value: "label",
                scopes: ["source.mscgen", "keyword.operator.mscgen", "keyword.attribute.mscgen"]
            }));
            it("classifies equal signs as operator", () => expect(lines[7][5]).toEqual({
                value: "=",
                scopes: ["source.mscgen", "keyword.operator.mscgen", "storage.type.mscgen"]
            }));
            it("classifies identifier-like tokens (even when it's an arc type token) as strings", () =>
                expect(lines[7][6]).toEqual({
                    value: "abox",
                    scopes: ["source.mscgen", "keyword.operator.mscgen", "string.identifier.as.attribute.value.mscgen"]
                })
            );
            /* eslint max-nested-callbacks:0 */
            describe("within strings", () => {
                it("leaves comments and keywords as is", () => expect(lines[6][12]).toEqual({
                    value: "Entity A /* comment in a string*/ hscale",
                    scopes: ["source.mscgen", "keyword.operator.mscgen", "string.quoted.double.mscgen"]
                }));
                it("recognizes escaped characters", () => expect(lines[14][12]).toEqual({
                    value: "\\n",
                    scopes: [
                        "source.mscgen",
                        "keyword.operator.mscgen",
                        "string.quoted.double.mscgen",
                        "constant.character.escape.mscgen"
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
                scopes: ["source.mscgen", "comment.block.mscgen", "punctuation.definition.comment.mscgen"]
            });
            expect(lines[0][1]).toEqual({
                value: " multi line comments",
                scopes: ["source.mscgen", "comment.block.mscgen"]
            });
            expect(lines[1][0]).toEqual({
                value: "   outside msc blocks are super legal as wel",
                scopes: ["source.mscgen", "comment.block.mscgen"]
            });
            expect(lines[2][0]).toEqual({
                value: " ",
                scopes: ["source.mscgen", "comment.block.mscgen"]
            });
            expect(lines[2][1]).toEqual({
                value: "*/",
                scopes: ["source.mscgen", "comment.block.mscgen", "punctuation.definition.comment.mscgen"]
            });
        });
        it("leaves spaces alone", () => {
            const tokens = grammar.tokenizeLine("            ").tokens;
            expect(tokens[0]).toEqual({
                value: "            ",
                scopes: ["source.mscgen"]
            });
        });
        it("declares everything else illegal", () => {
            const tokens = grammar.tokenizeLine("= not legal").tokens;
            expect(tokens[0]).toEqual({
                value: "=",
                scopes: ["source.mscgen", "invalid.illegal.mscgen"]
            });
        });
        it("declares stuff illegal that would be legal within msc {} scope", () => {
            const tokens = grammar.tokenizeLine("illegal box illegal;").tokens;
            expect(tokens[0]).toEqual({
                value: "i",
                scopes: ["source.mscgen", "invalid.illegal.mscgen"]
            });
        });
    });
});

/* global atom, waitsForPromise */
