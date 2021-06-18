#!/bin/bash
echo "Setting host into maintenance group: $1"
hostToRemove=$1
#***********************************************************************
#Beginning of custom variables
zabbixServer=""
zabbixUsername=""
zabbixPassword=""
#zabbixApiUrl="zabbix/api_jsonrpc.php"
zabbixApiUrl="/api_jsonrpc.php"
zabbixMaintHostGroupId=""
baseDir="/usr/lib/zabbix/alertscripts"
#End of custom variables
#***********************************************************************
header='Content-Type:application/json'
#zabbixApiUrl="https://$zabbixServer/zabbix/api_jsonrpc.php"

cd $baseDir

function exit_with_error() {
  echo '********************************'
  echo "$errorMessage"
  echo '--------------------------------'
  echo 'INPUT'
  echo '--------------------------------'
  echo "$json"
  echo '--------------------------------'
  echo 'OUTPUT'
  echo '--------------------------------'
  echo "$result"
  echo '********************************'
  exit 1
}

#------------------------------------------------------
# Auth to zabbix
# https://www.zabbix.com/documentation/3.4/manual/api/reference/user/login
#------------------------------------------------------
errorMessage='*ERROR* - Unable to get Zabbix authorization token'
json=`cat user.login.json`
json=${json/USERNAME/$zabbixUsername}
json=${json/PASSWORD/$zabbixPassword}
result=`curl --silent --show-error --insecure --header $header --data "$json" $zabbixApiUrl`
auth=`echo $result | jq '.result'`
if [ $auth == null ]; then exit_with_error; fi
echo "Login successful - Auth ID: $auth"

#------------------------------------------------------
# Get Host ID from name
# https://www.zabbix.com/documentation/3.4/manual/api/reference/hostgroup/get
#------------------------------------------------------
errorMessage="*ERROR* - Unable to get host ID for '$zabbixHostGroup'"
json=`cat host.get.json`
json=${json/HOSTTOADD/$hostToRemove}
json=${json/AUTHID/$auth}
result=`curl --silent --show-error --insecure --header $header --data "$json" $zabbixApiUrl`
hostId=`echo $result | jq -r '.result | .[0] | .hostid'`
if [ $hostId == null ]; then exit_with_error; fi
echo "HostId for '$hostToRemove': $hostId to be removed from maintenance mode"


#------------------------------------------------------
# Remove Host ID from group
# https://www.zabbix.com/documentation/2.0/manual/appendix/api/hostgroup/massremove
#------------------------------------------------------
errorMessage="*ERROR* - Unable to remove $hostToRemove from maintenance group'"
json=`cat host.group.remove.json`
json=${json/MAINTGROUPID/$zabbixMaintHostGroupId}
json=${json/MAINTHOSTID/$hostId}
json=${json/AUTHID/$auth}
result=`curl --silent --show-error --output /dev/null --insecure --header $header --data "$json" $zabbixApiUrl --write-out "%{http_code}"`
if [ $result != "200" ]; then exit_with_error; fi
echo "Successfully removed $hostToRemove from the Zabbix Maintenance Group"


#------------------------------------------------------
# Logout of zabbix
# https://www.zabbix.com/documentation/3.4/manual/api/reference/user/logout
#------------------------------------------------------
errorMessage='*ERROR* - Failed to logout'
json=`cat user.logout.json`
json=${json/AUTHID/$auth}
result=`curl --silent --show-error --insecure --header $header --data "$json" $zabbixApiUrl`
logout=`echo $result | jq '.result'`
if [ $logout == null ]; then exit_with_error; fi
echo 'Successfully logged out of Zabbix'
