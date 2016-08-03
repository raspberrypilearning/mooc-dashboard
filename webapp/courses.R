getListOfCourses <- function() {
  #print("Getting list of courses")
  outputPath <- file.path(getwd(),"../data",institution)
  #print(outputPath)
  courses <- list.dirs(path = outputPath, full.names = FALSE, recursive = FALSE)
  # print(courses)
  coursesupdated <- courses[which(courses != "Courses Data")]
  return(coursesupdated)
}

getRuns <- function (course) {
  print("Getting list of runs")
  runsPath <- file.path(getwd(),"../data",institution,course)
  print(runsPath)
  runs <- list.dirs(path = runsPath, full.names = FALSE, recursive = FALSE)
  #print(runs)
  return(runs)
}

getCourseDates <- function (course, run) {
  print("Reading course dates from metadata...")
  file_path <- file.path(getwd(),"../data",institution,course,run,"metadata.csv")
  print(file_path)
  metadata <- read.csv(file = file_path, header = TRUE, sep = ",")
  start_date = as.POSIXct(metadata$start_date[1])
  end_date = as.POSIXct(metadata$end_date[1])
  duration_weeks = metadata$duration_weeks[1]
  return (list(start_date, end_date, duration_weeks))
}

getUpdatedTime <- function() {
  updatedPath <- file.path(getwd(),"../data",institution,"updated.txt")
  updated_time = readChar(updatedPath, file.info(updatedPath)$size)
  return (updated_time)
}


getRunSteps <- function(course, run) {
  file_path <- file.path(getwd(),"../data",institution,course,run,"step-activity.csv")
  stepData <- read.csv(file = file_path, header = TRUE, sep = ",")
  stepData$week_step <- paste0(stepData$week_number,".", sprintf("%02d",as.integer(stepData$step_number)), sep = "")
  steps <- levels(as.factor(stepData$week_step))
  return(steps)
}