# SPDX-License-Identifier: AGPL-3.0-only
param([switch]$Fetch)
$ErrorActionPreference = 'Stop'
$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
$baseline = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'baseline.json') -Raw | ConvertFrom-Json
function Git-Value([string[]]$Arguments) {
    $result = & git -C $repo @Arguments
    if ($LASTEXITCODE -ne 0) { throw 'Git inspection failed.' }
    return ($result -join "`n").Trim()
}
$origin = Git-Value @('remote','get-url','origin')
$upstream = Git-Value @('remote','get-url','upstream')
if ($origin -ne $baseline.fork -or $upstream -ne $baseline.upstream) { throw 'Remote URLs do not match this fork baseline.' }
if ($Fetch) { $null = Git-Value @('fetch','--no-tags','upstream','master') }
$latest = Git-Value @('rev-parse','refs/remotes/upstream/master')
$headCommit = Git-Value @('rev-parse','HEAD')
$counts = (Git-Value @('rev-list','--left-right','--count','HEAD...refs/remotes/upstream/master')) -split '\s+'
& git -C $repo merge-base --is-ancestor $baseline.upstreamCommit HEAD
if ($LASTEXITCODE -ne 0) { throw 'Pinned baseline is not an ancestor of this checkout.' }
[ordered]@{
    pinnedBase = $baseline.upstreamCommit
    checkout = $headCommit
    upstream = $latest
    downstreamOnlyCommits = [int]$counts[0]
    upstreamOnlyCommits = [int]$counts[1]
    worktreeChanged = (Git-Value @('status','--porcelain')).Length -gt 0
    fetched = $Fetch.IsPresent
    merged = $false
} | ConvertTo-Json
