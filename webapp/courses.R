require(RMySQL)

#version of the function that works when the python script is used to create the mysql database and data
#getListOfCourses <- function() {
  #outputPath <- file.path(getwd(),"../data",institution)
  #courses <- list.dirs(path = outputPath, full.names = FALSE, recursive = FALSE)
  #courses <- courses[which(courses != "Courses Data")]
  #return(courses)
#}  

#version of the function that works when the python script is used to create the mysql database and data
#getRuns <- function (course) {
#  print("Getting list of runs")
#  runsPath <- file.path(getwd(),"../data",institution,course)
#  print(runsPath)
#  runs <- list.dirs(path = runsPath, full.names = FALSE, recursive = FALSE)
#  return(runs)
#}

#version of the function that works with the mysql dump
#returns a vector of courses of a certain institution from database
getListOfCourses <- function() {  
  print("Getting the courses")
  
  #creating sql connection
  m<-dbDriver("MySQL");
  con<-dbConnect(m,user='root',password=sqlPassword,host='localhost',dbname='moocs');
  
  #gets a data frame of courses from an institution
  query <- sprintf("SELECT DISTINCT(course) FROM Courses WHERE university = '%s'", institution)
  data <- dbGetQuery(con,query)
  
  #transforms the dataframe into a vector of courses that is returned
  courses <- character()
  for(course in data$course){
    courses <- c(courses, course)
  }
  dbDisconnect(con)
  return(courses)
}

#version of the function that works with the mysql dump
#returns the runs of a specified course
getRuns <- function (course) {
  print("Getting list of runs")
  
  #creating sql connection
  m<-dbDriver("MySQL");
  con<-dbConnect(m,user='root',password=sqlPassword,host='localhost',dbname='moocs');
  
  #gets a data frame of runs of a course and institution
  query <- sprintf("SELECT run FROM Courses WHERE university = '%s' AND course = '%s'", institution, course)
  data <- dbGetQuery(con,query)
  
  #transforms the dataframe into a vector of runs that is returned
  runs <- character()
  for(run in data$run){
    runs <- c(runs, run)
  }

  dbDisconnect(con)
  return(runs)
}



