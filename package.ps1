$ErrorActionPreference = "Stop"
Set-StrictMode -Version 3.0
Add-Type -Assembly 'System.IO.Compression.FileSystem'

$junctionVersion = "v1.0.0"
$junctionLink = "https://github.com/robojumper/free-junc/releases/download/$junctionVersion/free-junc.exe.zip"

$myDirectory = Split-Path $MyInvocation.MyCommand.Path
$targetDir = Join-Path -Path $myDirectory "target"
$packageDir = Join-Path -Path $targetDir "package"
$cacheDir = Join-Path -Path $targetDir "cache"

function Ensure-Directory {
    [CmdletBinding()]
    param ([Parameter(ValueFromPipeline)] [string] $dir)
    process {
        if (-not (Test-Path $dir)) {
            New-Item -Path $dir -ItemType Directory
        }
    }
}

Ensure-Directory $targetDir
Ensure-Directory $packageDir
Ensure-Directory $cacheDir

$junctionCacheDir = "$cacheDir\free-junc-$($junctionVersion)\"
$junctionZip = "$($junctionCacheDir)free-junc.exe.zip"
$junctionExe = "$($junctionCacheDir)free-junc.exe"

if (-not (Test-Path -Path $junctionZip)) {
    Ensure-Directory $junctionCacheDir
    Invoke-WebRequest -UseBasicParsing -Uri $junctionLink -OutFile $junctionZip
}

if (-not (Test-Path -Path $junctionExe)) {
    [System.IO.Compression.ZipFile]::ExtractToDirectory($junctionZip, $junctionCacheDir)
}

& "MSBuild.exe" ".\src\cs\X2ModBuildCommon.csproj"

if (Test-Path -Path "$packageDir\*") {
    Remove-Item -Force -Recurse -Path "$packageDir\*" -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
}

Copy-Item -Force "$myDirectory\LICENSE" "$packageDir\" -WarningAction SilentlyContinue
Copy-Item -Force "$myDirectory\README.md" "$packageDir\" -WarningAction SilentlyContinue
Copy-Item -Force "$junctionExe" "$packageDir\junction.exe" -WarningAction SilentlyContinue
Copy-Item -Force "$cacheDir\X2ModBuildCommon\X2ModBuildCommon.dll" "$packageDir\" -WarningAction SilentlyContinue
Copy-Item -Force "$myDirectory\src\ps\*.ps1" "$packageDir\" -WarningAction SilentlyContinue
Copy-Item -Force "$myDirectory\assets\*" "$packageDir\" -WarningAction SilentlyContinue
