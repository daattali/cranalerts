base_url <- "https://cranalerts.com"
body_text_css <- "font-size: 16px;"
button_css <- "background: #6ebb43; color: white; text-align: center; display: inline-block; padding: 10px 50px; text-decoration: none; font-weight: bold; font-size: 20px;"
AUTHOR_EMAIL <- "daattali@gmail.com"

# Is an email address valid?
is_valid_email <- function(x) {
  grepl("\\<[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}\\>", as.character(x), ignore.case=TRUE)
}

# Build a URI-encoded URL with a list of query string parameters
#
# build_url(list("email"="a@b.com", "package"="shinyjs")) -> 
#   "https://cranalerts.com?email=a%40b.com&package=shinyjs"
build_url <- function(params = list()) {
  paste0(
    base_url,
    "?",
    paste(
      lapply(names(params), function(x) {
        paste0(x, "=", URLencode(params[[x]], reserved = TRUE))
      }),
      collapse = "&"
    )
  )
}

# Send an email. Return TRUE if successful, FALSE if an error occurred
config <- config::get(file = "config.yml")
send_email <- function(to, subject, body) {
  result <- try(
    mailR::send.mail(
      from = config$Smtp.From,
      to = to,
      replyTo = config$Smtp.ReplyTo,
      subject = subject,
      body = as.character(body),
      html = TRUE,
      smtp = list(host.name = config$Smtp.Server,
                  port = config$Smtp.Port, 
                  user.name = config$Smtp.Username, 
                  passwd = config$Smtp.Password, 
                  ssl = TRUE),
      authenticate = TRUE,
      send = TRUE
    ),
    silent = TRUE
  )
  success <- (class(result) != "try-error" && !is.null(result))
  if (!success) {
    message("Failed to send '", subject, "' email to ", to)
  }
  
  success
}

# Generate the email footer. If the email exists as a registered user, add unsub links.
# If a package is provided, add a link to unsub from that package only. If an unsub_token
# is provided, then we can skip the database lookup.
email_footer <- function(email, package = NULL, unsub_token = NULL) {
  if (is.null(unsub_token)) {
    res <- make_pooled_query("SELECT unsub_token FROM Users WHERE email=?", list(email))
    if (nrow(res) > 0) {
      unsub_token <- res$unsub_token[1]
    } else {
      unsub_token <- NULL
    }
  }
  
  tagList(
    tags$p(
      style = paste(body_text_css, "font-style: italic;"),
      "Thanks for using",
      tags$a(href=base_url, "CRANalerts"),
      "--",
      "a project by", tags$a(href = "http://attalitech.com", "AttaliTech Ltd")
    ),
    if (!is.null(unsub_token)) tags$p(
      "---",
      tags$div(
        style = "font-size: 10px;",
        "We promise to never share your email with anyone and never send you any spam.",
        "Don't want more emails?",
        if (!is.null(package)) tagList(
          tags$a(
            href = build_url(c("action"="unsub", "pkg"=package, "token"=unsub_token)),
            "Unsubscribe",
            style = "text-decoration: none; color: inherit; font-weight: bold;"
          ),
          "from updates to", package, "or"
        ),
        tags$a(
          href = build_url(c("action"="unsub", "token"=unsub_token)),
          "Unsubscribe",
          style = "text-decoration: none; color: inherit; font-weight: bold;"
        ),
        "from all emails."
      )
    )
  )
}

# Send a pre-defined type of email
send_email_template <- function(type, email = NULL, package = NULL, token = NULL, new_version = NULL, subject = "", body = tags$div()) {
  if (type == "generic") {
    # Do nothing; generic emails should have the subject and body set in the function call
    body <- tags$div(body)
  } else if (type == "already_subscribed") {
    subject <- paste0("CRANalerts: Already subscribed to ", package)
    body <- tags$div(
      style = body_text_css,
      tags$p(
        "You've recently submitted a request on",
        tags$a(href=base_url, "CRANalerts"),
        "to subscribe",
        "to updates to the", package, "R package.", br(), br(),
        "According to our records",
        "you're already subscribed to", package, ", so just sit tight -- you're all set!"
      )
    )
    body <- tagList(body, email_footer(email, package))
  } else if (type == "confirm_subscription") {
    subject <- paste("CRANalerts: Confirm subscription to", package)
    body <- tags$div(
      style = body_text_css,
      tags$p(
        "You've recently submitted a request on",
        tags$a(href=base_url, "CRANalerts"),
        "to subscribe",
        "to updates to the", package, "R package.", br(), br(),
        "Click the following link to confirm your subscription:"
      ),
      tags$a(
        href = build_url(c("action"="confirm", "token"=token)),
        "Confirm",
        style = button_css
      ),
      tags$p(
        "We will only send you email updates if you click the above link. If you did not submit this request, you can safely ignore this email."
      )
    )
    body <- tagList(body, email_footer(email, package))
  } else if (type == "confirmed") {
    subject <- paste0("CRANalerts: Subscription to ", package, " confirmed")
    body <- tags$div(
      style = body_text_css,
      tags$p(
        "You are now subscribed to the", package, "R package. We'll email you every time it gets updated on CRAN."
      )
    )
    body <- tagList(body, email_footer(email, package))
  } else if (type == "unsub_all") {
    subject <- paste0("CRANalerts: Unsubscribed from all emails")
    body <- tags$div(
      style = body_text_css,
      tags$p(
        "Thank you for using",
        tags$a(href=base_url, "CRANalerts"), br(), br(),
        "You are now unsubscribed from all emails."
      )
    )
  } else if (type == "unsub_package") {
    subject <- paste0("CRANalerts: Unsubscribed from ", package)
    body <- tags$div(
      style = body_text_css,
      tags$p(
        "Thank you for using",
        tags$a(href=base_url, "CRANalerts"), br(), br(),
        "You are now unsubscribed from updates to the", package, "R package."
      )
    )
  } else if (type == "alert_updated") {
    subject <- paste0("CRANalerts: ", package, " has been updated on CRAN!")
    body <- tags$div(
      style = body_text_css,
      tags$p(
        "Good news!", br(), br(),
        "The R package", package, " has been updated to version", new_version, "on CRAN.", br(), br(),
        tags$a(
          href = paste0("https://CRAN.R-project.org/package=", package),
          "See updated package",
          style = button_css
        )
      )
    )
    body <- tagList(body, email_footer(email, package, unsub_token = token))
  } else if (type == "alert_removed") {
    subject <- paste0("CRANalerts: ", package, " has been removed from CRAN")
    body <- tags$div(
      style = body_text_css,
      tags$p(
        "It looks like the R package", package, " has been removed from CRAN."
      )
    )
    body <- tagList(body, email_footer(email, package, unsub_token = token))
  } else if (type == "20190626bug") {
    subject <- "Please ignore all CRANalerts emails from today"
    body <- tags$div(
      style = body_text_css,
      tags$p(
        "We're really sorry for the accidental spam!"
      ),
      tags$p(
        "Earlier today, you may have received emails notifying you that many R packages have been deleted from CRAN. This was not true and you do not have anything to worry about--all your R packages are still on CRAN."
      ),
      tags$p(
        "We realize this may have caused you some distress, and we apologize for that. CRANalerts has been running for over a year without any issues until now, and the bug that caused this mistake has now been fixed. We hope you'll continue to enjoy this free service."
      )
    )
    body <- tagList(body, email_footer(email, unsub_token = token))
  } else {
    message("Unknown email type: ", type)
    stop("Unknown email type: ", type)
  }
  
  send_email(email, subject, body)
}
