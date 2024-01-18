#!/usr/bin/env Rscript

library(tidyverse)
library(here)
source(here("R", "util.r"))

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
  select(hemisphere, date, nday, extent_m_sq_km) |>
  filter(year(date) > 1978) |>
  arrange(hemisphere, date) ->
sea_ice

# otherwise, write dailies out to disk
sea_ice |>
  filter(hemisphere == "north") |>
  write_csv(here("data", "seaice-daily-north.csv"))
sea_ice |>
  filter(hemisphere == "south") |>
  write_csv(here("data", "seaice-daily-south.csv"))

# calculate iqr
sea_ice |>
  group_by(hemisphere, nday) |>
  filter(year(date) != substr(Sys.Date(), 1, 4)) |>
  summarise(
    min = min(extent_m_sq_km, na.rm = TRUE),
    q1 = quantile(extent_m_sq_km, 0.25, na.rm = TRUE),
    mean = mean(extent_m_sq_km, na.rm = TRUE),
    median = median(extent_m_sq_km, na.rm = TRUE),
    q3 = quantile(extent_m_sq_km, 0.75, na.rm = TRUE),
    max = max(extent_m_sq_km, na.rm = TRUE),) |>
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
    year(date) ==
      (prev_lowest_year |> filter(hemisphere == "north") |> pull(year))) |>
  write_csv(here("data", "seaice-lowestyear-north.csv"))

sea_ice |>
  filter(
    hemisphere == "south",
    year(date) ==
      (prev_lowest_year |> filter(hemisphere == "south") |> pull(year))) |>
  write_csv(here("data", "seaice-lowestyear-south.csv"))

# finally, write out this year
sea_ice |>
  filter(
    hemisphere == "north",
    year(date) == substr(Sys.Date(), 1, 4)) |>
  write_csv(here("data", "seaice-thisyear-north.csv"))

sea_ice |>
  filter(
    hemisphere == "south",
    year(date) == substr(Sys.Date(), 1, 4)) |>
  write_csv(here("data", "seaice-thisyear-south.csv"))

# finally, write out annual stats
sea_ice |>
  mutate(year = year(date)) |>
  filter(year != substr(Sys.Date(), 1, 4)) |>
  group_by(year, hemisphere) |>
  summarise(
    min = min(extent_m_sq_km, na.rm = TRUE),
    mean = mean(extent_m_sq_km, na.rm = TRUE),
    max = max(extent_m_sq_km, na.rm = TRUE)) |>
  ungroup() ->
sea_ice_annual

sea_ice_annual |>
  filter(
    hemisphere == "north",
    year != substr(Sys.Date(), 1, 4)) |>
  write_csv(here("data", "seaice-annual-north.csv"))

sea_ice_annual |>
  filter(
    hemisphere == "south",
    year != substr(Sys.Date(), 1, 4)) |>
  write_csv(here("data", "seaice-annual-south.csv"))

# record update time for subsequent steps (basically to insert into slack msg)
write_to_gha_env("DAILY_UPDATED", "true")
write_to_gha_env("DAILY_RUN_END", Sys.time())
message("Successfully updated!")
