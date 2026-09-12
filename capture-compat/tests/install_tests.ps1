$ErrorActionPreference = 'Stop'
$project = Split-Path -Parent $PSScriptRoot
$installer = Join-Path $project 'install.ps1'

foreach ($helperName in @('codex-computer-use.exe', 'codex-computer-use-swift.exe')) {
    $fixture = Join-Path $project ('validation\install-fixture-' + [Guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $fixture -Force | Out-Null
    $helper = Join-Path $fixture $helperName
    $dll = Join-Path $fixture 'version.dll'
    $record = Join-Path $fixture 'codex-capture-compat.install.json'
    Set-Content -LiteralPath $helper -Value 'Non-executable install test fixture.'
    & $installer -HelperPath $helper -WhatIf
    if ((Test-Path -LiteralPath $dll) -or (Test-Path -LiteralPath $record)) { throw "WhatIf wrote files for $helperName." }
    & $installer -HelperPath $helper
    if (-not (Test-Path -LiteralPath $record)) { throw "Install record missing for $helperName." }
    if ((Get-FileHash -LiteralPath $dll).Hash -ne (Get-FileHash -LiteralPath (Join-Path $project 'dist\version.dll')).Hash) {
        throw "Copied DLL differs for $helperName."
    }
    & $installer -HelperPath $helper
    & $installer -HelperPath $helper -Action Uninstall
    if ((Test-Path -LiteralPath $dll) -or (Test-Path -LiteralPath $record)) { throw "Uninstall left owned files for $helperName." }
    Set-Content -LiteralPath $dll -Value 'Foreign DLL fixture - must not be overwritten or removed.'
    $foreignHash = (Get-FileHash -LiteralPath $dll).Hash
    $rejected = $false
    try { & $installer -HelperPath $helper } catch { $rejected = $true }
    if (-not $rejected -or (Get-FileHash -LiteralPath $dll).Hash -ne $foreignHash) { throw "Foreign DLL overwrite guard failed for $helperName." }
    $rejected = $false
    try { & $installer -HelperPath $helper -Action Uninstall } catch { $rejected = $true }
    if (-not $rejected -or (Get-FileHash -LiteralPath $dll).Hash -ne $foreignHash) { throw "Unowned DLL removal guard failed for $helperName." }
}

$invalidFixture = Join-Path $project ('validation\install-invalid-' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $invalidFixture -Force | Out-Null
$invalidHelper = Join-Path $invalidFixture 'Codex.exe'
Set-Content -LiteralPath $invalidHelper -Value 'Wrong executable name fixture.'
$rejected = $false
try { & $installer -HelperPath $invalidHelper } catch { $rejected = $true }
if (-not $rejected) { throw 'Unsupported helper name guard failed.' }

'PASS: both helper names, WhatIf, copy hash, idempotency, uninstall, name guard, foreign-DLL preservation.'
