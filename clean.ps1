Param(
    [string] $modName, # mod folder name
    [string] $srcDirectory, # the path that contains your mod's .XCOM_sln
    [string] $sdkPath, # the path to your SDK installation ending in "XCOM 2 War of the Chosen SDK"
    [string] $gamePath # the path to your XCOM 2 installation ending in "XCOM2-WaroftheChosen"
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version 3.0

# Deletes all cached build artifacts


Write-Host "Removing $sdkPath/XComGame/lastBuildDetails.json"
Remove-Item -Force "$sdkPath/XComGame/lastBuildDetails.json" -WarningAction SilentlyContinue

Write-Host "Removing $srcDirectory/BuildCache"
Remove-Item -Recurse -Force "$srcDirectory/BuildCache" -WarningAction SilentlyContinue

Write-Host "Removing $sdkPath/Development/Src/*"
Remove-Item -Recurse -Force "$sdkPath/Development/Src/*" -WarningAction SilentlyContinue

Write-Host "Removing $sdkPath/XComGame/Mods/*"
Remove-Item -Recurse -Force "$sdkPath/XComGame/Mods/*" -WarningAction SilentlyContinue

Write-Host "Removing $gamePath/XComGame/Mods/$modName"
Remove-Item -Recurse -Force "$gamePath/XComGame/Mods/$modName" -WarningAction SilentlyContinue

Write-Host "Removing $sdkPath/XComGame/Published"
Remove-Item -Recurse -Force "$sdkPath/XComGame/Published" -WarningAction SilentlyContinue

Write-Host "Removing $sdkPath/XComGame/Script/*.u"
Remove-Item -Force "$sdkPath/XComGame/Script/*.u" -WarningAction SilentlyContinue

Write-Host "Removing $sdkPath/XComGame/ScriptFinalRelease/*.u"
Remove-Item -Force "$sdkPath/XComGame/ScriptFinalRelease/*.u" -WarningAction SilentlyContinue

Write-Host "Removing $sdkPath/XComGame/Content/LocalShaderCache-PC-D3D-SM4.upk"
Remove-Item -Force "$sdkPath/XComGame/Content/LocalShaderCache-PC-D3D-SM4.upk" -WarningAction SilentlyContinue

Write-Host "Cleaned"
