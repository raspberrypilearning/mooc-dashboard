require(shiny)
require(shinydashboard)
require(rCharts)
require(dygraphs)
require(d3heatmap)
require(shinyGridster)
require(networkD3)
require(shinyjs)
require(DT)
require(rjson)
source("config.R")
source("learner_filters.R")
source("courses.R")

courses  <-getListOfCourses()

scatterChoices <- list("Number of comments" = "comments", "Number of replies" = "replies",
											 "Number of likes" = "likes",
											 "Number of submitted quiz responses" = "answers",
											 "Percentage of completed steps" = "steps",
											 "Percentage of correct answers" = "correct",
											 "Percentage of wrong answers" = "wrong",
											 "Percentage of completed questions" = "questions")
# Dashboard

header <- dashboardHeader(title = "MOOC Dashboard", titleWidth = 250)

sidebar <- dashboardSidebar(
	width = 250,
	sidebarMenu(
		id = "tabs", 
		menuItem("Home", tabName = "home", icon = icon("home")),
		menuItem("Aggregate Enrolment Data", tabName = "enrolment", icon = icon("th")),
		menuItem("Demographics", tabName = "demographics", icon = icon("pie-chart")),
		menuItem("Step Completion", tabName = "step_completion", icon = icon("graduation-cap")),
		menuItem("Comments Overview", tabName = "commentsOverview", icon = icon("commenting-o")),
		menuItem("Comments Viewer", tabName = "commentsViewer", icon = icon("commenting-o")),
		menuItem("Total Measures", tabName = "total_measures", icon = icon("comments")),
		menuItem("Correlations", tabName = "correlations", icon = icon("puzzle-piece")),
		menuItem("Cumulative Measures", tabName = "cumulative_measures", icon = icon("pie-chart")),
		menuItem("Social Network Analysis", tabName = "social_network_analysis", icon = icon("hashtag"))
	)#sidebarMenu
)

