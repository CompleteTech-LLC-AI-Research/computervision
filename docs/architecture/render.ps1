param(
    [string]$MermaidCli = 'mmdc',
    [string]$BrowserPath = 'C:/Program Files/Google/Chrome/Application/chrome.exe'
)
$ErrorActionPreference = 'Stop'
$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$browserConfig = Join-Path ([System.IO.Path]::GetTempPath()) ('mermaid-browser-' + [guid]::NewGuid().ToString('N') + '.json')
try {
    @{ executablePath = $BrowserPath; headless = $true } |
        ConvertTo-Json | Set-Content -LiteralPath $browserConfig
    $sources = @((Join-Path $repoRoot 'ARCHITECTURE.mmd')) +
        @(Get-ChildItem -LiteralPath $PSScriptRoot -Filter '*.mmd' | Sort-Object Name | ForEach-Object FullName)
    foreach ($source in $sources) {
        foreach ($mode in @('light', 'dark')) {
            $stem = [System.IO.Path]::Combine([System.IO.Path]::GetDirectoryName($source), [System.IO.Path]::GetFileNameWithoutExtension($source))
            $output = if ($source -eq $sources[0] -and $mode -eq 'light') { "$stem.png" } else { "$stem.$mode.png" }
            $background = if ($mode -eq 'dark') { '#0b1220' } else { '#ffffff' }
            & $MermaidCli -i $source -o $output -s 2 -w 1800 -b $background -p $browserConfig -c (Join-Path $PSScriptRoot "$mode.json")
            if ($LASTEXITCODE -ne 0) { throw "Mermaid render failed for $source ($mode)." }
            Write-Output "Rendered $output"
        }
    }
} finally {
    Remove-Item -LiteralPath $browserConfig -ErrorAction SilentlyContinue
}
