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
      values = (token.value for token in tokens)

      expect(values).toEqual ["//", " Comment!"]
      expect(tokens[0].scopes).toEqual ["source.qsharp", "comment.line.double-slash.qsharp", "punctuation.definition.comment.qsharp"]
      expect(tokens[1].scopes).toEqual ["source.qsharp", "comment.line.double-slash.qsharp"]

    it "tokenizes whitespace at the start of the line", ->
      {tokens} = grammar.tokenizeLine "   // Comment!"
      values = (token.value for token in tokens)

      expect(values).toEqual ["   ", "//", " Comment!"]
      expect(tokens[0].scopes).toEqual ["source.qsharp", "punctuation.whitespace.comment.leading.qsharp"]

    it "does not include leading content in the comment", ->
      {tokens} = grammar.tokenizeLine "Not a comment // Comment!"
      values = (token.value for token in tokens)

      expect(values).toEqual ["Not a comment ", "//", " Comment!"]
      expect(tokens[0].scopes).toEqual ["source.qsharp"]

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
      values = (token.value for token in tokens)

      expect(values).toEqual ["//", " Comment! // The same comment"]
      expect(tokens[1].scopes).toEqual ["source.qsharp", "comment.line.double-slash.qsharp"]

  describe "documentation comments", ->
    it "tokenizes the punctuation and content", ->
      {tokens} = grammar.tokenizeLine "/// This comment is formatted as Markdown"
      values = (token.value for token in tokens)

      expect(values).toEqual ["///", " This comment is formatted as Markdown"]
      expect(tokens[0].scopes).toEqual ["source.qsharp", "comment.block.documentation.qsharp", "punctuation.definition.comment.qsharp"]
      expect(tokens[1].scopes).toEqual ["source.qsharp", "comment.block.documentation.qsharp"]

    it "tokenizes whitespace at the start of the line", ->
      {tokens} = grammar.tokenizeLine "   /// Comment!"
      values = (token.value for token in tokens)

      expect(values).toEqual ["   ", "///", " Comment!"]
      expect(tokens[0].scopes).toEqual ["source.qsharp", "punctuation.whitespace.comment.leading.qsharp"]

    it "does not include leading content in the comment", ->
      {tokens} = grammar.tokenizeLine "Not a comment /// Comment!"
      values = (token.value for token in tokens)

      expect(values).toEqual ["Not a comment ", "///", " Comment!"]
      expect(tokens[0].scopes).toEqual ["source.qsharp"]

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
      values = (token.value for token in tokens)

      expect(values).toEqual ["///", " Comment! // The same comment"]
      expect(tokens[1].scopes).toEqual ["source.qsharp", "comment.block.documentation.qsharp"]

    it "tokenizes Markdown headers", ->
      {tokens} = grammar.tokenizeLine "/// # Summary "
      values = (token.value for token in tokens)

      expect(values).toEqual ["///", " ", "#", " ", "Summary", " "]
      expect(tokens[2].scopes).toEqual ["source.qsharp", "comment.block.documentation.qsharp", "markup.heading.1.md.qsharp", "punctuation.definition.comment-header.qsharp"]
      expect(tokens[4].scopes).toEqual ["source.qsharp", "comment.block.documentation.qsharp", "markup.heading.1.md.qsharp"]

    it "tokenizes cross-references", ->
      {tokens} = grammar.tokenizeLine "/// Check out @\"MyFile\""
      values = (token.value for token in tokens)

      expect(values).toEqual ["///", " Check out ", "@\"", "MyFile", "\""]
      expect(tokens[2].scopes).toEqual ["source.qsharp", "comment.block.documentation.qsharp", "markup.underline.link.qsharp", "punctuation.definition.cross-reference.begin.qsharp"]
      expect(tokens[3].scopes).toEqual ["source.qsharp", "comment.block.documentation.qsharp", "markup.underline.link.qsharp"]
      expect(tokens[4].scopes).toEqual ["source.qsharp", "comment.block.documentation.qsharp", "markup.underline.link.qsharp", "punctuation.definition.cross-reference.end.qsharp"]

    it "ignores pound signs in the comment body", ->
      {tokens} = grammar.tokenizeLine "/// My favorite language is Q#"
      values = (token.value for token in tokens)

      expect(values).toEqual ["///", " My favorite language is Q#"]

    it "does not tokenize Markdown headers other than `#`", ->
      {tokens} = grammar.tokenizeLine "/// ## Level 2 header"
      values = (token.value for token in tokens)

      expect(values).toEqual ["///", " ## Level 2 header"]

  describe "interpolated strings", ->
    it "tokenizes the punctuation and content", ->
      {tokens} = grammar.tokenizeLine "fail $\"Syndrome {syn} is incorrect\";"
      values = (token.value for token in tokens)

      expect(values).toEqual ["fail", " ", "$\"", "Syndrome ", "{", "syn", "}", " is incorrect", "\"", ";"]
      expect(tokens[2].scopes).toEqual ["source.qsharp", "string.quoted.double.qsharp", "punctuation.definition.string.begin.qsharp"]
      expect(tokens[4].scopes).toEqual ["source.qsharp", "string.quoted.double.qsharp", "meta.interpolation.qsharp", "punctuation.definition.interpolation.begin.qsharp"]
      expect(tokens[5].scopes).toEqual ["source.qsharp", "string.quoted.double.qsharp", "meta.interpolation.qsharp"]
      expect(tokens[6].scopes).toEqual ["source.qsharp", "string.quoted.double.qsharp", "meta.interpolation.qsharp", "punctuation.definition.interpolation.end.qsharp"]

  describe "`return` statement", ->
    it "tokenizes the keyword", ->
      {tokens} = grammar.tokenizeLine "return ();"
      values = (token.value for token in tokens)

      expect(values).toEqual ["return", " ()", ";"]
      expect(tokens[0].scopes).toEqual ["source.qsharp", "keyword.control.flow.return.qsharp"]

  describe "`if` statement", ->
    # FIXME: tokenizing "==" as "=", "="
    it "tokenizes the keyword and punctuation", ->
      {tokens} = grammar.tokenizeLine "if (i == 1) { X(target); }"
      values = (token.value for token in tokens)

      expect(values).toEqual ["if", " ", "(", "i ", "=", "=", " ", "1", ")", " { X", "(", "target", ")", "; }"]
      expect(tokens[0].scopes).toEqual ["source.qsharp", "keyword.control.conditional.if.qsharp"]
      expect(tokens[2].scopes).toEqual ["source.qsharp", "punctuation.parenthesis.open.qsharp"]
      expect(tokens[8].scopes).toEqual ["source.qsharp", "punctuation.parenthesis.close.qsharp"]

    # FIXME: tokenizing "==" as "=", "="
    it "tokenizes `elif` branches", ->
      {tokens} = grammar.tokenizeLine "elif (i == 2) { Y(target); }"
      values = (token.value for token in tokens)

      expect(values).toEqual ["elif", " ", "(", "i ", "=", "=", " ", "2", ")", " { Y", "(", "target", ")", "; }"]
      expect(tokens[0].scopes).toEqual ["source.qsharp", "keyword.control.conditional.elif.qsharp"]
      expect(tokens[2].scopes).toEqual ["source.qsharp", "punctuation.parenthesis.open.qsharp"]
      expect(tokens[8].scopes).toEqual ["source.qsharp", "punctuation.parenthesis.close.qsharp"]

    # FIXME: not tokenizing the block
    it "tokenizes `else` branches", ->
      {tokens} = grammar.tokenizeLine "else { Z(target); }"
      values = (token.value for token in tokens)

      expect(values).toEqual ["else", " { Z(target); }"]
      expect(tokens[0].scopes).toEqual ["source.qsharp", "keyword.control.conditional.else.qsharp"]

    # FIXME
    # it "does not match bodies without curly braces", ->
    #   {tokens} = grammar.tokenizeLine "if (i == 1) X(target);"
    #
    #   expect(tokens[0].value).not.toBe "if"

  describe "`for` statement", ->
    # FIXME: not tokenizing the block
    it "tokenizes the keywords and punctuation", ->
      {tokens} = grammar.tokenizeLine "for (i in 0 .. 5) { set sum = sum + 1; }"
      values = (token.value for token in tokens)

      expect(values).toEqual ["for", " ", "(", "i", " ", "in", " ", "0 .. 5", ")", " { set sum = sum + 1; }"]
      expect(tokens[0].scopes).toEqual ["source.qsharp", "keyword.control.loop.for.qsharp"]
      expect(tokens[2].scopes).toEqual ["source.qsharp", "punctuation.parenthesis.open.qsharp"]
      expect(tokens[3].scopes).toEqual ["source.qsharp", "entity.name.variable.local.qsharp"]
      expect(tokens[5].scopes).toEqual ["source.qsharp", "keyword.control.loop.in.qsharp"]
      expect(tokens[8].scopes).toEqual ["source.qsharp", "punctuation.parenthesis.close.qsharp"]

  describe "`repeat` statement", ->
    # FIXME: Wrong block tokenization
    it "tokenizes the keyword", ->
      # TODO: need a more complete example?
      {tokens} = grammar.tokenizeLine "repeat { set sum = sum + 1; }"
      values = (token.value for token in tokens)

      expect(values).toEqual ["repeat", " { set sum = sum + 1", "; }"]
      expect(tokens[0].scopes).toEqual ["source.qsharp", "keyword.control.loop.repeat.qsharp"]

  describe "`until` statement", ->
    # FIXME: "==" and " Zero " and "result " tokenizations incorrect
    it "tokenizes the keywords", ->
      {tokens} = grammar.tokenizeLine "} until result == Zero fixup { (); }"
      values = (token.value for token in tokens)

      expect(values).toEqual ["} ", "until", " ", "result ", "=", "=", " Zero ", "fixup", " ", "{ (); }"]
      expect(tokens[1].scopes).toEqual ["source.qsharp", "keyword.control.loop.until.qsharp"]
      expect(tokens[7].scopes).toEqual ["source.qsharp", "keyword.control.loop.fixup.qsharp"]

  describe "`fail` statement", ->
    it "tokenizes the keyword", ->
      {tokens} = grammar.tokenizeLine "fail \"It crashed!\"";
      values = (token.value for token in tokens)

      expect(values).toEqual ["fail", " ", "\"", "It crashed!", "\""]
      expect(tokens[0].scopes).toEqual ["source.qsharp", "keyword.control.flow.fail.qsharp"]

    it "tokenizes the string", ->
      {tokens} = grammar.tokenizeLine "fail \"Error\";";
      values = (token.value for token in tokens)

      expect(values).toEqual ["fail", " ", "\"", "Error", "\"", ";"]
      expect(tokens[2].scopes).toEqual ["source.qsharp", "string.quoted.double.qsharp", "punctuation.definition.string.begin.qsharp"]
      expect(tokens[3].scopes).toEqual ["source.qsharp", "string.quoted.double.qsharp"]
      expect(tokens[4].scopes).toEqual ["source.qsharp", "string.quoted.double.qsharp", "punctuation.definition.string.end.qsharp"]

  describe "`let` statment", ->
    it "tokenizes the keyword, variable name, and assignment operator", ->
      {tokens} = grammar.tokenizeLine "let a = 1;"
      values = (token.value for token in tokens)

      expect(values).toEqual [ "let", " ", "a", " ", "=", " ", "1", ";" ]
      expect(tokens[0].scopes).toEqual ["source.qsharp", "storage.modifiers.let.qsharp"]
      expect(tokens[2].scopes).toEqual ["source.qsharp", "entity.name.variable.local.qsharp"]
      expect(tokens[4].scopes).toEqual ["source.qsharp", "keyword.operator.assignment.qsharp"]

  describe "storage modifiers", ->
    # FIXME: tuple tokenization incorrect
    it "tokenizes the `let` keyword", ->
      {tokens} = grammar.tokenizeLine "let (a, (b, c)) = (1, (2, 3));"
      values = (token.value for token in tokens)

      expect(values).toEqual [ "let", " (a, (b, c)) = (", "1", ", (", "2", ", ", "3", "));" ]
      expect(tokens[0].scopes).toEqual ["source.qsharp", "storage.modifiers.let.qsharp"]

    # FIXME: assignment tokenization incorrect
    it "tokenizes the `mutable` keyword", ->
      {tokens} = grammar.tokenizeLine "mutable counter = 0;"
      values = (token.value for token in tokens)

      expect(values).toEqual ["mutable", " counter = ", "0", ";"]
      expect(tokens[0].scopes).toEqual ["source.qsharp", "storage.modifiers.mutable.qsharp"]

    # FIXME: assignment tokenization incorrect
    it "tokenizes the `set` keyword", ->
      {tokens} = grammar.tokenizeLine "set counter = counter + 1;"
      values = (token.value for token in tokens)

      expect(values).toEqual ["set", " counter = counter + ", "1", ";"]
      expect(tokens[0].scopes).toEqual ["source.qsharp", "storage.modifiers.set.qsharp"]

    # FIXME: RHS tokenization very incorrect
    it "tokenizes the `new` keyword", ->
      {tokens} = grammar.tokenizeLine "mutable ary = new Int[i+1];"
      values = (token.value for token in tokens)

      expect(values).toEqual ["mutable", " ary = ", "new", " Int[i+", "1", "];" ]
      expect(tokens[2].scopes).toEqual ["source.qsharp", "storage.modifiers.new.qsharp"]

  describe "literals", ->
    # FIXME: assignent tokenization incorrect
    it "tokenizes boolean `true`", ->
      {tokens} = grammar.tokenizeLine "mutable condition = true;"
      values = (token.value for token in tokens)

      expect(values).toEqual ["mutable", " condition = ", "true", ";"]
      expect(tokens[2].scopes).toEqual ["source.qsharp", "constant.language.boolean.true.qsharp"]

    # FIXME: assignent tokenization incorrect
    it "tokenizes boolean `false`", ->
      {tokens} = grammar.tokenizeLine "mutable condition = false;"
      values = (token.value for token in tokens)

      expect(values).toEqual ["mutable", " condition = ", "false", ";"]
      expect(tokens[2].scopes).toEqual ["source.qsharp", "constant.language.boolean.false.qsharp"]

    # FIXME: assignment tokenization incorrect
    it "tokenizes bare integers", ->
      {tokens} = grammar.tokenizeLine "let five = 5;"
      values = (token.value for token in tokens)

      expect(values).toEqual ["let", " five = ", "5", ";"]
      expect(tokens[2].scopes).toEqual ["source.qsharp", "constant.numeric.decimal.qsharp"]

    # FIXME: assignment tokenization incorrect
    it "tokenizes integers with exponents", ->
      {tokens} = grammar.tokenizeLine "let fiveMillion = 5e6;"
      values = (token.value for token in tokens)

      expect(values).toEqual ["let", " fiveMillion = ", "5e6", ";"]
      expect(tokens[2].scopes).toEqual ["source.qsharp", "constant.numeric.decimal.qsharp"]

    # FIXME: assignment tokenization incorrect
    it "tokenizes bare floats", ->
      {tokens} = grammar.tokenizeLine "let five_dot_zero = 5.0;"
      values = (token.value for token in tokens)

      expect(values).toEqual ["let", " five_dot_zero = ", "5.0", ";"]
      expect(tokens[2].scopes).toEqual ["source.qsharp", "constant.numeric.decimal.qsharp"]

    # FIXME: assignment tokenization incorrect
    it "tokenizes bare floats with exponents", ->
      {tokens} = grammar.tokenizeLine "let _5Million = 5.0e6;"
      values = (token.value for token in tokens)

      expect(values).toEqual ["let", " _5Million = ", "5.0e6", ";"]
      expect(tokens[2].scopes).toEqual ["source.qsharp", "constant.numeric.decimal.qsharp"]

    it "tokenizes string punctuation", ->
      {tokens} = grammar.tokenizeLine "\"Hello world!\""
      values = (token.value for token in tokens)

      expect(values).toEqual ["\"", "Hello world!", "\""]
      expect(tokens[0].scopes).toEqual ["source.qsharp", "string.quoted.double.qsharp", "punctuation.definition.string.begin.qsharp"]
      expect(tokens[2].scopes).toEqual ["source.qsharp", "string.quoted.double.qsharp", "punctuation.definition.string.end.qsharp"]

    it "tokenizes escaped characters in strings", ->
      {tokens} = grammar.tokenizeLine "\"Hello \\t world!\""
      values = (token.value for token in tokens)

      expect(values).toEqual ["\"", "Hello ", "\\t", " world!", "\""]
      expect(tokens[2].scopes).toEqual ["source.qsharp", "string.quoted.double.qsharp", "constant.character.escape.qsharp"]

    it "tokenizes illegal newlines in strings", ->
      {tokens} = grammar.tokenizeLine "\"Hello \n world!\""
      values = (token.value for token in tokens)

      expect(values).toEqual ["\"", "Hello", " ", "\n world!", "\""]
      expect(tokens[2].scopes).toEqual ["source.qsharp", "string.quoted.double.qsharp", "invalid.illegal.newline.qsharp"]

  # FIXME: identifier and assignment tokenization is incorrect for all expression-operators

  describe "assignment expression-operator", ->
    it "tokenizes `=`", ->
      {tokens} = grammar.tokenizeLine "let foo = 1;"
      values = (token.value for token in tokens)

      expect(values).toEqual ["let", " ", "foo", " ", "=", " ", "1", ";"]
      expect(tokens[4].scopes).toEqual ["source.qsharp", "keyword.operator.assignment.qsharp"]

  describe "arithmetic expression-operators", ->
    it "tokenizes `+`", ->
      {tokens} = grammar.tokenizeLine "let foo = 1 + 1;"
      values = (token.value for token in tokens)

      expect(values).toEqual ["let", " ", "foo", " ", "=", " ", "1", " ", "+", " ", "1", ";"]
      expect(tokens[8].scopes).toEqual ["source.qsharp", "keyword.operator.arithmetic.qsharp"]

    it "tokenizes `-`", ->
      {tokens} = grammar.tokenizeLine "let foo = 1 - 1;"
      values = (token.value for token in tokens)

      expect(values).toEqual ["let", " ", "foo", " ", "=", " ", "1", " ", "-", " ", "1", ";"]
      expect(tokens[8].scopes).toEqual ["source.qsharp", "keyword.operator.arithmetic.qsharp"]

    it "tokenizes `*`", ->
      {tokens} = grammar.tokenizeLine "let foo = 1 * 1;"
      values = (token.value for token in tokens)

      expect(values).toEqual ["let", " ", "foo", " ", "=", " ", "1", " ", "*", " ", "1", ";"]
      expect(tokens[8].scopes).toEqual ["source.qsharp", "keyword.operator.arithmetic.qsharp"]

    it "tokenizes `/`", ->
      {tokens} = grammar.tokenizeLine "let foo = 1 / 1;"
      values = (token.value for token in tokens)

      expect(values).toEqual ["let", " ", "foo", " ", "=", " ", "1", " ", "/", " ", "1", ";"]
      expect(tokens[8].scopes).toEqual ["source.qsharp", "keyword.operator.arithmetic.qsharp"]

    it "tokenizes `^`", ->
      {tokens} = grammar.tokenizeLine "let foo = 1 ^ 1;"
      values = (token.value for token in tokens)

      expect(values).toEqual ["let", " ", "foo", " ", "=", " ", "1", " ", "^", " ", "1", ";"]
      expect(tokens[8].scopes).toEqual ["source.qsharp", "keyword.operator.arithmetic.qsharp"]

    it "tokenizes `%`", ->
      {tokens} = grammar.tokenizeLine "let foo = 1 % 1;"
      values = (token.value for token in tokens)

      expect(values).toEqual ["let", " ", "foo", " ", "=", " ", "1", " ", "%", " ", "1", ";"]
      expect(tokens[8].scopes).toEqual ["source.qsharp", "keyword.operator.arithmetic.qsharp"]

  describe "logical expression-operators", ->
    it "tokenizes `!`", ->
      {tokens} = grammar.tokenizeLine "let foo = !false;"
      values = (token.value for token in tokens)

      expect(values).toEqual ["let", " ", "foo", " ", "=", " ", "!", "false", ";"]
      expect(tokens[6].scopes).toEqual ["source.qsharp", "keyword.operator.logical.not.qsharp"]

    it "tokenizes `&&`", ->
      {tokens} = grammar.tokenizeLine "let foo = true && false;"
      values = (token.value for token in tokens)

      expect(values).toEqual ["let", " ", "foo", " ", "=", " ", "true", " ", "&&", " ", "false", ";"]
      expect(tokens[8].scopes).toEqual ["source.qsharp", "keyword.operator.logical.and.qsharp"]

    it "tokenizes `||`", ->
      {tokens} = grammar.tokenizeLine "let foo = true || false;"
      values = (token.value for token in tokens)

      expect(values).toEqual ["let", " ", "foo", " ", "=", " ", "true", " ", "||", " ", "false", ";"]
      expect(tokens[8].scopes).toEqual ["source.qsharp", "keyword.operator.logical.or.qsharp"]

  describe "comparison expression-operators", ->
    it "tokenizes `==`", ->
      {tokens} = grammar.tokenizeLine "let foo = 1 == 1;"
      values = (token.value for token in tokens)

      expect(values).toEqual ["let", " ", "foo", " ", "=", " ", "1", " ", "==", " ", "1", ";"]
      expect(tokens[8].scopes).toEqual ["source.qsharp", "keyword.operator.comparison.qsharp"]

    it "tokenizes `!=`", ->
      {tokens} = grammar.tokenizeLine "let foo = 1 != 1;"
      values = (token.value for token in tokens)

      expect(values).toEqual ["let", " ", "foo", " ", "=", " ", "1", " ", "!=", " ", "1", ";"]
      expect(tokens[8].scopes).toEqual ["source.qsharp", "keyword.operator.comparison.qsharp"]

  describe "relational expression-operators", ->
    it "tokenizes `<=`", ->
      {tokens} = grammar.tokenizeLine "let foo = 1 <= 2;"
      values = (token.value for token in tokens)

      expect(values).toEqual ["let", " ", "foo", " ", "=", " ", "1", " ", "<=", " ", "2", ";"]
      expect(tokens[8].scopes).toEqual ["source.qsharp", "keyword.operator.relational.qsharp"]

    it "tokenizes `>=`", ->
      {tokens} = grammar.tokenizeLine "let foo = 1 >= 2;"
      values = (token.value for token in tokens)

      expect(values).toEqual ["let", " ", "foo", " ", "=", " ", "1", " ", ">=", " ", "2", ";"]
      expect(tokens[8].scopes).toEqual ["source.qsharp", "keyword.operator.relational.qsharp"]

    it "tokenizes `<`", ->
      {tokens} = grammar.tokenizeLine "let foo = 1 < 2;"
      values = (token.value for token in tokens)

      expect(values).toEqual ["let", " ", "foo", " ", "=", " ", "1", " ", "<", " ", "2", ";"]
      expect(tokens[8].scopes).toEqual ["source.qsharp", "keyword.operator.relational.qsharp"]

    it "tokenizes `>`", ->
      {tokens} = grammar.tokenizeLine "let foo = 1 > 2;"
      values = (token.value for token in tokens)

      expect(values).toEqual ["let", " ", "foo", " ", "=", " ", "1", " ", ">", " ", "2", ";"]
      expect(tokens[8].scopes).toEqual ["source.qsharp", "keyword.operator.relational.qsharp"]

  describe "bitwise expression-operators", ->
    it "tokenizes `&&&`", ->
      {tokens} = grammar.tokenizeLine "let foo = 1 &&& 3;"
      values = (token.value for token in tokens)

      expect(values).toEqual ["let", " ", "foo", " ", "=", " ", "1", " ", "&&&", " ", "3", ";"]
      expect(tokens[8].scopes).toEqual ["source.qsharp", "keyword.operator.bitwise.and.qsharp"]

    it "tokenizes `|||`", ->
      {tokens} = grammar.tokenizeLine "let foo = 1 ||| 3;"
      values = (token.value for token in tokens)

      expect(values).toEqual ["let", " ", "foo", " ", "=", " ", "1", " ", "|||", " ", "3", ";"]
      expect(tokens[8].scopes).toEqual ["source.qsharp", "keyword.operator.bitwise.or.qsharp"]

    it "tokenizes `^^^`", ->
      {tokens} = grammar.tokenizeLine "let foo = 1 ^^^ 3;"
      values = (token.value for token in tokens)

      expect(values).toEqual ["let", " ", "foo", " ", "=", " ", "1", " ", "^^^", " ", "3", ";"]
      expect(tokens[8].scopes).toEqual ["source.qsharp", "keyword.operator.bitwise.xor.qsharp"]

    it "tokenizes `~~~`", ->
      {tokens} = grammar.tokenizeLine "let foo = ~~~3;"
      values = (token.value for token in tokens)

      expect(values).toEqual ["let", " ", "foo", " ", "=", " ", "~~~", "3", ";"]
      expect(tokens[6].scopes).toEqual ["source.qsharp", "keyword.operator.bitwise.complement.qsharp"]
