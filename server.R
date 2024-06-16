library(shiny)
library(shinyFiles)
library(httr2)
library(tidyverse)

server <- function(input, output, session) {
  roots <- c(wd = '.')
  shinyDirChoose(input, "folder_location", roots = roots)
  
  observeEvent(input$generate_button, {
    req(input$user_input)
    req(input$folder_location)
    
    user_input <- input$user_input
    folder <- parseDirPath(roots, input$folder_location)
    
    # Generate folder name based on user input
    folder_name <- gsub(" ", "_", tolower(user_input))
    target_folder <- file.path(folder, folder_name)
    images_folder <- file.path(target_folder, "images")
    
    # Create directories
    dir.create(target_folder, showWarnings = FALSE, recursive = TRUE)
    dir.create(images_folder, showWarnings = FALSE, recursive = TRUE)
    dir.create(file.path(target_folder, ".github/workflows"), showWarnings = FALSE, recursive = TRUE)
    
    # Create slides.qmd with sample content
    slides_content <- 
"---
title: 'Sample Presentation'
format:
  revealjs:
    theme: custom.scss
---

## Slide 1 {.theme-slide1}

Content for slide 1.

**This** is some [text](https://google.com) and this is some `inline_code`.

```{r}
print('Hello world!')
```

## Slide 2

Content for slide 2.
"
    writeLines(slides_content, file.path(target_folder, "slides.qmd"))
    
# Create .gitignore file
gitignore_content <- 
".Rproj.user
.Rhistory
.RData
.Ruserdata
.Renviron

/.quarto/
/_site/
/slides_files/
"
writeLines(gitignore_content, file.path(target_folder, ".gitignore"))

# Create _quarto.yml file
quarto_yml_content <- paste0(
"project:
  title: ", user_input, " Quarto revealjs Theme
")
writeLines(quarto_yml_content, file.path(target_folder, "_quarto.yml"))


# Create README.md with some filler content
readme_content <- paste0(
"# Project Title

This is a sample Quarto project generated with the following theme:", user_input,

"## How to Use

1. In RStudio, use `New project > Existing directory` to create an R project for the generated outputs folder
2. If pushing to GitHub, run `renv::init()` when R project is opened in RStudio, and use `renv::status()` and `renv::snapshot()` as project is modified in order to keep package information updated
3. If pushing to GitHub, run `git init` inside the project directory and then commit and push
4. on GitHub, add a `gh-pages` branch and ensure that `gh-pages` is selected under `Settings > Pages > Deploy from a branch`.
5. Edit the `slides.qmd` file to add your content.
6. Customize the `custom.scss` file to change the theme.
7. When rendering locally, make a copy of all images in the `images` folder and put them into `slides_files/libs/revealjs/dist/theme`

## Generated Content

This project includes:
- A `slides.qmd` file with sample slides.
- A `custom.scss` file for theme customization.
- An `images` folder with AI-generated background images, based on your user prompt.
- A `publish.yml` file that will configure GitHub Actions to automatically publish your slides to GitHub Pages
- A `.gitignore` to avoid accidentally uploading unnecessary files to GitHub
")
writeLines(readme_content, file.path(target_folder, "README.md"))

# Create .github/workflows/publish.yml file
publish_yml_content <- 
"on:
  workflow_dispatch:
  push:
    branches: main
    
name: Quarto Publish

jobs:
  build-deploy:
    runs-on: ubuntu-latest
    permissions:
      contents: write
    steps:
      - name: Check out repository
        uses: actions/checkout@v4

      - name: Set up Quarto
        uses: quarto-dev/quarto-actions/setup@v2

      - name: Install R
        uses: r-lib/actions/setup-r@v2
        with:
          r-version: '4.2.0'

      - name: Install R Dependencies
        uses: r-lib/actions/setup-renv@v2
        with:
          cache-version: 1

      - name: Ensure revealjs theme directory exists
        run: mkdir -p slides_files/libs/revealjs/dist/theme
          
      - name: Copy images to revealjs theme directory
        run: cp -r images/* slides_files/libs/revealjs/dist/theme          

      - name: Render and Publish
        uses: quarto-dev/quarto-actions/publish@v2
        with:
          target: gh-pages
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
"
writeLines(publish_yml_content, file.path(target_folder, ".github/workflows/publish.yml"))

# Generate image using DALLE 3
response <- request("https://api.openai.com/v1") |>
  req_url_path_append("/images/generations") |>
  req_auth_bearer_token(Sys.getenv("OPENAI_API_KEY")) |>
  req_body_json(
    list(prompt = paste(user_input, "desktop background"))
  ) |>
  req_perform() |>
  resp_body_json()

image_url <- response$data[[1]]$url
download.file(image_url, file.path(images_folder, "slide1.png"), mode = "wb")

# Get font and font color recommendations using OpenAI Chat model
chat_response <- request("https://api.openai.com/v1") |>
  req_url_path_append("/chat/completions") |>
  req_auth_bearer_token(Sys.getenv("OPENAI_API_KEY")) |>
  req_body_json(list(
    model = "gpt-4",
    messages = list(
      list(role = "system", content = "You are a design assistant."),
      list(role = "user", content = paste("Based on the theme", user_input, ", recommend a font family and three colors for primary, secondary, tertiary, and accent. The accent color should contrast the other colors. Provide the recommendations in JSON format with keys: 'font_family', 'primary_color', 'secondary_color', 'tertiary_color', and 'accent_color'."))
    )
  )) |>
  req_perform() |>
  resp_body_json()

recommendations <- fromJSON(chat_response$choices[[1]]$message$content)

font_family <- recommendations$font_family
primary_color <- recommendations$primary_color
secondary_color <- recommendations$secondary_color
accent_color <- recommendations$accent_color

# Create custom.scss with theme elements generated by user prompt
font_url <- paste0("@import url('", "https://fonts.googleapis.com/css2?family=", gsub(" ", "+", recommendations$font_family), "&display=swap", "');\n")
scss_content <- paste0(
"/*-- scss:defaults --*/
$primary-color: ", recommendations$primary_color, ";\n",
"$secondary-color: ", recommendations$secondary_color, ";\n",
"$tertiary-color: ", recommendations$tertiary_color, ";\n",
"$accent-color: ", recommendations$accent_color, ";\n",

font_url,

"$font-family-sans-serif: '", recommendations$font_family, "', sans-serif;\n

$body-color: $primary-color;
$link-color: $secondary-color; 
$link-color-hover: $tertiary-color;
$selected-text-color: $secondary-color;
$code-color: $accent-color;

/*-- scss:rules --*/

@mixin background-full {
  background-size: cover;
  background-position: center;
  background-repeat: no-repeat;
}    

.theme-slide1 {
  position: relative;
  z-index: 0;

  &:is(.slide-background) {
    &::before {
      content: '';
      position: absolute;
      top: 0;
      left: 0;
      width: 100%;
      height: 100%;
      background-image: url('slide1.png');
      @include background-full;
      opacity: 0.2;
      z-index: -1;
    }
  }
}
")
writeLines(scss_content, file.path(target_folder, "custom.scss"))

output$status <- renderText("Theme generated successfully!")
  })
}