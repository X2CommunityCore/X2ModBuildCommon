function CleanModAssetCookerOutput (
    [string] $sdkPath, # the path to your SDK installation ending in "XCOM 2 War of the Chosen SDK"
    [string] $modNameCanonical,
    [string[]] $sourceAssetsPaths # Intended for ContentForCook and CollectionMaps, but any folder that has .upk or .umap files will work
) {
    # TODO: duplicates the logic in build_common.ps1
    $actualTfcSuffix = "_$($modNameCanonical)_DLCTFC_XPACK_"
    $cookerOutputPath = [io.path]::combine($sdkPath, 'XComGame', 'Published', 'CookedPCConsole')

    if (!(Test-Path $cookerOutputPath)) {
        Write-Host "No Published\CookedPCConsole directory - nothing to clean"
        return
    }

    $modMaps = @()
    $modPackages = @()

    foreach ($assetPath in $sourceAssetsPaths) {
        Write-Host "Asset path: $assetPath"

        if (!(Test-Path $assetPath)) { continue }

        $pathMaps = @(Get-ChildItem -Path $assetPath -Filter '*.umap' -Recurse -Force | Select-Object -ExpandProperty BaseName)
        $pathPackages = @(Get-ChildItem -Path $assetPath -Filter '*.upk' -Recurse -Force | Select-Object -ExpandProperty BaseName)

        Write-Host "Path maps: $pathMaps"
        Write-Host "Path packages: $pathPackages"

        $modMaps += $pathMaps
        $modPackages += $pathPackages
    }

    Write-Host "Removing SeekFree maps: $modMaps"
    $modMaps | ForEach-Object { Remove-Item -Force -LiteralPath "$cookerOutputPath\$_.upk" -WarningAction SilentlyContinue -ErrorAction SilentlyContinue }

    Write-Host "Removing SeekFree standalone packages: $modPackages"
    $modPackages | ForEach-Object { Remove-Item -Force -LiteralPath "$cookerOutputPath\$($_)_SF.upk" -WarningAction SilentlyContinue -ErrorAction SilentlyContinue }

    Write-Host "Removing TFCs: $actualTfcSuffix"
    Remove-Item -Force "$cookerOutputPath\*$actualTfcSuffix.tfc" -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
    
    Write-Host "Removing GuidCache"
    Remove-Item -Force "$cookerOutputPath\GuidCache_$modNameCanonical.upk" -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
}
