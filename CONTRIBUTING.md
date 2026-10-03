# Contributing

## Adding a rule

1. Create `src/ADHealthCheck/Checks/ADHC-<AREA>-<NNN>.ps1` returning a hashtable with
   `Id`, `Category`, `Title`, `Severity`, `Description`, `Recommendation`, `References`,
   `Requires` and a `Test` scriptblock. Copy an existing rule as a starting point.
2. `Test` receives the context and returns `@{ Status = 'Pass' | 'Warning' | 'Fail'; Message = '...'; Details = @(...) }`.
   It must only read `$Context.Data`, `$Context.Settings` and `$Context.Now`; never query AD directly.
3. If the rule needs data that is not collected yet, add a collector in `Private/` and
   call it from `Get-ADHealthCheckContext`.
4. Add at least one failing case to `tests/Unit/Rules.Tests.ps1`. The healthy baseline
   test must still pass.
5. Run `./build.ps1 -Task Analyze, Test, Docs` and commit the regenerated `docs/rules.md`.

## Style

- Source files are ASCII only and must run on Windows PowerShell 5.1: no ternary
  operators, null-coalescing, or `ForEach-Object -Parallel`.
- PSScriptAnalyzer must report zero findings.
