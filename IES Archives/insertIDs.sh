#Note these ids come from mongo's Random module.  They will need to be replaced if this script is run again

ids=("z4KyiDR8vL6g7k2r7" "SqTrEGLjG2v6eAfdC" "tHX8trP6J668L4yqD" "7MYD2DvXkt2SDob4m" "zAG4GfzbnBGXgGSir" "p29gXzDK6G6uEisqR" "h8B3Hd9nk8Fgcw7Gm" "5Gc5pBMTSaSKkKk6F" "oaQxJTF2ngP6GiJfL" "Wg4MbD4bDsHrJPjth" "4WHriwCe96vSeoaKT" "iDEgZZPybew7vnjtb" "SQAsRxZf99n28BYN4" "4PCEhcA7iBLfwttnX" "DWRsdcRAB5F2xzWgP" "a2jY8AXdRRdSqshop" "yGBwb8djMXt5Rjr2u" "uFy75PBYLSQ2WXrTu" "oEucLtnKhKaXoX5vd" "cBuhvtS36YYJzJrtN" "F2nfsTdKBoTNrm4Dm" "TbSqNSjwWkkJj93Bv" "XeKvdBaoLGPhLXLCM" "88jC35aTazfGE9aJm")

for file in `ls *.json`; do
	sed -i "s/\"source\": \"upload\"/\"source\": \"upload\",\n    \"_id\":\"$ids\"/" $file
	echo "s/\"source\": \"upload\"/\"source\": \"upload\",\n    \"_id\":\"$ids\"/"
	ids=("${ids[@]:1}")
	echo $file;
done
