# Uncovering the Socio-Economic Factors of Detroit Crime
### A Spatial Clustering and Association Rule Mining Approach

This project explores the non-linear relationships between neighborhood distress and violent crime in Detroit. Instead of relying on simple heatmaps, we built an automated R pipeline to integrate over 500,000 police reports with 2024 Census socio-economic data to find patterns that drive urban hotspots.

## Key Discoveries
* We discovered a specific neighborhood profile (**High Education + Low Income**) that results in a **100% confidence** of being a high-danger zone (Lift: 2.23).
* Neighborhoods with over 15% housing vacancy combined with economic distress have a **91.3% probability** of being crime hotspots.
* While poverty is a strong predictor of where a crime hotspot will form city-wide, our models reveal that these areas eventually reach a saturation point. Once a hotspot is established, local income levels lose their impact. Instead, the physical environment, specifically abandoned buildings and unemployment takes over as the primary driver of violence, overtaking household income in determining how dangerous the neighborhood remains.
---

## Data Sources
This project integrates two data sources:

### 1. US Census Bureau (ACS 2024 5-Year Estimates)
* **[DP02 | Selected Social Characteristics](https://data.census.gov/table/ACSDP5Y2024.DP02?q=DP02:+Selected+Social+Characteristics+in+the+United+States&g=050XX00US26163$1400000&y=2024)** (Educational attainement)
* **[DP03 | Selected Economic Characteristics](https://data.census.gov/table/ACSDP5Y2024.DP03?q=DP03:+Selected+Economic+Characteristics&g=050XX00US26163$1400000&y=2024)** (Median Household Income, Unemployment rate, Poverty rate)
* **[DP04 | Selected Housing Characteristics](https://data.census.gov/table/ACSDP5Y2024.DP04?q=DP04:+Selected+Housing+Characteristics&g=050XX00US26163$1400000&y=2024)** (Vacant Housing rate (housing blight))

### 2. Detroit Police Department (RMS Crime Incidents)
Raw incident-level data providing geographic coordinates and offense categories:
* **[2020](https://data.detroitmi.gov/maps/20a3c63d31a44088b143e925fc71a5a1)** | **[2021](https://data.detroitmi.gov/maps/63a224e108914937a6a4cd9f96d25e81)** | **[2022](https://data.detroitmi.gov/maps/e461023806dc4ab79746afd2a3e41e25)** | **[2023](https://data.detroitmi.gov/maps/43e793425d1d486a807c731d88648ac7)** | **[2024](https://data.detroitmi.gov/maps/ed7646f5c75c4de4ae0281054b9300a9)** | **[2025](https://data.detroitmi.gov/maps/b794a57159204676a690cb2dd736181c)**

---

## Raw Datasets Description
* **Crime Incidents (Police Records):** 505,391 observations across 30 initial variables (approx. 193 MB).
* **Census Data (Socio-economic Profiles):** 627 unique census tracts with over 550 initial variables across three Data Profiles (approx. 6.4 MB).

---

## The Pipeline
The project follows a standard CRISP-DM workflow across five R scripts:

1.  **`01_data_extraction.R`**: Downloads raw CSV files and organizes them into the project structure.
2.  **`02_data_preparation.R`**: Handles spatial projections, removes duplicates, and performs a spatial join between incident points and census tract polygons.
3.  **`03_modeling.R`**: Runs **DBSCAN** for spatial hotspot detection and the **Apriori** algorithm for multi-variable association mining.
4.  **`04_evaluation.R`**: Generates comparative correlation matrices (City-wide vs. Hotspot-only) to test the impact of socio-economic factors.
5.  **`05_visualization.R`**: Exports interactive `leaflet` maps, `arulesViz` network graphs, and `ggplot2` severity dashboards.

---

## Tech Stack and main libraries
* **Language:** R
* **Spatial Analysis:** `sf`, `tigris`, `leaflet`
* **Data Mining:** `arules`, `arulesViz`, `dbscan`

## Visual results
These are saved in output/ folder :
* **Interactive Hotspot Maps**
* **Association Rules Network Graph:** A visual web showing how vacancy, education, and income "anchor" together to predict high-risk areas.

---

## Installation & Usage
1. Clone the repository:

   ```bash
   git clone https://github.com/badrhrm/Detroit-Crime-Mining.git
   ```

2. Open the RProject file in RStudio.

3. Run the scripts in order (01 through 05) to reproduce the findings.

4. Check the `outputs/` folder for interactive HTML visualizations and plots.
