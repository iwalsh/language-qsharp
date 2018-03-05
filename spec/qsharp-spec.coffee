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
