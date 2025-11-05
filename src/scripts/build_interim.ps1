# This script is for building a LaTeX document located in the project root directory.
# It runs pdflatex and bibtex as needed, captures logs, and organizes output files
# This script assumes that pdflatex and bibtex are installed and available in the system PATH.
# Also, don't worry about moving this script anywhere. It works out the box from this location.

# This script is for Windows users, if you are on Linux or macOS, please use the corresponding shell script in build_interim.sh.

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent (Split-Path -Parent $scriptDir)
$srcDir = Join-Path $repoRoot 'src'
Set-Location -Path $repoRoot

function Get-PdfTextUsingWinRT
{
    param([string]$PdfPath)
    try
    {
        Add-Type -AssemblyName System.Runtime.WindowsRuntime -ErrorAction Stop
        $storageFile = [Windows.Storage.StorageFile]::GetFileFromPathAsync($PdfPath).GetAwaiter().GetResult()
        if (-not $storageFile)
        {
            return $null
        }
        $pdf = [Windows.Data.Pdf.PdfDocument]::LoadFromFileAsync($storageFile).GetAwaiter().GetResult()
        if (-not $pdf)
        {
            return $null
        }
        $allText = ""
        for ($i = 0; $i -lt $pdf.PageCount; $i++) {
            $page = $pdf.GetPage($i)
            if ($null -eq $page)
            {
                continue
            }
            $txt = $page.GetTextAsync().GetAwaiter().GetResult()
            if ($txt)
            {
                $allText += $txt + "`n"
            }
            $page.Dispose()
        }
        return $allText
    }
    catch
    {
        return $null
    }
}

$logDir = Join-Path -Path $repoRoot -ChildPath 'src/scripts/log'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null

$auxilDir = Join-Path -Path $repoRoot -ChildPath 'auxil'
New-Item -ItemType Directory -Force -Path $auxilDir | Out-Null

$outputPath = Join-Path $repoRoot "Interim_FYP-Digital Twin Framework for Autonomous Drone Swarm Coordination in Maritime SAR Operations.pdf"

$texPath = Join-Path $srcDir 'interim_report.tex'
$bibPathSrc = Join-Path $srcDir 'interim_report.bib'

pdflatex -interaction=nonstopmode -halt-on-error -output-directory="$repoRoot" "$texPath" 2>&1 | Tee-Object -FilePath (Join-Path $logDir 'pdflatex-pass1.scripts.log')

if (Test-Path (Join-Path $repoRoot 'interim_report.aux'))
{
    if (Test-Path $bibPathSrc)
    {
        Copy-Item $bibPathSrc (Join-Path $repoRoot 'interim_report.bib') -Force
    }

    Push-Location $repoRoot
    try {
        bibtex interim_report 2>&1 | Tee-Object -FilePath (Join-Path $logDir 'bibtex.scripts.log')
    } finally {
        Pop-Location
    }

    if (Test-Path (Join-Path $repoRoot 'interim_report.bib'))
    {
        Remove-Item (Join-Path $repoRoot 'interim_report.bib') -Force
    }
}

pdflatex -interaction=nonstopmode -halt-on-error -output-directory="$repoRoot" "$texPath" 2>&1 | Tee-Object -FilePath (Join-Path $logDir 'pdflatex-pass2.scripts.log')
pdflatex -interaction=nonstopmode -halt-on-error -output-directory="$repoRoot" "$texPath" 2>&1 | Tee-Object -FilePath (Join-Path $logDir 'pdflatex-pass3.scripts.log')

$tempPdfPath = Join-Path $repoRoot "interim_report.pdf"
if (Test-Path $tempPdfPath)
{
    Move-Item $tempPdfPath $outputPath -Force

    $parentAuxPath = Join-Path $repoRoot "interim_report.aux"
    $parentLogPath = Join-Path $repoRoot "interim_report.log"
    $parentBblPath = Join-Path $repoRoot "interim_report.bbl"
    $parentBlgPath = Join-Path $repoRoot "interim_report.blg"

    if (Test-Path $parentAuxPath)
    {
        Move-Item $parentAuxPath $auxilDir -Force
    }
    if (Test-Path $parentLogPath)
    {
        Move-Item $parentLogPath $auxilDir -Force
    }
    if (Test-Path $parentBblPath)
    {
        Move-Item $parentBblPath $auxilDir -Force
    }
    if (Test-Path $parentBlgPath)
    {
        Move-Item $parentBlgPath $auxilDir -Force
    }

    Get-ChildItem -Path $repoRoot -Include "*.out","*.toc","*.bbl","*.blg" -File -ErrorAction SilentlyContinue | Remove-Item -Force

    $pdfWordCount = $null
    $pdfPath = $outputPath
    $pdftotextCmd = Get-Command pdftotext -ErrorAction SilentlyContinue
    if ($pdftotextCmd)
    {
        try
        {
            $rawPdfText = & $pdftotextCmd.Source -layout -enc UTF-8 "$pdfPath" - 2> $null
            if ($rawPdfText -is [System.Array])
            {
                $rawPdfText = $rawPdfText -join "`n"
            }
            $pdfTokens = ($rawPdfText -split '\s+') | Where-Object { $_ -ne '' }
            $pdfWordCount = $pdfTokens.Count
        }
        catch
        {
            $pdfWordCount = $null
        }
    }
    else
    {
        $rawPdfText = Get-PdfTextUsingWinRT -PdfPath $pdfPath
        if ($rawPdfText)
        {
            $pdfTokens = ($rawPdfText -split '\s+') | Where-Object { $_ -ne '' }
            $pdfWordCount = $pdfTokens.Count
        }
        else
        {
            $pdfWordCount = $null
        }
    }

    if ($null -ne $pdfWordCount)
    {
        $pdfText = "Word count (PDF text): $pdfWordCount/10,000"
        Write-Output $pdfText
    }
    else
    {
        Write-Output "Word count (PDF text): unavailable (pdftotext/WinRT extractor not available)/10,000"
    }

    Write-Output "Done. Output: $( Resolve-Path $outputPath ). Log files cleaned up. Build logs: $( Resolve-Path $logDir )"
}
else
{
    Get-ChildItem -Path $repoRoot -Include "*.aux","*.log","*.out","*.toc","*.bbl","*.blg" -File -ErrorAction SilentlyContinue | Move-Item -Destination $logDir -Force
    Write-Output "PDF compilation failed. Logs: $( Resolve-Path $logDir )"
}
