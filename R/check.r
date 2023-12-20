#!/usr/bin/env Rscript

library(here)
source(here("R", "util.r"))

# check whether obs are stale based on the date-time of the last update
north_is_stale <- check_remote_obs_stale("north")
south_is_stale <- check_remote_obs_stale("south")

stopifnot(
  "Error: check_remote_obs_stale() returned a missing value." =
    !is.na(is_stale))

# save whether obs are stale to env var $MONTHLY_IS_STALE for later steps
message("Are northern observations stale? ", north_is_stale)
message("Are southern observations stale? ", south_is_stale)
write_to_gha_env("NORTH_IS_STALE", north_is_stale)
write_to_gha_env("SOUTH_IS_STALE", south_is_stale)
