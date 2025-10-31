# This script is for building a LaTeX document located in the project root directory.
# It runs pdflatex and bibtex as needed, captures logs, and organizes output files
# This script assumes that pdflatex and bibtex are installed and available in the system PATH.
# Also, don't worry about moving this script anywhere. It works out the box from this location.

# This script is for Windows users, if you are on Linux or macOS, please use the corresponding shell script in build_interim.sh.

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptDir
Set-Location -Path $projectRoot

$logDir = Join-Path -Path (Get-Location) -ChildPath 'scripts.log'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null

pdflatex -interaction=nonstopmode -halt-on-error interim_report.tex 2>&1 | Tee-Object -FilePath (Join-Path $logDir 'pdflatex-pass1.scripts.log')
if (Test-Path interim_report.aux) { bibtex interim_report 2>&1 | Tee-Object -FilePath (Join-Path $logDir 'bibtex.scripts.log') }
pdflatex -interaction=nonstopmode -halt-on-error interim_report.tex 2>&1 | Tee-Object -FilePath (Join-Path $logDir 'pdflatex-pass2.scripts.log')
pdflatex -interaction=nonstopmode -halt-on-error interim_report.tex 2>&1 | Tee-Object -FilePath (Join-Path $logDir 'pdflatex-pass3.scripts.log')

Get-ChildItem -Path . -Include *.aux,*.log,*.out,*.toc,*.bbl,*.blg -File -ErrorAction SilentlyContinue | Move-Item -Destination $logDir -Force

Write-Output "Done. Output: $(Resolve-Path .\interim_report.pdf). Logs: $(Resolve-Path $logDir)"
