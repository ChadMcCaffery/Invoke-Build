<#
.Synopsis
	Tests 'remove'.
#>

Import-Module .\Tools

# Synopsis: Errors on invalid arguments.
task InvalidArgument {
	($r = try {remove ''} catch {$_})
	equals $r.FullyQualifiedErrorId 'ParameterArgumentValidationErrorEmptyStringNotAllowed,Remove-BuildItem'

	($r = try {remove @()} catch {$_})
	equals $r.FullyQualifiedErrorId 'ParameterArgumentValidationErrorEmptyArrayNotAllowed,Remove-BuildItem'

	($r = try {remove .} catch {$_})
	equals "$r" 'Not allowed paths.'

	($r = try {remove *} catch {$_})
	equals "$r" 'Not allowed paths.'

	($r = try {remove '...***///\\\'} catch {$_})
	equals "$r" 'Not allowed paths.'

	($r = try {remove Remove.test.ps1, *} catch {$_})
	requires -Path Remove.test.ps1
	equals "$r" 'Not allowed paths.'
}

# Synopsis: Errors on locked items.
# Unix: "locked" file is removed.
task ErrorLockedFile -If (!(Test-Unix)) {
	# create a locked file
	$writer = [IO.File]::CreateText("$BuildRoot/z.txt")
	try {
		## terminating error
		($r1 = try {remove z.txt} catch {$_})
		equals $r1.FullyQualifiedErrorId Remove-BuildItem
		assert ("$r1" -match '[\\/]z\.txt')

		## non-terminating error
		# this will be removed
		Set-Content z.2.txt 42
		requires -Path z.2.txt
		# call with good and locked files
		$r = remove z.2.txt, z.txt -ea 2 -ev r2 2>&1
		#! just message or IB source leaks to output
		"$r"
		# good is removed
		assert (!(Test-Path z.2.txt))
		# locked error, two ways of catching
		equals $r.FullyQualifiedErrorId 'RemoveFileSystemItemIOError,Microsoft.PowerShell.Commands.RemoveItemCommand'
		equals $r2[0].FullyQualifiedErrorId 'RemoveFileSystemItemIOError,Microsoft.PowerShell.Commands.RemoveItemCommand'
	}
	finally {
		$writer.Close()
		remove z.txt
	}
}

# Synopsis: Work around Test-Path *\X when X is hidden
# https://github.com/PowerShell/PowerShell/issues/6473
# Test-Path with wildcards cannot find anything hidden.
# Unix: No .Attributes.
task HiddenInSubdirectory -If (!(Test-Unix)) {
	# new hidden item in a subdirectory
	remove z
	$item = mkdir z\hidden
	$item.Attributes = $item.Attributes -bor [System.IO.FileAttributes]::Hidden

	# OK, it exists
	$r = Test-Path z\hidden
	equals $r $true

	# KO, Test-Path *\hidden fails to find it,
	# hence the issue with using Test-Path
	$r = Test-Path *\hidden
	equals $r $false

	# `remove` works around and removes
	remove *\hidden

	# it was removed
	$r = Test-Path z\hidden
	equals $r $false

	remove z
}

# Support -Verbose, #147
task Verbose {
	function Write-Verbose {
		param($Message, [switch]$Verbose)
		$log.Add($Message)
	}

	# with Verbose
	$log = [System.Collections.Generic.List[object]]@()
	$env:Issue147 = 1
	remove env:Issue147*, Issue147 -Verbose
	$log
	equals 2 $log.Count
	equals 'remove: removing env:Issue147*' $log[0]
	equals 'remove: skipping Issue147' $log[1]

	# without Verbose
	$log = [System.Collections.Generic.List[object]]@()
	$env:Issue147 = 1
	remove env:\Issue147*, Issue147
	equals 0 $log.Count
}
