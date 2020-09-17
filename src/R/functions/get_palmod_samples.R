get_palmod_samples <- function(tmp_site, tmp_site_name) {
  # Get the samples data out of the PALMOD files.
  # Called from convert_palmod.R
  # (separated for clarity)
  
  # make sure create_df functions are defined
  source('./functions/db_tables.R')
  
  # data.frame of all measurements in this core
  core_samples <- create_samples_df()
  
  meta <- tmp_site$meta
  data <- tmp_site$data
  meta <- cbind(meta, data_tbl_idx = 2:(nrow(meta)+1))
  
  # list of (indices of) columns of interest from the data table
  data_good_cols_i <- meta[
    meta$Parameter %in% c("age","benthic.d13C","benthic.d18O","planktonic.d13C","planktonic.d18O")
    & meta$Material %in% c(NA, "benthic foraminifera calcite", "planktonic foraminifera calcite"),
    "data_tbl_idx"] # Material == NA allows for age rows
  age_cols_in_data <- meta[meta$Parameter == "age", "data_tbl_idx"]
  age_rows_in_meta <- which(meta$Parameter == "age")
  num_age_cols <- length(age_cols_in_data)
  
  # If a core has no age model, don't process samples.
  if (num_age_cols == 0) return( data.frame() ) # return empty data.frame
  
  # which of the data_good_cols_i are age parameters?
  age_cols_in_data_good_cols_i <- match(age_cols_in_data, data_good_cols_i)
  
  # loop over each "study" (measurements with different age models)
  for (ix in 1:num_age_cols) {
    # start at this age column and get all cols from data_good_cols_i up to but 
    # excluding the next age column.
    # Check: at the last age column? Yes: select to last col in data_good_cols_i
    
    end_data_col_i <-
      if (ix == num_age_cols) { length(data_good_cols_i) }
      else { age_cols_in_data_good_cols_i[ix + 1] - 1 }
    
    this_data_df <- data[, c(1,data_good_cols_i[age_cols_in_data_good_cols_i[ix]:end_data_col_i])]
  
    # get metadata for this data. Won't work for cases with no data, but we
    # don't need it for those cases anyway.
    # meta row indices are 1 smaller than data col indices (because of depth col in data)
    metadata <- meta[data_good_cols_i[age_cols_in_data_good_cols_i[ix]:end_data_col_i]-1, ]
    # includes age row, but we don't want it, so drop first row:
    metadata <- metadata[-1, ]
    
    # if this_data_df has only depth & age columns, discard, go to next iteration
    if (ncol(this_data_df) <= 2) next
    
    nsampl <- nrow(this_data_df)
    
    # data.frame of all measurements in this core with the same age model
    this_samples <- create_samples_df()
    # temporarily rename taxon_id and citekey. Will be updated later
    colnames(this_samples)[colnames(this_samples) %in% c("taxon_id", "citekey")] <- c("raw_name", "doi")
    
    # loop over measurements from this study (same age model)
    for (v in 1:nrow(metadata)) {
      if (metadata[v, "Parameter"] %in% c("benthic.d18O","planktonic.d18O")) {
        this_d18o <- this_data_df[[v+2]] # +2 = depth and age cols to left
        this_d13c <- rep_len(NA, nsampl)
      } else {
        this_d18o <- rep_len(NA, nsampl)
        this_d13c <- this_data_df[[v+2]]
      }
      
      this_habitat <- 
        if (grepl("benthic", metadata[v, "Parameter"], fixed=T)) "[Bn]" else "[Pl]"
      
      tmp_samples <- data.frame(
        site_name = rep_len(tmp_site_name, nsampl),
        depth_in_core = this_data_df[[1]],
        age = this_data_df[[2]],
        raw_name = rep_len(paste(metadata[v,"Species"], this_habitat), nsampl),
        doi = rep_len(tolower(metadata[v,"PublicationDOI"]), nsampl),
        data_url = rep_len(metadata[v,"DataLink"], nsampl),
        d18o = this_d18o,
        d13c = this_d13c,
        stringsAsFactors = FALSE
      )
      
      # GEOTU_SL148 is missing a DOI for its values:
      if (tmp_site_name == "GEOTU_SL148") {
        tmp_samples$doi <- rep_len("10.1016/j.palaeo.2008.07.010", nsampl)
      }
      
      # avoid NA in these columns for now
      tmp_samples[is.na(tmp_samples$data_url), "data_url"] <- "no link"
      tmp_samples[substr(tmp_samples$doi,1,2) != "10", "doi"] <- tolower(tmp_site_name) # all valid DOIs start with "10"
      
      # if more than one DOI is given, take only the first:
      tmp_samples$doi <- unlist(lapply((strsplit(tmp_samples$doi, "[;,] ")), `[[`, 1))
      
      # for data_url, keep all URLs: convert any commas to semicolons (for CSV)
      tmp_samples$data_url <- gsub(",", ";", tmp_samples$data_url)
      
      
      this_samples <- rbind(this_samples, tmp_samples)
      
    } # END loop over study measurements
    
    core_samples <- rbind(core_samples, this_samples)
  }
  
  if (nrow(core_samples) > 0) {
  
    # collapse rows from the same study measuring the same species 
    # at the same intervals, eg this should collapse to one row:
    # site_name  depth_in_core    age      taxon_id   d18o  d13c
    #    ODP846          0.055   0.00  N. dutertrei  -0.65    NA
    #    ODP846          0.055   0.00  N. dutertrei     NA  1.79
    # (using method from https://stackoverflow.com/a/28036386)
    core_samples <- aggregate(
      core_samples[c("d18o","d13c")], core_samples[c(-7,-8)], FUN=na.omit)
    
    # na.omit() makes missing values numeric(0) or logical(0). convert to NA:
    core_samples$d18o <- as.double(core_samples$d18o)
    core_samples$d13c <- as.double(core_samples$d13c)
    
    # remove rows with no isotope data
    core_samples <- core_samples[!(is.na(core_samples$d18o) & is.na(core_samples$d13c)), ]
    
  }
  
  return(core_samples)

}
