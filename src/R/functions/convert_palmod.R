convert_palmod <- function() {

  # Convert from PALMOD source RDS to database-style tables

  # make sure create_df functions are defined
  source('./functions/db_tables.R')
  source('./functions/get_palmod_samples.R')

  # create tables
  p_sites <- create_sites_df()
  p_samples <- create_samples_df()

  palmod <- list.files('../../data/raw/jonkers.etal2019_RDS', full.names = TRUE)


# Sites -------------------------------------------------------------------


  # loop through all data files (sites) and extract info
  for (site in palmod) {
    
    # read the file
    tmp_site <- readRDS(site)
    
    # normalise name - everything must be [A-Z], [0-9], or underscore (_)
    tmp_site_name <- trimws(tmp_site$site$SiteName)
    tmp_site_name <- toupper(gsub("[^[:alnum:]]", '_', tmp_site_name))
    
    tmp_lat       <- tmp_site$site$SiteLat
    tmp_lon       <- tmp_site$site$SiteLon
    
    # calculate the ocean basin
    source('./functions/calculate_ocean_basin.R')
    tmp_ocean <- calculate_ocean_basin(tmp_lat, tmp_lon)
    
    # extract site metadata
    # water_depth is positive to nearest meter
    tmp_tbl <- data.frame(
      site_name   = tmp_site_name,
      lat         = tmp_lat,
      lon         = tmp_lon,
      water_depth = abs(round(tmp_site$site$SiteDepth_m)),
      ocean_basin = tmp_ocean,
      stringsAsFactors = FALSE
    )
    
    # add to sites table
    p_sites <- rbind(p_sites, tmp_tbl)


# Samples -----------------------------------------------------------------
    
    
    p_samples <- rbind(p_samples, get_palmod_samples(tmp_site, tmp_site_name))

  } # END loop through sites (RDS files)

  return(list("sites" = p_sites, "samples" = p_samples))

}