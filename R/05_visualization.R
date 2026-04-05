library(tidyverse)
library(sf)
library(leaflet)
library(leaflet.extras)
library(RColorBrewer)
library(htmlwidgets)
library(patchwork)
library(corrplot)


dir.create("outputs/plots", recursive = TRUE, showWarnings = FALSE)
dir.create("outputs/maps", recursive = TRUE, showWarnings = FALSE)

df_tract      <- read_rds("data/processed/df_tract.rds")
detroit_socio <- read_rds("data/processed/detroit_socio.rds")
data_all      <- read_rds("data/processed/data_all_clusters.rds")
data_violent  <- read_rds("data/processed/data_violent_clusters.rds")
data_property <- read_rds("data/processed/data_property_clusters.rds")

map_data <- detroit_socio %>%
  inner_join(df_tract, by = c("GEOID" = "census_tract_geoid")) %>%
  st_transform(4326)

map_violent <- ggplot(map_data) +
  geom_sf(aes(fill = pct_Violent), color = "white", size = 0.1) +
  scale_fill_viridis_c(option = "magma", direction = -1) +
  theme_void() +
  labs(title = "Detroit Violent Crime Concentration", fill = "% Violent")

map_property <- ggplot(map_data) +
  geom_sf(aes(fill = pct_Property), color = "white", size = 0.1) +
  scale_fill_viridis_c(option = "mako", direction = -1) +
  theme_void() +
  labs(title = "Detroit Property Crime Concentration", fill = "% Property")

ggsave("outputs/plots/01_violent_map.png", map_violent, width = 10, height = 8, bg = "white")
ggsave("outputs/plots/02_property_map.png", map_property, width = 10, height = 8, bg = "white")

scatter_plot <- ggplot(df_tract, aes(x = pct_Property, y = pct_Violent)) +
  geom_point(aes(size = crimes_total, color = severity_absolute), alpha = 0.7) +
  scale_color_viridis_c(option = "inferno") +
  theme_minimal()

bar_severity <- df_tract %>%
  top_n(20, severity_absolute) %>%
  mutate(census_tract_geoid = reorder(census_tract_geoid, severity_absolute)) %>%
  ggplot(aes(x = census_tract_geoid, y = severity_absolute, fill = is_high_risk_violent)) +
  geom_col() + 
  coord_flip() + 
  theme_minimal() +
  scale_fill_manual(values = c("Standard" = "#4C566A", "High Risk" = "#BF616A"))

ggsave("outputs/plots/03_vibe_scatter.png", scatter_plot, width = 10, height = 6, bg = "white")
ggsave("outputs/plots/04_severity_bar.png", bar_severity, width = 10, height = 7, bg = "white")

create_crime_map <- function(map_data, title_name) {
  
  map_data <- st_transform(map_data, crs = 4326)
  coords <- st_coordinates(map_data)
  
  map_data <- map_data %>% 
    mutate(
      longitude = coords[, "X"],
      latitude  = coords[, "Y"]
    )
  
  num_clusters <- length(unique(map_data$cluster_id))
  pal <- colorFactor(colorRampPalette(brewer.pal(9, "Set1"))(num_clusters), map_data$cluster_id)
  standard_gradient <- c("#00000000", "#4169E1", "#32CD32", "#FFD700", "#FF0000")
  
  leaflet(data = map_data) %>%
    addProviderTiles(providers$CartoDB.Positron) %>%
    addHeatmap(lng = ~longitude, lat = ~latitude, blur = 20, max = 0.05, radius = 15, gradient = standard_gradient) %>%
    addCircleMarkers(lng = ~longitude, lat = ~latitude, color = ~pal(cluster_id), radius = 2, stroke = FALSE, fillOpacity = 0.6)
}

saveWidget(create_crime_map(data_all, "All"), file.path(getwd(), "outputs/maps", "01_hotspots_all.html"), selfcontained = TRUE)
saveWidget(create_crime_map(data_violent, "Violent"), file.path(getwd(), "outputs/maps", "02_hotspots_violent.html"), selfcontained = TRUE)
saveWidget(create_crime_map(data_property, "Property"), file.path(getwd(), "outputs/maps", "03_hotspots_property.html"), selfcontained = TRUE)




cor_matrix_hotspots <- read_rds("data/processed/cor_matrix_hotspots.rds")
cor_matrix_city      <- read_rds("data/processed/cor_matrix_city.rds")

png("outputs/plots/05_correlation_hotspots.png", width = 800, height = 800, res = 120)
corrplot(cor_matrix_hotspots, 
         method = "color", 
         type = "upper",        
         addCoef.col = "black", 
         tl.col = "black",      
         tl.srt = 45,            
         diag = FALSE,          
         col = colorRampPalette(c("#8B0000", "white", "#00008B"))(200), 
         title = "What Drives Violent Crime Hotspots in Detroit?",
         mar = c(0,0,2,0))      
dev.off()

png("outputs/plots/06_correlation_city.png", width = 800, height = 800, res = 120)
corrplot(cor_matrix_city, 
         method = "color", type = "upper", 
         addCoef.col = "black", tl.col = "black", tl.srt = 45, diag = FALSE,
         col = colorRampPalette(c("#8B0000", "white", "#00008B"))(200),
         title = "The True Drivers of Violent Crime (City-Wide)",
         mar = c(0,0,2,0))
dev.off()

message(" Correlation plots saved to 'outputs/plots/'")

library(arulesViz)

top_rules <- read_rds("data/processed/top_association_rules.rds")

network_graph <- plot(head(top_rules, 20), 
                      method = "graph", 
                      engine = "htmlwidget", 
                      control = list(
                        main = "Detroit Crime Drivers: Association Network",
                        cex = 1.2 
                      ))

saveWidget(network_graph, file = file.path(getwd(), "outputs/maps", "04_rules_network_graph.html"), selfcontained = TRUE)
message("Network Graph saved to 'outputs/maps/'")

message("######### Good : All visualizations and interactive maps are saved ")