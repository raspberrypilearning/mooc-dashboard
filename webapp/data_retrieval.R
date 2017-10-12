require(RMySQL)
source("config.R")

#' Get information about course and course_run from a specified table
#'
#' @param table name of table to get data from
#' @param course name of course to get data about
#' @param course_run run of the course
#'
#' @return a data frame of data
getTable <- function(table,course,course_run){
	m<-dbDriver("MySQL");
	con<-dbConnect(m,user='root',password=sqlPassword,host='localhost',dbname='moocs');
	
	query <- sprintf("SELECT * FROM %s",table)
	if(course != "All" && course_run != "All"){
		course_run <- strsplit(course_run," - ")[[1]][1]
		query <- sprintf("SELECT * FROM %s t WHERE t.course = '%s' AND t.course_run = %s",table,course,course_run)
	} else if(course != "All"){
		query <- sprintf("SELECT * FROM %s t WHERE t.course = '%s'",table,course)
	} else if(course_run != "All"){
		course_run <- strsplit(course_run," - ")[[1]][1]
		query <- sprintf("SELECT * FROM %s t WHERE t.course_run = %s",table,course_run)
	}
	data <- dbGetQuery(con,query)
	dbDisconnect(con)
	return(data)
}

#' To get specific information about the courses
#'
#' @return returns a data frame of metadata about all courses
getCourseMetaData <- function(){
  
  #creating the mysql connection
	m<-dbDriver("MySQL");
	con<-dbConnect(m,user='root',password=sqlPassword,host='localhost',dbname='moocs');
	
	#gets and then returns the data frame of metadata
	query <- 'Select * FROM Courses'
	data <- dbGetQuery(con,query)
	dbDisconnect(con)
	return(data)
}

#' To get specific course data
#'
#' @param course name of course
#' @param course_run run of the course
#'
#' @return returns a data frame of metadata about a course and a run
getCourseMetaDataSpecific <- function(course,course_run){
  
  #creating the mysql connection
	m<-dbDriver("MySQL");
 	con<-dbConnect(m,user='root',password=sqlPassword,host='localhost',dbname='moocs');
 	
 	#gets and then returns the data frame of metadata of a course and a run
	query <- paste0('Select * FROM Courses WHERE course = "', course, '" And run = ', course_run)
 	data <- dbGetQuery(con,query)
 	dbDisconnect(con)
 	return(data)
}


#' To get all the data from a specified table
#'
#' @param table Name of the table you want to get the data from
#'
#' @return a data frame containing table data
getAllTableData <- function (table){
  
  #creating the mysql connection
  m<-dbDriver("MySQL");
  con<-dbConnect(m,user='root',password=sqlPassword,host='localhost',dbname='moocs');
  
  #getting the data from the table and returning it
  query <- sprintf("SELECT * FROM %s",table)
  data <- dbGetQuery(con,query)
  dbDisconnect(con)
  return(data)
}

