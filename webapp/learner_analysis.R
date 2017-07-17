library(reshape2)
library(RMySQL)
library(xts)
library(networkD3)

# Unused function that used to take a csv filename and return the data.
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

# Takes data with week numbers and step numbers, and returns a vector of the weeks and steps concatenated together.
# Fixes the issue of steps 1.1 and 1.10 being equivalent when they're not.
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
getEnrolmentCount <- function (data) {
	data$enrolled_at <- as.POSIXct(data$enrolled_at, format = "%Y-%m-%d", tz = "GMT")
	data <- subset(data, enrolled_at >= as.POSIXct(startDate, format = "%Y-%m-%d", tz = "GMT"))
	data <- subset(data, enrolled_at <= as.POSIXct(endDate, format = "%Y-%m-%d", tz = "GMT"))
	learners <- as.vector(data$learner_id)
	# count <- length(learners)
	return (count)
}

getEnrolmentByDateTime <- function (data) {
	data$enrolled_at <- as.POSIXct(data$enrolled_at, format = "%Y-%m-%d %H", tz= "GMT")
	data$unenrolled_at <- as.POSIXct(data$unenrolled_at, format = "%Y-%m-%d %H", tz= "GMT")
	# data <- subset(data, learner_id %in% learners)
	# data <- subset(data, enrolled_at >= as.POSIXct(startDate))
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
getCompletionCount <- function (data) {
	completedCourse <- getStepsCompleted(data)
	completedCourse <- subset(completedCourse, completed >= 95)
	count <- nrow(completedCourse)
	return (count)
}


#for each learner in the parameter get the total number of comments made
getNumberOfCommentsByLearner <- function (data){
	data$timestamp <- as.Date(data$timestamp, format = "%Y-%m-%d")
#   data <- subset(data, timestamp >= startDate)
#   data <- subset(data, timestamp <= endDate)
	# data <- subset(data, author_id %in% learners)
	mdata <- melt(data, id = c("author_id", "step"))
	mdata <- subset(mdata, variable == "id")
	pivot <- dcast(mdata, author_id ~ ., length)
	colnames(pivot) <- c("learner_id","comments")
	return (pivot)
}

#gets the number of comments by step made by the specified learners
getNumberOfCommentsByStep <- function (data){
	data$timestamp <- as.POSIXct(data$timestamp, format = "%Y-%m-%d %H", tz= "GMT")
	#data <- subset(data, timestamp >= as.POSIXct(startDate, format = "%Y-%m-%d", tz = "GMT"))
	#data <- subset(data, timestamp <= as.POSIXct(endDate, format = "%Y-%m-%d", tz = "GMT"))
	# data <- subset(data, author_id %in% learners)
	mdata <- melt(data, id = c("author_id", "step"))
	mdata <- subset(mdata, variable == "id")
	pivot <- dcast(mdata, step ~ ., length)
	colnames(pivot)[2] <- "comments"
	return (pivot)
}

#date-time series of comments made by the specified learners
getNumberOfCommentsByDate <- function (data){
	mdata <- melt(data, id = c("author_id", "id"))
	mdata <- subset(mdata, variable == "timestamp")
	mdata$value <- as.POSIXct(mdata$value, format = "%Y-%m-%d %H", tz = "GMT")
	#mdata <- subset(mdata, value >= as.POSIXct(startDate, format = "%Y-%m-%d", tz = "GMT"))
	#mdata <- subset(mdata, value <= as.POSIXct(endDate, format = "%Y-%m-%d", tz = "GMT"))
	# mdata <- subset(mdata, author_id %in% learners)
	pivot <- dcast(mdata, value ~ ., length)
	colnames(pivot) <- c("timestamp", "comments")
	return (pivot) 
}

#gets the number of comments by step and date made by the specified learner
#the form of the table is ready for conversion to a matrix
getNumberOfCommentsByDateStep <- function (data){
	data$timestamp <- as.POSIXct(data$timestamp, format = "%Y-%m-%d")
	#data <- subset(data, timestamp >= as.POSIXct(startDate, format = "%Y-%m-%d", tz = "GMT"))
	#data <- subset(data, timestamp <= as.POSIXct(endDate, format = "%Y-%m-%d", tz = "GMT"))
	# data <- subset(data, author_id %in% learners)
	mdata <- melt(data, id = c("author_id", "step", "timestamp"))
	mdata <- subset(mdata, variable == "id")
	pivot <- dcast(mdata, timestamp ~ step, length)
	pivot[,1] <- as.numeric(pivot[,1])
	pivot[,2:length(pivot)] <- apply(pivot[,2:length(pivot)], c(1, 2), function (x) as.numeric(as.character(x)))
	return (pivot)
}


#gets the number of replies by date received by the specified learners
getNumberOfRepliesByDate <- function (data){
	data$timestamp <- as.POSIXct(data$timestamp, format = "%Y-%m-%d %H", tz = "GMT")
	#data <- subset(data, timestamp >= as.POSIXct(startDate, format = "%Y-%m-%d", tz = "GMT"))
	#data <- subset(data, timestamp <= as.POSIXct(endDate, format = "%Y-%m-%d", tz = "GMT"))
	# data <- subset(data, author_id %in% learners)
	mdata <- melt(data, id = c("timestamp", "author_id", "id"), na.rm = TRUE)
	mdata <- subset(mdata, variable == "parent_id")
	pivot <- dcast(mdata, timestamp + variable ~ ., length)
	colnames(pivot)[3] <- "replies"
	return (pivot[c("timestamp", "replies")])
}

#gets the number of replies by step received by the specified learners
getNumberOfRepliesByStep <- function (data){
	data$timestamp <- as.POSIXct(data$timestamp, format = "%Y-%m-%d %H", tz = "GMT")
	#data <- subset(data, timestamp >= as.POSIXct(startDate, format = "%Y-%m-%d", tz = "GMT"))
	#data <- subset(data, timestamp <= as.POSIXct(endDate, format = "%Y-%m-%d", tz = "GMT"))
	# data <- subset(data, author_id %in% learners)
	mdata <- melt(data, id = c("step", "author_id", "id"), na.rm = TRUE)
	mdata <- subset(mdata, variable == "parent_id")
	pivot <- dcast(mdata, step + variable ~ ., length)
	colnames(pivot)[3] <- "replies"
	return (pivot[c("step", "replies")])
}

#for each specified learner find the number of replies he has received
getNumberOfRepliesByLearner <- function (data){
	data$timestamp <- as.POSIXct(data$timestamp, format = "%Y-%m-%d %H", tz = "GMT")
	#data <- subset(data, timestamp >= as.POSIXct(startDate, format = "%Y-%m-%d", tz = "GMT"))
	#data <- subset(data, timestamp <= as.POSIXct(endDate, format = "%Y-%m-%d", tz = "GMT"))
	# data <- subset(data, author_id %in% learners)
	mdata <- melt(data, id = c("step", "author_id", "id"), na.rm = TRUE)
	mdata <- subset(mdata, variable == "parent_id")
	pivot <- dcast(mdata, author_id + variable ~ ., length)
	colnames(pivot) <- c("learner_id", "", "replies")
	return (pivot[c("learner_id", "replies")])
}

#gets the number of likes by step received by the specified learners
getNumberOfLikesByStep <- function (data){
	data$timestamp <- as.POSIXct(data$timestamp, format = "%Y-%m-%d %H", tz = "GMT")
	#data <- subset(data, timestamp >= as.POSIXct(startDate, format = "%Y-%m-%d", tz = "GMT"))
	#data <- subset(data, timestamp <= as.POSIXct(endDate, format = "%Y-%m-%d", tz = "GMT"))
	# data <- subset(data, author_id %in% learners)
	mdata <- melt(data, id = c("author_id", "step"))
	mdata <- subset(mdata, variable == "likes")
	mdata$value <- as.numeric(mdata$value)
	pivot <- dcast(mdata, step + variable ~ ., sum)
	colnames(pivot)[3] <- "likes"
	return (pivot[c("step", "likes")])
}

#gets the number of likes by date received by the specified learners
getNumberOfLikesByDate <- function (data){
	data$timestamp <- as.POSIXct(data$timestamp, format = "%Y-%m-%d %H", tz = "GMT")
 # data <- subset(data, timestamp >= as.POSIXct(startDate, format = "%Y-%m-%d", tz = "GMT"))
 # data <- subset(data, timestamp <= as.POSIXct(endDate, format = "%Y-%m-%d", tz = "GMT"))
	# data <- subset(data, author_id %in% learners)
	mdata <- melt(data, id = c("author_id", "timestamp"))
	mdata <- subset(mdata, variable == "likes")
	mdata$value <- as.numeric(mdata$value)
	pivot <- dcast(mdata, timestamp + variable ~ ., sum)
	colnames(pivot)[3] <- "likes"
	return (pivot[c("timestamp", "likes")])
}

getNumberOfLikesByLearner <- function (data) {
	# data <- subset(data, author_id %in% learners)
	mdata <- melt(data, id = c("author_id"))
	mdata <- subset(mdata, variable == "likes")
	mdata$value <- as.numeric(mdata$value)
	pivot <- dcast(mdata, author_id + variable ~ ., sum)
	colnames(pivot)[c(1, 3)] <- c("learner_id", "likes")
	return (pivot[c("learner_id", "likes")])
}

#gets the number of comment authors by date


#returns time of enrolment and unenrolment of the specified learners
getEnrolmentTime <- function (data){
	# enrolment <- subset(data, learner_id %in% learners)
	enrolment$enrolled_at <- as.POSIXct(data$enrolled_at, format = "%Y-%m-%d %H", tz= "GMT")
	#enrolment <- subset(enrolment, value >= as.POSIXct(startDate))
	return (enrolment)
}

#date-time series of quiz answers submitted by the specified learners
getNumberOfResponsesByDateTime <- function (data){
	
	mdata <- melt(data, id = c("learner_id", "quiz_question"))
	mdata <- subset(mdata, variable == "submitted_at")
	mdata$value <- as.POSIXct(mdata$value, format = "%Y-%m-%d %H", tz= "GMT")
	
	#HERE
	
	print(paste("getNumberOfResponsesByDateTime Start date: ",startDate))
	print(paste("getNumberOfResponsesByDateTime End date: ",endDate))
	
	
	mdata <- subset(mdata, value >= as.POSIXct(startDate))
	
	
	
	pivot <- dcast(mdata, value + learner_id ~ ., length)
	colnames(pivot)[c(1,3)] <- c("timestamp", "submits")
	# count <- subset(pivot, learner_id %in% learners)
	count <- ddply(count, ~timestamp, summarise, submits = sum(submits))
	return (count[c("timestamp", "submits")])
}

getNumberOfResponsesByLearner <- function (data){
	# data <- subset(data, learner_id %in% learners)
	mdata <- melt(data, id = c("learner_id"))
	mdata <- subset(mdata, variable == "quiz_question")
	pivot <- dcast(mdata, learner_id  ~ ., length)
	colnames(pivot)[2] <- "submits"
	return (pivot)
}

getPercentageOfAnsweredQuestions <- function (data) {
	questions <- as.vector(unique(data$quiz_question))
	# mdata <- melt(data, id = c("learner_id"))
	mdata <- subset(mdata, variable == "quiz_question")
	mdata<- unique(mdata)
	pivot <- dcast(mdata, learner_id ~ ., length)
	colnames(pivot)[2] <- "answers"
	pivot$completion <- (pivot$answers / length(questions)) * 100
	return (pivot[c("learner_id", "completion")])
}

#gets the percentage of correct and wrong answers for the specified learners
getResponsesPercentage <- function (data){
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
	# percentage <- subset(finalPivot, learner_id %in% learners)
	return (percentage[c("learner_id", "correct", "wrong")])
}

#for each step and date-time, gets the number of students who have visited and completed it
getStepActivity <- function(data){
	# data <- subset(data, learner_id %in% learners)
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
getStepsCompleted <- function (data){
	step_levels <- as.vector(unique(data$step))
	# data <- subset(data, learner_id %in% learners)  
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

#' Filters out step data that is not completed with week step.
#'
#' @param stepData data frame of activity data for a specific course run
#'
#' @return a data frame which shows how many times each step was completed
getStepsCompletedData <- function(stepData){
	data <- stepData
	completedSteps <- subset(data, last_completed_at != "")
	completedSteps$week_step <- getWeekStep(completedSteps)
	
	#counts how many times each step was completed
	stepsCount <- count(completedSteps, 'week_step')

	return (stepsCount)
}

#' Gets the number of times each step was first visited for rendering the chart
#'
#' @param stepData a data frame with activity information about a specified course run
#'
#' @returna data frame which shows how many times each step was first visited
getStepsFirstVistedData <- function(stepData){
	data <- stepData
	firstVisitedSteps <- subset(data, first_visited_at != "")
	firstVisitedSteps$week_step <- getWeekStep(firstVisitedSteps)
	
	#counts how many times each step has been first visited
	stepsCount <- count(firstVisitedSteps, 'week_step')
	return (stepsCount)
}

# Returns the heat map of step completion, requires step data and the start date of the run
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


#' Returns the heat map of first visited steps, requires step data and the start date of the run
#'
#' @param stepData data frame with activity data for the selected course run
#' @param startDate start date of the course run
#'
#' @return data frame with data: date vs steps, for the heat map
getFirstVisitedHeatMap <- function(stepData, startDate){
	data <-stepData
	
	data$week_step <- getWeekStep(data)
	  
	#it gets all the rows for the written columns
	data <- data[,c("week_step", "first_visited_at")]
	  
	#gets only the dates from the date-time column
	data$first_visited_at <- unlist(lapply(data$first_visited_at, function(x) substr(x,1,10)))
	  
	#count column with value 1 for each row 
	data$count <- 1
	  
	#applies the sum function to all count value for the step and date data
	aggregateData <- aggregate(count ~., data, FUN = sum)
	aggregateData <- subset(aggregateData , as.numeric(gsub("-","",aggregateData$first_visited_at)) >= startDate)
	  
	#casting formula - creates a data frame with the date column and a column for each step
	pivot <- dcast(aggregateData, first_visited_at ~ week_step)
	pivot[is.na(pivot)] <- 0
	  
	map <- as.data.frame(pivot)
	  
	return(map)
}

# Returns the comments heat map, requires comments data and the start date of the run
getCommentsHeatMap <- function(commentsData, startDate){
	data <- commentsData
	data$week_step <- getWeekStep(data)
	data <- data[,c("week_step", "timestamp")]
	data$timestamp <- unlist(lapply(data$timestamp, function(x) substr(x,1,10)))
	data$count <- 1
	aggregateData <- aggregate(count ~., data, FUN = sum)
	aggregateData <- subset(aggregateData , as.numeric(gsub("-","",aggregateData$timestamp)) >= startDate)
	pivot <- dcast(aggregateData, timestamp ~ week_step)
	pivot[is.na(pivot)] <- 0
	map <- as.data.frame(pivot)
	return(map)
}

#' Returns the plot data for comments per step, requires step data and comment data.
#'
#' @param stepData data frame with activity data for the selected course run
#' @param comments data frame with comment data
#'
#' @return a data frame with the numbers of posts and replies by step
getCommentsBarChart <- function(stepData,comments){
  
  #making compies of the data frames
	steps <- stepData
	data <- comments
	stepLevels <- unique(getWeekStep(steps))
	
	#creating a data frame for the plot data: step, post and reply
	plotData <-data.frame(week_step = stepLevels, post = integer(length = length(stepLevels)), reply = integer(length = length(stepLevels)),stringsAsFactors = FALSE)
	data$week_step <- getWeekStep(data)
	
	#isolating the required data
	data <- data[,c("week_step", "parent_id")]
	
	#creating the posts(no parent id) and replies(parent id) and counting them
	posts <- subset(data, is.na(data$parent_id))
	replies <- subset(data, !is.na(data$parent_id))[,c("week_step")]
	postCount <- count(posts)
	replyCount <- count(replies)
	replyCount$week_step <- as.character(replyCount$x)
	
	#counting the number ofposts and replies by week step
	for(x in c(1:length(postCount$freq))){
		plotData[plotData$week_step == postCount$week_step[x],]$post <- postCount$freq[x]
	}
	for(x in c(1:length(replyCount$freq))){
		plotData[plotData$week_step == replyCount$week_step[x],]$reply <- replyCount$freq[x]
	}
	return(plotData)
}

#' Returns the plot data for comments per week, just requires the comments data.
#'
#' @param comments data frame with comment data for the current course run
#'
#' @return data frame with week number, post and reply data
getCommentsBarChartWeek <- function(comments){
	data <- comments
	stepLevels <- unique(data$week_number)
	
	#creating a data frame for the plot data: week, post, reply
	plotData <-data.frame(week_number = stepLevels, post = integer(length = length(stepLevels)), reply = integer(length = length(stepLevels)),stringsAsFactors = FALSE)
	
	#isolates the required data
	data <- data[,c("week_number", "parent_id")]
	
	#creating the posts(no parent id) and replies(parent id) and counting them
	posts <- subset(data, is.na(data$parent_id))
	replies <- subset(data, !is.na(data$parent_id))[,c("week_number")]
	postCount <- count(posts)
	replyCount <- count(replies)
	replyCount$week_number <- as.character(replyCount$x)
	
	#counting the number ofposts and replies by week
	for(x in c(1:length(postCount$freq))){
		plotData[plotData$week_number == postCount$week_number[x],]$post <- postCount$freq[x]
	}
	for(x in c(1:length(replyCount$freq))){
		plotData[plotData$week_number == replyCount$week_number[x],]$reply <- replyCount$freq[x]
	}
	return(plotData)
}

#Returns the plot data for number of authors per week, requires the comments data.
getNumberOfAuthorsByWeek <- function (comments){
  data <- comments
  stepLevels <- sort(unique(data$week_number))
  plotData <-data.frame(week_number = stepLevels, authors = integer(length = length(stepLevels)),stringsAsFactors = FALSE)
  for(x in c(1:max(length(stepLevels)))){
    weekComments <- data[which(data$week_number == x),c("week_number","author_id")]
    authorCount <- count(unique(weekComments)$week_number)
    plotData[plotData$week_number == authorCount$x,]$authors <- authorCount$freq
  }
  return(plotData)
}

#' Takes enrolment data and returns counts and percentages for each gender.
#'
#' @param enrolmentData data frame with information about enrolments
#'
#' @return data frame with gender groups, counts and percentages
getGenderCount <- function(enrolmentData){
	data <- enrolmentData
	
	#transforming gender into a vector of characters and removing the Unknown values
	gender <- as.character(data$gender)
	gender <- gender[gender!="Unknown"]
	
	#making a dataframe with the gender values and their frequencies
	genderCount <- count(gender)
	genderCount <- genderCount[order(-genderCount$freq),]
	
	#changing the column name to gender
	names(genderCount)[names(genderCount)=="x"] <- "gender"
	
	#creating a percentage column in the data frame for the genders
	genderCount$percentage <- genderCount$freq / sum(genderCount$freq) * 100
	genderCount$percentage <- round(genderCount$percentage,2)
	return(genderCount)
}

#' Takes enrolment data and returns counts and percentages for each age group
#'
#' @param enrolmentData data frame with information about enrolments in a specified course run
#'
#' @return a data frame with age group, counts and percentages
getLearnerAgeCount <- function(enrolmentData){
	data <- enrolmentData
	
	#transforming age into a vector of characters and removing the Unknown values
	age <- as.character(data$age_range)
	age <- age[age!="Unknown"]
	
	#making a dataframe with the age groups and their frequencies
	ageCount <- count(age)
	ageCount <- ageCount[order(-ageCount$freq),]
	
	#changing the column name to age_group
	names(ageCount)[names(ageCount)=="x"] <- "age_group"
	
	#creating a percentages column for the age groups
	ageCount$percentage <- ageCount$freq / sum(ageCount$freq) * 100
	ageCount$percentage <- round(ageCount$percentage,2)
	return(ageCount)
}


#' Takes enrolment data and returns counts and percentages for each employment area.
#'
#' @param enrolmentData data frame with information about enrolments in a specified course run
#'
#' @return data frame with employment areas, counts and percentages
getEmploymentAreaCount <- function(enrolmentData){
	enrolments <- enrolmentData
	
	#vector of characters without Unknown values
	employment <- as.character(enrolments$employment_area)
	employment <- employment[employment!="Unknown"]
	
	#making a dataframe with the employment areas and their frequencies
	employmentCount <- count(employment)
	
	#changing the column name to 'employment'
	names(employmentCount)[names(employmentCount)=="x"] <- "employment"
	
	#creating a percentages column for the employment areas 
	employmentCount$percentage <- employmentCount$freq / sum(employmentCount$freq) * 100
	employmentCount$percentage <- round(employmentCount$percentage,2)
	
	#ordering the data frame in decreasing order
	employmentCount <- employmentCount[order(-employmentCount$percentage),]
	return(employmentCount)
}

#' Takes enrolments data and returns counts/percentages for each employment status.
#'
#' @param enrolmentData data frame with information about enrolments for a specific course run
#'
#' @return a data frame with 3 columns: status, count and percentage
getEmploymentStatusCount <- function(enrolmentData){
	enrolments <- enrolmentData
	
	#vector of all status values without Unknown values
	status <- as.character(enrolments$employment_status)
	status <- status[status!="Unknown"]
	
	#creating a data frame with the count value of each status
	statusCount <- count(status)
	
	#renaming the column x created above with 'status'
	names(statusCount)[names(statusCount)=="x"] <- "status"
	
	#creating a percentage column 
	statusCount$percentage <- statusCount$freq / sum(statusCount$freq) * 100
	statusCount$percentage <- round(statusCount$percentage,2)
	
	#ordering the data frame values in decreasing order by percentage
	statusCount <- statusCount[order(-statusCount$percentage),]
	return(statusCount)
}

#' Takes enrolment data and returns counts/percentages for each education level.
#'
#' @param enrolmentData data frame with information about enrolments for a specific course run
#'
#' @return a data frame with 3 columns: degree, count and percentage
getEmploymentDegreeCount <- function(enrolmentData){
  enrolments <- enrolmentData
  
  #vector of all degree values without Unknown values
  status <- as.character(enrolments$highest_education_level)
  status <- status[status!="Unknown"]
  
  #creating a data frame with the count value of each degree status
  statusCount <- count(status)
  
  #renaming the x column created above to 'degree'
  names(statusCount)[names(statusCount)=="x"] <- "degree"
  
  #creating a percentage column
  statusCount$percentage <- statusCount$freq / sum(statusCount$freq) * 100
  statusCount$percentage <- round(statusCount$percentage,2)
  return(statusCount)
}

#' Used to get comment data for the comment viewer
#'
#' @param commentData list of data frames that contain comment data for the chosen courses and runs 
#' @param run the chosen run for which to return comment data
#' @param courseMetaData all sort of information about the course
#'
#' @return Returns comment data in the format needed for the comment viewer
getCommentViewerData <- function(commentData, run, courseMetaData){
  
  #gets the data frame from the list corresponding to the course run
	comments <- commentData[[which(names(commentData) == run)]]
	
  #if the data frame is not empty 
	if(nrow(comments)!=0) {
	  #modify the timestamp column to contain just the date
	  comments$timestamp <- as.Date(substr(as.character(comments$timestamp), start = 1, stop = 10))
	  print(run)
	  
	  #activity steps under a specific form e.g. 1.3
	  comments$week_step <- getWeekStep(comments)
	  
	  isReply <- unlist(lapply(comments$parent_id, function(x) !is.na(x)))
	  hasReply <- unlist(lapply(comments$id, function(x) x %in% comments$parent_id))
	  comments$thread <- unlist(lapply(Reduce('|', list(isReply,hasReply)), function(x) if(x){"Yes"} else {"No"}))
	  comments$likes <- as.numeric(comments$likes)
	  comments$likes <- as.integer(comments$likes)
	  
	  #to build the url 
	  #splits the run name by '-' to separate the name of course and run number
	  runsplit <- strsplit(run,"-")
	  
	  #trims the leading and trailing whitespaces to get the correct name of the course
	  course <- trimws(runsplit[[1]])
	  
	  #based on the name of the course it get the shorten name with the run number
	  courseRun <- as.character(courseMetaData$course_run[courseMetaData$course == course[1]])[1]
	  
	  #gets the short name of the course 
	  shortenedCourse <- (strsplit(courseRun, "\\s"))[[1]][1]
	  
	  #creates the url and adds it to each row in the data frame
	  url <- paste0("https://www.futurelearn.com/courses/",shortenedCourse,"/",trimws(course[[2]]),"/comments/")
	  comments$url <- paste0("<a href='",url,comments$id,"'target='_blank'>link</a>")
	  
	  #sorting the comments in decreasing order by the number of likes
	  comments <- comments[order(-comments$likes),]
	  
	  # starts comments categorisation script
	  #parentgroup : to group the initiating post and replies together, for conversation id
	  comments$parent_id[is.na(comments$parent_id)]<-0 # change the na shown in the csv to 0 so the next two lines could work
	  comments$parent_group<-comments$parent_id
	  comments$parent_group[comments$parent_id==0]<-comments$id[comments$parent_id==0]
	  
	  #change author id in the file to learner_id
	  colnames(comments)[2]<-"learner_id"
	  
	  #order id within a parent group, initiating post =0
	  comments$order<-0
	  
	  #number of initiating post (still include lonepost which continue to replies
	  l=length(unique(comments$parent_group[comments$parent_id!=0])) #initiating post
	  
	  #make all non post to replies first
	  comments$nature[comments$parent_id!=0]<-" first reply"
	  
	  # add the column to put in the initiator's learner_id a user replies to 
	  comments$repliestowhom<-0
	  
	  # add the column to count the number of replies a new post/replies received.
	  comments$replies<-0
	  
	  for (i in 1:l){
	    parent_id<-(unique(comments$parent_group[comments$parent_id!=0]))[i]
	    initiator_id<-comments$learner_id[comments$id==parent_id] 	
	    comments$repliestowhom[comments$parent_id==parent_id]<-initiator_id  #fill in the replies to whom in replies postings
	    
	    #fill in number of replies a post/replies received and their order within an initiating post
	    n=nrow(comments[comments$parent_group==parent_id,]) #n=the sum of initiating post and replies it receives
	    comments$replies[comments$parent_group==parent_id]<-seq((n-1),0,by=(-1)) #how many replies after the current comment, so initiating post receives n-1 reply, 1st reply receives n-2 reply,last reply receives 0 reply 
	    comments$order[comments$parent_group==parent_id]<-seq(0,(n-1),by=1) #initiating post=0, 1st reply=1, 2nd reply=2, 3rd reply=3...
	    
	    
	    if (length(unique(comments$learner_id[comments$parent_group==parent_id]))==1){ # to determine if all the replies under an initiating post come from the initiators, so they are all lone posts		
	      comments$nature[comments$parent_group==parent_id]<-"lone post"
	      comments$replies[comments$parent_group==parent_id]<-0
	      comments$order[comments$parent_group==parent_id]<-0
	      
	    } else {
	      
	      
	      #analyzing further replies and calculate selfreplies for first instance,i.e.,replies
	      #comments line by line analysis
	      for (j in (n-1):1){ # line by line analysis of the replies
	        learner_id<-comments$learner_id[comments$order==j & (comments$parent_group==parent_id)]
	        if (length(grep(learner_id,comments$learner_id[(comments$order>0 & comments$order<j & comments$parent_group==parent_id)])>0)){
	          comments$nature[comments$order==j & comments$parent_group==parent_id]<-"further reply"
	          
	        } 
	        
	      }#j
	    }#if
	    
	    
	  }
	  
	  comments$nature[comments$repliestowhom==comments$learner_id & comments$parent_id!=0 & comments$order!=0]<-"initiator's reply"
	  comments$nature[(comments$replies==0 & comments$parent_id==0)]<-"lone post"
	  comments$nature[(comments$replies!=0 & comments$parent_id==0)]<-"initiating post"
	  #finished comment categorisation script
	} else {
	  #if the data frame is empty (no data for a specific course run)
	  #adding new empty columns for the table
	  comments$week_step <- character()
	  comments$thread <- character()
	  comments$url <- character()
	  comments$nature <- character()
	}
  
	return(comments)
}


#' To get data about team interactions with the platform: name, date, step, comment, link
#'
#' @param teamData a data frame with data about team members
#' @param commentData a list of data frames
#' @param run the course run
#' @param courseMetaData specific information about the courses
#'
#' @return a data frame about team interactions with the platform
getTeamMembersData <- function (teamData, commentData, run, courseMetaData){
  
  #gets the data frame from the list; corresponding to the course run
  commentDataRun <- commentData[[which(names(commentData) == run)]]
  
  #merge the data frames based on the user id
  data <- merge (commentDataRun, teamData,  by.x = "author_id", by.y = "id")
  
  #if the data frame is not empty
  if (nrow(data)!=0) {
    #creating a name column that contains the first and last name of team members
    data$name <- paste(data$first_name, data$last_name, sep = " ")
    
    #modify the timestamp column to contain just the date
    data$timestamp <- as.Date(substr(as.character(data$timestamp), start = 1, stop = 10))
    
    #activity steps under a specific form e.g. 1.3
    data$week_step <- getWeekStep(data)
    
    #splits the run name by '-' to separate the name of course and run number
    runsplit <- strsplit(run,"-")
    
    #trims the leading and trailing whitespaces to get the correct name of the course
    course <- trimws(runsplit[[1]])
    
    #based on the name of the course it get the shorten name with the run number
    courseRun <- as.character(courseMetaData$course_run[courseMetaData$course == course[1]])[1]
    
    #gets the short name of the course 
    shortenedCourse <- (strsplit(courseRun, "\\s"))[[1]][1]
    
    #creates the url and adds it to each row in the data frame
    url <- paste0("https://www.futurelearn.com/courses/",shortenedCourse,"/",trimws(course[[2]]),"/comments/")
    data$url <- paste0("<a href='",url,data$id,"'target='_blank'>link</a>")
    
    #sorting the data frame by the name of team members
    data <- data[order(data$name),]
  } else {
    
    #if the data frame is empty
    data$name <- character()
    data$url <- character()
    data$week_step <- character()
  }
  
  
  return(data)
}


getSurveyResponsesFromFullyParticipating <- function(enrolmentData){
	responses <- enrolmentData[which(enrolmentData$fully_participated_at != ""),]
	responses <- responses[which(responses$gender != "Unknown" | responses$country != "Unknown" | responses$age_range != "Unknown" | responses$highest_education_level != "Unknown" | responses$employment_status != "Unknown" | responses$employment_area != "Unknown"),]
	return(responses)
}

#' To get enrolment data about people who purchased a statement
#'
#' @param enrolmentData data frame with information about enrolments for a specific course run
#'
#' @return a data frame with information about people who purchased statements
getSurveyResponsesFromStatementBuyers <- function(enrolmentData){
  
  #gets the enrolment data for the people who purchased a statement
	responses <- enrolmentData[which(enrolmentData$purchased_statement_at != ""),]
	
	#removes the rows with unknown values
	responses <- responses[which(responses$gender != "Unknown" | responses$country != "Unknown" | responses$age_range != "Unknown" | responses$highest_education_level != "Unknown" | responses$employment_status != "Unknown" | responses$employment_area != "Unknown"),]
	return(responses)
}

# Unused, was used to count all data, fully participating data and statement sold data and present them together.
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

# Converts two letter country code data to the corresponding HDI level, has a hard coded dictionary.
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

#' For populating the learner age chart
#'
#' @param dataType the character value of the selected radio button
#'
#' @return a data frame with age group values for each course-run chosen
learnersAgeData <- function(dataType){
  
  #creating a data frame with one column - levels
	data <- data.frame(levels = c("<18","18-25","26-35","36-45","46-55","56-65",">65"))
	data$levels <- as.character(data$levels)
	
	#enrolment_data is a list of course-run data frames
	#goes through each course-run data frame in the list
	for(x in names(enrolment_data)){
	  
	  #creates a data frame containing 3 columns: age group, count and percentages for the current course-run in the loop
		ageCount <- getLearnerAgeCount(enrolment_data[[x]])
		
		#creates a new column with the title of the course run
		#initialised with 0s for each age group level
		data[[x]] <- numeric(7)
		
		#goes through each existing age group and updates the age group values of the course-run
		for(i in c(1:length(ageCount$age_group))){
		  if(dataType == "percentages"){
		    data[[x]][which(data$levels == ageCount$age_group[i])] <- ageCount$percentage[i]
		  } else {
		    data[[x]][which(data$levels == ageCount$age_group[i])] <- ageCount$freq[i]
		  }
		}
	}

	return(data)
}

#' For populating the gender chart
#'
#' @param dataType the character value of the selected radio button
#'
#' @return a data frame with gender count/percentages for each course-run chosen
learnersGenderData <- function(dataType){
  
  #creating a data frame with one column - levels
	data <- data.frame(levels = c("male","female","other","non-binary"))
	data$levels <- as.character(data$levels)

	#enrolment_data is a list of course-run data frames
	#goes through each course-run data frame in the list
	for(x in names(enrolment_data)){
	  
	  #creates a data frame containing 3 columns: gender, count and percentages for the current course run in the loop
		genderCount <- getGenderCount(enrolment_data[[x]])
		
		#creates a new column with the title of the course run
		#initialised with 0s for each gender level
		data[[x]] <- numeric(4)
		
		#goes through each existing gender and updates the gender values of the course-run
		for(i in c(1:length(genderCount$gender))){
		  if(dataType == "percentages"){
		    data[[x]][which(data$levels == genderCount$gender[i])] <- genderCount$percentage[i]
		  } else {
		    data[[x]][which(data$levels == genderCount$gender[i])] <- genderCount$freq[i]
		  }
		}
	}
	return(data)
}

#' For populating the employment area chart
#'
#' @param dataType the character value of the selected radio button
#'
#' @return a dataframe with employment area count/percentages for each selected course-run
learnersEmploymentData <- function(dataType){
  
  #creating a data frame with one column - area
	data <- data.frame(area = as.character(c("accountancy_banking_and_finance","armed_forces_and_emergency_services",
										 "business_consulting_and_management","charities_and_voluntary_work" ,"creative_arts_and_culture",
										 "energy_and_utilities","engineering_and_manufacturing","environment_and_agriculture","health_and_social_care",
										 "hospitality_tourism_and_sport","it_and_information_services","law","marketing_advertising_and_pr","media_and_publishing",               
										 "property_and_construction","public_sector","recruitment_and_pr","retail_and_sales",
										 "science_and_pharmaceuticals","teaching_and_education","transport_and_logistics")))
	data$area <- as.character(data$area)

	#enrolment_data is a list of course-run data frames
	#goes through each course-run data frame in the list
	for(x in names(enrolment_data)){
	  
	  #creates a data frame containing 3 columns: employment area, count and percentages for the current course run in the loop
	  areaCount <- getEmploymentAreaCount(enrolment_data[[x]])
	  
	  #creates a new column with the title of the course run
	  #initialises with 0s for each employment area
	  data[[x]] <- numeric(21)
	  
	  #goes through each employment area and updates the values of the course-run for that specific area
	  for(i in c(1:length(areaCount$employment))){
	    if(dataType == "percentages"){
	      data[[x]][which(data$area == areaCount$employment[i])] <- areaCount$percentage[i]
	    } else {
	      data[[x]][which(data$area == areaCount$employment[i])] <- areaCount$freq[i]
	    }
	  }
	}
	
	#ordering the area data in decreasing order of the values of the first course run
	data <- data[order(-data[[names(enrolment_data[1])]]),]
	return(data)
}

#' For populating the Status bar chart
#'
#' @param dataType the character value of the selected radio button
#'
#' @return a dataframe with status count/percentages for each selected course-run
learnersStatusData <- function(dataType){

  #creating a data frame with one column - levels
	data <- data.frame(levels = as.character(c("unemployed","working_full_time","working_part_time","retired",
		"not_working","full_time_student","self_employed","looking_for_work")))
	data$levels <- as.character(data$levels)
	
	#enrolment_data is a list of data frames of course runs
	#goes through each course run data frame
	for(x in names(enrolment_data)){
	  
	  #data frame with status-count-percentage about the current course run in the loop
		statusCount <- getEmploymentStatusCount(enrolment_data[[x]])
		
		#creates a new column with the name of the course run and initialises it with 0s
		data[[x]] <- numeric(8)
		
		#goes through each employment status and updates the values of the current course run
		for(i in c(1:length(statusCount$status))){
		  if(dataType == "percentages"){
		    data[[x]][which(data$levels == statusCount$status[i])] <- statusCount$percentage[i]
		  } else {
		    data[[x]][which(data$levels == statusCount$status[i])] <- statusCount$freq[i]
		  }
	  }
	}
	
	#ordering the status data in decreasing order of the values of the first course run
	data <- data[order(-data[[names(enrolment_data[1])]]),]
	return(data)	
}

#' For populating the degree bar chart
#'
#' @param dataType the character value of the selected radio button
#'
#' @return a dataframe with degree status count/percentages for each selected course-run
learnersEducationData <- function(dataType){
  
  #creates a data frame with one column - level
	data <- data.frame(level = c("apprenticeship","less_than_secondary","professional","secondary",           
		"tertiary","university_degree","university_masters","university_doctorate"))
	data$level <- as.character(data$level)

	#enrolment_data is a list with one data frame for each course_run
	#goes through each course run data frame
	for(x in names(enrolment_data)){
	  
	  #data frame with degree-count-percentage about the current course run in the loop
	  degreeCount <- getEmploymentDegreeCount(enrolment_data[[x]])
	  
	  #creates a new column with the title of the current course run and initialises it with 0s
	  data[[x]] <- numeric(8)
	  
	  #goes through each degree status and updates the values of the current course run
	  for(i in c(1:length(degreeCount$degree))){
	    if(dataType == "percentages"){
	      data[[x]][which(data$level == degreeCount$degree[i])] <- degreeCount$percentage[i]
	    } else {
	      data[[x]][which(data$level == degreeCount$degree[i])] <- degreeCount$freq[i]
	    }
	  }
	}
	return(data)
}

learnersHDIData <- function(){
	data <- data.frame(levels = c("Very High","High","Medium","Low"))

	for(x in names(enrolment_data)){
	  enrolments <- enrolment_data[[x]][which(enrolment_data[[x]]$country != "Unknown"), ]
	  countries<- as.character(enrolments$country)
	  hdilevels <- countryCodesToHDI(countries)
	  all <- as.factor(hdilevels)
	  allCount <- count(all)
	  allCount$percentage <- allCount$freq / sum(allCount$freq) * 100
	  allCount$percentage <- round(allCount$percentage,2)
	  allCount$x <- as.character(allCount$x)
	  allCount <- allCount[,c("x","percentage")]
	  allCount <- allCount[order(-allCount$percentage),]
	  data[[x]] <- numeric(4)
	  
	  for(i in c(1:length(allCount$x))){
		data[[x]][which(data$levels == allCount$x[i])] <- allCount$percentage[i]
	  }
	}
	return(data)
}


#' For creating the statement purchasers gender chart
#'
#' @param dataType the character value of the selected radio button
#'
#' @return a dataframe with gender count/percentages for each selected course-run
stateGenderData <- function(dataType){
  
  #creates a data frame wiith one columm - levels
	data <- data.frame(levels = c("male","female","other","non-binary"))
	data$levels <- as.character(data$levels)

	#enrolement_data is a list of data frames, one for each course run
	# goes through each course_run data frame
	for(x in names(enrolment_data)){
	  
	  #data frame with the enrolment information of the people who purchased statements
	  statementsSoldCount <- getSurveyResponsesFromStatementBuyers(enrolment_data[[x]])
	  
	  #data frame with gender-count-percentage data 
	  statementsSoldCount <- getGenderCount(statementsSoldCount)
	  
	  #creates a new column with the name of the current course run and initialises it with 0s
	  data[[x]] <- numeric(4)
	  
	  #goes through each gender option and updates the count/percentage values for the course run
	  for(i in c(1:length(statementsSoldCount$gender))){
	    if(dataType == "percentages"){
	      data[[x]][which(data$levels == statementsSoldCount$gender[i])] <- statementsSoldCount$percentage[i]
	    } else {
	      data[[x]][which(data$levels == statementsSoldCount$gender[i])] <- statementsSoldCount$freq[i]
	    }
	  }
	}

	#ordering the status data in decreasing order of the values of the first course run
	data <- data[order(-data[[names(enrolment_data[1])]]),]
	return(data)
}

#' To create the statement purchasers age chart
#'
#' @param dataType the character value of the selected radio button
#'
#' @return a data frame with age group count/percentage information about the selected course runs
stateAgeData <-function(dataType){
  
  #creates a data frame with one column initially - levels of age groups
	data <- data.frame(levels = c("<18","18-25","26-35","36-45","46-55","56-65",">65"))
	data$levels <- as.character(data$levels)
	
	#enrolment data is list of data frames, one for each course run
	#goes through all the course run data frames
	for(x in names(enrolment_data)){
	  
	  #data frame with  enrolment information about the statement purchasers in this course run
		ageCount <- getSurveyResponsesFromStatementBuyers(enrolment_data[[x]])
		
		#data frame has 3 columns: age-count-percentage
		ageCount <- getLearnerAgeCount(ageCount)
		
		#creates a column with the title of the course run and initialises it with 0s for each age group
		data[[x]] <- numeric(7)
		
		#goes through each age group and updates the information in the current course run
		for(i in c(1:length(ageCount$age_group))){
		  if(dataType == "percentages"){
		    data[[x]][which(data$levels == ageCount$age_group[i])] <- ageCount$percentage[i]
		  } else {
		    data[[x]][which(data$levels == ageCount$age_group[i])] <- ageCount$freq[i]
		  }
		}
	}
	return(data)
}

#' For creating the employment area chart for the statement buyers
#'
#' @param dataType the character value of the selected radio button
#'
#' @return a data frame with employment area count/percentage information about the selected course runs
stateEmploymentData<-function(dataType){
  
  #creates a data frame with one column initially - area
	data <- data.frame(area = as.character(c("accountancy_banking_and_finance","armed_forces_and_emergency_services",
										 "business_consulting_and_management","charities_and_voluntary_work" ,"creative_arts_and_culture",
										 "energy_and_utilities","engineering_and_manufacturing","environment_and_agriculture","health_and_social_care",
										 "hospitality_tourism_and_sport","it_and_information_services","law","marketing_advertising_and_pr","media_and_publishing",               
										 "property_and_construction","public_sector","recruitment_and_pr","retail_and_sales",
										 "science_and_pharmaceuticals","teaching_and_education","transport_and_logistics")))
	data$area <- as.character(data$area)

	#enrolment_data is a list of data frames, one for each course run selected
	#goes through each course run data frame
	for(x in names(enrolment_data)){
	  
	  #data frame with enrolment information about the statement buyers
		areaCount <- getSurveyResponsesFromStatementBuyers(enrolment_data[[x]])
		
		#with 3 columns - age, count and percentages
		areaCount <- getEmploymentAreaCount(areaCount)
		
		#creates a new column with the name of the current course run and initiliases it with 0s for each employment area
		data[[x]] <- numeric(21)
		
		#goes through each employment area option and updates its value in the current course run
		for(i in c(1:length(areaCount$employment))){
		  if(dataType == "percentages"){
		    data[[x]][which(data$area == areaCount$employment[i])] <- areaCount$percentage[i]
		  } else {
		    data[[x]][which(data$area == areaCount$employment[i])] <- areaCount$freq[i]
		  }
	  }
	}
	
	#orders the data in decreasing order by the values of the first course run
	data <- data[order(-data[[names(enrolment_data[1])]]),]
	return(data)
}

#' For creating the employment status chart for the statement buyers
#'
#' @param dataType the character value of the selected radio button
#'
#' @return a data frame with employemnt status value/percentage for each selected course
stateStatusData<-function(dataType){
  
  #creates a data frame with initially one column - levels of employment status
	data <- data.frame(levels = as.character(c("unemployed","working_full_time","working_part_time","retired",
			"not_working","full_time_student","self_employed","looking_for_work")))
	data$levels <- as.character(data$levels)
	
	#enrolment_data is a list of data frames, one for each course run
	#goes through each course run data frame
	for(x in names(enrolment_data)){
	  
	  #data frame with the enrolment informantion of only the statement buyers
		statusCount <- getSurveyResponsesFromStatementBuyers(enrolment_data[[x]])
		
		#counting the employment status choices in the course run - 3 columns: status, count and percentage
		statusCount <- getEmploymentStatusCount(statusCount)
		
		#creates a column with the name of the current course run in the loop and initialises the values with 0s
		data[[x]] <- numeric(8)
		
		#goes through each option of employment status and updates its value in the current course run
		for(i in c(1:length(statusCount$status))){
		  if(dataType == "percentages"){
		    data[[x]][which(data$levels == statusCount$status[i])] <- statusCount$percentage[i]
		  } else {
		    data[[x]][which(data$levels == statusCount$status[i])] <- statusCount$freq[i]
		  }
	  }
	}

	#ordering the data in decreasing order after the data in the first course run
	data <- data[order(-data[[names(enrolment_data[1])]]),]
	return(data)
}

#' For the Degree chart of the statement purchasers
#'
#' @param dataType the character value of the selected radio button
#'
#' @return a data frame with education status values/percentages for each of the selected course runs
stateEducationData<-function(dataType){
  
  #creates a data frame with initially one column - level of education
	data <- data.frame(level = c("apprenticeship","less_than_secondary","professional","secondary",           
		"tertiary","university_degree","university_masters","university_doctorate"))
	data$level <- as.character(data$level)

	#enrolment_data is a list of data frames, one for each selected course run
	#geos through each course run data frame
	for(x in names(enrolment_data)){
	  
	  #data frame with enrolment information about the statement buyers
		degreeCount <- getSurveyResponsesFromStatementBuyers(enrolment_data[[x]])
		
		#counting the education status values: 3 columns - degree, count and percentage
		degreeCount <- getEmploymentDegreeCount(degreeCount)
		
		#creates a column with the title of the current course run and initialises it with 0s
		data[[x]] <- numeric(8)
		
		#goes through each education status option and updates its values in the current course run
		for(i in c(1:length(degreeCount$degree))){
		  if(dataType == "percentages"){
		    data[[x]][which(data$level == degreeCount$degree[i])] <- degreeCount$percentage[i]
		  } else {
		    data[[x]][which(data$level == degreeCount$degree[i])] <- degreeCount$freq[i]
		  }
		}
	}
	return(data)
}

stateHDIData <-function(){
	data <- data.frame(levels = c("Very High","High","Medium","Low"))
		for(x in names(enrolment_data)){
			enrolments <- getSurveyResponsesFromStatementBuyers(enrolment_data[[x]])
			enrolments <- enrolments[which(enrolments$country != "Unknown"), ]
			countries<- as.character(enrolments$country)
			hdilevels <- countryCodesToHDI(countries)
			all <- as.factor(hdilevels)
			allCount <- count(all)
			allCount$percentage <- allCount$freq / sum(allCount$freq) * 100
			allCount$percentage <- round(allCount$percentage,2)
			allCount$x <- as.character(allCount$x)
			allCount <- allCount[,c("x","percentage")]
			allCount <- allCount[order(-allCount$percentage),]
			data[[x]] <- numeric(4)
			
			for(i in c(1:length(allCount$x))){
				data[[x]][which(data$levels == allCount$x[i])] <- allCount$percentage[i]
				}
		}
	return(data)
}

signUpData<-function(){
	freqs <- list()
	maxLength <- 0
	startDays <- list()
	for(i in c(1:length(names(enrolment_data)))){
		learners <- enrolment_data[[names(enrolment_data)[i]]]
		learners <- learners[which(learners$role == "learner"),]
		signUpCount <- count(substr(as.character(learners$enrolled_at),start = 1, stop = 10))
		dates <- list(seq.Date(from = as.Date(signUpCount$x[1]), to = as.Date(tail(signUpCount$x, n =1)), by = 1) , numeric())
		if(length(dates[[1]]) > maxLength){
			maxLength <- length(dates[[1]])
		}
		for(x in c(1:length(signUpCount$x))){
			dates[[2]][[which(dates[[1]] == as.Date(signUpCount$x[x]))]] <- signUpCount$freq[[x]]
		}
		freqs[[i]] <- dates
		startDay <- substr(as.character(course_data[[names(course_data)[i]]]$start_date),start = 1, stop = 10)
		startDays[i] <- as.Date(startDay) - as.Date(signUpCount$x[1])
	}
	data <- data.frame(day = seq(from = 1, to = maxLength))
	for(x in c(1:length(freqs))){
		d <- numeric(maxLength)
		for(i in c(1:length(freqs[[x]][[2]]))){
			if(!is.na(freqs[[x]][[2]][i]))
			d[i] <- freqs[[x]][[2]][i]
		}
		data[[names(enrolment_data[x])]] <- d
	}
	return(list(data,startDays,startDay))
}

#' To get the number of statements sold for each of the selected course in the range of days
#'
#' @return 	data frame with a 'day' column with all days in the sequence, and a column for each of the selected courses 
#           with their respective counts of statements sold in every particular day
statementsSoldData<-function(){
	freqs <- list()

	maxLength <- 0
	
	#enrolment data is a list of data frames, one for each course run selected
	for(i in c(1:length(names(enrolment_data)))){
	  
	  #copy the specific course run data frame
		learners <- enrolment_data[[names(enrolment_data)[i]]]
		
		#gets only the learners who purchased statements
		learners <- learners[which(learners$role == "learner"),]
		learners <- learners[which(learners$purchased_statement_at != ""),]
		
		#counts how many statements were purchased on each date
		signUpCount <- count(substr(as.character(learners$purchased_statement_at),start = 1, stop = 10))
		
		#if there is at least one row in the table
		if(nrow(learners) != 0){
		  #creates a list of two elements - a vector of dates and a numeric empty vector  
		  dates <- list(seq.Date(from = as.Date(signUpCount$x[1]), to = as.Date(tail(signUpCount$x, n =1)), by = 1) , numeric())
		  
		  #updated the max length of the sequence of days when statements were bought
		  if(length(dates[[1]]) > maxLength){
		    maxLength <- length(dates[[1]])
		  }
		  
		  #for each of the dates in the sign up period it assigns the number of statements sold in that day
		  for(x in c(1:length(signUpCount$x))){
		    dates[[2]][[which(dates[[1]] == as.Date(signUpCount$x[x]))]] <- signUpCount$freq[[x]]
		  }
		} else {
		  
		  #if there are no rows in the table it just creates an empty list
		  dates <- list(character(), numeric())
		}
		
		#it creates a list of lists - one list for each course run selected
		freqs[[i]] <- dates
	}

	#creates a data frame with one column - day, with one row for each of the days in the max sign up sequence
	if(maxLength > 1) {
	  data <- data.frame(day = seq(from = 1, to = maxLength))
	} else {
	  data <- data.frame(day = numeric(0))
	}
	
	#goes through each list in the freq list
	for(x in c(1:length(freqs))){
	  
	    #creates a numeric vector of size max length initialised only with 0s
			d <- numeric(maxLength)
			
			#goes through each value in the 2nd vector of the list and replaces the 0s with that when there were statements sold 
			if(length(freqs[[x]][[2]]) > 0){
			  for(i in c(1:length(freqs[[x]][[2]]))){
			    if(!is.na(freqs[[x]][[2]][i]))
			      d[i] <- freqs[[x]][[2]][i]
			  }
			}
			
			#creates a column in the data frame with the name of the course run and the values of the counts of the statements sold
			data[[names(enrolment_data[x])]] <- d
	}
	
	#data frame with a 'day' column with all days in the sequence, and a column for each of the selected courses 
	#with their respective counts of statements sold in every particular day
	return(data)
}

#' FOr creating the steps first visited per day table
#'
#' @return data frame with a 'day' column and a column for each of the selected courses
#'         with their respective counts of first visited steps in each day
stepsFirstVisitedPerDay<-function(){
	freqs <- list()

	maxLength <- 0
	
	#step data is a list of data frames, one for each selected course run 
	for(i in c(1:length(names(step_data)))){
	  
	  #creates a new data frame to store the step data of the current course run
		steps <- step_data[[names(step_data)[i]]]
		
		#gets the data with first visited dates
		steps <- steps[which(steps$first_visited_at != ""),]
		
		#counts the steps first visited for each day
		stepsCount <- count(substr(as.character(steps$first_visited_at),start = 1, stop = 10))
		
		#checks if the data is empty or not
		if(nrow(steps) != 0){
		  
		  #list of two elements - a vector of dates and a numeric empty vector
		  dates <- list(seq.Date(from = as.Date(stepsCount$x[1]), to = as.Date(tail(stepsCount$x, n =1)), by = 1) , numeric())
		  
		  #gets the max length of the sequence of dates
		  if(length(dates[[1]]) > maxLength){
		    maxLength <- length(dates[[1]])
		  }
		  
		  #for each of the dates in the sequence it assigns the number of steps first visited 
		  for(x in c(1:length(stepsCount$x))){
		    dates[[2]][[which(dates[[1]] == as.Date(stepsCount$x[x]))]] <- stepsCount$freq[[x]]
		  }
		  
		} else {
		  #if there are no rows in the table it just creates a list of empty elements
		  dates <- list(character(), numeric())
		}
		
		#it creates a list of lists - one list for each selected course
		freqs[[i]] <- dates
	}

	#creates a data frame with one column - day, with one row for each of the days in the max steps first visited sequence
	if(maxLength > 1) {
	  data <- data.frame(day = seq(from = 1, to = maxLength))
	} else {
	  data <- data.frame(day = numeric(0))
	}
	
	#goes through each list in the freq list
	for(x in c(1:length(freqs))){
	  
	    #creates a numeric vector with maxlength and 0s
			d <- numeric(maxLength)
			
			#goes through each value in the 2nd vector of the list and updates the 0s with that when there steps visited
			if(length(freqs[[x]][[2]]) > 0){
			  for(i in c(1:length(freqs[[x]][[2]]))){
			    if(!is.na(freqs[[x]][[2]][i]))
			      d[i] <- freqs[[x]][[2]][i]
			  }
			}
			
			#creates a new column with the name of the current course run and the values as number of steps first visited for each day
			data[[names(step_data[x])]] <- d
	}
	
	#data frame with 'day' column and columns for each of the selected course runs, presenting the number of first visited steps
	return(data)
}

commentsPerDay<-function(){
	freqs <- list()

	maxLength <- 0
	for(i in c(1:length(names(comments_data)))){
		comments <- comments_data[[names(comments_data)[i]]]
		comments <- comments[which(comments$timestamp != ""),]
		commentsCount <- count(substr(as.character(comments$timestamp),start = 1, stop = 10))
		dates <- list(seq.Date(from = as.Date(commentsCount$x[1]), to = as.Date(tail(commentsCount$x, n =1)), by = 1) , numeric())
		if(length(dates[[1]]) > maxLength){
			maxLength <- length(dates[[1]])
		}
		for(x in c(1:length(commentsCount$x))){
			dates[[2]][[which(dates[[1]] == as.Date(commentsCount$x[x]))]] <- commentsCount$freq[[x]]
		}
		freqs[[i]] <- dates
	}

	data <- data.frame(day = seq(from = 1, to = maxLength))
	for(x in c(1:length(freqs))){
			d <- numeric(maxLength)
			for(i in c(1:length(freqs[[x]][[2]]))){
				if(!is.na(freqs[[x]][[2]][i]))
				d[i] <- freqs[[x]][[2]][i]
			}
			data[[names(comments_data[x])]] <- d
	}
	return(data)
}


#' For rendering a chart of days vs number of steps marked as completed that day
#'
#' @return a data frame with 'day' column and for each day the value of the number of steps marked as completed in the selected courses
stepsMarkedCompletedPerDay<-function(){
	freqs <- list()

	maxLength <- 0
	
	#step_data is a list of data frames, one for each of the selected course runs
	for(i in c(1:length(names(step_data)))){
	  
	  #selects the step data for the current course
		steps <- step_data[[names(step_data)[i]]]
		
		#selects the steps which were last completed at a date
		steps <- steps[which(steps$last_completed_at != ""),]
		
		#counts the number of steps marked as completed for every day
		stepsCount <- count(substr(as.character(steps$last_completed_at),start = 1, stop = 10))
		
		#checks if the data is empty or not
		if(nrow(steps) != 0){
		  #creates a list with 2 elements - a vector of dates and an empty numeric vector
		  dates <- list(seq.Date(from = as.Date(stepsCount$x[1]), to = as.Date(tail(stepsCount$x, n =1)), by = 1) , numeric())
		  
		  #gets the max length of the sequence of days 
		  if(length(dates[[1]]) > maxLength){
		    maxLength <- length(dates[[1]])
		  }
		  
		  #for each of the dates in the sequence it assigns the number of completed steps in that day
		  for(x in c(1:length(stepsCount$x))){
		    dates[[2]][[which(dates[[1]] == as.Date(stepsCount$x[x]))]] <- stepsCount$freq[[x]]
		  }
		} else {
		  #if there are no rows in the table it just creates a list of empty elements
		  dates <- list(character(), numeric())
		}
	
		#it creates a list of lists - one list for each selected course
		freqs[[i]] <- dates
	}

	#creates a data frame with one column - day, with one row for each of the days in the max steps completed sequence
	if(maxLength > 1) {
	  data <- data.frame(day = seq(from = 1, to = maxLength))
	} else {
	  data <- data.frame(day = numeric(0))
	}
	
	#goes through each list in the freq list
	for(x in c(1:length(freqs))){
	  
	    #creates a numeric vector with maxlength and 0s
			d <- numeric(maxLength)
			
			if(length(freqs[[x]][[2]]) > 0){
			  for(i in c(1:length(freqs[[x]][[2]]))){
			    if(!is.na(freqs[[x]][[2]][i]))
			      d[i] <- freqs[[x]][[2]][i]
			  }
			}
			
			#creates a new column with the name of the current course run and the values as number of steps marked completed for each day
			data[[names(step_data[x])]] <- d
	}
	return(data)
}


#' Gets data for pre course survey table which also contains the comments in step 1.2
#'
#' @param dfPreCourse data frame with data from the pre course survey
#' @param comments data frame with comment data for the selected course run
#'
#' @return data frame with the comment in 1.2 and pre course survey data
getBasicSurveyData <- function(dfPreCourse, comments){
  
  #gets the author and comment text for those who commented in 1.2
  stepComments <- subset(comments, comments$step == "1.2")[, c("author_id", "text")]
  colnames(stepComments) <- c("Author ID", "Comment in step 1.2")

  #merges the ids of the learners from comments and surveys
  preCourseData <- merge(stepComments, dfPreCourse, by.x = "Author ID", by.y = "partner_export_id Open-Ended Response")

  return(preCourseData)
}

