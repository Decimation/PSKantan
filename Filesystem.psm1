# region Filesystem IO
using namespace System.IO


function Get-Name {
	param (
		[Parameter(Mandatory = $true)]
		$x,
		[switch]$no_ext,
		[switch]$full_path
	)
	$fi = [System.IO.FileInfo]::new($x)
	$s = $fi.Name
	if ($no_ext) {
		$s = [System.IO.Path]::GetFileNameWithoutExtension($fi.FullName)
	}
	if ($full_path) {
		$s = Join-Path $fi.Directory $s
	}
	return $s
}

Set-Alias gn Get-Name

function OpenHere {
	Start-Process $(Get-Location)
}

function Find-Item {
	[CmdletBinding()]
	param (
		
		[Parameter(Mandatory = $true)]
		[string]$s,
		[Parameter(Mandatory = $false)]
		[System.Management.Automation.CommandTypes]$c = 'All'
	
		
	)
	
	$a = (Get-Command $s -CommandType $c).Path

	

	<# if ((Test-Command 'whereis' Application) -and (-not $a)) {
		return (whereis.exe $s)
	} #>
	
	return $a
}
	

Set-Alias whereitem Find-Item

function Search-InFiles {
	param (
		# Content filter
		[Parameter(Mandatory)]
		$ContentFilter,

		# Path filter
		[parameter(Mandatory = $false)]
		$PathFilter,

		# Path
		[parameter(Mandatory = $false)]
		$Path = '.',

		# Depth
		[Parameter(Mandatory = $false)]
		$Depth = 1,
		
		[switch]$Strict
	)
	
	if (-not $Strict) {
		$PathFilter = "*$PathFilter*"
	}
	
	$r = Get-ChildItem -Path $Path -File -Filter "$PathFilter" `
		-Recurse -Depth $Depth -ErrorAction SilentlyContinue

	$r2 = $r | ForEach-Object {
		Write-Host "$_ :`n"
		
		Select-String -Path $_ $ContentFilter
	}

	return $r2
}

Set-Alias search Search-InFiles

# endregion


function New-TempFile {
	return [System.IO.Path]::GetTempFileName()
}


function New-RandomFile {
	param (
		[Parameter(Mandatory = $true)]
		[long]$Length,
		[Parameter(Mandatory = $false)]
		[string]$File,
		[switch]$Empty
	)
	
	if (-not ($File)) {
		$File = $(New-TempFile)
	}
	
	if (-not (Test-Path $File)) {
		# New-Item -ItemType File -Path $File
		# return $false;
		
		$buf = & {
			fsutil file createnew $File $Length
		}
		Write-Host "$buf"
	}
	
	
	if (($Empty)) {
		return $File
	}

	$fp = $(Resolve-Path $File)
	$fs = [File]::OpenWrite($fp)
	$br = [System.IO.BinaryWriter]::new($fs)
	$lc = $($Length / 8)
	$ts = 0
	$i = 0
	try {
		Get-Random -Minimum $([long]::MinValue) -Maximum $([long]::MaxValue) -Count $lc | ForEach-Object -Process {
			$i++
			$br.Write([long]$_)
			$p = $br.BaseStream.Position
			$extra = $p - $Length
			
			if ($p % 50 -eq 0) {
				$br.BaseStream.Flush()
				$stat = @{
					Activity        = "Allocate $File"
					Status          = "Writing [$p / $Length] bytes [$i / $lc]"
					PercentComplete = ($i / $lc) * 100
				}
				Write-Progress @stat
			}
			if ($extra -gt 0) {
				break
			}
		}
	}
	finally {
		$fs.Dispose()
		$br.Dispose()
	}
	
	$ts = $br.BaseStream.Length
	Write-Host "Allocated $File with $ts bytes"
	return $File;
}


function Get-FileBytes {
	param (
		[Parameter(Mandatory = $true)]
		[string]$File
	)
	$b = [System.IO.file]::ReadAllBytes($File)
	return $b
}


function Get-RegistryFileType {
	param (
		[Parameter(Mandatory = $true)]
		[string]$Update
	)
	
	$s = ".$($Update.Split('.')[-1])"
	$r = Get-ItemProperty -Path "Registry::HKEY_CLASSES_ROOT\$s"
	$p = $r | Select-Object -ExpandProperty '(Default)'
	$r2 = Get-ItemProperty -Path "Registry::HKEY_CLASSES_ROOT\$p"
	
	Write-Host $r.'(default)'
	Write-Host $r.'Content Type'
	Write-Host $r.'PerceivedType'
	Write-Host $r2.'(default)'
	
	return $r
}



<#function Get-FileMetadata {
	
	<#
	Adapted from Get-FolderMetadata by Ed Wilson

	https://devblogs.microsoft.com/scripting/list-music-file-metadata-in-a-csv-and-open-in-excel-with-powershell/
	https://web.archive.org/web/20201111223917/https://gallery.technet.microsoft.com/scriptcenter/get-file-meta-data-function-f9e8d804
	>
	
	param (
		[Parameter(Mandatory = $true)]
		[string]$folder,
		[Parameter(Mandatory = $false)]
		[string]$PathFilter
		
	)
	
	$rg = New-List 'psobject'
	$a = 0
	$objShell = New-Object -ComObject Shell.Application
	$objFolder = $objShell.namespace($folder)
	
	$items = $objFolder.items()
	
	if (($PathFilter)) {
		$items = $items | Where-Object {
			$_.Name -contains $PathFilter
		}
	}
	
	foreach ($File in $items) {
		$FileMetaData = New-Object PSOBJECT
		for ($a; $a -le 266; $a++) {
			if ($objFolder.getDetailsOf($File, $a)) {
				$hash += @{
					$($objFolder.getDetailsOf($objFolder.items, $a)) =
					$($objFolder.getDetailsOf($File, $a))
				}
				$FileMetaData | Add-Member $hash
				$hash.clear()
			}
		}
		$a = 0
		#$FileMetaData
		
		$rg.Add($FileMetaData)
		
	}
	
	return $rg
}#>


function Get-SanitizedFilename {
	param (
		$origFileName, $repl = ''
	)
	$invalids = [System.IO.Path]::GetInvalidFileNameChars()
	$newName = [String]::Join($repl, $origFileName.Split($invalids, 
			[System.StringSplitOptions]::RemoveEmptyEntries)).TrimEnd('.')
	
	return $newName
}


function Get-FileNameInfo {
	param ($x) 
	
	return $($(Resolve-Path $x) -as [string]).Split('.')[0]
}