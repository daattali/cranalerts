library(htmltools)

base_url <- "https://cranalerts.com"
use_mock_emails <- TRUE
CONFIG_FILE <- "config.yml"
if (file.exists(CONFIG_FILE)) {
  use_mock_emails <- FALSE
  config <- config::get(file = CONFIG_FILE)
  if (!is.null(config$baseurl)) {
    base_url <- config$baseurl
  }
}
if (use_mock_emails) {
  message("----\nNOTE: Emails will not actually be sent, and will instead be printed to console.\n----")
}

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

# Generate the email footer. If the email exists as a registered user, add unsub links.
# If a package is provided, add a link to unsub from that package only. If an unsub_token
# is provided, then we can skip the database lookup.
email_footer <- function(email, package = NULL, unsub_token = NULL) {
  if (is.null(unsub_token)) {
    # TODO this isn't great, con is assumed to be a global variable that just exists
    if (!exists("con") || !is(con, "Pool")) {
      return()
    }
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

Email <- R6::R6Class(
  "Email",
  public = list(
    initialize = function(email, subject, body,
                          include_footer = FALSE, package = NULL, token = NULL) {
      private$email <- email
      private$subject <- subject
      private$body <- body
      private$include_footer <- include_footer
      private$package <- package
      private$token <- token
    },

    # Send an email. Return TRUE if successful, FALSE if an error occurred
    send = function() {
      body <- private$body
      if (is.character(body) && length(body) == 1 && body == "") {
        body <- "<div></div>"
      }
      if (private$include_footer) {
        body <- tagList(body, email_footer(private$email, private$package, private$token))
      }

      if (use_mock_emails) {
        message("--- Mock email ---")
        message("To: ", private$email)
        message("Subject: ", private$subject)
        message("", body)
        message("")
        
        result <- TRUE
      } else {
        result <- try(
          mailR::send.mail(
            from = config$Smtp.From,
            to = private$email,
            replyTo = config$Smtp.ReplyTo,
            subject = private$subject,
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
      }
      
      success <- (class(result) != "try-error" && !is.null(result))
      if (!success) {
        message("Failed to send '", private$subject, "' email to ", private$email)
      }

      success
    }
  ),
  private = list(
    email = NULL,
    subject = NULL,
    body = NULL,    # body cannot be an empty string
    include_footer = NULL,
    package = NULL,
    token = NULL
  )
)

EmailAlreadySubscribed <- R6::R6Class(
  "EmailAlreadySubscribed",
  inherit = Email,
  public = list(
    initialize = function(email, package) {
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

      super$initialize(email, subject, body, include_footer = TRUE, package = package)
    }
  )
)

EmailConfirmSubscription <- R6::R6Class(
  "EmailConfirmSubscription",
  inherit = Email,
  public = list(
    initialize = function(email, package, token) {
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

      super$initialize(email, subject, body, include_footer = TRUE, package = package)
    }
  )
)

EmailConfirmed <- R6::R6Class(
  "EmailConfirmed",
  inherit = Email,
  public = list(
    initialize = function(email, package) {
      subject <- paste0("CRANalerts: Subscription to ", package, " confirmed")
      body <- tags$div(
        style = body_text_css,
        tags$p(
          "You are now subscribed to the", package, "R package. We'll email you every time it gets updated on CRAN."
        )
      )

      super$initialize(email, subject, body, include_footer = TRUE, package = package)
    }
  )
)

EmailUnsubAll <- R6::R6Class(
  "EmailUnsubAll",
  inherit = Email,
  public = list(
    initialize = function(email) {
      subject <- paste0("CRANalerts: Unsubscribed from all emails")
      body <- tags$div(
        style = body_text_css,
        tags$p(
          "Thank you for using",
          tags$a(href=base_url, "CRANalerts"), br(), br(),
          "You are now unsubscribed from all emails."
        )
      )

      super$initialize(email, subject, body, include_footer = FALSE)
    }
  )
)

EmailUnsubPackage <- R6::R6Class(
  "EmailUnsubPackage",
  inherit = Email,
  public = list(
    initialize = function(email, package) {
      subject <- paste0("CRANalerts: Unsubscribed from ", package)
      body <- tags$div(
        style = body_text_css,
        tags$p(
          "Thank you for using",
          tags$a(href=base_url, "CRANalerts"), br(), br(),
          "You are now unsubscribed from updates to the", package, "R package."
        )
      )

      super$initialize(email, subject, body, include_footer = FALSE)
    }
  )
)

EmailAlertUpdated <- R6::R6Class(
  "EmailAlertUpdated",
  inherit = Email,
  public = list(
    initialize = function(email, package, token, new_version) {
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

      super$initialize(email, subject, body, include_footer = TRUE, package = package, token = token)
    }
  )
)

EmailAlertRemoved <- R6::R6Class(
  "EmailAlertRemoved",
  inherit = Email,
  public = list(
    initialize = function(email, package, token) {
      subject <- paste0("CRANalerts: ", package, " has been removed from CRAN")
      body <- tags$div(
        style = body_text_css,
        tags$p(
          "It looks like the R package", package, " has been removed from CRAN."
        )
      )

      super$initialize(email, subject, body, include_footer = TRUE, package = package, token = token)
    }
  )
)
