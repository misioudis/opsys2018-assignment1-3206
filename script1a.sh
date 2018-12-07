#! /bin/bash

function get_website_md5() {

	# execute wget to fetch website. 
	# "$1" is a variable that descirbes the first argument
	content=$(wget -qO- -T 10 $1)


	#  checks if the variable "$content" is empty.
	if [[ -z "$content" ]]; then

		# if "$content" is empty, thath means that wget failed then 
		# set result as "NA" ("NA" is arbitrary and it is simply used
		# to indicate that the wget has failed )
		result="NA"
	else
		# else if "$content is not empty then pass value of varialbe 
		# through md5sum command and then pass the out put to cut in order
		# to trim anything after a space (' ')
		result=$(echo -e $content | md5sum | cut -d ' ' -f 1)
	fi

	
	echo "$result"
}
# end of function definition
# --------------------------

# The commands from this point and below WILL be executed
# ---------------------------------------------------------

# define variables that we will use later
#  colors

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Get first argument that was passed to the script, for example
# if the script was executed as: "sh script1a.sh address_list.txt"
# then $1 = address_list.txt. 
input_file=$1


# If input_file is null (that means that the user did not provide a 
# argument when running the script ), print error and exit with 1 
if [[ $input_file = "" ]]; then
	echo "Please provide a file that contains addresses as an argument"
	exit 1
fi

# if the file does not exist
# exit with 1  
if [[ ! -e $input_file ]]; then
	echo -e "File \"$input_file\" does not exist"
	exit 1
fi

# Declare an array with name "urls"
declare -a urls

# read $input_line and for each line if the line starts with 
# no or more spaces followed by a "#" then continue loop
# if the line does not starts with "#" then add it to the 
# array that we declared above
while read -r line; do
	[[ "$line" =~ ^[[:space:]]*# ]] && continue
	urls+=( "$line" )
done < $input_file

# Declare an assosiative array with name "websites"
# An assosiative array is one that contains "key => values" pairs
# In this used to store the websites that were already visted
declare -A websites

# this command is executed in order to make sure file exits
touch visited_websites.txt

# read lines from the file and store them in the assosiative array
# lines are in a format of "url|md5sum"
while IFS=\| read url md5;
do
	websites[$url]=$md5
done < visited_websites.txt

# loop that for each url in the input file, does the work
for url in ${urls[@]}; do

	# get md5sum of website
	md5sum=$(get_website_md5 $url)

	# if the md5s sum is "NA" 
	# then print to STDERR that the call to the website FAILED
	if [[ $md5sum = "NA" ]]; then
		(>&2 echo -e "$url ${RED}FAILED${NC}")  #print to stderr
	fi

	# if the url does exist in the websites (assosiative array with the alread websites)
	# then print INIT and add it to the assosiative array
	if [[ ! -n "${websites[$url]}" ]]; then 
		echo -e "$url ${GREEN}INIT${NC}"
		websites[$url]=$md5sum

	# else if the url is in the array (that means that we already have visited)
	# then check if the md5sum has changed	
	else

		# if the md5sum have changed, then store the new md5sum
		if [[ $md5sum != ${websites[$url]} ]]; then	#if content changed
			echo "$url"
			websites[$url]=$md5sum
		fi
	fi
#end of loop
done

# clear the visited_websites file of all old data and rewrite 
# the assosiative array of websites to it
cat  /dev/null > visited_websites.txt
for i in "${!websites[@]}"
do
       	echo "$i|${websites[$i]}" >> visited_websites.txt
done

exit





