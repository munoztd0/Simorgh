library(shiny)
library(shinydashboard)
library(stringr)

# Source the script with the launchPythonScript function
source("launch_py.R")

options(shiny.maxRequestSize = 5 * 1024^3) #5GB

ui <- dashboardPage(
  dashboardHeader(title = "Zip File Uploader and Parameter Input"),
  dashboardSidebar(),
  dashboardBody(
    fluidRow(
      box(
        title = "Upload and Unzip",
        status = "primary",
        solidHeader = TRUE,
        collapsible = TRUE,
        fileInput("fileInput", "Choose ZIP File", accept = c(".zip")),
        textInput("folderName", "Project Name", ""),
        actionButton("unzipButton", "Unzip File"),
        textOutput("unzipStatus")
      )
    ),
    uiOutput("parameterInputUI"), # UI for parameters will be rendered here
    uiOutput("scriptRunUI") # UI for script execution button
  )
)

server <- function(input, output, session) {
  # Reactive value to track if the file has been unzipped
  fileUnzipped <- reactiveVal(FALSE)

  observeEvent(input$unzipButton, {
    req(input$fileInput)

    
    folderName <- str_pad(input$folderName, 8, side = "right", pad = "_")
    #keep only 8 first characters
    folderName <- substr(folderName, 1, 8)
    
    

    # if (nchar(folderName) != 8) {
    #   output$unzipStatus <- renderText("Error: The project name must be exactly 8 characters long.")
    #   return()
    # }

    output$unzipStatus <- renderText({
      inFile <- input$fileInput
      destDir <- file.path(getwd(), folderName)

      if (!dir.exists(destDir)) {
        dir.create(destDir)
      }

      unzip(inFile$datapath, exdir = destDir)
      fileUnzipped(TRUE) # Set the reactive value to TRUE
      paste("File unzipped in directory:", destDir)
    })
  })

  output$parameterInputUI <- renderUI({
    if (fileUnzipped()) {
      fluidRow(
        box(
          title = "Input Parameters",
          status = "primary",
          solidHeader = TRUE,
          collapsible = TRUE,
          textInput("accountname", "Account Name", ""),
          selectInput("industrytype", "Industry Type", choices = c("mse", "ndt", "shm")),
          selectInput("calculationtype", "Calculation Type", choices = c("passive", "realtime")),
          selectInput("datatype", "Data Type", choices = c("binary", "segy", "segy2", "sac", "miniseed", "T5", "gcf", "ascii")),
          selectInput("recordingtype", "Recording Type", choices = c("continuous", "triggerbased")),
          sliderInput("samplingrate", "Sampling Rate", min = 0, max = 100000000, value = 10000000),
          sliderInput("datalength", "Data Length (sec)", min = 0, max = 999, value = 4),
          sliderInput("lowfrequency", "Low Frequency (Hz)", min = 0, max = 1000000, value = 100000),
          sliderInput("highfrequency", "High Frequency (Hz)", min = 0, max = 1000000, value = 800000),      
          textAreaInput("description", "Description", ""),
          actionButton("saveButton", "Save Parameters"),
          textOutput("saveStatus")
        )
      )
    }
  })
  
  paramsSaved <- reactiveVal(FALSE)
  
  csvFilePath <- reactiveVal(NULL)
  
  
  observeEvent(input$saveButton, {
    
    accountName <- str_pad(input$accountname, 8, side = "right", pad = "_")
    #keep only 8 first characters
    accountName <- substr(accountName, 1, 8)
    
    folderName <- str_pad(input$folderName, 8, side = "right", pad = "_")
    #keep only 8 first characters
    folderName <- substr(folderName, 1, 8)
    
    
    #paste sampling and data length
    samplingrate <- paste0('"(', input$samplingrate, "," , input$datalength, ')"')
    
    #paste low and high frequency
    frequency <- paste0('"(', input$lowfrequency, "," , input$highfrequency, ')"')
    
    
    # Create a data frame
    parameters <- data.frame(
      col1 = c(accountName, folderName, input$industrytype, input$calculationtype, input$datatype, 
               input$recordingtype, samplingrate, frequency, input$description),
      stringsAsFactors = FALSE
    )
    
    #change row names
    row.names(parameters) = c("0", "1", "2", "3", "4", "5", "6", "7", "8")
    
    
    csvFileName <- paste(accountName, input$industrytype, input$calculationtype, sep = "-")
    csvFilePath <- file.path(getwd(), folderName, paste0(csvFileName, ".csv"))
    
    csvFilePath(csvFilePath)
    
    # Save to a CSV file
    write.csv(parameters, csvFilePath, row.names = TRUE, quote = FALSE)

  
    output$saveStatus <- renderText(paste("Parameters saved in file:", csvFilePath))
    
    # After saving, set paramsSaved to TRUE
    paramsSaved(TRUE)
    
    })
  
    output$scriptRunUI <- renderUI({
    if (paramsSaved()) {
      fluidRow(
        box(
          title = "Run Python Script",
          status = "primary",
          solidHeader = TRUE,
          collapsible = TRUE,
          actionButton("runScriptButton", "Run Python Script"),
          textOutput("scriptStatus")
        )
      )
    }
  })

    observeEvent(input$runScriptButton, {
      # Assume csvFilePath is available here. Adjust this part as per your app's logic
      tryCatch({
        print("running")
        launchPythonScript(csvFilePath())
        print("runned")
        output$scriptStatus <- renderText("Python script executed successfully.")
      }, error = function(e) {
        output$scriptStatus <- renderText(paste("Error in executing script:", e$message))
      })
    })

}




shinyApp(ui, server)
