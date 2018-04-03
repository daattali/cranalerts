library(shiny)

source("database.R", local = TRUE)
source("email.R", local = TRUE)

con <- get_database(type = "pool")
onStop(function() {
  pool::poolClose(con)
})
package_info <- DBI::dbReadTable(con, "PackageInfo")
