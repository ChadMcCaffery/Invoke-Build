<#
.Synopsis
	Tests tasks altering others by the parameters After and Before.
#>

# These tasks are to be altered below. Imagine that they are in another script
# which is dot-sourced in here and we do not want or can modify this script.
task PreTask1 { 'In PreTask1' }
task PostTask1 { 'In PostTask1' }
task Task1 PreTask1, { 'In Task1' }, PostTask1
task Task2 { 'In Task2' }
task Task3 { 'In Task3' }

# Invoke after Task1 and Task2. NOTE: as far as tasks are invoked once, it is
# actually invoked after Task1 only.
task AfterTask -After Task1, Task2 {
	'In AfterTask'
}

# Invoke before Task1 and Task2. NOTE: as far as tasks are invoked once, it is
# actually invoked before Task1 only.
task BeforeTask -Before Task1, Task2 {
	'In BeforeTask'
}

# Invoke after Task3, fail but allow the build to survive.
task AfterTask3 -After ?Task3 {
	throw 'In AfterTask3'
}

# Invoke before Task3, fail but allow the build to survive.
task BeforeTask3 -Before ?Task3 {
	throw 'In BeforeTask3'
}
