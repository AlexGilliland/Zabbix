
***Workflow***

On graceful shutdown/reboot -> Script uses zabbix_sender to send item to Zabbix -> Zabbix triggers based on the received item and an action places the server into "Maintenance Mode" group.
On boot -> Startup script uses zabbix_sender to send item to Zabbix -> Zabbix
 
Steps
1. Create a group called 'Maintenance Mode'
**Note:** Document the groupid which can be found in the URL string when selecting the group within **Configuration>Host Groups**
2. Create the new item with the key 'maintenance.mode' within the template of your choosing
	**Note:** I opted to use Template Module Zabbix Agent
3. Create a trigger with the **Problem Expression** set to ``{Template Module Zabbix agent:maintenance.mode.regexp("^Entering Maintenance Mode",1)}=1`` and **Recovery Expression** set to ``{Template Module Zabbix agent:maintenance.mode.count(15m,"Exiting Maintenance Mode")}>=1 and {Template Module Zabbix agent:maintenance.mode.count(#2, "Entering Maintenance Mode")}=1``
4. Create and place the two scripts from [here](https://github.com/AlexGilliland/Zabbix/blob/main/Enter-MaintenanceMode.bat) to /usr/lib/zabbix/alertscripts/ (or where ever you store your Zabbix scripts, but if you do, you'll need to update the basedir within the script) and update the custom variables section within the .bat file to match your environment. This includes the groupid from step 1
5. Create a new Zabbix action within **Configuration>Actions**
	**Name:** Enter Maintenance Mode
	**Conditions:** A) Trigger name containers *Maintenance Mode* B) Trigger name containers *Enter Maintenance Mode*
	**Operations Tab**
	**Operations:**
			**Target list:** Set this to your Zabbix host
			**Type:** Custom script
			**Execute On:** Zabbix server
			**Commands:** /usr/lib/zabbix/alertscripts/Enter-MaintenanceMode.bat {HOST.NAME}
			
6. Create a new Group Policy and apply to the OUs you want and set the Computer Configuration > Policies > Windows Settings > Scripts, Shutdown (Enter-MaintenanceMode.ps1) and Startup (Exit-MaintenanceMode.ps1)

