require(RMySQL)
source("config.R")

getTable <- function(table,course,course_run){
	m<-dbDriver("MySQL");
	con<-dbConnect(m,user='root',password=sqlPassword,host='localhost',dbname='moocs');
	
	query <- sprintf("SELECT * FROM %s",table)
	if(course != "All" && course_run != "All"){
		course_run <- substring(course_run,1,1)
		query <- sprintf("SELECT * FROM %s t WHERE t.course = '%s' AND t.course_run = %s",table,course,course_run)
	} else if(course != "All"){
		query <- sprintf("SELECT * FROM %s t WHERE t.course = '%s'",table,course)
	} else if(course_run != "All"){
		course_run <- substring(course_run,1,1)
		query <- sprintf("SELECT * FROM %s t WHERE t.course_run = %s",table,course_run)
	}
	data <- dbGetQuery(con,query)
	dbDisconnect(con)
	return(data)
}

getCourseMetaData <- function(){
	m<-dbDriver("MySQL");
	con<-dbConnect(m,user='root',password=sqlPassword,host='localhost',dbname='moocs');
	query <- 'Select * FROM Courses'
	data <- dbGetQuery(con,query)
	dbDisconnect(con)
	return(data)
}

getCourseMetaDataSpecific <- function(course,course_run){
	m<-dbDriver("MySQL");
 	con<-dbConnect(m,user='root',password=sqlPassword,host='localhost',dbname='moocs');
	query <- paste0('Select * FROM Courses WHERE course = "', course, '" And run = ', course_run)
 	data <- dbGetQuery(con,query)
 	dbDisconnect(con)
 	return(data)
 }