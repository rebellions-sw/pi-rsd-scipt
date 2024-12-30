#!/bin/bash
command1=$1
command2=$2

echo "comand1 is $command1  command2 is $command2"
echo "command is $command1 -d npu_num | $command2" 


RBLN_NUM=$(rbln-stat -L | wc -l)
echo "rbln device is $RBLN_NUM"

for ((i=0; i < $RBLN_NUM; i++)); do
	#run_command="$command1 -d $i | $command2"
	if [ -z "$command2" ]; then
            run_command="$command1 -d $i"
    	else
            run_command="$command1 -d $i | $command2"
	fi
	echo "run_command is $run_command"
	eval "$run_command"
	sleep 1
done


