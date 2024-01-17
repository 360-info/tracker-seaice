
# `/data`

This dataset updates daily based on upstream updates from the [Sea Ice Index](https://nsidc.org/data/g02135/versions/3) dataset ([NSIDC](https://nsidc.org)).

## Processed data

The processed observations are:

- `seaice-daily-[north|south].csv`: historical observations for either the Arctic (`north`) or Antarctic (`south`)
- `seaice-annual-[north|south].csv`: annual statistics (min, mean and max) for each complete year on the record
- `seaice-lowestyear-[north|south].csv`: observations filtered to the year of the lowest observation (excluding this year)
- `seaice-thisyear-[north|south].csv`: observations filtered to this year 
- `seaice-iqr-[north|south].csv`: the interquartile range for each day of the year over the historical period (excluding the current year). Columns include:
  - `hemisphere`: `north` or `south`
  - `nday`: The day of the year (0-366)
  - `q1`: The first quartile of the extent for this day
  - `median`: The median of the extent for this day 
  - `q3`: The third quartile of the extent for this day

If you want to create a chart that updates automatically based on one of these files (eg. in Flourish, which [supports live data sources](https://help.flourish.studio/article/163-how-to-connect-to-live-data-sources)), navigate to one of these files in GitHub, click on the "Raw" button and then copy the URL from the address bar (do not right-click the button and copy the link—it redirects).

For example, the raw URL for `monthly-all.csv` is:

```
https://raw.githubusercontent.com/360-info/tracker-seaice/main/data/seaice-daily-south.csv
```
## Other files

`last-monthly-update-[north|south].txt` is a datestamp of the time of the last update on NSIDC's end. We save this at the end of an update to avoid unnecessary updates when no new data is available.
