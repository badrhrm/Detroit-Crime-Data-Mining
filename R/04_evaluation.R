 library(tidyverse)
library(sf)

data_violent <- read_rds("data/processed/data_violent_clusters.rds")
city_profile <- read_rds("data/processed/city_profile_data.rds")

hotspot_profiles <- data_violent %>%
  st_drop_geometry() %>%
  group_by(cluster_id) %>%
  summarise(
    total_violent_crimes = n(), 
    avg_income      = mean(median_income, na.rm = TRUE),
    avg_poverty     = mean(pct_poverty, na.rm = TRUE),
    avg_unemployed  = mean(pct_unemployed, na.rm = TRUE),
    avg_vacant      = mean(pct_vacant, na.rm = TRUE),
    avg_bachelors   = mean(pct_bachelors, na.rm = TRUE),
    avg_uninsured   = mean(pct_uninsured, na.rm = TRUE),
    .groups = "drop"
  )

cor_matrix_hotspots <- cor(hotspot_profiles %>% select(-cluster_id), use = "complete.obs")

city_numeric <- city_profile %>%
  select(violent_crime_count, median_income, pct_poverty, 
         pct_unemployed, pct_vacant, pct_bachelors, pct_uninsured)

cor_matrix_city <- cor(city_numeric, use = "complete.obs")

write_rds(cor_matrix_hotspots, "data/processed/cor_matrix_hotspots.rds")
write_rds(cor_matrix_city,     "data/processed/cor_matrix_city.rds")
write_rds(hotspot_profiles,    "data/processed/hotspot_profiles.rds")

message("######### Good : Evaluation complete")