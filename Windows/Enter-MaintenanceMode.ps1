#requires -version 2
<#
.SYNOPSIS
  Notifies Zabbix of when a server is shutting down.
.DESCRIPTION
  The script will be added as a shutdown event to all servers with the 
  Zabbix agent installed and notify Zabbix view a log file. Zabbix has a 
  trigger and action to then place the server within the maintenance group.
  The script will be called on once the server is up and running to resume
  from maintenance mode.
    1. Sends an e-mail when a shutdown/restart event is thrown.
    2. Puts a machine into maintenance mode, if shutdown reason is matched. 
  
#>

function New-Log($eventObject){

  return "Entering Maintenance Mode| A $($eventObject.ShutdownType) event has been initiated on $env:Computername | User: $($eventObject.User) | Type: $($eventObject.Reason)|  Comment: $($eventObject.Comment)"
  
  }
  function Send-Email($eventObject){
  
          $html = "<p>A $($eventObject.ShutdownType) event has been initiated on $env:Computername.
          <p>User: $($eventObject.User)
          <br>Time: $($eventObject.Time)
          <br>Type: $($eventObject.Reason)
          <br>Comment: $($eventObject.Comment)"
  
      Send-MailMessage -SmtpServer $smtpEndpoint -From ("$env:COMPUTERNAME" + $DomainName) -To $notificationaddresses -Subject "A $($eventObject.ShutdownType) has been initiated on $env:Computername" -Body $html -BodyAsHtml
  }
  
  
  ### VARIABLES ###
  $LogSource = "Maintenance Mode"
  $xmlfilter = "<QueryList><Query Id='0' Path='System'><Select Path='System'>*[System[EventID=1074]]</Select></Query></QueryList>"
  $Notificationaddresses = "maintenance@yourdomain.com"
  $SMTPEndpoint = "yoursmtpserverhere"
  $EventDetails = New-Object PSObject
  $DomainName = "@yourdomain.com"
  
  ### MAIN ###
  # Validate source doesn't exist already, if not, create it
  if (![System.Diagnostics.EventLog]::SourceExists("$LogSource")) {
      New-Eventlog -LogName "Application" -Source $LogSource
  }
  
  [xml]$event = (Get-WinEvent -FilterXml $xmlfilter -MaxEvents 1).ToXml()
  $eventDetails | Add-Member NoteProperty Time (get-date -Format "dd/MM/yy hh:mm:ss")
  $OperatingSysetmInfo = Get-WmiObject -class win32_operatingsystem
  if ([version]$OperatingSysetmInfo.version -lt [version]6.2) { #Server 2008r2 and below
      # Parse and create object
      $eventDetails | Add-Member NoteProperty User $event.Event.EventData.Data[6]
      $eventDetails | Add-Member NoteProperty ShutdownType $event.Event.EventData.Data[4]
      $eventDetails | Add-Member NoteProperty Comment $event.Event.EventData.Data[5]
      if (($event.Event.EventData.Data[3]) -match 0x8) {
        $eventDetails | Add-Member NoteProperty Reason  "Planned"
      } else{
        $eventDetails | Add-Member NoteProperty Reason  "Unplanned"
      }
      
  
  } else { 
      $eventDetails | Add-Member NoteProperty User $event.Event.EventData.Data[6].'#text'
      $eventDetails | Add-Member NoteProperty ShutdownType $event.Event.EventData.Data[4].'#text'
      $eventDetails | Add-Member NoteProperty Comment $event.Event.EventData.Data[5].'#text'
      if (($event.Event.EventData.Data.Item(3)."#text") -match 0x8) {
        $eventDetails | Add-Member NoteProperty Reason  "Planned"
      } else{
        $eventDetails | Add-Member NoteProperty Reason  "Unplanned"
      }
      
  }
  
  # Validate Zabbix_sender is installed
  if(!(Test-Path 'C:\Program Files\Zabbix Agent\zabbix_sender.exe')){
      Write-EventLog -LogName Application -Source $LogSource -EventId "1003" -Message "The maintenance mode script did not notify Zabbix as the zabbix_sender.exe is not installed."
  } else {
      try {
          $log = New-Log $eventDetails
          Start-Process -FilePath "C:\Program Files\Zabbix Agent\zabbix_sender.exe" -WindowStyle hidden -ArgumentList '-c "C:\Program Files\Zabbix Agent\zabbix_agentd.conf"', "-k maintenance.mode", "-o `"$log`""
          if($?){Write-EventLog -LogName Application -Source $LogSource -EventId "1000" -Message "The maintenance mode script notified Zabbix."}
      }
      catch {
          Write-EventLog -LogName Application -Source $LogSource -EventId "1001" -Message "The maintenance mode script errored while trying to notify Zabbix."
      } 
  }
  
  Send-Email($eventDetails)
  if($?){Write-EventLog -LogName Application -Source $logsource -EventId "1000" -Message "Maintenance Mode has sent an e-mail to $notificationaddresses."}else{Write-EventLog -LogName Application -Source $logsource -EventId "1001" -Message "Maintenance Mode has failed to send an e-mail to $notificationaddresses."}
