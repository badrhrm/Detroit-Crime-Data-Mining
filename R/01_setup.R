message("--- Starting Project Setup ---")

pkgs <- c(
  "tidyverse",
  "janitor",
  "lubridate",
  "sf",
  "dbscan",
  "leaflet",
  "leaflet.extras",
  "RColorBrewer",
  "viridis",
  "tigris",
  "ggrepel",
  "patchwork",
  "htmlwidgets",
  "corrplot",
  "arules",
  "arulesViz"
)

install_if_missing <- function(p) {
  if (!require(p, character.only = TRUE)) {
    install.packages(p, dependencies = TRUE)
    library(p, character.only = TRUE)
  }
}

invisible(lapply(pkgs, install_if_missing))
message("######### Good : All libraries loaded.")

folders <- c(
  "data/raw",
  "data/processed",
  "outputs/plots",
  "outputs/maps",
  "report"
)

lapply(folders, dir.create, showWarnings = FALSE, recursive = TRUE)
message("######### Good : Directory structure verified.")

options(tigris_use_cache = TRUE)

set.seed(42)

message("--- Setup Complete---")