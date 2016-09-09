library(reshape2)
library(RMySQL)
library(xts)
library(networkD3)

getRawData <- function (filename, type) {
	if (type == "step" || type == "comments") {
		data <- read.csv(filename, na.strings=c("","NA"), colClasses = "character")
		data$week <- lapply(data$step, function (x) unlist(strsplit(x, "[.]"))[1])
		data$stepNumber <- lapply(data$step, function (x) unlist(strsplit(x, "[.]"))[2])
		data$week <- as.numeric(data$week)
		data$stepNumber <- as.numeric(data$stepNumber)
		data <- data[order(data$week, data$stepNumber), ]
		step_levels <- as.vector(unique(data$step))
		data$step <- factor(data$step, levels = step_levels)
		return (data)
	}else {
		data <- read.csv(filename, na.strings=c("","NA"))
		return (data)
	}
}

getWeekStep <- function(data){
	weekStep <- paste0(data$week_number,".", sprintf("%02d",as.integer(data$step_number)), sep = "")
	return(weekStep)
}

#gets the list of all learners
getAllLearners <- function (data) {
	learners <- as.vector(data$learner_id)
	print(paste("number of learners: ", length(learners)))
	return (learners)
}

#gets the number of enroled students during the specified period
getEnrolmentCount <- function (learners, startDate, endDate, data) {
	data$enrolled_at <- as.POSIXct(data$enrolled_at, format = "%Y-%m-%d", tz = "GMT")
	data <- subset(data, enrolled_at >= as.POSIXct(startDate, format = "%Y-%m-%d", tz = "GMT"))
	data <- subset(data, enrolled_at <= as.POSIXct(endDate, format = "%Y-%m-%d", tz = "GMT"))
	learners <- as.vector(data$learner_id)
	count <- length(learners)
	return (count)
}

getEnrolmentByDateTime <- function (learners, startDate, endDate, data) {
	data$enrolled_at <- as.POSIXct(data$enrolled_at, format = "%Y-%m-%d %H", tz= "GMT")
	data$unenrolled_at <- as.POSIXct(data$unenrolled_at, format = "%Y-%m-%d %H", tz= "GMT")
	data <- subset(data, learner_id %in% learners)
	data <- subset(data, enrolled_at >= as.POSIXct(startDate))
	mdata <- melt(data, id = c("enrolled_at"), na.rm = TRUE)
	pivotEnrolled <- dcast(mdata, enrolled_at ~., length)
	colnames(pivotEnrolled) <- c("timestamp", "enroled") 
	mdata <- melt(data, id = c("unenrolled_at"), na.rm = TRUE)
	pivotUnenrolled <- dcast(mdata, unenrolled_at ~., length)
	colnames(pivotUnenrolled) <- c("timestamp", "unenroled")
	pivotTotal <- data.frame(union(pivotEnrolled$timestamp, pivotUnenrolled$timestamp))
	colnames(pivotTotal) <- "timestamp"
	pivotTotal$timestamp <- as.POSIXct(pivotTotal$timestamp, format = "%Y-%m-%d %H", origin = "1970-01-01 00", tz= "GMT")
	pivotTotal <- merge(pivotTotal, pivotEnrolled, by = "timestamp", all = TRUE)
	pivotTotal <- merge(pivotTotal, pivotUnenrolled, by = "timestamp", all = TRUE)
	pivotTotal$enroled <- lapply(pivotTotal$enroled, function (x) if (is.na(x)) 0 else as.numeric(x))
	pivotTotal$unenroled <- lapply(pivotTotal$unenroled, function (x) if (is.na(x)) 0 else as.numeric(x))
	pivotTotal$enrolment <- as.numeric(pivotTotal$enroled) - as.numeric(pivotTotal$unenroled)
	pivotTotal$enrolment <- cumsum(pivotTotal$enrolment)
	pivotTotal <- pivotTotal[c("timestamp", "enrolment")]
	pivotTotal <- na.omit(pivotTotal)
	return (pivotTotal)
}


#gets the number of students who completed the course (at least 95% of the steps)
getCompletionCount <- function (learners, startDate, endDate, data) {
	completedCourse <- getStepsCompleted(learners, startDate, endDate, data)
	completedCourse <- subset(completedCourse, completed >= 95)
	count <- nrow(completedCourse)
	return (count)
}


#for each learner in the parameter get the total number of comments made
getNumberOfCommentsByLearner <- function (learners, startDate, endDate, data){
	data$timestamp <- as.Date(data$timestamp, format = "%Y-%m-%d")
#   data <- subset(data, timestamp >= startDate)
#   data <- subset(data, timestamp <= endDate)
	data <- subset(data, author_id %in% learners)
	mdata <- melt(data, id = c("author_id", "step"))
	mdata <- subset(mdata, variable == "id")
	pivot <- dcast(mdata, author_id ~ ., length)
	colnames(pivot) <- c("learner_id","comments")
	return (pivot)
}

