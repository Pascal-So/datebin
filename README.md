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