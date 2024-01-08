#!/usr/bin/env Rscript

library(tidyverse)
library(here)

sea_ice_url <- function(hemisphere = c("north", "south")) {
  paste0(
    "https://noaadata.apps.nsidc.org/NOAA/G02135/", hemisphere,
    "/daily/data/",
    toupper(substr(hemisphere, 1, 1)),
    "_seaice_extent_daily_v3.0.csv")
}

# download and tidy the daily obs
c(sea_ice_url("south"), sea_ice_url("north")) |>
  read_csv(
    col_names = c("year", "month", "day", "extent_m_sq_km", "missing",
      "source_data"),
    skip = 2,
    id = "path") |>
  mutate(
    hemisphere =
      dirname(path) |>
      str_replace_all(c(
        "https://noaadata.apps.nsidc.org/NOAA/G02135/" = "",
        "/daily/data" = "")),
    date = ymd(paste(year, month, day)),
    nday = date - ymd(paste(year, "01", "01"))) |>
  select(hemisphere, date, nday, extent_m_sq_km) ->
sea_ice

# write dailies out to disk
sea_ice |>
  filter(hemisphere == "north") |>
  write_csv(here("data", "seaice-daily-north.csv"))
sea_ice |>
  filter(hemisphere == "south") |>
  write_csv(here("data", "seaice-daily-south.csv"))

# calculate iqr
sea_ice |>
  group_by(hemisphere, nday) |>
  summarise(
    q1 = quantile(extent_m_sq_km, 0.25, na.rm = TRUE),
    median = median(extent_m_sq_km, na.rm = TRUE),
    q3 = quantile(extent_m_sq_km, 0.75, na.rm = TRUE)) |>
  ungroup() ->
sea_ice_iqr

# write out iqr
sea_ice_iqr |>
  filter(hemisphere == "north") |>
  write_csv(here("data", "seaice-iqr-north.csv"))
sea_ice_iqr |>
  filter(hemisphere == "south") |>
  write_csv(here("data", "seaice-iqr-south.csv"))

# calculate previous minimum (ignoring this year)
sea_ice |>
  filter(year(date) != substr(Sys.Date(), 1, 4)) |>
  group_by(hemisphere) |>
  arrange(extent_m_sq_km) |>
  slice(1) |>
  ungroup() |>
  mutate(year = year(date)) |>
  select(hemisphere, year) ->
prev_lowest_year

sea_ice |>
  filter(
    hemisphere == "north",
    year(date) == (prev_lowest_year |>
      filter(hemisphere == "north") |>
      pull(year))) |>
  write_csv(here("data", "seaice-lowestyear-north.csv"))

sea_ice |>
  filter(
    hemisphere == "south",
    year(date) == (prev_lowest_year |>
      filter(hemisphere == "south") |>
      pull(year))) |>
  write_csv(here("data", "seaice-lowestyear-south.csv"))

