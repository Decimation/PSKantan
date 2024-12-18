
# region Objects

function ConvertTo-Array {
	param (
		[Parameter(Mandatory = $true)]
		[hashtable]$Value,
		[switch]$RemoveNull
	)
	
	$k = [array]$Value.Keys
	$v = [array]$Value.Values
	$r = @()
	for ($i = 0; $i -lt $v.Count; $i++) {
		$r1 = @($k[$i], $v[$i])
		if ($RemoveNull) {
			$r1 = $r1 -notlike $null
		}

		$r += $r1
	}
	return $r
}

function Get-SubstringBetween {
	param ([string]$value,
		[string]$a,
		[string]$b)
	
	$posA = $value.IndexOf($a, [System.StringComparison]::Ordinal)
	$posB = $value.LastIndexOf($b, [System.StringComparison]::Ordinal)
	
	$inv = -1
	
	if ($posA -eq $inv -or $posB -eq $inv) {
		return [String]::Empty
	}
	
	$adjustedPosA = $posA + $a.Length
	$pred = $adjustedPosA -ge $posB ? [String]::Empty: $value[$adjustedPosA .. $posB]
	$sz = [string]::new([char[]]$pred)
	
	if ($sz.EndsWith($b)) {
		$sz = $sz.Substring(0, $sz.LastIndexOf($b))
	}
	return $sz
}

function Convert-ObjToHashTable {
	[CmdletBinding()]
	[outputtype([hashtable])]
	param (
		[parameter(Mandatory = $true, ValueFromPipeline = $true)]
		[pscustomobject]$Object
	)
	process {
		$HashTable = @{
		}
		$ObjectMembers = Get-Member -InputObject $Object -MemberType *Property
		foreach ($Member in $ObjectMembers) {
			$HashTable.$($Member.Name) = $Object.$($Member.Name)
		}
		return $HashTable
	}
	
	
}
function Convert-HashtableToSplat {
	[CmdletBinding()]
	[outputtype([array])]
	param (
		[parameter(Mandatory = $true, ValueFromPipeline = $true)]
		[hashtable]$HashTable,
		[switch]$ExcludeNullValues,
		[switch]$TrueAsSwitch,
		[switch]$SeparateParameterArgument
	)


	process {
		$Splat = @()
		foreach ($key in $HashTable.Keys) {
			$value = $HashTable[$key]
			$splatAdd = @($key)
			
			

			if ($ExcludeNullValues -and $value -eq $null) {
				continue
			}
			
			if ($TrueAsSwitch -and $value -is [bool] -and $value) {
				
			}
			else {
				if ($key -eq '') {
					$splatAdd = $value
				}
				else {
					$splatAdd += $value
				}
			}
			
			if ($SeparateParameterArgument) {
				$splatAdd = $splatAdd -join ' '
			}
			
			$Splat += $splatAdd
		}
		
		# [array]::Reverse($Splat)

		return $Splat
	}
}

function Convert-Obj {
	param (
		$a,
		$t
	)

	if ($a -is [System.Management.Automation.SwitchParameter]) {
		if (@([int]) -contains $t) {
			return $a ? 1 : 0
		}
	}

	$a2 = $null
	try {
		$a2 = [System.Management.Automation.LanguagePrimitives]::ConvertTo($a, ($t2))
	}
	catch {
		$a2 = $a -as $t
	}
	return $a2

}

Set-Alias cast Convert-Obj
Set-Alias conv Convert-Obj

function Convert-ObjFromHashTable {
	param (
		[parameter(Mandatory = $true)]
		$pred,
		[parameter(Mandatory = $false)]
		$t
	)
	
	$o = New-Object pscustomobject
	$o | Add-Member $pred
	
	if ($t) {
		$o = Convert-Obj $o $t
	}
	try {
		return $o -as $t
	}
	catch {
		
		return $o
	}
	
}



function Get-Bytes {
	[outputtype([byte[]])]
	param (
		[Parameter(Mandatory = $true, ValueFromPipeline)]
		$x,
		[Parameter(Mandatory = $false)]
		$encoding
	)

	process {

		$isStr = $x -is [string]
		$info1 = @()
		$rg = @()
		
		if ($isStr) {
			if (!($encoding)) {
				$encoding = [System.Text.Encoding]::Default
			}
			
			$info1 += $encoding.EncodingName
			$rg = $encoding.GetBytes($x)
		}
		else {
			$rg = [System.BitConverter]::GetBytes($x)
		}
		
		<# Write-Host "[$($typeX.Name)]" -NoNewline -ForegroundColor Yellow
		
		if ($info1.Length -ne 0) {
			Write-Host ' | ' -NoNewline
			Write-Host "$($info1 -join ' | ')" -NoNewline
		}
		
		Write-Host ' | ' -NoNewline
		Write-Host "$x" -ForegroundColor Cyan #>
		
		return $rg
	}
}



