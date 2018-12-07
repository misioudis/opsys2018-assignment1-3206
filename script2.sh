#!/bin/bash

base_repo_dir="assignments/"

if [[ $# -eq 0 ]] ; then
	echo "Please provide at least one tar.gz file as an argument"
	exit 1
fi
dir_list=()

function proccess_files() {
	tar=$1 && shift
	files=($@)
	for file in "${files[@]}" ; do
		repo="$(tar -axf $tar $file -O | grep '^https' | head -n 1)"
		repo_name=$(basename $repo .git) &> /dev/null
		repo_dir=$base_repo_dir$repo_name
		GIT_TERMINAL_PROMPT=0 git clone --quiet $repo $repo_dir &> /dev/null
		if [[ -d $repo_dir ]] ; then
			echo "$repo: Cloning OK"
			dir_list+=( "$repo_dir" )
		else
			(>&2 echo "$repo: Cloning FAILED")
		fi
	done
}

for tar in "$@" ; do
        files=($(tar -tzf $tar |  egrep '\.txt$'))
        proccess_files $tar "${files[@]}"
done


for dir in ${dir_list[@]} ; do
	repo_name=$(basename $dir)
	echo "$repo_name:"

	directories=$(find $dir -type d -not -path '*/\.*' -not -name "$repo_name")
	txt_files=$(find $dir -type f -name "*.txt")
	other_files=$(find $dir -not -path '*/\.*' -type f -not -name "*.txt")

	dir_num=$(echo "$directories" | grep -c "[^ \\n\\t]")          # use "grep -c" instead of "wc -l" because wc counts empty lines, so if "$directories" is empty then wc will count 1!!
	txt_file_num=$(echo "$txt_files" |  grep -c "[^ \\n\\t]")
	other_file_num=$(echo "$other_files" | grep -c "[^ \\n\\t]")

	echo "Number of directories: $dir_num"
	echo "Number of txt files: $txt_file_num"
	echo "Number of other files: $other_file_num"

	ok_flag=true
	if [[ "$dir_num" -eq 1 ]] && [[ "$txt_file_num" -eq 3 ]] && [[ "$other_file_num" -eq 0 ]] ; then
		[[ ! -f $dir/dataA.txt ]] && ok_flag=false
		[[ ! -f $dir/more/dataB.txt ]] && ok_flag=false
		[[ ! -f $dir/more/dataC.txt ]] && ok_flag=false
	else 
		ok_flag=false
	fi
	[[ "$ok_flag" = "false" ]] && (>&2 echo "Directory structure is NOT OK.") || echo "Directory structure is OK."
done

exit