#gets the number of comments by step made by the specified learners
getNumberOfCommentsByStep <- function (learners, startDate, endDate, data){
	data$timestamp <- as.POSIXct(data$timestamp, format = "%Y-%m-%d %H", tz= "GMT")
	#data <- subset(data, timestamp >= as.POSIXct(startDate, format = "%Y-%m-%d", tz = "GMT"))
	#data <- subset(data, timestamp <= as.POSIXct(endDate, format = "%Y-%m-%d", tz = "GMT"))
	data <- subset(data, author_id %in% learners)
	mdata <- melt(data, id = c("author_id", "step"))
	mdata <- subset(mdata, variable == "id")
	pivot <- dcast(mdata, step ~ ., length)
	colnames(pivot)[2] <- "comments"
	return (pivot)
}

#date-time series of comments made by the specified learners
getNumberOfCommentsByDate <- function (learners, startDate, endDate, data){
	mdata <- melt(data, id = c("author_id", "id"))
	mdata <- subset(mdata, variable == "timestamp")
	mdata$value <- as.POSIXct(mdata$value, format = "%Y-%m-%d %H", tz = "GMT")
	#mdata <- subset(mdata, value >= as.POSIXct(startDate, format = "%Y-%m-%d", tz = "GMT"))
	#mdata <- subset(mdata, value <= as.POSIXct(endDate, format = "%Y-%m-%d", tz = "GMT"))
	mdata <- subset(mdata, author_id %in% learners)
	pivot <- dcast(mdata, value ~ ., length)
	colnames(pivot) <- c("timestamp", "comments")
	return (pivot) 
}

#gets the number of comments by step and date made by the specified learner
#the form of the table is ready for conversion to a matrix
getNumberOfCommentsByDateStep <- function (learners, startDate, endDate, data){
	data$timestamp <- as.POSIXct(data$timestamp, format = "%Y-%m-%d")
	#data <- subset(data, timestamp >= as.POSIXct(startDate, format = "%Y-%m-%d", tz = "GMT"))
	#data <- subset(data, timestamp <= as.POSIXct(endDate, format = "%Y-%m-%d", tz = "GMT"))
	data <- subset(data, author_id %in% learners)
	mdata <- melt(data, id = c("author_id", "step", "timestamp"))
	mdata <- subset(mdata, variable == "id")
	pivot <- dcast(mdata, timestamp ~ step, length)
	pivot[,1] <- as.numeric(pivot[,1])
	pivot[,2:length(pivot)] <- apply(pivot[,2:length(pivot)], c(1, 2), function (x) as.numeric(as.character(x)))
	return (pivot)
}


#gets the number of replies by date received by the specified learners
getNumberOfRepliesByDate <- function (learners, startDate, endDate, data){
	data$timestamp <- as.POSIXct(data$timestamp, format = "%Y-%m-%d %H", tz = "GMT")
	#data <- subset(data, timestamp >= as.POSIXct(startDate, format = "%Y-%m-%d", tz = "GMT"))
	#data <- subset(data, timestamp <= as.POSIXct(endDate, format = "%Y-%m-%d", tz = "GMT"))
	data <- subset(data, author_id %in% learners)
	mdata <- melt(data, id = c("timestamp", "author_id", "id"), na.rm = TRUE)
	mdata <- subset(mdata, variable == "parent_id")
	pivot <- dcast(mdata, timestamp + variable ~ ., length)
	colnames(pivot)[3] <- "replies"
	return (pivot[c("timestamp", "replies")])
}

#gets the number of replies by step received by the specified learners
getNumberOfRepliesByStep <- function (learners, startDate, endDate, data){
	data$timestamp <- as.POSIXct(data$timestamp, format = "%Y-%m-%d %H", tz = "GMT")
	#data <- subset(data, timestamp >= as.POSIXct(startDate, format = "%Y-%m-%d", tz = "GMT"))
	#data <- subset(data, timestamp <= as.POSIXct(endDate, format = "%Y-%m-%d", tz = "GMT"))
	data <- subset(data, author_id %in% learners)
	mdata <- melt(data, id = c("step", "author_id", "id"), na.rm = TRUE)
	mdata <- subset(mdata, variable == "parent_id")
	pivot <- dcast(mdata, step + variable ~ ., length)
	colnames(pivot)[3] <- "replies"
	return (pivot[c("step", "replies")])
}

#for each specified learner find the number of replies he has received
getNumberOfRepliesByLearner <- function (learners, startDate, endDate, data){
	data$timestamp <- as.POSIXct(data$timestamp, format = "%Y-%m-%d %H", tz = "GMT")
	#data <- subset(data, timestamp >= as.POSIXct(startDate, format = "%Y-%m-%d", tz = "GMT"))
	#data <- subset(data, timestamp <= as.POSIXct(endDate, format = "%Y-%m-%d", tz = "GMT"))
	data <- subset(data, author_id %in% learners)
	mdata <- melt(data, id = c("step", "author_id", "id"), na.rm = TRUE)
	mdata <- subset(mdata, variable == "parent_id")
	pivot <- dcast(mdata, author_id + variable ~ ., length)
	colnames(pivot) <- c("learner_id", "", "replies")
	return (pivot[c("learner_id", "replies")])
}

