#!/usr/bin/env bash

# If no arguments are passed
if [[ $# -lt 1 ]]; then
    echo -e "\e[31mUsage: $0 <query>\e[0m"
    exit 1
fi
QUERY=$1
PAGE=1
DEPS=(pdftotext jq httpie)
HEADERS=(
	'User-Agent:Mozilla/5.0 (X11; Linux x86_64)'
	'Cookie:justiceGovAgeVerified=true'
)
RED='\e[31m'
YEL='\e[33m'
GRN='\e[32m'
DEF='\e[0m'

dependency_check () {
	echo -e "$YEL \nDependency control... $DEF"
	local dep_status=0
	for i in "${DEPS[@]}"; do
		printf "Checking %s -> " "$i"
		if command -v "$i" &>/dev/null; then echo "passed"; ((dep_status++)); else echo "failed"; fi
	done

	if [[ "$dep_status" -ne "${#DEPS[@]}" ]]; then
		echo -e "$RED\nThere are missing packages. Please install them to use grepstein.sh $DEF"
		exit 1
	fi
}

fetch_results () {
	URL="https://www.justice.gov/multimedia-search?keys=$QUERY&page=$PAGE"
	DATA=$(http GET "$URL" "${HEADERS[@]}" | jq)
	TOTAL_RECORDS=$(echo "$DATA" | jq '.hits.total.value')
	PDF_URLS=($(echo "$DATA" | jq -r '.hits.hits[]._source.ORIGIN_FILE_URI' | sed 's/ /%20/g'))
	PDF_COUNT=${#PDF_URLS[@]}

	#echo "$DATA"

	echo -e "$GRN \nWe found $TOTAL_RECORDS result(s) for $QUERY on all pages. Page $PAGE only shows $PDF_COUNT result(s) $DEF"

	if [[ "$PDF_COUNT" -gt 0 ]]; then
		for i in "${!PDF_URLS[@]}"; do
			echo "$i - ${PDF_URLS[i]}"
		done
	fi
}

ask_usrcmd () {
    if [[ "$PDF_COUNT" -gt 0 ]]; then
        echo -e "$GRN \nPlease select your action $DEF"
        echo "-> Type OPEN to open a file"
        echo "-> Type NEXT to continue to next page"
        echo "-> Type EXIT to exit"
        echo -n "Your command : "
        read USRCMD

        USRCMD=${USRCMD,,}

        case "$USRCMD" in
            open)
                echo -ne "$GRN \nPlease write the index number of the file that you want to open : $DEF"
                read INDEX

		if ! [[ "$INDEX" =~ ^[0-9]+$ ]] || (( INDEX < 0 || INDEX >= PDF_COUNT )); then
        		echo -e "$RED \nInvalid index. Please choose a number between 0 and $((PDF_COUNT-1)). $DEF"
        		ask_usrcmd
        		return
    		fi

                http "${PDF_URLS[$INDEX]}" "${HEADERS[@]}" > /tmp/epstein_file.pdf
                pdftotext -layout /tmp/epstein_file.pdf - | less
                rm /tmp/epstein_file.pdf
                fetch_results
                ask_usrcmd
                ;;
            next)
                echo -e "$YEL \nProceding to next page... $DEF"
                let "PAGE+=1"
                fetch_results
                ask_usrcmd
                ;;
            exit)
                echo -e "$YEL \nExiting... $DEF"
                exit 1
                ;;
            *)
                echo -e "$RED \nInvalid command, please enter a valid command. $DEF"
                ask_usrcmd
                ;;
        esac
    fi
}

dependency_check
fetch_results
ask_usrcmd
