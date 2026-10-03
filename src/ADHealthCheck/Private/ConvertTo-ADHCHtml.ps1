function ConvertTo-ADHCHtml {
    <#
    .SYNOPSIS
        Renders a report as a single self-contained HTML document.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [object] $Report
    )

    function Encode([object] $Value) {
        return [System.Net.WebUtility]::HtmlEncode([string]$Value)
    }

    $statusOrder = @{ Fail = 0; Error = 1; Warning = 2; Skipped = 3; Pass = 4 }
    $severityOrder = @{ Critical = 0; High = 1; Medium = 2; Low = 3; Info = 4 }
    $summary = $Report.Summary
    $gradeClass = 'grade-' + $summary.Grade.ToLowerInvariant()

    $rows = New-Object -TypeName System.Text.StringBuilder
    $sorted = $Report.Results | Sort-Object -Property @{ Expression = { $statusOrder[$_.Status] } }, @{ Expression = { $severityOrder[$_.Severity] } }, Id
    foreach ($result in $sorted) {
        $detailHtml = ''
        if (@($result.Details).Count -gt 0) {
            $items = ($result.Details | ForEach-Object { '<li>' + (Encode $_) + '</li>' }) -join ''
            $detailHtml = "<p class=`"label`">Affected ($($result.AffectedCount))</p><ul class=`"details`">$items</ul>"
        }
        $referenceHtml = ''
        if (@($result.References).Count -gt 0) {
            $links = ($result.References | ForEach-Object { '<li><a href="' + (Encode $_) + '" rel="noreferrer">' + (Encode $_) + '</a></li>' }) -join ''
            $referenceHtml = "<p class=`"label`">References</p><ul class=`"refs`">$links</ul>"
        }
        $null = $rows.AppendFormat(
            '<details class="result" data-status="{0}"><summary><span class="status s-{1}">{0}</span><span class="sev v-{2}">{3}</span><span class="id">{4}</span><span class="title">{5}</span><span class="cat">{6}</span></summary><div class="body"><p>{7}</p>{8}<p class="label">Recommendation</p><p>{9}</p>{10}</div></details>',
            (Encode $result.Status), $result.Status.ToLowerInvariant(), $result.Severity.ToLowerInvariant(), (Encode $result.Severity),
            (Encode $result.Id), (Encode $result.Title), (Encode $result.Category), (Encode $result.Message),
            $detailHtml, (Encode $result.Recommendation), $referenceHtml)
        $null = $rows.AppendLine()
    }

    $collectionNotes = ''
    $notes = @()
    foreach ($key in $Report.CollectionErrors.Keys) { $notes += "<li><strong>$(Encode $key)</strong> could not be collected: $(Encode $Report.CollectionErrors[$key])</li>" }
    foreach ($key in $Report.SkippedCollections.Keys) { $notes += "<li><strong>$(Encode $key)</strong> skipped: $(Encode $Report.SkippedCollections[$key])</li>" }
    if ($notes.Count -gt 0) {
        $collectionNotes = '<section class="notes"><h2>Collection notes</h2><ul>' + ($notes -join '') + '</ul></section>'
    }

    $generated = ([datetime]$Report.GeneratedAt).ToString('yyyy-MM-dd HH:mm') + ' UTC'
    $failed = $summary.FailedBySeverity

    @"
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>AD Health Check - $(Encode $Report.Domain)</title>
<style>
:root { --page:#f7f8fa; --surface:#fff; --ink:#111827; --muted:#4b5563; --line:#e5e7eb; --accent:#4338ca;
  --pass:#15803d; --warning:#b45309; --fail:#b91c1c; --error:#7c3aed; --skipped:#6b7280; }
@media (prefers-color-scheme: dark) { :root { --page:#0d1117; --surface:#131a23; --ink:#e6edf3; --muted:#9aa4b2; --line:#222b36; --accent:#8b9cff;
  --pass:#4ade80; --warning:#fbbf24; --fail:#f87171; --error:#c4b5fd; --skipped:#9ca3af; } }
* { box-sizing:border-box; }
body { margin:0; font:15px/1.55 -apple-system, "Segoe UI", Roboto, Arial, sans-serif; background:var(--page); color:var(--ink); }
main { max-width:1100px; margin:0 auto; padding:40px 24px 64px; }
header { display:flex; flex-wrap:wrap; justify-content:space-between; gap:24px; align-items:flex-end; margin-bottom:28px; }
h1 { margin:0 0 6px; font-size:28px; letter-spacing:-.02em; }
h2 { font-size:18px; margin:32px 0 12px; }
.meta { color:var(--muted); font-size:14px; }
.score { display:flex; align-items:center; gap:16px; padding:16px 20px; border:1px solid var(--line); border-radius:12px; background:var(--surface); }
.score strong { font-size:40px; line-height:1; letter-spacing:-.03em; }
.grade { display:grid; place-items:center; width:48px; height:48px; border-radius:10px; font-size:24px; font-weight:700; color:#fff; }
.grade-a { background:var(--pass); } .grade-b { background:#4d7c0f; } .grade-c { background:var(--warning); } .grade-d { background:#c2410c; } .grade-f { background:var(--fail); }
.cards { display:grid; grid-template-columns:repeat(5, 1fr); gap:12px; }
.card { padding:14px 16px; border:1px solid var(--line); border-radius:12px; background:var(--surface); }
.card b { display:block; font-size:24px; }
.card span { color:var(--muted); font-size:13px; }
.sevline { margin:14px 0 0; color:var(--muted); font-size:14px; }
.filters { display:flex; flex-wrap:wrap; gap:8px; margin:28px 0 12px; }
.filters button { padding:6px 14px; border:1px solid var(--line); border-radius:999px; background:var(--surface); color:var(--ink); font:inherit; font-size:13px; cursor:pointer; }
.filters button[aria-pressed="true"] { background:var(--accent); border-color:var(--accent); color:#fff; }
.result { border:1px solid var(--line); border-radius:10px; background:var(--surface); margin-bottom:8px; }
.result summary { display:grid; grid-template-columns:84px 76px 120px 1fr auto; gap:12px; align-items:center; padding:12px 16px; cursor:pointer; list-style:none; }
.result summary::-webkit-details-marker { display:none; }
.status, .sev { font-size:12px; font-weight:600; text-transform:uppercase; letter-spacing:.04em; }
.s-pass { color:var(--pass); } .s-warning { color:var(--warning); } .s-fail { color:var(--fail); } .s-error { color:var(--error); } .s-skipped { color:var(--skipped); }
.sev { color:var(--muted); } .v-critical, .v-high { color:var(--fail); }
.id { font:12px ui-monospace, Consolas, monospace; color:var(--muted); }
.title { font-weight:600; }
.cat { color:var(--muted); font-size:13px; }
.body { padding:0 16px 16px; border-top:1px solid var(--line); }
.body p { margin:12px 0 0; }
.label { font-size:12px; font-weight:600; text-transform:uppercase; letter-spacing:.04em; color:var(--muted); }
.details, .refs { margin:6px 0 0; padding-left:20px; font:13px ui-monospace, Consolas, monospace; max-height:260px; overflow:auto; }
.refs { font-family:inherit; }
a { color:var(--accent); }
.notes ul { padding-left:20px; color:var(--muted); }
footer { margin-top:40px; color:var(--muted); font-size:13px; }
@media (max-width:760px) { .cards { grid-template-columns:repeat(2, 1fr); } .result summary { grid-template-columns:72px 1fr; } .sev, .cat, .id { display:none; } }
</style>
</head>
<body>
<main>
<header>
  <div>
    <h1>Active Directory health check</h1>
    <div class="meta">$(Encode $Report.Domain) &middot; forest $(Encode $Report.Forest) &middot; $generated &middot; ADHealthCheck $(Encode $Report.ToolVersion)</div>
  </div>
  <div class="score"><div class="grade $gradeClass">$(Encode $summary.Grade)</div><div><strong>$($summary.Score)</strong><div class="meta">score out of 100</div></div></div>
</header>
<section class="cards">
  <div class="card"><b class="s-fail">$($summary.Fail)</b><span>Failed</span></div>
  <div class="card"><b class="s-warning">$($summary.Warning)</b><span>Warnings</span></div>
  <div class="card"><b class="s-pass">$($summary.Pass)</b><span>Passed</span></div>
  <div class="card"><b class="s-error">$($summary.Error)</b><span>Errors</span></div>
  <div class="card"><b class="s-skipped">$($summary.Skipped)</b><span>Skipped</span></div>
</section>
<p class="sevline">Failed by severity: $($failed.Critical) critical &middot; $($failed.High) high &middot; $($failed.Medium) medium &middot; $($failed.Low) low</p>
<div class="filters" role="group" aria-label="Filter results">
  <button type="button" data-filter="all" aria-pressed="true">All ($($summary.Total))</button>
  <button type="button" data-filter="Fail" aria-pressed="false">Failed</button>
  <button type="button" data-filter="Warning" aria-pressed="false">Warnings</button>
  <button type="button" data-filter="Error" aria-pressed="false">Errors</button>
  <button type="button" data-filter="Skipped" aria-pressed="false">Skipped</button>
  <button type="button" data-filter="Pass" aria-pressed="false">Passed</button>
</div>
<section id="results">
$($rows.ToString())
</section>
$collectionNotes
<footer>Generated by ADHealthCheck. Results reflect the data readable by the account that ran the check.</footer>
</main>
<script>
document.querySelectorAll('.filters button').forEach(function (button) {
  button.addEventListener('click', function () {
    var filter = button.getAttribute('data-filter');
    document.querySelectorAll('.filters button').forEach(function (b) { b.setAttribute('aria-pressed', String(b === button)); });
    document.querySelectorAll('.result').forEach(function (row) {
      row.hidden = filter !== 'all' && row.getAttribute('data-status') !== filter;
    });
  });
});
</script>
</body>
</html>
"@
}
