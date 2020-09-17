# This script generates the base information to then go and manually generate
#  the correction table for duplicate sites.

# check if the `sites` variable is available. If not, process raw data
if (!exists("sites")) {
  # load each conversion function
  source('convert_palmod.R')
  source('convert_oliver.R')
  # call functions to process files.
  palmod <- convert_palmod()
  oliver <- convert_oliver()
  
  sites <- unique(rbind(palmod$sites, oliver$sites))
}


# First, find duplicates by position:
# compare only on position and water depth
# find within +/- 0.02 deg (~2 km) and +/- 1 m water depth

ref_site <- array()
matched_site <- array()

for (s in 1:nrow(sites)) {
  this_name <- sites[s,"site_name"]
  this_lat <- sites[s,"lat"]
  this_lon <- sites[s,"lon"]
  this_dep <- sites[s,"water_depth"]
  
  radius <- 0.02 # the search radius in degrees
  
  dupes_lat <- sites[sites$lat <= this_lat + radius & sites$lat >= this_lat - radius,]
  dupes_lon <- sites[sites$lon <= this_lon + radius & sites$lon >= this_lon - radius,]
  dupes_dep <- sites[sites$water_depth <= this_dep + 1 & sites$water_depth >= this_dep - 1,]
  
  dupes <- Reduce(merge, list(dupes_lat,dupes_lon,dupes_dep))
  
  if (nrow(dupes) == 1) next
  # else
  # get all duplicates with a different name (also known as: aka)
  aka_matches  <- dupes[dupes$site_name != this_name, 1] 
  ref_site     <- append(ref_site, rep_len(this_name, length(aka_matches)))
  matched_site <- append(matched_site, aka_matches)
  
  if (length(aka_matches) != 0) next
  # aka_matches is empty, matches must all have same name
  ref_site     <- append(ref_site, this_name)
  matched_site <- append(matched_site, this_name)
}

# Second, find duplicates by name:
# construct a temporary very simplified version of the sites table
sites_rounded <- sites
sites_rounded$lat <- trunc(sites_rounded$lat)
sites_rounded$lon <- trunc(sites_rounded$lon)
sites_rounded$water_depth <- round(sites_rounded$water_depth/10)*10 # nearest 10 m
sites_rounded <- unique(sites_rounded)
dupl_site_names <- sites_rounded[duplicated(sites_rounded$site_name), 1]
# "V19_30"  "R657"    "V22_108"

# construct position duplicates table:
dupl_sites <- data.frame(ref_site, matched_site)
dupl_sites <- unique(merge(dupl_sites, sites_rounded, by.x = "ref_site", by.y = "site_name", all.x = T))

write.csv(dupl_sites, 'dupl_sites.csv', row.names = FALSE)

# manually check duplicates at this stage, complete canonical CSVs:

canon_names_tbl <- data.frame(
  lat = double(),
  lon = double(),
  canon_name = character(),
  evidence = character()
)

canon_positions_tbl <- data.frame(
  name = character(),
  canon_lat = double(),
  canon_lon = double(),
  evidence = character()
)

canon_depths_tbl <- data.frame(
  name = character(),
  canon_depth = integer(),
  canon_lon = double()
)

write.csv(canon_names_tbl, 'canon_names_tbl.csv', row.names = FALSE)
write.csv(canon_positions_tbl, 'canon_positions_tbl.csv', row.names = FALSE)
write.csv(canon_depths_tbl, 'canon_depths_tbl.csv', row.names = FALSE)
