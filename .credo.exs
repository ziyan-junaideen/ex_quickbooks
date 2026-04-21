%{
  configs: [
    %{
      name: "default",
      files: %{
        included: ["lib/", "test/"],
        excluded: ["_build/", "deps/"]
      },
      requires: [],
      strict: true,
      color: true,
      checks: [
        {Credo.Check.Consistency.ExceptionNames, []},
        {Credo.Check.Consistency.LineEndings, []},
        {Credo.Check.Consistency.SpaceAroundOperators, []},
        {Credo.Check.Consistency.ParameterPatternMatching, []},
        {Credo.Check.Consistency.SpaceInParentheses, []},
        {Credo.Check.Consistency.TabsOrSpaces, []},
        {Credo.Check.Design.SkipTestWithoutComment, []},
        {Credo.Check.Design.TagFIXME, []},
        {Credo.Check.Design.TagTODO, []},
        {Credo.Check.Readability.AliasOrder, []},
        {Credo.Check.Readability.BlockPipe, []},
        {Credo.Check.Readability.FunctionNames, []},
        {Credo.Check.Readability.LargeNumbers, []},
        {Credo.Check.Readability.MaxLineLength, [priority: :low, max_length: 120, ignore_definitions: true, ignore_heredocs: true, ignore_sigils: true, ignore_strings: true, ignore_urls: true, ignore_specs: false]},
        {Credo.Check.Readability.ModuleAttributeNames, []},
        {Credo.Check.Readability.ModuleDoc, []},
        {Credo.Check.Readability.ModuleNames, []},
        {Credo.Check.Readability.NestedFunctionCalls, []},
        {Credo.Check.Readability.OneArityFunctionInPipe, []},
        {Credo.Check.Readability.OnePipePerLine, []},
        {Credo.Check.Readability.ParenthesesOnZeroArityDefs, []},
        {Credo.Check.Readability.PreferImplicitTry, []},
        {Credo.Check.Readability.RedundantBlankLines, []},
        {Credo.Check.Readability.SeparateAliasRequire, []},
        {Credo.Check.Readability.SinglePipe, []},
        {Credo.Check.Readability.Specs, []},
        {Credo.Check.Readability.StrictModuleLayout, []},
        {Credo.Check.Readability.StringSigils, []},
        {Credo.Check.Readability.TrailingWhiteSpace, []},
        {Credo.Check.Readability.VariableNames, []},
        {Credo.Check.Refactor.ABCSize, [max_size: 30]},
        {Credo.Check.Refactor.FunctionArity, []}
      ]
    }
  ]
}