function IsReal {
	param (
		$x
	)
	$c = typecodeof $x
	
	return IsInRange -a $c -max ([System.TypeCode]::Decimal) -min ([System.TypeCode]::Single)
}

function IsInteger {
	param (
		$x
	)
	$c = typecodeof $x
	
	return IsInRange -a $c -max ([System.TypeCode]::UInt64) -min ([System.TypeCode]::SByte)
}

function IsInRange {
	param (
		$a,
		$min,
		$max,
		[switch]$noninc
	)

	
	if ($noninc) {
		return $a -gt $min -and $a -lt $max
	}
	return $a -ge $min -and $a -le $max
}

function IsNumeric {
	param (
		$x
	)
	return (IsInteger $x) -or (IsReal $x)
}


function typename {
	[CmdletBinding()]
	param (
		[Parameter(ValueFromPipeline)]
		$x
	)

	process {

		$y = ($x | Get-Member)[0].TypeName
		return $y
	}
	
}

function typeof {
	[CmdletBinding()]
	[OutputType([type])]
	param (
		[Parameter(Mandatory, Position = 0, ValueFromPipeline)]
		$InputObject
	)

	process {

		#return [type]::GetType((typename $x))
		return $InputObject.GetType()
	}
}

function typecodeof {
	[CmdletBinding()]
	[OutputType([System.TypeCode])]
	param (
		[Parameter(Mandatory, Position = 0, ValueFromPipeline)]
		$InputObject
	)
	process {
		return (typeof $InputObject).TypeCode

	}
}

# endregion




# region Collection operations

function Flatten($a) {
	, @($a | ForEach-Object { $_ })
}

function Get-Difference {
	param (
		[Parameter(Mandatory = $true)]
		[object[]]$a,
		[Parameter(Mandatory = $true)]
		[object[]]$b
	)
	
	return $b | Where-Object {
		($a -notcontains $_)
	}
}

function Get-Intersection {
	param (
		[Parameter(Mandatory = $true)]
		[object[]]$a,
		[Parameter(Mandatory = $true)]
		[object[]]$b
	)
	return Compare-Object $a $b -PassThru -IncludeEqual -ExcludeDifferent
}

function Get-Union {
	param (
		[Parameter(Mandatory = $true)]
		[object[]]$a,
		[Parameter(Mandatory = $true)]
		[object[]]$b
	)
	return Compare-Object $a $b -PassThru -IncludeEqual
}

function New-List {
	param (
		[Parameter(Mandatory = $true, Position = 0)]
		$x
	)
	return New-Object "System.Collections.Generic.List[$x]"
}


function Linq-Where {
	
	param (
		[Parameter(Mandatory, Position = 0)]
		$Value,
		[Parameter(ValueFromRemainingArguments, Position = 1)]
		$Predicate
	)
	process {
		$Predicate = [func[object, bool]]$Predicate

		return Invoke-Linq -Name "Where" $Value ([System.Func[object, bool]] $Predicate)
	}
}

function Linq-First {
	param (
		[Parameter(ValueFromPipeline)]
		$Value,
		[Parameter()]
		$Predicate
	)
	process {
		return Invoke-Linq -Name "First" $Value ([System.Func[object, bool]] $Predicate)
	}
}

function Linq-Select {
	param (
		[Parameter(ValueFromPipeline)]
		$Value,
		[Parameter()]
		$Predicate
	)
	process {
		$Predicate = [func[object, object]]$Predicate
		return Invoke-Linq -Name "Select" $Value ([System.Func[object, bool]] $Predicate)

	}
}

function Linq-TakeLast {
	param($Value, $Count)
	return Invoke-Linq -Name "TakeLast" -Value $Value -Arg1 $Count
}

function Linq-Skip {
	param($Value, $Count)
	return Invoke-Linq -Name "Skip" -Value $Value -Arg1 $Count
}

function Invoke-Linq {
	param (
		$Value, $Name, $Arg1
	)
	[System.Linq.Enumerable]::$Name($Value, $Arg1)
}

function New-RandomArray {
	param (
		[Parameter(Mandatory = $true)]
		[int]$c
	)
	$rg = [byte[]]::new($c)
	[System.Random]::Shared.NextBytes($rg)
	return $rg
}

# endregion



function New-QVar {
	param (
		[Parameter(Mandatory = $true)]
		[string]$name,
		[Parameter(Mandatory = $true)]
		$val,
		[Parameter(Mandatory = $false)]
		[string]$scope = 'Global', 
		[Parameter(Mandatory = $false)]
		[System.Management.Automation.ScopedItemOptions]
		$opt = [System.Management.Automation.ScopedItemOptions]::None
	)
	

	$sp = @{
		'Scope'  = $scope
		'Name'   = $name
		'Value'  = $val
		'Option' = $opt
		
	}
	
	Set-Variable @sp -ErrorAction Ignore
}

