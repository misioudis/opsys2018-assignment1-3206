#! /bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color


function get_website_md5() {
	content=$(wget -qO- -T 10 $1)
	if [[ -z "$content" ]]; then
		result="NA"
	else
		result=$(echo -e $content | md5sum | cut -d ' ' -f 1)
	fi
	echo "$result"
}

function process_url() {
	md5sum=$(get_website_md5 $1)
	if [[ $md5sum = "NA" ]]; then
		(>&2 echo -e "$url ${RED}FAILED${NC}")
	fi

	if [[ ! -n "${websites[$1]}" ]]; then 
		echo -e "$1 ${GREEN}INIT${NC}"    
		websites[$1]=$md5sum
	 else                                                    	
	 	if [[ $md5sum != ${websites[$1]} ]]; then 
			echo "$1"
               	 	websites[$1]=$md5sum
         	fi
	fi
	
	for i in "${!websites[@]}"
	do
		echo "$i|${websites[$i]}" >> visited_websites.txt
	done
}

input_file=$1
if [[ $input_file = "" ]]; then
	echo "Please provide a file that contains addresses as an argument"
	exit 1
fi
if [[ ! -e $input_file ]]; then
	echo -e "File \"$input_file\" does not exist"
	exit 1
fi

declare -a urls
while read -r line; do
	[[ "$line" =~ ^[[:space:]]*# ]] && continue
	urls+=( "$line" )
done < $input_file

declare -A websites
touch visited_websites.txt
while IFS=\| read url md5;
do
	websites[$url]=$md5
done < visited_websites.txt

cat /dev/null > visited_websites.txt

for url in ${urls[@]}; do
	process_url $url &
done
wait

exit
