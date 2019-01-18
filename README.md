# scheduledEventChecker

## Azure VM의 Schedeuled Event를 체크하는 스크립트
<br>

## 1. 구성도
<img src=https://github.com/chupark/scheduledEventChecker/blob/master/images/send_slack.png />

## 2. 구성 파일
````yaml
파일명                      역할
----                        ----
servers                     Azure VM들의 사설 IP를 써 넣습니다.
startScheduledEvent.sh      Scheduled Event 모니터링을 시작합니다
stop.sh                     Scheduled Event 모니터링을 종료합니다.
processes                   stop.sh를 실행하면 어떤 프로세스로 실행됐었는지 보여줍니다.
send_slack.log              이름은 send_slack.log지만 스크립트 로그를 기록합니다.
````

## 3. 사용방법
1. bash shell에서 json텍스트를 파싱하는 jq 툴을 설치합니다.
- sudo apt-get install jq
2. "git clone https://github.com/chupark/scheduledEventChecker.git" 명령을 사용하여 파일을 다운 받습니다.
3. 원격 모니터링 서버 없이, 개별 VM에서 스크립트를 실행한다면 servers 파일에 localhost 만 씁니다.
4. startScheduledEvent.sh 파일의 설정을 수정합니다.
````bash
## Remote VM's id/pw info // 대상 서버들의 id / pw
sshId="<your-id>"
sshPw="<your-password>"

## Server list file Path // 모니터링 대상 서버들의 ip가 저장된 파일 (원격서버가 없을시 servers 파일 내에 localhost만 작성)
serverListPath="servers"

## Slack Config // Slack 설정
noticeChannel="<your-slack-channel>"
botToken="<your-slack-bot-token>"
postMsgUrl="https://slack.com/api/chat.postMessage"

## Send Msg Interval (Seconds) // 몇초 단위로 Scheduled Event를 수집할지
sendInterval=10
````
5. servers 파일에 Azure VM들의 사설 IP를 써 넣습니다. Excel로 미리 만들어 복사, 붙여넣기 하면 편합니다.
6. startScheduledEvent.sh 를 실행합니다 
````bash
user@vm:/scheduledEventTest$ ./startScheduledEvent.sh
````
7. 로그를 확인합니다.
````bash
> Scheduled Event가 없다면 아래와 같이 나타납니다.

user@vm:/scheduledEventTest$ cat send_slack.log
Thu Jan 10 16:39:46 KST 2019 not Scheduled 10.1.1.5
Thu Jan 10 16:39:46 KST 2019 not Scheduled 10.1.1.6
Thu Jan 10 16:43:55 KST 2019 not Scheduled 10.1.1.7
Thu Jan 10 16:39:46 KST 2019 not Scheduled 10.1.1.5
Thu Jan 10 16:39:46 KST 2019 not Scheduled 10.1.1.6
Thu Jan 10 16:43:55 KST 2019 not Scheduled 10.1.1.7
Thu Jan 10 16:39:46 KST 2019 not Scheduled 10.1.1.5
````
<br>

````bash
> Scheduled Event가 있다면 아래 데이터를 파싱합니다.
---------
{
	"DocumentIncarnation": 1,
	"Events": [{
		"EventId": "72E160B5-6F75-40FA-BD4C-0C7FA2318A51",
		"EventStatus": "Scheduled",
		"EventType": "Redeploy",
		"ResourceType": "VirtualMachine",
		"Resources": ["VM-SE-Server02"],
		"NotBefore": "Thu, 17 Jan 2019 05:57:06 GMT"
	}]
}

> Scheduled Event가 있다면 로그는 아래와 같이 나타납니다.

user@vm:/scheduledEventTest$ cat send_slack.log
Thu Jan 10 17:22:20 KST 2019 {"ok":true,"channel":"CDGTC9UMD","ts":"1547108541.013800","message":{"type":"message","subtype":"bot_message","text":"*New Scheduled Event Alert !!! :bomb::bomb::bomb:*","ts":"1547108541.013800","username":"grafana_noti","bot_id":"BDF3XC196","attachments":[{"title":"[[ Azure Portal ]]","id":1,"title_link":"https:\/\/portal.azure.com","color":"f44242","fields":[{"title":"EventId","value":"195E86EA-EB42-4F84-9B5C-198047ED23E2","short":true},{"title":"EventStatus","value":"Scheduled","short":true},{"title":"EventType","value":"Redeploy","short":true},{"title":"ResourceType","value":"VirtualMachine","short":true},{"title":"When","value":"Thu, 10 Jan 2019 08:26:33 GMT","short":true},{"title":"VM","value":"VM-SE-Server04","short":true},{"title":"IP","value":"10.1.1.8","short":true},{"title":"CurrentTime","value":"Thu Jan 10 17:22:20 KST 2019","short":true}],"fallback":"[[ Azure Portal ]]"}]},"warning":"missing_charset","response_metadata":{"warnings":["missing_charset"]}}

````
8. Scheduled 모니터링 종료를 원한다면 stop.sh를 실행합니다.
````bash
user@vm:/scheduledEventTest$ sh stop.sh
terminated
user@vm:/scheduledEventTest$
````

## 4. Slack 확인
Slack에 아래와 같은 메세지가 전송됩니다.
<br>
<img src=https://github.com/chupark/scheduledEventChecker/blob/master/images/slackImage.png />
<br>
현재 각 VM별 메세지를 전송하기 때문에 VM100대 모두 Scheduled Event가 발생했을 경우 메세지 100개가 전송됩니다. <br>
이 문제는 어떻게할지 고민이 좀더 필요하기 때문에 업데이트에는 시간이 걸리겠습니다.

## 5. 참고 링크
1. Slack 메세지 보내기
- https://bit.ly/2MhdMMr
2. Slack 메세지 포맷 테스트
- https://bit.ly/2f972yx