function Set-SpecialVar {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string][ValidateNotNullOrEmpty()]$n,

		[Parameter(Mandatory = $true)]
		[string][ValidateNotNullOrEmpty()]$v,
		
		[Parameter(Mandatory = $true)]
		[System.Management.Automation.ScopedItemOptions]$o,

		[Parameter(Mandatory = $false)]
		[string]$s
	)

	if (!($s)) {
		$s = 'global'
	}

	$errPref = $ErrorActionPreference
  
	$ErrorActionPreference = 'SilentlyContinue'

	try {
		Set-Variable -Name $n -Value $v -Scope $s -Option $o
	}
	catch {
		Write-Error "Constant value $name not written"
	
	}
	finally {
		$ErrorActionPreference = $errPref
		Write-Verbose "$name = $value"
	}
	
}

function Set-Constant {
	<#
	.SYNOPSIS
		Creates constants.
	.DESCRIPTION
		This function can help you to create constants so easy as it possible.
		It works as keyword 'const' as such as in C#.
	.EXAMPLE
		PS C:\> Set-Constant a = 10
		PS C:\> $a += 13

		There is a integer constant declaration, so the second line return
		error.
	.EXAMPLE
		PS C:\> const str = "this is a constant string"

		You also can use word 'const' for constant declaration. There is a
		string constant named '$str' in this example.
	.LINK
		Set-Variable
		About_Functions_Advanced_Parameters
	#>
	[CmdletBinding()]
	param(
		[Parameter(Mandatory = $true, Position = 0)]
		[string][ValidateNotNullOrEmpty()]$name,
  
		[Parameter(Mandatory = $true, Position = 1)]
		[char][ValidateSet('=')]$link,
  
		[Parameter(Mandatory = $true, Position = 2)]
		[object][ValidateNotNullOrEmpty()]$value
  
		#[Parameter(Mandatory=$false, Position=3)]
		#[ValidateSet("r")]
		#[object][ValidateNotNullOrEmpty()]$arg,
	)

	Set-SpecialVar -n $name -v $value -o ([System.Management.Automation.ScopedItemOptions]::Constant)
}

Set-Alias const Set-Constant

function Set-Readonly {
	
	[CmdletBinding()]
	param(
		[Parameter(Mandatory = $true, Position = 0)]
		[string][ValidateNotNullOrEmpty()]$name,
  
		[Parameter(Mandatory = $true, Position = 1)]
		[char][ValidateSet('=')]$link,
  
		[Parameter(Mandatory = $true, Position = 2)]
		[object][ValidateNotNullOrEmpty()]$value
  
		#[Parameter(Mandatory=$false, Position=3)]
		#[ValidateSet("r")]
		#[object][ValidateNotNullOrEmpty()]$arg,
	)

	Set-SpecialVar -n $name -v $value -o ([System.Management.Automation.ScopedItemOptions]::ReadOnly)
}

Set-Alias readonly Set-Readonly

function New-PInvoke {
	param (
		[parameter()]
		$className, 
		[parameter()]
		$dll,
		[parameter()]
		$returnType,
		[parameter()]
		$funcName,
		[parameter()]
		$funcParams
	)


	<# using System;
		using System.Text;
		using System.Runtime.InteropServices; #>
		
	Add-Type -Namespace 'PInvoke' -Name $className -MemberDefinition @"
[DllImport("$dll", SetLastError = true, CharSet = CharSet.Unicode)]
public static extern $returnType $funcName($funcParams);
"@
	
}


function Get-ForEach {
	param (
		[Parameter(ValueFromPipeline)]
		$Value,

		[Parameter()]
		$Func,


		[switch]$Copy
	)

	
	process {
		$Value2 = @()

		for ($i = 0; $i -lt $Value.Count; $i++) {
			$t = $Value[$i]
			$r = & $Func @t

			if ($Copy) {
				$Value2 += $r
			}
			else {
				$Value[$i] = $r
			}
		}
	
		if ($Copy) {
			return $Value2
		}
		else {
			return $Value
		}
	}
}

function Get-Select {
	param (
		[Parameter(ValueFromPipeline)]
		$Value,

		[Parameter()]
		$Func

	)
	process {

		$Value2 = @()
		for ($i = 0; $i -lt $Value.Count; $i++) {
			$t = $Value[$i]
			$r = & $Func @t
			$Value2 += $r
		}
		
		return $Value2
	}
}

function Reset-HttpRequest {
	param (
		[System.Net.Http.HttpRequestMessage]$req
	)
	
	$t = $req.GetType()
	$f = $t.GetField("_sendStatus", [System.Reflection.BindingFlags]::NonPublic -bor `
			[System.Reflection.BindingFlags]::GetField -bor `
			[System.Reflection.BindingFlags]::Instance)
	$f.SetValue($req, 0)
	return $req
}