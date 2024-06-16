library(shiny)
library(shinyFiles)
library(shinycssloaders)

ui <- fluidPage(
  titlePanel("Generative AI Quarto Theme Generator"),
  sidebarLayout(
    sidebarPanel(
      textInput("user_input", "Enter a phrase:", value = "Abstract purple minimal"),
      shinyDirButton("folder_location", "Select Folder", "Please select a folder"),
      actionButton("generate_button", "Generate my theme")
    ),
    mainPanel(
      withSpinner(textOutput("status"))
    )
  )
)
