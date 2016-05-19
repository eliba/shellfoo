#!/bin/bash
# i3 thread: https://faq.i3wm.org/question/150/how-to-launch-a-terminal-from-here/?answer=152#post-id-152

CMD="xterm -bg black -fg grey"
CWD=''

# Get window ID
ID=$(xdpyinfo | grep focus | cut -f4 -d " ")

# Get PID of process whose window this is
PID=$(xprop -id $ID | grep -m 1 PID | cut -d " " -f3)

# Get last child process (shell, vim, etc)
if [ -n "$PID" ]; then
	TREE=$(pstree -lpA $PID | tail -n 1)
	PID=$(echo $TREE | awk -F'---' '{print $NF}' | sed -re 's/[^0-9]//g')
	
	# If we find the working directory, run the command in that directory
	if [ -e "/proc/$PID/cwd" ]; then
		CWD=$(readlink /proc/$PID/cwd)
	fi
fi

# get currently running application
echo $PID
CURRENT_CMD=$(pstree -lpA $PID | tail -1 | awk -F'---' '{print $NF}' | sed -re 's/[0-9()]//g')
echo "cmd: $CURRENT_CMD"
case ${CURRENT_CMD} in
	ssh)
		SSH_ADDR=$(netstat -tnpa 2> /dev/null | grep "ESTABLISHED ${PID}/ssh" | awk '{print $5}' | cut -d: -f1)
		# assuming "Host" is the first line above "HostName" in your ssh config
		SSH_HOSTNAME=$(grep -B1 ${SSH_ADDR} ${HOME}/.ssh/config | head -1 | cut -d\  -f2)
		if [ -n "SSH_HOSTNAME" ]; then
			# no ssh config entry found
			SSH_USER=$(cat /proc/${PID}/cmdline | sed -e 's/^ssh\(.*\)@.*$/\1/')
			# crawl for more ssh-options here if necessary
			CMD="${CMD} -e ssh ${SSH_USER}@${SSH_ADDR}"
		else
			CMD="${CMD} -e ssh ${SSH_HOSTNAME}"
		fi
		;;
	*)
		# do nuttin
		;;
esac

if [ -n "$CWD" ]; then
	cd $CWD && $CMD
else
	$CMD
fi
