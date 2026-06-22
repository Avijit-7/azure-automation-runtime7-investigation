# Display the current working directory to verify where the runbook/script is executing from.
Write-Output "PWD = $(Get-Location)"
# List all PowerShell scripts (*.ps1) in the current directory.
# Useful for confirming that the child script is present and accessible.
Get-ChildItem . -Filter *.ps1 | Select Name
# Log a message indicating that the child script execution test is starting.
#//Write-Output "Testing local script call"
# Execute the child script and capture its output in the $ChildOutput variable.
#//$ChildOutput = .\init-test-variables.ps1
# Display the output returned by the child script.
#//Write-Output $ChildOutput
# Connect to Azure using Managed Identity
Connect-AzAccount -Identity
# Variables
$ResourceGroupName = "CyberSecurityTraining"
$AutomationAccountName = "SecOpsDev"
$ChildRunbookName = "init-test-variables"
# Start the child runbook
Write-Output "Starting child runbook: $ChildRunbookName"
$Job = Start-AzAutomationRunbook `
    -ResourceGroupName $ResourceGroupName `
    -AutomationAccountName $AutomationAccountName `
    -Name $ChildRunbookName
Write-Output "Child runbook started successfully."
Write-Output "Job ID: $($Job.JobId)"
# Wait for completion
do {
    Start-Sleep -Seconds 5
    $JobStatus = Get-AzAutomationJob `
        -ResourceGroupName $ResourceGroupName `
        -AutomationAccountName $AutomationAccountName `
        -Id $Job.JobId
    Write-Output "Current Status: $($JobStatus.Status)"
} while ($JobStatus.Status -eq "Running" -or $JobStatus.Status -eq "New" -or $JobStatus.Status -eq "Activating")
# Display final status
Write-Output "Final Status: $($JobStatus.Status)"
# Retrieve output records
$OutputRecords = Get-AzAutomationJobOutput `
    -ResourceGroupName $ResourceGroupName `
    -AutomationAccountName $AutomationAccountName `
    -Id $Job.JobId
# Retrieve actual output messages
Write-Output "===== CHILD RUNBOOK OUTPUT ====="
foreach ($Record in $OutputRecords)
{
    $Output = Get-AzAutomationJobOutputRecord `
        -ResourceGroupName $ResourceGroupName `
        -AutomationAccountName $AutomationAccountName `
        -JobId $Job.JobId `
        -Id $Record.StreamRecordId

    Write-Output $Output.Value
    Write-Output $Output.Value.Message
}
