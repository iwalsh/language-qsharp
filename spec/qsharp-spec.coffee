describe "Q# grammar", ->
  grammar = null

  beforeEach ->
    waitsForPromise ->
      atom.packages.activatePackage("language-qsharp")

    runs ->
      grammar = atom.grammars.grammarForScopeName("source.qsharp")

  it "parses the grammar", ->
    expect(grammar).toBeDefined()
    expect(grammar.scopeName).toBe "source.qsharp"

  describe "double-slash comments", ->
    it "tokenizes the punctation and content", ->
      {tokens} = grammar.tokenizeLine "// Comment!"

      expect(tokens.length).toBe 2
      expect(tokens[0].value).toBe "//"
      expect(tokens[0].scopes).toEqual ["source.qsharp", "comment.line.double-slash.qsharp", "punctuation.definition.comment.qsharp"]
      expect(tokens[1].value).toBe " Comment!"
      expect(tokens[1].scopes).toEqual ["source.qsharp", "comment.line.double-slash.qsharp"]

    it "tokenizes whitespace at the start of the line", ->
      {tokens} = grammar.tokenizeLine "   // Comment!"

      expect(tokens.length).toBe 3
      expect(tokens[0].value).toBe "   "
      expect(tokens[0].scopes).toEqual ["source.qsharp", "punctuation.whitespace.comment.leading.qsharp"]

    it "does not include leading content in the comment", ->
      {tokens} = grammar.tokenizeLine "Not a comment // Comment!"

      expect(tokens.length).toBe 3
      expect(tokens[0].value).toBe "Not a comment "
      expect(tokens[0].scopes).toEqual ["source.qsharp"]
      expect(tokens[1].value).toBe "//"
      expect(tokens[2].value).toBe " Comment!"

    it "does not include subsequent lines in the comment", ->
      tokens = grammar.tokenizeLines "// Comment!\nNot a comment"

      # Line 0
      expect(tokens[0][0].value).toBe "//"
      expect(tokens[0][1].value).toBe " Comment!"
      # Line 1
      expect(tokens[1][0].value).toBe "Not a comment"
      expect(tokens[1][0].scopes).toEqual ["source.qsharp"]

    it "ignores extra slashes in the comment body", ->
      {tokens} = grammar.tokenizeLine "// Comment! // The same comment"
      expect(tokens.length).toBe 2
      expect(tokens[0].value).toBe "//"
      expect(tokens[1].value).toBe " Comment! // The same comment"
      expect(tokens[1].scopes).toEqual ["source.qsharp", "comment.line.double-slash.qsharp"]

  describe "documentation comments", ->
    it "tokenizes the punctuation and content", ->
      {tokens} = grammar.tokenizeLine "/// This comment is formatted as Markdown"

      expect(tokens.length).toBe 2
      expect(tokens[0].value).toBe "///"
      expect(tokens[0].scopes).toEqual ["source.qsharp", "comment.block.documentation.qsharp", "punctuation.definition.comment.qsharp"]
      expect(tokens[1].value).toBe " This comment is formatted as Markdown"
      expect(tokens[1].scopes).toEqual ["source.qsharp", "comment.block.documentation.qsharp"]

    it "tokenizes whitespace at the start of the line", ->
      {tokens} = grammar.tokenizeLine "   /// Comment!"

      expect(tokens.length).toBe 3
      expect(tokens[0].value).toBe "   "
      expect(tokens[0].scopes).toEqual ["source.qsharp", "punctuation.whitespace.comment.leading.qsharp"]

    it "does not include leading content in the comment", ->
      {tokens} = grammar.tokenizeLine "Not a comment /// Comment!"

      expect(tokens.length).toBe 3
      expect(tokens[0].value).toBe "Not a comment "
      expect(tokens[0].scopes).toEqual ["source.qsharp"]
      expect(tokens[1].value).toBe "///"
      expect(tokens[2].value).toBe " Comment!"

    it "does not include subsequent lines in the comment", ->
      tokens = grammar.tokenizeLines "/// Comment!\nNot a comment"

      # Line 0
      expect(tokens[0][0].value).toBe "///"
      expect(tokens[0][1].value).toBe " Comment!"
      # Line 1
      expect(tokens[1][0].value).toBe "Not a comment"
      expect(tokens[1][0].scopes).toEqual ["source.qsharp"]

    it "ignores extra slashes in the comment body", ->
      {tokens} = grammar.tokenizeLine "/// Comment! // The same comment"

      expect(tokens.length).toBe 2
      expect(tokens[0].value).toBe "///"
      expect(tokens[1].value).toBe " Comment! // The same comment"
      expect(tokens[1].scopes).toEqual ["source.qsharp", "comment.block.documentation.qsharp"]

    it "tokenizes Markdown headers", ->
      {tokens} = grammar.tokenizeLine "/// # Summary "

      expect(tokens.length).toBe 6
      expect(tokens[0].value).toBe "///"
      expect(tokens[2].value).toBe "#"
      expect(tokens[2].scopes).toEqual ["source.qsharp", "comment.block.documentation.qsharp", "markup.heading.1.md.qsharp", "punctuation.definition.comment-header.qsharp"]
      expect(tokens[4].value).toBe "Summary"
      expect(tokens[4].scopes).toEqual ["source.qsharp", "comment.block.documentation.qsharp", "markup.heading.1.md.qsharp"]

    it "tokenizes cross-references", ->
      {tokens} = grammar.tokenizeLine "/// Check out @\"MyFile\""

      expect(tokens.length).toBe 5
      expect(tokens[0].value).toBe "///"
      expect(tokens[2].value).toBe "@\""
      expect(tokens[2].scopes).toEqual ["source.qsharp", "comment.block.documentation.qsharp", "markup.underline.link.qsharp", "punctuation.definition.cross-reference.begin.qsharp"]
      expect(tokens[3].value).toBe "MyFile"
      expect(tokens[3].scopes).toEqual ["source.qsharp", "comment.block.documentation.qsharp", "markup.underline.link.qsharp"]
      expect(tokens[4].value).toBe "\""
      expect(tokens[4].scopes).toEqual ["source.qsharp", "comment.block.documentation.qsharp", "markup.underline.link.qsharp", "punctuation.definition.cross-reference.end.qsharp"]

    it "ignores pound signs in the comment body", ->
      {tokens} = grammar.tokenizeLine "/// My favorite language is Q#"

      expect(tokens.length).toBe 2
      expect(tokens[0].value).toBe "///"
      expect(tokens[1].value).toBe " My favorite language is Q#"

    it "does not tokenize Markdown headers other than `#`", ->
      {tokens} = grammar.tokenizeLine "/// ## Level 2 header"

      expect(tokens.length).toBe 2
      expect(tokens[0].value).toBe "///"
      expect(tokens[1].value).toBe " ## Level 2 header"

  describe "interpolated strings", ->
    it "tokenizes the punctuation and content", ->
      {tokens} = grammar.tokenizeLine "fail $\"Syndrome {syn} is incorrect\";"

      expect(tokens.length).toBe 10
      expect(tokens[2].value).toBe "$\""
      expect(tokens[2].scopes).toEqual ["source.qsharp", "string.quoted.double.qsharp", "punctuation.definition.string.begin.qsharp"]
      expect(tokens[4].value).toBe "{"
      expect(tokens[4].scopes).toEqual ["source.qsharp", "string.quoted.double.qsharp", "meta.interpolation.qsharp", "punctuation.definition.interpolation.begin.qsharp"]
      expect(tokens[5].value).toBe "syn"
      expect(tokens[5].scopes).toEqual ["source.qsharp", "string.quoted.double.qsharp", "meta.interpolation.qsharp"]
      expect(tokens[6].value).toBe "}"
      expect(tokens[6].scopes).toEqual ["source.qsharp", "string.quoted.double.qsharp", "meta.interpolation.qsharp", "punctuation.definition.interpolation.end.qsharp"]

  describe "`return` statement", ->
    it "tokenizes the keyword", ->
      {tokens} = grammar.tokenizeLine "return ();"

      expect(tokens.length).toBe 3
      expect(tokens[0].value).toBe "return"
      expect(tokens[0].scopes).toEqual ["source.qsharp", "keyword.control.flow.return.qsharp"]

  describe "`if` statement", ->
    it "tokenizes the keyword and punctuation", ->
      {tokens} = grammar.tokenizeLine "if (i == 1) { X(target); }"

      expect(tokens.length).toBe(10)
      expect(tokens[0].value).toBe "if"
      expect(tokens[0].scopes).toEqual ["source.qsharp", "keyword.control.conditional.if.qsharp"]
      expect(tokens[2].value).toBe "("
      expect(tokens[2].scopes).toEqual ["source.qsharp", "punctuation.parenthesis.open.qsharp"]
      expect(tokens[8].value).toBe ")"
      expect(tokens[8].scopes).toEqual ["source.qsharp", "punctuation.parenthesis.close.qsharp"]

    it "tokenizes `elif` branches", ->
      {tokens} = grammar.tokenizeLine "elif (i == 2) { Y(target); }"

      expect(tokens.length).toBe(10)
      expect(tokens[0].value).toBe "elif"
      expect(tokens[0].scopes).toEqual ["source.qsharp", "keyword.control.conditional.elif.qsharp"]
      expect(tokens[2].value).toBe "("
      expect(tokens[2].scopes).toEqual ["source.qsharp", "punctuation.parenthesis.open.qsharp"]
      expect(tokens[8].value).toBe ")"
      expect(tokens[8].scopes).toEqual ["source.qsharp", "punctuation.parenthesis.close.qsharp"]

    it "tokenizes `else` branches", ->
      {tokens} = grammar.tokenizeLine "else { Z(target); }"

      expect(tokens.length).toBe 2
      expect(tokens[0].value).toBe "else"
      expect(tokens[0].scopes).toEqual ["source.qsharp", "keyword.control.conditional.else.qsharp"]

    # FIXME
    # it "does not match bodies without curly braces", ->
    #   {tokens} = grammar.tokenizeLine "if (i == 1) X(target);"
    #
    #   expect(tokens[0].value).not.toBe "if"

  describe "`for` statement", ->
    it "tokenizes the keywords and punctuation", ->
      {tokens} = grammar.tokenizeLine "for (i in 0 .. 5) { set sum = sum + 1; }"

      expect(tokens.length).toBe 10
      expect(tokens[0].value).toBe "for"
      expect(tokens[0].scopes).toEqual ["source.qsharp", "keyword.control.loop.for.qsharp"]
      expect(tokens[2].value).toBe "("
      expect(tokens[2].scopes).toEqual ["source.qsharp", "punctuation.parenthesis.open.qsharp"]
      expect(tokens[3].value).toBe "i"
      expect(tokens[3].scopes).toEqual ["source.qsharp", "entity.name.variable.local.qsharp"]
      expect(tokens[5].value).toBe "in"
      expect(tokens[5].scopes).toEqual ["source.qsharp", "keyword.control.loop.in.qsharp"]
      expect(tokens[8].value).toBe ")"
      expect(tokens[8].scopes).toEqual ["source.qsharp", "punctuation.parenthesis.close.qsharp"]

  describe "`repeat` statement", ->
    it "tokenizes the keyword", ->
      # TODO: need a more complete example?
      {tokens} = grammar.tokenizeLine "repeat { set sum = sum + 1; }"

      expect(tokens[0].value).toBe "repeat"
      expect(tokens[0].scopes).toEqual ["source.qsharp", "keyword.control.loop.repeat.qsharp"]

  describe "`until` statement", ->
    it "tokenizes the keywords", ->
      {tokens} = grammar.tokenizeLine "} until result == Zero fixup { (); }"

      expect(tokens.length).toBe 7
      expect(tokens[1].value).toBe "until"
      expect(tokens[1].scopes).toEqual ["source.qsharp", "keyword.control.loop.until.qsharp"]
      expect(tokens[4].value).toBe "fixup"
      expect(tokens[4].scopes).toEqual ["source.qsharp", "keyword.control.loop.fixup.qsharp"]

  describe "`fail` statement", ->
    it "tokenizes the keyword", ->
      {tokens} = grammar.tokenizeLine "fail \"It crashed!\"";

      expect(tokens.length).toBe 5
      expect(tokens[0].value).toBe "fail"
      expect(tokens[0].scopes).toEqual ["source.qsharp", "keyword.control.flow.fail.qsharp"]

    it "tokenizes the string", ->
      {tokens} = grammar.tokenizeLine "fail \"Error\";";

      expect(tokens.length).toBe 6
      expect(tokens[2].value).toBe "\""
      expect(tokens[2].scopes).toEqual ["source.qsharp", "string.quoted.double.qsharp", "punctuation.definition.string.begin.qsharp"]
      expect(tokens[3].value).toBe "Error"
      expect(tokens[3].scopes).toEqual ["source.qsharp", "string.quoted.double.qsharp"]
      expect(tokens[4].value).toBe "\""
      expect(tokens[4].scopes).toEqual ["source.qsharp", "string.quoted.double.qsharp", "punctuation.definition.string.end.qsharp"]

  describe "storage modifiers", ->
    it "tokenizes the `let` keyword", ->
      {tokens} = grammar.tokenizeLine "let (a, (b, c)) = (1, (2, 3));"

      expect(tokens.length).toBe 2
      expect(tokens[0].value).toBe "let"
      expect(tokens[0].scopes).toEqual ["source.qsharp", "storage.modifiers.let.qsharp"]

    it "tokenizes the `mutable` keyword", ->
      {tokens} = grammar.tokenizeLine "mutable counter = 0;"

      expect(tokens.length).toBe 2
      expect(tokens[0].value).toBe "mutable"
      expect(tokens[0].scopes).toEqual ["source.qsharp", "storage.modifiers.mutable.qsharp"]

    it "tokenizes the `set` keyword", ->
      {tokens} = grammar.tokenizeLine "set counter = counter + 1;"

      expect(tokens.length).toBe 2
      expect(tokens[0].value).toBe "set"
      expect(tokens[0].scopes).toEqual ["source.qsharp", "storage.modifiers.set.qsharp"]

    it "tokenizes the `new` keyword", ->
      {tokens} = grammar.tokenizeLine "mutable ary = new Int[i+1];"

      expect(tokens.length).toBe 4
      expect(tokens[2].value).toBe "new"
      expect(tokens[2].scopes).toEqual ["source.qsharp", "storage.modifiers.new.qsharp"]

  describe "literals", ->
    it "tokenizes boolean `true`", ->
      {tokens} = grammar.tokenizeLine "mutable condition = true;"

      expect(tokens.length).toBe 4
      expect(tokens[2].value).toBe "true"
      expect(tokens[2].scopes).toEqual ["source.qsharp", "constant.language.boolean.true.qsharp"]

    it "tokenizes boolean `false`", ->
      {tokens} = grammar.tokenizeLine "mutable condition = false;"

      expect(tokens.length).toBe 4
      expect(tokens[2].value).toBe "false"
      expect(tokens[2].scopes).toEqual ["source.qsharp", "constant.language.boolean.false.qsharp"]

    it "tokenizes string punctuation", ->
      {tokens} = grammar.tokenizeLine "\"Hello world!\""

      expect(tokens.length).toBe 3
      expect(tokens[0].value).toBe "\""
      expect(tokens[0].scopes).toEqual ["source.qsharp", "string.quoted.double.qsharp", "punctuation.definition.string.begin.qsharp"]
      expect(tokens[2].value).toBe "\""
      expect(tokens[2].scopes).toEqual ["source.qsharp", "string.quoted.double.qsharp", "punctuation.definition.string.end.qsharp"]

    it "tokenizes escaped characters in strings", ->
      {tokens} = grammar.tokenizeLine "\"Hello \\t world!\""

      expect(tokens.length).toBe 5
      expect(tokens[2].value).toBe "\\t"
      expect(tokens[2].scopes).toEqual ["source.qsharp", "string.quoted.double.qsharp", "constant.character.escape.qsharp"]

    it "tokenizes illegal newlines in strings", ->
      {tokens} = grammar.tokenizeLine "\"Hello \n world!\""

      expect(tokens.length).toBe 5
      expect(tokens[2].value).toBe " "
      expect(tokens[2].scopes).toEqual ["source.qsharp", "string.quoted.double.qsharp", "invalid.illegal.newline.qsharp"]
