library(httr2)
library(lubridate)
library(here)
source(here("R", "util.r"))

# check the latest update time from noaa

sea_ice_url("south") |>
  request() |>
  req_method("HEAD") |>
  req_perform() ->
req_south

sea_ice_url("north") |>
  request() |>
  req_method("HEAD") |>
  req_perform() ->
req_north

# some quick error-handling

if (resp_is_error(req_north) || resp_is_error(req_north)) {
  stop("NOAA server unavailable for one or both sea ice data sources.")
}

if (
  !resp_header_exists(req_north, "Last-Modified") ||
  !resp_header_exists(req_south, "Last-Modified")) {
  stop("Cannot check update time for one or both NOAA sea ice data sources.")
}

# get the update date-times from the requests
# (they come in as GMT; we'll convert to UTC internally)
resp_header(req_north, "Last-Modified") |>
  parse_date_time("admYHMS") |>
  force_tz("GMT") ->
north_update_dt

resp_header(req_south, "Last-Modified") |>
  parse_date_time("admYHMS") |>
  force_tz("GMT") ->
south_update_dt

# compare against previous update times

last_update_path_north <- here("data", "last-monthly-update-north.txt")
last_update_path_south <- here("data", "last-monthly-update-south.txt")

# if either previous update time is missing,
# write out the new values and mark as stale
if (
  !file.exists(last_update_path_north) ||
  !file.exists(last_update_path_south)) {

  north_update_dt |>
    with_tz("UTC") |>
    as.character() |>
    writeLines(last_update_path_north)
  south_update_dt |>
    with_tz("UTC") |>
    as.character() |>
    writeLines(last_update_path_south)
  write_to_gha_env("DAILY_IS_STALE", "true")
} else {

  # otherwise, compare the times

  last_update_path_north |>
    readLines() |>
    ymd_hms(tz = "UTC") ->
  old_dt_north

  last_update_path_south |>
    readLines() |>
    ymd_hms(tz = "UTC") ->
  old_dt_south

  if (north_update_dt > old_dt_north || south_update_dt > old_dt_south) {
    # obs are out of date: write new update times and mark as stale
    north_update_dt |>
      with_tz("UTC") |>
      as.character() |>
      writeLines(last_update_path_north)
    south_update_dt |>
      with_tz("UTC") |>
      as.character() |>
      writeLines(last_update_path_south)
    write_to_gha_env("DAILY_IS_STALE", "true")
  } else {
    message("Local sources are still up to date")
    write_to_gha_env("DAILY_IS_STALE", "false")
  }
}