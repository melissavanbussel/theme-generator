library(shiny)
library(shinyFiles)
library(httr2)
library(tidyverse)
library(zip)
library(jsonlite)
library(shinycssloaders)

server <- function(input, output, session) {

  loading <- reactiveVal(FALSE)
  
  # Before button is pressed, display a message saying download is not yet ready.
  output$status <- renderUI({
    if (loading()) {
      HTML('<span class="purple-background">Generating your theme, please wait...</span>')
    } else {
      if (input$generate_button > 0) {
        HTML('<span class="purple-background">Theme generated successfully! You may now use the download button.</span>')
      } else {
        HTML('<span class="purple-background">Theme has not yet been generated, so there are no files to download.</span>')
      }
    }
  })
  
  # If the user has checked the "Generate images" checkbox and is using shinyapps.io, warn them
  output$checkbox_validator <- renderUI({
    if (Sys.getenv("R_CONFIG_ACTIVE") == "shinyapps" & input$images_checkbox == TRUE) {
      HTML('<br><br><span class="red-background">WARNING: Images cannot be generated when the app is being run from shinyapps.io. Please uncheck the checkbox.</span>')
    } 
  })
  
  observeEvent(input$generate_button, {
    req(input$user_input, input$api_key)
    
    # When button is pressed, display a loading bar/spinner
    loading(TRUE)
    
    # Disable the "Generate my theme" button from being clicked again
    session$sendCustomMessage('disableButton', TRUE)
    
    user_input <- input$user_input
    
    # Create temporary folder to save all outputs to
    temp_dir <- tempdir()
    setwd(temp_dir)
    
    # Generate folder name based on user input
    folder_name <- gsub(" ", "_", tolower(user_input))
    target_folder <- file.path(getwd(), folder_name)
    images_folder <- file.path(target_folder, "images")
    
    # Create directories
    dir.create(target_folder, showWarnings = FALSE, recursive = TRUE)
    dir.create(images_folder, showWarnings = FALSE, recursive = TRUE)
    dir.create(file.path(target_folder, ".github/workflows"), showWarnings = FALSE, recursive = TRUE)
    
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
"# ", user_input, " Quarto presentation

This is a Quarto revealjs presentation template generated using [this app](https://github.com/melissavanbussel/theme-generator), with the following theme:\n", user_input,

"\n## How to use this app

**Pre-requisites:** You will need R and RStudio installed (or if not RStudio, another means of creating `.Rproj` files). To be able to push to GitHub Pages, you will need Git installed, and you will need to have a GitHub account. 

### Step 1: Generating the files

There are two ways to use the Shiny app to generate the files. Option A is to run it from [shinyapps.io](https://melissavanbussel.shinyapps.io/quarto_theme_generator/), and Option B is to run it locally. In order to generate images for the slide backgrounds, Option B must be selected (this is because generating the images takes several minutes, and the app will timeout in the browser mid-way through generating the images). 

#### Option A: Running the app from shinyapps.io 

* Navigate to [https://melissavanbussel.shinyapps.io/quarto_theme_generator/](https://melissavanbussel.shinyapps.io/quarto_theme_generator/).
* Enter a phrase for the theme you would like to generate (e.g., 'Abstract purple minimal'').
* Enter your OpenAI API key (see [this page](https://openai.com/index/openai-api/) to obtain one).
* Ensure that the 'Generate images in addition to CSS?' checkbox is **unchecked**. Leaving it checked (when running from shinyapps.io) will result in the app timing out and not generating the files. 
* Click on the 'Generate my theme' button.
* Notice that the purple text at the top right of the app will initially say 'Theme has not yet been generated, so there are no files to download.'
* Once the files have finished generating, the purple text will change to 'Theme generated successfully! You may now use the download button.'.
* You may now click the 'Download all files' button and save the ZIP folder on your computer. 

#### Option B: Running the app locally

* Download [this](https://github.com/melissavanbussel/theme-generator) repository.
* Ensure all the packages listed at the top of the `ui.R` and `server.R` files are installed (use `install.packages` if not). Note that the project uses `renv`, so packages will be installed at the project-level.
* Run the Shiny app (e.g., open `server.R` in RStudio and click the 'Run App' button).
* Follow the same steps as for Option A, but you may check the 'Generate images in addition to CSS?' checkbox, if you wish. 

### Step 2: Pushing to GitHub Pages 

* Unzip the zip folder that was created. 
* In RStudio, use `New project > Existing directory` to create an R project. When asked to select a folder, select the folder that contains `slides.qmd` and the other generated files.
* Run `renv::init()`. This is necessary to create the `renv.lock` file that GitHub Pages will use to install the required R packages for the project. 
* Push the folder to GitHub. There are many ways to do this, but the steps I usually take are: Create a new (public, not private) repository on GitHub and leave the default configuration options (i.e., do not create a `README.md` or `.gitignore`), then use Git Bash to push the folder to that repository on GitHub. 
* On GitHub, add a `gh-pages` branch and ensure that `gh-pages` is selected under `Settings > Pages > Deploy from a branch`.
* A few minutes later, you should be able to view the slides by going to `Actions` and clicking on `pages build and deployment`, followed by clicking on the link that is shown under the `deploy` workflow run.

### Step 3: Modifying the slide content

* Edit the `slides.qmd` file to add your content.
* Customize the `custom.scss` file to change style elements in the theme. 
* If any new R packages are used in the project, they must be tracked using `renv` (otherwise the slides will not work properly on GitHub Pages). If you have added new packages to the project, run `renv::snapshot()` to update the `renv.lock` file. To check if the `renv.lock` file is currently up-to-date and has all of the necessary information, you can run `renv::status()`. 

**Please note:** The filename of `slides.qmd` must **not** be changed, unless the `.github/workflows/publish.yml` file is also changed accordingly. I recommend leaving the file named as `slides.qmd` unless you have a lot of experience with GitHub Actions and feel comfortable troubleshooting.

### Step 4 (optional): Rendering the slides locally

Please note that the slides never need to be rendered locally in order for them to work properly on GitHub Pages. If you would like to render them locally, though, the following step is necessary: 

* When rendering locally, make a copy of all images in the `images` folder and put them into `slides_files/libs/revealjs/dist/theme`.

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

    # Generate images using DALLE 3
    if (input$images_checkbox == TRUE) {
      image_names <- c("title1.png", paste0("section", 1:3, ".png"), paste0("slide", 1:6, ".png"))
      for (i in 1:length(image_names)){
        response <- request("https://api.openai.com/v1") |>
          req_url_path_append("/images/generations") |>
          req_auth_bearer_token(input$api_key) |>
          req_body_json(
            list(prompt = paste(user_input, "desktop background"))
          ) |>
          req_perform() |>
          resp_body_json()
        
        image_url <- response$data[[1]]$url
        download.file(image_url, file.path(images_folder, image_names[i]), mode = "wb")
        Sys.sleep(30)
      }  
    }
    
    # Get font and font color recommendations using OpenAI Chat model
    chat_response <- request("https://api.openai.com/v1") |>
      req_url_path_append("/chat/completions") |>
      req_auth_bearer_token(input$api_key) |>
      req_body_json(list(
        model = "gpt-4",
        messages = list(
          list(role = "system", content = "You are a design assistant."),
          list(role = "user", content = paste("Based on the theme", user_input, ", recommend a Google font family and three colors for primary, secondary, and accent. The accent color should contrast the other colors. The font family should be the full name used by Google Fonts. Also recommend a pandoc highlight-style name that matches. Provide the recommendations in JSON format with keys: 'font_family', 'primary_color', 'secondary_color', 'accent_color', and 'highlight_style'."))
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
"$tertiary-color: lighten($secondary-color, 15%);\n",
"$accent-color: ", recommendations$accent_color, ";\n",
"$theme-white: #fff;\n",
"$theme-black: #000;\n",

font_url,

"$font-family-sans-serif: '", recommendations$font_family, "', sans-serif;\n

$presentation-heading-color: $theme-white;
$body-color: $primary-color;
$link-color: $secondary-color; 
$selected-text-color: $secondary-color;
$code-color: $accent-color;
$code-block-bg: $tertiary-color;

/*-- scss:rules --*/

@mixin background-full {
  background-size: cover;
  background-position: center;
  background-repeat: no-repeat;
}    

.footer {
  p {
    color: $secondary-color;
  }
  a {
    color: lighten($link-color, 15%);
  }
  a:hover {
    color: lighten($link-color, 25%);
  }
}

.theme-slide1 {
  position: relative;
  z-index: 0;
  
  h2 {
    color: $secondary-color;
  }

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

.theme-slide2 {
  position: relative;
  z-index: 0;
  
  h2 {
    color: $secondary-color;
  }

  &:is(.slide-background) {
    &::before {
      content: '';
      position: absolute;
      top: 0;
      left: 0;
      width: 100%;
      height: 100%;
      background-image: url('slide2.png');
      @include background-full;
      opacity: 0.2;
      z-index: -1;
    }
  }
}

.theme-slide3 {
  position: relative;
  z-index: 0;
  
  h2 {
    color: $secondary-color;
  }

  &:is(.slide-background) {
    &::before {
      content: '';
      position: absolute;
      top: 0;
      left: 0;
      width: 100%;
      height: 100%;
      background-image: url('slide3.png');
      @include background-full;
      opacity: 0.2;
      z-index: -1;
    }
  }
}

.theme-slide4 {
  position: relative;
  z-index: 0;
  
  h2 {
    color: $secondary-color;
  }

  &:is(.slide-background) {
    &::before {
      content: '';
      position: absolute;
      top: 0;
      left: 0;
      width: 100%;
      height: 100%;
      background-image: url('slide4.png');
      @include background-full;
      opacity: 0.2;
      z-index: -1;
    }
  }
}

.theme-slide5 {
  position: relative;
  z-index: 0;
  
  h2 {
    color: $secondary-color;
  }

  &:is(.slide-background) {
    &::before {
      content: '';
      position: absolute;
      top: 0;
      left: 0;
      width: 100%;
      height: 100%;
      background-image: url('slide5.png');
      @include background-full;
      opacity: 0.2;
      z-index: -1;
    }
  }
}

.theme-slide6 {
  position: relative;
  z-index: 0;
  
  h2 {
    color: $secondary-color;
  }

  &:is(.slide-background) {
    &::before {
      content: '';
      position: absolute;
      top: 0;
      left: 0;
      width: 100%;
      height: 100%;
      background-image: url('slide6.png');
      @include background-full;
      opacity: 0.2;
      z-index: -1;
    }
  }
}

.theme-section1 {
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
      background-image: url('section1.png');
      @include background-full;
      opacity: 0.8;
      z-index: -1;
    }
  }
}

.theme-section2 {
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
      background-image: url('section2.png');
      @include background-full;
      opacity: 0.8;
      z-index: -1;
    }
  }
}

.theme-section3 {
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
      background-image: url('section3.png');
      @include background-full;
      opacity: 0.8;
      z-index: -1;
    }
  }
}
")
    writeLines(scss_content, file.path(target_folder, "custom.scss"))

    # Create slides.qmd with sample content
    slides_content <- paste0(
"---
title: 'Presentation Title'
author: 'Your Name Goes Here'
format:
  revealjs:
    theme: custom.scss
    highlight-style: ", tolower(recommendations$highlight_style), "
    title-slide-attributes: 
      data-background-image: 'images/title1.png'
---

## Slide 1 {.theme-slide1}

This is some regular text, and this is some **bold text**, and  [this](https://google.com) is a hyperlink. This is some `inline_code`.

* This is a list item
* So is this
* And this

```{r}
#| echo: true
#| eval: false
print('This is some code')
```

:::footer

This is a footer with a link: [https://wwww.google.com](https://wwww.google.com)

:::

# Section 1 {.theme-section1 .center}

## Slide 2 {.theme-slide2}

This is some regular text, and this is some **bold text**, and  [this](https://google.com) is a hyperlink. This is some `inline_code`.

* This is a list item
* So is this
* And this

```{r}
#| echo: true
#| eval: false
print('This is some code')
```

:::footer

This is a footer with a link: [https://wwww.google.com](https://wwww.google.com)

:::

## Slide 3 {.theme-slide3}

This is some regular text, and this is some **bold text**, and  [this](https://google.com) is a hyperlink. This is some `inline_code`.

* This is a list item
* So is this
* And this

```{r}
#| echo: true
#| eval: false
print('This is some code')
```

:::footer

This is a footer with a link: [https://wwww.google.com](https://wwww.google.com)

:::

# Section 2 {.theme-section2 .center}

## Slide 4 {.theme-slide4}

This is some regular text, and this is some **bold text**, and  [this](https://google.com) is a hyperlink. This is some `inline_code`.

* This is a list item
* So is this
* And this

```{r}
#| echo: true
#| eval: false
print('This is some code')
```

:::footer

This is a footer with a link: [https://wwww.google.com](https://wwww.google.com)

:::

## Slide 5 {.theme-slide5}

This is some regular text, and this is some **bold text**, and  [this](https://google.com) is a hyperlink. This is some `inline_code`.

* This is a list item
* So is this
* And this

```{r}
#| echo: true
#| eval: false
print('This is some code')
```

:::footer

This is a footer with a link: [https://wwww.google.com](https://wwww.google.com)

:::

# Section 3 {.theme-section3 .center}

## Slide 6 {.theme-slide6}

This is some regular text, and this is some **bold text**, and  [this](https://google.com) is a hyperlink. This is some `inline_code`.

* This is a list item
* So is this
* And this

```{r}
#| echo: true
#| eval: false
print('This is some code')
```

:::footer

This is a footer with a link: [https://wwww.google.com](https://wwww.google.com)

:::
")
    writeLines(slides_content, file.path(target_folder, "slides.qmd"))

    # Once files have finished generating, the loading spinner can be turned off
    loading(FALSE)
    
    # After button has been pressed and files have been generated, update the message. 
    output$status <- renderUI({
      if (input$generate_button > 0) {
        HTML('<span class="purple-background">Theme generated successfully! You may now use the download button.</span>')
      } else {
        HTML('<span class="purple-background">Theme has not yet been generated, so there are no files to download.</span>')
      }
    })
    
    output$downloadData <- downloadHandler(
      filename = function() {
        paste("project_files_", Sys.Date(), ".zip", sep = "")
      },
      content = function(file) {
        zip(file, folder_name)
      },
      contentType = "application/zip"
    )
  
  })
}
