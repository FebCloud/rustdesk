# SPDX-License-Identifier: AGPL-3.0-only
$ErrorActionPreference = 'Stop'
$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
Push-Location $repo
try {
    $metadataText = & cargo metadata --no-deps --format-version 1 --offline
    if ($LASTEXITCODE -ne 0) { throw 'Cargo metadata failed. Initialize pinned submodules first.' }
    $metadata = $metadataText | ConvertFrom-Json
    $sources = @('src/lib.rs','src/client.rs','src/server.rs','src/server/connection.rs','src/server/video_service.rs','src/server/input_service.rs')
    $couplings = foreach ($source in $sources) {
        $text = Get-Content -LiteralPath (Join-Path $repo $source) -Raw
        [ordered]@{
            source = $source
            uiReferences = [regex]::Matches($text, 'ui_interface|ui_session_interface|crate::flutter').Count
            configReferences = [regex]::Matches($text, 'Config::|Config2::|PeerConfig::').Count
        }
    }
    [ordered]@{
        kind = 'source-inventory-not-build-validation'
        packages = @($metadata.packages | ForEach-Object {
            [ordered]@{name=$_.name; declaredLicense=$_.license; localDependencies=@($_.dependencies | Where-Object path | ForEach-Object name | Sort-Object -Unique)}
        })
        couplingIndicators = @($couplings)
        note = 'Text matches are indicators, not a complete call graph or license audit.'
    } | ConvertTo-Json -Depth 6
} finally { Pop-Location }