body <- dashboardBody(
	useShinyjs(),
	tags$h2(paste(institution)),
	tags$h4(textOutput("pageTitle")),
	tabItems( 
		tabItem(tabName = "home",
						fluidRow(
							box(
								tags$div(style="display:inline-block; margin-right:15px", 
												selectInput("course", label = "Courses", width = "450px", choices = courses, selected = courses[1])),
								tags$div(style="display:inline-block; margin-right:15px", uiOutput("runs", inline = TRUE)),
								tags$div(uiOutput("chooseCourse", inline = TRUE)),
								title = "Course selection",
								status = "primary", solidHeader = TRUE, width = 10, collapsible = TRUE
							)
						)
						
		),
		tabItem(tabName = "enrolment",
						fluidRow(
							box(
								title = "Aggregate Enrolment Data",
								status = "primary", solidHeader = TRUE, width = 10, collapsible = TRUE,
								DT::dataTableOutput('aggregateEnrolmentData')),
								valueBoxOutput("totalJoiners", width = 5),
								valueBoxOutput("totalLearners", width = 5),
								valueBoxOutput("totalStatementsSold", width = 5)
							)
			),
		tabItem(tabName = "demographics",
						fluidRow(
							box(
								showOutput("learnersAgeBar", "highcharts"),
									title = "Age Distribution", 
									status = "primary", solidHeader = TRUE, width = 7, collapsible = TRUE),
							box(
								showOutput("learnersGender", "highcharts"),
								title = "Gender",
								status = "primary", solidHeader = TRUE, width = 3, collapsible = TRUE)
						),
						fluidRow(
							tabBox(
								title = "Employment and Education",
								id = "employmentTabBox",
								width = 10,
								tabPanel("Area", showOutput("employmentArea", "highcharts")),
								tabPanel("Status", showOutput("employmentStatus", "highcharts")),
								tabPanel("Degree", showOutput("degreeLevel", "highcharts"))
							)
						),#fluidRow
						fluidRow(
							box(htmlOutput("learnerMap"),
									title = "Learners by country", 
									status = "primary", solidHeader = TRUE, width = 10, height = 500,collapsible = TRUE)
						)#fluidRow
		),
		tabItem(tabName = "step_completion",
			fluidRow(
				box(plotOutput("stepsCompleted"),
				textOutput("Test"),
				title = "Steps Marked As Complete",
				status = "primary", solidHeader = TRUE, width = 10, collapsible = TRUE
				),
				box(
					d3heatmapOutput("firstVisitedHeat"),
					title = "Steps First Visited By Step And Date",
					status = "primary", solidHeader = TRUE, width = 10, collapsible = TRUE
				),
				box(
					d3heatmapOutput("stepCompletionHeat"),
					title = "Steps Marked As Complete By Step And Date",
					status = "primary", solidHeader = TRUE, width = 10, collapsible = TRUE
				)
			)
		),
		tabItem(tabName = "commentsOverview",
						fluidRow(
							textInput("filteredLearners", ""),
							box(showOutput("commentsBarChart", "highcharts"),
									title = "Number of Comments by Step", 
									status = "primary", solidHeader = TRUE, width = 10, collapsible = TRUE),
							box(d3heatmapOutput("stepDateCommentsHeat"),
									title = "Number of Comments by Step and Date", 
									status = "primary", solidHeader = TRUE, width = 10, collapsible = TRUE)
						),#fluidRow
						fluidRow(
							box(showOutput("commentsRepliesWeekBar", "highcharts"),
									title = "Comments and Replies by Week", 
									status = "primary", solidHeader = TRUE, width = 5, collapsible = TRUE),
							box(showOutput("authorsWeekBar", "highcharts"),
									title = "Number of Commentors by Week", 
									status = "primary", solidHeader = TRUE, width = 5, collapsible = TRUE)
						),#fluidRow
						fluidRow(
							box(
								sliderInput("commentCloudFreq", "Minimum Frequency of Words:",
									min = 1, max = 100, value = 50),
								sliderInput("commentCloudMax", "Maximum Number of Words:",
									min = 1, max = 100, value = 50),
								actionButton("loadCloud", label = "Load Word Cloud"),
								title = "Comment Word Cloud Panel", 
								status = "primary", solidHeader = TRUE, width = 3, collapsible = TRUE
								),
							box(
								plotOutput("commentWordCloud"),
								title = "Word Cloud", 
								status = "primary", solidHeader = TRUE, width = 7, collapsible = TRUE)
						)
		),
		tabItem(tabName = "commentsViewer",
			fluidRow(
				box(
					fluidRow(
						uiOutput("runSteps"),
						uiOutput("viewButton")
						),
					title = "Selector", 
					status = "primary", solidHeader = TRUE, width = 10, height = 200 ,collapsible = TRUE	
					),
				box(DT::dataTableOutput("commentViewer"),
					title = "Comments", 
					status = "primary", solidHeader = TRUE, width = 10, height = 1000 ,collapsible = TRUE
      	)
			)
		),
		tabItem(tabName = "total_measures",
						fluidRow(
							valueBoxOutput("totalComments", width = 5),
							valueBoxOutput("avgComments", width = 5),
							valueBoxOutput("totalReplies", width = 5),
							valueBoxOutput("avgReplies", width = 5)
						),#fluidRow
						fluidRow(
							box(showOutput("avgCommentsCompletionLine", "highcharts"),
									title = "Average Number of Comments per Completion", 
									status = "primary", solidHeader = TRUE, width = 10, height = 270 ,collapsible = TRUE)
						)#fluidRow
		),
		tabItem(tabName = "correlations",
						fluidRow(
							box(htmlOutput("scatterPlot"),
									textInput("scatterSlopeValue", ""),
									title = "Scatter plot", 
									status = "primary", solidHeader = TRUE, width = 10, collapsible = TRUE)
						),#fluidRow
						fluidRow(
							box(selectInput("scatterX", label = "Choose Series for y", 
															choices = scatterChoices, selected = "comments"),
									selectInput("scatterY", label = "Choose Series for x", 
															choices = scatterChoices, selected = "steps"),
									actionButton("plotScatterButton", label = "Plot"),
									status = "primary", solidHeader = FALSE, width = 5, collapsible = TRUE),
							box(uiOutput("learnerStream"),
									textInput("filteredStreams", ""),
									status = "primary", solidHeader = FALSE, width = 5, collapsible = TRUE)
						),#fluidRow
						fluidRow(
							valueBoxOutput("scatterSlope", width = 5)
						)
		),
		tabItem(tabName = "cumulative_measures", 
						fluidRow(
							box(dygraphOutput("dateTimeSeries"),
									title = "Course Evolution",
									status = "primary", solidHeader = TRUE, width = 10, collapsible = TRUE)
						)
		),
		tabItem(tabName = "social_network_analysis",
						fluidRow(
							box(forceNetworkOutput("network", width = "100%", height = "900px"),
									title = "Learner Network",
									status = "primary", solidHeader = TRUE, width = 6, height = 950, collapsible = TRUE),
							column(width = 5,
										 box(dygraphOutput("densityAndReciprocity"),
												 title = "Density and Reciprocity",
												 status = "primary", solidHeader = TRUE, width = NULL, collapsible = TRUE),
										 box(dygraphOutput("degreeGraph"),
												 title = "Degree Centrality",
												 status = "primary", solidHeader = TRUE, width = NULL, collapsible = TRUE) 
										 
							)#column
						)#fluidRow
		)#tabItem
	),
	tags$h5(textOutput("updatedTime"))
)# dashboardBody

dashboardPage (header, sidebar, body, skin = "blue")# dashboardPage

