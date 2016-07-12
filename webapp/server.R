require(shiny)
require(shinydashboard)
require(rCharts)
require(dygraphs)
require(xts)
require(d3heatmap)
require(ggplot2)
require(plyr)
require(googleVis)
require(networkD3)
require(shinyjs)
source("config.R")
source("learner_analysis.R")
source("learner_filters.R")
source("courses.R")

function(input, output, session) { 
	
	output$institution <- renderText({"soton"})
	output$pageTitle <- renderText("Welcome to MOOC Dashboard")
	output$updatedTime <- renderText(paste("Data last updated  -  ",getUpdatedTime()))
	
	# Make the text inputs of the active filters read-only and hide the dummy inputs
	shinyjs::disable("gender") 
	shinyjs::disable("age")
	shinyjs::disable("selected")
	shinyjs::disable("emplArea")
	shinyjs::disable("emplStatus")
	shinyjs::disable("degree")
	shinyjs::disable("foundCourse")
	shinyjs::disable("hopeCourse")
	shinyjs::disable("experience")
	shinyjs::disable("methods")
	shinyjs::disable("subjects")
	shinyjs::disable("place")
	shinyjs::hide("filteredLearners")
	shinyjs::hide("filteredStreams")
	shinyjs::hide("scatterSlopeValue")
	
	# Load the raw csv files for the selected course and assign them to global variables
	# Executes after user has clicked the "chooseCourseButton"
	
	observeEvent(input$chooseCourseButton, {
		
		output$pageTitle <- renderText(paste(input$course, "- [", input$run, "]"))
		
		updateTabsetPanel(session, "tabs", selected = "demographics")
		
		#FixMe - this could all go into a function - but check scope
		
		stepDataFile <- file.path(getwd(),"../data",institution,input$course,input$run,"step-activity.csv")
		print(stepDataFile)
		assign("step_data", getRawData(stepDataFile, "step"), envir = .GlobalEnv)


		stepData <- read.csv(file.path(getwd(),"../data",institution,input$course,input$run,"step-activity.csv"))
		assign("stepData", stepData, envir = .GlobalEnv)  
		
		commentsDataFile <- file.path(getwd(),"../data",institution,input$course,input$run,"comments.csv")
		print(commentsDataFile)
		assign("comments_data", getRawData(commentsDataFile, "comments"), envir = .GlobalEnv)    
		
		quizDataFile <- file.path(getwd(),"../data",institution,input$course,input$run,"question-response.csv")
		print(quizDataFile)
		assign("quiz_data", getRawData(quizDataFile, ""), envir = .GlobalEnv)
		
		assignmentsDataFile <- file.path(getwd(),"../data",institution,input$course,input$run,"peer-review-assignments.csv")
		print(assignmentsDataFile)
		if(file.exists(assignmentsDataFile))
		{
			assign("assignments_data", getRawData(assignmentsDataFile, ""), envir = .GlobalEnv)
		}
		else print("...No such File")
		
		reviewsDataFile <- file.path(getwd(),"../data",institution,input$course,input$run,"peer-review-reviews.csv")
		print(reviewsDataFile)
		if(file.exists(reviewsDataFile))
		{
			assign("reviews_data", getRawData(assignmentsDataFile, ""), envir = .GlobalEnv)
		}
		else print("...No such File")
		
		
		enrolmentDataFile <- file.path(getwd(),"../data",institution,input$course,input$run,"enrolments.csv")
		print(enrolmentDataFile)
		assign("enrolment_data", getRawData(enrolmentDataFile, ""), envir = .GlobalEnv)
		
		enrolmentDataFile <- file.path(getwd(),"../data",institution,input$course,input$run,"enrolments.csv")
		print(enrolmentDataFile)
		assign("pre_course_data", getPreCourseData(enrolmentDataFile), envir = .GlobalEnv)
		
		assign("allLearners", getAllLearners(enrolment_data), envir = .GlobalEnv)
		assign("filtersEnabled", FALSE, envir = .GlobalEnv)
		updateTextInput(session, "filteredLearners", value = allLearners)
		
	}, priority = 10)
	
	observeEvent(input$chooseCourseButton, {
		range <- getCourseDates(input$course, input$run)
		assign("courseDates", range, envir = .GlobalEnv)
		assign("startDate", as.POSIXct(range[[1]], format = "%Y-%m-%d", origin = "1970-01-01", tz = "GMT"), envir = .GlobalEnv)
		assign("endDate", as.POSIXct(range[[2]], format = "%Y-%m-%d", origin = "1970-01-01", tz = "GMT"), envir = .GlobalEnv)
		
		courseWeeks <- courseDates[[3]]
		courseStart <- courseDates[[1]]
		weeks <- c(courseStart)
		for (i in 2:courseWeeks) {
			weeks[i] <- as.POSIXct(weeks[i-1], origin = "1970-01-01") + 7 * 24 * 60 * 60
		}
		assign("weeks", weeks, envir = .GlobalEnv)
		if (courseWeeks == 1) {
			assign("weekCat", c("Week 1"), envir = .GlobalEnv)
		}
		else if (courseWeeks == 2) {
			assign("weekCat",
						 c("Week 1", "Week 2"), envir = .GlobalEnv)
		}
		else if (courseWeeks == 3) {
			assign("weekCat",
						 c("Week 1", "Week 2", "Week 3"), envir = .GlobalEnv)
		}
		else if (courseWeeks == 4) {
			assign("weekCat",
						 c("Week 1", "Week 2", "Week 3", "Week 4"), envir = .GlobalEnv)
		}
		else if (courseWeeks == 5) {
			assign("weekCat",
						 c("Week 1", "Week 2", "Week 3", "Week 4", "Week 5"), envir = .GlobalEnv)
		}
		else if (courseWeeks == 6) {
			assign("weekCat",
						 c("Week 1", "Week 2", "Week 3", "Week 4", "Week 5", "Week 6"), envir = .GlobalEnv)
		}
		else if (courseWeeks == 7) {
			assign("weekCat",
						 c("Week 1", "Week 2", "Week 3", "Week 4", "Week 5", "Week 6", "Week 7"), envir = .GlobalEnv)
		}
		else if (courseWeeks == 8) {
			assign("weekCat",
						 c("Week 1", "Week 2", "Week 3", "Week 4", "Week 5", "Week 6", "Week 7", "Week 8"), envir = .GlobalEnv)
		}
		else if (courseWeeks == 9) {
			assign("weekCat",
						 c("Week 1", "Week 2", "Week 3", "Week 4", "Week 5", "Week 6", "Week 7", "Week 8", "Week 9"), envir = .GlobalEnv)
		}
		else if (courseWeeks == 10) {
			assign("weekCat",
						 c("Week 1", "Week 2", "Week 3", "Week 4", "Week 5", "Week 6", "Week 7", "Week 8", "Week 9", "Week 10"), envir = .GlobalEnv)
		}
		else if (courseWeeks == 11) {
			assign("weekCat",
						 c("Week 1", "Week 2", "Week 3", "Week 4", "Week 5", "Week 6", "Week 7", "Week 8", "Week 9", "Week 10", "Week 11"), envir = .GlobalEnv)
		}
		else if (courseWeeks == 12) {
			assign("weekCat",
						 c("Week 1", "Week 2", "Week 3", "Week 4", "Week 5", "Week 6", "Week 7", "Week 8", "Week 9", "Week 10", "Week 11", "Week 12"), envir = .GlobalEnv)
		}
	}, priority = 4)
	
	categoriseWeek <- function (x) {
		
		for (i in 1:courseDates[[3]]) {
			if (!is.na(weeks[i+1])){
				if (x >= weeks[i] && x < weeks[i+1]) {
					return (paste("Week", i))
				}
			}else {
				if (x >= weeks[i]) {
					return (paste("Week", i))
				}
			}
		}
	}
	
	chartDependency <- eventReactive(input$chooseCourseButton, {})
	
	#START: COURSE SELECTION UI AND VALUE BOXES
	
	print("About to assemble runs")
	output$runs <-renderUI({
		print("hello")
		print(input$course)
		runs <- getRuns(input$course)
		selectInput("run", label = "Run", width = "450px", choices = runs)
	})
	
	output$courseNameAndRun <- renderUI({
		if (!is.null(input$course)) {
			tags$h2(paste(input$course, " - ", input$run))
		}
	})
	
	output$chooseCourse <- renderUI({
		actionButton("chooseCourseButton", label = "Go")
	})
	
	output$enrolmentCount <- renderValueBox({
		chartDependency()
		learners <- unlist(strsplit(input$filteredLearners, "[,]"))
		count <- getEnrolmentCount(learners, startDate, endDate, enrolment_data)   
		valueBox("Enrolled", count, icon = icon("line-chart"), color = "blue")
	})
	
	output$completedCount <- renderValueBox({
		chartDependency()
		learners <- unlist(strsplit(input$filteredLearners, "[,]"))
		count <- getCompletionCount(learners, startDate, endDate, step_data)
		valueBox("Completed", count, icon = icon("list"), color = "purple")
	})
	
	output$courseDuration <- renderValueBox({
		chartDependency()
		valueBox("Duration", paste(courseDates[3], "weeks"), icon = icon("clock-o"), color = "aqua")
	})
	
	output$courseStart <- renderValueBox({
		chartDependency()
		valueBox("Start date", courseDates[1], icon = icon("calendar"), color = "yellow")
	})
	
	output$totalComments <- renderValueBox({
		chartDependency()
		learners <- unlist(strsplit(input$filteredLearners, "[,]"))
		comments <- getNumberOfCommentsByLearner(learners, startDate, endDate, comments_data)
		comments <- sum(comments$comments)
		valueBox("Comments", paste(comments, "in total"), icon = icon("comment-o"), color = "red")
	})
	
	output$totalReplies <- renderValueBox({
		chartDependency()
		learners <- unlist(strsplit(input$filteredLearners, "[,]"))
		replies <- getNumberOfRepliesByLearner(learners, startDate, endDate, comments_data)
		replies <- sum(replies$replies)
		valueBox("Replies", paste(replies, "in total"), icon = icon("reply"), color = "yellow")
	})
	
	output$avgComments <- renderValueBox({
		chartDependency()
		learners <- unlist(strsplit(input$filteredLearners, "[,]"))
		comments <- getNumberOfCommentsByLearner(learners, startDate, endDate, comments_data)
		comments <- median(comments$comments)
		valueBox("Comments", paste(comments, "average per learner"), icon = icon("comment-o"), color = "green")
	})
	
	
	output$avgReplies <- renderValueBox({
		chartDependency()
		learners <- unlist(strsplit(input$filteredLearners, "[,]"))
		replies <- getNumberOfRepliesByLearner(learners, startDate, endDate, comments_data)
		replies <- median(replies$replies)
		valueBox("Replies", paste(replies, "average per learner"), icon = icon("reply"), color = "olive")
	})
	
	output$learnerStream <- renderUI({
		chartDependency()
		stream <- getSetOfLearnersByDate(courseDates[[3]], courseDates[[1]], enrolment_data)
		sets <- unique(stream$set)
		assign("streamData", stream, envir = .GlobalEnv)
		selectInput("learnerStreamSelect", label = "Choose a learner stream", choices = sets)
	})
	
	observeEvent(input$scatterSlopeValue, {
		output$scatterSlope <- renderValueBox({
			chartDependency()
			input$plotScatterButton
			valueBox("Slope", input$scatterSlopeValue, icon = icon("line-chart"), color = "red")
		})
	})
	
	
	#END: COURSE SELECTION UI AND VALUE BOXES
	
	
	#START: LEARNER FILTERS - TEXT INPUTS
	observeEvent(input$click$genderFilter, {
		updateTextInput(session, "gender", value = input$click$genderFilter)
	})
	
	observeEvent(input$click$ageFilter, {
		updateTextInput(session, "age", value = input$click$ageFilter)
	})
	
	observeEvent(input$click$employmentAreaFilter, {
		updateTextInput(session, "emplArea", value = input$click$employmentAreaFilter)
	})
	
	observeEvent(input$click$employmentStatusFilter, {
		updateTextInput(session, "emplStatus", value = input$click$employmentStatusFilter)
	})
	
	observeEvent(input$click$degreeFilter, {
		updateTextInput(session, "degree", value = input$click$degreeFilter)
	})
	
	observeEvent(input$click$foundCourseFilter, {
		updateTextInput(session, "foundCourse", value = input$click$foundCourseFilter)
	})
	
	observeEvent(input$click$hopeCourseFilter, {
		updateTextInput(session, "hopeCourse", value = input$click$hopeCourseFilter)
	})
	
	observeEvent(input$click$experienceFilter, {
		updateTextInput(session, "experience", value = input$click$experienceFilter)
	})
	
	observeEvent(input$click$methodsFilter, {
		updateTextInput(session, "methods", value = input$click$methodsFilter)
	})
	
	observeEvent(input$click$subjectsFilter, {
		updateTextInput(session, "subjects", value = input$click$subjectsFilter)
	})
	
	observeEvent(input$click$placeFilter, {
		updateTextInput(session, "place", value = input$click$placeFilter)
	})
	
	output$selected <- renderText({
		input$selected
	})
	#END: LEARNER FILTERS - TEXT INPUTS
	
	#START: LEARNER FILTERS - FILTERING
	
	assign("selectedGenderIDs", "", envir = .GlobalEnv)
	assign("selectedAgeIDs", "", envir = .GlobalEnv)
	assign("selectedDegreeIDs", "", envir = .GlobalEnv)
	assign("selectedCountryIDs", "", envir = .GlobalEnv)
	assign("selectedEmplAreaIDs", "", envir = .GlobalEnv)
	assign("selectedEmplStatusIDs", "", envir = .GlobalEnv)
	assign("selectedFoundCourseIDs", "", envir = .GlobalEnv)
	assign("selectedHopeCourseIDs", "", envir = .GlobalEnv)
	assign("selectedSubjectsIDs", "", envir = .GlobalEnv)
	assign("selectedMethodIDs", "", envir = .GlobalEnv)
	assign("selectedPlaceIDs", "", envir = .GlobalEnv)
	assign("selectedExperienceIDs", "", envir = .GlobalEnv)
	
	observeEvent(input$gender, {
		if (exists("fullGenderData")) {
			selected <- input$gender
			data <- subset(fullGenderData, gender == selected)
			learnerIDs <- as.vector(na.omit(data$learner_id))
			currentLearners <- unlist(strsplit(input$filteredLearners, "[,]"))
			if (filtersEnabled == TRUE) {
				currentLearners <- setdiff(currentLearners, selectedGenderIDs)
				assign("selectedGenderIDs", learnerIDs, envir = .GlobalEnv)
				learnerIDs <- append(learnerIDs, currentLearners)  
				updateTextInput(session, "filteredLearners", value = learnerIDs)
			}else {
				assign("selectedGenderIDs", learnerIDs, envir = .GlobalEnv)
				assign("filtersEnabled", TRUE, envir = .GlobalEnv)
				updateTextInput(session, "filteredLearners", value = learnerIDs)
			}
			
		}
	})
	
	observeEvent(input$age, {
		if (exists("fullAgeData")) {
			selected <- input$age
			data <- subset(fullAgeData, age == selected)
			learnerIDs <- as.vector(na.omit(data$learner_id))
			currentLearners <- unlist(strsplit(input$filteredLearners, "[,]"))
			if (filtersEnabled == TRUE) {
				currentLearners <- setdiff(currentLearners, selectedAgeIDs)
				assign("selectedAgeIDs", learnerIDs, envir = .GlobalEnv)
				learnerIDs <- append(learnerIDs, currentLearners)  
				updateTextInput(session, "filteredLearners", value = learnerIDs)
			}else {
				assign("selectedAgeIDs", learnerIDs, envir = .GlobalEnv)
				assign("filtersEnabled", TRUE, envir = .GlobalEnv)
				updateTextInput(session, "filteredLearners", value = learnerIDs)
			}
		}
	})
	
	observeEvent(input$selected, {
		if (exists("fullCountryData")) {
			selected <- input$selected
			data <- subset(fullCountryData, country == selected)
			learnerIDs <- as.vector(na.omit(data$learner_id))
			currentLearners <- unlist(strsplit(input$filteredLearners, "[,]"))
			if (filtersEnabled == TRUE) {
				currentLearners <- setdiff(currentLearners, selectedCountryIDs)
				assign("selectedCountryIDs", learnerIDs, envir = .GlobalEnv)
				learnerIDs <- append(learnerIDs, currentLearners)  
				updateTextInput(session, "filteredLearners", value = learnerIDs)
			}else {
				assign("selectedCountryIDs", learnerIDs, envir = .GlobalEnv)
				assign("filtersEnabled", TRUE, envir = .GlobalEnv)
				updateTextInput(session, "filteredLearners", value = learnerIDs)
			}
		}
	})
	
	observeEvent(input$emplArea, {
		if (exists("fullEmplAreaData")) {
			selected <- input$emplArea
			data <- subset(fullEmplAreaData, employment_area == selected)
			learnerIDs <- as.vector(na.omit(data$learner_id))
			currentLearners <- unlist(strsplit(input$filteredLearners, "[,]"))
			if (filtersEnabled == TRUE) {
				currentLearners <- setdiff(currentLearners, selectedEmplAreaIDs)
				assign("selectedEmplAreaIDs", learnerIDs, envir = .GlobalEnv)
				learnerIDs <- append(learnerIDs, currentLearners)  
				updateTextInput(session, "filteredLearners", value = learnerIDs)
			}else {
				assign("selectedEmplAreaIDs", learnerIDs, envir = .GlobalEnv)
				assign("filtersEnabled", TRUE, envir = .GlobalEnv)
				updateTextInput(session, "filteredLearners", value = learnerIDs)
			}
		}
	})
	
	observeEvent(input$emplStatus, {
		if (exists("fullEmplStatusData")) {
			selected <- input$emplStatus
			data <- subset(fullEmplStatusData, employment_status == selected)
			learnerIDs <- as.vector(na.omit(data$learner_id))
			currentLearners <- unlist(strsplit(input$filteredLearners, "[,]"))
			if (filtersEnabled == TRUE) {
				currentLearners <- setdiff(currentLearners, selectedEmplStatusIDs)
				assign("selectedEmplStatusIDs", learnerIDs, envir = .GlobalEnv)
				learnerIDs <- append(learnerIDs, currentLearners)  
				updateTextInput(session, "filteredLearners", value = learnerIDs)
			}else {
				assign("selectedEmplStatusIDs", learnerIDs, envir = .GlobalEnv)
				assign("filtersEnabled", TRUE, envir = .GlobalEnv)
				updateTextInput(session, "filteredLearners", value = learnerIDs)
			}
		}
	})
	
	observeEvent(input$degree, {
		if (exists("fullDegreeData")) {
			selected <- input$degree
			data <- subset(fullDegreeData, degree == selected)
			learnerIDs <- as.vector(na.omit(data$learner_id))
			currentLearners <- unlist(strsplit(input$filteredLearners, "[,]"))
			if (filtersEnabled == TRUE) {
				currentLearners <- setdiff(currentLearners, selectedDegreeIDs)
				assign("selectedDegreeIDs", learnerIDs, envir = .GlobalEnv)
				learnerIDs <- append(learnerIDs, currentLearners)  
				updateTextInput(session, "filteredLearners", value = learnerIDs)
			}else {
				assign("selectedDegreeIDs", learnerIDs, envir = .GlobalEnv)
				assign("filtersEnabled", TRUE, envir = .GlobalEnv)
				updateTextInput(session, "filteredLearners", value = learnerIDs)
			}
		}
	})
	
	observeEvent(input$foundCourse, {
		if (exists("fullFoundCourseData")) {
			selected <- input$foundCourse
			data <- subset(fullFoundCourseData, how_found_course == selected)
			learnerIDs <- as.vector(na.omit(data$learner_id))
			currentLearners <- unlist(strsplit(input$filteredLearners, "[,]"))
			if (filtersEnabled == TRUE) {
				currentLearners <- setdiff(currentLearners, selectedFoundCourseIDs)
				assign("selectedFoundCourseIDs", learnerIDs, envir = .GlobalEnv)
				learnerIDs <- append(learnerIDs, currentLearners)  
				updateTextInput(session, "filteredLearners", value = learnerIDs)
			}else {
				assign("selectedFoundCourseIDs", learnerIDs, envir = .GlobalEnv)
				assign("filtersEnabled", TRUE, envir = .GlobalEnv)
				updateTextInput(session, "filteredLearners", value = learnerIDs)
			}
		}
	})
	
	observeEvent(input$hopeCourse, {
		if (exists("fullHopeCourseData")) {
			selected <- input$hopeCourse
			data <- subset(fullHopeCourseData, hope_get_course == selected)
			learnerIDs <- as.vector(na.omit(data$learner_id))
			currentLearners <- unlist(strsplit(input$filteredLearners, "[,]"))
			if (filtersEnabled == TRUE) {
				currentLearners <- setdiff(currentLearners, selectedHopeCourseIDs)
				assign("selectedHopeCourseIDs", learnerIDs, envir = .GlobalEnv)
				learnerIDs <- append(learnerIDs, currentLearners)  
				updateTextInput(session, "filteredLearners", value = learnerIDs)
			}else {
				assign("selectedHopeCourseIDs", learnerIDs, envir = .GlobalEnv)
				assign("filtersEnabled", TRUE, envir = .GlobalEnv)
				updateTextInput(session, "filteredLearners", value = learnerIDs)
			}
		}
	})
	
	observeEvent(input$experience, {
		if (exists("fullExperienceData")) {
			selected <- input$experience
			data <- subset(fullExperienceData, previous_online_course == selected)
			learnerIDs <- as.vector(na.omit(data$learner_id))
			currentLearners <- unlist(strsplit(input$filteredLearners, "[,]"))
			if (filtersEnabled == TRUE) {
				currentLearners <- setdiff(currentLearners, selectedExperienceIDs)
				assign("selectedExperienceIDs", learnerIDs, envir = .GlobalEnv)
				learnerIDs <- append(learnerIDs, currentLearners)  
				updateTextInput(session, "filteredLearners", value = learnerIDs)
			}else {
				assign("selectedExperienceIDs", learnerIDs, envir = .GlobalEnv)
				assign("filtersEnabled", TRUE, envir = .GlobalEnv)
				updateTextInput(session, "filteredLearners", value = learnerIDs)
			}
		}
	})
	
	observeEvent(input$subjects, {
		if (exists("fullSubjectsData")) {
			selected <- input$subjects
			data <- subset(fullSubjectsData, subject == selected)
			learnerIDs <- as.vector(na.omit(data$learner_id))
			currentLearners <- unlist(strsplit(input$filteredLearners, "[,]"))
			if (filtersEnabled == TRUE) {
				currentLearners <- setdiff(currentLearners, selectedSubjectsIDs)
				assign("selectedSubjectsIDs", learnerIDs, envir = .GlobalEnv)
				learnerIDs <- append(learnerIDs, currentLearners)  
				updateTextInput(session, "filteredLearners", value = learnerIDs)
			}else {
				assign("selectedSubjectsIDs", learnerIDs, envir = .GlobalEnv)
				assign("filtersEnabled", TRUE, envir = .GlobalEnv)
				updateTextInput(session, "filteredLearners", value = learnerIDs)
			}
		}
	})
	
	observeEvent(input$methods, {
		if (exists("fullMethodsData")) {
			selected <- input$methods
			split <- strsplit(selected, "[;]") 
			method <- split[0]
			degree <- split[1]
			data <- subset(fullMethodsData, learning_method == method)
			data <- subset(fullMethodsData, degree == degree)
			learnerIDs <- as.vector(na.omit(data$learner_id))
			currentLearners <- unlist(strsplit(input$filteredLearners, "[,]"))
			if (filtersEnabled == TRUE) {
				currentLearners <- setdiff(currentLearners, selectedMethodIDs)
				assign("selectedMethodIDs", learnerIDs, envir = .GlobalEnv)
				learnerIDs <- append(learnerIDs, currentLearners)  
				updateTextInput(session, "filteredLearners", value = learnerIDs)
			}else {
				assign("selectedMethodIDs", learnerIDs, envir = .GlobalEnv)
				assign("filtersEnabled", TRUE, envir = .GlobalEnv)
				updateTextInput(session, "filteredLearners", value = learnerIDs)
			}
		}
	})
	
	observeEvent(input$place, {
		if (exists("fullPlaceData")) {
			selected <- input$place
			data <- subset(fullPlaceData, learning_place == selected)
			learnerIDs <- as.vector(na.omit(data$learner_id))
			currentLearners <- unlist(strsplit(input$filteredLearners, "[,]"))
			if (filtersEnabled == TRUE) {
				currentLearners <- setdiff(currentLearners, selectedPlaceIDs)
				assign("selectedPlaceIDs", learnerIDs, envir = .GlobalEnv)
				learnerIDs <- append(learnerIDs, currentLearners)  
				updateTextInput(session, "filteredLearners", value = learnerIDs)
			}else {
				assign("selectedPlaceIDs", learnerIDs, envir = .GlobalEnv)
				assign("filtersEnabled", TRUE, envir = .GlobalEnv)
				updateTextInput(session, "filteredLearners", value = learnerIDs)
			}
		}
	})
	
	observeEvent(input$resetFilters, {
		updateTextInput(session, "gender", value = "")
		updateTextInput(session, "age", value = "")
		updateTextInput(session, "degree", value = "")
		updateTextInput(session, "emplArea", value = "")
		updateTextInput(session, "emplStatus", value = "")
		updateTextInput(session, "foundCourse", value = "")
		updateTextInput(session, "hopeCourse", value = "")
		updateTextInput(session, "experience", value = "")
		updateTextInput(session, "subjects", value = "")
		updateTextInput(session, "methods", value = "")
		updateTextInput(session, "place", value = "")
		updateTextInput(session, "selected", value = "")
		updateTextInput(session, "filteredLearners", value = allLearners)
		assign("filtersEnabled", FALSE, envir = .GlobalEnv)
	})
	
	observeEvent(input$learnerStreamSelect, {
		if (exists("streamData")) {
			selected <- input$learnerStreamSelect
			data <- subset(streamData, set == selected)
			learnerIDs <- as.vector(na.omit(streamData$learner_id))
			updateTextInput(session, "filteredStreams", value = learnerIDs)
		}
	})
	
	#START: LEARNER FILTERS - CHARTS
	output$learnersAge <- renderChart2({
		chartDependency()
		
		#assign("allLearners", getAllLearners(enrolment_data), envir = .GlobalEnv)
		assign("filtersEnabled", FALSE, envir = .GlobalEnv)
		updateTextInput(session, "filteredLearners", value = allLearners)
		
		data <- getLearnersByAge(pre_course_data)
		assign("fullAgeData", data[[1]], envir = .GlobalEnv)
		plotData <- data[[2]]
		plotData$ageFilter <- plotData$age
		colnames(plotData)[c(1,2)] <- c("name", "y")
		pie <- Highcharts$new()
		pie$chart (type = "pie", width = "190")
		pie$series(
			name = "learners",
			colorByPoint = "true",
			data = toJSONArray2(plotData, json = FALSE, names = TRUE)
		)
		pie$plotOptions(
			pie = list(
				dataLabels = list(
					enabled = "false",
					connectorWidth = "0",
					color = "white"
				),
				showInLegend = "true",
				allowPointSelect = "true",
				size = "100%",
				cursor = "pointer",
				point = list(
					events = list(
						click = "#! function() { Shiny.onInputChange('click', {ageFilter: this.ageFilter})} !#"
					)
				)
			) 
		)
		return (pie)
	})
	
	
	output$learnersGender <- renderChart2({
		chartDependency()
		
		data <- getLearnersByGender(pre_course_data)
		assign("fullGenderData", data[[1]], envir = .GlobalEnv)
		plotData <- data[[2]]
		
		plotData$genderFilter <- plotData$gender
		colnames(plotData)[c(1,2)] <- c("x", "y")
		plotData <- plotData[1:2,]
		plotData[1,1] <- 0
		plotData[2,1] <- 1
		histogram <- Highcharts$new()
		histogram$chart (type = "column", width = "190")
		histogram$series(
			data = toJSONArray2(plotData, json = FALSE, names = TRUE),
			name = "learners"
		)
		histogram$xAxis (
			categories = c("Female", "Male"),
			labels = list(
				style = list(
					fontSize = 8
				)
			)
		)
		histogram$plotOptions(
			column = list(
				dataLabels = list(
					enabled = "true"
				),
				cursor = "pointer",
				point = list(
					events = list(
						click = "#! function() { Shiny.onInputChange('click', {genderFilter: this.genderFilter})} !#"
					)
				)
			)
		)
		return (histogram)
	})
	
	output$employmentArea <- renderChart2({
		chartDependency()
		
		data <- getLearnersByEmploymentArea(pre_course_data)
		assign("fullEmplAreaData", data[[1]], envir = .GlobalEnv)
		plotData <- data[[2]]
		plotData$employmentAreaFilter <- plotData$employment_area
		colnames(plotData)[c(1,2)] <- c("name", "y")
		pie <- Highcharts$new()
		pie$chart (type = "pie", width = "800")
		pie$series(
			name = "learners",
			colorByPoint = "true",
			data = toJSONArray2(plotData, json = FALSE, names = TRUE)
		)
		pie$plotOptions(
			pie = list(
				allowPointSelect = "true",
				cursor = "pointer", 
				point = list(
					events = list(
						click = "#! function() { Shiny.onInputChange('click', {employmentAreaFilter: this.employmentAreaFilter})} !#"
					)
				),
				dataLabels = list(
					enabled = "true",
					connectorPadding = 1,
					crop = "false",
					distance = 10
				),
				size = "25%",
				startAngle = 300
			)
		)
		return (pie)
	})
	
	output$employmentStatus <- renderChart2({
		chartDependency()
		
		data <- getLearnersByEmploymentStatus(pre_course_data)
		assign("fullEmplStatusData", data[[1]], envir = .GlobalEnv)
		plotData <- data[[2]]
		catList <- plotData$employment_status
		plotData$employmentStatusFilter <- plotData$employment_status
		plotData$employment_status <- seq(from = 0, to = nrow(plotData) - 1)
		colnames(plotData)[c(1,2)] <- c("x", "y")
		histogram <- Highcharts$new()
		histogram$chart (type = "column", width = "800")
		histogram$series(
			data = toJSONArray2(plotData, json = FALSE, names = TRUE),
			name = "learners"
		)
		histogram$xAxis (
			categories = catList,
			labels = list(
				style = list(
					fontSize = 10
				)
			)
		)
		histogram$plotOptions(
			column = list(
				dataLabels = list(
					enabled = "true"
				),
				cursor = "pointer",
				point = list(
					events = list(
						click = "#! function() { Shiny.onInputChange('click', {employmentStatusFilter: this.employmentStatusFilter})} !#"
					)
				)  
			)
		)
		return (histogram)
	})
	
	output$degreeLevel <- renderChart2({
		chartDependency()
		
		data <- getLearnersByDegreeLevel(pre_course_data)
		assign("fullDegreeData", data[[1]], envir = .GlobalEnv)
		plotData <- data[[2]]
		catList <- plotData$degree
		plotData$degreeFilter <- plotData$degree
		plotData$degree <- seq(from = 0, to = nrow(plotData) - 1)
		colnames(plotData)[c(1,2)] <- c("x", "y")
		histogram <- Highcharts$new()
		histogram$chart (type = "column", width = "800")
		histogram$series(
			data = toJSONArray2(plotData, json = FALSE, names = TRUE),
			name = "learners"
		)
		histogram$xAxis (
			categories = catList,
			labels = list(
				style = list(
					fontSize = 10
				)
			)
		)
		histogram$plotOptions(
			column = list(
				dataLabels = list(
					enabled = "true"
				),
				cursor = "pointer",
				point = list(
					events = list(
						click = "#! function() { Shiny.onInputChange('click', {degreeFilter: this.degreeFilter})} !#"
					)
				)
			)
		)
		return (histogram)
	})
	
	output$learnerMap <- renderGvis({
		chartDependency()
		
		data <- getLearnersByCountry(pre_course_data)
		assign("fullCountryData", data[[1]], envir = .GlobalEnv)
		plotData <- data[[2]]
		jscode <- "var sel = chart.getSelection();  
								var row = sel[0].row;
								var country = data.getValue(row, 0);
								$('input#selected').val(country);
								$('input#selected').trigger('change');"
		
		map <- gvisGeoChart(plotData, locationvar = "country", colorvar = "learners",
												options = list(
													gvis.listener.jscode = jscode,
													width = 900,
													height = 440,
													keepAspectRatio = "false",
													colorAxis = "{colors:['#91BFDB', '#FC8D59']}"
												)
		)
		return (map)
	})
	
	output$howFoundCourse <- renderChart2({
		chartDependency()
		# Check whether the survey for the selected course had this question
		validate(
			need(checkHasHowFoundCourse(pre_course_data) == TRUE,
					 "The survey for this course doesn't have this question")
		)
		data <- getLearnersByHowFoundCourse(pre_course_data)
		assign("fullHowFoundCourseData", data[[1]], envir = .GlobalEnv)
		
		plotData <- data[[2]]
		catList <- plotData$how_found_course
		plotData$foundCourseFilter <- plotData$how_found_course
		plotData$how_found_course <- seq(from = 0, to = nrow(plotData) - 1)
		colnames(plotData)[c(1,2)] <- c("x", "y")
		histogram <- Highcharts$new()
		histogram$chart (width = "380")
		histogram$series(
			data = toJSONArray2(plotData, json = FALSE, names = TRUE),
			type = "bar",
			name = "learners"
		)
		histogram$xAxis (
			categories = plotData$catList,
			labels = list(
				style = list(
					fontSize = 8
				)
			)
		)
		histogram$plotOptions(
			bar = list(
				cursor = "pointer", 
				point = list(
					events = list(
						click = "#! function() { Shiny.onInputChange('click', {foundCourseFilter: this.foundCourseFilter})} !#"
					)
				)
			)
		)
		return (histogram)
	})
	
	
	output$hopeGetFromCourse <- renderChart2({
		chartDependency()
		
		data <- getLearnersByHopeGetFromCourse(pre_course_data)
		assign("fullHopeCourseData", data[[1]], envir = .GlobalEnv)
		plotData <- data[[2]]
		catList <- plotData$hope_get_course
		plotData$hopeCourseFilter <- plotData$hope_get_course
		plotData$hope_get_course <- seq(from = 0, to = nrow(plotData) - 1)
		colnames(plotData)[c(1,2)] <- c("x", "y")
		histogram <- Highcharts$new()
		histogram$chart (width = "380")
		histogram$series(
			data = toJSONArray2(plotData, json = FALSE, names = TRUE),
			type = "bar",
			name = "learners"
		)
		histogram$xAxis (
			categories = catList,
			labels = list(
				style = list(
					fontSize = 8
				)
			)
		)
		histogram$plotOptions(
			bar = list(
				cursor = "pointer", 
				point = list(
					events = list(
						click = "#! function() { Shiny.onInputChange('click', {hopeCourseFilter: this.hopeCourseFilter})} !#"
					)
				)
			)
		)
		return (histogram)
	})
	
	output$learningMethods <- renderChart2({
		chartDependency()
		
		data <- getLearnersByLearningMethods(pre_course_data)
		assign("fullMethodsData", data[[1]], envir = .GlobalEnv)
		plotData <- data[[2]]
		histogram <- Highcharts$new()
		histogram$chart (width = "380")
		
		histogram$series(
			data = list(
				list(x = 0, y = plotData[5,3], methodsFilter = paste(plotData[5,1], plotData[5,2], sep = ";")),
				list(x = 1, y = plotData[11,3], methodsFilter = paste(plotData[11,1], plotData[11,2], sep = ";")),
				list(x = 2, y = plotData[17,3], methodsFilter = paste(plotData[17,1], plotData[17,2], sep = ";")),
				list(x = 3, y = plotData[23,3], methodsFilter = paste(plotData[23,1], plotData[23,2], sep = ";")),
				list(x = 4, y = plotData[29,3], methodsFilter = paste(plotData[29,1], plotData[29,2], sep = ";"))
			), 
			type = "column",
			name = "Strongly dislike"
		)
		histogram$series(
			data = list(
				list(x = 0, y = plotData[1,3], methodsFilter = paste(plotData[1,1], plotData[1,2], sep = ";")),
				list(x = 1, y = plotData[7,3], methodsFilter = paste(plotData[7,1], plotData[7,2], sep = ";")),
				list(x = 2, y = plotData[13,3], methodsFilter = paste(plotData[13,1], plotData[13,2], sep = ";")),
				list(x = 3, y = plotData[19,3], methodsFilter = paste(plotData[19,1], plotData[19,2], sep = ";")),
				list(x = 4, y = plotData[25,3], methodsFilter = paste(plotData[25,1], plotData[25,2], sep = ";"))
			), 
			type = "column",
			name = "Dislike"
		)
		histogram$series(
			data = list(
				list(x = 0, y = plotData[4,3], methodsFilter = paste(plotData[4,1], plotData[4,2], sep = ";")),
				list(x = 1, y = plotData[10,3], methodsFilter = paste(plotData[10,1], plotData[10,2], sep = ";")),
				list(x = 2, y = plotData[16,3], methodsFilter = paste(plotData[16,1], plotData[16,2], sep = ";")),
				list(x = 3, y = plotData[22,3], methodsFilter = paste(plotData[22,1], plotData[22,2], sep = ";")),
				list(x = 4, y = plotData[28,3], methodsFilter = paste(plotData[28,1], plotData[28,2], sep = ";"))
			), 
			type = "column",
			name = "Neutral"
		)
		histogram$series(
			data = list(
				list(x = 0, y = plotData[3,3], methodsFilter = paste(plotData[3,1], plotData[3,2], sep = ";")),
				list(x = 1, y = plotData[9,3], methodsFilter = paste(plotData[9,1], plotData[9,2], sep = ";")),
				list(x = 2, y = plotData[15,3], methodsFilter = paste(plotData[15,1], plotData[15,2], sep = ";")),
				list(x = 3, y = plotData[21,3], methodsFilter = paste(plotData[21,1], plotData[21,2], sep = ";")),
				list(x = 4, y = plotData[27,3], methodsFilter = paste(plotData[27,1], plotData[27,2], sep = ";"))
			), 
			type = "column",
			name = "Like"
		)
		histogram$series(
			data = list(
				list(x = 0, y = plotData[6,3], methodsFilter = paste(plotData[6,1], plotData[6,2], sep = ";")),
				list(x = 1, y = plotData[12,3], methodsFilter = paste(plotData[12,1], plotData[12,2], sep = ";")),
				list(x = 2, y = plotData[18,3], methodsFilter = paste(plotData[18,1], plotData[18,2], sep = ";")),
				list(x = 3, y = plotData[24,3], methodsFilter = paste(plotData[24,1], plotData[24,2], sep = ";")),
				list(x = 4, y = plotData[30,3], methodsFilter = paste(plotData[30,1], plotData[30,2], sep = ";"))
			), 
			type = "column",
			name = "Strongly like"
		)
		histogram$series(
			data = list(
				list(x = 0, y = plotData[2,3], methodsFilter = paste(plotData[2,1], plotData[2,2], sep = ";")),
				list(x = 1, y = plotData[8,3], methodsFilter = paste(plotData[8,1], plotData[8,2], sep = ";")),
				list(x = 2, y = plotData[14,3], methodsFilter = paste(plotData[14,1], plotData[14,2], sep = ";")),
				list(x = 3, y = plotData[20,3], methodsFilter = paste(plotData[20,1], plotData[20,2], sep = ";")),
				list(x = 4, y = plotData[26,3], methodsFilter = paste(plotData[26,1], plotData[26,2], sep = ";"))
			), 
			type = "column",
			name = "Don't know"
		)
		histogram$xAxis (
			categories = unique(plotData$learning_method),
			labels = list(
				style = list(
					fontSize = 8
				)
			)
		)
		histogram$plotOptions(
			column = list(
				cursor = "pointer", 
				point = list(
					events = list(
						click = "#! function() { Shiny.onInputChange('click', {methodsFilter: this.methodsFilter})} !#"
					)
				)
			)
		)
		return (histogram)
	})
	
	output$interestedSubjects <- renderChart2({
		chartDependency()
		
		data <- getLearnersByInterestedSubjects(pre_course_data)
		assign("fullSubjectsData", data[[1]], envir = .GlobalEnv)
		plotData <- data[[2]]
		catList <- plotData$subject
		plotData$subjectsFilter <- plotData$subject
		plotData$subject <- seq(from = 0, to = nrow(plotData) - 1)
		colnames(plotData)[c(1,2)] <- c("x", "y")
		histogram <- Highcharts$new()
		histogram$chart (width = "380")
		
		histogram$series(
			data = toJSONArray2(plotData, F, T),
			type = "column",
			name = "learners"
		)
		histogram$xAxis (
			categories = catList,
			labels = list(
				style = list(
					fontSize = 8
				)
			)
		)
		histogram$plotOptions(
			column = list(
				cursor = "pointer", 
				point = list(
					events = list(
						click = "#! function() { Shiny.onInputChange('click', {subjectsFilter: this.subjectsFilter})} !#"
					)
				)
			)
		)
		return (histogram)
	})
	
	output$pastExperience <- renderChart2({
		chartDependency()
		
		data <- getLearnersByPastOnlineCourse(pre_course_data)
		assign("fullExperienceData", data[[1]], envir = .GlobalEnv)
		plotData <- data[[2]]
		catList <- plotData$previous_online_course
		plotData$experienceFilter <- plotData$previous_online_course
		plotData$previous_online_course <- seq(from = 0, to = nrow(plotData) - 1)
		colnames(plotData)[c(1,2)] <- c("x", "y")
		histogram <- Highcharts$new()
		histogram$chart (width = "380")
		histogram$series(
			data = toJSONArray2(plotData, F, T),
			type = "column",
			name = "learners"
		)
		histogram$xAxis (
			categories = catList,
			labels = list(
				style = list(
					fontSize = 8
				)
			)
		)
		histogram$plotOptions(
			column = list(
				cursor = "pointer", 
				point = list(
					events = list(
						click = "#! function() { Shiny.onInputChange('click', {experienceFilter: this.experienceFilter})} !#"
					)
				)
			)
		)
		return (histogram)
	})
	
	output$learningPlace <- renderChart2({
		chartDependency()
		
		data <- getLearnersByExpectedLearningPlace(pre_course_data)
		assign("fullPlaceData", data[[1]], envir = .GlobalEnv)
		plotData <- data[[2]]
		catList <- plotData$learning_place
		plotData$placeFilter <- plotData$learning_place
		plotData$learning_place <- seq(from = 0, to = nrow(plotData) - 1)
		colnames(plotData)[c(1,2)] <- c("x", "y")
		histogram <- Highcharts$new()
		histogram$chart (width = "380")
		histogram$series(
			data = toJSONArray2(plotData, F, T),
			type = "column",
			name = "learners"
		)
		histogram$xAxis (
			categories = catList,
			labels = list(
				style = list(
					fontSize = 8
				)
			)
		)
		histogram$plotOptions(
			column = list(
				cursor = "pointer", 
				point = list(
					events = list(
						click = "#! function() { Shiny.onInputChange('click', {placeFilter: this.placeFilter})} !#"
					)
				)
			)
		)
		return (histogram)
	})
	#END: LEARNER FITLERS - CHARTS
	
	
	#START: CHARTS - COMMENTS ORIENTATED
	# Heatmap of comments made per step and date
	output$stepDateCommentsHeat <- renderD3heatmap({
		# Draw the chart when the "chooseCourseButton" is pressed by the user
		chartDependency()
		learners <- unlist(strsplit(input$filteredLearners, "[,]"))
		comments <- getNumberOfCommentsByDateStep(learners, startDate, endDate, comments_data)
		comments <- as.matrix(comments)
		d3heatmap(comments[,2:ncol(comments)], dendrogram = "none", 
							color = "Blues",, 
							scale = "column",
							labRow = as.character(as.POSIXct(comments[,1], origin = "1970-01-01")),
							labCol = colnames(comments)[-1])
	})
	
	# Histogram of the comment and replies made per week
	output$commentsRepliesWeekBar <- renderChart2({
		# Draw the chart when the "chooseCourseButton" is pressed by the user
		chartDependency()
		# Get the comments and replies by date and combine them to a single data frame
		learners <- unlist(strsplit(input$filteredLearners, "[,]"))
		comments <- getNumberOfCommentsByDate(learners, startDate, endDate, comments_data)
		replies <- getNumberOfRepliesByDate(learners, startDate, endDate, comments_data)
		plotData <- merge (comments, replies, by = "timestamp")
		# Categorise the dates into course weeks
		weekList <- lapply(plotData$timestamp, function (x) categoriseWeek (x))
		# Add the list to the data frame and order it by week
		plotData$week <- weekList
		plotData$week <- factor(plotData$week, levels = weekCat)
		# Split the data by week and aggregate (to get the total sum of comments and replies made per week)
		plotData <- ddply(plotData, ~week, summarise, replies = sum(replies), comments = sum(comments))
		# Create the histogram and pass in some options
		histogram <- Highcharts$new()
		histogram$chart (type = "column",  width = "380")
		histogram$data (plotData)
		histogram$xAxis (categories = weekCat)
		histogram$yAxis (
			title = list(
				text = "Total comments made"
			),
			stackLabels = list(
				enabled = "true",
				style = list(
					fontWeight = "bold",
					color = "gray"
				)
			)
		)
		histogram$plotOptions (
			column = list(
				stacking = "normal",
				dataLabels = list(
					enabled = "true",
					color = "white",
					style = list(
						textShadow = "0 0 3px black"
					)
				)
			)
		)
		return (histogram)
	})
	
	# Histogram of the number of authors per week
	output$authorsWeekBar <- renderChart2({
		# Draw the chart when the "chooseCourseButton" is pressed by the user
		chartDependency()
		# Get the number of authors by date
		learners <- unlist(strsplit(input$filteredLearners, "[,]"))
		authors <- getNumberOfAuthorsByDate(learners, input$courseDates[1], input$courseDates[2], comments_data)
		# Categorise the dates into weeks
		weekList <- lapply(authors$timestamp, function (x) categoriseWeek (x))
		# Add the list of weeks to the data frame and order it
		authors$week <- weekList
		authors$week <- factor(authors$week, levels = weekCat)
		# Find the total number of authors per week
		authors <- ddply(authors, ~week, summarise, authors = sum(authors))
		# Create the histogram and pass in some options
		histogram <- Highcharts$new()
		histogram$chart (type = "column", width = "380")
		histogram$data (authors)
		histogram$xAxis (categories = weekCat)
		histogram$yAxis (
			title = list(
				text = "Number of authors"
			)
		)
		histogram$plotOptions (
			column = list(
				dataLabels = list(
					enabled = "true",
					color = "white",
					style = list(
						textShadow = "0 0 3px black"
					)
				)
			)
		)
		return (histogram)
	})
	
	# Line chart of the average number of comments made per step completion percentage
	output$avgCommentsCompletionLine <- renderChart2({
		# Draw the chart when the "chooseCourseButton" is pressed by the user
		chartDependency()
		# Get number of comments made and steps completed by learner
		learners <- unlist(strsplit(input$filteredLearners, "[,]"))
		# JSR replaced
		#assign("startDate", input$courseDates[1], envir = .GlobalEnv)
		#assign("endDate", input$courseDates[2], envir = .GlobalEnv)
		
		comments <- getNumberOfCommentsByLearner(learners, input$courseDates[1], input$courseDates[2], comments_data)
		steps <- getStepsCompleted(learners, input$courseDates[1], input$courseDates[2], step_data)
		# Round the percentage 
		steps$completed <- round(steps$completed)
		# Merge the two data frame together
		plotData <- merge(comments, steps, by = "learner_id")
		assign("plotTest", plotData, envir = .GlobalEnv)
		# To reduce the number of drawn point, scale the percentages to increments of 5
		plotData$completed <- lapply(plotData$completed, function (x) if (x %% 5 != 0) {x - x %% 5} else {x})
		plotData$completed <- as.numeric(plotData$completed)
		# Aggregate the data to get the total average of comments made per percentage of completed steps
		plotData <- ddply(plotData, ~completed, summarise, comments = mean(comments))
		# Create the line chart and pass in some options
		lineChart <- Highcharts$new()
		lineChart$chart (type = "line", width = "380", height = "210")
		lineChart$series (
			name = "Comments",
			data = toJSONArray2(plotData, json = FALSE, names = FALSE),
			type = "line"
		)
		lineChart$xAxis (title = list(text = "Completed (%)"))
		lineChart$yAxis (title = list(text = "Comments"))
		return (lineChart)
	})
	
	#END: CHARTS - COMMENTS ORIENTATED
	
	#START: CHARTS - OTHER
	# Scatter plot
	output$scatterPlot <- renderChart2({
		# Draw the chart when the "chooseCourseButton" AND the "plotScatterButton" are pressed by the user
		chartDependency()
		input$plotScatterButton
		learners <- unlist(strsplit(input$filteredLearners, "[,]"))
		# In case the user has selected the same values for x and y, display an error message
		validate(
			need(isolate(input$scatterX) != isolate(input$scatterY),
					 "X and Y values cannot be identical. Please, choose different ones.")
		)
		# Check selected input for x and get the according data
		if (isolate(input$scatterX) == "comments") {
			x <- getNumberOfCommentsByLearner(learners, startDate, endDate, comments_data)
			xAxisTitle <- "Comments"
		}
		else if (isolate(input$scatterX) == "replies") {
			x <- getNumberOfRepliesByLearner(learners, startDate, endDate, comments_data)
			xAxisTitle <- "Replies"
		}
		else if (isolate(input$scatterX) == "likes") {
			x <- getNumberOfLikesByLearner(learners, startDate, endDate, comments_data)
			xAxisTitle <- "Likes"
		}
		else if (isolate(input$scatterX) == "answers") {
			x <- getNumberOfResponsesByLearner(learners, startDate, endDate, quiz_data)
			xAxisTitle <- "Answers"
		}
		else if (isolate(input$scatterX) == "steps") {
			x <- getStepsCompleted(learners, startDate, endDate, step_data)
			xAxisTitle <- "Completed (%)"
		}
		else if (isolate(input$scatterX) == "correct") {
			x <- getResponsesPercentage(learners, startDate, endDate, quiz_data)
			x <- x[c("learner_id", "correct")]
			xAxisTitle <- "Correct (%)"
		}
		else if (isolate(input$scatterX) == "wrong") {
			x <- getResponsesPercentage(learners, startDate, endDate, quiz_data)
			x <- x[c("learner_id", "wrong")]
			xAxisTitle <- "Wrong (%)"
		}
		else if (isolate(input$scatterX) == "questions") {
			x <- getPercentageOfAnsweredQuestions(learners, startDate, endDate, quiz_data)
			xAxisTitle <- "Questions (%)"
		}
		# Check selected input for y and get the according data
		if (isolate(input$scatterY) == "comments") {
			y <- getNumberOfCommentsByLearner(learners, startDate, endDate, comments_data)
			yAxisTitle <- "Comments"
		}
		else if (isolate(input$scatterY) == "replies") {
			y <- getNumberOfRepliesByLearner(learners, startDate, endDate, comments_data)
			yAxisTitle <- "Replies"
		}
		else if (isolate(input$scatterY) == "likes") {
			y <- getNumberOfLikesByLearner(learners, startDate, endDate, comments_data)
			yAxisTitle <- "Likes"
		}
		else if (isolate(input$scatterY) == "answers") {
			y <- getNumberOfResponsesByLearner(learners, startDate, endDate, quiz_data)
			yAxisTitle <- "Answers"
		}
		else if (isolate(input$scatterY) == "steps") {
			y <- getStepsCompleted(learners, startDate, endDate, step_data)
			yAxisTitle <- "Completed (%)"
		}
		else if (isolate(input$scatterY) == "correct") {
			y <- getResponsesPercentage(learners, startDate, endDate, quiz_data)
			y <- y[c("learner_id", "correct")]
			yAxisTitle <- "Correct (%)"
		}
		else if (isolate(input$scatterY) == "wrong") {
			y <- getResponsesPercentage(learners, startDate, endDate, quiz_data)
			y <- y[c("learner_id", "wrong")]
			yAxisTitle <- "Wrong (%)"
		}
		else if (isolate(input$scatterY) == "questions") {
			y <- getPercentageOfAnsweredQuestions(learners, startDate, endDate, quiz_data)
			yAxisTitle <- "Questions (%)"
		}
		# Merge the x and y data frames together and rename the columns
		plotData <- merge(x, y, by = "learner_id")
		colnames(plotData)[c(2,3)] <- c("x", "y")
		# Produce the regression model 
		regressionModel <- lm(x ~ y, data = plotData)
		# Find the slope and assign it to a global variable
		updateTextInput(session, "scatterSlopeValue", value = as.character(coef(regressionModel)[2]))
		# Convert the regression model to a data frame
		regressionData <- fortify(regressionModel)
		# Extract the line of best fit
		regressionData$x <- regressionData$`.fitted`
		# Reorder and rename the columns
		regressionData <- regressionData[,c(2, 1)]
		colnames(regressionData) <- c("x", "y")
		# Get the start and end coordinates of the line of best fit
		startPoint <- subset(regressionData, y == min(y))
		startPoint <- startPoint[1,]
		endPoint <- subset(regressionData, y == max(y))
		endPoint <- endPoint[1,]
		regressionData <- rbind(startPoint, endPoint)
		# Create the scatter plot and pass in some options
		scatter <- hPlot(x ~ y, data = plotData, type = "scatter", color = "completed")
		scatter$chart (width = "1500")
		scatter$series (list(
			list(
				data = toJSONArray2(regressionData, json = FALSE, names = FALSE), 
				type = "line"
			)
		))
		scatter$xAxis (title = list(text = yAxisTitle), ticks = 15, min = 0)
		scatter$yAxis (title = list(text = xAxisTitle), ticks = 15, min = 0, max = 100)
		scatter$tooltip (formatter = "#! function() { return 'Comments: '     + this.point.y + '<br />' +
																 'Completed: '    + this.point.x.toFixed(2)  + '<br />'; } !#")
		scatter$chart (zoomType = "xy")
		
		return (scatter)
	})
	
	output$dateTimeSeries <- renderDygraph({
		chartDependency()
		learners <- unlist(strsplit(input$filteredStreams, "[,]"))
		#calculate the comments, like and replies by date

		comments <- getNumberOfCommentsByDate(learners, startDate, endDate, comments_data)
		likes <-  getNumberOfLikesByDate(learners, startDate, endDate, comments_data)
		replies <- getNumberOfRepliesByDate(learners, startDate, endDate, comments_data)
		answers <- getNumberOfResponsesByDateTime(learners, startDate, endDate, quiz_data)
		enrolment <- getEnrolmentByDateTime(learners, startDate, endDate, enrolment_data)
		
		#convert them to time series objects so dygraph can plot them
		commentsXts <- xts(as.matrix(comments[,-1]),as.POSIXct(comments[,1],format='%Y-%m-%d %H', tz= "GMT"))
		likesXts <- xts(as.matrix(likes[,-1]),as.POSIXct(likes[,1],format='%Y-%m-%d %H', tz= "GMT"))
		repliesXts <- xts(as.matrix(replies[,-1]),as.POSIXct(replies[,1],format='%Y-%m-%d %H', tz= "GMT"))
		answersXts <- xts(as.matrix(answers[,-1]),as.POSIXct(answers[,1],format='%Y-%m-%d %H', tz= "GMT"))
		enrolmentXts <- xts(as.matrix(enrolment[,-1]),as.POSIXct(enrolment[,1],format='%Y-%m-%d %H', tz= "GMT"))
		#combine the series
		plotData <- cbind(commentsXts, repliesXts, likesXts, answersXts, enrolmentXts)
		plotData <- na.fill(plotData, 0)
		for (i in 1:nrow(plotData)) {
			if (plotData[i,5] == 0) {
				plotData[i,5] = plotData[i-1,5]
			}
		}
		colnames(plotData) <- c("comments", "replies", "likes", "answers", "enrolment")
		plotData$comments <- cumsum(plotData$comments)
		plotData$replies <- cumsum(plotData$replies)
		plotData$likes <- cumsum(plotData$likes)
		plotData$answers <- cumsum(plotData$answers)
		#plot all the series in one chart, passing it some options
		dygraph(plotData) %>%
			dySeries("comments", label = "Comments") %>%
			dySeries("replies", label = "Likes") %>%
			dySeries("likes", label = "Replies") %>%
			dySeries("answers", label = "Answers") %>%
			dySeries("enrolment", label = "Enrolment") %>%
			#for some reason, useDataTimezone stopped working
			dyOptions(stepPlot = FALSE, fillGraph = FALSE, drawGrid = FALSE, useDataTimezone = TRUE) %>%
			dyLegend(show = "always", hideOnMouseOut = TRUE, width = 700) %>%
			dyRangeSelector() %>%
			dyRoller(rollPeriod  = 1) %>%
			dyHighlight(highlightCircleSize = 5, 
									highlightSeriesBackgroundAlpha = 0.2,
									hideOnMouseOut = TRUE,
									highlightSeriesOpts = list(strokeWidth = 2))
	})
	
	
	output$network <- renderForceNetwork({
		chartDependency()
		
		com <- comments_data
		input$resetButton
		start <- startDate
		end <- endDate
		net <- getNetworkByLearner(com)
		
		#net <- net[as.Date(net$Timestamp) >= start & as.Date(net$Timestamp) <= end,]
		id <- unique(c(net$Givers,net$Receivers))
		node <<- data.frame(id)
		src <- apply(as.matrix(net$Givers),1,function(x) match(x,id)) 
		tag <- apply(as.matrix(net$Receivers),1,function(x) match(x,id))
		src <- src - 1
		tag <- tag - 1
		link <<- data.frame(src,tag)
		link <- dcast(link,src + tag ~ 'value',length)
		
		giver <- unique(net$Givers)
		receiver <- unique(net$Receivers)
		group <- apply(as.matrix(id),1,function(x) if(!is.na(match(x,giver)) & !is.na(match(x,receiver))) 'both' else if (!is.na(match(x,giver))) 'giver' else 'receiver')
		node$group <- group
		node$size <- 5
		forceNetwork(link,node,Source ='src',Target = 'tag', Nodesize = 'size',radiusCalculation = JS("d.nodesize"),
								 linkWidth = JS("function(d) { return d.value
														; }"), linkColour = "#000000",opacity = 0.9,
								 Value = 'value',NodeID = 'id',Group = 'group',zoom =  T, legend = T,colourScale = 'd3.scale.category10()',
								 clickAction = 'var pos = d3.transform(d3.select(this).attr("transform")).translate;
														var x = pos[0];
														var y = pos[1];
														var line = d3.selectAll("line");
														var size = line.size();
														var lines = line[0];
														for (var i = 0;i < size; i ++){
															l = lines[i]
																if((x == l.x1.animVal.value && y == l.y1.animVal.value) || (x == l.x2.animVal.value && y == l.y2.animVal.value)){
																			if( l.style["stroke"] == "rgb(255, 0, 0)" ){
																					l.style["stroke"] = "rgb(0,0,0)";
																			}else{
																					l.style["stroke"] = "rgb(255,0,0)";
																			}
																}
														}
														 '  
								 
		)
	}) 
	
	output$densityAndReciprocity <- renderDygraph({
		chartDependency()
		comments <- comments_data
		comments$timestamp <- as.POSIXct(comments$timestamp, format = '%Y-%m-%d', tz= "UTC")
		density <- getDensityByDate(getNewLearnersByDate(comments),getNewConnectionByDate(comments))
		reciprocity <- getReciprocityByDate(comments)
		data <- getFinalData(density,reciprocity)
		
		
		d <- xts(data$Density,as.POSIXct(data$timestamp,format='%Y-%m-%d', tz= "UTC"))
		r <- xts(data$Reciprocity*100,as.POSIXct(data$timestamp,format='%Y-%m-%d', tz= "UTC"))
		plotData <- cbind(d,r)
		dygraph(plotData, main = 'Density and Reciprocity', x = 'Date') %>%  
			dySeries("..1", label = "Density") %>%
			dySeries("..2", label = "Reciprocity") %>%
			dyRangeSelector()
		
	})
	
	output$degreeGraph <- renderDygraph({
		chartDependency()
		degree <- getDegreeByLearner(comments_data)
		plotData <- data.frame()
		for (n in 2:ncol(degree)){
			x <- xts(degree[,n], as.POSIXct(degree$timestamp,format='%Y-%m-%d', tz= "UTC"))
			plotData <- cbind(plotData,x)
			
		}
		
		colnames(plotData) <- paste(substr(colnames(degree)[2:ncol(degree)],0,5),'..',sep ='')
		dygraph(plotData, main = 'Degree(top 7 learners)', x = 'Date') %>%  
			dyLegend(show = 'onmouseover', hideOnMouseOut = T) %>%
			dyRangeSelector()
	})  

	aggregateEnrol <- read.csv(file.path(getwd(),"../data",institution,"Enrolment Data","enrolmentData.csv"))
	output$aggregateEnrolmentData <- DT::renderDataTable(
		DT::datatable(
			aggregateEnrol, class = 'cell-border stripe', filter = 'top', colnames = c('Start Date' = 3,
			'Weeks' = 4,
			'Active Learners' = 8,
			'Returning Learners' = 9,
			'Social Learners' = 10,
			'Fully Participating Learners' = 11,
			'Statements Sold' = 12),
			 options = list(
				lengthMenu = list(c(5,15,25,-1),c('5','15','25','ALL')),
				pageLength = 15
			)
		)
	)

	output$totalJoiners <- renderValueBox({
		valueBox("Total Joiners", subtitle = sum(aggregateEnrol$Joiners), icon = icon("group"), color = "red")
	})
	output$totalLearners <- renderValueBox({
		learners <- subset(aggregateEnrol , Learners != "N/A")
		learners2 <- sapply(learners$Learners, function(x) strsplit(toString(x), "-"))
		learners3 <- sapply(learners2, function(x) as.numeric(x[[1]]))
		# learners <- as.numeric(unlist(strsplit(toString(subset(aggregateEnrol$Learners, aggregateEnrol$Learners != "N/A")), "-")))
		valueBox("Total Learners", subtitle = sum(learners3), icon = icon("group"), color = "red")
	})
	output$totalStatementsSold <- renderValueBox({
		valueBox("Total Statements Sold", subtitle = sum(aggregateEnrol$Statements.Sold), icon = icon("certificate"), color = "red")
	})

	output$stepsCompleted <- renderPlot({
		chartDependency()
		completedSteps <- subset(stepData, last_completed_at != "")
		completedSteps$week_step <- paste0(completedSteps$week_number,".", sprintf("%02d",as.integer(completedSteps$step_number)), sep = "")
		stepsCount <- count(completedSteps, 'week_step')
		p <- ggplot(stepsCount, aes(x = week_step,y = freq)) +
		geom_bar(stat = "identity",aes(fill = freq)) +
		xlab("Step") +
		ylab("Number of learners marked as complete") +
		theme(axis.text.x = element_text(angle = 90))
		print(p)
		})

	output$stepCompletionHeat <- renderD3heatmap({
		# Draw the chart when the "chooseCourseButton" is pressed by the user
		chartDependency()
		completedSteps <- subset(stepData, last_completed_at != "")
		completedSteps$week_step <- paste0(completedSteps$week_number,".", sprintf("%02d",as.integer(completedSteps$step_number)), sep = "")
		data <- completedSteps[,c("week_step", "last_completed_at")]
		data$last_completed_at <- unlist(lapply(data$last_completed_at, function(x) substr(x,1,10)))
		data$count <- 1
		aggregateData <- aggregate(count ~., data, FUN = sum)
		pivot <- dcast(aggregateData, last_completed_at ~ week_step)
		pivot[is.na(pivot)] <- 0
		map <- as.data.frame(pivot)
		print(d3heatmap(map[,2:ncol(map)],
			dendrogram = "none",
			scale = "column",
			color = "Blues",
			labRow = as.character(as.POSIXct(map[,1]), origin = "1970-01-01")))
	})

	getPage<-function() {
		return(includeHTML("funnel.html"))
	}
	
	#   output$funnel <- renderChart2({
	#     chartDependency()
	#     plotData <- getFunnelOfParticipation(enrolment_data, step_data, comments_data, assignments_data, 
	#                                          input$startDate, input$endDate)
	#     funnel <- Highcharts$new()
	#     funnel$plotOptions (
	#       funnel = list(
	#         neckWidth = "23%",
	#         neckHeight = "32%",
	#         width = "68%",
	#         dataLabels = list(
	#           enabled = "true",
	#           style = list(
	#             fontSize = "8px"
	#           )
	#         )
	#       )
	#     )
	#     funnel$series (
	#       data = list(
	#         list(plotData[1,1], plotData[1,2]),
	#         list(plotData[2,1], plotData[2,2]),
	#         list(plotData[3,1], plotData[3,2]),
	#         list(plotData[4,1], plotData[4,2]),
	#         list(plotData[5,1], plotData[5,2])
	#       ),
	#       type = "funnel",
	#       name = "learners"
	#     )
	#     return(funnel)
	#   })
	# 
	#   
	
	
	
	createFunnelChart <- function () {
		plotData <- getFunnelOfParticipation(enrolment_data, step_data, comments_data, assignments_data, 
																				 startDate, endDate)
		funnel <- Highcharts$new()
		funnel$plotOptions (
			funnel = list(
				neckWidth = "23%",
				neckHeight = "32%",
				width = "68%",
				dataLabels = list(
					enabled = "true",
					style = list(
						fontSize = "8px"
					)
				)
			)
		)
		funnel$series (
			data = list(
				list(plotData[1,1], plotData[1,2]),
				list(plotData[2,1], plotData[2,2]),
				list(plotData[3,1], plotData[3,2]),
				list(plotData[4,1], plotData[4,2]),
				list(plotData[5,1], plotData[5,2])
			),
			type = "funnel",
			name = "learners"
		)
		funnel$addAssets(js = "http://code.highcharts.com/modules/funnel.js")
		funnel$save("funnel.html", cdn = FALSE)
	}
}