# Generative AI Quarto revealjs theme generator

This Shiny app takes a user-inputted phrase (e.g., "Abstract purple minimal") and generates a Quarto revealjs theme. 

![]("www/demo.png")

## How it works

The app uses the user-inputted phrase and asks ChatGPT to choose a relevant colour scheme and font. There's also an option to generate slide background images, if the app is run locally. 

The app then generates all necessary files: 

* `slides.qmd`
* `custom.scss`
* All generated slide background images, if applicable
* `.gitignore`
* `_quarto.yml`
* A project `README.md` with usage and modification instructions
* A configuration file for GitHub Actions and GitHub Pages -- just push the repo, and the slides will be hosted automatically on GitHub Pages and automatically updated any time a commit is made.

![]("www/app_screenshot.png")

## How to use this app

If you don't want to generate images, you can use the app on [shinyapps.io](https://melissavanbussel.shinyapps.io/quarto_theme_generator/).

If you want to generate images, you will need to download this repo and run the app locally. 

You will need an OpenAI API key for either method. 