getListOfCourses <- function() {
  outputPath <- file.path(getwd(),"../data",institution)
  courses <- list.dirs(path = outputPath, full.names = FALSE, recursive = FALSE)
  courses <- courses[which(courses != "Courses Data")]
  return(courses)
}

getRuns <- function (course) {
  print("Getting list of runs")
  runsPath <- file.path(getwd(),"../data",institution,course)
  print(runsPath)
  runs <- list.dirs(path = runsPath, full.names = FALSE, recursive = FALSE)
  return(runs)
}