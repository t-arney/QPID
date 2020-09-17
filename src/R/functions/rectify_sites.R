
# Names -------------------------------------------------------------------

# correct any sites with the "canonical" name from the original source (normalised)
# input data frame must have the columns site_name, lat, and lon.
rectify_site_names <- function(sites_df) {

  sites_df$lat <- trunc(sites_df$lat*100)/100
  sites_df$lon <- trunc(sites_df$lon*100)/100

  # load correction table
  canon_names_tbl <- read.csv('./lookup-tables/canon_names_tbl.csv', stringsAsFactors=FALSE)

  # correct names
  for (n in 1:nrow(canon_names_tbl)) {
    sites_df[sites_df$lat == canon_names_tbl[n, "lat"] &
               sites_df$lon == canon_names_tbl[n, "lon"], "site_name"] <-
      canon_names_tbl[n, "canon_name"]
  }
  # KT94_15_PC_9 (aka KT9415P9) is a special case: it is in "essentially the same
  # location [as GH93_KI_5]" (39.56 N, 139.41 E; doi:10.1029/1998PA900023)
  # correct the name here instead:
  sites_df[sites_df$site_name == "KT9415P9", "site_name"] <- "KT94_15_PC_9"
  
  return(sites_df)
}


# Positions ---------------------------------------------------------------

# correct any sites with the "canonical" position from the original source.
# Must be run AFTER rectify_site_names()
# input data frame must have the columns site_name, lat, and lon.
# If the input has an ocean_basin column, that will be updated too.
rectify_site_positions <- function(sites_df) {

  # load correction table
  canon_positions_tbl <- read.csv('./lookup-tables/canon_positions_tbl.csv', stringsAsFactors=FALSE)

  # correct positional data
  for (n in 1:nrow(canon_positions_tbl)) {
    matches <- sites_df$site_name == canon_positions_tbl[n, "name"]
    this_lat <- canon_positions_tbl[n, "canon_lat"]
    this_lon <- canon_positions_tbl[n, "canon_lon"]
    
    sites_df[matches, "lat"] <- this_lat
    sites_df[matches, "lon"] <- this_lon
    # make sure ocean basin hasn't changed, if present:
    if ("ocean_basin" %in% colnames(sites_df)){
      if (!exists("calculate_ocean_basin")) source('./functions/calculate_ocean_basin.R')
      sites_df[matches, "ocean_basin"] <- calculate_ocean_basin(this_lat, this_lon)
    }
  }

  return(sites_df)
}


# Depths ------------------------------------------------------------------

# correct any sites with the "canonical" depth from the original source.
# Must be run AFTER rectify_site_names()
# input data frame must have the columns water_depth and site_name
rectify_site_depths <- function(sites_df) {
  
  sites_df$water_depth <- round(sites_df$water_depth)

  canon_depths_tbl <- read.csv('./lookup-tables/canon_depths_tbl.csv', stringsAsFactors=FALSE)

  # correct water depths
  for (n in 1:nrow(canon_depths_tbl)) {
    sites_df[sites_df$site_name == canon_depths_tbl[n, "name"], "water_depth"] <-
      canon_depths_tbl[n, "canon_depth"]
  }

  return(sites_df)
}