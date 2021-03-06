base_url <- "https://cranalerts.com"

# Create an email input from the parameters of a text input
emailInput <- function(...) {
  tag <- textInput(...)
  tag$children[[2]]$attribs$type <- "email"
  # Prevent LastPass from inserting its icon into the input
  tag$children[[2]] <- tagAppendAttributes(tag$children[[2]], "data-lpignore" = "true")
  tag
}

fluidPage(
  title = "CRANalerts - Get email alerts when a CRAN package gets updated",
  shinydisconnect::disconnectMessage(
    overlayColour = "#999", overlayOpacity = 0.7,
    refresh = "Reload", refreshColour = "#9999FF",
    width = 350, size = 20
  ),
  shinyjs::useShinyjs(),
  tags$head(
    tags$link(rel="stylesheet", href="cranalerts.css"),
    tags$link(rel="stylesheet", href="https://fonts.googleapis.com/css?family=Open+Sans"),
    tags$link(rel = "shortcut icon", type="image/png", href="favicon.png"),
    
    tags$meta(name = "description", content = "Get a notification straight to your email inbox when an R package on CRAN gets updated. A project by AttaliTech."),

    # Facebook OpenGraph tags
    tags$meta(property = "og:title", content = "CRANalerts"),
    tags$meta(property = "og:type", content = "website"),
    tags$meta(property = "og:url", content = "https://cranalerts.com/"),
    tags$meta(property = "og:image", content = "https://cranalerts.com/screenshot.PNG"),
    tags$meta(property = "og:description", content = "Get email alerts when a CRAN package gets updated."),

    # Twitter summary cards
    tags$meta(name = "twitter:card", content = "summary"),
    tags$meta(name = "twitter:site", content = "@daattali"),
    tags$meta(name = "twitter:creator", content = "@daattali"),
    tags$meta(name = "twitter:title", content = "CRANalerts"),
    tags$meta(name = "twitter:description", content = "Get email alerts when a CRAN package gets updated."),
    tags$meta(name = "twitter:image", content = "https://cranalerts.com/screenshot.PNG"),
    
    tags$meta(name="theme-color", content="#4476b3"),
    tags$meta(name="msapplication-navbutton-color", content="#4476b3"),
    tags$meta(name="apple-mobile-web-app-status-bar-style", content="#4476b3")
  ),
  class = "full_content_area",
  
  div(tags$a(href = base_url, id = "page_title", "CRANalerts")),
  div(id = "page_subtitle",
      "Get email alerts when a CRAN package gets updated"),
  
  div(
    id = "main_content_area",
    img(id = "loader_img_main", src="loader_rings_big.gif"),
    shinyjs::hidden(
      div(
        id = "page_main",
        textInput("package_name", NULL, "", placeholder = "R package"), br(),
        emailInput("user_email", NULL, "", placeholder = "Your email"), br(),
        actionButton("confirm_submit_btn", "SUBSCRIBE TO UPDATES"),
        tags$em(textOutput("main_error"))
      ),
      div(
        id = "page_main_response",
        div(class="section_title", "Check your email inbox to confirm your subscription"), br(),
        tags$strong(textOutput("main_response_email")), br(),
        tags$strong("Don't forget to check your spam folder!"), br(), br(),
        actionLink("submit_another_btn", "Subscribe to another package")
      ),
      div(
        id = "page_confirm",
        div(class="section_title", uiOutput("confirm_msg")), br(), br(),
        tags$a(href = base_url, "Subscribe to another package")
      ),
      div(
        id = "page_unsub",
        div(class="section_title", uiOutput("unsub_msg")), br(), br(),
        tags$a(href = base_url, "Subscribe to a package")
      )
    )
  ),
  div(
    id = "footer",
    "A project by", tags$a(href = "http://attalitech.com", "AttaliTech Ltd"),
    HTML("&bull;"),
    tags$a(href = "https://www.paypal.me/daattali/10", "Support us"), br(),
    span(style = "display: inline-block;margin-top: 2px; font-size:14px;",
         "Built entirely in R/Shiny", HTML("&middot;"),
         tags$a("Code", href = "https://github.com/daattali/cranalerts"))
  )
)
