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

# main loop
while read line
do

    front=""
    # only try to put a value in `front` if there actually
    # is something.
    if [[ $startfield -gt 1 ]]; then
	front=$(cut -d"$delimiter" -f1-"$( $startfield - 1 )" <<<$line)
    fi
    
    back=$(cut -d"$delimiter" -f"$(( $endfield + 1 ))"- <<<$line)

    datefields=$(cut -d"$delimiter" -f"$startfield"-"$endfield" <<<$line)

    # convert the datefields to a timestamp
    timestamp=$(date -d"$datefields" +%s)

    # now do the actual binning
    timestamp=$(( $diff * ( $timestamp / $diff) ))

    # echo the final reassembled line
    echo $front $timestamp $back
        
done < "${input_file:-/dev/stdin}"
