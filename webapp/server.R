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

source("learner_filters.R")
source("courses.R")
source("data_retrieval.R")

jscode <- "
shinyjs.collapse = function(boxid) {
$('#' + boxid).closest('.box').find('[data-widget=collapse]').click();
}
"

#' Title
#'
#' @param input 
#' @param output 
#' @param session 
#'
#' @return
#' @export
#'
#' @examples
function(input, output, session) { 
  source("learner_analysis.R", local=TRUE)
  output$institution <- renderText({"soton"})
  output$pageTitle <- renderText("Welcome to the MOOC Dashboard! Select the course(s) and run(s) you wish to visualise")
  # output$updatedTime <- renderText(paste("Data last updated  -  ",getUpdatedTime()))
  
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
  
  # Load the meta data.
  courseMetaData <- getCourseMetaData()
  
  # Load the necessary data from the SQL database for each of the runs, store the types of data,
  # step data, comment data, enrolment data, quiz data, review data, course meta data, team data for each of the 
  # runs in a list of data frames
  # Executes after user has clicked the "chooseCourseButton"
  step_data <- NULL
  comments_data <- NULL
  quiz_data <- NULL
  assignments_data <- NULL
  reviews_data <- NULL
  enrolment_data <- NULL
  course_data <- NULL
  team_data <- NULL
  
  observeEvent(input$chooseCourseButton, {
    
    withProgress(message = "Loading Data", value = 0, {
      
      #Updates the page title to contain the courses and runs selected
      output$pageTitle <- renderText(paste(input$course1, "- [", substr(input$run1,1,1), "]",
                                           ifelse(input$run2 != "None",paste0(" vs ",input$course2,"- [", substr(input$run2,1,1), "]"),""),
                                           ifelse(input$run3 != "None",paste0(" vs ",input$course3,"- [", substr(input$run3,1,1), "]"),""),
                                           ifelse(input$run4 != "None",paste0(" vs ",input$course4,"- [", substr(input$run4,1,1), "]"),"")))
      
      #Updates the app to show the demographics page after loading a course
      updateTabsetPanel(session, "tabs", selected = "demographics")
      
      #FixMe - this could all go into a function - but check scope
      
      #number of steps in the loading part
      n <- 9
      
      #getting the data from the database and storing it into a global variable
      #updating the loading progress
      #same process repeated for each variable
      stepDataFiles <- getData("Activity")
      step_data <<- stepDataFiles
      incProgress(1/n, detail = "Loaded Step Data")
      
      commentsDataFiles <- getData("Comments")
      comments_data <<- commentsDataFiles
      incProgress(1/n, detail = "Loaded Comment Data")
      
      quizDataFiles <- getData("Quiz")
      quiz_data <<- quizDataFiles
      incProgress(1/n, detail = "Loaded Quiz Data")
      
      assignmentsDataFiles <- getData("Assignments")
      assignments_data <<- assignmentsDataFiles
      incProgress(1/n, detail = "Loaded assignment Data")
      
      reviewsDataFiles <- getData("Reviews")
      reviews_data <<- reviewsDataFiles
      incProgress(1/n, detail = "Loaded Review Data")
      
      enrolmentsDataFiles <- getData("Enrolments")
      enrolment_data <<- enrolmentsDataFiles
      incProgress(1/n, detail = "Loaded Enrolments Data")
      
      courseMetaData <- getCourseData()
      course_data <<- courseMetaData
      incProgress(1/n, detail = "Loaded Meta Data")
      
      teamDataFiles <- getAllTableData("TeamMembers")
      team_data <<- teamDataFiles
      incProgress(1/n, detail = "Loaded Team Members Data")
      
      assign("pre_course_data", do.call("rbind",enrolment_data) , envir = .GlobalEnv)
      assign("allLearners", getAllLearners(enrolmentsDataFiles), envir = .GlobalEnv)
      assign("filtersEnabled", FALSE, envir = .GlobalEnv)
      updateTextInput(session, "filteredLearners", value = allLearners)
      
      incProgress(1/n, detail = "Finished")
      
    })
    
  }, priority = 10)
  
  
  
  
  # Runs SQL queries for each of the selected runs with the sql table to query as a parameter
  # and returns the data as a list of dataframes
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
  
  # Queries the course meta data table
  getCourseData <- function(){
    run1 <- substr(input$run1,1,1)
    if(run1 != "A"){
      data1 <- getCourseMetaDataSpecific(input$course1,run1)
      name <- paste(c(input$course1,run1), collapse = " - ")
      datasets <- list("1"= data1)
      names(datasets)[which(names(datasets) == "1")] <- name
    } else {
      datasets <- list()
    }
    run2 <- substr(input$run2,1,1)
    if(input$run2 != "None" &  run2 != "A"){
      data2 <- getCourseMetaDataSpecific(input$course2, run2)
      datasets[[paste(c(input$course2,run2), collapse = " - ")]] <- data2
    }
    run3 <- substr(input$run3,1,1)
    if(input$run3 != "None" & run3 != "A"){
      data3 <- getCourseMetaDataSpecific(input$course3, run3)
      datasets[[paste(c(input$course3,substr(input$run3,1,1)), collapse = " - ")]] <- data3
    }
    run4 <- substr(input$run4,1,1)
    if(input$run4 != "None" & run4 != "A"){
      data4 <- getCourseMetaDataSpecific(input$course4, run4)
      datasets[[paste(c(input$course4,run4), collapse = " - ")]] <- data4
    }
    return(datasets)
  }
  
  #Needs to be converted to use getMetaData
  # aggregateEnrol <- read.csv(file.path(getwd(),"../data",institution,"Courses Data","Deets","Courses-Data.csv"))
  # assign("aggregateEnrol", aggregateEnrol, envir = .GlobalEnv) 
  
  # Various Dependencies which stop graphs from attemping to be created without the required data selected first.
  chartDependency <- eventReactive(input$chooseCourseButton, {})
  stepDependancy <- eventReactive(input$runChooserSteps, {})
  commentDependancy <- eventReactive(input$runChooserComments, {})
  measuresDependancy <- eventReactive(input$totalMeasuresRunChooser, {})
  
  
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
    count <- getEnrolmentCount(enrolment_data[[1]])   
    valueBox("Enrolled", count, icon = icon("line-chart"), color = "blue")
  })
  
  output$completedCount <- renderValueBox({
    chartDependency()
    learners <- unlist(strsplit(input$filteredLearners, "[,]"))
    count <- getCompletionCount(step_data)
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
  
  # outputs in a value box the number of total comments in the current course run
  output$totalComments <- renderValueBox({
    
    # to update the value when the button to change course run is pressed or the selected course in the dropdown changes
    chartDependency()
    measuresDependancy()
    learners <- unlist(strsplit(input$filteredLearners, "[,]"))
    
    # comment data for the selected course run
    cData <- comments_data[[which(names(comments_data)==input$totalMeasuresRunChooser)]]
    
    # checks if there exists comment data and updates the valueBox
    if(nrow(cData)!=0) {
      comments <- getNumberOfCommentsByLearner(cData)
      comments <- sum(comments$comments)
    } else {
      comments <- 0
    }
    valueBox("Comments", paste(comments, "in total"), icon = icon("comment-o"), color = "red")
  })
  
  
  # outputs in a value box the number of total replies in the current course run
  output$totalReplies <- renderValueBox({
    
    # to update the value when the button to change course run is pressed or the selected course in the dropdown changes
    chartDependency()
    measuresDependancy()
    learners <- unlist(strsplit(input$filteredLearners, "[,]"))
    
    # comment data for the selected course run
    cData <- comments_data[[which(names(comments_data)==input$totalMeasuresRunChooser)]]
    
    # checks if there exists comment data and updates the valueBox
    if(nrow(cData)!=0){
      replies <- getNumberOfRepliesByLearner(cData)
      replies <- sum(replies$replies)
    } else {
      replies <-0
    }
    valueBox("Replies", paste(replies, "in total"), icon = icon("reply"), color = "yellow")
  })
  
  
  # outputs in a value box the average number of comments in the current course run
  output$avgComments <- renderValueBox({
    
    # to update the value when the button to change course run is pressed or the selected course in the dropdown changes
    chartDependency()
    measuresDependancy()
    learners <- unlist(strsplit(input$filteredLearners, "[,]"))
    
    #comment data for the selected course run
    cData <- comments_data[[which(names(comments_data)==input$totalMeasuresRunChooser)]]
    
    #checks if there is any available comment data and computes the value box
    if(nrow(cData)!=0){
      comments <- getNumberOfCommentsByLearner(cData)
      comments <- median(comments$comments)
    } else {
      comments <- 0
    }
    valueBox("Comments", paste(comments, "average per learner"), icon = icon("comment-o"), color = "green")
  })
  
  
  # outputs in a value box the average number of replies in the current course run
  output$avgReplies <- renderValueBox({
    
    # to update the value when the button to change course run is pressed or the selected course in the dropdown changes
    chartDependency()
    measuresDependancy()
    learners <- unlist(strsplit(input$filteredLearners, "[,]"))
    
    #comment data for the selected course run
    cData <- comments_data[[which(names(comments_data)==input$totalMeasuresRunChooser)]]
    
    #checks if there is any available comment data and computes the value box
    if(nrow(cData)!=0){
      replies <- getNumberOfRepliesByLearner(cData)
      replies <- median(replies$replies)
    } else {
      replies <- 0
    }
    valueBox("Replies", paste(replies, "average per learner"), icon = icon("reply"), color = "olive")
  })
  
  observeEvent(input$scatterSlopeValue, {
    output$scatterSlope <- renderValueBox({
      chartDependency()
      input$plotScatterButton
      valueBox("Slope", input$scatterSlopeValue, icon = icon("line-chart"), color = "red", width = 12)
    })
  })
  
  
  #END: COURSE SELECTION UI AND VALUE BOXES
  
  
  # =================================START NOT USED===============================================
  #START: LEARNER FILTERS - TEXT INPUTS - NOT USED
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
  #END: LEARNER FILTERS - TEXT INPUTS - NOT USED
  
  #START: LEARNER FILTERS - FILTERING - NOT USED
  
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
  # END: LEARNER FITLERS - CHARTS - NOT USED
  # =============================================END NOT USED==============================================
  
  
  # START OF ENROLMENTS TABLE GRAPHS - Demographics tab
  
  # Produces graph of the values of learners age groups
  # Depending of the selected radio button it shows either percentages or numbers
  output$learnersAgeBar <- renderChart2({
    
    #used to update the chart when the Go button is pressed
    chartDependency()
    
    #a data frame of age data - either with percentages or values depending on the radio button selected
    data <- learnersAgeData(input$rbChartDataType)
    
    #creating the learner age chart
    a <- rCharts:::Highcharts$new()
    a$chart(type = "column", width = 750)
    
    #x-axis with the age groups
    a$xAxis(categories = data$levels)
    
    #y-axis with either percentages or values 
    if(input$rbChartDataType == "percentages"){
      a$yAxis(title = list(text = "Percentage of Population"))
    } else {
      a$yAxis(title = list(text = "Population"))
    }
    
    #contains the data for all the selected course runs
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
  
  #download button for the learner age data - as a csv file
  output$downloadLearnerAge <- downloadHandler(
    filename = function() { paste("learner_age", '.csv', sep='') },
    content = function(file) {
      data <- learnersAgeData(input$rbChartDataType)
      write.csv(data, file)
    }
  )
  
  # Produces graph of the values of learners gender groups
  # Depending of the selected radio button it shows either percentages or numbers
  output$learnersGender <- renderChart2({
    
    #used to update the chart when the Go button is pressed
    chartDependency()
    
    #a data frame of gender data - either with percentages or value depending on the radio button selected
    data <- learnersGenderData(input$rbChartDataType)
    
    #creating the gender chart
    a <- rCharts:::Highcharts$new()
    a$chart(type = "column", width = 350)
    
    #x-axis with the gender values
    a$xAxis(categories = data$levels)
    
    #y-axis with either percentages or values 
    if(input$rbChartDataType == "percentages"){
      a$yAxis(title = list(text = "Percentage of Population"))
    } else {
      a$yAxis(title = list(text = "Population"))
    }
    
    #contains the data for all the selected course runs
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
  
  #download button for the gender data - as a csv file
  output$downloadLearnerGender <- downloadHandler(
    filename = function() { paste("learner_gender", '.csv', sep='') },
    content = function(file) {
      data <- learnersGenderData(input$rbChartDataType)
      write.csv(data, file)
    }
  )
  
  # Produces graph of the values of the learners employment area
  # Depending of the selected radio button it shows either percentages or numbers
  output$employmentBar <-renderChart2({
    
    #to update the chart when the Go button is pressed
    chartDependency()
    
    #data frame with employment area count/percentages for each course run
    data <- learnersEmploymentData(input$rbChartDataType)
    
    #creating the bar chart
    a <- rCharts:::Highcharts$new()
    a$chart(type = "bar", width = 1200, height = 650)
    
    #contains the data for all selected course runs
    a$data(data[c(names(enrolment_data))])
    a$colors('#7cb5ec', '#434348','#8085e9','#00ffcc')
    
    #x axis contains the employment area 
    a$xAxis(categories = gsub( "_"," ",(data$area)))
    
    #y-axis with either percentages or values
    if(input$rbChartDataType == "percentages"){
      a$yAxis(title = list(text = "Percentage of Population"))
    } else {
      a$yAxis(title = list(text = "Population"))
    }
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
  
  #download button for employment area data - as a csv
  output$downloadLearnerEmployment <- downloadHandler(
    filename = function() { paste("learner_employment", '.csv', sep='') },
    content = function(file) {
      data <- learnersEmploymentData(input$rbChartDataType)
      write.csv(data, file)
    }
  )	
  
  # Produces graph of the values of the learners employment status
  # Depending of the selected radio button it shows either percentages or numbers
  output$employmentStatus <- renderChart2({
    
    #to update the chart when the Go button is pressed
    chartDependency()
    
    #data frame with status count/percentages for each course run
    data<-learnersStatusData(input$rbChartDataType)
    
    #creating the bar chart
    a <- rCharts:::Highcharts$new()
    a$chart(type = "bar", width = 1200, height = 650)
    
    #contains the data for all selected course runs
    a$data(data[c(names(enrolment_data))])
    a$colors('#7cb5ec', '#434348','#8085e9','#00ffcc')
    
    #x-axis contains the status options
    a$xAxis(categories = gsub( "_"," ",unlist(data$levels)))
    
    #y-axis with either percentages or values
    if(input$rbChartDataType == "percentages"){
      a$yAxis(title = list(text = "Percentage of Population"))
    } else {
      a$yAxis(title = list(text = "Population"))
    }
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
  
  #download button for status data - as a csv
  output$downloadLearnerStatus <- downloadHandler(
    filename = function() { paste("learner_status", '.csv', sep='') },
    content = function(file) {
      data <- learnersStatusData(input$rbChartDataType)
      write.csv(data, file)
    }
  )	
  
  # Produces graph of the values of the learners education level
  # Depending of the selected radio button it shows either percentages or numbers
  output$degreeLevel <- renderChart2({
    
    #to update the chart when the go button is pressed
    chartDependency()
    
    #data frame with education status count/percentage for each selected course run
    data<-learnersEducationData(input$rbChartDataType)
    
    #creating the chart
    a <- rCharts:::Highcharts$new()
    a$chart(type = "column", width = 1200, height = 650)
    
    #contains the data for all selected course runs
    a$data(data[c(names(enrolment_data))])
    a$colors('#7cb5ec', '#434348','#8085e9','#00ffcc')
    
    #x-axis containing the education status options
    a$xAxis(categories = gsub( "_"," ",data$level))
    
    #y-axis with either percentages or values
    if(input$rbChartDataType == "percentages"){
      a$yAxis(title = list(text = "Percentage of Population"))
    } else {
      a$yAxis(title = list(text = "Population"))
    }
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
  
  
  #download button for education status data - as a csv
  output$downloadLearnerEducation <- downloadHandler(
    filename = function() { paste("learner_education", '.csv', sep='') },
    content = function(file) {
      data <- learnersEducationData(input$rbChartDataType)
      write.csv(data, file)
    }
  )	
  
  # Produces map of which countries the learners are from and in what numbers
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
  
  output$downloadCountryData <- downloadHandler(	
    filename = function() { paste("learner_country", '.csv', sep='') },
    content = function(file) {
      data <- getLearnersByCountry(pre_course_data[which(pre_course_data$country != "Unknown"), ])[[2]]		
      write.csv(data, file)
    }
  )	
  
  #Produces map of which HDI level the learners are from based on their country data
  output$HDIColumn <- renderChart2({
    chartDependency()
    data <- learnersHDIData()
    
    chart <- Highcharts$new()
    chart$chart(type = 'column', width = 1200)
    chart$data(data[c(names(enrolment_data))])
    chart$colors('#7cb5ec', '#434348','#8085e9','#00ffcc')
    chart$xAxis(categories = data$levels)
    chart$yAxis(title = list(text = "Percentage of Countries"))
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
  
  output$downloadHDIData <- downloadHandler(	
    filename = function() { paste("learner_HDI", '.csv', sep='') },
    content = function(file) {
      data <- learnersHDIData()
      write.csv(data, file)
    }
  )
  # END DEMOGRAPHICS TAB
  
  
  
  # START STATEMENT DEMOGRAPHICS TAB
  
  # Column chart of statement purchaser's genders
  # Depending of the selected radio button it shows either percentages or numbers
  output$stateGenderColumn <- renderChart2({
    
    #to update the chart when the Go button is pressed
    chartDependency()
    
    #data frame with gender count/percentage for each selected course run
    data <- stateGenderData(input$rbChartDataType)
    
    #creating the column chart
    a <- rCharts:::Highcharts$new()
    a$chart(type = "column", width = 350)
    
    #x-axis contains the gender levels
    a$xAxis(categories = data$levels)
    
    #y-axis with either percentages or values
    if(input$rbChartDataType == "percentages"){
      a$yAxis(title = list(text = "Percentage of Population"))
    } else {
      a$yAxis(title = list(text = "Population"))
    }
    
    #data for each of the selected course runs
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
  
  #button to download the statement purchasers' gender data as a csv file
  output$downloadStateLearnerGender <- downloadHandler(
    filename = function() { paste("statements_learner_gender", '.csv', sep='') },
    content = function(file) {
      data <- stateGenderData(input$rbChartDataType)
      write.csv(data, file)
    }
  )
  
  # Column chart of statement purchaser's age groups
  # Depending of the selected radio button it shows either percentages or numbers
  output$stateAgeColumn <- renderChart2({
    
    #to update the chart when pressing the Go button
    chartDependency()
    
    # data frame with age group values/percentage for each course run
    data<-stateAgeData(input$rbChartDataType)
    
    #creating the column chart
    a <- rCharts:::Highcharts$new()
    a$chart(type = "column", width = 750)
    
    #x-axis contains the age group levels
    a$xAxis(categories = data$levels)
    
    #y-axis with either percentages or values
    if(input$rbChartDataType == "percentages"){
      a$yAxis(title = list(text = "Percentage of Population"))
    } else {
      a$yAxis(title = list(text = "Population"))
    }
    
    #data about all the selected course runs
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
  
  #button to download the statement purchasers' age data as a csv file
  output$downloadStateLearnerAge <- downloadHandler(
    filename = function() { paste("statements_learner_age", '.csv', sep='') },
    content = function(file) {
      data <- stateAgeData(input$rbChartDataType)
      write.csv(data, file)
    }
  )
  
  # Bar chart of statement purchasers' employment area
  # Depending of the selected radio button it shows either percentages or numbers
  output$stateEmploymentAreaBar <- renderChart2({
    
    #to update the chart when the Go button is pressed
    chartDependency()
    
    #data frame with employment area values/percentages for each course run
    data <- stateEmploymentData(input$rbChartDataType)
    
    #creating the chart
    a <- rCharts:::Highcharts$new()
    a$chart(type = "bar", width = 1200, height = 650)
    
    #data for all the course runs selected
    a$data(data[c(names(enrolment_data))])
    a$colors('#7cb5ec', '#434348','#8085e9','#00ffcc')
    
    #x-axis to with the employment area options
    a$xAxis(categories = gsub( "_"," ",(data$area)))
    
    #y-axis with either percentages or values
    if(input$rbChartDataType == "percentages"){
      a$yAxis(title = list(text = "Percentage of Population"))
    } else {
      a$yAxis(title = list(text = "Population"))
    }
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
  
  #button for downloading the statement purchsers' employment area data in csv
  output$downloadStateLearnerEmployment <- downloadHandler(
    filename = function() { paste("statements_learner_employment", '.csv', sep='') },
    content = function(file) {
      data <- stateEmploymentData(input$rbChartDataType)
      write.csv(data, file)
    }
  )
  
  # Column chart of statement purchasers' employment status
  # Depending of the selected radio button it shows either percentages or numbers
  output$stateEmploymentStatusColumn <- renderChart2({
    
    #creates the chart when pressing the Go button
    chartDependency()
    
    #data frame with status groups value/percentage for each course run
    data<-stateStatusData(input$rbChartDataType)
    
    #creating the chart
    a <- rCharts:::Highcharts$new()
    a$chart(type = "bar", width = 1200, height = 650)
    
    #chart data for all the selected course runs
    a$data(data[c(names(enrolment_data))])
    a$colors('#7cb5ec', '#434348','#8085e9','#00ffcc')
    
    #x-axis contains the employment status levels
    a$xAxis(categories = gsub( "_"," ",unlist(data$levels)))
    
    #y-axis with either percentages or values
    if(input$rbChartDataType == "percentages"){
      a$yAxis(title = list(text = "Percentage of Population"))
    } else {
      a$yAxis(title = list(text = "Population"))
    }
    
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
  
  #button for downloading status data for statement purchasers as csv file
  output$downloadStateLearnerStatus <- downloadHandler(
    filename = function() { paste("statements_learner_status", '.csv', sep='') },
    content = function(file) {
      data <- stateStatusData(input$rbChartDataType)
      write.csv(data, file)
    }
  )
  
  # Column chart of statement purchaser's education level
  # Depending of the selected radio button it shows either percentages or numbers
  output$stateDegreeColumn <- renderChart2({
    
    #to update the chart after pressing the Go button
    chartDependency()
    
    #data frame with education status value/percentage for each course run selected
    data<-stateEducationData(input$rbChartDataType)
    
    #creating the chart
    a <- rCharts:::Highcharts$new()
    a$chart(type = "column", width = 1200, height = 650)
    
    #chart data for all the selected course runs
    a$data(data[c(names(enrolment_data))])
    a$colors('#7cb5ec', '#434348','#8085e9','#00ffcc')
    
    #x-axis with the education status categories
    a$xAxis(categories = gsub( "_"," ",data$level))
    
    #y-axis with either percentages or values
    if(input$rbChartDataType == "percentages"){
      a$yAxis(title = list(text = "Percentage of Population"))
    } else {
      a$yAxis(title = list(text = "Population"))
    }
    
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
  
  #button for downloading education status data for all the statement purchasers
  output$downloadStateLearnerEducation <- downloadHandler(
    filename = function() { paste("statements_learner_education", '.csv', sep='') },
    content = function(file) {
      data <- stateEducationData(input$rbChartDataType)
      write.csv(data, file)
    }
  )
  
  # Map of what countries the statement purchaser's came from
  output$stateLearnerMap <- renderGvis({		
    data <- getLearnersByCountry(pre_course_data[which(pre_course_data$country != "Unknown" & pre_course_data$purchased_statement_at != ""), ])
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
  
  output$downloadStateLearnerCountry <- downloadHandler(
    filename = function() { paste("statements_learner_country", '.csv', sep='') },
    content = function(file) {
      data <- getLearnersByCountry(pre_course_data[which(pre_course_data$country != "Unknown" & pre_course_data$purchased_statement_at != ""), ])
      write.csv(data, file)
    }
  )
  
  # Column graph for the HDI levels of statement purchaser's
  output$stateHDIColumn <- renderChart2({
    chartDependency()
    data<-stateHDIData()
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
  
  output$downloadStateLearnerHDI <- downloadHandler(
    filename = function() { paste("statements_learner_hdi", '.csv', sep='') },
    content = function(file) {
      data <- stateHDIData()
      write.csv(data, file)
    }
  )
  
  # END STATEMENT DEMOGRAPHICS TAB
  
  
  # START SIGN UPS AND STATEMENTS SOLD TAB
  
  # Line showing sign ups over time
  output$signUpsLine <- renderChart2({
    chartDependency()
    
    analysis <- signUpData()
    data<- analysis[[1]]
    startDays <- analysis[[2]]
    startDay <- analysis[[3]]
    chart <- Highcharts$new()
    chart$chart(type = "line", width = 1200)
    chart$data(data[c(names(enrolment_data))])
    chart$colors('#7cb5ec', '#434348','#8085e9','#00ffcc')
    if(length(startDays) == 1){
      chart$xAxis(
        title = list(text = "Day"),
        categories = data$day, plotLines = list(
          list(
            value = startDays[1],
            color = "#7cb5ec",
            width = 3,
            zIndex = 4,
            label = list(
              text = paste("Course Started: ", startDay,
                           sep = " "),
              style = list( color = 'black')
            )
          )
        )
      )
    } else if (length(startDays) == 2){
      chart$xAxis(
        title = list(text = "Day"),
        categories = data$day, plotLines = list(
          list(
            value = startDays[1],
            color = "#7cb5ec",
            width = 3,
            zIndex = 4,
            label = list(
              text = paste(names(enrolment_data)[1],
                           "Start", sep = " "),
              style = list( color = 'black')
            )
          ),
          list(
            value = startDays[2],
            color = "#434348",
            width = 3,
            zIndex = 4,
            label = list(
              text = paste(names(enrolment_data)[2],
                           "Start", sep = " "),
              style = list( color = 'black')
            )
          )
        )
      )
    }else if (length(startDays) == 3){
      chart$xAxis(
        title = list(text = "Day"),
        categories = data$day, plotLines = list(list(
          value = startDays[1],
          color = "#7cb5ec",
          width = 3,
          zIndex = 4,
          label = list(text = paste(names(enrolment_data)[1],"Start", sep = " "),
                       style = list( color = 'black')
          )),
          list(
            value = startDays[2],
            color = '#434348',
            width = 3,
            zIndex = 4,
            label = list(text = paste(names(enrolment_data)[2],"Start", sep = " "),
                         style = list( color = 'black')
            )),
          list(
            value = startDays[3],
            color = '#8085e9',
            width = 3,
            zIndex = 4,
            label = list(text = paste(names(enrolment_data)[3],"Start", sep = " "),
                         style = list( color = 'black')
            ))
        ))
    }else if (length(startDays) == 4){
      chart$xAxis(
        title = list(text = "Day"),
        categories = data$day, plotLines = list(list(
          value = startDays[1],
          color = "#7cb5ec",
          width = 3,
          zIndex = 4,
          label = list(text = paste(names(enrolment_data)[1],"Start", sep = " "),
                       style = list( color = 'black')
          )),
          list(
            value = startDays[2],
            color = '#434348',
            width = 3,
            zIndex = 4,
            label = list(text = paste(names(enrolment_data)[2],"Start", sep = " "),
                         style = list( color = 'black')
            )),
          list(
            value = startDays[3],
            color = '#8085e9',
            width = 3,
            zIndex = 4,
            label = list(text = paste(names(enrolment_data)[3],"Start", sep = " "),
                         style = list( color = 'black')
            )),
          list(
            value = startDays[4],
            color = '#00ffcc',
            width = 3,
            zIndex = 4,
            label = list(text = paste(names(enrolment_data)[4],"Start", sep = " "),
                         style = list( color = 'black')
            ))
        ))
    }
    chart$yAxis(title = list(text = "Frequency"))
    return(chart)
  })
  
  output$downloadSignUps <- downloadHandler(
    filename = function() { paste("signUps", '.csv', sep='') },
    content = function(file) {
      data <- signUpData()[[1]]
      write.csv(data, file)
    }
  )
  
  # Line showing statements sold over time: day vs frequency
  output$statementsSoldLine <- renderChart2({
    
    #to update the chart after pressing the Go button
    chartDependency()
    
    #getting the data for the chart  
    data<-statementsSoldData()
    
   #if the data is not empty it creates a chart, otherwise it shows a message
    if(nrow(data) > 0){
      chart <- rCharts:::Highcharts$new()
      chart$chart(type = "line", width = 1200)
      chart$xAxis(categories = unlist(as.factor(data$day)), title = list(text = "Day"))
      chart$yAxis(title = list(text = "Frequency"))
      chart$data(data[c(names(enrolment_data))])
      chart$colors('#7cb5ec', '#434348','#8085e9','#00ffcc')
      return(chart)
    } else {
      shiny::validate(
        need(nrow(data)>0,
             "No data available")
      )
    }
     
    
    
  })
  
  #downloading the statements data as a csv
  output$downloadStatementsSold <- downloadHandler(
    filename = function() { paste("statements_sold", '.csv', sep='') },
    content = function(file) {
      data <- statementsSoldData()
      write.csv(data, file)
    }
  )
  
  # END SIGN UPS AND STATEMENTS SOLD TAB
  
  
  
  
  
  
 
  
  #START: CHARTS - OTHER
  
  scatterDependency <- eventReactive(input$plotScatterButton, {})
  
  output$correlationsRunSelector <-renderUI({
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
    print(selectInput("correlationsRunChooser", label = "Run",
                      choices = runs, width = "550px"))
  })
  
  # Scatter plot
  output$scatterPlot <- renderChart2({
    # Draw the chart when the "chooseCourseButton" AND the "plotScatterButton" are pressed by the user
    chartDependency()
    scatterDependency()
    # input$plotScatterButton
    learners <- unlist(strsplit(input$filteredLearners, "[,]"))
    # In case the user has selected the same values for x and y, display an error message
    shiny::validate(
      need(isolate(input$scatterX) != isolate(input$scatterY),
           "X and Y values cannot be identical. Please, choose different ones.")
    )
    # Check selected input for x and get the according data
    if (isolate(input$scatterX) == "comments") {
      cData <- comments_data[[which(names(comments_data) == input$correlationsRunChooser)]]
      if(nrow(cData)>0){
        x <- getNumberOfCommentsByLearner(cData)
      } else {
        x <- -1
      }
      
      xAxisTitle <- "Comments"
    }
    else if (isolate(input$scatterX) == "replies") {
      cData <- comments_data[[which(names(comments_data) == input$correlationsRunChooser)]]
      if(nrow(cData)>0){
        x <- getNumberOfRepliesByLearner(cData)
      } else {
        x <- -1
      }
      
      xAxisTitle <- "Replies"
    }
    else if (isolate(input$scatterX) == "likes") {
      cData <- comments_data[[which(names(comments_data) == input$correlationsRunChooser)]]
      if(nrow(cData)>0){
        x <- getNumberOfLikesByLearner(cData)
      } else {
        x <- -1
      }
      
      xAxisTitle <- "Likes"
    }
    else if (isolate(input$scatterX) == "answers") {
      qData <- quiz_data[[which(names(quiz_data) == input$correlationsRunChooser)]]
      if(nrow(qData)>0){
        x <- getNumberOfResponsesByLearner(qdata)
      } else {
        x <- -1
      }
      
      xAxisTitle <- "Answers"
    }
    else if (isolate(input$scatterX) == "steps") {
      sData <- step_data[[which(names(step_data) == input$correlationsRunChooser)]]
      if(nrow(sData)>0){
        x <- getStepsCompleted(sData)
      } else {
        x <- -1
      }
      
      xAxisTitle <- "Completed (%)"
    }
    else if (isolate(input$scatterX) == "correct") {
      qData <- quiz_data[[which(names(quiz_data) == input$correlationsRunChooser)]]
      if(nrow(qData)>0){
        x <- getResponsesPercentage(qData)
        x <- x[c("learner_id", "correct")]
      } else {
        x <- -1
      }
      
      xAxisTitle <- "Correct (%)"
    }
    else if (isolate(input$scatterX) == "wrong") {
      qData <- quiz_data[[which(names(quiz_data) == input$correlationsRunChooser)]]
      if(nrow(qData)>0){
        x <- getResponsesPercentage(qData)
        x <- x[c("learner_id", "wrong")]
      } else {
        x <- -1
      }
      
      xAxisTitle <- "Wrong (%)"
    }
    else if (isolate(input$scatterX) == "questions") {
      qData <- quiz_data[[which(names(quiz_data) == input$correlationsRunChooser)]]
      if(nrow(qData)>0){
        x <- getPercentageOfAnsweredQuestions(qData)
      } else {
        x <- -1
      }
      
      xAxisTitle <- "Questions (%)"
    }
    # Check selected input for y and get the according data
    if (isolate(input$scatterY) == "comments") {
      cData <- comments_data[[which(names(comments_data) == input$correlationsRunChooser)]]
      if(nrow(cData)>0){
        y <- getNumberOfCommentsByLearner(cData)
      } else {
        y <- -1
      }
      
      yAxisTitle <- "Comments"
    }
    else if (isolate(input$scatterY) == "replies") {
      cData <- comments_data[[which(names(comments_data) == input$correlationsRunChooser)]]
      if(nrow(cData)>0){
        y <- getNumberOfRepliesByLearner(cData)
      } else {
        y <- -1
      }
      
      yAxisTitle <- "Replies"
    }
    else if (isolate(input$scatterY) == "likes") {
      cData <- comments_data[[which(names(comments_data) == input$correlationsRunChooser)]]
      if(nrow(cData)>0){
        y <- getNumberOfLikesByLearner(cData)
      } else {
        y <- -1
      }
      
      yAxisTitle <- "Likes"
    }
    else if (isolate(input$scatterY) == "answers") {
      qData <- quiz_data[[which(names(quiz_data) == input$correlationsRunChooser)]]
      if(nrow(qData)>0){
        y <- getNumberOfResponsesByLearner(qData)
      } else {
        y <- -1
      }
      
      yAxisTitle <- "Answers"
    }
    else if (isolate(input$scatterY) == "steps") {
      sData <- step_data[[which(names(step_data) == input$correlationsRunChooser)]]
      if(nrow(sData) > 0){
        y <- getStepsCompleted(sData)
      } else {
        y <- -1
      }
      
      yAxisTitle <- "Completed (%)"
    }
    else if (isolate(input$scatterY) == "correct") {
      qData <- quiz_data[[which(names(quiz_data) == input$correlationsRunChooser)]]
      if(nrow(qData) > 0){
        y <- getResponsesPercentage(qData)
        y <- y[c("learner_id", "correct")]
      } else {
        y <- -1
      }
      
      yAxisTitle <- "Correct (%)"
    }
    else if (isolate(input$scatterY) == "wrong") {
      qData <- quiz_data[[which(names(quiz_data) == input$correlationsRunChooser)]]
      if(nrow(qData)>0){
        y <- getResponsesPercentage(qData)
        y <- y[c("learner_id", "wrong")]
      } else {
        y <- -1
      }
      
      yAxisTitle <- "Wrong (%)"
    }
    else if (isolate(input$scatterY) == "questions") {
      qData <- quiz_data[[which(names(quiz_data) == input$correlationsRunChooser)]]
      if(nrow(qData)>0){
        y <- getPercentageOfAnsweredQuestions(qData)
      } else {
        y <- -1
      }
      
      yAxisTitle <- "Questions (%)"
    }
    updateTextInput(session, "scatterSlopeValue", value = "No data available")
    if(x == -1 || y == -1){
      shiny::validate(
        need(x != -1 && y != -1,
             "No data available")
      )
    } else {
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
      scatter$chart (width = 1200, height = 600, zoomType = "xy")
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
      
      return (scatter)
    }
    
  })
  
  output$dateTimeSeries <- renderDygraph({
    chartDependency()
    learners <- unlist(strsplit(input$filteredStreams, "[,]"))
    #calculate the comments, like and replies by date
    
    comments <- getNumberOfCommentsByDate(comments_data)
    likes <-  getNumberOfLikesByDate(comments_data)
    replies <- getNumberOfRepliesByDate(comments_data)
    answers <- getNumberOfResponsesByDateTime(quiz_data)
    enrolment <- getEnrolmentByDateTime(enrolment_data)
    
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
  
  # Data table showing learner information for each run.
  output$aggregateEnrolmentData <- renderDataTable({
    
    courseMetaData <- courseMetaData[, !(colnames(courseMetaData) %in% c("course","run"))]
    courseMetaData$course_run <- gsub( "-", " ", as.character(courseMetaData$course_run))
    courseMetaData$course_run <- capitalize(courseMetaData$course_run)
    courseMetaData <- courseMetaData[order(courseMetaData$course_run),]
    courseMetaData$start_date <- as.Date(courseMetaData$start_date)
    courseMetaData <- courseMetaData[ , !(names(courseMetaData) %in% c("university"))]
    
    DT::datatable(
      courseMetaData, class = 'cell-border stripe', filter = 'top', extensions = 'Buttons',
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
  
  # Valuebox aggregating the number of joiners in all courses
  output$totalJoiners <- renderValueBox({
    valueBox("Total Joiners", subtitle = sum(courseMetaData$joiners), icon = icon("group"), color = "red")
  })
  
  # Valuebox aggregating the number of learners in all courses
  output$totalLearners <- renderValueBox({
    learners <- subset(courseMetaData , learners != "N/A")
    learners2 <- sapply(learners$learners, function(x) strsplit(toString(x), "-"))
    learners3 <- sapply(learners2, function(x) as.numeric(x[[1]]))
    valueBox("Total Learners", subtitle = sum(learners3), icon = icon("group"), color = "red")
  })
  
  #Valuebox aggregating the number of statements sold in all courses
  output$totalStatementsSold <- renderValueBox({
    valueBox("Total Statements Sold", subtitle = sum(courseMetaData$statements_sold), icon = icon("certificate"), color = "red")
  })
  
  # END AGGREGATE ENROLMENT TAB
  
  
  # START STEP COMPLETION TAB
  
  # Selector for which run to display on the step tab
  
  StepButtonDependency <- eventReactive(input$runSelectorStepsButton, {})
  observeEvent(input$runSelectorStepsButton, {
    output$runSelectorSteps <- renderUI({
      StepButtonDependency()
      chartDependency()
      # stepDependancy()
      
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
    if (isolate(input$graphName) == "StepsMarkedAsComplete") {
      # Step completed column chart
      # output$StepsFirstVisited <- renderChart2({})
      # output$stepCompletionHeat <- renderD3heatmap({})
      # output$firstVisitedHeat <- renderD3heatmap({})
      # output$firstVisitedPerDay <- renderChart2({})
      # output$markedCompletedPerDay <- renderChart2({})
      shinyjs::hide(id = "box2")
      shinyjs::hide(id = "box3")
      shinyjs::hide(id = "box4")
      shinyjs::hide(id = "box5")
      shinyjs::hide(id = "box6")
      shinyjs::show(id = "box1")
      output$stepsCompleted <- renderChart2({
        sData <- step_data[[which(names(step_data) == input$runChooserSteps)]]
        
        if(nrow(sData)>0){
          stepsCount <- getStepsCompletedData(sData)
          a <- rCharts:::Highcharts$new()
          a$chart(type = "column", width = 1200)
          a$series(
            name = input$runChooserSteps,
            type = column,
            data = stepsCount$freq
          )
          a$xAxis(categories = unlist(as.factor(stepsCount[,c("week_step")])), title = list(text = "Step"))
          a$yAxis(title = list(text = "Frequency"))
          a$plotOptions(
            column = list(
              animation = FALSE
            ),
            line = list(
              animation = FALSE)
          )
          return(a)
        } else {
          #if there is no data available it shows an error message
          shiny::validate(
            need(nrow(sData)>0,
                 "No data available")
          )
        }
        
        
        
        # model <- lm(stepsCount[,2] ~ stepsCount$week_step)
        # fit <- predict(model,newData = stepsCount)
        # a$series(
        # 	name = "Best Fit",
        #       	type = line,
        #       	data = fit
        #       )
        
      })
    }
    else if (isolate(input$graphName) == "StepsFirstVisited") {
      # Step completed column chart
      # output$stepsCompleted <- renderChart2({})
      # output$stepCompletionHeat <- renderD3heatmap({})
      # output$firstVisitedHeat <- renderD3heatmap({})
      # output$firstVisitedPerDay <- renderChart2({})
      # output$markedCompletedPerDay <- renderChart2({})
      shinyjs::hide(id = "box1")
      shinyjs::hide(id = "box3")
      shinyjs::hide(id = "box4")
      shinyjs::hide(id = "box5")
      shinyjs::hide(id = "box6")
      shinyjs::show(id = "box2")
      output$StepsFirstVisited <- renderChart2({
        #gets the step data for the selected course run
        sData <- step_data[[which(names(step_data) == input$runChooserSteps)]]
        
        #checks if the data is empty or not
        if(nrow(sData)>0){
          stepsCount <- getStepsFirstVistedData(sData)
          a <- rCharts:::Highcharts$new()
          a$chart(type = "column", width = 1200)
          a$series(
            name = input$runChooserSteps,
            type = column,
            data = stepsCount$freq
          )
          a$xAxis(categories = unlist(as.factor(stepsCount[,c("week_step")])), title = list(text = "Step"))
          a$yAxis(title = list(text = "Frequency"))
          a$plotOptions(
            column = list(
              animation = FALSE
            ),
            line = list(
              animation = FALSE)
          )
          return(a)
        } else {
          #if there is no data available it shows an error message
          shiny::validate(
            need(nrow(sData)>0,
                 "No data available")
          )
        }
        
        # model <- lm(stepsCount[,2] ~ stepsCount$week_step)
        # fit <- predict(model,newData = stepsCount)
        # a$series(
        # 	name = "Best Fit",
        #       	type = line,
        #       	data = fit
        #       )
        
      })
    }
    else if (isolate(input$graphName) == "StepsFirstVisitedByStepAndDate") {
      # Step completion heat map
      # output$StepsFirstVisited <- renderChart2({})
      # output$stepsCompleted <- renderChart2({})
      # output$stepCompletionHeat <- renderD3heatmap({})
      # output$firstVisitedPerDay <- renderChart2({})
      # output$markedCompletedPerDay <- renderChart2({})
      shinyjs::hide(id = "box1")
      shinyjs::hide(id = "box2")
      shinyjs::hide(id = "box4")
      shinyjs::hide(id = "box5")
      shinyjs::hide(id = "box6")
      shinyjs::show(id = "box3")
      output$firstVisitedHeat <- renderD3heatmap({
        
        #gets the start date of the course run which is selected
        startDate <- course_data[[which(names(course_data) == input$runChooserSteps)]]$start_date
        
        #gets the step data for the selected course run
        sData <- step_data[[which(names(step_data) == input$runChooserSteps)]]
        
        if(nrow(sData)!=0){
          #gets the data for the heat map, passing the step data for the course run and the start date
          map <- getFirstVisitedHeatMap(sData, startDate)
          return(d3heatmap(map[,2:ncol(map)],
                           dendrogram = "none",
                           scale = "column",
                           color = "Blues",
                           labRow = as.character(as.POSIXct(map[,1]), origin = "1970-01-01")))
        } else {
          shiny::validate(
            need(nrow(sData)>0,
                 "No data available")
          )
        }
      })
    }
    else if (isolate(input$graphName) == "StepsFirstVisitedPerDay") {
      # Step completion heat map
      # output$StepsFirstVisited <- renderChart2({})
      # output$stepsCompleted <- renderChart2({})
      # output$firstVisitedHeat <- renderD3heatmap({})
      # output$stepCompletionHeat <- renderD3heatmap({})
      # output$markedCompletedPerDay <- renderChart2({})
      shinyjs::hide(id = "box1")
      shinyjs::hide(id = "box2")
      shinyjs::hide(id = "box3")
      shinyjs::hide(id = "box5")
      shinyjs::hide(id = "box6")
      shinyjs::show(id = "box4")
      output$firstVisitedPerDay <- renderChart2({
        chartDependency()
        data<-stepsFirstVisitedPerDay()
        
        if(nrow(data)>0){
          chart <- Highcharts$new()
          chart$chart(type = "line", width = 1200)
          chart$data(data[c(names(step_data))])
          chart$colors('#7cb5ec', '#434348','#8085e9','#00ffcc')
          chart$xAxis(categories = unlist(as.factor(data$day)), title = list(text = "Day"))
          chart$yAxis(title = list(text = "Frequency"))
          return(chart)
        } else {
          shiny::validate(
            need(nrow(data)>0,
                 "No data available")
          )
        }
        
 
      })
    }
    else if (isolate(input$graphName) == "StepsMarkedCompletedPerDay") {
      # Step completion heat map
      # output$StepsFirstVisited <- renderChart2({})
      # output$stepsCompleted <- renderChart2({})
      # output$firstVisitedHeat <- renderD3heatmap({})
      # output$stepCompletionHeat <- renderD3heatmap({})
      # output$firstVisitedPerDay <- renderChart2({})
      shinyjs::hide(id = "box1")
      shinyjs::hide(id = "box2")
      shinyjs::hide(id = "box3")
      shinyjs::hide(id = "box4")
      shinyjs::hide(id = "box6")
      shinyjs::show(id = "box5")
      output$markedCompletedPerDay <- renderChart2({
        chartDependency()
        data<-stepsMarkedCompletedPerDay()
      
        if(nrow(data) > 0){
          chart <- Highcharts$new()
          chart$chart(type = "line", width = 1200)
          chart$data(data[c(names(step_data))])
          chart$colors('#7cb5ec', '#434348','#8085e9','#00ffcc')
          chart$xAxis(categories = unlist(as.factor(data$day)), title = list(text = "Day"))
          chart$yAxis(title = list(text = "Frequency"))
          return(chart)
        } else {
          shiny::validate(
            need(nrow(data)>0,
                 "No data available")
          )
        }
        
        
      })
    }
    else if (isolate(input$graphName) == "StepsMarkedAsCompleteByStepAndDate") {
      # First Visited Heat Map
      # output$StepsFirstVisited <- renderChart2({})
      # output$stepsCompleted <- renderChart2({})
      # output$stepCompletionHeat <- renderD3heatmap({})
      # output$firstVisitedPerDay <- renderChart2({})
      # output$markedCompletedPerDay <- renderChart2({})
      shinyjs::hide(id = "box1")
      shinyjs::hide(id = "box2")
      shinyjs::hide(id = "box3")
      shinyjs::hide(id = "box4")
      shinyjs::hide(id = "box5")
      shinyjs::show(id = "box6")
      output$stepCompletionHeat <- renderD3heatmap({
        
        #gets the start date of the selected course run
        startDate <- course_data[[which(names(course_data) == input$runChooserSteps)]]$start_date
        
        #gets the step data of the selected course run
        sData <- step_data[[which(names(step_data) == input$runChooserSteps)]]
        
        #if the table contains data it computes the necessary data and renders the heatmap
        #otherwise shows an error message
        if(nrow(sData)>0){
          map <- getStepCompletionHeatMap(sData, startDate)
          return((d3heatmap(map[,2:ncol(map)],
                            dendrogram = "none",
                            scale = "column",
                            color = "Blues",
                            labRow = as.character(as.POSIXct(map[,1]), origin = "1970-01-01"))))
        } else {
          shiny::validate(
            need(nrow(sData)>0,
                 "No data available")
          )
        }
      })
    }
  })
  
  # END STEP COMPLETION TAB
  
 
  
  
  #START: CHARTS - COMMENTS ORIENTATED
  
  # Selector for which run to display comment related things
  
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
  
  output$commentsBarChart <- renderChart2({
    
    #to update if the go button is pressed or the comment selector is changed
    chartDependency()
    commentDependancy()
    
    #step and comment data for the selected course run
    sData <- step_data[[which(names(step_data) == input$runChooserComments)]]
    cData <- comments_data[[which(names(comments_data)==input$runChooserComments)]]
    
   
    
    #checking to see if the data needed to compute the chart is empty or not
    #if empty it displays an error message, if not it renders the chart
    if(nrow(sData)>0 && nrow(cData)>0){
      histogram <- Highcharts$new()
      #get the data for the barchart, passing the step and comment data for the selected course run
      plotData <- getCommentsBarChart(sData, cData)
      histogram$chart(type = "column" , width = 1200)
      histogram$data(plotData[,c("reply","post")])
      histogram$xAxis (categories = plotData$week_step, title = list(text = "Activity step"))
      histogram$yAxis(title = list(text = "Frequency"))
      histogram$plotOptions (
        column = list(
          stacking = "normal"
        ),
        animation = FALSE
      )
      return(histogram)
    } else {
      shiny::validate(
        need(nrow(sData)>0 && nrow(cData)>0,
             "No data available")
      )
    }
    
  })
  
  # Heatmap of comments made per step and date
  output$stepDateCommentsHeat <- renderD3heatmap({
    # Draw the chart when the "chooseCourseButton" is pressed by the user or the drop down value is changed
    chartDependency()
    commentDependancy()
    learners <- unlist(strsplit(input$filteredLearners, "[,]"))
    
    #gets the starts date of the course run and the comment data
    startDate <- course_data[[which(names(course_data) == input$runChooserComments)]]$start_date
    cData <- comments_data[[which(names(comments_data) == input$runChooserComments)]]
    
    #renders the heatmap if there is existing data and shows an error message if not
    if(nrow(cData)>0){
      comments <- getCommentsHeatMap(cData, startDate)
      d3heatmap(comments[,2:ncol(comments)], dendrogram = "none", 
                color = "Blues",
                scale = "column",
                labRow = as.character(as.POSIXct(comments[,1], origin = "1970-01-01")),
                labCol = colnames(comments)[-1])
    } else {
      shiny::validate(
        need(nrow(cData)>0,
             "No data available")
      )
    }
    

  })
  
  # Histogram of the comment and replies made per week
  output$commentsRepliesWeekBar <- renderChart2({
    
    #to render the chart when the go button is pressed or the comment selector is changed
    chartDependency()
    commentDependancy()
    
    #comment data for the selected course
    cData <- comments_data[[which(names(comments_data)==input$runChooserComments)]]

    
    #checks to see if the table data used to compute the data for the chart is empty or not
    #if not, it displays the chart, if yes it shows an error message
    if(nrow(cData)!=0){
      histogram <- Highcharts$new()
      histogram$chart(type = "column" , width = 550)
      
      #getting data for the chart and displaying the chart
      plotData <- getCommentsBarChartWeek(cData)
      histogram$data(plotData[,c("reply","post")])
      histogram$xAxis (categories = plotData$week_number, title = list(text = "Week"))
      histogram$yAxis(title = list(text = "Frequency"))
      histogram$plotOptions (
        column = list(
          stacking = "normal"
        ),
        animation = FALSE
      )
      return(histogram)
    } else {
      shiny::validate(
        need(nrow(cData)>0,
             "No data available")
      )
    }
    
    
  })
  
  # Histogram of the number of authors per week
  output$authorsWeekBar <- renderChart2({
    
    #to update the chart when the go button is pressed or comment overview run selector changed
    chartDependency()
    commentDependancy()
    
    #get comment data for the selected course run
    cData <- comments_data[[which(names(comments_data)==input$runChooserComments)]]
    
    #checks if the table needed for getting chart data is empty or not
    #if not empty, it computes the chart, else it throws an error message
    if(nrow(cData)!=0){
      plotData <- getNumberOfAuthorsByWeek(cData)
      histogram <- Highcharts$new()
      histogram$chart(type = "column" , width = 550)
      histogram$data(plotData[,c("authors")])
      histogram$xAxis (categories = plotData$week_number, title = list(text = "Week"))
      histogram$yAxis(title = list(text = "Frequency"))
      histogram$plotOptions (
        column = list(
          stacking = "normal"
        ),
        animation = FALSE
      )
      return(histogram)
    } else {
      shiny::validate(
        need(nrow(cData)>0,
             "No data available")
      )
    }
    
    
  })
  
  output$totalMeasuresRunSelector <- renderUI({
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
    print(selectInput("totalMeasuresRunChooser", label = "Run",
                      choices = runs, width = "550px"))
  })
  
  # Line chart of the average number of comments made per step completion percentage
  output$avgCommentsCompletionLine <- renderChart2({
    # Draw the chart when the "chooseCourseButton" is pressed by the user
    chartDependency()
    measuresDependancy()
    
    # Get number of comments made and steps completed by learner
    learners <- unlist(strsplit(input$filteredLearners, "[,]"))
    
    # JSR replaced
    #assign("startDate", input$courseDates[1], envir = .GlobalEnv)
    #assign("endDate", input$courseDates[2], envir = .GlobalEnv)
    
    #gets the comment and step data for the selected course run
    cData <- comments_data[[which(names(comments_data)==input$totalMeasuresRunChooser)]]
    sData <- step_data[[which(names(step_data)==input$totalMeasuresRunChooser)]]
    
    #checks if the table needed to compute the data for the chart is empty or not
    #if not, it renders the chart, if empty it shows an error message
    if(nrow(cData)>0 && nrow(sData)>0) {
      comments <- getNumberOfCommentsByLearner(cData)
      steps <- getStepsCompleted(sData)
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
      lineChart$chart (type = "line", width = 1200, height = 600)
      lineChart$series (
        name = "Comments",
        data = toJSONArray2(plotData, json = FALSE, names = FALSE),
        type = "line"
      )
      lineChart$xAxis (title = list(text = "Completed (%)"))
      lineChart$yAxis (title = list(text = "Comments"))
      return (lineChart)
    } else {
      shiny::validate(
        need(nrow(cData)>0 && nrow(sData)>0,
             "No data available")
      )
    }
    
  })
  
  #END: CHARTS - COMMENTS ORIENTATED
  
  
  
   
  # START COMMENT VIEWER TAB
  
  #Selector to choose which run to view comments of
  output$commentRunSelector <- renderUI({
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
  
  # View comments button
  output$viewButton <- renderUI({
    chartDependency()
    print(actionButton("viewButton","View Comments"))
  })
  
  # Load cloud button
  output$loadCloud <- renderUI({
    chartDependency()
    print(actionButton("loadCloud", "Load Cloud"))
  })
  
  # Dependency for the data table to only load after the view comments button has been pressed
  viewPressed <- eventReactive(input$viewButton, {
    return(input$runChooser)
  })
  
  # Produces a data table for the comments
  output$commentViewer <- renderDataTable({
    chartDependency()
    viewPressed()
    if(input$viewButton == 0){
      return()
    }
    withProgress(message = "Processing Comments",{
      data <- getCommentViewerData(comments_data, viewPressed(), courseMetaData)
      DT::datatable(
        data[,c("timestamp","week_step","text","thread","likes","url")], class = 'cell-border stripe', filter = 'top', extensions = 'Buttons',
        colnames = c(
          "Date" = 1,
          "Step" = 2,
          "Comment" = 3,
          "Part of a Thread?" = 4,
          "Likes" = 5,
          "Link" = 6
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
              text = 'Download PDF'
            ),
            list(
              extend = 'excel',
              filename = 'Comments',
              text = 'Download Excel'
            )
          )
        ),
        rownames = FALSE,
        selection = 'single',
        escape = FALSE
      )
    })
  })
  
  # Checks if a comment has been selected
  threadSelected <- eventReactive( input$commentViewer_rows_selected, {
    runif(input$commentViewer_rows_selected)
  })
  
  #Produced a data table of the thread for the comment selected
  output$threadViewer <- renderDataTable({
    chartDependency()
    viewPressed()
    threadSelected()
    withProgress(message = "Retrieving Thread",{
      data <- getCommentViewerData(comments_data, viewPressed(),courseMetaData)
      data$likes <- as.integer(data$likes)
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
        rows[,c("timestamp","week_step","text","likes","url")], class = 'cell-border stripe', filter = 'top', extensions = 'Buttons',
        colnames = c(
          "Date" = 1,
          "Step" = 2,
          "Comment" = 3,
          "Likes" = 4,
          "Link" = 5
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
              text = 'Download PDF'
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
  })
  
  #Makes the wordcloud code repeatable.
  wordcloud_rep <- repeatable(wordcloud)
  
  #Generates the terms for the word cloud
  terms <- reactive({
    isolate({
      withProgress(message = "Processing Word Cloud",{
        data <- comments_data[[which(names(comments_data) == input$runChooser)]]
        data$week_step <- getWeekStep(data)
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
        m <- as.matrix(myDTM)
        m <- sort(rowSums(m), decreasing = TRUE)
      })
    })
  })
  
  #Cloud depends on having pushed the load cloud button
  cloudDependancy <- eventReactive(input$loadCloud, {})
  
  #Produced the word cloud
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
  
  # END COMMENT VIEWER TAB
  
 
  
  
  
  # START TEAM MEMBERS TAB
  
  #Selector to choose which run to be displayed
  output$memberSelector <- renderUI({
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
    print(selectInput("runChooserTeam", label = "Run", choices = runs, width = "550px"))
  })
  
  # View team members button
  output$viewTeamButton <- renderUI({
    chartDependency()
    print(actionButton("viewTeamButton","View Team Members"))
  })
  
  # Dependency for the data table to only load after the view team members button has been pressed
  viewTeamPressed <- eventReactive(input$viewTeamButton, {
    return(input$runChooserTeam)
  })
  
  # Produces a data table for the team members
  output$teamMembersViewer <- renderDataTable({
    chartDependency()
    viewTeamPressed()
    if(input$viewTeamButton == 0){
      return()
    }
    withProgress(message = "Processing",{
      data <- getTeamMembersData(team_data, comments_data, viewTeamPressed(), courseMetaData)
      DT::datatable(
        data[,c("name","timestamp","week_step","text", "url")], class = 'cell-border stripe', filter = 'top', extensions = 'Buttons',
        colnames = c(
          "Name" = 1,
          "Date" = 2,
          "Step" = 3,
          "Comment" = 4,
          "Link" = 5
        ),
        options = list(
          autoWidth = TRUE,
          columnDefs = list(list(width = '10%', targets = list(0,1,2))),
          scrollY = "700px",
          lengthMenu = list(c(10,20,30),c('10','20','30')),
          pageLength = 20,
          dom = 'lfrtBip',
          buttons = list(
            "print",
            list(
              extend = 'pdf',
              filename = 'Team Members',
              text = 'Download PDF'
            ),
            list(
              extend = 'excel',
              filename = 'Team Members',
              text = 'Download Excel'
            )
          )
        ),
        rownames = FALSE,
        selection = 'single',
        escape = FALSE
      )
    })
  })
  
  # Checks if a comment has been selected
  threadSelected <- eventReactive( input$commentViewer_rows_selected, {
    runif(input$commentViewer_rows_selected)
  })
  
  # END TEAM MEMBERS VIEWER TAB
  
  # Debug tool print statements.
  # output$debug <- renderText({
  # 	freqs <- list()
  # 	maxLength <- 0
  # 	startDays <- list()
  # 	for(i in c(1:length(names(enrolment_data)))){
  # 		learners <- enrolment_data[[names(enrolment_data)[i]]]
  # 		learners <- learners[which(learners$role == "learner"),]
  # 		signUpCount <- count(substr(as.character(learners$enrolled_at),start = 1, stop = 10))
  # 		dates <- list(seq.Date(from = as.Date(signUpCount$x[1]), to = as.Date(tail(signUpCount$x, n =1)), by = 1) , numeric())
  # 		if(length(dates[[1]]) > maxLength){
  # 			maxLength <- length(dates[[1]])
  # 		}
  # 		for(x in c(1:length(signUpCount$x))){
  # 			dates[[2]][[which(dates[[1]] == as.Date(signUpCount$x[x]))]] <- signUpCount$freq[[x]]
  # 		}
  # 		freqs[[i]] <- dates
  # 		startDay <- substr(as.character(course_data[[names(course_data)[i]]]$start_date),start = 1, stop = 10)
  # 		startDays[i] <- as.Date(startDay) - as.Date(signUpCount$x[1])
  # 	}
  # 	print(length(startDays))
  # })
  
  
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