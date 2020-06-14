# You can use run this function to set up a local dev environment for testing
dev_init <- function() {
  DB_FILE <- "cranalerts.sqlite3"
  if (file.exists(DB_FILE)) {
    success <- suppressWarnings(file.remove(DB_FILE))
    if (!success) {
      stop("The database file can't be removed, make sure it's not currently in use and try again.",
           " (You may have a connection open, try restarting your session.)")
    }
  }
  con <- DBI::dbConnect(RSQLite::SQLite(), DB_FILE)
  
  DBI::dbExecute(con, "
CREATE TABLE IF NOT EXISTS Confirmations (
  confirmation_id INTEGER PRIMARY KEY,
  token TEXT NOT NULL,
  email TEXT NOT NULL,
  package TEXT NOT NULL,
  timestamp TEXT NOT NULL
)")
  
  DBI::dbExecute(con, "
CREATE TABLE IF NOT EXISTS Users (
  user_id INTEGER PRIMARY KEY,
  email TEXT NOT NULL,
  unsub_token TEXT NOT NULL,
  timestamp TEXT NOT NULL
);")
  
  DBI::dbExecute(con, "
CREATE TABLE IF NOT EXISTS Alerts (
  alert_id INTEGER PRIMARY KEY,
  email TEXT NOT NULL,
  package TEXT NOT NULL,
  timestamp TEXT NOT NULL
);")
  
  DBI::dbExecute(con, "
CREATE TABLE IF NOT EXISTS PackageInfo (
  Package TEXT NOT NULL,
  Version TEXT NOT NULL
);")
  
  # Get a current list of CRAN packages ---
  mirrors <- c("https://cloud.r-project.org", "https://cran.rstudio.com")
  new_info <- NULL
  for (mirror in mirrors) {
    mirror_contrib <- contrib.url(mirror)
    new_info <- as.data.frame(available.packages(contriburl = mirror_contrib, filters = "duplicates"))
    if (nrow(new_info) > 0) break
    message("Mirror ", mirror, " is down")
  }
  
  # Update the package versions table ----
  new_info <- new_info[, c("Package", "Version")]
  rownames(new_info) <- NULL
  new_info$Package <- as.character(new_info$Package)
  new_info$Version <- as.character(new_info$Version)
  DBI::dbWriteTable(con, "PackageInfo", new_info, overwrite = TRUE)
  DBI::dbDisconnect(con)
}
