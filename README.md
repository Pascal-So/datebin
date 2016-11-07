# datebin - Binning time values for histograms

When processing log files or similar data with time information, this script can be used to reduce the resolution of the time information to a defined interval.

## Usage

```
Usage: datebin.sh [OPTIONS] [INPUTFILE]

 -f     Fields containing the date string, default 1-2
 -d     Field delimiter, default ' '
 -w     Binwidth, default '10 minutes'
 -h     Print this help message
```

The input can either be read from a file, or if no file is given, then stdin is used.

Example:

```
in.log
---------------------------------------------
2016-10-27 14:34:41 Debug: something happened
2016-10-27 14:34:46 Debug: something happened
2016-10-27 14:35:26 Debug: something happened
2016-10-27 15:42:15 Debug: something happened
```
**Make sure that the last line has a newline at the end!**


```bash
$ ./datebin.sh in.log -w '30 minutes'
```

This will produce the following output:
```
1477571400 Debug: something happened
1477571400 Debug: something happened
1477571400 Debug: something happened
1477575000 Debug: something happened
```

This data can now for example be used in gnuplot to plot histograms over time.

Using the `-f` command, the number of fields that contain the time information (1-based) can be set. In the above case, this is fields 1 and 2, which is the default, therefore we did not have to specify it. The syntax in general is: `-f<start>-<end>` for a range of fields, where both start and end can be omitted and will be automatically adjusted to the beginning/end of the line. Alternatively, if the information is in a single field, `-f<field>` can be used as well. The date information has to be in a format that is accepted by GNU `date`.

Note that quoting fields will not stop the script from splitting them if the delimiter is found inside the quoted part.