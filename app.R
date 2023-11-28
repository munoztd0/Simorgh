
library(shiny)
library(stringr)

# Source the script with the launchPythonScript function
source("launch_py.R")

options(shiny.maxRequestSize = 5 * 1024^3) # 5GB


ui <- fluidPage(
  tags$head(
    tags$style(HTML("
      .centered {
        display: flex;
        justify-content: center;
        align-items: center;
      }
      body { 
        background-color: white !important; 
      }
      /* Other custom CSS */
    "))
  ),
  titlePanel("Simorgh"),
  fluidRow(
    column(1),
    column(4,
      fileInput("fileInput", "Choose ZIP File", accept = c(".zip")),
      textOutput("uploadStatus"),
      uiOutput("unzipUI"), # UI for Unzip button will be rendered here
      uiOutput("parameterInputUI"), # UI for parameters will be rendered here
      br(),
      br()
  ),
  column(7,
       uiOutput("scriptRunUI"), # UI for script execution button and status
       br(),
       uiOutput("imageOutput") # UI for displaying the image
      )
  )
)

server <- function(input, output, session) {
  # Reactive value to track if the file has been unzipped
  fileUnzipped <- reactiveVal(FALSE)
  
  fileUploaded <- reactiveVal(FALSE)
  
  scriptRunSuccessful <- reactiveVal(FALSE)
  
  folderName <- reactiveVal(FALSE)
  
  accountName <- reactiveVal(FALSE)
  
  industryType <- reactiveVal(FALSE)
  
  calculationType <- reactiveVal(FALSE)
  
  observe({
    # Check if a file is uploaded
    if (!is.null(input$fileInput)) {
      fileUploaded(TRUE) # Set the reactive value to TRUE
      output$uploadStatus <- renderText("File uploaded.")
    }
  })

  output$unzipUI <- renderUI({
    if (fileUploaded()) {
      # Render the Unzip button
      fluidRow(
          textInput("folderName", "Project Name", ""),
          actionButton("unzipButton", "Next"),
          textOutput("unzipStatus")
      )
    }
  })

  
  
  observeEvent(input$unzipButton, {
    req(input$fileInput)

    # Progress bar
    withProgress(message = 'Preparing data...', value = 0, {
      folderName <- str_pad(input$folderName, 8, side = "right", pad = "_")
      folderName <- substr(folderName, 1, 8)

      inFile <- input$fileInput
      destDir <- file.path(getwd(), folderName)

      if (!dir.exists(destDir)) {
        dir.create(destDir)
      }

      setProgress(0.5)  # Update progress

      unzip(inFile$datapath, exdir = destDir)

      setProgress(1)  # Complete the progress
      fileUnzipped(TRUE)

      output$unzipStatus <- renderText(paste("Data is ready"))
    })
  })
  

  output$parameterInputUI <- renderUI({
    if (fileUnzipped()) {
      fluidRow(
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
    }
  })
  
  paramsSaved <- reactiveVal(FALSE)
  
  csvFilePath <- reactiveVal(NULL)
  
  
  observeEvent(input$saveButton, {
    
    accountName <- str_pad(input$accountname, 8, side = "right", pad = "_")
    #keep only 8 first characters
    accountName <- substr(accountName, 1, 8)
    
    accountName(accountName)
    
    folderName <- str_pad(input$folderName, 8, side = "right", pad = "_")
    #keep only 8 first characters
    folderName <- substr(folderName, 1, 8)
    
    folderName(folderName)
    
    industryType(input$industrytype)
    
    calculationType(input$calculationtype)
    
    
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

  
    output$saveStatus <- renderText(paste("Parameters saved"))
    
    # After saving, set paramsSaved to TRUE
    paramsSaved(TRUE)
    
    })
  
    output$scriptRunUI <- renderUI({
    if (paramsSaved()) {
      fluidRow(
          actionButton("runScriptButton", "Run Modeling"),
          textOutput("scriptStatus")
      )
    }
  })

  observeEvent(input$runScriptButton, {
  # Check if the parameters have been saved
  req(paramsSaved())

  # Progress bar for the modeling process
  withProgress(message = 'Running modeling script...', value = 0, {
    # Set initial progress
    setProgress(0.5)

    # Run Python script
    tryCatch({
      launchPythonScript(csvFilePath())
      scriptRunSuccessful(TRUE)
      setProgress(1)  # Complete the progress
      output$scriptStatus <- renderText("Script executed successfully.")
    }, error = function(e) {
      setProgress(1)  # Complete the progress even if there's an error
      output$scriptStatus <- renderText(paste("Error in executing script:", e$message))
    })
  })
})

  output$imageOutput <- renderUI({
    if (scriptRunSuccessful()) {
      
      # Define a resource path for the image directory
      
      imageDir <- paste0(getwd(), "/simorghmse/", folderName(), "/", accountName(), "-",folderName(), "-", industryType(),  "-results")
      
      addResourcePath("externalImages", imageDir)

      img(src = paste0("externalImages/", accountName(), "-", folderName(), "-", industryType(), "-visualization.png"), style = "width:100%; height:auto;")
    }
  })

}




shinyApp(ui, server)
