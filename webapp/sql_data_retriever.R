require(RMySQL)

getTable <- function(table,course,course_run){
	m<-dbDriver("MySQL");
	con<-dbConnect(m,user='root',password='moocDashboard1',host='localhost',dbname='moocs');

	table <- paste0(c(table," t "))
	where <- ""
	course1 <- "t.course = "
	course_run1 <- "t.course_run = "

	if(course != "All" && course_run != "All"){
		where <- paste0("WHERE ", course1,course,",",course_run1,courserun)
	} else if(course != "All"){
		where <- paste0("WHERE ", course1,course)
	} else if(course_run != "All"){
		where <- paste0("WHERE ", course_run1,course_run)
	}

	query <- paste0(c("SELECT * FROM ",table,where))
	sendQuery<-dbSendQuery(con, query)
	data<- fetch(sendQuery, n = -1)
	dbDisconnect(con)
	return(data)
}