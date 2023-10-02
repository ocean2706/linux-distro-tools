#!/bin/bash
#### @todo 20231002
#### Issue: if your command implies reading also from stdin for example
####  cat > log.file  
#### after you paste the content, you need to end with ctrl+c. This will also end the main script.
#### @author
#### 6072@protonmail.com
echo "Starting Bash-log emulator.Type EXIT or QUIT to exit "
cmd=""
dt=$1; 
#####// set file as first argument; 
if [ -z $dt ]
then
dt=$(date +%Y%m%d);
dt="$dt.shscript.log";
fi

echo "Log to $dt";
while  IFS= read -r -p ">>>" cmd  ; 
	case "$cmd" in
	"EXIT"|"QUIT") 
		break
	;;
	*) 
		echo "Executing $cmd. type EXIT to exit"
		echo ">>> $cmd" >> $dt 
		bash -c "$cmd" 2>&1 | tee -a $dt
	;;
	esac
	
done

echo  "Emulator End"

