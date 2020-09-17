calculate_ocean_basin <- function(lat, lon) {
  if ((       lat <=  23.5 && lat >   8  ) && (lon >= -100 && lon <  -70)) {
    basin <- 'CHECK' # ambiguous central American coast region: check manually
  } else if ((lat <=  66.5 && lat >  50  ) && (lon >= -100 && lon <  -70)) {
    basin <- 'Ar'    # Hudson's Bay
  } else if ((lat <=    48 && lat >  30  ) && (lon >=    0 && lon <   45)) {
    basin <- 'Med'  # Mediterranean & Black Sea
  } else if ((lat <=    33 && lat >  40  ) && (lon >= -5.8 && lon <    0)) {
    basin <- 'Med'  # Mediterranean (Straits of Gibraltar, E of Kamara Ridge)
  } else if ((lat <=  66.5 && lat >  23.5) && (lon >=  -40 && lon <   20)) {
    basin <- 'NEAt'
  } else if ((lat <=  66.5 && lat >  23.5) && (lon >= -100 && lon <  -40)) {
    basin <- 'NWAt'
  } else if ((lat <=  23.5 && lat > -23.5) && (lon >=  -70 && lon <   20)) {
    basin <- 'TAt'
  } else if ((lat <= -23.5 && lat > -55  ) && (lon >=  -70 && lon <   20)) {
    basin <- 'SAt'
  } else if ((lat <=  66.5 && lat >  23.5) && (lon >= -180 && lon < -100)) {
    basin <- 'NEPa'
  } else if ((lat <=  66.5 && lat >  23.5) && (lon >=  120 && lon <  180)) {
    basin <- 'NWPa'
  } else if ((lat <=  23.5 && lat > -23.5) && (lon >=  120 || lon <  -70)) {
    basin <- 'TPa'
  } else if ((lat <= -23.5 && lat > -55  ) && (lon >=  120 || lon <  -70)) {
    basin <- 'SPa'
  } else if ((lat <=  30   && lat > -55  ) && (lon >=   80 && lon <  120)) {
    basin <- 'EIn'
  } else if ((lat <=  30   && lat > -55  ) && (lon >=   20 && lon <   80)) {
    basin <- 'WIn'
  } else if ((lat <= -55   && lat > -90  ) && (lon >=   20 || lon < -160)) {
    basin <- 'ESo'
  } else if ((lat <= -55   && lat > -90  ) && (lon >= -160 && lon <   20)) {
    basin <- 'WSo'
  } else if ((lat <=  90   && lat >  66.5) && (lon >= -180 && lon <  180)) {
    basin <- 'Ar'
  } else {
    basin <- NA
  }
  return(basin)
}