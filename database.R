get_database <- function(type = c("pool", "single")) {
  dbname <- "cranalerts.sqlite3"
  type <- match.arg(type)
  if (type == "pool") {
    con <- pool::dbPool(drv = RSQLite::SQLite(), dbname = dbname)
  } else if (type == "single") {
    con <- DBI::dbConnect(RSQLite::SQLite(), dbname)
  }
  con
}

make_pooled_query <- function(sql, params = list()) {
  if (!is.list(params)) {
    stop("params must be a list")
  }
  if (startsWith(tolower(sql), "select")) {
    type <- "select"
  } else if (startsWith(tolower(sql), "insert")) {
    type <- "insert"
  } else if (startsWith(tolower(sql), "delete")) {
    type <- "delete"
  } else {
    stop("Only SELECT, INSERT, DELETE statements are supported")
  }
  
  con_single <- pool::poolCheckout(con)
  on.exit({ pool::poolReturn(con_single) })
  if (type == "select") {
    query <- DBI::dbSendQuery(con_single, sql)
  } else if (type %in% c("insert", "delete")) {
    query <- DBI::dbSendStatement(con_single, sql)
  }
  DBI::dbBind(query, params)
  if (type == "select") {
    res <- DBI::dbFetch(query)
  }
  DBI::dbClearResult(query)
  if (type == "select") {
    return(res)
  }
}