#gets the number of likes by step received by the specified learners
getNumberOfLikesByStep <- function (learners, startDate, endDate, data){
	data$timestamp <- as.POSIXct(data$timestamp, format = "%Y-%m-%d %H", tz = "GMT")
	#data <- subset(data, timestamp >= as.POSIXct(startDate, format = "%Y-%m-%d", tz = "GMT"))
	#data <- subset(data, timestamp <= as.POSIXct(endDate, format = "%Y-%m-%d", tz = "GMT"))
	data <- subset(data, author_id %in% learners)
	mdata <- melt(data, id = c("author_id", "step"))
	mdata <- subset(mdata, variable == "likes")
	mdata$value <- as.numeric(mdata$value)
	pivot <- dcast(mdata, step + variable ~ ., sum)
	colnames(pivot)[3] <- "likes"
	return (pivot[c("step", "likes")])
}

#gets the number of likes by date received by the specified learners
getNumberOfLikesByDate <- function (learners, startDate, endDate, data){
	data$timestamp <- as.POSIXct(data$timestamp, format = "%Y-%m-%d %H", tz = "GMT")
 # data <- subset(data, timestamp >= as.POSIXct(startDate, format = "%Y-%m-%d", tz = "GMT"))
 # data <- subset(data, timestamp <= as.POSIXct(endDate, format = "%Y-%m-%d", tz = "GMT"))
	data <- subset(data, author_id %in% learners)
	mdata <- melt(data, id = c("author_id", "timestamp"))
	mdata <- subset(mdata, variable == "likes")
	mdata$value <- as.numeric(mdata$value)
	pivot <- dcast(mdata, timestamp + variable ~ ., sum)
	colnames(pivot)[3] <- "likes"
	return (pivot[c("timestamp", "likes")])
}

getNumberOfLikesByLearner <- function (learners, startDate, endDate, data) {
	data <- subset(data, author_id %in% learners)
	mdata <- melt(data, id = c("author_id"))
	mdata <- subset(mdata, variable == "likes")
	mdata$value <- as.numeric(mdata$value)
	pivot <- dcast(mdata, author_id + variable ~ ., sum)
	colnames(pivot)[c(1, 3)] <- c("learner_id", "likes")
	return (pivot[c("learner_id", "likes")])
}

#gets the number of comment authors by date
getNumberOfAuthorsByDate <- function (learners, startDate, endDate, data){
	data$timestamp <- as.POSIXct(data$timestamp, format = "%Y-%m-%d", tz = "GMT")
	#data <- subset(data, timestamp >= as.POSIXct(startDate, format = "%Y-%m-%d", tz = "GMT"))
	#data <- subset(data, timestamp <= as.POSIXct(endDate, format = "%Y-%m-%d", tz = "GMT"))
	data <- subset(data, author_id %in% learners)
	mdata <- melt(data, id = c("timestamp"))
	mdata <- subset(mdata, variable == "author_id")
	mdata <- unique(mdata)
	pivot <- dcast(mdata, timestamp + variable ~ ., length)
	colnames(pivot)[3] <- "authors"
	return (pivot[c("timestamp", "authors")])
}

#returns time of enrolment and unenrolment of the specified learners
getEnrolmentTime <- function (learners, startDate, endDate, data){
	enrolment <- subset(data, learner_id %in% learners)
	enrolment$enrolled_at <- as.POSIXct(enrolment$enrolled_at, format = "%Y-%m-%d %H", tz= "GMT")
	#enrolment <- subset(enrolment, value >= as.POSIXct(startDate))
	return (enrolment)
}

#date-time series of quiz answers submitted by the specified learners
getNumberOfResponsesByDateTime <- function (learners, startDate, endDate, data){
	
	print(data)
	
	
	mdata <- melt(data, id = c("learner_id", "quiz_question"))
	mdata <- subset(mdata, variable == "submitted_at")
	mdata$value <- as.POSIXct(mdata$value, format = "%Y-%m-%d %H", tz= "GMT")
	
	#HERE
	
	print(paste("getNumberOfResponsesByDateTime Start date: ",startDate))
	print(paste("getNumberOfResponsesByDateTime End date: ",endDate))
	
	
	mdata <- subset(mdata, value >= as.POSIXct(startDate))
	
	
	
	pivot <- dcast(mdata, value + learner_id ~ ., length)
	colnames(pivot)[c(1,3)] <- c("timestamp", "submits")
	count <- subset(pivot, learner_id %in% learners)
	count <- ddply(count, ~timestamp, summarise, submits = sum(submits))
	return (count[c("timestamp", "submits")])
}

getNumberOfResponsesByLearner <- function (learners, startDate, endDate, data){
	data <- subset(data, learner_id %in% learners)
	mdata <- melt(data, id = c("learner_id"))
	mdata <- subset(mdata, variable == "quiz_question")
	pivot <- dcast(mdata, learner_id  ~ ., length)
	colnames(pivot)[2] <- "submits"
	return (pivot)
}

getPercentageOfAnsweredQuestions <- function (learners, startDate, endDate, data) {
	questions <- as.vector(unique(data$quiz_question))
	mdata <- melt(data, id = c("learner_id"))
	mdata <- subset(mdata, variable == "quiz_question")
	mdata<- unique(mdata)
	pivot <- dcast(mdata, learner_id ~ ., length)
	colnames(pivot)[2] <- "answers"
	pivot$completion <- (pivot$answers / length(questions)) * 100
	return (pivot[c("learner_id", "completion")])
}

