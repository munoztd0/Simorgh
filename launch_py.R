# Load necessary library
library(data.table)

# Function to launch Python script
launchPythonScript <- function(csvFilePath) {
  # Read parameters from CSV
  params <- fread(csvFilePath)

  # Assuming that the first row of the CSV contains the parameters
  # Adjust this part according to the structure of your CSV
  args <- as.character(unlist(params[, 2]))

  
  #mv folder to good folder
  if (args[4] == "mse") {
    command <- paste("mv -f", args[3], "simorghmse/")    
    pythonScript <- "simorghmsecode/simorghMSE.py"
  } else if (args[4] == "ndt") {
    command <- paste("mv -f", args[3], "simorghndt/")
    pythonScript <- "simorghndtcode/simorghNDT.py"
  } else if (args[4] == "shm") {
    command <- paste("mv -f", args[3], "simorghshm/")
    pythonScript <- "simorghshmcode/simorghSHM.py"
  }
  
  # Print the command (for debugging purposes)
  cat("Running command:", command, "\n")
  
  #  move tmp folder
  system(command, wait = TRUE)


  # Create the command to run the Python script
  # The command structure will depend on how your Python script expects arguments
  # Here, it's assumed that arguments are passed in order: 'python simorghMSE.py arg1 arg2 ...'
  command <- paste("python3", pythonScript, paste(args[2:5], collapse = " "))
  
  # Print the command (for debugging purposes)
  cat("Running command:", command, "\n")

  # Run the command
  system(command, wait = TRUE)
}


# Example usage
# csvFilePath <- "/home/david/repos/simorgh-aws/Simorgh/simorghmse/test124_/pedro___-mse-passive.csv"
# csvFilePath <- "/home/david/repos/simorgh-aws/Simorgh/test124_/pedro___-mse-passive.csv"
# # Launch the Python script with parameters from CSV
# launchPythonScript(csvFilePath)

# pythonScript <- "./simorghmsecode/simorghMSE.py"
# 

# 
# python3 simorghMSE.py pedro___ test123_  mse passive

