library(arules)

master_data <- read_rds("data/processed/master_cleaned_data.rds")

get_hotspots <- function(data, eps_val = 250, min_pts = 200) {
  coords <- st_coordinates(data)
  
  db_res <- dbscan(coords, eps = eps_val, minPts = min_pts)
  
  data %>%
    mutate(cluster_id = as.factor(db_res$cluster)) %>%
    filter(cluster_id != "0") 
}

hotspots_violent <- master_data %>%
  filter(offense_group == "Violent") %>%
  get_hotspots(eps_val = 250, min_pts = 70)

hotspots_property <- master_data %>%
  filter(offense_group == "Property") %>%
  get_hotspots(eps_val = 250, min_pts = 150)

hotspots_all <- master_data %>%
  get_hotspots(eps_val = 250, min_pts = 200)

write_rds(hotspots_all,      "data/processed/data_all_clusters.rds")
write_rds(hotspots_violent,  "data/processed/data_violent_clusters.rds")
write_rds(hotspots_property, "data/processed/data_property_clusters.rds")

city_data <- read_rds("data/processed/city_profile_data.rds") %>% drop_na()

rules_data <- city_data %>%
  mutate(
    Crime_Level = discretize(violent_crime_count, method = "fixed", 
                             breaks = c(-Inf, 0, 34, Inf), 
                             labels = c("Safe (Zero Crime)", "Moderate Crime", "High Danger")),
    Income = discretize(median_income, method = "cluster", breaks = 3, 
                        labels = c("Under $38k", "$38k - $79k", "Over $79k")),
    Vacancy = discretize(pct_vacant, method = "fixed", 
                         breaks = c(-Inf, 5, 15, Inf), 
                         labels = c("Low Vacancy(<5%)", "Moderate Vacancy", "High Vacancy (>15%)")),
    Uninsured = discretize(pct_uninsured, method = "frequency", breaks = 3, 
                           labels = c("Good Health Coverage", "Average Coverage", "Poor Coverage")),
    Education = discretize(pct_bachelors, method = "cluster", breaks = 3, 
                           labels = c("Low Degrees", "Average Degrees", "High Degrees")),
    Unemployment = discretize(pct_unemployed, method = "fixed", 
                              breaks = c(-Inf, 5, 10, Inf),
                              labels = c("Low Unemployment", "Med Unemployment", "High Unemployment (>10%)"))
  ) %>%
  select(Vacancy, Education, Income, Unemployment, Crime_Level)

transactions <- as(rules_data, "transactions")

final_rules <- apriori(
  transactions, 
  parameter = list(supp = 0.02, conf = 0.40, maxlen = 3),
  appearance = list(default="lhs", rhs=c("Crime_Level=High Danger", "Crime_Level=Safe (Zero Crime)")),
  control = list(verbose = FALSE)
)

top_rules <- sort(final_rules, by = "lift")
write_rds(top_rules, "data/processed/top_association_rules.rds")

dir.create("outputs/tables", showWarnings = FALSE, recursive = TRUE)
write_csv(as(top_rules, "data.frame"), "outputs/tables/01_association_rules_report.csv")

message("######### Good : Modeling complete")