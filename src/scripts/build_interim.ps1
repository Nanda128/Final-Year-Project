# This script is for building a LaTeX document located in the project root directory.
# It runs pdflatex and bibtex as needed, captures logs, and organizes output files
# This script assumes that pdflatex and bibtex are installed and available in the system PATH.
# Also, don't worry about moving this script anywhere. It works out the box from this location.

# This script is for Windows users, if you are on Linux or macOS, please use the corresponding shell script in build_interim.sh.

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptDir
Set-Location -Path $projectRoot

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

$logDir = Join-Path -Path (Get-Location) -ChildPath 'scripts/log'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null

$parentDir = Split-Path -Parent $projectRoot
$auxilDir = Join-Path -Path $parentDir -ChildPath 'auxil'
New-Item -ItemType Directory -Force -Path $auxilDir | Out-Null

$outputPath = Join-Path (Split-Path -Parent $projectRoot) "Interim_FYP-Digital Twin Framework for Autonomous Drone Swarm Coordination in Maritime SAR Operations.pdf"

pdflatex -interaction=nonstopmode -halt-on-error -output-directory="$( Split-Path -Parent $projectRoot )" interim_report.tex 2>&1 | Tee-Object -FilePath (Join-Path $logDir 'pdflatex-pass1.scripts.log')

$originalLocation = Get-Location
try
{
    Set-Location -Path (Split-Path -Parent $projectRoot)
    if (Test-Path interim_report.aux)
    {
        $bibSource = Join-Path $projectRoot "interim_report.bib"
        $bibDest = Join-Path (Split-Path -Parent $projectRoot) "interim_report.bib"
        if (Test-Path $bibSource)
        {
            Copy-Item $bibSource $bibDest -Force
        }

        bibtex interim_report 2>&1 | Tee-Object -FilePath (Join-Path $logDir 'bibtex.scripts.log')

        if (Test-Path $bibDest)
        {
            Remove-Item $bibDest -Force
        }
    }
}
finally
{
    Set-Location -Path $originalLocation
}

pdflatex -interaction=nonstopmode -halt-on-error -output-directory="$( Split-Path -Parent $projectRoot )" interim_report.tex 2>&1 | Tee-Object -FilePath (Join-Path $logDir 'pdflatex-pass2.scripts.log')
pdflatex -interaction=nonstopmode -halt-on-error -output-directory="$( Split-Path -Parent $projectRoot )" interim_report.tex 2>&1 | Tee-Object -FilePath (Join-Path $logDir 'pdflatex-pass3.scripts.log')

$tempPdfPath = Join-Path (Split-Path -Parent $projectRoot) "interim_report.pdf"
if (Test-Path $tempPdfPath)
{
    Move-Item $tempPdfPath $outputPath -Force

    $parentAuxPath = Join-Path $parentDir "interim_report.aux"
    $parentLogPath = Join-Path $parentDir "interim_report.log"
    $parentBblPath = Join-Path $parentDir "interim_report.bbl"
    $parentBlgPath = Join-Path $parentDir "interim_report.blg"

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

    Get-ChildItem -Path . -Include "*.out","*.toc","*.bbl","*.blg" -File -ErrorAction SilentlyContinue | Remove-Item -Force

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
    Get-ChildItem -Path . -Include "*.aux","*.log","*.out","*.toc","*.bbl","*.blg" -File -ErrorAction SilentlyContinue | Move-Item -Destination $logDir -Force
    Write-Output "PDF compilation failed. Logs: $( Resolve-Path $logDir )"
}
