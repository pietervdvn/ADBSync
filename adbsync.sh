#! /bin/bash

SOURCE="$1"
DEST="$2"

if [[ `whoami` == "rein"  && $# -eq 0 ]]
then
	echo "Using settings for rien's machine"
	SOURCE="/home/rien/Music/"
	DEST="/storage/sdcard0/Music"
elif [[ `whoami` == "pietervdvn"  && $# -eq 0 ]]
then
	echo "Using settings for pietervdvn's machine"
	SOURCE="/home/pietervdvn/Music/"
	DEST="/storage/sdcard1/Music/"
elif [[ $# -lt 2 ]]
then
	echo "ADBSync: Usage"
	echo "ADBSync <computer directory> <phone directory> [-r]"
	exit
fi


echo "Copying from $SOURCE to $DEST"


CUT=`echo $SOURCE | wc -c`
FILES=`find -L "$SOURCE" -not -path "*./*" -not -name ".*" -type f | cut -b $CUT-`
IFS=$'\n'
let "COUNT=0"
let "TOTAL=0"
let "ERR=0"
let "SKIP=0"
let "COPIED=0"
LOG=""

for FILE in $FILES
do
	let "TOTAL++"
done


START=$(date +%s.%N)


let "TRIPPER=1"
let "THRESHOLD=80"
for FILE in $FILES
do
	let "COUNT++"
	SHORT=`echo $FILE | cut -b 1-60`
	SAFEDEST=`echo $DEST/$FILE | tr -d ':?' | tr -d "'\\\`"`
# TODO fix issue: names with "'" are not recognized!
	EXISTS=`adb shell "
if [[ -f \"$SAFEDEST\" ]]
then
echo 1
else
echo 0
fi "`


	if [[ "$EXISTS" == *"1"* ]]
	then
		# echo "    Skipped"
		echo -n "."
		let "SKIP++"
	else
		echo -n "    Copying: "
		echo "$COUNT/$TOTAL (S:$SKIP,F:$ERR): $SHORT"
		if adb push "$SOURCE/$FILE" "$SAFEDEST"
		then
			echo -n "+"
			let "COPIED++"
		else
			echo -n "E"
			let "ERR++"
			LOG="$LOG\n$FILE"
		fi
	fi






	# status output each THRESHOLD files
	if [[ $TRIPPER -eq $THRESHOLD ]]
	then
		END=$(date +%s.%N)
		DIFF=$(echo "$END - $START" | bc)
		echo -e "\r$COUNT/$TOTAL (S:$SKIP,F:$ERR,C:$COPIED) $DIFF sec busy"
		let "TRIPPER=0"
	fi
	let "TRIPPER++"




done

echo -e "\nDONE!"
echo "Copied: $COPIED	Skipped: $SKIP   Failed: $ERR    Total: $TOTAL"
END=$(date +%s.%N)
DIFF=$(echo "$END - $START" | bc)
echo "This took $DIFF sec"
if [ -n "$LOG" ]
then
	echo "Following files failed:"
	echo -e "$LOG"
fi
