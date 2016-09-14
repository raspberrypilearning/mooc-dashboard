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
		menuItem("Statement Demographics", tabName = "statementDemographics", icon = icon("pie-chart")),
		menuItem("Sign Ups and Statements Sold", tabName = "signUpsStatementsSold", icon = icon("graduation-cap")),
		menuItem("Step Completion", tabName = "step_completion", icon = icon("graduation-cap")),
		menuItem("Comments Overview", tabName = "commentsOverview", icon = icon("commenting-o")),
		menuItem("Comments Viewer", tabName = "commentsViewer", icon = icon("commenting-o")),
		menuItem("Total Measures", tabName = "total_measures", icon = icon("comments")),
		menuItem("Correlations", tabName = "correlations", icon = icon("puzzle-piece")),
		menuItem("Cumulative Measures", tabName = "cumulative_measures", icon = icon("pie-chart")),
		menuItem("Social Network Analysis", tabName = "social_network_analysis", icon = icon("hashtag")),
		menuItem("Debug", tabName = "debug")
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
						selectInput("course1", label = "Courses", width = "450px", choices = c("All",courses))),
					tags$div(style="display:inline-block; margin-right:15px", uiOutput("runs1", inline = TRUE)),
					title = "Course selection",
					status = "primary", solidHeader = TRUE, width = 10, collapsible = FALSE
				),
				box(
					tags$div(uiOutput("chooseCourse", inline = TRUE)),
					title = "Go",
					status = "primary", solidHeader = TRUE, width = 2, collapsible = FALSE
				),
				box(
					tags$div(style="display:inline-block; margin-right:15px", 
						selectInput("course2", label = "Courses", width = "450px", choices = c("None",courses))),
					tags$div(style="display:inline-block; margin-right:15px", uiOutput("runs2", inline = TRUE)),
					title = "Course selection",
					status = "primary", solidHeader = TRUE, width = 10, collapsible = FALSE
				),
				box(
					tags$div(style="display:inline-block; margin-right:15px", 
						selectInput("course3", label = "Courses", width = "450px", choices = c("None",courses))),
					tags$div(style="display:inline-block; margin-right:15px", uiOutput("runs3", inline = TRUE)),
					title = "Course selection",
					status = "primary", solidHeader = TRUE, width = 10, collapsible = FALSE
				),
				box(
					tags$div(style="display:inline-block; margin-right:15px", 
						selectInput("course4", label = "Courses", width = "450px", choices = c("None",courses))),
					tags$div(style="display:inline-block; margin-right:15px", uiOutput("runs4", inline = TRUE)),
					title = "Course selection",
					status = "primary", solidHeader = TRUE, width = 10, collapsible = FALSE
				)
			)
		),
		tabItem(tabName = "enrolment",
			fluidRow(
				box(
					title = "Aggregate Enrolment Data",
					status = "primary", solidHeader = TRUE, width = 12, collapsible = TRUE,
					DT::dataTableOutput('aggregateEnrolmentData', width = "100%")
				),
				valueBoxOutput("totalJoiners", width = 6),
				valueBoxOutput("totalLearners", width = 6),
				valueBoxOutput("totalStatementsSold", width = 6)
			)
		),
		tabItem(tabName = "demographics",
			fluidRow(
				box(
					showOutput("learnersAgeBar", "highcharts"),
					title = "Age Distribution", 
					status = "primary", solidHeader = TRUE, width = 8, collapsible = TRUE
				),
				box(
					showOutput("learnersGender", "highcharts"),
					title = "Gender",
					status = "primary", solidHeader = TRUE, width = 4, collapsible = TRUE
				)
			),
			fluidRow(
				tabBox(
					title = "Employment and Education",
					id = "employmentTabBox",
					width = 12,
					height = 730,
					tabPanel("Area", showOutput("employmentBar", "highcharts")),
					tabPanel("Status", showOutput("employmentStatus", "highcharts")),
					tabPanel("Degree", showOutput("degreeLevel", "highcharts"))
				)
			),#fluidRow
			fluidRow(
				tabBox(
					title = "Regional",
					id = "regionalTabBox",
					width = 12,
					tabPanel("Country", htmlOutput("learnerMap")),
					tabPanel("HDI", showOutput("HDIColumn", "highcharts"))
				)
			)#fluidRow
		),
		tabItem(tabName = "statementDemographics",
			fluidRow(
				box(showOutput("AllvsFPvsStateAgeBar","highcharts"),
					title = "Statements Sold Age Ranges",
					status = "primary", solidHeader = TRUE, width = 8, height = 500,collapsible = TRUE
				),
				box(
					showOutput("AllvsFPvsStateGenderColumn","highcharts"),
					title = "Statements Sold Gender",
					status = "primary", solidHeader = TRUE, width = 4, height = 500,collapsible = TRUE
				)
			),
			fluidRow(
				tabBox(
					title = "Employment and Education",
					id = "StatementsEmploymentTabBox",
					width = 12,
					height = 730,
					tabPanel("Area", showOutput("AllvsFPvsStateEmploymentAreaBar", "highcharts")),
					tabPanel("Status", showOutput("AllvsFPvsStateEmploymentStatusBar", "highcharts")),
					tabPanel("Degree", showOutput("AllvsFPvsStateDegreeBar", "highcharts"))
				)
			),
			fluidRow(
				tabBox(
					title = "Country Data",
					id = "statementsRegionalTabBox",
					width = 12,
					height = 1600,
					tabPanel("Countrys", htmlOutput("statementLearnerMap")),
					tabPanel("HDI", showOutput("allvsFPvsStateHDIColumn", "highcharts"))
				)
			)
		),
		tabItem(tabName = "signUpsStatementsSold",
			fluidRow(
				box(
					showOutput("signUpsLine", "highcharts"),
					title = "Sign Ups per day",
					status = "primary", solidHeader = TRUE, width = 12, collapsible = TRUE
				),
				box(
					showOutput("statementsSoldLine", "highcharts"),
					title = "Statements Sold per day",
					status = "primary", solidHeader = TRUE, width = 12, collapsible = TRUE
				)
			)
		),
		tabItem(tabName = "step_completion",
			fluidRow(
				box(
					uiOutput("runSelectorSteps"),
					title = "Run Selector",
					status = "primary", solidHeader = TRUE, width = 12, collapsible = TRUE
				),
				box(
					showOutput("stepsCompleted","highcharts"),
					title = "Steps Marked As Complete",
					status = "primary", solidHeader = TRUE, width = 12, collapsible = TRUE
				),
				box(
					d3heatmapOutput("firstVisitedHeat"),
					title = "Steps First Visited By Step And Date",
					status = "primary", solidHeader = TRUE, width = 12, collapsible = TRUE
				),
				box(
					d3heatmapOutput("stepCompletionHeat"),
					title = "Steps Marked As Complete By Step And Date",
					status = "primary", solidHeader = TRUE, width = 12, collapsible = TRUE
				)
			)
		),
		tabItem(tabName = "commentsOverview",
			fluidRow(
				textInput("filteredLearners", ""),
				box(uiOutput("runSelectorComments"),
					title = "Run Selector",
					status = "primary", solidHeader = TRUE, width = 12, collapsible = TRUE
				),
				box(showOutput("commentsBarChart", "highcharts"),
					title = "Number of Comments by Step", 
					status = "primary", solidHeader = TRUE, width = 12, collapsible = TRUE
				),
				box(d3heatmapOutput("stepDateCommentsHeat"),
					title = "Number of Comments by Step and Date", 
					status = "primary", solidHeader = TRUE, width = 12, collapsible = TRUE
				)
			),#fluidRow
			fluidRow(
				box(showOutput("commentsRepliesWeekBar", "highcharts"),
					title = "Comments and Replies by Week", 
					status = "primary", solidHeader = TRUE, width = 6, collapsible = TRUE),
				box(showOutput("authorsWeekBar", "highcharts"),
					title = "Number of Commentors by Week", 
					status = "primary", solidHeader = TRUE, width = 6, collapsible = TRUE)
			)#fluidRow
		),
		tabItem(tabName = "commentsViewer",
			fluidRow(
				box(
					fluidRow(
						tags$div(style = "display:inline-block; margin-left:15px", uiOutput("runSelector", inline = TRUE)),
						tags$div(style = "display:inline-block; margin-left:15px", uiOutput("runSteps", inline = TRUE)),
						tags$div(style = "display:inline-block; margin-left:15px", uiOutput("commentDateRange")),
						tags$div(style = "margin-left:15px", uiOutput("viewButton")),
						tags$br(),
						tags$div(style = "display:inline-block; margin-left:15px", sliderInput("commentCloudFreq", "Minimum Frequency of Words:",
							min = 1, max = 100, value = 50, width = "550px")),
						tags$div(style = "display:inline-block; margin-left:15px", sliderInput("commentCloudMax", "Maximum Number of Words:",
							min = 1, max = 100, value = 50, width = "550px")),
						tags$div(style = "margin-left:15px", uiOutput("loadCloud"))
						),
					title = "Selector", 
					status = "primary", solidHeader = TRUE, width = 6, height = 460 ,collapsible = TRUE	
				),
				box(
					plotOutput("stepWordCloud"),
					title = "Word Cloud",
					status = "primary", solidHeader = TRUE, width = 6, height = 460, collapsible = TRUE
				)
			),
			fluidRow(
				box(
					DT::dataTableOutput("commentViewer"),
					title = "Comments", 
					status = "primary", solidHeader = TRUE, width = 12, height = 1000 ,collapsible = TRUE
				)
			),
			fluidRow(
				box(
					DT::dataTableOutput("threadViewer"),
					title = "Comment Thread Viewer", 
					status = "primary", solidHeader = TRUE, width = 12, height = 1000 ,collapsible = TRUE
				)
			)
		),
		tabItem(tabName = "total_measures",
			fluidRow(
				valueBoxOutput("totalComments", width = 6),
				valueBoxOutput("avgComments", width = 6),
				valueBoxOutput("totalReplies", width = 6),
				valueBoxOutput("avgReplies", width = 6)
			),#fluidRow
			fluidRow(
				box(showOutput("avgCommentsCompletionLine", "highcharts"),
					title = "Average Number of Comments per Completion", 
					status = "primary", solidHeader = TRUE, width = 12, height = 270 ,collapsible = TRUE)
			)#fluidRow
		),
		tabItem(tabName = "correlations",
			fluidRow(
				box(htmlOutput("scatterPlot"),
					textInput("scatterSlopeValue", ""),
					title = "Scatter plot", 
					status = "primary", solidHeader = TRUE, width = 12, collapsible = TRUE)
			),#fluidRow
			fluidRow(
				box(selectInput("scatterX", label = "Choose Series for y", 
						choices = scatterChoices, selected = "comments"),
					selectInput("scatterY", label = "Choose Series for x", 
						choices = scatterChoices, selected = "steps"),
					actionButton("plotScatterButton", label = "Plot"),
					status = "primary", solidHeader = FALSE, width = 6, collapsible = TRUE),
				box(uiOutput("learnerStream"),
					textInput("filteredStreams", ""),
					status = "primary", solidHeader = FALSE, width = 6, collapsible = TRUE
				)
			),#fluidRow
			fluidRow(
				valueBoxOutput("scatterSlope", width = 6)
			)
		),
		tabItem(tabName = "cumulative_measures", 
			fluidRow(
				box(dygraphOutput("dateTimeSeries"),
					title = "Course Evolution",
					status = "primary", solidHeader = TRUE, width = 12, collapsible = TRUE)
			)
		),
		tabItem(tabName = "social_network_analysis",
			fluidRow(
				box(forceNetworkOutput("network", width = "100%", height = "900px"),
						title = "Learner Network",
						status = "primary", solidHeader = TRUE, width = 6, height = 950, collapsible = TRUE),
				column(width = 6,
				 box(dygraphOutput("densityAndReciprocity"),
						 title = "Density and Reciprocity",
						 status = "primary", solidHeader = TRUE, width = NULL, collapsible = TRUE),
				 box(dygraphOutput("degreeGraph"),
						 title = "Degree Centrality",
						 status = "primary", solidHeader = TRUE, width = NULL, collapsible = TRUE)
				)#column
			)#fluidRow
		),#tabItem
		tabItem(tabName = "debug",
			fluidRow(
				box(textOutput("debug"),
					width = 12)
			)
		)
	),
	tags$h5(textOutput("updatedTime"))
)# dashboardBody

dashboardPage (header, sidebar, body, skin = "blue")# dashboardPage