#gets the percentage of correct and wrong answers for the specified learners
getResponsesPercentage <- function (learners, startDate, endDate, data){
	data$submitted_at <- as.POSIXct(data$submitted_at, format = "%Y-%m-%d %H", tz= "GMT")
#  data <- subset(data, submitted_at >= as.POSIXct(startDate))
	mdata <- melt(quiz_data, id = c("learner_id"))
	mdata <- subset(mdata, variable == "correct")
	correct <- subset(mdata, value == "true")
	wrong <- subset(mdata, value == "false")
	correctPivot <- dcast(correct, learner_id ~ ., length)
	wrongPivot <- dcast(wrong, learner_id ~ ., length)
	colnames(correctPivot)[2] <- "correct_count"
	colnames(wrongPivot)[2] <- "wrong_count"
	finalPivot <- merge(correctPivot, wrongPivot)
	finalPivot$correct <- (finalPivot$correct_count / (finalPivot$wrong_count + finalPivot$correct_count)) * 100
	finalPivot$wrong <- (finalPivot$wrong_count / (finalPivot$wrong_count + finalPivot$correct_count)) * 100
	percentage <- subset(finalPivot, learner_id %in% learners)
	return (percentage[c("learner_id", "correct", "wrong")])
}

#for each step and date-time, gets the number of students who have visited and completed it
getStepActivity <- function(learners, startDate, endDate, data){
	data <- subset(data, learner_id %in% learners)
	mdata <- melt(data, id = c("step"), na.rm = TRUE)
	visited <- subset(mdata, variable == c("first_visited_at"))
	completed <- subset(mdata, variable == c("last_completed_at"))
	visited$value <- as.POSIXct(visited$value, format = "%Y-%m-%d %H", tz= "GMT")
	completed$value <- as.POSIXct(completed$value, format = "%Y-%m-%d %H", tz= "GMT")
 # visited <- subset(visited, value >= as.POSIXct(startDate, format = "%Y-%m-%d", tz = "GMT"))
	#completed <- subset(completed, value >= as.POSIXct(startDate, format = "%Y-%m-%d", tz = "GMT"))
 # visited <- subset(visited, value <= as.POSIXct(endDate, format = "%Y-%m-%d", tz = "GMT"))
 # completed <- subset(completed, value <= as.POSIXct(endDate, format = "%Y-%m-%d", tz = "GMT"))
	visitedPivot <- dcast(visited, step + value ~ ., length)
	completedPivot <- dcast(completed, step + value ~ ., length)
	colnames(visitedPivot)[3] <- "visited"
	colnames(completedPivot)[3] <- "completed"
	finalPivot <- merge(visitedPivot, completedPivot)
	return (finalPivot)
}

#for the specified learners, gets the percentage of completed steps
getStepsCompleted <- function (learners, startDate, endDate, data){
	step_levels <- as.vector(unique(data$step))
	data <- subset(data, learner_id %in% learners)  
#   data <- subset(data, as.Date(first_visited_at, format = "%Y-%m-%d") >= startDate)
#   data <- subset(data, as.Date(first_visited_at, format = "%Y-%m-%d") <= endDate)
	mdata <- melt(data, id = c("learner_id", "step"), na.rm = TRUE)
	mdata <- subset(mdata, variable == "last_completed_at")
	pivot <- dcast(mdata, learner_id + step ~ ., length)
	pivot <- subset(pivot, !is.na(step))
	pivot <- dcast(pivot, learner_id ~ ., length)
	pivot$completed <- (pivot$`.` / (length(step_levels))) * 100
	return (pivot[c("learner_id", "completed")])
}

getFunnelOfParticipation <- function (enrolment_data, step_data, comments_data, assignments_data, startDate, endDate) {
	#the total number of enroled students
	total <- getAllLearners(enrolment_data)
	#the total number of students who completed at least five steps
	mdata <- melt(step_data, id = c("learner_id", "step"), na.rm = TRUE)
	mdata <- subset(mdata, variable == "last_completed_at")
	pivot <- dcast(mdata, learner_id ~ ., length)
	colnames(pivot)[2] <- "count"
	completedSteps <- subset(pivot, count >= 5)
	#the number of students who posted at least five comments
	madeComments <- getNumberOfCommentsByLearner(completedSteps$learner_id, startDate, endData, comments_data)
	madeComments <- subset(madeComments, comments >= 5)
	#the number of students who completed the assignment
	completedAssignment <- subset(assignments_data, author_id %in% madeComments$learner_id)
	#the number of students who completed at least 95% of the steps
	completedCourse <- getStepsCompleted(completedAssignment$author_id, startDate, endDate, step_data)
	completedCourse <- subset(completedCourse, completed >= 95)
	#the final data frame
	participation <- c("Total enrolment", "Completed at least 5 steps", "Made at least 5 comments", "Completed the assignment",
										 "Completed at least 95% of the steps")
	count <- c(length(total), nrow(completedSteps), nrow(madeComments), nrow(completedAssignment), nrow(completedCourse))
	funnel <- data.frame(cbind(participation, count))
	funnel$participation <- as.character(funnel$participation)
	funnel$count <- as.numeric(as.character(funnel$count))
	return (funnel)
}

##NETWORK LIN CODE


