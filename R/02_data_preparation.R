library(tidyverse)
library(sf)
library(janitor)
library(tigris)
library(stringr)

options(tigris_use_cache = TRUE)

if (!dir.exists("data/processed")) {
  dir.create("data/processed", recursive = TRUE)
}

path <- "data/raw/"
files <- list.files(path, pattern = "RMS_Crime_Incidents_\\d{4}\\.csv", full.names = TRUE)

df_raw <- read_csv(files, id = "file_source", show_col_types = FALSE) %>%
  clean_names()

df_clean <- df_raw %>%
  distinct(incident_entry_id, .keep_all = TRUE) %>% 
  filter(!is.na(longitude), !is.na(latitude)) %>%
  mutate(
    census_block_2020_geoid = format(census_block_2020_geoid, scientific = FALSE),
    census_tract_geoid = str_sub(census_block_2020_geoid, 1, 11),
    time_of_day = if_else(incident_hour_of_day >= 6 & incident_hour_of_day < 18, "Daytime", "Nighttime"),
    offense_group = case_when(
      offense_category %in% c("ASSAULT", "AGGRAVATED ASSAULT", "HOMICIDE", "JUSTIFIABLE HOMICIDE", 
                              "SEXUAL ASSAULT", "SEX OFFENSES", "ROBBERY", "KIDNAPPING") ~ "Violent",
      offense_category %in% c("LARCENY", "DAMAGE TO PROPERTY", "STOLEN VEHICLE", 
                              "BURGLARY", "STOLEN PROPERTY", "ARSON") ~ "Property",
      offense_category %in% c("FRAUD", "FORGERY", "EXTORTION") ~ "Fraud",
      offense_category %in% c("WEAPONS OFFENSES", "DANGEROUS DRUGS", "OUIL",
                              "DISORDERLY CONDUCT", "LIQUOR", "GAMBLING", "SOLICITATION") ~ "Public_Order",
      TRUE ~ "Other"
    )
  ) %>%
  filter(!is.na(census_tract_geoid), offense_group != "Other")

df_tract <- df_clean %>%
  group_by(census_tract_geoid) %>%
  summarise(
    crimes_Violent      = sum(offense_group == "Violent", na.rm = TRUE),
    crimes_Property     = sum(offense_group == "Property", na.rm = TRUE),
    crimes_Fraud        = sum(offense_group == "Fraud", na.rm = TRUE),
    crimes_Public_Order = sum(offense_group == "Public_Order", na.rm = TRUE),
    time_Daytime        = sum(time_of_day == "Daytime", na.rm = TRUE),
    time_Nighttime      = sum(time_of_day == "Nighttime", na.rm = TRUE),
    crimes_total        = n(), 
    .groups = "drop"
  ) %>%
  mutate(
    pct_Violent      = round((crimes_Violent / crimes_total) * 100, 1),
    pct_Property     = round((crimes_Property / crimes_total) * 100, 1),
    pct_Fraud        = round((crimes_Fraud / crimes_total) * 100, 1),
    pct_Public_Order = round((crimes_Public_Order / crimes_total) * 100, 1),
    pct_Nighttime    = round((time_Nighttime / crimes_total) * 100, 1),
    pct_Daytime      = round((time_Daytime / crimes_total) * 100, 1),
    
    severity_absolute = (crimes_Violent * 5) + (crimes_Property * 2) + (crimes_Fraud * 1) + (crimes_Public_Order * 1),
    severity_relative = round(severity_absolute / crimes_total, 2),
    
    is_high_risk_violent = if_else(pct_Violent > mean(pct_Violent, na.rm = TRUE), 
                                   "High Risk", "Standard")
  )

path_acs <- "data/raw/"

dp02 <- read_csv(file.path(path_acs, "ACSDP5Y2024.DP02-Data.csv")) %>% slice(-1)
dp03 <- read_csv(file.path(path_acs, "ACSDP5Y2024.DP03-Data.csv")) %>% slice(-1)
dp04 <- read_csv(file.path(path_acs, "ACSDP5Y2024.DP04-Data.csv")) %>% slice(-1)

socio_tabular <- dp03 %>%
  select(
    GEO_ID, 
    median_income = DP03_0062E, 
    pct_poverty = DP03_0128PE, 
    pct_unemployed = DP03_0009PE,
    pct_uninsured = DP03_0099PE 
  ) %>%
  left_join(dp02 %>% select(GEO_ID, pct_bachelors = DP02_0068PE), by = "GEO_ID") %>%
  left_join(dp04 %>% select(GEO_ID, pct_vacant = DP04_0003PE), by = "GEO_ID") %>%
  mutate(
    GEOID = str_remove(GEO_ID, "1400000US"),
    across(c(median_income, pct_poverty, pct_unemployed, pct_uninsured, pct_bachelors, pct_vacant), as.numeric)
  )

detroit_socio <- tracts(state = "MI", county = "Wayne", year = 2022, cb = TRUE) %>%
  inner_join(socio_tabular, by = "GEOID") %>%
  st_transform(crs = 2253)

detroit_combined <- detroit_socio %>%
  left_join(df_tract, by = c("GEOID" = "census_tract_geoid"))

df_crime_sf <- st_as_sf(df_clean, coords = c("longitude", "latitude"), crs = 4326) %>%
  st_transform(crs = 2253)

master_data <- st_join(df_crime_sf, detroit_combined, join = st_intersects) %>%
  filter(!is.na(GEOID))

city_profile <- detroit_socio %>%
  left_join(df_tract %>% select(census_tract_geoid, violent_crime_count = crimes_Violent), 
            by = c("GEOID" = "census_tract_geoid")) %>%
  mutate(violent_crime_count = replace_na(violent_crime_count, 0)) %>%
  st_drop_geometry() %>%
  select(violent_crime_count, median_income, pct_poverty, 
         pct_unemployed, pct_vacant, pct_bachelors, pct_uninsured)

write_rds(city_profile, "data/processed/city_profile_data.rds")
write_rds(master_data, "data/processed/master_cleaned_data.rds") 
write_rds(df_tract, "data/processed/df_tract.rds")                
write_rds(detroit_socio, "data/processed/detroit_socio.rds")

message("######### Good : Data preparation complete.")