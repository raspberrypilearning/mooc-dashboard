require(shiny)
require(shinydashboard)
require(rCharts)
require(dygraphs)
require(d3heatmap)
require(shinyGridster)
require(networkD3)
require(shinyjs)
source("learner_filters.R")
source("courses.R")

unis <- getListOfUniversities()

scatterChoices <- list("Number of comments" = "comments", "Number of replies" = "replies",
                        "Number of likes" = "likes",
                        "Number of submitted quiz responses" = "answers",
                        "Percentage of completed steps" = "steps",
                        "Percentage of correct answers" = "correct",
                        "Percentage of wrong answers" = "wrong",
                        "Percentage of completed questions" = "questions")

dashboardPage(
  dashboardHeader(title = "MOOC Dashboard", titleWidth = 250),
  dashboardSidebar(
    width = 250,
    sidebarMenu(
      menuItem("Home", tabName = "home", icon = icon("home")),
      menuItem("Dashboard", tabName = "dashboard", icon = icon("dashboard"),
               menuSubItem("Active courses", tabName = "active"),
               menuSubItem("Past courses", tabName = "past")),
      menuItem("Favourites", tabName = "favourites", icon = icon("star-o")),
      menuItem("Discussion", tabName = "forum", icon = icon("comment")),
      menuItem("Data tables", tabName = "data", icon = icon("table")),
      menuItem("Settings", tabName = "settings", icon = icon("cog"))
    )
  ),
  dashboardBody(
    useShinyjs(),
    tabItems(
      tabItem(tabName = "home",
              tags$h1("Welcome to MOOC Dashboard")
      ),
      tabItem(tabName = "past",
              fluidRow(
                box(
                    tags$div(style="display:inline-block; margin-right:15px", 
                             selectInput("university", label = "University", width = "350px",
                                         choices = unis, selected = "prompt")),
                    tags$div(style="display:inline-block; margin-right:15px",
                             uiOutput("course", inline = TRUE)),
                    tags$div(style="display:inline-block; margin-right:15px",
                             uiOutput("run", inline = TRUE)),
                    tags$div(style="display:inline-block; margin-right:15px",
                             uiOutput("startDate", inline = TRUE)),
                    tags$div(style="display:inline-block; margin-right:15px",
                             uiOutput("endDate", inline = TRUE)),
                    tags$div(style="display:inline-block",
                             uiOutput("chooseCourse", inline = TRUE)),
                    title = "Course selection",
                    status = "primary", solidHeader = TRUE, width = 12, collapsible = TRUE)
              ),
              fluidRow(
                column(width = 4,
                       box(d3heatmapOutput("stepDateCommentsHeat"),
                           title = "Number of Comments by Step and Date", 
                           status = "primary", solidHeader = TRUE, width = NULL, collapsible = TRUE),
                       box(showOutput("commentsRepliesWeekBar", "highcharts"),
                            title = "Comments and Replies by Week", 
                            status = "primary", solidHeader = TRUE, width = NULL, collapsible = TRUE),
                       box(showOutput("avgCommentsCompletionLine", "highcharts"),
                           title = "Average Number of Comments per Completion", 
                           status = "primary", solidHeader = TRUE, width = NULL, height = 270 ,collapsible = TRUE)

                ),
                column(width = 4,
                       box(includeHTML("funnel.html"),
                           title = "Funnel of Participation", 
                           status = "primary", solidHeader = TRUE, width = NULL, collapsible = TRUE),
                       box(showOutput("authorsWeekBar", "highcharts"),
                           title = "Number of Commentors by Week", 
                           status = "primary", solidHeader = TRUE, width = NULL, collapsible = TRUE),
                       valueBoxOutput("totalComments", width = 6),
                       valueBoxOutput("avgComments", width = 6),
                       valueBoxOutput("totalReplies", width = 6),
                       valueBoxOutput("avgReplies", width = 6)
                       
                       
                ),
                column(width = 2,
                       valueBoxOutput("enrolmentCount", width = NULL),
                       valueBoxOutput("completedCount", width = NULL),
                       box(showOutput("learnersAge", "highcharts"),
                           title = "Age Distribution", 
                           status = "primary", solidHeader = TRUE, width = NULL, collapsible = TRUE)
                       
                       
                ),
                column(width = 2,
                       valueBoxOutput("courseDuration", width = NULL),
                       valueBoxOutput("courseStart", width = NULL),
                       box(showOutput("learnersGender", "highcharts"),
                           title = "Male to Female Ratio", 
                           status = "primary", solidHeader = TRUE, width = NULL, collapsible = TRUE)
                       
                ),
                tabBox(
                  title = "Employment and Education",
                  id = "employmentTabBox",
                  width = 4,
                  tabPanel("Area", showOutput("employmentArea", "highcharts")),
                  tabPanel("Status", showOutput("employmentStatus", "highcharts")),
                  tabPanel("Degree", showOutput("degreeLevel", "highcharts"))
                )
            ),
            fluidRow(
              box(title = "Empty for now",
                  status = "primary", solidHeader = TRUE, width = 6, collapsible = TRUE),
              box(tags$div(style="display:inline-block; margin-right:15px",
                           textInput("gender", "Gender", value = "", width = "300px")),
                  tags$div(style="display:inline-block; margin-right:15px",
                           textInput("foundCourse", "How they found out about the course", value = "", width = "300px")),
                  tags$br(),
                  tags$div(style="display:inline-block; margin-right:15px",
                           textInput("age", "Age", value = "", width = "300px")),
                  tags$div(style="display:inline-block; margin-right:15px",
                           textInput("hopeCourse", "What they hope to achieve from the course", value = "", width = "300px")),
                  tags$br(),
                  tags$div(style="display:inline-block; margin-right:15px",
                           textInput("selected", "Country", value = "", width = "300px")),
                  tags$div(style="display:inline-block; margin-right:15px",
                           textInput("experience", "Past MOOC participation", value = "", width = "300px")),
                  tags$br(),
                  tags$div(style="display:inline-block; margin-right:15px",
                           textInput("emplArea", "Employment area", value = "", width = "300px")),
                  tags$div(style="display:inline-block; margin-right:15px",
                           textInput("subjects", "Interested subjects", value = "", width = "300px")),
                  tags$br(),
                  tags$div(style="display:inline-block; margin-right:15px",
                           textInput("emplStatus", "Employment status", value = "", width = "300px")),
                  tags$div(style="display:inline-block; margin-right:15px",
                           textInput("methods", "Learning methods", value = "", width = "300px")),
                  tags$br(),
                  tags$div(style="display:inline-block; margin-right:15px",
                           textInput("degree", "Degree", value = "", width = "300px")),
                  tags$div(style="display:inline-block; margin-right:15px",
                           textInput("place", "Learning place", value = "", width = "300px")),
                  tags$br(),
                  actionButton("resetFilters", "Reset"),
                  textInput("filteredLearners", ""),
                  title = "Filters",
                  status = "primary", solidHeader = TRUE, width = 6, collapsible = TRUE)
            ),
            fluidRow(
              box(htmlOutput("learnerMap"),
                  title = "Learners by country", 
                  status = "primary", solidHeader = TRUE, width = 8, height = 500,collapsible = TRUE),
              tabBox(
                title = "Survey Responses",
                id = "surveyTabBox",
                width = 4, height = 500,
                tabPanel("Found",
                         showOutput("howFoundCourse", "highcharts")
                ),
                tabPanel("Hopes",
                         showOutput("hopeGetFromCourse", "highcharts")
                ),
                tabPanel("Methods",
                         showOutput("learningMethods", "highcharts")
                ),
                tabPanel("Subjects",
                         showOutput("interestedSubjects", "highcharts")
                ),
                tabPanel("Experience",
                         showOutput("pastExperience", "highcharts")
                ),
                tabPanel("Place",
                         showOutput("learningPlace", "highcharts")
                )
              )
            ),
            fluidRow(
              box(htmlOutput("scatterPlot"),
                  textInput("scatterSlopeValue", ""),
                  title = "Scatter plot", 
                  status = "primary", solidHeader = TRUE, width = 8, collapsible = TRUE),
              column (width = 4,
                box(selectInput("scatterX", label = "Choose Series for y", 
                                choices = scatterChoices, selected = "comments"),
                    selectInput("scatterY", label = "Choose Series for x", 
                                choices = scatterChoices, selected = "steps"),
                    actionButton("plotScatterButton", label = "Plot"),
                    status = "primary", solidHeader = FALSE, width = NULL, collapsible = TRUE),
                box(uiOutput("learnerStream"),
                    textInput("filteredStreams", ""),
                    status = "primary", solidHeader = FALSE, width = NULL, collapsible = TRUE),
                valueBoxOutput("scatterSlope", width = 6)
              )      
            ),
            fluidRow(
              box(dygraphOutput("dateTimeSeries"),
                  title = "Course Evolution",
                  status = "primary", solidHeader = TRUE, width = 12, collapsible = TRUE)
            ),
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
                     
              )
            )
          )
        )
      )
    )
  