getNewLearnersByDate <- function(data){
	d <- melt(data, id = c('timestamp','author_id'),na.rm = TRUE)
	d <- subset(d,variable == 'id')
	aut <- dcast(d,timestamp + author_id ~.,length)
	uni_author <- dcast(d,author_id ~.,length)
	i <- match(uni_author$author_id,aut$author_id)
	uni_author <- aut[i,]
	return (dcast(uni_author,timestamp ~ 'New_Nodes', length))
}

getNewConnectionByDate <- function(data){
	
	d <- melt(data, id = c('timestamp','author_id'),na.rm = TRUE)
	com <- subset(d,variable == 'id')
	rp <- subset(d, variable == 'parent_id')
	rp2Com <- merge(com,rp,by.x = 'value', by.y = 'value')
	rp2Com <- dcast(rp2Com,timestamp.y + author_id.y + author_id.x ~., length )
	colnames(rp2Com) <- c('timestamp','Givers','Receivers','Count')
	rp2Com <- subset(rp2Com, Givers != Receivers)
	# remove duplication
	rp2Com <- rp2Com[!duplicated(rp2Com[,2:3]),]
	return (dcast(rp2Com,timestamp ~ 'New_Connection',length))
}

getDensityByDate <- function(data1, data2){
	data <- data.frame()    
	if(length(data1[,1]) >= length(data2[,1])){
		n <- names(data2)[2]
		data1$col <- 0
		i <- match(data2[,1],data1[,1])
		i1 <- i[!is.na(i)]
		i2 <- data2[is.na(i),]
		
		if(length(i2[,1])!= 0){
			ir <- match(data1[i1,1],data2[,1])
			nRow <- i1
			nRow[,2] <- 0
			nRow$col <- i1[,2]
			colnames(nRow)[2:3] = c(names(data1)[2],n)
			data1$col[i] <- data2[,2]
			colnames(data1)[3] <- n
			data1 <- rbind(data1,nRow)
		}
		else{
			
			data1$col[i] <- data2[,2]
			colnames(data1)[3] <- n
			
		}
		data <- data1
	}else{
		n <- names(data1)[2]
		data2$col <- 0
		i <- match(data1[,1],data2[,1])
		i1 <- i[!is.na(i)]
		i2 <- data1[is.na(i),]
		if(length(i2[,1])!=0){
			ir <- match(data2[i1,1],data1[,1])
			nRow <- i2
			nRow[,2] <- 0
			nRow$col <- i2[,2]
			colnames(nRow)[2:3] = c(names(data2)[2],n)
			data2$col[i1] <- data1[,2][ir]
			colnames(data2)[3] <- n
			data2 <- rbind(data2,nRow)
			
		}else{
			data2$col[i] <- data1[,2]
			colnames(data2)[3] <- n
		}
		data <- data2
	}
	data$Connection <- cumsum(data$New_Connection)
	data$Nodes <- cumsum(data$New_Nodes)
	data$DensityEachDay <- data$Connection / (data$Nodes*(data$Nodes - 1)/2)
	data <- data[order(data$timestamp),]
	return (data)
}

getReciprocityByDate <- function(data) {
	
	
	rp2Com <- getConnection(data)
	
	recip <- rp2Com[!duplicated(rp2Com[,2:3]),]
	
	recip <- recip[duplicated(apply(recip[,2:3],1,function(x) paste(sort(x),collapse=''))),]
	return (dcast(recip,timestamp ~ 'New_bdConnection',length))
	
}

# merge density and reciprocity
getFinalData <- function(data1,data2) {
	density <- data1
	reciprocity <- data2
	
	if(length(names(density)) < length(names(reciprocity))){
		density <- data2  
		reciprocity <- data1  
	}
	
	i <- match(reciprocity$timestamp,density$timestamp)
	
	density$New_bdConnection <- 0
	density$New_bdConnection[i] <- reciprocity$New_bdConnection
	density$bdConnection <- cumsum(density$New_bdConnection)
	density$ReciprocityEachDay <- density$bdConnection/(density$Nodes*(density$Nodes - 1)/2)
	density$PC <- density$Nodes * (density$Nodes - 1) /2
	l <- nrow(density)
	density$Density <- density$Connection / density$PC[l]
	density$Reciprocity <- density$bdConnection / density$PC[l]
	
	return (density)
}



getConnection <- function(data){
	d <- melt(data, id = c('timestamp','author_id'),na.rm = TRUE)
	com <- subset(d,variable == 'id')
	rp <- subset(d, variable == 'parent_id')
	rp2Com <- merge(com,rp,by.x = 'value', by.y = 'value')
	rp2Com <- dcast(rp2Com,timestamp.y + author_id.y + author_id.x ~., length )
	colnames(rp2Com) <- c('timestamp','Givers','Receivers','Count')
	rp2Com <- subset(rp2Com, Givers != Receivers)
	
	return (rp2Com)
}

#default list 10 learner
getNetworkByLearner <- function(data,number = 10){
	rp2Com <- getConnection(data)
	
	aut_rp <- dcast(rp2Com,Givers ~ 'Replies',length)
	aut_rp <- aut_rp[order(aut_rp$Replies,decreasing = TRUE),]
	aut_rp <- aut_rp$Givers[1:number]    
	
	i <-  apply(as.matrix(aut_rp),1,function(x) which(rp2Com$Givers %in% x))   
	i <- unlist(i)
	rp2Com <- rp2Com[i,]
	return (rp2Com[order(rp2Com$timestamp),])
	
}

