# write_to_gha_env: write a key-value pair out to the github actions environment
# variables
write_to_gha_env <- function(key, value) {
  system2("echo", c(
    paste0(key, "=", value),
    ">>",
    "$GITHUB_ENV"))
}

# sea_ice_url: construct a url to download from based on hemisphere
sea_ice_url <- function(hemisphere = c("north", "south")) {
  paste0(
    "https://noaadata.apps.nsidc.org/NOAA/G02135/", hemisphere,
    "/daily/data/",
    toupper(substr(hemisphere, 1, 1)),
    "_seaice_extent_daily_v3.0.csv")
}