declare -a DATA=`./sc.py`
printf "shell script gets \"%s\" & \"%s\" from py script.\n" \
    ${DATA[0]} ${DATA[1]}

