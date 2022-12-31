
@{
	RootModule            = 'PSKantan.psm1'
	ModuleVersion         = '1.1'
	Author                = 'Decimation'
	Copyright             = '(C) 2022 Read Stanton. All rights reserved.'
	PowerShellVersion     = '7.1'
	ProcessorArchitecture = 'Amd64'
	FunctionsToExport     = '*'
	CmdletsToExport       = '*'
	VariablesToExport     = '*'
	AliasesToExport       = '*'
	Description="Utilities by RDS"
	GUID                  = '452f3f44-712b-460d-8ced-88fb37aaf8d6'
	NestedModules         = @('Android', 'Utilities', 'Filesystem', 'Types')
	#ModuleList            = @('Android')
}
