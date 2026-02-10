#!/usr/bin/env bash

if [[ $1 == "--fzf" ]]; then
	shift
	FZF=true
else
	FZF=false
fi

QUERY="$*"
PAGE=1
DEPS=(pdftotext jq httpie)
TMP_PDF="/tmp/epstein_file.pdf"
HEADERS=(
	'User-Agent:Mozilla/5.0 (X11; Linux x86_64)'
	'Cookie:justiceGovAgeVerified=true'
)
RED=$'\e[31m'
YEL=$'\e[33m'
GRN=$'\e[32m'
DEF=$'\e[0m'

cleanup() {
	for file in "$TMP_PDF" "$TMP_TXT"
	do
		[[ -f "$file" ]] && rm -f "$file"
	done
}

trap 'cleanup' EXIT

if [[ -z $QUERY ]]; then
	echo -e "$RED Please provide a valid search term. $DEF"
	exit 1
fi


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
	mapfile -t PDF_URLS < <(echo "$DATA" | jq -r '.hits.hits[]._source.ORIGIN_FILE_URI' | sed 's/ /%20/g')
	PDF_COUNT=${#PDF_URLS[@]}

	[[ $1 == "--quiet" ]] && return 0

	echo -e "$GRN \nWe found $TOTAL_RECORDS result(s) for ${QUERY} on all pages. Page $PAGE only shows $PDF_COUNT result(s) $DEF"

	if [[ "$PDF_COUNT" -gt 0 ]]; then
	for i in "${!PDF_URLS[@]}"; do
			echo "$i - ${PDF_URLS[i]}"
		done
	fi
}

ask_usrcmd () {
	if [[ "$PDF_COUNT" -gt 0 ]]; then
		while true; do
			echo -e "$GRN \nPlease select your action $DEF"
			echo "-> Type OPEN to open a file"
			echo "-> Type NEXT to continue to next page"
			echo "-> Type EXIT to exit"
			echo -n "Your command : "
			read -r USRCMD

			USRCMD="${USRCMD,,}"

			case "$USRCMD" in
				open)
					echo -ne "$GRN \nPlease write the index number of the file that you want to open : $DEF"
					read -r INDEX
					if [[ $INDEX -ge 0 && $INDEX -lt $PDF_COUNT ]]; then
						http "${PDF_URLS[INDEX]}" "${HEADERS[@]}" > "$TMP_PDF"
						pdftotext -layout "$TMP_PDF" - | less
						rm "$TMP_PDF"
						fetch_results
					else
						echo -e "$RED \nPlease Provide a valid index number $DEF"
					fi
					;;
				next)
					echo -e "$YEL \nProceding to next page... $DEF"
					((PAGE++))
					fetch_results
					;;
				exit)
					echo -e "$YEL \nExiting... $DEF"
					break
					;;
				*)
					echo -e "$RED \nInvalid command, please enter a valid command. $DEF"
					;;
			esac
		done
	fi
}

dependency_check

if ! $FZF
then
	fetch_results
	ask_usrcmd
	exit 0
fi

# fzf option

command -v fzf &>/dev/null \
|| { printf "fzf is not installed\n" 2>&1; exit 1; }

TMP_TXT="/tmp/epstein_file.txt"
export QUERY TMP_PDF TMP_TXT RED DEF

get_file() {
	local URL="$1"
	local -a HEADERS

	HEADERS=(
		'User-Agent:Mozilla/5.0 (X11; Linux x86_64)'
		'Cookie:justiceGovAgeVerified=true'
	)

	http GET "$URL" "${HEADERS[@]}" > "$TMP_PDF"
	pdftotext -layout "$TMP_PDF" > "$TMP_TXT"
	sed -i "s/${QUERY}/${RED}&${DEF}/gI" "$TMP_TXT"
}

preview() {
	get_file "$1"
	cat "$TMP_TXT"
}

get_all_urls() {
	local page

	while true
	do
		fetch_results --quiet

		page=$(
			for URL in "${PDF_URLS[@]}"
			do
				printf "%s\n" "$URL"
			done
		)

		[[ $page == "$old_page" || -z "$page" ]] && break
		old_page="$page"

		printf "%s\n" "$page"
		((PAGE++))
	done
}

export -f fetch_results get_file preview

header+="┌─┐┬─┐┌─┐┌─┐┌─┐┌┬┐┌─┐X┌┐┌"$'\n'
header+="│ ┬├┬┘├┤ ├─┘└─┐ │ ├┤ ││││"$'\n'
header+="└─┘┴└─└─┘┴  └─┘ ┴ └─┘┘┘└┘"

fzf_opts=(
	--reverse
	--header-first
	--header "$header"
	--color "header:red:bold"
	--preview 'bash -c "preview {}"'
)

file=$(get_all_urls | fzf "${fzf_opts[@]}")
[[ -n "$file" ]] || exit 0

get_file "$file"
less -R "$TMP_TXT"
