setwd("/srv/shiny-server/cranalerts/")

library(htmltools)

source("database.R", local = TRUE)
source("email.R", local = TRUE)

con <- get_database(type = "single")

# Get a current list of CRAN packages ---
mirrors <- c("https://cloud.r-project.org", "https://cran.rstudio.com")
new_info <- NULL
for (mirror in mirrors) {
  mirror_contrib <- contrib.url(mirror)
  new_info <- as.data.frame(available.packages(contriburl = mirror_contrib, filters = "duplicates"))
  if (nrow(new_info) > 0) break
  message("Mirror ", mirror, " is down")
}
if (is.null(new_info) || nrow(new_info) == 0) {
  Email$new(email = AUTHOR_EMAIL, subject = "CRANalerts mirrors down", body = "")$send()
  stop("No working mirror found")
}

# Read old info ----
users_table <- DBI::dbReadTable(con, "Users")
alerts_table <- DBI::dbReadTable(con, "Alerts")
old_package_info <- DBI::dbReadTable(con, "PackageInfo")

# Update the package versions table ----
new_info <- new_info[, c("Package", "Version")]
rownames(new_info) <- NULL
new_info$Package <- as.character(new_info$Package)
new_info$Version <- as.character(new_info$Version)
DBI::dbWriteTable(con, "PackageInfo", new_info, overwrite = TRUE)
DBI::dbDisconnect(con)

# Make sure the app restarts to re-connect to the database ----
system("touch restart.txt")

# Send emails about packages that have a different version ----
merged_df <- merge(old_package_info, new_info,
                   by = "Package", all = FALSE, suffixes = c("old", "new"))
merged_df$updated <- merged_df$Versionold != merged_df$Versionnew
updated_pkgs <- merged_df[merged_df$updated, , drop = FALSE]

if (nrow(updated_pkgs) > 0) {
  invisible <- lapply(updated_pkgs$Package, function(pkg) {
    message("Package updated: ", pkg)
    users_to_alert <- alerts_table[alerts_table$package == pkg, , drop = FALSE]
    
    if (nrow(users_to_alert) > 0) {
      new_version <- updated_pkgs[updated_pkgs$Package == pkg, 'Versionnew']
      users_to_alert <- users_to_alert$email
      
      lapply(users_to_alert, function(email) {
        message("User alerted: ", email)
        unsub_token <- users_table[users_table$email == email, 'unsub_token']
        if (length(unsub_token) == 0) return()
        EmailAlertUpdated$new(email = email, package = pkg, token = unsub_token, new_version = new_version)$send()
      })
    }
  })
}


# Send emails about packages that were removed from CRAN ----
pkgs_removed <- setdiff(old_package_info$Package, new_info$Package)
if (length(pkgs_removed) > 0) {
  invisible <- lapply(pkgs_removed, function(pkg) {
    message("Package updated: ", pkg)
    users_to_alert <- alerts_table[alerts_table$package == pkg, , drop = FALSE]
    
    if (nrow(users_to_alert) > 0) {
      users_to_alert <- users_to_alert$email
      
      lapply(users_to_alert, function(email) {
        message("User alerted: ", email)
        unsub_token <- users_table[users_table$email == email, 'unsub_token']
        if (length(unsub_token) == 0) return()
        EmailAlertRemoved$new(email = email, package = pkg, token = unsub_token)$send()
      })
    }
  })
}
