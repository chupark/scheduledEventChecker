#!/bin/bash

## Scheduled Event Api Version
apiVersion="2017-08-01"

## Remote VM's id/pw info
sshId="<your-id>"
sshPw="<your-password>"

## Server list file Path
serverListPath="servers"

## Slack Config
noticeChannel="<your-slack-channel>"
botToken="<your-slack-bot-token>"
postMsgUrl="https://slack.com/api/chat.postMessage"

## Send Msg Interval (Seconds)
sendInterval=10


############################################################
############################################################
## Do not Change this Variables Never!!!!!                ##
eventInfo=""
eventId=""
eventStatus=""
eventType=""
resourceType=""
notBefore=""
vm=""
vms=""
result=""
############################################################
############################################################

##
# Send Message to Slack
# visit this link for message deatils
# 1. https://api.slack.com/docs/messages/builder?msg=%7B%22text%22%3A%22*bold*%20%60code%60%20_italic_%20~strike~%22%2C%22username%22%3A%22markdownbot%22%2C%22mrkdwn%22%3Atrue%7D
# 2. https://api.slack.com/changelog/2017-10-keeping-up-with-the-jsons
##
function send_slack_msg (){
  msg_parser "$1" "$2"
  thisTime="$(date)"
  abc=$(curl --silent -X POST -H "Authorization: Bearer $botToken" -H 'Content-type: application/json' --data '{ "text": "*New Scheduled Event Alert !!! :bomb::bomb::bomb:*", "channel":"'"$noticeChannel"'", "attachments": [ { "color": "#f44242", "title": "[[ Azure Portal ]]", "title_link": "https://portal.azure.com", "fields": [ { "title": "EventId", "value": "'"$eventId"'", "short": true }, { "title": "EventStatus", "value": "'"$eventStatus"'", "short": true }, { "title": "EventType", "value": "'"$eventType"'", "short": true }, { "title": "ResourceType", "value": "'"$resourceType"'", "short": true }, { "title": "When", "value": "'"$notBefore"'", "short": true }, { "title": "VM", "value": "'"$vms"'", "short": true }, { "title": "IP", "value": "'"$2"'", "short": true }, { "title": "CurrentTime", "value": "'"$thisTime"'", "short": true } ] } ] }' $postMsgUrl)
  echo $thisTime $abc >> send_slack.log
}


##
# Json Parser
# jq library required!
# sudo apt-get install jq
##
function msg_parser () {
  vm=""
  eventNum=$(echo $1 | jq ".Events" | jq length)
  for (( i=0; i<$eventNum; i++ ))
    do
      eventInfo=$(echo $1 | jq ".Events[$i]")
      eventId=$(echo $eventInfo | jq ".EventId" | sed 's/"//g')
      eventStatus=$(echo $eventInfo | jq ".EventStatus" | sed 's/"//g')
      eventType=$(echo $eventInfo | jq ".EventType" | sed 's/"//g')
      resourceType=$(echo $eventInfo | jq ".ResourceType" | sed 's/"//g')
      notBefore="$(echo $eventInfo | jq ".NotBefore" | sed 's/"//g')"
      resourceNum=$(echo $eventInfo | jq ".Resources" | jq length)
      for (( j=0; j<$resourceNum; j++ ))
        do
          vm+=$(echo $eventInfo | jq ".Resources[$j]")
        done
    done
  vms="$(echo $vm | sed 's/"//g')"
}


##
#
#
##
function get_scheduled_event () {
vmIP=$1
while :
    do
	thisTime=$(date)
	if [ $vmIP == 'localhost' ]
	then
		event=$(curl --silent -H Metadata:true http://169.254.169.254/metadata/scheduledevents?api-version=$apiVersion)
		vmIP=$(hostname)
	else
	        event=$(sshpass -p$sshPw ssh -o StrictHostKeyChecking=no $sshId@$vmIP "curl --silent -H Metadata:true http://169.254.169.254/metadata/scheduledevents?api-version=$apiVersion")
	fi
        isNull=$(echo $event | jq ".Events" | jq length)
        if [ $isNull -eq 0 ]
            then
		echo $thisTime not Scheduled $vmIP >> send_slack.log
            else
		send_slack_msg "$event" "$vmIP"
        fi
        sleep $sendInterval
    done
}

######################################################################################################################################################
######################################################################################################################################################
######################################################################################################################################################


while read line
    do
        get_scheduled_event $line &
    done < "$serverListPath"
