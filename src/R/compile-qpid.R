# Combine the two source datasets into one DB (individual tables & RDS)
# this file calls out to other worker functions in /functions to
# keep things manageable. Source this file to compile the database from scratch
# Ensure the original source files are present in /data/raw:
# 
# Oliver: CSV file "rawQUEST_d13Csynthesis.csv" from doi:10.5194/cp-6-645-2010
#         https://cp.copernicus.org/articles/6/645/2010/cp-6-645-2010-supplement.zip
#         move/rename to /data/raw/oliver.etal2010.csv. see note in /functions/convert_oliver.R
# 
# PalMod: RDS files in R.zip from doi:0.1594/PANGAEA.908831
#         http://store.pangaea.de/Publications/Jonkers-etal_2019/R.zip
#         extract R.zip to /data/raw/jonkers.etal2019_RDS


# -------------------------------------------------------------------------


# load each conversion function
source('./functions/convert_palmod.R')
source('./functions/convert_oliver.R')

# call functions to process files.
palmod <- convert_palmod()
oliver <- convert_oliver()


# Wrangle and combine -----------------------------------------------------


sites <- unique(rbind(palmod$sites, oliver$sites))

source('./functions/rectify_sites.R')

# correct sites with aliases, near-duplicates, etc
sites <- rectify_site_names(sites)
sites <- rectify_site_positions(sites)
sites <- rectify_site_depths(sites)

sites <- unique(sites)

# rectify site names
oliver$samples <- rectify_site_names(oliver$samples)

# remove position data from samples table
oliver$samples <- oliver$samples[,-2:-3]

# extract out taxa columns, process manually
oliver$taxa <- unique(oliver$samples[, c("raw_name","habitat")])
oliver$samples$habitat <- NULL

# remove "Var. benthic" from Oliver species column
oliver$samples$raw_name <- gsub("[Vv]ar\\.? benthic: ", "", oliver$samples$raw_name)
oliver$samples$raw_name <- trimws(oliver$samples$raw_name)

# convert raw_names column in samples tables to taxon_id
taxa_lookup <- read.csv('./lookup-tables/taxa_lookup.csv', stringsAsFactors=FALSE)

# in Oliver...
oliver$samples <- merge(x = oliver$samples, y = taxa_lookup, all.x = TRUE)
oliver$samples$raw_name <- NULL

# ...and in PALMOD
palmod$samples <- merge(x = palmod$samples, y = taxa_lookup, all.x = TRUE)
palmod$samples$raw_name <- NULL

# remove unused sites from sites table:
used_sites <- unique(append(unique(palmod$samples$site_name), unique(oliver$samples$site_name)))
sites <- sites[sites$site_name %in% used_sites, ]

# set DOI and data_url to NA if they have missing data
palmod$samples[palmod$samples$doi == "no DOI", "doi"] <- NA
palmod$samples[palmod$samples$data_url == "no link", "data_url"] <- NA

# PALMOD: convert doi column in samples tables to citekey
doi_lookup <- read.csv('./lookup-tables/doi-lookup.csv', stringsAsFactors=FALSE)
palmod$samples <- merge(x = palmod$samples, y = doi_lookup, all.x = TRUE)
palmod$samples$doi <- NULL

# reorder columns
palmod$samples <- palmod$samples[, c(1:3,7,8,4:6)]
oliver$samples <- oliver$samples[, c(1:3,8,4,5:7)]

samples <- rbind(palmod$samples, oliver$samples)

# sort by site_name (then depth_in_core, age, taxon_id if still a tie in samples):
samples <- samples[order(samples$site_name, samples$depth_in_core, samples$age, samples$taxon_id),]
sites   <- sites[order(sites$site_name), ]

# Write CSVs --------------------------------------------------------------

write.csv(sites, '../../data/sites.csv', row.names=FALSE, quote=FALSE, na="")
write.csv(samples, '../../data/samples.csv', row.names=FALSE, quote=FALSE, na="")
# taxa, studies, and env are written outside of this project


# Write RDS ---------------------------------------------------------------


# convert to factors:
samples$site_name <- factor(samples$site_name)
samples$taxon_id <- factor(samples$taxon_id)
samples$citekey <- factor(samples$citekey)

sites$ocean_basin <- factor(sites$ocean_basin)

taxa_col_classes <- c("character","character","character","character","character","factor","character")
taxa <- read.csv('../../data/taxa.csv', colClasses = taxa_col_classes)

env <- read.csv('../../data/env.csv')

studies_col_classes <- rep_len("character", 8)
studies_col_classes[5] <- "integer"
studies <- read.csv('../../data/studies.csv')

save(sites, samples, taxa, studies, env, file = "../../data/compiled/qpid.rds")

full_dataset <- Reduce(merge,list(sites,env,taxa,samples,studies))
# reorder columns
full_dataset <- full_dataset[, c(2,4:8,15,16,18,19,3,9:14,17,1,20:26)]
full_dataset <- full_dataset[order(full_dataset$site_name, full_dataset$depth_in_core, full_dataset$age, full_dataset$taxon_id),]
write.csv(full_dataset, '../../data/compiled/qpid_full_dataset.csv', row.names = FALSE)