# default list 7 learner
getDegreeByLearner <- function(data, number = 7){
	
	rp2Com <- getConnection(data)
	
	aut_rp <- dcast(rp2Com,Givers ~ 'Replies',length)
	aut_rp <- aut_rp[order(aut_rp$Replies,decreasing = TRUE),]
	aut_rp <- aut_rp$Givers[1:number]
	
	
	degree <- data.frame(unique(rp2Com$timestamp))
	
	
	for (n in 1: number){
		
		degree <- cbind(degree,matrix(0,nrow = nrow(degree),ncol = 1))
		i <- which(rp2Com$Givers %in% aut_rp[n])
		aut <- rp2Com[i,]
		t <- dcast(aut,timestamp ~.,length)
		dg <- apply(as.matrix(t$timestamp),1,function(x) sum(as.numeric(aut$Count[which(aut$timestamp %in% x)])))
		t$.<- dg
		
		i <- match(t$timestamp,degree[,1])
		degree[,n + 1][i] <- t$.
		degree[,n + 1] <- cumsum(degree[,n + 1])
	}
	
	colnames(degree)[1:8] <- c('timestamp',aut_rp)
	return (degree)
	
}

# take two parameters
# comment calculates the length of course

getSetOfLearnersByDate <- function(courseDuration, startDate, enrolment){
	maxWeek <- courseDuration
	div <- 0
	set <- 0
	
	if(maxWeek > 8){
		div <- 3
		set <- ceiling(maxWeek /div)
	}else if(maxWeek == 3){
		div <- 1
		set <- 3
	}else{
		div <- 2
		set <- ceiling(maxWeek / div)
	}

	dayDiff <- div * 7
	dateSet <- data.frame()
	sd <- as.Date(startDate)

	e <- enrolment
	e$enrolled_at <-  as.POSIXct(e$enrolled_at, format = "%Y-%m-%d", tz = "UTC")
	
	#filter people not learner
	#e <- subset(e, e$role == 'learner)
	ws <- character(0)
	week = 1
	for (i in 1 : set){
		beg <- sd
		end <- sd + dayDiff
		dateSet <- rbind(dateSet,c(beg,end))
		ws[i] <- paste(paste('w',week,sep = ''),paste('-w',week + div - 1,sep = ''),sep = '')
		sd <- sd + dayDiff + 1
		week = week + div
	}
	
	colnames(dateSet) <- c('start','end')
	dateSet$set <- ws
	
	setOflearner <- character(0)
	
	for(n in 1 : length(e$enrolled_at)){
		date <- e$enrolled_at[n]
		if(as.Date(date) < as.Date(dateSet$end[1])){
			setOflearner[n] <- dateSet$set[1]
			
		}else if(as.Date(date) >= as.Date(dateSet$start[nrow(dateSet)])){
			setOflearner[n] <- dateSet$set[nrow(dateSet)]    
			
		}else{
			d <- as.Date(date) >= as.Date(dateSet$start) & as.Date(date) <= as.Date(dateSet$end)
			setOflearner[n] <- dateSet$set[d]
			
		}
	}
	e$set <- setOflearner
	
	e <- dcast(e,enrolled_at + learner_id + set~.,length)
	
	
	return(e)
	

}

getStepsCompletedData <- function(stepData){
	data <- stepData
	completedSteps <- subset(data, last_completed_at != "")
	completedSteps$week_step <- getWeekStep(completedSteps)
	stepsCount <- count(completedSteps, 'week_step')
	return (stepsCount)
}

getStepCompletionHeatMap <- function(stepData, startDate){
	data <-stepData
	completedSteps <- subset(data, last_completed_at != "")
	completedSteps$week_step <- getWeekStep(completedSteps)
	data <- completedSteps[,c("week_step", "last_completed_at")]
	data$last_completed_at <- unlist(lapply(data$last_completed_at, function(x) substr(x,1,10)))
	data$count <- 1
	aggregateData <- aggregate(count ~., data, FUN = sum)
	aggregateData <- subset(aggregateData , as.numeric(gsub("-","",aggregateData$last_completed_at)) >= startDate)
	pivot <- dcast(aggregateData, last_completed_at ~ week_step)
	pivot[is.na(pivot)] <- 0
	map <- as.data.frame(pivot)
	return(map)
}

getFirstVisitedHeatMap <- function(stepData, startDate){
	data <-stepData
	data$week_step <- getWeekStep(data)
	data <- data[,c("week_step", "first_visited_at")]
	data$first_visited_at <- unlist(lapply(data$first_visited_at, function(x) substr(x,1,10)))
	data$count <- 1
	aggregateData <- aggregate(count ~., data, FUN = sum)
	aggregateData <- subset(aggregateData , as.numeric(gsub("-","",aggregateData$first_visited_at)) >= startDate)
	pivot <- dcast(aggregateData, first_visited_at ~ week_step)
	pivot[is.na(pivot)] <- 0
	map <- as.data.frame(pivot)
	return(map)
}

