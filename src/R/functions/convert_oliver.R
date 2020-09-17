
# reformat Oliver et al. (2010) CSV to DB-style tables

# This script reformats the CSV file "rawQUEST_d13Csynthesis.csv" from the
# supplementary materials of Oliver et al. (2010). 
# IMPORTANT: For R to successfully import, the file must be placed into a
# subdirectory called "raw" in the "data" folder, and renamed to
# "oliver.etal2010.csv", (i.e. '../../data/raw/oliver.etal2010.csv')
# AND the first 6 lines (marked X below) must be deleted and replaced with 
# the new headings below


# ** Original file **

# # "% This file contains raw data used...  X
# # % This file should not be treated a...  X
# # "% Dates younger than 150 ka are su...  X
# #                                         X
# # %Core name,Lat itude(decimal degree...  X
# #                                         X
# # RC12-294,-37.26666667,-10.11527778,3308,0.25,13.467,Uvig. spp.,,,4.64,-0.49


# * New file *
# # site_name,lat,lon,water_depth,depth_in_core,age,species,pl.d18O,pl.d13C,bn.d18O,bn.d13C
# # RC12-294,-37.26666667,-10.11527778,3308,0.25,13.467,Uvig. spp.,,,4.64,-0.49

convert_oliver <- function() {

  # import data -----------------------------------------------------------


  # make sure create_df functions are defined
  source('./functions/db_tables.R')

  # import original CSV file
  raw_oliver <- read.csv('../../data/raw/oliver.etal2010.csv', header = T)



  # Clean the data ----------------------------------------------------------


  # remove any rows with no core name
  raw_oliver <- raw_oliver[!raw_oliver$site_name == ' ',]
  # remove any row missing position OR age data
  raw_oliver <-
    raw_oliver[complete.cases(raw_oliver[, c("lat", 'lon', 'age')]), ]
  # remove any row with no isotope data
  raw_oliver <-
    raw_oliver[apply(!is.na(raw_oliver[, c('pl.d18O',
                                          'pl.d13C',
                                          'bn.d18O',
                                          'bn.d13C')]), 1, any),]     
  
  num_raw_rows <- length(raw_oliver[[1]])

  # To help spot duplicates:
  # normalise name - everything must be [A-Z], [0-9], or underscore (_)
  raw_oliver$site_name <- trimws(raw_oliver$site_name)
  raw_oliver$site_name <- toupper(gsub("[^[:alnum:]]", '_', raw_oliver$site_name))
  

  # Corrections -------------------------------------------------------------

  
  # "RC11_26" is unreliable - no reference, not available online, and has planktic
  # d18O data but species is listed as "benthic". Remove these rows
  raw_oliver <- raw_oliver[!raw_oliver$site_name == "RC11_26",]
  
  # IOE105KK @ 0.2m depth has an incorrect d13C value: decimal point is missing
  # (155, should be 1.55 - https://doi.org/10.1594/PANGAEA.77634)
  raw_oliver[raw_oliver$site_name == "IOE105KK" & raw_oliver$depth_in_core == 0.2, "pl.d13C"] <- 1.55

  
  # Sites -------------------------------------------------------------------

  # get unique sites
  oliver_sites <- unique(raw_oliver[, 1:4])
  num_sites <- length(oliver_sites[[1]])

  # calculate ocean basin
  ocean_basin <- vector("character", num_sites)

  source('./functions/calculate_ocean_basin.R')

  for (i in 1:num_sites) {
    ocean_basin[[i]] <-
      calculate_ocean_basin(oliver_sites[i, 'lat'], oliver_sites[i, 'lon'])
  }

  # add ocean_basin column
  oliver_sites <- cbind(oliver_sites, ocean_basin)
  
  # Manually set any sites near central America:
  # oliver_sites[oliver_sites$ocean_basin == 'CHECK',]
  # site_name     lat    lon    water_depth  ocean_basin
  # RC12_36  14.74  -97.67        3354        CHECK   <- TPa
  # V28_127  11.65  -80.13        3237        CHECK   <- TAt
  # V12_122  17.00  -74.42        2800        CHECK   <- TAt

  oliver_sites[oliver_sites$site_name == 'RC12_36',]$ocean_basin <- 'TPa'
  oliver_sites[oliver_sites$site_name == 'V28_127',]$ocean_basin <- 'TAt'
  oliver_sites[oliver_sites$site_name == 'V12_122',]$ocean_basin <- 'TAt'

  # remove unrelated row names
  rownames(oliver_sites) <- NULL
  

  # Samples -----------------------------------------------------------------

  # A small number of sites have isotope values in the wrong column:
  # they should be benthic values but were recorded in the orig CSV as planktic
  pl2bn_sites <- c("RC12_267", "GEOB1041_3", "GEOB6718_2")
  
  # find rows where there is pl data AND it's from one of the problem cores:
  pl2bn_rows_d18O <- raw_oliver$site_name %in% pl2bn_sites & !is.na(raw_oliver$pl.d18O)
  pl2bn_rows_d13C <- raw_oliver$site_name %in% pl2bn_sites & !is.na(raw_oliver$pl.d13C)
  
  # copy oxygen into bn.d18O if there isn't data there already
  raw_oliver[pl2bn_rows_d18O & is.na(raw_oliver$bn.d18O),"bn.d18O"] <- 
    raw_oliver[pl2bn_rows_d18O,"pl.d18O"]

  # do the same for carbon
  raw_oliver[pl2bn_rows_d13C & is.na(raw_oliver$bn.d13C),"bn.d13C"] <- 
    raw_oliver[pl2bn_rows_d13C,"pl.d13C"]
  
  # delete planktic column data:
  raw_oliver[pl2bn_rows_d18O | pl2bn_rows_d13C, c("pl.d18O", "pl.d13C")] <- NA
  
  # import manually generated citekey lookup table
  keys <- read.csv('./lookup-tables/oliver.etal2010_sites_ref_codes.csv', stringsAsFactors=FALSE, na.string = "")
  
  # apply same name normalisation
  keys$site_name <- trimws(keys$site_name)
  keys$site_name <- toupper(gsub("[^[:alnum:]]", '_', keys$site_name))
  
  # Process each row in a loop, split into individual samples:
  tmp_list <- vector("list", num_raw_rows)

  for (i in 1:num_raw_rows) {
    this_obs <- raw_oliver[i,]
    this_has_pl <- any(!is.na(this_obs[8:9])) # has any planktic isotope values
    this_has_bn <- any(!is.na(this_obs[10:11]))# has any benthic isotope values
    species <- unlist(strsplit(this_obs$species, "; ", fixed = TRUE))
    
    if (length(species) == 2) {
      pl_species <- species[1]
      bn_species <- species[2]
    } else {
      pl_species <- this_obs$species
      bn_species <- this_obs$species
    }
    
    # Get citekey and data_url for this core. 
    this_citekey <- keys[keys$site_name == this_obs$site_name,"citekey"]
    this_data_url <- keys[keys$site_name == this_obs$site_name,"data_url"]
    
    # If no ref, fall back to Oliver et al. 2010
    if (length(this_citekey) == 0) {
      this_citekey <- "oliver.etal2010"
      this_data_url <- NA
    }

    if (this_has_pl & this_has_bn) {
      # has both values: split into two rows:
      this_data <- data.frame(
        site_name = rep_len(this_obs$site_name, 2),
        lat = rep_len(this_obs$lat, 2),
        lon = rep_len(this_obs$lon, 2),
        depth_in_core = rep_len(this_obs$depth_in_core, 2),
        age = rep_len(this_obs$age, 2),
        raw_name = c(pl_species, bn_species),
        habitat = c("Pl", "Bn"),
        citekey = rep_len(this_citekey, 2),
        data_url = rep_len(this_data_url, 2),
        d18o = c(this_obs$pl.d18O, this_obs$bn.d18O),
        d13c = c(this_obs$pl.d13C, this_obs$bn.d13C),
        stringsAsFactors = FALSE
      )
    } else if (this_has_pl) {
      this_data <- data.frame(
        site_name = this_obs$site_name,
        lat = this_obs$lat,
        lon = this_obs$lon,
        depth_in_core = this_obs$depth_in_core,
        age = this_obs$age,
        raw_name = pl_species,
        habitat = "Pl",
        citekey = this_citekey,
        data_url = this_data_url,
        d18o = this_obs$pl.d18O,
        d13c = this_obs$pl.d13C,
        stringsAsFactors = FALSE
      )
    } else if (this_has_bn) {
      this_data <- data.frame(
        site_name = this_obs$site_name,
        lat = this_obs$lat,
        lon = this_obs$lon,
        depth_in_core = this_obs$depth_in_core,
        age = this_obs$age,
        raw_name = bn_species,
        habitat = "Bn",
        citekey = this_citekey,
        data_url = this_data_url,
        d18o = this_obs$bn.d18O,
        d13c = this_obs$bn.d13C,
        stringsAsFactors = FALSE
      )
    }
    
    tmp_list[[i]] <- this_data
    
  }
  
  oliver_samples <- do.call("rbind", tmp_list)
  

  return(list("sites" = oliver_sites, "samples" = oliver_samples))
  
}