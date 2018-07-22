#!/bin/bash

# Snippet from http://stackoverflow.com/questions/11856054/bash-easy-way-to-pass-a-raw-string-to-grep
ere_quote() {
    sed 's/[]/\.|$(){}?+*^]/\\&/g' <<< "$*"
}

regex_key_trim_char_pattern="[ |\/|#]" # space(' '), /, #
regex_active_key_trim_char_pattern="[ ]" # space(' '), /, #
regex_param_key_trim_char_pattern="[ ]"

cat_regex_name=`ere_quote "$3"`

append_cat() {
	# Given category does not exist; The category must be appended.
	last_line=`tail -1 "$1"`
	if [ "$last_line" != "" ]
		then
			echo "" >> "$1"
	fi
	echo "[$2]" >> "$1"
	cat_line_num=`cat "$1" | wc -l`
	cat_line_end_num=$cat_line_num
}

no_append_cat() {
	echo "Given category doesn't exist."
	exit 1
}

search_cat() {
        # Searching for given category
        cat_line_num=`cat "$1" | grep -n "^\[$cat_regex_name\]" | grep -o "^[0-9]*"`
        if [ "$cat_line_num" = "" ]
                then
			$3 "$1" "$2"
                else
                        # Given category exists
                        cat_line_end_num=`cat "$1" | grep -n "^\[" | grep -o "^[0-9]*" | sed -n "/^$cat_line_num$/{n;p}"`
                        if [ "$cat_line_end_num" = "" ]
                                then
                                        cat_line_end_num=`cat "$1" | wc -l`
                                else
                                        cat_line_end_num=$(( cat_line_end_num - 1 ))
                        fi
        fi
}

normalize_key() {
	key=`echo "$1" | cut -d "=" -f 1 | sed "s/^$regex_param_key_trim_char_pattern*//g" | sed "s/$regex_param_key_trim_char_pattern*$//g"`
	key_regex=`ere_quote "$key"`
}

normalize_value() {
	value=`echo "$1" | cut -d "=" -f 2 | sed "s/^$regex_param_key_trim_char_pattern*//g" | sed "s/$regex_param_key_trim_char_pattern*$//g"`
	value_regex=`ere_quote "$value"`
}

append_key() {
	last_non_empty_line=`tail -n +$cat_line_num "$1" | head -n $cat_line_count | grep -n -v "^\s*$" | grep -o "^[0-9]*" | tail -1`
	last_non_empty_line=$(( cat_line_num + last_non_empty_line - 1 ))
	sed -i "$last_non_empty_line a $line_to_insert" "$1"
}

no_append_key() {
	echo "Given key doesn't exist."
	exit 1
}

replace_key() {
	sed -i "$cat_line_num,$cat_line_end_num""s/^$regex_key_trim_char_pattern*$key_regex.*/$line_to_insert/g" "$1"
}

comment_key() {
	sed -i "$cat_line_num,$cat_line_end_num""s/^$regex_active_key_trim_char_pattern*$key_regex/# $key_regex/g" "$1"
}

search_key() {
	cat_line_count=$(( cat_line_end_num - cat_line_num + 1 ))
	search_counts=`tail -n +$cat_line_num "$1" | head -n $cat_line_count | grep "^$regex_key_trim_char_pattern*$key_regex" | wc -l`

	line_to_insert="$key_regex = $value_regex"
        if [ "$search_counts" -eq "0" ]
                then
			$2 "$1"
                else
                        $3 "$1"
        fi
}

set_key() {
	search_cat "$1" "$2" append_cat

	normalize_key "$3"
	normalize_value "$3"

	search_key "$1" append_key replace_key
}

unset_key() {
	search_cat "$1" "$2" no_append_cat

	normalize_key "$3"

	search_key "$1" no_append_key comment_key
}

# Needs improvment here
touch "$1" 2> /dev/null

case $2 in
set)
	set_key "$1" "$3" "$4"
	;;
unset)
	unset_key "$1" "$3" "$4"
	;;
*)
	echo "Invalid argument given."
	echo "Usage: $0 config_file set|unset category key=value"
	echo "Example:"
	echo " 	  $0 /etc/ceilometer/ceilometer.conf set DEFAULT auth_type=password"
	echo " 	  $0 /etc/ceilometer/ceilometer.conf unset DEFAULT auth_type"
	;;
esac
