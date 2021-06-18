#requires -version 2
<#
.SYNOPSIS
  Notifies Zabbix of when a server has booted to remove it from maintenance mode.
.DESCRIPTION
  The script will be added as a startup event to all servers with the 
  Zabbix agent installed and notify Zabbix view a log file. Zabbix has a 
  trigger and action to then place the server within the maintenance group.
  The script will be called on once the server is up and running to resume
  from maintenance mode.
    1. Removes a machine from maintenance mode, if shutdown reason is matched. 
  
.INPUTS
  None
.OUTPUTS
  Writes to the Application Event Log
#>


### MAIN ###
$LogSource = "Maintenance Mode"

# Validate source doesn't exist already, if not, create it
if (![System.Diagnostics.EventLog]::SourceExists("$LogSource")) {
    New-Eventlog -LogName "Application" -Source $LogSource
}

# Validate Zabbix_sender is installed
if(!(Test-Path 'C:\Program Files\Zabbix Agent\zabbix_sender.exe')){
    Write-EventLog -LogName Application -Source $LogSource -EventId "1003" -Message "The maintenance mode script did not notify Zabbix as the zabbix_sender.exe is not installed."
} else {
    try {
      $log = "Exiting Maintenance Mode"
      Start-Process -FilePath "C:\Program Files\Zabbix Agent\zabbix_sender.exe" -WindowStyle hidden -ArgumentList '-c "C:\Program Files\Zabbix Agent\zabbix_agentd.conf"', "-k maintenance.mode", "-o `"$log`""
        if($?){Write-EventLog -LogName Application -Source $LogSource -EventId "1000" -Message "The maintenance mode script notified Zabbix that the system should be removed from maintenance mode."}
    }
    catch {
        Write-EventLog -LogName Application -Source $LogSource -EventId "1001" -Message "The maintenance mode script errored while trying to notify Zabbix of system coming out of maintenance mode."
    } 
}
