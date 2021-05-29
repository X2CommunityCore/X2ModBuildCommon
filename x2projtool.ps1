Param(
    [string]$projDirectory, # the path that contains the mod's .x2proj
	[string]$subcommand, # one of `check`, `update`
    [string[]] $ignoreOnDisk = "", # we pretend these files don't exist on disk
    [string[]] $ignoreInProj = "" # we pretend we didn't see these files in the project
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version 3.0 | Out-Null

function NormalizeAndFilter {
    [CmdletBinding()]
    param([string[]] $ToIgnore, [Parameter(ValueFromPipeline = $true)] $obj)
    process {
        $obj = $obj -Replace '/','\'
        $obj = $obj -Replace '^\.\\'
        #Write-Host "Checking $obj"
        $ignored = @($ToIgnore | Where-Object -FilterScript { $obj -Match "^$($_)([\\]|$).*"}).Count -gt 0
        if ($ignored) {
            $obj = $null
        }
        $obj
    }
}

class Tool {
    [string] $projDirectory
    [string] $projFile
    [string] $namespace
    [object] $nsmgr
    [xml] $projXml

    [string[]] $physFolders
    [string[]] $physFiles

    Tool(
		[string]$projDirectory,
        [string[]]$ignoreDisk
	){
		$this.projDirectory = $projDirectory

        # Resolve-Path makes things relative with this
        Push-Location $projDirectory | Out-Null

        $this.physFolders = Get-ChildItem $projDirectory -directory -recurse |
            Where-Object { (Get-ChildItem $_.fullName | Measure-Object).count -ne 0 } |
            Select-Object -expandproperty FullName |
            ForEach-Object { Resolve-Path -Relative $_ } |
            NormalizeAndFilter -ToIgnore $ignoreDisk |
            Sort-Object


        $this.physFiles = Get-ChildItem $projDirectory -file -recurse -exclude "*.x2proj" |
            Select-Object -expandproperty FullName |
            ForEach-Object { Resolve-Path -Relative $_ } |
            NormalizeAndFilter -ToIgnore $ignoreDisk |
            Sort-Object

        Pop-Location | Out-Null

        $this.projFile = Get-ChildItem $projDirectory -file "*.x2proj" | Select-Object -ExpandProperty FullName

        [xml]$this.projXml = Get-Content -Path $this.projFile
        $this.nsmgr = [System.XML.XmlNamespaceManager]::new([System.XML.NameTable]::new())
        $this.namespace = "http://schemas.microsoft.com/developer/msbuild/2003"
        $this.nsmgr.AddNamespace("vs", $this.namespace) | Out-Null
	}

    [string[]]GetItemList($kind, $ignoreInProj) {
        $xpath = "/vs:Project/vs:ItemGroup/vs:$($kind)"
        $nodes = $this.projXml.SelectNodes($xpath, $this.nsmgr)
        $items = $nodes |
            ForEach-Object { $_.GetAttributeNode("Include").Value } |
            NormalizeAndFilter $ignoreInProj |
            Sort-Object
        if ($kind -eq "Folder") {
            $items = $items | ForEach-Object { $_ -Replace "\\$" }
        }
        return @($items)
    }

    [object]InsertItemList($kind, $list, $prev) {
        $group = $this.projXml.CreateElement("ItemGroup", $this.namespace)
        $list | ForEach-Object {
            $folderElem = $this.projXml.CreateElement($kind, $this.namespace)
            $attrib = $this.projXml.CreateAttribute("Include")
            $attrib.Value = "$_"
            $folderElem.Attributes.Append($attrib) | Out-Null
            $group.AppendChild($folderElem) | Out-Null
        }
        $prev.ParentNode.InsertAfter($group, $prev) | Out-Null
        return $group
    }

    [bool]RunDiff($disk, $proj, $kind) {
        $diff = @(Compare-Object -ReferenceObject $disk -DifferenceObject $proj)
        if ($diff.Count -gt 0) {
            Write-Host -ForegroundColor Red "Error: The .x2proj file contains an incorrect $kind list."
    
            $left = @($diff | Where-Object -Property "SideIndicator" -EQ -Value "<=")
            if ($left.Count -gt 0) {
                Write-Host "The following $kind are only present in the project file:"
                $left | ForEach-Object { Write-Host "    $($_.InputObject)" }
            }
    
            $right = @($diff | Where-Object -Property "SideIndicator" -EQ -Value "=>")
            if ($right.Count -gt 0) {
                Write-Host "The following $kind are only present on disk:"
                $right | ForEach-Object { Write-Host "    $($_.InputObject)" }
            }
            return $false
        }
        return $true
    }
}

function Invoke-Check($projDirectory, $ignoreOnDisk, $ignoreInProj) {
    $tool = [Tool]::new($projDirectory, $ignoreOnDisk)
    $projFolders = $tool.GetItemList("Folder", $ignoreInProj)
    $projFiles = $tool.GetItemList("Content", $ignoreInProj)

    $ok = $tool.RunDiff($projFolders, $tool.physFolders, "folders")
    $ok = $tool.RunDiff($projFiles, $tool.physFiles, "files") -and $ok

    return $ok
}

function Invoke-Update($projDirectory, $ignoreOnDisk) {
    $tool = [Tool]::new($projDirectory, $ignoreOnDisk)

    $xpath = "/vs:Project/vs:ItemGroup"
    $nodes = $tool.projXml.SelectNodes($xpath, $tool.nsmgr)
    $nodes | ForEach-Object {
        $_.ParentNode.RemoveChild($_) | Out-Null
    }

    $xpath = "/vs:Project/vs:PropertyGroup"
    $prevNode = $tool.projXml.SelectNodes($xpath, $tool.nsmgr)[0]

    # create folders
    $prevNode = $tool.InsertItemList("Folder", $tool.physFolders, $prevNode)
    # create files
    $prevNode = $tool.InsertItemList("Content", $tool.physFiles, $prevNode)

    # write to output
    try
    {
        $ioWriter = [System.IO.StreamWriter]::new($tool.projFile)
        $xmlWriter = [System.XMl.XmlTextWriter]::new($ioWriter)
        $xmlWriter.Formatting = "indented" 
        $xmlWriter.Indentation = 2
        $tool.projXml.WriteContentTo($xmlWriter) 
    }
    finally
    {
        $ioWriter.close()
    }
}

switch ($subcommand) {
    "check" {
        $ok = Invoke-Check $projDirectory $ignoreOnDisk $ignoreInProj
        if (-not $ok) {
            $host.SetShouldExit(1)
            exit
        }
    }
    "update" {
        Invoke-Update $projDirectory $ignoreOnDisk
        $ok = Invoke-Check $projDirectory $ignoreOnDisk $ignoreInProj
        if (-not $ok) {
            Write-Host -ForegroundColor Red "Error: Internal tool error: Checking the updated project file failed."
            Write-Host -ForegroundColor Red "This is a bug in x2projtool. Please report it at:"
            Write-Host "    https://github.com/X2CommunityCore/X2ModBuildCommon/issues/new"
            $host.SetShouldExit(1)
            exit
        }
    }
    "" { throw "Missing subcommand" }
    default { throw "Unknown command" }
}
