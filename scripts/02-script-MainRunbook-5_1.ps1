# Display the current working directory to verify where the runbook/script is executing from.
Write-Output "PWD = $(Get-Location)"
# List all PowerShell scripts (*.ps1) in the current directory.
# Useful for confirming that the child script is present and accessible.
Get-ChildItem . -Filter *.ps1 | Select Name
# Log a message indicating that the child script execution test is starting.
Write-Output "Testing local script call"
# Execute the child script and capture its output in the $ChildOutput variable.
$ChildOutput = .\init-test-variables_5-1.ps1
# Display the output returned by the child script.
Write-Output $ChildOutput
