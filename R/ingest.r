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

sea_ice_url("south") |>
  read_csv(
    col_names = c("year", "month", "day", "extent_m_sq_km", "missing",
      "source_data"),
    skip = 2) |>
  mutate(
    date = ymd(paste(year, month, day)),
    nday = date - ymd(paste(year, "01", "01"))) ->
sea_ice

# calculate iqr
sea_ice |>
  group_by(nday) |>
  summarise(
    q1 = quantile(extent_m_sq_km, 0.25, na.rm = TRUE),
    median = median(extent_m_sq_km, na.rm = TRUE),
    q3 = quantile(extent_m_sq_km, 0.75, na.rm = TRUE)) |>
  ungroup() ->
sea_ice_iqr

# calculate previous minimum
sea_ice |>
  filter(year != substr(Sys.Date(), 1, 4)) |>
  arrange(extent_m_sq_km) |>
  slice(1) |>
  pull(year) ->
prev_lowest_year

sea_ice |>
  filter(year == prev_lowest_year) ->
prev_lowest_year_obs

# and this year's data
sea_ice |>
  filter(year == substr(Sys.Date(), 1, 4)) ->
current_data

# visualise
ggplot() +
  geom_ribbon(
    aes(x = nday, ymin = q1, ymax = q3),
    data = sea_ice_iqr,
    fill = "#aaaaaa") +
  geom_line(
    aes(x = nday, y = median),
    data = sea_ice_iqr,
    colour = "#666666") +
  geom_line(
    aes(x = nday, y = extent_m_sq_km),
    data = prev_lowest_year_obs,
    colour = "#333333", linetype = "dotted") +
  geom_line(
    aes(x = nday, y = extent_m_sq_km),
    data = current_data,
    colour = "red") +
  theme_minimal() +
  labs(
    x = "Day of year", y = "Extent (M sq km)",
    title = "Antarctic sea ice extent") ->
sea_ice_plot

ggsave(here("sea_ice_south.png"), sea_ice_plot, width = 16, height = 9)
