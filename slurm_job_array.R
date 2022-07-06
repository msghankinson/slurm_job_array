library(sf)
library(dplyr)

setwd("~/Documents/GitHub/slurm_job_array")

# buffer --  polygon shapefile, 3,086 circles
# buffer <- st_read(paste0("lihtc_bites/", shp_filename, ".shp")) # code for job array
buffer <- st_read("bites/CAA19990763_lihtc_9902_buff_near.shp")

# lihtc -- point shapefile used as index in function for merging
# lihtc <- st_read(paste0("california/", lihtc_filename, ".csv")) # code for job array
lihtc <- st_read("california/lihtc_9902_sf.shp")

# blocks -- polygon shapefile of Census blocks (from San Francisco County as example)
blocks <- sf::st_read("blocks/blocks_75.shp")
blocks <- st_transform(blocks, st_crs(lihtc)) # update projection
blocks$blocks_area <- st_area(blocks) # calculate area of blocks for function

# intersection function
cnty_func <- function(buff_test, lihtc_proj_test) {
  lihtc_proj_id <- lihtc_proj_test %>% # drop geometry to leave only dataframe object for indexing later
    st_drop_geometry()
  buff_blocks_int <- st_intersects(buff_test, blocks) # id which blocks overlap with buffer
  ints_holder <- data.frame()
  for(i in 1:nrow(buff_blocks_int)){ 
    blocks_int <- subset(blocks, as.numeric(rownames(blocks)) %in% buff_blocks_int[[i]]) # subset to only overlapping blocks
    blocks_int$hud_id <- lihtc_proj_id[i, 1] # add index for merge
    ints_holder <- rbind(ints_holder, blocks_int)
  }
  buff_blocks <- st_intersection(buff_test, ints_holder) %>% # run full intersection on circles and overlapping lbocks
                mutate(intersect_area = st_area(.)) %>% # calculate area of overlap
                dplyr::select(GEOID10, intersect_area) %>%
    st_drop_geometry()
  lihtc_out_area <- merge(blocks, buff_blocks , by = "GEOID10", all.x = T) # reattach intersections to full blocks data
  lihtc_out_area$coverage <- as.numeric(lihtc_out_area$intersect_area / lihtc_out_area$blocks_area) # calculate share of overlap
  lihtc_out_area <- subset(lihtc_out_area, coverage >=.5) # keep only blocks with >50% area overlap
  return(lihtc_out_area)
}

lihtc_out <- cnty_func(buffer, lihtc)

st_write(lihtc_out, paste0("completed/", shp_filename, ".shp"), append = F) # write shapefile of these overlapping blocks

