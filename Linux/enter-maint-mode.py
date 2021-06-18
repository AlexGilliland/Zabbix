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


from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText

### VARIABLES ###
notificationaddresses=""
smtpEndpoint=""
SMTP_SERVER = ""
SMTP_PORT = 25
EMAIL_TO = ""
HOSTNAME = socket.gethostname()
EMAIL_FROM = HOSTNAME + "@domain.com"


class SendMail:
    
    def send_email(self, event_type):
        EMAIL_SUBJECT = "A " + event_type + " event has been initiated on " + HOSTNAME
        syslog.syslog(EMAIL_FROM)
        syslog.syslog(EMAIL_TO)
        syslog.syslog(EMAIL_SUBJECT)
        content = "<html><head></head><body><p>A " + event_type + " event has been initiated on " + HOSTNAME + ". </br>Server is being placed into maintenance mode until it comes back online.</p></body></html>"
        content1 = MIMEText(content, 'html')
        msg = MIMEMultipart('alternative')
        msg['Subject'] = EMAIL_SUBJECT
        msg['To'] = EMAIL_TO
        msg['From'] = EMAIL_FROM
        msg.attach(content1)
        mail = smtplib.SMTP(SMTP_SERVER, SMTP_PORT)
        mail.sendmail(EMAIL_FROM, EMAIL_TO, msg.as_string())
        mail.quit()

### MAIN ### 
if __name__ == "__main__":
    # Validate Zabbix_sender is installed
    
    if not os.path.exists('/usr/bin/zabbix_sender'):
        syslog.syslog("The maintenance mode script did not notify Zabbix as the zabbix_sender.exe is not installed.")
    else:
        syslog.syslog("Attempting to notify Zabbix to put server into maintenance mode")
        try:
            stream = os.popen('last -x | grep \'reboot\|shutdown\' | tac | tail -1')
            output = stream.read()
            event_type = re.match('reboot|shutdown',output).group(0) # event type, shutdown or reboot
            cmd = "zabbix_sender -c /etc/zabbix/zabbix_agentd.conf -k maintenance.mode -o 'Entering Maintenance Mode'"
            os.system(cmd)
            obj = SendMail()
            obj.send_email(event_type)
            # write success to syslog
        except:
            syslog.syslog("Failed sending notification to Zabbix to enter maintenance mode")