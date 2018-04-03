base_url <- "https://cranalerts.com"

fluidPage(
  title = "CRANalerts - Get email alerts when a CRAN package gets updated",
  shinyjs::useShinyjs(),
  tags$link(rel="stylesheet", href="cranalerts.css"),
  tags$link(rel="stylesheet", href="https://fonts.googleapis.com/css?family=Open+Sans"),
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
        textInput("user_email", NULL, "", placeholder = "Your email"), br(),
        actionButton("confirm_submit_btn", "SUBSCRIBE TO UPDATES"),
        tags$em(textOutput("main_error"))
      ),
      div(
        id = "page_main_response",
        div(class="section_title", "Check your email inbox to confirm your subscription"), br(),
        tags$strong("Don't forget to check your spam folder!"), br(), br(),
        actionLink("submit_another_btn", "Subscribe to another package")
      ),
      div(
        id = "page_confirm",
        div(class="section_title", textOutput("confirm_msg")), br(), br(),
        tags$a(href = base_url, "Subscribe to another package")
      ),
      div(
        id = "page_unsub",
        div(class="section_title", textOutput("unsub_msg")), br(), br(),
        tags$a(href = base_url, "Subscribe to a package")
      )
    )
  ),
  div(id = "footer", "A project by", tags$a(href = "http://attalitech.com", "AttaliTech Ltd"))
)