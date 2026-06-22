# Create a hashtable named $CommonVars to store values that can be shared
# with the parent runbook or other scripts.
$CommonVars = @{
    
    # Sample key-value pair.
    # Key   : Message
    # Value : "Hello from child runbook"
    Message = "Hello from child runbook"
}
# Return the hashtable to the calling runbook.
# The parent runbook can access the value using:
# $ReturnedVars.Message
return $CommonVars.Message
