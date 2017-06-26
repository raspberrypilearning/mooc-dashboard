require(RMySQL)

#version of the function that works when the pytohn script is used to create the mysql database and data
#getListOfCourses <- function() {
  #outputPath <- file.path(getwd(),"../data",institution)
  #courses <- list.dirs(path = outputPath, full.names = FALSE, recursive = FALSE)
  #courses <- courses[which(courses != "Courses Data")]
  #return(courses)
#}  

#version of the function that works when the pytohn script is used to create the mysql database and data
#getRuns <- function (course) {
#  print("Getting list of runs")
#  runsPath <- file.path(getwd(),"../data",institution,course)
#  print(runsPath)
#  runs <- list.dirs(path = runsPath, full.names = FALSE, recursive = FALSE)
#  return(runs)
#}

#version of the function that works with the mysql dump
getListOfCourses <- function() {  
  m<-dbDriver("MySQL");
  con<-dbConnect(m,user='root',password=sqlPassword,host='localhost',dbname='moocs');
  query <- sprintf("SELECT DISTINCT(course) FROM Courses WHERE university = '%s'", institution)
  data <- dbGetQuery(con,query)
  courses <- character()
  for(course in data$course){
    courses <- c(courses, course)
  }
  print(courses)
  dbDisconnect(con)
  return(courses)
}

#version of the function that works with the mysql dump
getRuns <- function (course) {
  print("Getting list of runs")
  #runs <- list.dirs(path = runsPath, full.names = FALSE, recursive = FALSE)
  m<-dbDriver("MySQL");
  con<-dbConnect(m,user='root',password=sqlPassword,host='localhost',dbname='moocs');
  query <- sprintf("SELECT run FROM Courses WHERE university = '%s' AND course = '%s'", institution, course)
  data <- dbGetQuery(con,query)
  runs <- character()
  for(run in data$run){
    runs <- c(runs, run)
  }
  print(runs)
  dbDisconnect(con)
  
  return(runs)
}



