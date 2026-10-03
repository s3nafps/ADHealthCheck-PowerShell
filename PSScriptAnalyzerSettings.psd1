@{
    Severity     = @('Error', 'Warning', 'Information')
    ExcludeRules = @(
        # Rule definitions are data files that return a hashtable; their scriptblocks
        # receive $Context positionally, which this rule cannot see.
        'PSReviewUnusedParameter'
    )
    Rules        = @{
        PSUseCompatibleSyntax = @{
            Enable         = $true
            TargetVersions = @('5.1', '7.4')
        }
        PSPlaceOpenBrace      = @{ Enable = $true; OnSameLine = $true }
        PSUseConsistentIndentation = @{ Enable = $true; IndentationSize = 4; Kind = 'space' }
    }
}
