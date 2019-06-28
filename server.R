function(input, output, session) {
  
  page_type <- reactiveVal()
  
  # When the page loads, decide what page to show
  observe({
    query <- parseQueryString(session$clientData$url_search)
    page <- query$action
    allowed_pages <- c("main", "confirm", "unsub")
    if (is.null(page) || !page %in% allowed_pages) {
      page <- "main"
    }
    shinyjs::hide("loader_img_main")
    shinyjs::show(id = paste0("page_", page))
    page_type(page)
    
    # Focus on the first input so the user can type right away
    shinyjs::runjs("$($('#main_content_area').find('input:visible')[0]).focus().click();")
  })
  
  # --------------
  # Main page ----

  main_error_msg <- reactiveVal()
  output$main_error <- renderText(main_error_msg())
  output$main_response_email <- renderText(trimws(input$user_email))
  
  # Submit the form when Enter is pressed within one of the two inputs
  input_click_enter <- function(event) {
    if (!is.null(event$keyCode) && event$keyCode == 13) {
      shinyjs::click("confirm_submit_btn")
    }
  }
  shinyjs::onevent("keydown", "package_name", input_click_enter)
  shinyjs::onevent("keydown", "package_name", input_click_enter)
  
  # Submitting a new email-package alert request
  observeEvent(input$confirm_submit_btn, {
    main_error_msg(NULL)

    package <- trimws(input$package_name)
    if (!package %in% package_info$Package) {
      if (tolower(package) %in% tolower(package_info$Package)) {
        suggestion <- package_info$Package[which(tolower(package) == tolower(package_info$Package))[1]]
        main_error_msg(paste0("Please enter a package that is currently on CRAN (did you mean ", suggestion, "?)"))
      } else {
        main_error_msg("Please enter a package that is currently on CRAN")
      }
      return()
    }
    
    # check user input
    email <- trimws(input$user_email)
    if (!is_valid_email(email)) {
      main_error_msg("Please enter a valid email address")
      return()
    }
    
    shinyjs::hide("page_main")
    shinyjs::show("loader_img_main")
    
    # check if user is already subscribed to this package
    res <- make_pooled_query("SELECT alert_id FROM Alerts WHERE email=? AND package=?", list(email, package))
    already_subscribed <- (nrow(res) > 0)  
    
    if (already_subscribed) {
      email_result <- EmailAlreadySubscribed$new(email = email, package = package)$send()
    } else {
      # check if there is already a confirmation pending for this request
      res <- make_pooled_query("SELECT token FROM Confirmations WHERE email=? AND package=?", list(email, package))
      already_requested <- (nrow(res) > 0)
      
      if (already_requested) {
        # if user already requestd, re-use the token and don't add an entry to the database
        token <- res$token[1]
      } else {
        # generate a token
        token <- paste0("c", gsub("-", "", uuid::UUIDgenerate()))
        # add an entry to the Confirmations table
        make_pooled_query("INSERT INTO Confirmations (token, email, package, timestamp) VALUES (?, ?, ?, strftime('%Y%m%d%H%M%S', 'now'))", list(token, email, package))
      }
      
      email_result <- EmailConfirmSubscription$new(email = email, package = package, token = token)$send()
    }
    
    if (!email_result) {
      shinyjs::show("page_main")
      shinyjs::hide("loader_img_main")
      shinyjs::enable("confirm_submit_btn")
      main_error_msg("An error occurred, please try again")
      return()
    }
    
    shinyjs::hide("loader_img_main")
    shinyjs::reset("package_name")
    shinyjs::show("page_main_response")
  })
  
  observeEvent(input$submit_another_btn, {
    shinyjs::hide("page_main_response")
    shinyjs::show("page_main")
    shinyjs::hide("loader_img_main")
    shinyjs::enable("confirm_submit_btn")
    shinyjs::runjs("$($('#main_content_area').find('input:visible')[0]).focus().click();")
  })
  
  # ----------------------
  # Confirmation page ----
  
  confirm_msg <- reactiveVal()
  output$confirm_msg <- renderUI({
    shinyjs::hide("loader_img_main")
    HTML(confirm_msg())
  })
  
  observeEvent(page_type(), {
    if (page_type() != "confirm") return()
    shinyjs::show("loader_img_main")
    
    query <- parseQueryString(session$clientData$url_search)
    token <- query$token
    
    if (is.null(token)) {
      confirm_msg("Invalid request")
      return()
    }
    
    # Get the information relating to this request from the database
    res <- make_pooled_query("SELECT email, package FROM Confirmations WHERE token=?", list(token))
    if (nrow(res) == 0) {
      confirm_msg("Invalid request")
      return()
    }
    
    email <- res$email[1]
    package <- res$package[1]
    
    # check if this email already exists as a user
    res <- make_pooled_query("SELECT user_id FROM Users WHERE email=?", list(email))
    user_exists <- (nrow(res) > 0)
    
    if (user_exists) {
      # check if user is already subscribed to this package
      res <- make_pooled_query("SELECT alert_id FROM Alerts WHERE email=? AND package=?", list(email, package))
      already_subscribed <- (nrow(res) > 0)
      if (already_subscribed) {
        confirm_msg(paste0("According to our records you're already subscribed to ", tags$strong(package), ", so just sit tight -- you're all set!"))
        return()
      }
    }
    
    # add this user to the Users table if they don't exist yet
    if (!user_exists) {
      unsub_token <- paste0("u", gsub("-", "", uuid::UUIDgenerate()))
      make_pooled_query("INSERT INTO Users (email, unsub_token, timestamp) VALUES (?, ?, strftime('%Y%m%d%H%M%S', 'now'))", list(email, unsub_token))
    }
    
    # add this subscription to the Alerts table
    make_pooled_query("INSERT INTO Alerts (email, package, timestamp) VALUES (?, ?, strftime('%Y%m%d%H%M%S', 'now'))", list(email, package))
    
    confirm_msg(paste0("You're now subscribed to ", tags$strong(package), ". You'll get an email whenever the package gets updated on CRAN."))
    
    # send a confirmation email
    EmailConfirmed$new(email = email, package = package)$send()
  })
  
  # ---------------------
  # Unsubscribe page ----
  
  unsub_msg <- reactiveVal()
  output$unsub_msg <- renderUI({
    shinyjs::hide("loader_img_main")
    HTML(unsub_msg())
  })
  
  observeEvent(page_type(), {
    if (page_type() != "unsub") return()
    
    shinyjs::show("loader_img_main")
    query <- parseQueryString(session$clientData$url_search)
    unsub_token <- query$token
    
    if (is.null(unsub_token)) {
      unsub_msg("Invalid request")
      return()
    }
    
    # Get the email of the user who made this request
    res <- make_pooled_query("SELECT email FROM Users WHERE unsub_token=?", list(unsub_token))
    if (nrow(res) == 0) {
      unsub_msg("Invalid request")
      return()
    }
    
    email <- res$email[1]
    pkg <- query$pkg
    
    # Delete the corresponding rows from the Alerts table and send email
    if (is.null(pkg)) {
      make_pooled_query("DELETE FROM Alerts WHERE email=?", list(email))
      unsub_msg("You have been unsubscribed from all CRANalerts emails")
      EmailUnsubAll$new(email = email)$send()
    } else {
      make_pooled_query("DELETE FROM Alerts WHERE email=? AND package=?", list(email, pkg))
      unsub_msg(paste0("You have been unsubscribed from updates to ", tags$strong(pkg)))
      EmailUnsubPackage$new(email = email, package = pkg)$send()
    }
  })
}