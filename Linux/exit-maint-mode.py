# <#
# .SYNOPSIS
#   Notifies Zabbix of when a server is shutting down.
# .DESCRIPTION
#   The script will be added as a shutdown service to all servers with the 
#   Zabbix agent installed and notify Zabbix. Zabbix has a 
#   trigger and action to then place the server within the maintenance group.
#   The script will be called on once the server is up and running to resume
#   from maintenance mode.
#     1. Sends an e-mail when a shutdown/restart event is thrown.
#     2. Puts a machine into maintenance mode, if shutdown reason is matched. 
  
# #>
import sys
import time
import os
import os.path
import re
import smtplib
import syslog
import socket
import glob


### VARIABLES ###
### MAIN ### 
if __name__ == "__main__":
    # Validate Zabbix_sender is installed
    
    if not os.path.exists('/usr/bin/zabbix_sender'):
        syslog.syslog("The maintenance mode script did not notify Zabbix as the zabbix_sender.exe is not installed.")
    else:
        syslog.syslog("Attempting to notify Zabbix to take server out of maintenance mode")
        try:
            cmd = "zabbix_sender -c /etc/zabbix/zabbix_agentd.conf -k maintenance.mode -o 'Exiting Maintenance Mode'"
            os.system(cmd)
        except:
            syslog.syslog("Failed sending notification to Zabbix to exit  maintenance mode")