getCommentsBarChart <- function(stepData,comments){
	steps <- stepData
	data <- comments
	stepLevels <- unique(getWeekStep(steps))
	plotData <-data.frame(week_step = stepLevels, post = integer(length = length(stepLevels)), reply = integer(length = length(stepLevels)),stringsAsFactors = FALSE)
	data$week_step <- getWeekStep(data)
	data <- data[,c("week_step", "parent_id")]
	posts <- subset(data, is.na(data$parent_id))
	replies <- subset(data, !is.na(data$parent_id))[,c("week_step")]
	postCount <- count(posts)
	replyCount <- count(replies)
	replyCount$week_step <- as.character(replyCount$x)
	for(x in c(1:length(postCount$freq))){
		plotData[plotData$week_step == postCount$week_step[x],]$post <- postCount$freq[x]
	}
	for(x in c(1:length(replyCount$freq))){
		plotData[plotData$week_step == replyCount$week_step[x],]$reply <- replyCount$freq[x]
	}
	return(plotData)
}

getGenderCount <- function(enrolmentData){
	data <- enrolmentData
	gender <- as.character(data$gender)
	gender <- gender[gender!="Unknown"]
	genderCount <- count(gender)
	genderCount <- genderCount[order(-genderCount$freq),]
	names(genderCount)[names(genderCount)=="x"] <- "gender"
	genderCount$percentage <- genderCount$freq / sum(genderCount$freq) * 100
	genderCount$percentage <- round(genderCount$percentage,2)
	return(genderCount)
}

getLearnerAgeCount <- function(enrolmentData){
	data <- enrolmentData
	age <- as.character(data$age_range)
	age <- age[age!="Unknown"]
	ageCount <- count(age)
	ageCount <- ageCount[order(-ageCount$freq),]
	names(ageCount)[names(ageCount)=="x"] <- "age_group"
	ageCount$percentage <- ageCount$freq / sum(ageCount$freq) * 100
	ageCount$percentage <- round(ageCount$percentage,2)
	return(ageCount)
}

getEmploymentAreaCount <- function(enrolmentData){
	enrolments <- enrolmentData
	employment <- as.character(enrolments$employment_area)
	employment <- employment[employment!="Unknown"]
	employmentCount <- count(employment)
	names(employmentCount)[names(employmentCount)=="x"] <- "employment"
	employmentCount$percentage <- employmentCount$freq / sum(employmentCount$freq) * 100
	employmentCount$percentage <- round(employmentCount$percentage,2)
	employmentCount <- employmentCount[order(-employmentCount$percentage),]
	return(employmentCount)
}

getEmploymentStatusCount <- function(enrolmentData){
	enrolments <- enrolmentData
	status <- as.character(enrolments$employment_status)
	status <- status[status!="Unknown"]
	statusCount <- count(status)
	names(statusCount)[names(statusCount)=="x"] <- "status"
	statusCount$percentage <- statusCount$freq / sum(statusCount$freq) * 100
	statusCount$percentage <- round(statusCount$percentage,2)
	statusCount <- statusCount[order(-statusCount$percentage),]
	return(statusCount)
}

getEmploymentDegreeCount <- function(enrolmentData){
  enrolments <- enrolmentData
  status <- as.character(enrolments$highest_education_level)
  status <- status[status!="Unknown"]
  statusCount <- count(status)
  names(statusCount)[names(statusCount)=="x"] <- "degree"
  statusCount$percentage <- statusCount$freq / sum(statusCount$freq) * 100
  statusCount$percentage <- round(statusCount$percentage,2)
  return(statusCount)
}

getCommentViewerData <- function(commentData, run){
	data <- commentData[[which(names(commentData) == run)]]
	data$timestamp <- as.Date(substr(as.character(data$timestamp), start = 1, stop = 10))
	data$week_step <- getWeekStep(data)
	isReply <- unlist(lapply(data$parent_id, function(x) !is.na(x)))
	hasReply <- unlist(lapply(data$id, function(x) x %in% data$parent_id))
	data$thread <- unlist(lapply(Reduce('|', list(isReply,hasReply)), function(x) if(x){"Yes"} else {"No"}))
	data$likes <- as.numeric(data$likes)
	sorted <- data[order(-data$likes),]
	return(sorted)
}

getSurveyResponsesFromFullyParticipating <- function(enrolmentData){
	responses <- enrolmentData[which(enrolmentData$fully_participated_at != ""),]
	responses <- responses[which(responses$gender != "Unknown" | responses$country != "Unknown" | responses$age_range != "Unknown" | responses$highest_education_level != "Unknown" | responses$employment_status != "Unknown" | responses$employment_area != "Unknown"),]
	return(responses)
}

getSurveyResponsesFromStatementBuyers <- function(enrolmentData){
	responses <- enrolmentData[which(enrolmentData$purchased_statement_at != ""),]
	responses <- responses[which(responses$gender != "Unknown" | responses$country != "Unknown" | responses$age_range != "Unknown" | responses$highest_education_level != "Unknown" | responses$employment_status != "Unknown" | responses$employment_area != "Unknown"),]
	return(responses)
}

