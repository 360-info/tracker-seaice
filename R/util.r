library(dplyr)
library(lubridate)
library(readr)
library(rvest)

#' Get the date-time of the last update for either the northern or southern
#' hemisphere sea ice index.
#' 
#' @return A date-time.
get_update_dt <- function(hemisphere = c("north", "south")) {
  paste0(
    "https://noaadata.apps.nsidc.org/NOAA/G02135/", hemisphere,
    "/daily/data/") |>
    read_html() |>
    html_element("pre") |>
    html_text2() |>
    read_table(col_names = c("file", "date", "time", "size")) |>
    filter(file == "S_seaice_extent_daily_v3.0.csv") |>
    mutate(dt = dmy_hms(paste(date, time))) |>
    pull(dt)
}

#' Determine whether new monthly observations are available
#' 
#' @return A boolean. True if new obs are available for download, or if obs have
#'   never been downloaded
check_remote_obs_stale <- function() {
  last_update_path <- here("data", "last-update.txt")

  (!file.exists(last_update_path)) ||
    (get_update_dt() > (last_update_path |> readLines() |> ymd_hms())
  )
}

#' Writes the given key-value pair to an environment variable in github
#' actions, for use by subsequent action steps.
write_to_gha_env <- function(key, value) {
  system2("echo", c(
    paste0(key, "=", value),
    ">>",
    "$GITHUB_ENV"))
}