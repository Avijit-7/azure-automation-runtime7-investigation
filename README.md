# Azure Automation Runtime Environment 7.x Investigation

## Overview

While testing Azure Automation Runtime Environment 7.x on Hybrid Workers, I encountered an unexpected behavior.

A parent runbook was able to call a local child script successfully in PowerShell 5.1, but the same implementation failed when executed using Runtime Environment 7.x.

The following error was observed:

```text
The term '.\init-test-variables.ps1' is not recognized as a name of a cmdlet,
function, script file, or executable program.
```

This investigation explores:

- Why the behavior differs between PowerShell 5.1 and Runtime Environment 7.x
- How child runbooks are executed in Azure Automation
- Authentication considerations
- Hybrid Worker execution behavior
- Recommended migration patterns for Runtime Environment 7.x

---

## Environment

| Component | Version |
|------------|------------|
| Azure Automation | Cloud |
| PowerShell | 5.1 |
| PowerShell | 7.4 |
| PowerShell | 7.6 |
| Execution Target | Hybrid Worker |
| Execution Target | Azure Cloud (ACI) |

---

## Problem Statement

The following implementation worked successfully in PowerShell 5.1:

```powershell
$ChildOutput = .\init-test-variables.ps1
```

However, the same pattern failed in Runtime Environment 7.x with:

```text
The term '.\init-test-variables.ps1' is not recognized...
```

This raised an important question:

Why does local child script execution work in PowerShell 5.1 but fail in Runtime Environment 7.x?

---

## Execution Architecture

### PowerShell 5.1

```text
Main Runbook
    |
    +--> .\child.ps1
            |
            +--> Same Process
            +--> Same Context
```

### Runtime Environment 7.x

```text
Main Runbook
    |
    +--> Start-AzAutomationRunbook
                |
                +--> Separate Job
                +--> Separate Context
                +--> Separate Authentication
```

### Key Difference

PowerShell 5.1 allows local script execution within the same process and execution context.

Runtime Environment 7.x introduces stronger execution isolation and encourages child runbooks to be executed as independent Azure Automation jobs.

---

## Lab Setup

### Step 1

Created an Azure Automation Account.

### Step 2

Created a child script:

```powershell
$CommonVars = @{
    Message = "Hello from child runbook"
}

return $CommonVars
```

### Step 3

Created a parent runbook:

```powershell
Write-Output "PWD = $(Get-Location)"

Write-Output "Testing local script call"

$ChildOutput = .\init-test-variables.ps1

Write-Output $ChildOutput
```

### Step 4

Executed the runbook using PowerShell 5.1.

Result:

```text
Success
```

### Step 5

Executed the same runbook using Runtime Environment 7.x.

Result:

```text
Failure
```

---

## Error Analysis

Job Stream Output:

```text
PWD = C:\Packages\Plugins\Microsoft.Azure.Automation.HybridWorker...

Testing local script call

The term '.\init-test-variables.ps1' is not recognized...
```

The current working directory was:

```text
C:\Packages\Plugins\Microsoft.Azure.Automation.HybridWorker...
```

PowerShell attempted to locate:

```powershell
.\init-test-variables.ps1
```

inside that directory.

Since the file did not exist there, PowerShell was unable to locate it and execution failed.

---

## Root Cause Analysis

Initially, the issue appeared to be a Runtime Environment 7.x defect.

Investigation showed that the failure was actually caused by execution context differences.

In PowerShell 5.1:

- Local script invocation was supported.
- The child script was available in the execution environment.
- Parent and child execution remained within the same context.

In Runtime Environment 7.x:

- Execution occurs in an isolated runtime environment.
- Local script files are not automatically available.
- Relative path execution cannot assume the child script exists.

Therefore:

```powershell
.\init-test-variables.ps1
```

is no longer a reliable pattern.

The issue was caused by execution context isolation rather than a platform defect.

---

## Recommended Solution

Microsoft recommends executing child runbooks using:

```powershell
Start-AzAutomationRunbook
```

Example:

```powershell
Connect-AzAccount -Identity

$Job = Start-AzAutomationRunbook `
    -ResourceGroupName $ResourceGroupName `
    -AutomationAccountName $AutomationAccountName `
    -Name "init-test-variables"
```

This creates a dedicated Azure Automation job for the child runbook.

---

## Key Findings

### Finding 1 – Child Runbooks Execute as Separate Jobs

When using:

```powershell
Start-AzAutomationRunbook
```

Azure Automation creates:

- A Parent Job
- A Child Job

Each receives its own Job ID.

```text
Parent Runbook
    |
    +--> Child Runbook
            |
            +--> Separate Job ID
```

---

### Finding 2 – Child Runbooks Do Not Automatically Run on the Same Hybrid Worker

Running the parent on a Hybrid Worker does not automatically cause the child runbook to execute on that same worker.

Example:

```powershell
Start-AzAutomationRunbook -Name "init-test-variables"
```

To guarantee Hybrid Worker execution:

```powershell
Start-AzAutomationRunbook `
    -Name "init-test-variables" `
    -RunOn "HybridWorkerName"
```

---

### Finding 3 – Authentication Is Required

Before starting another runbook:

```powershell
Connect-AzAccount -Identity
```

must be performed.

Without authentication:

```powershell
Start-AzAutomationRunbook
```

cannot communicate with Azure Automation.

---

### Finding 4 – Authentication Is Not Shared

Authentication established in one runbook is not automatically inherited by another runbook.

Each runbook should establish its own Azure authentication context.

---

### Finding 5 – Runtime Environment 7.x Introduces Stronger Isolation

PowerShell 5.1 implementations often relied on shared initialization patterns.

Examples:

- Authentication runbooks
- Variable initialization runbooks
- Shared configuration scripts
- Key Vault retrieval scripts

These assumptions should be reviewed when migrating to Runtime Environment 7.x.

---

## Migration Checklist

Before migrating from PowerShell 5.1 to Runtime Environment 7.x:

- Verify all local child script calls
- Remove assumptions about shared authentication
- Validate Hybrid Worker execution paths
- Test initialization runbooks
- Review relative-path dependencies
- Validate output retrieval logic
- Treat each runbook as an independent workload

---

## Lessons Learned

- Do not assume child runbooks inherit the parent execution environment.
- Do not assume authentication is shared.
- Always verify execution location.
- Explicitly specify Hybrid Workers when required.
- Validate legacy PowerShell 5.1 patterns before migration.
- Runtime Environment 7.x should be treated as a more isolated execution model.

---

## Conclusion

The issue was not caused by a defect in Azure Automation Runtime Environment 7.x.

The failure occurred because the child script was not available within the Runtime Environment 7.x execution context.

Traditional local child script invocation patterns that worked in PowerShell 5.1 should be revalidated when migrating to Runtime Environment 7.x.

The recommended approach is:

- Use `Start-AzAutomationRunbook`
- Treat child runbooks as independent jobs
- Establish authentication independently
- Explicitly specify Hybrid Worker execution when required

Understanding these execution boundaries is critical when modernizing Azure Automation solutions for Runtime Environment 7.x.

---

## Full Report

The complete investigation report is available in this repository as a PDF document.

---

## References

Microsoft Documentation

- Azure Automation Child Runbooks
- Start-AzAutomationRunbook
- Azure Automation Runtime Environment
- Azure Automation Hybrid Workers
