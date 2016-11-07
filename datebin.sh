#!/bin/bash

# round down date columns to the nearest value according to
# the bin width. Output is always as timestamp

# Pascal Sommer, November 2016


# set defaults
fields=1-2
delimiter=' '
binwidth='10 minutes'

HELPSTRING="Usage: datebin.sh [OPTIONS] [INPUTFILE]\n"
HELPSTRING+="\n"
HELPSTRING+="  -f \tFields containing the date string, default 1-2\n"
HELPSTRING+="  -d \tField delimiter, default ' '\n"
HELPSTRING+="  -w \tBinwidth, default '10 minutes'\n"
HELPSTRING+="  -h \tPrint this help message\n"

# Using this function to join the fields back together in
# the end.
# 
# Credit to:
# http://stackoverflow.com/a/17841619/5817996
function join_by { local IFS="$1"; shift; echo "$*"; }

# get file name if passed as first argument
if [ $# -ge 1 ] && [ ${1:0:1} != "-" ]; then
    input_file=$1
    shift
fi

while getopts ":f:w:d:h" opt; do
    case $opt in
	f)
	    fields=$OPTARG
	    ;;
	w)
	    binwidth=$OPTARG
	    ;;
	d)
	    delimiter=$OPTARG
	    ;;
	h)
	    echo -e $HELPSTRING >&2
	    exit 0
	    ;;
	\?)
	    echo -e "ERROR: Unknown option -$OPTARG\n" >&2
	    echo -e $HELPSTRING >&2
	    exit 1
	    ;;
	:)
	    echo -e "ERROR: Option -$OPTARG requires an option argument\n" >&2
	    echo -e $HELPSTRING >&2
	    exit 1
	    ;;
    esac
done

# get filename if passed as last argument
shift $(($OPTIND - 1))
if [ $# -ge 1 ]; then
    input_file=$1
    shift
fi

# calculate the binwidth in seconds
soon=$(date -d"$binwidth" +%s)
now=$(date +%s)
diff=$(( $soon - $now ))


# extract the fields values
if [[ $fields =~ ^([1-9]*)-([1-9]*)$ ]]; then
    startfield=${BASH_REMATCH[1]}
    endfield=${BASH_REMATCH[2]}
    if [[ $startfield -eq "" ]]; then
        startfield=1
    fi
    if [[ $endfield -eq "" ]]; then
	endfield=999
    fi
    if [[ $startfield -gt $endfield ]]; then
	# exit if invalid fields numbers are given (e.g. 2-1)
	echo "Invalid fields description: $fields" >&2
	exit 1
    fi
elif [[ $fields =~ ([1-9]+) ]]; then
    startfield=${BASH_REMATCH[1]}
    endfield=${BASH_REMATCH[1]}
else
    echo "Invalid fields description: $fields" >&2
    exit 1
fi

# convert base 1 indexes to base 0
startfield=$(( $startfield - 1 ))
endfield=$(( $endfield - 1 ))

#echo "Startfield = $startfield";
#echo "Endfield = $endfield";

# main loop
while read line
do
    # split the current line by $delimiter
    IFS="$delimiter" read -ra FIELDS <<< "$line"
    
    if [[ ${#FIELDS[@]} -le $startfield ]]; then
	#ignore lines where startfield is outside the range
	continue
    fi

    # use temporary variable for end field, because line
    # length might vary
    tempEnd=$endfield;
    if [[ $tempEnd -ge ${#FIELDS[@]} ]]; then
	tempEnd=$(( ${#FIELDS[@]} - 1 ))
    fi

    # now we should have always valid, 0-based, inclusive
    # indexes of the date fields

    len=$(( $tempEnd - $startfield + 1 ))
    datefields="${FIELDS[@]:$startfield:$len}"

    # convert the datefields to a timestamp
    timestamp=$(date -d"$datefields" +%s)

    # now do the actual binning
    timestamp=$(( $diff * ( $timestamp / $diff) ))
    
    # now get the remaining fields of the array so that we
    # can reassemble it later

    front="${FIELDS[@]:0:$startfield}"

    # start fields after datefields from tempEnd + 1
    backpos=$(( $tempEnd + 1 ))
    back="${FIELDS[@]:$backpos}"

    # echo the final reassembled line
    echo $front $timestamp $back
    
done < "${input_file:-/dev/stdin}"
