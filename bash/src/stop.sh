ps -ef |grep startScheduledEvent | grep -v grep > processes

while read A B C
    do
        kill -9 ${B}
    done < "processes"
echo "terminated"
