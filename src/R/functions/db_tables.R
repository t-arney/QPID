# Constructor functions for relational database-style tables.

create_sites_df <- function(){
  sites <- data.frame(
    site_name = character(),
    lat = double(),
    lon = double(),
    water_depth = double(),
    ocean_basin = character(), # TODO: convert to factor
    stringsAsFactors = FALSE
  )
  return(sites)
}

create_samples_df <- function(){
  samples <- data.frame(
    site_name = character(),
    depth_in_core = double(),
    age = double(),
    taxon_id = character(),
    citekey = character(),
    data_url = character(),
    d18o = double(),
    d13c = double(),
    stringsAsFactors = FALSE
  )
  return(samples)
}

create_taxa_df <- function(){
  taxa <- data.frame(
    taxon_id = character(),
    grouping = character(),
    genus = character(),
    species = character(),
    type = character(),
    habitat = character(), # TODO: convert to factor
    original_name = character(),
    stringsAsFactors = FALSE
  )
  return(taxa)
}

create_studies_df <- function(){
  studies <- data.frame(
    citekey = character(),
    doi = character(),
    year = integer(),
    stringsAsFactors = FALSE
  )
  return(studies)
}