getAllvsFPvsStateData <-function(all, fp, state){
	allCount <- count(all)
	allCount$percentage <- allCount$freq / sum(allCount$freq) * 100
	allCount$percentage <- round(allCount$percentage,2)
	allCount <- allCount[,c("x","percentage")]

	fpCount <- count(fp)
	fpCount$percentage <- fpCount$freq / sum(fpCount$freq) * 100
	fpCount$percentage <- round(fpCount$percentage,2)
	fpCount <- fpCount[,c("x","percentage")]

	stateCount <- count(state)
	stateCount$percentage <- stateCount$freq / sum(stateCount$freq) * 100
	stateCount$percentage <- round(stateCount$percentage,2)
	stateCount <- stateCount[,c("x","percentage")]

	levels <- unique(allCount$x)
	data <- data.frame(x = levels, Overall = integer(length = length(levels)), FullyParticipating = integer(length = length(levels)), StatementsSold = integer(length = length(levels)))
	
	for(i in c(1:length(allCount$percentage))){
	  data[data$x == allCount$x[i],]$Overall <- allCount$percentage[i]
	}

	for(i in c(1:length(fpCount$percentage))){
		data[data$x == fpCount$x[i],]$FullyParticipating <- fpCount$percentage[i]
	}

	for(i in c(1:length(stateCount$percentage))){
		data[data$x == stateCount$x[i],]$StatementsSold <- stateCount$percentage[i] 
	}

	data <- data[order(-data$Overall),]
	return(data)
}

countryCodesToHDI <- function(countryCodes){
  table <- data.frame(code = unlist(strsplit(
    "AF,AL,DZ,AD,AO,AG,AR,AM,AU,AT,AZ,BS,BH,BD,BB,BY,BE,BZ,BJ,BT,BO,BA,BW,BR,BN,BG,BF,BI,KH,CM,CA,CV,CF,TD,CL,CN,CO,KM,CG,CD,CR,HR,CU,CY,CZ,DK,DJ,DM,DO,EC,EG,SV,GQ,ER,EE,ET,FJ,FI,FR,GA,GM,GE,DE,GH,GR,GD,GT,GN,GW,GY,HT,HN,HK,HU,IS,IN,ID,IR,IQ,IE,IL,IT,JM,JP,JO,KZ,KE,KI,KR,KW,KG,LA,LV,LB,LS,LR,LY,LI,LT,LU,MK,MG,MW,MY,MV,ML,MT,MR,MU,MX,FM,MD,MN,ME,MA,MZ,MM,NA,NP,NL,NZ,NI,NE,NG,NO,OM,PK,PW,PS,PA,PG,PY,PE,PH,PL,PT,QA,RO,RU,RW,KN,LC,VC,WS,ST,SA,SN,RS,SC,SL,SG,SK,SI,SB,ZA,SS,ES,LK,SD,SR,SZ,SE,CH,SY,TJ,TZ,TH,TL,TG,TO,TT,TN,TR,TM,UG,UA,AE,GB,US,UY,UZ,VU,VE,VN,YE,ZM,ZW,JE,IM,GG,TW,BM,VI,XK,SO,PR,UM,CI,BV,RE,AQ,CW,TC,AN,AI,TV,FK,GS,MF,PF,KY,NU,GI,YT",
    split = ",")),
    hdi = unlist(strsplit(
      "Low,High,High,Very High,Low,High,Very High,High,Very High,Very High,High,High,Very High,Medium,High,High,Very High,High,Low,Medium,Medium,High,Medium,High,Very High,High,Low,Low,Medium,Low,Very High,Medium,Low,Low,Very High,High,High,Low,Medium,Low,High,Very High,High,Very High,Very High,Very High,Low,High,High,High,Medium,Medium,Medium,Low,Very High,Low,High,Very High,Very High,Medium,Low,High,Very High,Medium,Very High,High,Medium,Low,Low,Medium,Low,Medium,Very High,Very High,Very High,Medium,Medium,High,Medium,Very High,Very High,Very High,High,Very High,High,High,Low,Medium,Very High,Very High,Medium,Medium,Very High,High,Low,Low,High,Very High,Very High,Very High,High,Low,Low,High,High,Low,Very High,Low,High,High,Medium,Medium,High,Very High,Medium,Low,Low,Medium,Low,Very High,Very High,Medium,Low,Low,Very High,High,Low,High,Medium,High,Low,Medium,High,Medium,Very High,Very High,Very High,High,High,Low,High,High,High,High,Medium,Very High,Low,High,High,Low,Very High,Very High,Very High,Low,Medium,Low,Very High,High,Low,High,Low,Very High,Very High,Medium,Medium,Low,High,Medium,Low,High,High,High,High,Medium,Low,High,Very High,Very High,Very High,High,Medium,Medium,High,Medium,Low,Medium,Low,Very High,Very High,Very High,Very High,Very High,Very High,High,Low,Very High,Very High,Low,Very High,High,Very High,Very High,High,Very High,High,Medium,Very High,Very High,Very High,High,Very High,Medium,Very High,High",
      split = ",")))
  
  table$code <- as.character(table$code)
  table$hdi <- as.character(table$hdi)
  
  hdi <- character(length = length(countryCodes))
  for(i in c(1:length(countryCodes))){
    hdi[i] <- table[countryCodes[i] == table$code,]$hdi
  }
  return(hdi)
}