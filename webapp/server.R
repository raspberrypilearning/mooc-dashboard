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
require(tm)
require(wordcloud)
require(DT)
require(R.utils)
require(RMySQL)
source("config.R")
source("learner_analysis.R")
source("learner_filters.R")
source("courses.R")
source("data_retrieval.R")

function(input, output, session) { 
	
	output$institution <- renderText({"soton"})
	output$pageTitle <- renderText("Welcome to the MOOC Dashboard! Select the course(s) and run(s) you wish to visualise")
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
		
		output$pageTitle <- renderText(paste(input$course1, "- [", substr(input$run1,1,1), "]",
		ifelse(input$run2 != "None",paste0(" vs ",input$course2,"- [", substr(input$run2,1,1), "]"),""),
		ifelse(input$run3 != "None",paste0(" vs ",input$course3,"- [", substr(input$run3,1,1), "]"),""),
		ifelse(input$run4 != "None",paste0(" vs ",input$course4,"- [", substr(input$run4,1,1), "]"),"")))
		
		updateTabsetPanel(session, "tabs", selected = "demographics")
		
		#FixMe - this could all go into a function - but check scope
		
		stepDataFiles <- getData("Activity")
		assign("step_data", stepDataFiles, envir = .GlobalEnv)

		commentsDataFiles <- getData("Comments")
		assign("comments_data", commentsDataFiles, envir = .GlobalEnv)

		quizDataFiles <- getData("Quiz")
		assign("quiz_data", quizDataFiles, envir = .GlobalEnv)

		assignmentsDataFiles <- getData("Assignments")
		assign("assignments_data", assignmentsDataFiles, envir = .GlobalEnv)

		reviewsDataFiles <- getData("Reviews")
		assign("reviews_data", reviewsDataFiles, envir = .GlobalEnv)

		enrolmentsDataFiles <- getData("Enrolments")
		assign("enrolment_data", enrolmentsDataFiles, envir = .GlobalEnv)

		courseMetaData <- getMetaData()
		assign("course_data", courseMetaData, envir = .GlobalEnv)

		# enrolmentDataFile <- file.path(getwd(),"../data",institution,input$course1,input$run1,"enrolments.csv")
		assign("pre_course_data", do.call("rbind",enrolment_data) , envir = .GlobalEnv)

		assign("allLearners", getAllLearners(enrolmentsDataFiles), envir = .GlobalEnv)

		assign("filtersEnabled", FALSE, envir = .GlobalEnv)
		updateTextInput(session, "filteredLearners", value = allLearners)

		
	}, priority = 10)

	getMetaData <- function(){
		data1 <- getCourseMetaData(input$course1,substr(input$run1,1,1))
		name <- paste(c(input$course1,substr(input$run1,1,1)), collapse = " - ")
		datasets <- list("1"= data1)
		names(datasets)[which(names(datasets) == "1")] <- name
		if(input$run2 != "None"){
			data2 <- getCourseMetaData(input$course2, substr(input$run2,1,1))
			datasets[[paste(c(input$course2,substr(input$run2,1,1)), collapse = " - ")]] <- data2
		}
		if(input$run3 != "None"){
			data3 <- getCourseMetaData(input$course3, substr(input$run3,1,1))
			datasets[[paste(c(input$course3,substr(input$run3,1,1)), collapse = " - ")]] <- data3
		}
		if(input$run4 != "None"){
			data4 <- getCourseMetaData(input$course4, substr(input$run4,1,1))
			datasets[[paste(c(input$course4,substr(input$run4,1,1)), collapse = " - ")]] <- data4
		}
		return(datasets)
	}

	getData <- function(table){
		data1 <- getTable(table, input$course1,input$run1)
		name <- paste(c(input$course1,substr(input$run1,1,1)), collapse = " - ")
		datasets <- list("1"= data1)
		names(datasets)[which(names(datasets) == "1")] <- name
		if(input$run2 != "None"){
			data2 <- getTable(table, input$course2,input$run2)
			datasets[[paste(c(input$course2,substr(input$run2,1,1)), collapse = " - ")]] <- data2
		}
		if(input$run3 != "None"){
			data3 <- getTable(table, input$course3,input$run3)
			datasets[[paste(c(input$course3,substr(input$run3,1,1)), collapse = " - ")]] <- data3
		}
		if(input$run4 != "None"){
			data4 <- getTable(table, input$course4,input$run4)
			datasets[[paste(c(input$course4,substr(input$run4,1,1)), collapse = " - ")]] <- data4
		}
		return(datasets)
	}

	aggregateEnrol <- read.csv(file.path(getwd(),"../data",institution,"Courses Data","Deets","Courses-Data.csv"))
	assign("aggregateEnrol", aggregateEnrol, envir = .GlobalEnv) 
	
	chartDependency <- eventReactive(input$chooseCourseButton, {})
	stepDependancy <- eventReactive(input$runChooserSteps, {})
	commentDependancy <- eventReactive(input$runChooserComments, {})

	
	#START: COURSE SELECTION UI AND VALUE BOXES
	
	print("About to assemble runs")
	output$runs1 <-renderUI({
		runs <- getRuns(input$course1)
		selectInput("run1", label = "Run", width = "450px", choices = c("All",runs))
	})
	output$runs2 <-renderUI({
		runs <- getRuns(input$course2)
		selectInput("run2", label = "Run", width = "450px", choices = c("None","All",runs))
	})
	output$runs3 <-renderUI({
		runs <- getRuns(input$course3)
		selectInput("run3", label = "Run", width = "450px", choices = c("None","All",runs))
	})
	output$runs4 <-renderUI({
		runs <- getRuns(input$course4)
		selectInput("run4", label = "Run", width = "450px", choices = c("None","All",runs))
	})
	
	output$chooseCourse <- renderUI({
		actionButton("chooseCourseButton", label = "Go")
	})
	
	output$enrolmentCount <- renderValueBox({
		chartDependency()
		learners <- unlist(strsplit(input$filteredLearners, "[,]"))
		count <- getEnrolmentCount(learners, startDate, endDate, enrolment_data$a)   
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
		stream <- getSetOfLearnersByDate(courseDates[[3]], courseDates[[1]], enrolment_data$a)
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

	output$learnersAgeBar <- renderChart2({
		chartDependency()

		data <- data.frame(levels = c("<18","18-25","26-35","36-45","46-55","56-65",">65"))
		data$levels <- as.character(data$levels)
		for(x in names(enrolment_data)){
			ageCount <- getLearnerAgeCount(enrolment_data[[x]])
			data[[x]] <- numeric(7)
			for(i in c(1:length(ageCount$age_group))){
				data[[x]][which(data$levels == ageCount$age_group[i])] <- ageCount$percentage[i]
			}
		}

		a <- rCharts:::Highcharts$new()
		a$chart(type = "column", width = 750)
		a$xAxis(categories = data$levels)
		a$yAxis(title = list(text = "Percentage of Population"))
		a$data(data[c(names(enrolment_data))])
		a$colors('#7cb5ec', '#434348','#8085e9','#00ffcc')
		a$plotOptions(
			column = list(
				dataLabels = list(
				enabled = "true"
				),
				animation = FALSE
			)
		)
		return(a)
	})

	output$learnersGender <- renderChart2({
		chartDependency()
		data <- data.frame(levels = c("male","female","other","non-binary"))
		data$levels <- as.character(data$levels)

		for(x in names(enrolment_data)){
			genderCount <- getGenderCount(enrolment_data[[x]])
			data[[x]] <- numeric(4)
			for(i in c(1:length(genderCount$gender))){
				data[[x]][which(data$levels == genderCount$gender[i])] <- genderCount$percentage[i]
			}
		}
		data <- data[order(-data[[names(enrolment_data[1])]]),]

		a <- rCharts:::Highcharts$new()
		a$chart(type = "column", width = 350)
		a$xAxis(categories = data$levels)
		a$yAxis(title = list(text = "Percentage of Population"))
		a$data(data[c(names(enrolment_data))])
		a$colors('#7cb5ec', '#434348','#8085e9','#00ffcc')
		a$plotOptions(
			column = list(
				dataLabels = list(
					enabled = "true"
				),
				animation = FALSE
			)
		)
		return(a)
	})

	output$employmentBar <-renderChart2({
		chartDependency()
		data <- data.frame(area = as.character(c("accountancy_banking_and_finance","armed_forces_and_emergency_services",
										 "business_consulting_and_management","charities_and_voluntary_work" ,"creative_arts_and_culture",
										 "energy_and_utilities","engineering_and_manufacturing","environment_and_agriculture","health_and_social_care",
										 "hospitality_tourism_and_sport","it_and_information_services","law","marketing_advertising_and_pr","media_and_publishing",               
										 "property_and_construction","public_sector","recruitment_and_pr","retail_and_sales",
										 "science_and_pharmaceuticals","teaching_and_education","transport_and_logistics")))
		data$area <- as.character(data$area)

		for(x in names(enrolment_data)){
		  areaCount <- getEmploymentAreaCount(enrolment_data[[x]])
		  data[[x]] <- numeric(21)
		  for(i in c(1:length(areaCount$employment))){
			data[[x]][which(data$area == areaCount$employment[i])] <- areaCount$percentage[i]
		  }
		}
		data <- data[order(-data[[names(enrolment_data[1])]]),]
		a <- rCharts:::Highcharts$new()
		a$chart(type = "bar", width = 1200, height = 650)
		a$data(data[c(names(enrolment_data))])
		a$colors('#7cb5ec', '#434348','#8085e9','#00ffcc')
		a$xAxis(categories = gsub( "_"," ",(data$area)))
		a$yAxis(title = list(text = "Percentage of Population"))
		a$plotOptions(
		  bar = list(
			dataLabels = list(
			  enabled = "true"
			),
			animation = FALSE
		  )
		)
		return(a)
	})	

	output$employmentStatus <- renderChart2({
		chartDependency()

		data <- data.frame(levels = as.character(c("unemployed","working_full_time","working_part_time","retired",
			"not_working","full_time_student","self_employed","looking_for_work")))
		data$levels <- as.character(data$levels)
		for(x in names(enrolment_data)){
			statusCount <- getEmploymentStatusCount(enrolment_data[[x]])
			data[[x]] <- numeric(8)
			for(i in c(1:length(statusCount$status))){
			data[[x]][which(data$levels == statusCount$status[i])] <- statusCount$percentage[i]
		  }
		}
		
		data <- data[order(-data[[names(enrolment_data[1])]]),]

		a <- rCharts:::Highcharts$new()
		a$chart(type = "bar", width = 1200, height = 650)
		a$data(data[c(names(enrolment_data))])
		a$colors('#7cb5ec', '#434348','#8085e9','#00ffcc')
		a$xAxis(categories = gsub( "_"," ",unlist(data$levels)))
		a$yAxis(title = list(text = "Percentage of Population"))
		a$plotOptions(
			bar = list(
				dataLabels = list(
				enabled = "true"
				),
				animation = FALSE
			)
		)
		return(a)
	})
	
	output$degreeLevel <- renderChart2({
		chartDependency()
		data <- data.frame(level = c("apprenticeship","less_than_secondary","professional","secondary",           
		"tertiary","university_degree","university_masters","university_doctorate"))
		data$level <- as.character(data$level)

		for(x in names(enrolment_data)){
		  degreeCount <- getEmploymentDegreeCount(enrolment_data[[x]])
		  data[[x]] <- numeric(8)
		  for(i in c(1:length(degreeCount$degree))){
			data[[x]][which(data$level == degreeCount$degree[i])] <- degreeCount$percentage[i]
		  }
		}


		a <- rCharts:::Highcharts$new()
		a$chart(type = "column", width = 1200, height = 650)
		a$data(data[c(names(enrolment_data))])
		a$colors('#7cb5ec', '#434348','#8085e9','#00ffcc')
		a$xAxis(categories = gsub( "_"," ",data$level))
		a$yAxis(title = list(text = "Percentage of Population"))
		a$plotOptions(
			column = list(
				dataLabels = list(
					enabled = "true"
				),
				animation = FALSE
			)
		)
		return(a)
	})
	
	output$learnerMap <- renderGvis({
		chartDependency()
		
		data <- getLearnersByCountry(pre_course_data[which(pre_course_data$country != "Unknown"), ])
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
													width = 1100,
													height = 600,
													keepAspectRatio = "false",
													colorAxis = "{colors:['#91BFDB', '#FC8D59']}"
												)
		)
		return (map)
	})

	output$HDIColumn <- renderChart2({
		chartDependency()
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

		chart <- Highcharts$new()
		chart$chart(type = 'column', width = 1200)
		chart$data(data[c(names(enrolment_data))])
		chart$colors('#7cb5ec', '#434348','#8085e9','#00ffcc')
		chart$xAxis(categories = data$levels)
		chart$yAxis(title = list(text = "Percentage of Population"))
		chart$plotOptions(
		  column = list(
			dataLabels = list(
			  enabled = "true"
			),
			animation = FALSE
		  )
		)
		return(chart)
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
		histogram$chart (width = 380)
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
		histogram$chart (width = 380)
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
		histogram$chart (width = 380)
		
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
		histogram$chart (width = 380)
		
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
		histogram$chart (width = 380)
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
		histogram$chart (width = 380)
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

	output$commentsBarChart <- renderChart2({
		chartDependency()
		commentDependancy()
		plotData <- getCommentsBarChart(step_data[[which(names(step_data) == input$runChooserComments)]],comments_data[[which(names(comments_data)==input$runChooserComments)]])
		histogram <- Highcharts$new()
		histogram$chart(type = "column" , width = 1200)
		histogram$data(plotData[,c("reply","post")])
		histogram$xAxis (categories = plotData$week_step)
		histogram$yAxis(title = list(text = "Frequency"))
		histogram$plotOptions (
			column = list(
				stacking = "normal"
			),
			animation = FALSE
		)
		return(histogram)
	})

	# Heatmap of comments made per step and date
	output$stepDateCommentsHeat <- renderD3heatmap({
		# Draw the chart when the "chooseCourseButton" is pressed by the user
		chartDependency()
		commentDependancy()
		learners <- unlist(strsplit(input$filteredLearners, "[,]"))
		startDate <- course_data[[which(names(course_data) == input$runChooserComments)]]$start_date
		comments <- getCommentsHeatMap(comments_data[[which(names(comments_data) == input$runChooserComments)]], startDate)

		
		d3heatmap(comments[,2:ncol(comments)], dendrogram = "none", 
							color = "Blues",
							scale = "column",
							labRow = as.character(as.POSIXct(comments[,1], origin = "1970-01-01")),
							labCol = colnames(comments)[-1])
	})
	
	# Histogram of the comment and replies made per week
	output$commentsRepliesWeekBar <- renderChart2({
		chartDependency()
		commentDependancy()
		plotData <- getCommentsBarChartWeek(comments_data[[which(names(comments_data)==input$runChooserComments)]])
		
		histogram <- Highcharts$new()
		histogram$chart(type = "column" , width = 550)
		histogram$data(plotData[,c("reply","post")])
		histogram$xAxis (categories = plotData$week_number)
		histogram$yAxis(title = list(text = "Frequency"))
		histogram$plotOptions (
			column = list(
				stacking = "normal"
			),
			animation = FALSE
		)
		return(histogram)
	})
	
	# Histogram of the number of authors per week
	output$authorsWeekBar <- renderChart2({
		chartDependency()
		commentDependancy()
		plotData <- getNumberOfAuthorsByWeek(comments_data[[which(names(comments_data)==input$runChooserComments)]])
		histogram <- Highcharts$new()
		histogram$chart(type = "column" , width = 550)
		histogram$data(plotData[,c("authors")])
		histogram$xAxis (categories = plotData$week_number)
		histogram$yAxis(title = list(text = "Frequency"))
		histogram$plotOptions (
			column = list(
				stacking = "normal"
			),
			animation = FALSE
		)
		return(histogram)
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
		lineChart$chart (type = "line", width = 380, height = 210)
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
		scatter$chart (width = 1500)
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

	output$aggregateEnrolmentData <- renderDataTable({

		aggregateEnrol <- aggregateEnrol[, !(colnames(aggregateEnrol) %in% c("course","course_run"))]
		aggregateEnrol$run_id <- gsub( "-", " ", as.character(aggregateEnrol$run_id))
		aggregateEnrol$run_id <- capitalize(aggregateEnrol$run_id)
		aggregateEnrol <- aggregateEnrol[order(aggregateEnrol$run_id),]
		aggregateEnrol$start_date <- as.Date(aggregateEnrol$start_date)

		DT::datatable(
			aggregateEnrol, class = 'cell-border stripe', filter = 'top', extensions = 'Buttons',
			colnames = c('Course' = 1,
			'Start Date' = 2,
			'Weeks' = 3,
			'Joiners' = 4,
			'Leavers (Joiners who leave the course)' = 5,
			'Learners (Joiners who view a step)' = 6,
			'Active Learners (Learners who mark as complete)' = 7,
			'Returning Learners (Learners who mark as complete in two weeks)' = 8,
			'Social Learners (Learners who make comments)' = 9,
			'Fully Participating Learners (Learners who complete 50% of steps + assements)' = 10,
			'Statements Sold' = 11),
			options = list(
				lengthMenu = list(c(10,20,30,-1),c('10','20','30','All')),
				pageLength = 20,
				dom = 'lfrtBip',
				buttons = list(
					"print",
					list(
						extend = 'pdf',
						filename = paste(institution,'Mooc Enrolment Data', Sys.Date()),
						orientation = 'landscape',
						text = 'Download PDF'),
					list(
						extend = 'excel',
						filename = paste(institution,'Mooc Enrolment Data', Sys.Date()),
						text = 'Download Excel'
					)
				)
			),
			rownames = FALSE
		)
	})

	output$totalJoiners <- renderValueBox({
		valueBox("Total Joiners", subtitle = sum(aggregateEnrol$joiners), icon = icon("group"), color = "red")
	})

	output$totalLearners <- renderValueBox({
		learners <- subset(aggregateEnrol , learners != "N/A")
		learners2 <- sapply(learners$learners, function(x) strsplit(toString(x), "-"))
		learners3 <- sapply(learners2, function(x) as.numeric(x[[1]]))
		valueBox("Total Learners", subtitle = sum(learners3), icon = icon("group"), color = "red")
	})

	output$totalStatementsSold <- renderValueBox({
		valueBox("Total Statements Sold", subtitle = sum(aggregateEnrol$statements_sold), icon = icon("certificate"), color = "red")
	})

	output$runSelectorSteps <- renderUI({
		chartDependency()
		runs <- paste(input$course1,substr(input$run1,1,1), sep = " - ")
		if(input$run2 != "None"){
			runs <- c(runs, paste(input$course2,substr(input$run2,1,1), sep = " - "))
		}
		if(input$run3 != "None"){
			runs <- c(runs, paste(input$course3,substr(input$run3,1,1), sep = " - "))
		}
		if(input$run4 != "None"){
			runs <- c(runs, paste(input$course4,substr(input$run4,1,1), sep = " - "))
		}
		print(selectInput("runChooserSteps", label = "Run", choices = runs, width = "550px"))
	})

	
	output$stepsCompleted <- renderChart2({
		chartDependency()
		stepDependancy()
		stepsCount <- getStepsCompletedData(step_data[[which(names(step_data) == input$runChooserSteps)]])
		a <- rCharts:::Highcharts$new()
		a$chart(type = "column", width = 1200)
		a$data(stepsCount[c("freq")])
		a$xAxis(categories = unlist(as.factor(stepsCount[,c("week_step")])))
		a$yAxis(title = list(text = "Frequency"))
		a$plotOptions(
			column = list(
				animation = FALSE
			)
		)
		return(a)
	})

	output$stepCompletionHeat <- renderD3heatmap({
		chartDependency()
		stepDependancy()
		startDate <- course_data[[which(names(course_data) == input$runChooserSteps)]]$start_date
		map <- getStepCompletionHeatMap(step_data[[which(names(step_data) == input$runChooserSteps)]], startDate)
		print(d3heatmap(map[,2:ncol(map)],
			dendrogram = "none",
			scale = "column",
			color = "Blues",
			labRow = as.character(as.POSIXct(map[,1]), origin = "1970-01-01")
			)
		)
	})

	output$firstVisitedHeat <- renderD3heatmap({
		chartDependency()
		stepDependancy()
		startDate <- course_data[[which(names(course_data) == input$runChooserSteps)]]$start_date
		map <- getFirstVisitedHeatMap(step_data[[which(names(step_data) == input$runChooserSteps)]], startDate)
		print(d3heatmap(map[,2:ncol(map)],
			dendrogram = "none",
			scale = "column",
			color = "Blues",
			labRow = as.character(as.POSIXct(map[,1]), origin = "1970-01-01")
			)
		)
	})

	output$runSelectorComments <- renderUI({
		chartDependency()
		runs <- paste(input$course1,substr(input$run1,1,1), sep = " - ")
		if(input$run2 != "None"){
			runs <- c(runs, paste(input$course2,substr(input$run2,1,1), sep = " - "))
		}
		if(input$run3 != "None"){
			runs <- c(runs, paste(input$course3,substr(input$run3,1,1), sep = " - "))
		}
		if(input$run4 != "None"){
			runs <- c(runs, paste(input$course4,substr(input$run4,1,1), sep = " - "))
		}
		print(selectInput("runChooserComments", label = "Run", choices = runs, width = "550px"))
	})

	

	output$runSelector <- renderUI({
		chartDependency()
		runs <- paste(input$course1,substr(input$run1,1,1), sep = " - ")
		if(input$run2 != "None"){
			runs <- c(runs, paste(input$course2,substr(input$run2,1,1), sep = " - "))
		}
		if(input$run3 != "None"){
			runs <- c(runs, paste(input$course3,substr(input$run3,1,1), sep = " - "))
		}
		if(input$run4 != "None"){
			runs <- c(runs, paste(input$course4,substr(input$run4,1,1), sep = " - "))
		}
		print(selectInput("runChooser", label = "Run", choices = runs, width = "550px"))
	})

	output$viewButton <- renderUI({
		chartDependency()
		print(actionButton("viewButton","View Comments"))
	})

	output$loadCloud <- renderUI({
		chartDependency()
		print(actionButton("loadCloud", "Load Cloud"))
	})

	viewPressed <- eventReactive(input$viewButton, {
		return(input$runChooser)
	})

	output$commentViewer <- renderDataTable({
		chartDependency()
		viewPressed()
		if(input$viewButton == 0){
			return()
		}
		withProgress(message = "Processing Comments",{
			data <- getCommentViewerData(comments_data, viewPressed())
			DT::datatable(
				data[,c("course","timestamp","week_step","text","thread","likes")], class = 'cell-border stripe', filter = 'top', extensions = 'Buttons',
				colnames = c(
					"Course" = 1,
					"Date" = 2,
					"Step" = 3,
					"Comment" = 4,
					"Part of a Thread?" = 5,
					"Likes" = 6
				),
				options = list(
					scrollY = "700px",
					lengthMenu = list(c(10,20,30),c('10','20','30')),
					pageLength = 20,
					dom = 'lfrtBip',
					buttons = list(
						"print", 
						list(
							extend = 'pdf',
							filename = 'Comments',
							text = 'Download pdf'
							),
						list(
							extend = 'excel',
							filename = 'Comments',
							text = 'Download Excel'
						)
					)
				),
				rownames = FALSE,
				selection = 'single'
			)
		})
	})

	threadSelected <- eventReactive( input$commentViewer_rows_selected, {
		runif(input$commentViewer_rows_selected)
	})

	output$threadViewer <- renderDataTable({
		chartDependency()
		viewPressed()
		threadSelected()
		data <- getCommentViewerData(comments_data, viewPressed())
		selectedRow <- data[input$commentViewer_rows_selected,]
		if(selectedRow$thread != "Yes"){
			return()
		}
		reply = TRUE
		parent = FALSE
		if(is.na(selectedRow$parent_id)){
			reply = FALSE
			parent = TRUE
		}
		if(parent){
			rows <- data[c(which(data$id == selectedRow$id), which(data$parent_id == selectedRow$id)),]
		} else {
			rows <- data[c(which(data$id == selectedRow$parent_id), which(data$parent_id == selectedRow$parent_id),  which(data$id == selectedRow$id)),]
		}

		rows <- rows[order(rows$timestamp),]

		DT::datatable(
			rows[,c("course","timestamp","week_step","text","likes")], class = 'cell-border stripe', extensions = 'Buttons',
			colnames = c(
				"Course" = 1,
				"Date" = 2,
				"Step" = 3,
				"Comment" = 4,
				"Likes" = 5
			),
			options = list(
				scrollY = "700px",
				lengthMenu = list(c(10,20,30),c('10','20','30')),
				pageLength = 20,
				dom = 'lfrtBip',
				buttons = list(
					"print", 
					list(
						extend = 'pdf',
						filename = 'Comment Thread',
						text = 'Download pdf'
					),
					list(
						extend = 'excel',
						filename = 'Comment Thread',
						text = 'Download Excel'
					)
				)
			),
			rownames = FALSE
		)
	})

	wordcloud_rep <- repeatable(wordcloud)

	terms <- reactive({
		isolate({
			withProgress(message = "Processing Word Cloud",{
				data <- comments_data[[which(names(comments_data) == input$runChooser)]]
				data$week_step <- getWeekStep(data)
				# stepChoice <- input$stepChoice
				# if(stepChoice != "All"){
				# 	data <- subset(data, data$week_step == stepChoice)
				# }
				data <- data[c("text","likes")]
				data$likes <- as.numeric(data$likes)
				data <- data[order(-data$likes),]
				text <- unlist(strsplit(toString(data$text),"[\n]"))
				myCorpus = Corpus(VectorSource(head(text,1000)))
				myCorpus = tm_map(myCorpus, content_transformer(tolower))
				myCorpus = tm_map(myCorpus, removePunctuation)
				myCorpus = tm_map(myCorpus, removeNumbers)
				myCorpus = tm_map(myCorpus, removeWords,
				                  c(stopwords("SMART")))
				myDTM = TermDocumentMatrix(myCorpus,
				                           control = list(minWordLength = 1))
				m = as.matrix(myDTM)
				m <- sort(rowSums(m), decreasing = TRUE)
			})
		})
	})

	cloudDependancy <- eventReactive(input$loadCloud, {})

	output$stepWordCloud <- renderPlot({
		chartDependency()
		cloudDependancy()
		m <- terms()
		wordcloud_rep(names(m),m,scale = c(4,0.5),
			min.freq = input$commentCloudFreq,
			max.words = input$commentCloudMax,
			colors = brewer.pal(8,"Dark2"),
			rot.per = 0)
	})

	output$AllvsFPvsStateGenderColumn <- renderChart2({
		chartDependency()
		data <- data.frame(levels = c("male","female","other","non-binary"))
		data$levels <- as.character(data$levels)

		for(x in names(enrolment_data)){
		  statementsSoldCount <- getSurveyResponsesFromStatementBuyers(enrolment_data[[x]])
		  statementsSoldCount <- getGenderCount(statementsSoldCount)
		  print(statementsSoldCount)
		  
		  data[[x]] <- numeric(4)
		  for(i in c(1:length(statementsSoldCount$gender))){
			data[[x]][which(data$levels == statementsSoldCount$gender[i])] <- statementsSoldCount$percentage[i]
		  }
		}

		data <- data[order(-data[[names(enrolment_data[1])]]),]

		a <- rCharts:::Highcharts$new()
		a$chart(type = "column", width = 350)
		a$xAxis(categories = data$levels)
		a$yAxis(title = list(text = "Percentage of Population"))
		a$data(data[c(names(enrolment_data))])
		a$colors('#7cb5ec', '#434348','#8085e9','#00ffcc')
		a$plotOptions(
		  column = list(
			dataLabels = list(
			  enabled = "true"
			),
			animation = FALSE
		  )
		)
		return(a)
	})

	output$AllvsFPvsStateAgeBar <- renderChart2({
		chartDependency()

		data <- data.frame(levels = c("<18","18-25","26-35","36-45","46-55","56-65",">65"))
		data$levels <- as.character(data$levels)
		for(x in names(enrolment_data)){
			ageCount <- getSurveyResponsesFromStatementBuyers(enrolment_data[[x]])
			ageCount <- getLearnerAgeCount(ageCount)
			data[[x]] <- numeric(7)
			for(i in c(1:length(ageCount$age_group))){
				data[[x]][which(data$levels == ageCount$age_group[i])] <- ageCount$percentage[i]
			}
		}

		a <- rCharts:::Highcharts$new()
		a$chart(type = "column", width = 750)
		a$xAxis(categories = data$levels)
		a$yAxis(title = list(text = "Percentage of Population"))
		a$data(data[c(names(enrolment_data))])
		a$colors('#7cb5ec', '#434348','#8085e9','#00ffcc')
		a$plotOptions(
			column = list(
				dataLabels = list(
				enabled = "true"
				),
				animation = FALSE
			)
		)
		return(a)
	})

	output$AllvsFPvsStateEmploymentAreaBar <- renderChart2({
		chartDependency()

		chartDependency()
		data <- data.frame(area = as.character(c("accountancy_banking_and_finance","armed_forces_and_emergency_services",
										 "business_consulting_and_management","charities_and_voluntary_work" ,"creative_arts_and_culture",
										 "energy_and_utilities","engineering_and_manufacturing","environment_and_agriculture","health_and_social_care",
										 "hospitality_tourism_and_sport","it_and_information_services","law","marketing_advertising_and_pr","media_and_publishing",               
										 "property_and_construction","public_sector","recruitment_and_pr","retail_and_sales",
										 "science_and_pharmaceuticals","teaching_and_education","transport_and_logistics")))
		data$area <- as.character(data$area)

		for(x in names(enrolment_data)){
			areaCount <- getSurveyResponsesFromStatementBuyers(enrolment_data[[x]])
			areaCount <- getEmploymentAreaCount(areaCount)
			data[[x]] <- numeric(21)
			for(i in c(1:length(areaCount$employment))){
			data[[x]][which(data$area == areaCount$employment[i])] <- areaCount$percentage[i]
		  }
		}
		data <- data[order(-data[[names(enrolment_data[1])]]),]
		a <- rCharts:::Highcharts$new()
		a$chart(type = "bar", width = 1200, height = 650)
		a$data(data[c(names(enrolment_data))])
		a$colors('#7cb5ec', '#434348','#8085e9','#00ffcc')
		a$xAxis(categories = gsub( "_"," ",(data$area)))
		a$yAxis(title = list(text = "Percentage of Population"))
		a$plotOptions(
		  bar = list(
			dataLabels = list(
			  enabled = "true"
			),
			animation = FALSE
		  )
		)
		return(a)
	})

	output$AllvsFPvsStateEmploymentStatusBar <- renderChart2({
		chartDependency()

		data <- data.frame(levels = as.character(c("unemployed","working_full_time","working_part_time","retired",
			"not_working","full_time_student","self_employed","looking_for_work")))
		data$levels <- as.character(data$levels)
		for(x in names(enrolment_data)){
			statusCount <- getSurveyResponsesFromStatementBuyers(enrolment_data[[x]])
			statusCount <- getEmploymentStatusCount(statusCount)
			data[[x]] <- numeric(8)
			for(i in c(1:length(statusCount$status))){
			data[[x]][which(data$levels == statusCount$status[i])] <- statusCount$percentage[i]
		  }
		}

		data <- data[order(-data[[names(enrolment_data[1])]]),]

		a <- rCharts:::Highcharts$new()
		a$chart(type = "bar", width = 1200, height = 650)
		a$data(data[c(names(enrolment_data))])
		a$colors('#7cb5ec', '#434348','#8085e9','#00ffcc')
		a$xAxis(categories = gsub( "_"," ",unlist(data$levels)))
		a$yAxis(title = list(text = "Percentage of Population"))
		a$plotOptions(
			bar = list(
				dataLabels = list(
				enabled = "true"
				),
				animation = FALSE
			)
		)
		return(a)
	})

	output$AllvsFPvsStateDegreeBar <- renderChart2({
		chartDependency()
		data <- data.frame(level = c("apprenticeship","less_than_secondary","professional","secondary",           
		"tertiary","university_degree","university_masters","university_doctorate"))
		data$level <- as.character(data$level)

		for(x in names(enrolment_data)){
			degreeCount <- getSurveyResponsesFromStatementBuyers(enrolment_data[[x]])
			degreeCount <- getEmploymentDegreeCount(degreeCount)
			data[[x]] <- numeric(8)
			for(i in c(1:length(degreeCount$degree))){
				data[[x]][which(data$level == degreeCount$degree[i])] <- degreeCount$percentage[i]
			}
		}


		a <- rCharts:::Highcharts$new()
		a$chart(type = "column", width = 1200, height = 650)
		a$data(data[c(names(enrolment_data))])
		a$colors('#7cb5ec', '#434348','#8085e9','#00ffcc')
		a$xAxis(categories = gsub( "_"," ",data$level))
		a$yAxis(title = list(text = "Percentage of Population"))
		a$plotOptions(
			column = list(
				dataLabels = list(
					enabled = "true"
				),
				animation = FALSE
			)
		)
		return(a)
	})

	output$statementLearnerMap <- renderGvis({
		chartDependency()
		
		data <- getLearnersByCountry(pre_course_data[which(pre_course_data$country != "Unknown"), ])
		data <- data[which(data$purchased_statement_at != ""),]
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
													width = 1100,
													height = 600,
													keepAspectRatio = "false",
													colorAxis = "{colors:['#91BFDB', '#FC8D59']}"
												)
		)
		return (map)
	})

	output$allvsFPvsStateHDIColumn <- renderChart2({
		chartDependency()
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
		chart <- Highcharts$new()
		chart$chart(type = 'column', width = 1200)
		chart$data(data[c(names(enrolment_data))])
		chart$colors('#7cb5ec', '#434348','#8085e9')
		chart$xAxis(categories = data$levels)
		chart$yAxis(title = list(text = "Percentage of Population"))
		chart$plotOptions(
			column = list(
				dataLabels = list(
					enabled = "true"
				)
			)
		)
		return(chart)
	})

	output$signUpsLine <- renderChart2({
		chartDependency()
		freqs <- list()
		maxLength <- 0
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
		chart <- Highcharts$new()
		chart$chart(type = "line", width = 1200)
		chart$data(data[c(names(enrolment_data))])
		chart$colors('#7cb5ec', '#434348','#8085e9','#00ffcc')
		chart$xAxis(categories = data$day)
		chart$yAxis(title = list(text = "Frequency"))
		return(chart)
	})

	output$statementsSoldLine <- renderChart2({
		chartDependency()

		freqs <- list()

		maxLength <- 0
		for(i in c(1:length(names(enrolment_data)))){
			learners <- enrolment_data[[names(enrolment_data)[i]]]
			learners <- learners[which(learners$role == "learner"),]
			learners <- learners[which(learners$purchased_statement_at != ""),]
			signUpCount <- count(substr(as.character(learners$purchased_statement_at),start = 1, stop = 10))
			dates <- list(seq.Date(from = as.Date(signUpCount$x[1]), to = as.Date(tail(signUpCount$x, n =1)), by = 1) , numeric())
			if(length(dates[[1]]) > maxLength){
				maxLength <- length(dates[[1]])
			}
			for(x in c(1:length(signUpCount$x))){
				dates[[2]][[which(dates[[1]] == as.Date(signUpCount$x[x]))]] <- signUpCount$freq[[x]]
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
			data[[names(enrolment_data[x])]] <- d
		}

		chart <- Highcharts$new()
		chart$chart(type = "line", width = 1200)
		chart$data(data[c(names(enrolment_data))])
		chart$colors('#7cb5ec', '#434348','#8085e9','#00ffcc')
		chart$xAxis(categories = data$day)
		chart$yAxis(title = list(text = "Frequency"))
		return(chart)
	})

	output$debug <- renderText({
		chartDependency()
		print(unlist(getNumberOfAuthorsByWeek(comments_data[[1]])))
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
	
	
	
	# createFunnelChart <- function () {
	# 	plotData <- getFunnelOfParticipation(enrolment_data, step_data, comments_data, assignments_data, 
	# 																			 startDate, endDate)
	# 	funnel <- Highcharts$new()
	# 	funnel$plotOptions (
	# 		funnel = list(
	# 			neckWidth = "23%",
	# 			neckHeight = "32%",
	# 			width = "68%",
	# 			dataLabels = list(
	# 				enabled = "true",
	# 				style = list(
	# 					fontSize = "8px"
	# 				)
	# 			)
	# 		)
	# 	)
	# 	funnel$series (
	# 		data = list(
	# 			list(plotData[1,1], plotData[1,2]),
	# 			list(plotData[2,1], plotData[2,2]),
	# 			list(plotData[3,1], plotData[3,2]),
	# 			list(plotData[4,1], plotData[4,2]),
	# 			list(plotData[5,1], plotData[5,2])
	# 		),
	# 		type = "funnel",
	# 		name = "learners"
	# 	)
	# 	funnel$addAssets(js = "http://code.highcharts.com/modules/funnel.js")
	# 	funnel$save("funnel.html", cdn = FALSE)
	# }


}