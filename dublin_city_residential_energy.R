library(csodata)
library(leaflet)
library(tidyverse)
library(sf)
library(geojsonio)
library(htmlwidgets)

# Import Dublin small area residential energy usage
dublin_energy <- read_csv('dublin-city-residential-energy-in-each-small-area.csv')
head(dublin_energy)

# Rename columns
dublin_energy <- rename(dublin_energy, 
       area_code = `Dublin City Small Area Code`, 
       annual_energy_use = `Estimated Total Annual Energy Use (kWh)`,
       annual_energy_cost = `Estimated Total Annual Cost of Energy`,
       total_area = `Total Floor Area`)
head(dublin_energy)

# Remove incorrectly formatted data
dublin_energy <- dublin_energy %>% filter(!grepl('_', area_code))
head(dublin_energy)

# Download small areas geometry data (shapefile) for Ireland
shp <- cso_get_geo('Small Areas')
head(shp)

# Join energy dataset with geometries
dublin_energy_shp <- left_join(dublin_energy, shp, 
                                by = join_by(area_code == en))
dublin_energy_shp <- drop_na(dublin_energy_shp)

# Convert tbl back to sf format
dublin_energy_shp <- sf::st_as_sf(dublin_energy_shp)
head(dublin_energy_shp)

# Define colour palette based on energy usage
pal <- colorBin(
  c("#E1F5C4", "#EDE574", "#F9D423", "#FC913A", "#FF4E50"),
  domain = dublin_energy_shp$annual_energy_use,
  bins = c(0, 1e6, 2e6, 4e6, 6e6, 10e6, 50e6, Inf)
)
                
# Plot total energy usage by Dublin small areas boundaries
energy_map <- leaflet(dublin_energy_shp) %>% 
  addTiles() %>% 
  addPolygons(weight=0.5, 
              fillColor = ~pal(annual_energy_use),
              fillOpacity = 0.9) %>%
  addLegend(pal = pal,
            values = ~annual_energy_use,
            position = 'bottomleft',
            title = 'Annual  Residential <br/> Energy Use (Kwh)',
            opacity = 0.9)

saveWidget(energy_map, 
           file = 'dublin_energy_map.html',
           selfcontained = TRUE)

# Write data to GEOJSON format
dublin_energy_geojson <- geojson_json(dublin_energy_shp)
geojson_write(dublin_energy_geojson, file = 'dublin_energy.geojson')

# Run at end of session to clear local cache
cso_clear_cache()
