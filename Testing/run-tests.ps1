param(
    [string]$ImageName,
    [switch]$Build,
    [string]$Path = "Testing/Tests",
    [string]$ResultsDir = "Testing/TestResults",
    [switch]$SkipPull
)

# Local wrapper for the shared test image.
#
# Default behavior mirrors CI: pull the published GHCR image, mount the repo,
# run the suite from Testing/Tests, and write a console log plus JUnit XML into
# Testing/TestResults.

$ErrorActionPreference = "Stop"

$testingRoot = $PSScriptRoot
$repoRoot = Split-Path -Parent $testingRoot
$configFile = "Testing/.busted"
$coverageConfigFile = "Testing/.luacov"
$resultsPath = Join-Path $repoRoot $ResultsDir
$consoleLogPath = Join-Path $resultsPath "busted.log"
$junitPath = Join-Path $resultsPath "junit.xml"
$coverageReportPath = Join-Path $resultsPath "luacov.report.out"
$coverageStatsPath = Join-Path $resultsPath "luacov.stats.out"

New-Item -ItemType Directory -Force -Path $resultsPath | Out-Null
Remove-Item -Force -ErrorAction SilentlyContinue $consoleLogPath, $junitPath, $coverageReportPath, $coverageStatsPath

function Get-DefaultImageName {
    $remoteUrl = git -C $repoRoot remote get-url origin 2>$null
    if ($LASTEXITCODE -eq 0 -and $remoteUrl) {
        if ($remoteUrl -match 'github\.com[:/](?<owner>[^/]+)/(?<repo>[^/.]+?)(?:\.git)?$') {
            $owner = $matches.owner.ToLowerInvariant()
            return "ghcr.io/$owner/ellesmereui-tests:latest"
        }
    }

    return "ellesmereui-tests:latest"
}

if (-not $ImageName) {
    $ImageName = Get-DefaultImageName
}

if ($Build) {
    Write-Host "Building Podman test image '$ImageName'..."
    podman build -f "$testingRoot/Containerfile" -t $ImageName $repoRoot
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
} elseif (-not $SkipPull) {
    Write-Host "Pulling test image '$ImageName'..."
    podman pull $ImageName
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
}

$mountPath = ($repoRoot -replace "\\", "/")
$commonArguments = @(
    "run",
    "--rm",
    "-v", "${mountPath}:/workspace:Z",
    "-w", "/workspace",
    $ImageName
)

Write-Host "Running busted in Podman for '$Path'..."
$plainArguments = $commonArguments + @(
    "-f", $configFile,
    "--coverage",
    "--coverage-config-file", $coverageConfigFile,
    $Path
)
$plainOutput = & podman @plainArguments 2>&1
$plainExitCode = $LASTEXITCODE

$plainOutput | Out-Host
$plainOutput | Set-Content -Path $consoleLogPath -Encoding utf8

Write-Host "Writing JUnit report to '$junitPath'..."
$junitArguments = $commonArguments + @(
    "-f", $configFile,
    "-o", "junit",
    "-Xoutput", "Testing/TestResults/junit.xml",
    $Path
)
& podman @junitArguments
$junitExitCode = $LASTEXITCODE

$coverageArguments = @(
    "run",
    "--rm",
    "--entrypoint", "luacov",
    "-v", "${mountPath}:/workspace:Z",
    "-w", "/workspace",
    $ImageName,
    "-c", $coverageConfigFile
)
& podman @coverageArguments
$coverageExitCode = $LASTEXITCODE

$coverageSummary = $null
if (Test-Path $coverageReportPath) {
    $coverageSummary = Select-String -Path $coverageReportPath -Pattern '^Total\s+' | Select-Object -First 1
}

Write-Host "Console log: $consoleLogPath"
Write-Host "JUnit XML:   $junitPath"
Write-Host "Coverage:    $coverageReportPath"
if ($coverageSummary) {
    Write-Host $coverageSummary.Line
}

if ($plainExitCode -ne 0) {
    exit $plainExitCode
}

if ($coverageExitCode -ne 0) {
    exit $coverageExitCode
}

exit $junitExitCode