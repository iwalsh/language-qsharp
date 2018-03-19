describe 'Q# grammar', ->
  grammar = null

  beforeEach ->
    waitsForPromise ->
      atom.packages.activatePackage('language-qsharp')

    runs ->
      grammar = atom.grammars.grammarForScopeName('source.qsharp')

  it 'parses the grammar', ->
    expect(grammar).toBeDefined()
    expect(grammar.scopeName).toBe 'source.qsharp'

  describe 'namespace-declaration', ->
    it 'tokenizes the keyword and name', ->
      {tokens} = grammar.tokenizeLine 'namespace Hello.QSharp { let foo = bar; }'
      values = (token.value for token in tokens)

      expect(values).toEqual ['namespace', ' ', 'Hello.QSharp', ' ', '{', ' ', 'let', ' ', 'foo', ' ', '=', ' ', 'bar', ';', ' ', '}']
      expect(tokens[0].scopes).toEqual ['source.qsharp', 'keyword.other.qsharp']
      expect(tokens[2].scopes).toEqual ['source.qsharp', 'entity.name.namespace.qsharp']

    # FIXME: What's with the empty string token at the end of the line?
    it 'tokenizes namespace bodies that span multiple lines', ->
      program = '''
                namespace Hello.QSharp {
                  let foo = bar;
                }
                '''
      tokens = grammar.tokenizeLines(program)
      values = (token.value for token in tokens[0])
      expect(values).toEqual ['namespace', ' ', 'Hello.QSharp', ' ', '{', '']
      expect(tokens[0][0].scopes).toEqual ['source.qsharp', 'keyword.other.qsharp']
      expect(tokens[0][2].scopes).toEqual ['source.qsharp', 'entity.name.namespace.qsharp']

  describe 'open-directive', ->
    it 'tokenizes the keyword and name', ->
      program = '''
                namespace Hello.QSharp {
                  open Microsoft.Quantum.Canon;
                }
                '''
      tokens = grammar.tokenizeLines program
      values = (token.value for token in tokens[1])

      expect(values).toEqual ['  ', 'open', ' ', 'Microsoft.Quantum.Canon', ';', '']
      expect(tokens[1][1].scopes).toEqual ['source.qsharp', 'keyword.other.qsharp']
      expect(tokens[1][3].scopes).toEqual ['source.qsharp', 'entity.name.namespace.qsharp']

    it 'tokenizes the surrounding namespace', ->
      program = '''
                namespace Hello.QSharp {
                  open Microsoft.Quantum.Canon;
                }
                '''
      tokens = grammar.tokenizeLines program
      values = (token.value for token in tokens[0])

      expect(values).toEqual ['namespace', ' ', 'Hello.QSharp', ' ', '{', '']
      expect(tokens[0][0].scopes).toEqual ['source.qsharp', 'keyword.other.qsharp']
      expect(tokens[0][2].scopes).toEqual ['source.qsharp', 'entity.name.namespace.qsharp']

  describe 'newtype-directive', ->
    it 'tokenizes the keyword, name and assignment operator', ->
      {tokens} = grammar.tokenizeLine 'namespace Q { newtype T = (Int); }'
      values = (token.value for token in tokens)

      expect(values).toEqual ['namespace', ' ', 'Q', ' ', '{', ' ', 'newtype', ' ', 'T', ' ', '=', ' ', '(', 'Int', ')', ';', ' ', '}']
      expect(tokens[6].scopes).toEqual ['source.qsharp', 'keyword.other.qsharp']
      expect(tokens[8].scopes).toEqual ['source.qsharp', 'entity.name.type.qsharp']
      expect(tokens[10].scopes).toEqual ['source.qsharp', 'keyword.operator.assignment.qsharp']
      expect(tokens[13].scopes).toEqual ['source.qsharp', 'entity.name.type.qsharp']

    it 'supports tuple types', ->
      {tokens} = grammar.tokenizeLine 'namespace Q { newtype T = (Int, Double); }'
      values = (token.value for token in tokens)

      expect(values).toEqual ['namespace', ' ', 'Q', ' ', '{', ' ', 'newtype', ' ', 'T', ' ', '=', ' ', '(', 'Int', ',', ' ', 'Double', ')', ';', ' ', '}']
      expect(tokens[13].scopes).toEqual ['source.qsharp', 'entity.name.type.qsharp']
      expect(tokens[14].scopes).toEqual ['source.qsharp', 'punctuation.separator.comma.qsharp']
      expect(tokens[16].scopes).toEqual ['source.qsharp', 'entity.name.type.qsharp']

    it 'supports type parameters', ->
      {tokens} = grammar.tokenizeLine 'namespace Q { newtype T = \'A; }'
      values = (token.value for token in tokens)

      expect(values).toEqual ['namespace', ' ', 'Q', ' ', '{', ' ', 'newtype', ' ', 'T', ' ', '=', ' ', '\'A', ';', ' ', '}']
      expect(tokens[12].scopes).toEqual ['source.qsharp', 'entity.name.type.qsharp']

    it 'supports array types', ->
      {tokens} = grammar.tokenizeLine 'namespace Q { newtype T = Qubit[]; }'
      values = (token.value for token in tokens)

      expect(values).toEqual ['namespace', ' ', 'Q', ' ', '{', ' ', 'newtype', ' ', 'T', ' ', '=', ' ', 'Qubit[]', ';', ' ', '}']
      expect(tokens[12].scopes).toEqual ['source.qsharp', 'entity.name.type.qsharp']

    it 'supports operation types using fat-arrow (=>)', ->
      {tokens} = grammar.tokenizeLine 'namespace Q { newtype T = (\'Tinput => \'Tresult); }'
      values = (token.value for token in tokens)

      expect(values).toEqual ['namespace', ' ', 'Q', ' ', '{', ' ', 'newtype', ' ', 'T', ' ', '=', ' ', '(', '\'Tinput', ' ', '=>', ' ', '\'Tresult', ')', ';', ' ', '}']
      expect(tokens[13].scopes).toEqual ['source.qsharp', 'entity.name.type.qsharp']
      expect(tokens[15].scopes).toEqual ['source.qsharp', 'punctuation.fat-arrow.qsharp']
      expect(tokens[17].scopes).toEqual ['source.qsharp', 'entity.name.type.qsharp']

    it 'supports function types using arrow (->)', ->
      {tokens} = grammar.tokenizeLine 'namespace Q { newtype T = (\'A[], \'A->\'A) -> \'A[]); }'
      values = (token.value for token in tokens)

      expect(values).toEqual ['namespace', ' ', 'Q', ' ', '{', ' ', 'newtype', ' ', 'T', ' ', '=', ' ', '(', '\'A[]', ',', ' ', '\'A', '->', '\'A', ')', ' ', '->', ' ', '\'A[]', ')', ';', ' ', '}']
      expect(tokens[17].scopes).toEqual ['source.qsharp', 'punctuation.arrow.qsharp']
      expect(tokens[21].scopes).toEqual ['source.qsharp', 'punctuation.arrow.qsharp']

    it 'supports functor lists for operations', ->
      {tokens} = grammar.tokenizeLine 'namespace Q { newtype T = (Int => (): Adjoint, Controlled); }'
      values = (token.value for token in tokens)

      expect(values).toEqual ['namespace', ' ', 'Q', ' ', '{', ' ', 'newtype', ' ', 'T', ' ', '=', ' ', '(', 'Int', ' ', '=>', ' ', '(', ')', ':', ' ', 'Adjoint', ',', ' ', 'Controlled', ')', ';', ' ', '}']
      expect(tokens[19].scopes).toEqual ['source.qsharp', 'punctuation.separator.colon.qsharp']
      expect(tokens[21].scopes).toEqual ['source.qsharp', 'entity.other.functor.qsharp']
      expect(tokens[24].scopes).toEqual ['source.qsharp', 'entity.other.functor.qsharp']

  describe 'function-definition', ->
    it 'tokenizes the keyword, identifier, and types', ->
      program = '''
                namespace Hello.QSharp {
                  function DotProduct(a : Double[], b : Double[]) : Double {}
                }
                '''
      tokens = grammar.tokenizeLines program
      values = (token.value for token in tokens[1])

      expect(values).toEqual ['  ', 'function', ' ', 'DotProduct', '(', 'a', ' ', ':', ' ', 'Double[]', ',', ' ', 'b', ' ', ':', ' ', 'Double[]', ')', ' ', ':', ' ', 'Double', ' ', '{', '}']
      expect(tokens[1][1].scopes).toEqual ['source.qsharp', 'keyword.other.qsharp']
      expect(tokens[1][3].scopes).toEqual ['source.qsharp', 'entity.name.function.qsharp']
      expect(tokens[1][5].scopes).toEqual ['source.qsharp', 'variable.parameter.qsharp']

    it 'tokenizes statements within the function body', ->
      program = '''
                namespace Hello.QSharp {
                  function SetFooToBar() : Double {
                    set foo = bar;
                  }
                }
                '''
      tokens = grammar.tokenizeLines program
      values = (token.value for token in tokens[2])

      expect(values).toEqual ['    ', 'set', ' ', 'foo', ' ', '=', ' ', 'bar', ';', '']
      expect(tokens[2][1].scopes).toEqual ['source.qsharp', 'keyword.binding.set.qsharp']

  describe 'operation-definition', ->
    it 'tokenizes the keyword, identifier, and types', ->
      program = '''
                namespace Hello.QSharp {
                  operation NoOp (q : Qubit) : () {}
                }
                '''
      tokens = grammar.tokenizeLines program
      values = (token.value for token in tokens[1])

      expect(values).toEqual ['  ', 'operation', ' ', 'NoOp', ' ' , '(', 'q', ' ', ':', ' ', 'Qubit', ')', ' ', ':', ' ', '(', ')', ' ', '{', '}']
      expect(tokens[1][1].scopes).toEqual ['source.qsharp', 'keyword.other.qsharp']
      expect(tokens[1][3].scopes).toEqual ['source.qsharp', 'entity.name.function.qsharp']
      expect(tokens[1][6].scopes).toEqual ['source.qsharp', 'variable.parameter.qsharp']

    it 'tokenizes the `body` keyword and block', ->
      program = '''
                namespace Hello.QSharp {
                  operation SetFooToBar () : () {
                    body { set foo = bar; }
                  }
                }
                '''
      tokens = grammar.tokenizeLines program
      values = (token.value for token in tokens[2])

      expect(values).toEqual ['    ', 'body', ' ', '{', ' ' , 'set', ' ', 'foo', ' ', '=', ' ', 'bar', ';', ' ', '}']
      expect(tokens[2][1].scopes).toEqual ['source.qsharp', 'keyword.other.qsharp']

    it 'tokenizes the `adjoint` and `auto` keywords', ->
      program = '''
                namespace Hello.QSharp {
                  operation SetFooToBar () : () {
                    body { set foo = bar; }
                    adjoint auto
                  }
                }
                '''
      tokens = grammar.tokenizeLines program
      values = (token.value for token in tokens[3])

      expect(values).toEqual ['    ', 'adjoint', ' ', 'auto']
      expect(tokens[3][1].scopes).toEqual ['source.qsharp', 'keyword.other.qsharp']
      expect(tokens[3][3].scopes).toEqual ['source.qsharp', 'keyword.other.qsharp']

    it 'tokenizes the `adjoint` and `self` keywords', ->
      program = '''
                namespace Hello.QSharp {
                  operation SetFooToBar () : () {
                    body { set foo = bar; }
                    adjoint self
                  }
                }
                '''
      tokens = grammar.tokenizeLines program
      values = (token.value for token in tokens[3])

      expect(values).toEqual ['    ', 'adjoint', ' ', 'self']
      expect(tokens[3][1].scopes).toEqual ['source.qsharp', 'keyword.other.qsharp']
      expect(tokens[3][3].scopes).toEqual ['source.qsharp', 'keyword.other.qsharp']


    it 'tokenizes `adjoint` blocks', ->
      program = '''
                namespace Hello.QSharp {
                  operation SetFooToBar () : () {
                    adjoint { set foo = bar; }
                  }
                }
                '''
      tokens = grammar.tokenizeLines program
      values = (token.value for token in tokens[2])

      expect(values).toEqual ['    ', 'adjoint', ' ', '{', ' ' , 'set', ' ', 'foo', ' ', '=', ' ', 'bar', ';', ' ', '}']
      expect(tokens[2][1].scopes).toEqual ['source.qsharp', 'keyword.other.qsharp']

    it 'tokenizes the `controlled` and `auto` keywords', ->
      program = '''
                namespace Hello.QSharp {
                  operation SetFooToBar () : () {
                    body { set foo = bar; }
                    controlled auto
                  }
                }
                '''
      tokens = grammar.tokenizeLines program
      values = (token.value for token in tokens[3])

      expect(values).toEqual ['    ', 'controlled', ' ', 'auto']
      expect(tokens[3][1].scopes).toEqual ['source.qsharp', 'keyword.other.qsharp']
      expect(tokens[3][3].scopes).toEqual ['source.qsharp', 'keyword.other.qsharp']

    it 'tokenizes `controlled` blocks', ->
      program = '''
                namespace Hello.QSharp {
                  operation SetFooToBar () : () {
                    controlled (controls) { set foo = bar; }
                  }
                }
                '''
      tokens = grammar.tokenizeLines program
      values = (token.value for token in tokens[2])

      expect(values).toEqual ['    ', 'controlled', ' ', '(', 'controls', ')', ' ', '{', ' ' , 'set', ' ', 'foo', ' ', '=', ' ', 'bar', ';', ' ', '}']
      expect(tokens[2][1].scopes).toEqual ['source.qsharp', 'keyword.other.qsharp']
      expect(tokens[2][4].scopes).toEqual ['source.qsharp', 'variable.parameter.qsharp']

    it 'tokenizes the `controlled adjoint` and `auto` keywords ', ->
      program = '''
                namespace Hello.QSharp {
                  operation SetFooToBar () : () {
                    body { set foo = bar; }
                    adjoint controlled auto
                  }
                }
                '''
      tokens = grammar.tokenizeLines program
      values = (token.value for token in tokens[3])

      expect(values).toEqual ['    ', 'adjoint', ' ', 'controlled', ' ', 'auto']
      expect(tokens[3][1].scopes).toEqual ['source.qsharp', 'keyword.other.qsharp']
      expect(tokens[3][3].scopes).toEqual ['source.qsharp', 'keyword.other.qsharp']
      expect(tokens[3][5].scopes).toEqual ['source.qsharp', 'keyword.other.qsharp']

    it 'tokenizes `adjoint controlled` blocks', ->
      program = '''
                namespace Hello.QSharp {
                  operation SetFooToBar () : () {
                    adjoint controlled (controls) { set foo = bar; }
                  }
                }
                '''
      tokens = grammar.tokenizeLines program
      values = (token.value for token in tokens[2])

      expect(values).toEqual ['    ', 'adjoint', ' ', 'controlled', ' ', '(', 'controls', ')', ' ', '{', ' ' , 'set', ' ', 'foo', ' ', '=', ' ', 'bar', ';', ' ', '}']
      expect(tokens[2][1].scopes).toEqual ['source.qsharp', 'keyword.other.qsharp']
      expect(tokens[2][3].scopes).toEqual ['source.qsharp', 'keyword.other.qsharp']
      expect(tokens[2][6].scopes).toEqual ['source.qsharp', 'variable.parameter.qsharp']

  describe 'comments', ->
    describe 'double-slash comments', ->
      it 'tokenizes the punctation and content', ->
        {tokens} = grammar.tokenizeLine '// Comment!'
        values = (token.value for token in tokens)

        expect(values).toEqual ['//', ' Comment!']
        expect(tokens[0].scopes).toEqual ['source.qsharp', 'comment.line.double-slash.qsharp', 'punctuation.definition.comment.qsharp']
        expect(tokens[1].scopes).toEqual ['source.qsharp', 'comment.line.double-slash.qsharp']

      it 'tokenizes whitespace at the start of the line', ->
        {tokens} = grammar.tokenizeLine '   // Comment!'
        values = (token.value for token in tokens)

        expect(values).toEqual ['   ', '//', ' Comment!']
        expect(tokens[0].scopes).toEqual ['source.qsharp', 'punctuation.whitespace.comment.leading.qsharp']

      it 'does not include leading content in the comment', ->
        {tokens} = grammar.tokenizeLine 'Not a comment // Comment!'
        values = (token.value for token in tokens)

        expect(values).toEqual ['Not', ' ', 'a', ' ', 'comment', ' ', '//', ' Comment!']
        expect(tokens[0].scopes).toNotEqual ['source.qsharp', 'comment.line.double-slash.qsharp']

      it 'does not include subsequent lines in the comment', ->
        tokens = grammar.tokenizeLines '// Comment!\nNot a comment'

        # Line 0
        expect(tokens[0][0].value).toBe '//'
        expect(tokens[0][1].value).toBe ' Comment!'
        # Line 1
        expect(tokens[1][0].value).toBe 'Not'
        expect(tokens[1][0].scopes).toNotEqual ['source.qsharp', 'comment.line.double-slash.qsharp']

      it 'ignores extra slashes in the comment body', ->
        {tokens} = grammar.tokenizeLine '// Comment! // The same comment'
        values = (token.value for token in tokens)

        expect(values).toEqual ['//', ' Comment! // The same comment']
        expect(tokens[1].scopes).toEqual ['source.qsharp', 'comment.line.double-slash.qsharp']

    describe 'documentation comments', ->
      it 'tokenizes the punctuation and content', ->
        {tokens} = grammar.tokenizeLine '/// This comment is formatted as Markdown'
        values = (token.value for token in tokens)

        expect(values).toEqual ['///', ' This comment is formatted as Markdown']
        expect(tokens[0].scopes).toEqual ['source.qsharp', 'comment.block.documentation.qsharp', 'punctuation.definition.comment.qsharp']
        expect(tokens[1].scopes).toEqual ['source.qsharp', 'comment.block.documentation.qsharp']

      it 'tokenizes whitespace at the start of the line', ->
        {tokens} = grammar.tokenizeLine '   /// Comment!'
        values = (token.value for token in tokens)

        expect(values).toEqual ['   ', '///', ' Comment!']
        expect(tokens[0].scopes).toEqual ['source.qsharp', 'punctuation.whitespace.comment.leading.qsharp']

      it 'does not include leading content in the comment', ->
        {tokens} = grammar.tokenizeLine 'Not a comment /// Comment!'
        values = (token.value for token in tokens)

        expect(values).toEqual ['Not', ' ', 'a', ' ', 'comment', ' ', '///', ' Comment!']
        expect(tokens[0].scopes).toNotEqual ['source.qsharp', 'comment.line.double-slash.qsharp']

      it 'does not include subsequent lines in the comment', ->
        tokens = grammar.tokenizeLines '/// Comment!\nNot a comment'

        # Line 0
        expect(tokens[0][0].value).toBe '///'
        expect(tokens[0][1].value).toBe ' Comment!'
        # Line 1
        expect(tokens[1][0].value).toBe 'Not'
        expect(tokens[1][0].scopes).toNotEqual ['source.qsharp', 'comment.line.double-slash.qsharp']

      it 'ignores extra slashes in the comment body', ->
        {tokens} = grammar.tokenizeLine '/// Comment! // The same comment'
        values = (token.value for token in tokens)

        expect(values).toEqual ['///', ' Comment! // The same comment']
        expect(tokens[1].scopes).toEqual ['source.qsharp', 'comment.block.documentation.qsharp']

      it 'tokenizes Markdown headers', ->
        {tokens} = grammar.tokenizeLine '/// # Summary '
        values = (token.value for token in tokens)

        expect(values).toEqual ['///', ' ', '#', ' ', 'Summary', ' ']
        expect(tokens[2].scopes).toEqual ['source.qsharp', 'comment.block.documentation.qsharp', 'markup.heading.1.md.qsharp', 'punctuation.definition.comment-header.qsharp']
        expect(tokens[4].scopes).toEqual ['source.qsharp', 'comment.block.documentation.qsharp', 'markup.heading.1.md.qsharp']

      it 'tokenizes cross-references', ->
        {tokens} = grammar.tokenizeLine '/// Check out @"MyFile"'
        values = (token.value for token in tokens)

        expect(values).toEqual ['///', ' Check out ', '@"', 'MyFile', '"']
        expect(tokens[2].scopes).toEqual ['source.qsharp', 'comment.block.documentation.qsharp', 'markup.underline.link.qsharp', 'punctuation.definition.cross-reference.begin.qsharp']
        expect(tokens[3].scopes).toEqual ['source.qsharp', 'comment.block.documentation.qsharp', 'markup.underline.link.qsharp']
        expect(tokens[4].scopes).toEqual ['source.qsharp', 'comment.block.documentation.qsharp', 'markup.underline.link.qsharp', 'punctuation.definition.cross-reference.end.qsharp']

      it 'ignores pound signs in the comment body', ->
        {tokens} = grammar.tokenizeLine '/// My favorite language is Q#'
        values = (token.value for token in tokens)

        expect(values).toEqual ['///', ' My favorite language is Q#']

      it 'does not tokenize Markdown headers other than `#`', ->
        {tokens} = grammar.tokenizeLine '/// ## Level 2 header'
        values = (token.value for token in tokens)

        expect(values).toEqual ['///', ' ## Level 2 header']

  describe 'interpolated strings', ->
    it 'tokenizes the punctuation and content', ->
      {tokens} = grammar.tokenizeLine 'fail $"Syndrome {syn} is incorrect";'
      values = (token.value for token in tokens)

      expect(values).toEqual ['fail', ' ', '$"', 'Syndrome ', '{', 'syn', '}', ' is incorrect', '"', ';']
      expect(tokens[2].scopes).toEqual ['source.qsharp', 'string.quoted.double.qsharp', 'punctuation.definition.string.begin.qsharp']
      expect(tokens[4].scopes).toEqual ['source.qsharp', 'string.quoted.double.qsharp', 'meta.interpolation.qsharp', 'punctuation.definition.interpolation.begin.qsharp']
      expect(tokens[5].scopes).toEqual ['source.qsharp', 'string.quoted.double.qsharp', 'meta.interpolation.qsharp', 'variable.other.qsharp']
      expect(tokens[6].scopes).toEqual ['source.qsharp', 'string.quoted.double.qsharp', 'meta.interpolation.qsharp', 'punctuation.definition.interpolation.end.qsharp']

  describe 'statements', ->
    describe 'return-statement', ->
      it 'tokenizes the keyword', ->
        {tokens} = grammar.tokenizeLine 'return ();'
        values = (token.value for token in tokens)

        expect(values).toEqual ['return', ' ', '(', ')', ';']
        expect(tokens[0].scopes).toEqual ['source.qsharp', 'keyword.control.flow.return.qsharp']

    describe 'if-statement', ->
      it 'tokenizes the keyword and punctuation', ->
        {tokens} = grammar.tokenizeLine 'if (i == 1) { X(target); }'
        values = (token.value for token in tokens)

        expect(values).toEqual ['if', ' ', '(', 'i', ' ', '==', ' ', '1', ')', ' ', '{', ' ', 'X', '(', 'target', ')',
        ';', ' ', '}']
        expect(tokens[0].scopes).toEqual ['source.qsharp', 'keyword.control.conditional.if.qsharp']
        expect(tokens[2].scopes).toEqual ['source.qsharp', 'punctuation.parenthesis.open.qsharp']
        expect(tokens[8].scopes).toEqual ['source.qsharp', 'punctuation.parenthesis.close.qsharp']

      it 'tokenizes `elif` branches', ->
        {tokens} = grammar.tokenizeLine 'elif (i == 2) { Y(target); }'
        values = (token.value for token in tokens)

        expect(values).toEqual ['elif', ' ', '(', 'i', ' ', '==', ' ', '2', ')', ' ', '{', ' ', 'Y', '(', 'target', ')',
        ';', ' ', '}']
        expect(tokens[0].scopes).toEqual ['source.qsharp', 'keyword.control.conditional.elif.qsharp']
        expect(tokens[2].scopes).toEqual ['source.qsharp', 'punctuation.parenthesis.open.qsharp']
        expect(tokens[8].scopes).toEqual ['source.qsharp', 'punctuation.parenthesis.close.qsharp']

      it 'tokenizes `else` branches', ->
        {tokens} = grammar.tokenizeLine 'else { Z(target); }'
        values = (token.value for token in tokens)

        expect(values).toEqual ['else', ' ', '{', ' ', 'Z', '(', 'target', ')', ';', ' ', '}']
        expect(tokens[0].scopes).toEqual ['source.qsharp', 'keyword.control.conditional.else.qsharp']

    describe 'for-statement', ->
      # FIXME: Not tokenizing the block
      it 'tokenizes the keywords and punctuation', ->
        {tokens} = grammar.tokenizeLine 'for (i in 0 .. 5) { set sum = sum + 1; }'
        values = (token.value for token in tokens)

        expect(values).toEqual ['for', ' ', '(', 'i', ' ', 'in', ' ', '0', ' ', '..', ' ', '5', ')', ' { set sum = sum + 1; }']
        expect(tokens[0].scopes).toEqual ['source.qsharp', 'keyword.control.loop.for.qsharp']
        expect(tokens[2].scopes).toEqual ['source.qsharp', 'punctuation.parenthesis.open.qsharp']
        expect(tokens[3].scopes).toEqual ['source.qsharp', 'entity.name.variable.local.qsharp']
        expect(tokens[5].scopes).toEqual ['source.qsharp', 'keyword.control.loop.in.qsharp']
        expect(tokens[9].scopes).toEqual ['source.qsharp', 'punctuation.definition.range.qsharp']
        expect(tokens[12].scopes).toEqual ['source.qsharp', 'punctuation.parenthesis.close.qsharp']

    describe 'repeat-statement', ->
      it 'tokenizes the keyword', ->
        {tokens} = grammar.tokenizeLine 'repeat { set sum = sum + 1; }'
        values = (token.value for token in tokens)

        expect(values).toEqual ['repeat', ' ', '{', ' ', 'set', ' ', 'sum', ' ', '=', ' ', 'sum', ' ', '+', ' ', '1', ';', ' ', '}']
        expect(tokens[0].scopes).toEqual ['source.qsharp', 'keyword.control.loop.repeat.qsharp']
        expect(tokens[2].scopes).toEqual ['source.qsharp', 'punctuation.curlybrace.open.qsharp']
        expect(tokens[17].scopes).toEqual ['source.qsharp', 'punctuation.curlybrace.close.qsharp']

      # TODO: need a more complete "repeat" example

    describe 'until-statement', ->
      it 'tokenizes the keywords', ->
        {tokens} = grammar.tokenizeLine '} until result == Zero fixup { (); }'
        values = (token.value for token in tokens)

        expect(values).toEqual ['} ', 'until', ' ', 'result', ' ', '==', ' ', 'Zero', ' ', 'fixup', ' ', '{', ' ', '(', ')', ';', ' ', '}']
        expect(tokens[1].scopes).toEqual ['source.qsharp', 'keyword.control.loop.until.qsharp']
        expect(tokens[9].scopes).toEqual ['source.qsharp', 'keyword.control.loop.fixup.qsharp']

    describe 'fail-statement', ->
      it 'tokenizes the keyword', ->
        {tokens} = grammar.tokenizeLine 'fail "It crashed!"';
        values = (token.value for token in tokens)

        expect(values).toEqual ['fail', ' ', '"', 'It crashed!', '"']
        expect(tokens[0].scopes).toEqual ['source.qsharp', 'keyword.control.flow.fail.qsharp']

      it 'tokenizes the string', ->
        {tokens} = grammar.tokenizeLine 'fail "Error";';
        values = (token.value for token in tokens)

        expect(values).toEqual ['fail', ' ', '"', 'Error', '"', ';']
        expect(tokens[2].scopes).toEqual ['source.qsharp', 'string.quoted.double.qsharp', 'punctuation.definition.string.begin.qsharp']
        expect(tokens[3].scopes).toEqual ['source.qsharp', 'string.quoted.double.qsharp']
        expect(tokens[4].scopes).toEqual ['source.qsharp', 'string.quoted.double.qsharp', 'punctuation.definition.string.end.qsharp']

    describe 'let-statment', ->
      it 'tokenizes the keyword, variable name, and assignment operator', ->
        {tokens} = grammar.tokenizeLine 'let a = 1;'
        values = (token.value for token in tokens)

        expect(values).toEqual [ 'let', ' ', 'a', ' ', '=', ' ', '1', ';' ]
        expect(tokens[0].scopes).toEqual ['source.qsharp', 'keyword.binding.let.qsharp']
        expect(tokens[2].scopes).toEqual ['source.qsharp', 'entity.name.variable.local.qsharp']
        expect(tokens[4].scopes).toEqual ['source.qsharp', 'keyword.operator.assignment.qsharp']

      # FIXME: Not yet recognized as 'let'
      it 'supports tuple-deconstruction assignment', ->
        {tokens} = grammar.tokenizeLine 'let (a, (b, c)) = (1, (2, 3));'
        values = (token.value for token in tokens)

        expect(values).toEqual [ 'let ', '(', 'a', ',', ' ', '(', 'b', ',', ' ', 'c', ')', ')', ' = ', '(', '1', ',', ' ', '(', '2', ',', ' ', '3', ')', ')', ';' ]
        expect(tokens[0].scopes).toEqual ['source.qsharp', 'keyword.binding.let.qsharp']

    describe 'mutable-statement', ->
      it 'tokenizes the keyword, variable name, and assignment operator', ->
        {tokens} = grammar.tokenizeLine 'mutable counter = 1;'
        values = (token.value for token in tokens)

        expect(values).toEqual [ 'mutable', ' ', 'counter', ' ', '=', ' ', '1', ';' ]
        expect(tokens[0].scopes).toEqual ['source.qsharp', 'keyword.binding.mutable.qsharp']
        expect(tokens[2].scopes).toEqual ['source.qsharp', 'entity.name.variable.local.qsharp']
        expect(tokens[4].scopes).toEqual ['source.qsharp', 'keyword.operator.assignment.qsharp']

    describe 'set-statement', ->
      it 'tokenizes the keyword, variable name, and assignment operator', ->
        {tokens} = grammar.tokenizeLine 'set counter = counter + 1;'
        values = (token.value for token in tokens)

        expect(values).toEqual ['set', ' ', 'counter', ' ', '=', ' ', 'counter', ' ', '+', ' ', '1', ';']
        expect(tokens[0].scopes).toEqual ['source.qsharp', 'keyword.binding.set.qsharp']
        expect(tokens[2].scopes).toEqual ['source.qsharp', 'entity.name.variable.local.qsharp']
        expect(tokens[4].scopes).toEqual ['source.qsharp', 'keyword.operator.assignment.qsharp']

    describe 'using-or-borrowing-statement', ->
      it 'tokenizes the `using` statement', ->
        {tokens} = grammar.tokenizeLine 'using (q = Qubit[1]) { }'
        values = (token.value for token in tokens)

        expect(values).toEqual ['using', ' ', '(', 'q', ' ', '=', ' ', 'Qubit', '[', '1', ']', ')', ' ', '{', ' ', '}' ]
        expect(tokens[0].scopes).toEqual ['source.qsharp', 'keyword.other.qsharp']
        expect(tokens[3].scopes).toEqual ['source.qsharp', 'entity.name.variable.local.qsharp']
        expect(tokens[5].scopes).toEqual ['source.qsharp', 'keyword.operator.assignment.qsharp']
        expect(tokens[7].scopes).toEqual ['source.qsharp', 'entity.name.type.qsharp']
        expect(tokens[8].scopes).toEqual ['source.qsharp', 'punctuation.squarebracket.open.qsharp']
        expect(tokens[10].scopes).toEqual ['source.qsharp', 'punctuation.squarebracket.close.qsharp']

      it 'tokenizes the `borrowing` statement', ->
        {tokens} = grammar.tokenizeLine 'borrowing (q = Qubit[2]) { }'
        values = (token.value for token in tokens)

        expect(values).toEqual ['borrowing', ' ', '(', 'q', ' ', '=', ' ', 'Qubit', '[', '2', ']', ')', ' ', '{', ' ', '}' ]
        expect(tokens[0].scopes).toEqual ['source.qsharp', 'keyword.other.qsharp']
        expect(tokens[3].scopes).toEqual ['source.qsharp', 'entity.name.variable.local.qsharp']
        expect(tokens[5].scopes).toEqual ['source.qsharp', 'keyword.operator.assignment.qsharp']
        expect(tokens[7].scopes).toEqual ['source.qsharp', 'entity.name.type.qsharp']
        expect(tokens[8].scopes).toEqual ['source.qsharp', 'punctuation.squarebracket.open.qsharp']
        expect(tokens[10].scopes).toEqual ['source.qsharp', 'punctuation.squarebracket.close.qsharp']

  describe 'punctuation-range', ->
    it 'tokenizes start/stop ranges', ->
      {tokens} = grammar.tokenizeLine 'let range = 1..5;'
      values = (token.value for token in tokens)

      expect(values).toEqual ['let', ' ', 'range', ' ', '=', ' ', '1', '..', '5', ';']
      expect(tokens[7].scopes).toEqual ['source.qsharp', 'punctuation.definition.range.qsharp']

    it 'tokenizes start/step/stop ranges', ->
      {tokens} = grammar.tokenizeLine 'let range = 1..2..5;'
      values = (token.value for token in tokens)

      expect(values).toEqual ['let', ' ', 'range', ' ', '=', ' ', '1', '..', '2', '..', '5', ';']
      expect(tokens[7].scopes).toEqual ['source.qsharp', 'punctuation.definition.range.qsharp']
      expect(tokens[9].scopes).toEqual ['source.qsharp', 'punctuation.definition.range.qsharp']

    it 'tolerates whitespace in the range', ->
      {tokens} = grammar.tokenizeLine 'let range = 1 .. 2 .. 5;'
      values = (token.value for token in tokens)

      expect(values).toEqual ['let', ' ', 'range', ' ', '=', ' ', '1', ' ', '..', ' ', '2', ' ', '..', ' ', '5', ';']
      expect(tokens[8].scopes).toEqual ['source.qsharp', 'punctuation.definition.range.qsharp']
      expect(tokens[12].scopes).toEqual ['source.qsharp', 'punctuation.definition.range.qsharp']

  describe 'array-creation-expression', ->
    it 'tokenizes the keyword and punctuation', ->
      {tokens} = grammar.tokenizeLine 'let ary = new Int[i+1];'
      values = (token.value for token in tokens)

      expect(values).toEqual ['let', ' ', 'ary', ' ', '=', ' ', 'new', ' ', 'Int', '[', 'i', '+', '1', ']', ';']
      expect(tokens[6].scopes).toEqual ['source.qsharp', 'keyword.other.new.qsharp']
      expect(tokens[8].scopes).toEqual ['source.qsharp', 'entity.name.type.qsharp']
      expect(tokens[9].scopes).toEqual ['source.qsharp', 'punctuation.squarebracket.open.qsharp']
      expect(tokens[13].scopes).toEqual ['source.qsharp', 'punctuation.squarebracket.close.qsharp']

  describe 'arrays', ->
    # TODO: literal syntax let ary = [1;2;3];
    # TODO: concatentation let ary = [1;2;3] + [4;5;6];
    # TODO: range let ary = a[1..3];
    # TODO: indexing let first = a[0];

  describe 'primitive-type', ->
    [
      'Int', 'Double', 'Bool', 'Qubit', 'Pauli', 'Result', 'Range', 'String'
    ].forEach((type) =>
      it "recognizes the primitive type `#{type}`", =>
        {tokens} = grammar.tokenizeLine "return #{type};"
        values = (token.value for token in tokens)

        expect(values).toEqual ['return', ' ', type, ';']
        expect(tokens[2].scopes).toEqual ['source.qsharp', 'storage.type.qsharp']
    );

  describe 'library-functions', ->
    [
      'X', 'Y', 'Z', 'H', 'HY', 'S', 'T', 'SWAP', 'CNOT', 'CCNOT', 'MultiX', 'R',
      'RFrac', 'Rx', 'Ry', 'Rz', 'R1', 'R1Frac', 'Exp', 'ExpFrac', 'Measure',
      'M', 'MultiM'
    ].forEach((func) =>
      it "tokenizes the builtin quantum function `#{func}`", =>
        {tokens} = grammar.tokenizeLine "let res = #{func}(foo);"
        values = (token.value for token in tokens)

        expect(values).toEqual ['let', ' ', 'res', ' ', '=', ' ', func, '(', 'foo', ')', ';']
        expect(tokens[6].scopes).toEqual ['source.qsharp', 'support.function.quantum.qsharp']
    );

    [
      'Message', 'Length', 'Assert', 'AssertProb', 'AssertEqual', 'Random',
      'Floor', 'Float', 'Start', 'Step', 'Stop'
    ].forEach((func) =>
      it "tokenizes the builtin classical function `#{func}`", =>
        {tokens} = grammar.tokenizeLine "let res = #{func}(foo);"
        values = (token.value for token in tokens)

        expect(values).toEqual ['let', ' ', 'res', ' ', '=', ' ', func, '(', 'foo', ')', ';']
        expect(tokens[6].scopes).toEqual ['source.qsharp', 'support.function.builtin.qsharp']
    );

  describe 'callable expressions', ->
    it 'tokenizes the name and arguments', ->
      {tokens} = grammar.tokenizeLine "{ Foo(1); }"
      values = (token.value for token in tokens)

      expect(values).toEqual ['{', ' ', 'Foo', '(', '1', ')', ';', ' ', '}']
      expect(tokens[2].scopes).toEqual ['source.qsharp', 'entity.name.function.qsharp']

    it 'tokenizes functors that are applied to the operation', ->
      {tokens} = grammar.tokenizeLine "{ (Adjoint Foo)(1); }"
      values = (token.value for token in tokens)

      expect(values).toEqual ['{', ' ', '(', 'Adjoint', ' ', 'Foo', ')', '(', '1', ')', ';', ' ', '}']
      expect(tokens[3].scopes).toEqual ['source.qsharp', 'entity.other.functor.qsharp']
      expect(tokens[5].scopes).toEqual ['source.qsharp', 'entity.name.function.qsharp']

  describe 'callable invocations', ->
    it 'tokenizes the function name and arguments', ->
      {tokens} = grammar.tokenizeLine "{ Foo(bar); }"
      values = (token.value for token in tokens)

      expect(values).toEqual ['{', ' ', 'Foo', '(', 'bar', ')', ';', ' ', '}']
      # FIXME: I would like to scope this to 'variable.parameter.qsharp'
      expect(tokens[4].scopes).toEqual ['source.qsharp', 'variable.other.qsharp']

    it 'tokenizes invocations using partial application', ->
      {tokens} = grammar.tokenizeLine "{ Foo(bar, _); }"
      values = (token.value for token in tokens)

      # FIXME: Underscore is not tokenized correctly: getting " _"
      expect(values).toEqual ['{', ' ', 'Foo', '(', 'bar', ',', ' _', ')', ';', ' ', '}']
      expect(tokens[4].scopes).toEqual ['source.qsharp', 'variable.other.qsharp']
      #expect(tokens[7].scopes).toEqual ['source.qsharp', 'variable.other.qsharp']

  describe 'literals', ->
    describe 'boolean-literal', ->
      [
        'true', 'false'
      ].forEach((bool) =>
        it "tokenizes boolean `#{bool}`", =>
          {tokens} = grammar.tokenizeLine "mutable condition = #{bool};"
          values = (token.value for token in tokens)

          expect(values).toEqual ['mutable', ' ', 'condition', ' ', '=', ' ', bool, ';']
          expect(tokens[6].scopes).toEqual ['source.qsharp', 'constant.language.boolean.qsharp']
      );

    describe 'numeric-literal', ->
      it 'tokenizes bare integers', ->
        {tokens} = grammar.tokenizeLine 'let five = 5;'
        values = (token.value for token in tokens)

        expect(values).toEqual ['let', ' ', 'five', ' ', '=', ' ', '5', ';']
        expect(tokens[6].scopes).toEqual ['source.qsharp', 'constant.numeric.decimal.qsharp']

      it 'tokenizes integers with exponents', ->
        {tokens} = grammar.tokenizeLine 'let fiveMillion = 5e6;'
        values = (token.value for token in tokens)

        expect(values).toEqual ['let', ' ', 'fiveMillion', ' ', '=', ' ', '5e6', ';']
        expect(tokens[6].scopes).toEqual ['source.qsharp', 'constant.numeric.decimal.qsharp']

      it 'tokenizes bare floats', ->
        {tokens} = grammar.tokenizeLine 'let five_dot_zero = 5.0;'
        values = (token.value for token in tokens)

        expect(values).toEqual ['let', ' ', 'five_dot_zero', ' ', '=', ' ', '5.0', ';']
        expect(tokens[6].scopes).toEqual ['source.qsharp', 'constant.numeric.decimal.qsharp']

      it 'tokenizes bare floats with exponents', ->
        {tokens} = grammar.tokenizeLine 'let _5Million = 5.0e6;'
        values = (token.value for token in tokens)

        expect(values).toEqual ['let', ' ', '_5Million', ' ', '=', ' ', '5.0e6', ';']
        expect(tokens[6].scopes).toEqual ['source.qsharp', 'constant.numeric.decimal.qsharp']

      it 'tokenizes hexadecimal numbers', ->
        {tokens} = grammar.tokenizeLine 'let hex = 0xdeadbeef;'
        values = (token.value for token in tokens)

        expect(values).toEqual ['let', ' ', 'hex', ' ', '=', ' ', '0xdeadbeef', ';']
        expect(tokens[6].scopes).toEqual ['source.qsharp', 'constant.numeric.hex.qsharp']

    describe 'string-literal', ->
      it 'tokenizes string punctuation', ->
        {tokens} = grammar.tokenizeLine '"Hello world!"'
        values = (token.value for token in tokens)

        expect(values).toEqual ['"', 'Hello world!', '"']
        expect(tokens[0].scopes).toEqual ['source.qsharp', 'string.quoted.double.qsharp', 'punctuation.definition.string.begin.qsharp']
        expect(tokens[2].scopes).toEqual ['source.qsharp', 'string.quoted.double.qsharp', 'punctuation.definition.string.end.qsharp']

      it 'tokenizes escaped characters in strings', ->
        {tokens} = grammar.tokenizeLine '"Hello \\t world!"'
        values = (token.value for token in tokens)

        expect(values).toEqual ['"', 'Hello ', '\\t', ' world!', '"']
        expect(tokens[2].scopes).toEqual ['source.qsharp', 'string.quoted.double.qsharp', 'constant.character.escape.qsharp']

      it 'tokenizes illegal newlines in strings', ->
        {tokens} = grammar.tokenizeLine '"Hello \n world!"'
        values = (token.value for token in tokens)

        expect(values).toEqual ['"', 'Hello', ' ', '\n ', 'world', '!', '"']
        expect(tokens[2].scopes).toEqual ['source.qsharp', 'string.quoted.double.qsharp', 'invalid.illegal.newline.qsharp']

    describe 'tuple-literal', ->
      it 'tokenizes the punctation', ->
        {tokens} = grammar.tokenizeLine 'let tuple = (1,2);'
        values = (token.value for token in tokens)

        expect(values).toEqual ['let', ' ', 'tuple', ' ', '=', ' ', '(', '1', ',', '2', ')', ';']
        expect(tokens[6].scopes).toEqual ['source.qsharp', 'punctuation.parenthesis.open.qsharp']
        expect(tokens[8].scopes).toEqual ['source.qsharp', 'punctuation.separator.comma.qsharp']
        expect(tokens[10].scopes).toEqual ['source.qsharp', 'punctuation.parenthesis.close.qsharp']

      it 'tokenizes the inner expression', ->
        {tokens} = grammar.tokenizeLine 'let tuple = (1+2);'
        values = (token.value for token in tokens)

        expect(values).toEqual ['let', ' ', 'tuple', ' ', '=', ' ', '(', '1', '+', '2', ')', ';']
        expect(tokens[8].scopes).toEqual ['source.qsharp', 'keyword.operator.arithmetic.qsharp']

    describe 'pauli-literal', ->
      [
        'PauliI', 'PauliX', 'PauliY', 'PauliZ'
      ].forEach((type) =>
        it "recognizes the Pauli constant `#{type}`", =>
          {tokens} = grammar.tokenizeLine "return #{type};"
          values = (token.value for token in tokens)

          expect(values).toEqual ['return', ' ', type, ';']
          expect(tokens[2].scopes).toEqual ['source.qsharp', 'constant.language.pauli.qsharp']
      );

    describe 'result-literal', ->
      [
        'One', 'Zero'
      ].forEach((type) =>
        it "recognizes the Result constant `#{type}`", =>
          {tokens} = grammar.tokenizeLine "return #{type};"
          values = (token.value for token in tokens)

          expect(values).toEqual ['return', ' ', type, ';']
          expect(tokens[2].scopes).toEqual ['source.qsharp', 'constant.language.result.qsharp']
      );

  describe 'expression-operators', ->
    it 'tokenizes assignment (`=`)', ->
      {tokens} = grammar.tokenizeLine 'let foo = 1;'
      values = (token.value for token in tokens)

      expect(values).toEqual ['let', ' ', 'foo', ' ', '=', ' ', '1', ';']
      expect(tokens[2].scopes).toEqual ['source.qsharp', 'entity.name.variable.local.qsharp']
      expect(tokens[4].scopes).toEqual ['source.qsharp', 'keyword.operator.assignment.qsharp']

    describe 'arithmetic-operators', ->
      [
        '+', '-', '*', '/', '^', '%'
      ].forEach((op) =>
        it "tokenizes the operator `#{op}`", =>
          {tokens} = grammar.tokenizeLine "let foo = 1 #{op} 2;"
          values = (token.value for token in tokens)

          expect(values).toEqual ['let', ' ', 'foo', ' ', '=', ' ', '1', ' ', op, ' ', '2', ';']
          expect(tokens[8].scopes).toEqual ['source.qsharp', 'keyword.operator.arithmetic.qsharp']
      );

    describe 'logical-operators', ->
      it 'tokenizes NOT (`!`)', ->
        {tokens} = grammar.tokenizeLine 'let foo = !false;'
        values = (token.value for token in tokens)

        expect(values).toEqual ['let', ' ', 'foo', ' ', '=', ' ', '!', 'false', ';']
        expect(tokens[6].scopes).toEqual ['source.qsharp', 'keyword.operator.logical.qsharp']

      it 'tokenizes AND (`&&`)', ->
        {tokens} = grammar.tokenizeLine 'let foo = true && false;'
        values = (token.value for token in tokens)

        expect(values).toEqual ['let', ' ', 'foo', ' ', '=', ' ', 'true', ' ', '&&', ' ', 'false', ';']
        expect(tokens[8].scopes).toEqual ['source.qsharp', 'keyword.operator.logical.qsharp']

      it 'tokenizes OR (`||`)', ->
        {tokens} = grammar.tokenizeLine 'let foo = true || false;'
        values = (token.value for token in tokens)

        expect(values).toEqual ['let', ' ', 'foo', ' ', '=', ' ', 'true', ' ', '||', ' ', 'false', ';']
        expect(tokens[8].scopes).toEqual ['source.qsharp', 'keyword.operator.logical.qsharp']

    describe 'comparison-operators', ->
      [
        '==', '!='
      ].forEach((op) =>
        it "tokenizes the operator `#{op}`", =>
          {tokens} = grammar.tokenizeLine "let foo = 1 #{op} 2;"
          values = (token.value for token in tokens)

          expect(values).toEqual ['let', ' ', 'foo', ' ', '=', ' ', '1', ' ', op, ' ', '2', ';']
          expect(tokens[8].scopes).toEqual ['source.qsharp', 'keyword.operator.comparison.qsharp']
      );

    describe 'relational-operators', ->
      [
        '<=', '>=', '<', '>'
      ].forEach((op) =>
        it "tokenizes the operator `#{op}`", =>
          {tokens} = grammar.tokenizeLine "let foo = 1 #{op} 2;"
          values = (token.value for token in tokens)

          expect(values).toEqual ['let', ' ', 'foo', ' ', '=', ' ', '1', ' ', op, ' ', '2', ';']
          expect(tokens[8].scopes).toEqual ['source.qsharp', 'keyword.operator.relational.qsharp']
      );

    describe 'bitwise-operators', ->
      [
        '&&&', '|||', '^^^', '<<<', '>>>'
      ].forEach((op) =>
        it "tokenizes the operator `#{op}`", =>
          {tokens} = grammar.tokenizeLine "let foo = 1 #{op} 2;"
          values = (token.value for token in tokens)

          expect(values).toEqual ['let', ' ', 'foo', ' ', '=', ' ', '1', ' ', op, ' ', '2', ';']
          expect(tokens[8].scopes).toEqual ['source.qsharp', 'keyword.operator.bitwise.qsharp']
      );

      it 'tokenizes bitwise-complement (`~~~`)', ->
        {tokens} = grammar.tokenizeLine 'let foo = ~~~3;'
        values = (token.value for token in tokens)

        expect(values).toEqual ['let', ' ', 'foo', ' ', '=', ' ', '~~~', '3', ';']
        expect(tokens[6].scopes).toEqual ['source.qsharp', 'keyword.operator.bitwise.qsharp']

  describe 'reserved-csharp-keywords, A-D', ->
    [
      'abstract', 'as', 'base', 'bool', 'break', 'byte', 'case', 'catch',
      'char', 'checked', 'class', 'const', 'continue', 'decimal', 'default',
      'delegate', 'do', 'double'
    ].forEach((keyword) =>
      it "reserves the C# keyword `#{keyword}`", =>
        {tokens} = grammar.tokenizeLine "foo #{keyword} bar;"
        values = (token.value for token in tokens)

        expect(values).toEqual ['foo', ' ', keyword, ' ', 'bar', ';']
        expect(tokens[2].scopes).toEqual ['source.qsharp', 'invalid.illegal.reserved-csharp-keyword.a-d.qsharp']
    );

  describe 'reserved-csharp-keywords, E-L', ->
    [
      'enum', 'event', 'explicit', 'extern', 'finally', 'fixed', 'float',
      'foreach', 'goto', 'implicit', 'int', 'interface', 'internal', 'is',
      'lock', 'long'
    ].forEach((keyword) =>
      it "reserves the C# keyword `#{keyword}`", =>
        {tokens} = grammar.tokenizeLine "foo #{keyword} bar;"
        values = (token.value for token in tokens)

        expect(values).toEqual ['foo', ' ', keyword, ' ', 'bar', ';']
        expect(tokens[2].scopes).toEqual ['source.qsharp', 'invalid.illegal.reserved-csharp-keyword.e-l.qsharp']
    );

  describe 'reserved-csharp-keywords, N-S', ->
    [
      'null', 'object', 'operator', 'out', 'override', 'params', 'private',
      'protected', 'public', 'readonly', 'ref', 'sbyte', 'sealed', 'short',
      'sizeof', 'stackalloc'
    ].forEach((keyword) =>
      it "reserves the C# keyword `#{keyword}`", =>
        {tokens} = grammar.tokenizeLine "foo #{keyword} bar;"
        values = (token.value for token in tokens)

        expect(values).toEqual ['foo', ' ', keyword, ' ', 'bar', ';']
        expect(tokens[2].scopes).toEqual ['source.qsharp', 'invalid.illegal.reserved-csharp-keyword.n-s.qsharp']
    );

  describe 'reserved-csharp-keywords, S-V', ->
    [
      'static', 'string', 'struct', 'switch', 'this', 'throw', 'try', 'typeof',
      'unit', 'ulong', 'unchecked', 'unsafe', 'ushort', 'virtual', 'void',
      'volatile'
    ].forEach((keyword) =>
      it "reserves the C# keyword `#{keyword}`", =>
        {tokens} = grammar.tokenizeLine "foo #{keyword} bar;"
        values = (token.value for token in tokens)

        expect(values).toEqual ['foo', ' ', keyword, ' ', 'bar', ';']
        expect(tokens[2].scopes).toEqual ['source.qsharp', 'invalid.illegal.reserved-csharp-keyword.s-v.qsharp']
    );
