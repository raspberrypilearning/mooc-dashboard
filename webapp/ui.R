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
require(plotly)
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

stepCompletionList <- list("Steps Marked As Complete" = "StepsMarkedAsComplete",
                           "Steps First Visited" = "StepsFirstVisited",
                           "Steps First Visited By Step And Date" = "StepsFirstVisitedByStepAndDate",
                           "Steps First Visited Per Day" = "StepsFirstVisitedPerDay",
                           "Steps Marked Completed Per Day" = "StepsMarkedCompletedPerDay",
                           "Steps Marked As Complete By Step And Date" = "StepsMarkedAsCompleteByStepAndDate")

commentOverviewList <- list("Number of Comments by Step" = "NumberofCommentsbyStep",
                            "Number of Comments per Day" = "NumberofCommentsperDay",
                            "Number of Comments by Step and Date" = "NumberofCommentsbyStepandDate",
                            "Comments and Replies by Week" = "CommentsandRepliesbyWeek",
                            "Number of Commentors by Week" = "NumberofCommentorsbyWeek")

commentsTypeAnalysisList <- list("Comments' Analysis Table" = "CommentsAnalysisTable",
                                 "Number And Type of Comments by Step" = "NumberAndTypeOfCommentsByStep",
                                 "Number and Type of Comments by Day" = "NumberAndTypeOfCommentsByDay",  
                                 "Comments by Category" = "CommentsByCategory")

header <- dashboardHeader(title = "MOOC Dashboard", titleWidth = 250)

sidebar <- dashboardSidebar(
  width = 250,
  sidebarMenu(
    id = "tabs", 
    menuItem("Home", tabName = "home", icon = icon("home")),
    menuItem("Aggregate Enrolment Data", tabName = "enrolment", icon = icon("database")),
    menuItem("Demographics", tabName = "demographics", icon = icon("bar-chart")),
    menuItem("Statement Demographics", tabName = "statementDemographics", icon = icon("pie-chart")),
    menuItem("Sign Ups and Statements Sold", tabName = "signUpsStatementsSold", icon = icon("area-chart")),
    menuItem("Step Completion", tabName = "stepCompletion", icon = icon("graduation-cap")),
    menuItem("Comments Overview", tabName = "commentsOverview", icon = icon("comments")),
    menuItem("Comments Type Analysis", tabName = "commentsTypeAnalysis", icon = icon("commenting")),
    menuItem("Comments Viewer", tabName = "commentsViewer", icon = icon("comments-o")),
    menuItem("Learners Analysis", tabName = "learnersAnalysis", icon = icon("user-circle-o")),
    menuItem("Total Measures", tabName = "totalMeasures", icon = icon("comment")),
    menuItem("Correlations", tabName = "correlations", icon = icon("puzzle-piece")),
    menuItem("Team Members", tabName = "teamMembers", icon = icon("users")),
    menuItem("Surveys Analysis", tabName = "surveysAnalysis", icon = icon("bookmark")),
    menuItem("Learner paths", tabName = "learnerPaths", icon = icon("random"))
    # ,menuItem("Cumulative Measures", tabName = "cumulative_measures", icon = icon("pie-chart"))
    # ,menuItem("Social Network Analysis", tabName = "social_network_analysis", icon = icon("hashtag"))
    # ,menuItem("Debug", tabName = "debug")
  )#sidebarMenu
)

body <- dashboardBody(
  useShinyjs(),
  tags$h2(paste(institution)),
  tags$h4(textOutput("pageTitle")),
  tags$p("Loading data for all courses may take a few minutes."),
  tabItems( 
    tabItem(tabName = "home",
            fluidRow(
              box(
                tags$div(style="display:inline-block; margin-right:15px", 
                         selectInput("course1", label = "Courses", width = "450px", choices = c("All",courses), selected = courses[1])),
                tags$div(style="display:inline-block; margin-right:15px", uiOutput("runs1", inline = TRUE)),
                title = "Course selection",
                status = "primary", solidHeader = TRUE, width = 10, collapsible = FALSE
              ),
              box(
                fixedRow(
                  column(
                    width = 6,
                    tags$div(radioButtons("rbChartDataType", "Display charts by:", c("Percentages" = "percentages", "Population" = "population"))),
                    fixedRow(
                      column(
                        width = 12,
                        selectInput("palette", " Heatmap Palette", c("Blues", "Reds", "Purples", "Oranges", "Greys", "Greens")),
                        fixedRow(
                          column(
                            width = 2,
                            # offset = 2,
                            tags$div(uiOutput("chooseCourse", inline = TRUE)))))))),
                title = "Customisation",
                status = "primary", solidHeader = TRUE, width = 2, collapsible = FALSE
              ),
              box(
                tags$div(style="display:inline-block; margin-right:15px", 
                         selectInput("course2", label = "Courses", width = "450px", choices = c("None",courses, "All"))),
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
                downloadButton('downloadLearnerAge', 'Download'),
                title = "Age Distribution", 
                status = "primary", solidHeader = TRUE, width = 8, collapsible = TRUE
              ),
              box(
                showOutput("learnersGender", "highcharts"),
                downloadButton('downloadLearnerGender', 'Download'),
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
                tabPanel("Area", 
                         fluidRow(
                           column(1,downloadButton('downloadLearnerEmployment','Download')),
                           column(12,showOutput("employmentBar", "highcharts"))
                         )
                ),
                tabPanel("Status", 
                         fluidRow(
                           column(1,downloadButton('downloadLearnerStatus','Download')),
                           column(12,showOutput("employmentStatus", "highcharts"))
                         )
                ),
                tabPanel("Degree", 
                         fluidRow(
                           column(1,downloadButton('downloadLearnerEducation','Download')),
                           column(12,showOutput("degreeLevel", "highcharts"))
                         )
                )
              )
            ),#fluidRow
            fluidRow(
              tabBox(
                title = "Regional",
                id = "regionalTabBox",
                width = 12,
                tabPanel("Country", 
                         fluidRow(
                           column(1,downloadButton('downloadCountryData', 'Download')),
                           column(12,htmlOutput("learnerMap"))
                         )
                ),
                tabPanel("HDI", 
                         fluidRow(
                           column(1,downloadButton('downloadHDIData','Download')),
                           column(12,showOutput("HDIColumn", "highcharts"))
                         )
                )
              )
            )#fluidRow
    ),
    tabItem(tabName = "statementDemographics",
            fluidRow(
              box(showOutput("stateAgeColumn","highcharts"),
                  downloadButton("downloadStateLearnerAge","Download"),
                  title = "Statements Sold Age Ranges",
                  status = "primary", solidHeader = TRUE, width = 8, collapsible = TRUE
              ), 
              height = 500,
              box(
                showOutput("stateGenderColumn","highcharts"),
                downloadButton("downloadStateLearnerGender","Download"),
                title = "Statements Sold Gender",
                status = "primary", solidHeader = TRUE, width = 4, collapsible = TRUE
              ), height = 500
            ),
            fluidRow(
              tabBox(
                title = "Employment and Education",
                id = "StatementsEmploymentTabBox",
                width = 12,
                height = 730,
                tabPanel("Area", 
                         fluidRow(
                           column(1,downloadButton("downloadStateLearnerEmployment","Download")),
                           column(12,showOutput("stateEmploymentAreaBar", "highcharts"))
                         )
                ),
                tabPanel("Status", 
                         fluidRow(
                           column(1,downloadButton("downloadStateLearnerStatus","Download")),
                           column(12, showOutput("stateEmploymentStatusColumn", "highcharts"))
                         )
                ),
                tabPanel("Degree", 
                         fluidRow(
                           column(1,downloadButton("downloadStateLearnerEducation","Download")),
                           column(12,showOutput("stateDegreeColumn", "highcharts"))
                         )
                )
              )
            ),
            fluidRow(
              tabBox(
                title = "Country Data",
                id = "statementsRegionalTabBox",
                width = 12,
                tabPanel("Countrys", 
                         fluidRow(
                           column(1,downloadButton("downloadStateLearnerCountry","Download")),
                           column(12,htmlOutput("stateLearnerMap"))
                         )
                ),
                tabPanel("HDI", 
                         fluidRow(
                           column(1,downloadButton("downloadStateLearnerHDI","Download")),
                           column(12,showOutput("stateHDIColumn", "highcharts"))
                         )
                )
              )
            )
    ),
    tabItem(tabName = "signUpsStatementsSold",
            fluidRow(
              box(
                showOutput("signUpsLine", "highcharts"),
                downloadButton("downloadSignUps","Download"),
                title = "Sign Ups per day",
                status = "primary", solidHeader = TRUE, width = 12, collapsible = TRUE
              ),
              box(
                showOutput("statementsSoldLine", "highcharts"),
                downloadButton("downloadStatementsSold","Download"),
                title = "Statements Sold per day",
                status = "primary", solidHeader = TRUE, width = 12, collapsible = TRUE
              )
            )
    ),
    tabItem(tabName = "stepCompletion",
            fluidRow(box(
              uiOutput("runSelectorSteps"),
              selectInput("graphName", label = "Choose a graph", 
                          choices = stepCompletionList, selected = "StepsMarkedAsComplete",width = 550),
              actionButton("runSelectorStepsButton", label = "Display"),
              title = "Run Selector",
              status = "primary", solidHeader = TRUE, width = 12, collapsible = TRUE
            )),
            fluidRow(box(
              showOutput("stepsCompleted","highcharts"),
              title = "Steps Marked As Complete",
              id="box1",
              status = "primary", solidHeader = TRUE, width = 12, collapsible = TRUE, collapsed = TRUE,
              tags$div(style = "margin-left:15px; font-size:15px ", textOutput("runTestTextSMC")), 
              tags$div(style = "display:inline-block; margin-left:15px", uiOutput("alphaValueSelectorSMC", inline = TRUE)),
              tags$div(style = "margin-left:15px", uiOutput("runTestButtonSMC")),
              tags$div(style = "margin-left:15px; color:  #002080; font-size:20px ", textOutput("testResultSMC")) 
            )),
            fluidRow(box(
              showOutput("StepsFirstVisited","highcharts"),
              title = "Steps First Visited",
              id="box2",
              status = "primary", solidHeader = TRUE, width = 12, collapsible = TRUE, collapsed = TRUE,
              tags$div(style = "margin-left:15px; font-size:15px ", textOutput("runTestTextSFV")), 
              tags$div(style = "display:inline-block; margin-left:15px", uiOutput("alphaValueSelectorSFV", inline = TRUE)),
              tags$div(style = "margin-left:15px", uiOutput("runTestButtonSFV")),
              tags$div(style = "margin-left:15px; color:  #002080; font-size:20px ", textOutput("testResultSFV")) 
            )),
            fluidRow(box(
              d3heatmapOutput("firstVisitedHeat"),
              title = "Steps First Visited By Step And Date",
              id="box3",
              status = "primary", solidHeader = TRUE, width = 12, collapsible = TRUE, collapsed = TRUE
            )),
            fluidRow(box(
              showOutput("firstVisitedPerDay","highcharts"),
              title = "Steps First Visited Per Day",
              id="box4",
              status = "primary", solidHeader = TRUE, width = 12, collapsible = TRUE, collapsed = TRUE
            )),
            fluidRow(box(
              showOutput("markedCompletedPerDay","highcharts"),
              title = "Steps Marked Completed Per Day",
              id="box5",
              status = "primary", solidHeader = TRUE, width = 12, collapsible = TRUE, collapsed = TRUE
            )),
            fluidRow(box(
              d3heatmapOutput("stepCompletionHeat"),
              title = "Steps Marked As Complete By Step And Date",
              id="box6",
              status = "primary", solidHeader = TRUE, width = 12, collapsible = TRUE, collapsed = TRUE
            ))
    ),
    tabItem(tabName = "commentsOverview",
            fluidRow(
              textInput("filteredLearners", ""),
              box(uiOutput("runSelectorComments"),
                  selectInput("commentovervewGraph", label = "Choose a graph",
                              choices = commentOverviewList, selected = "NumberofCommentsbyStep",width = 550),
                  actionButton("runSelectorCommentsButton", label = "Display"),
                  title = "Run Selector",
                  status = "primary", solidHeader = TRUE, width = 12, collapsible = TRUE
              ),
              box(showOutput("commentsBarChart", "highcharts"),
                  title = "Number of Comments by Step", 
                  id="commentBox1",
                  status = "primary", solidHeader = TRUE, width = 12, collapsible = TRUE, collapsed = TRUE
              ),
              
              box(showOutput("commentsPerDayBarChart", "highcharts"),
                  title = "Number of Comments per Day", 
                  id="commentBox2",
                  status = "primary", solidHeader = TRUE, width = 12, collapsible = TRUE, collapsed = TRUE
              ),
              box(d3heatmapOutput("stepDateCommentsHeat"),
                  title = "Number of Comments by Step and Date", 
                  id="commentBox3",
                  status = "primary", solidHeader = TRUE, width = 12, collapsible = TRUE, collapsed = TRUE
              )
            ),
            fluidRow(
              box(showOutput("commentsRepliesWeekBar", "highcharts"),
                  title = "Comments and Replies by Week",
                  id="commentBox4",
                  status = "primary", solidHeader = TRUE, width = 12, collapsible = TRUE, collapsed = TRUE),
              box(showOutput("authorsWeekBar", "highcharts"),
                  title = "Number of Commentors by Week", 
                  id="commentBox5",
                  status = "primary", solidHeader = TRUE, width = 12, collapsible = TRUE, collapsed = TRUE)
            )
    ),
    tabItem(tabName = "commentsTypeAnalysis",
            fluidRow(
              
              box(uiOutput("runSelectorCommentsType"),
                  selectInput("commentTypeOutput", label = "Choose an output",
                              choices = commentsTypeAnalysisList, selected = "CommentsAnalysisTable",width = 550),
                  actionButton("runSelectorCommentsTypeButton", label = "Display"),
                  title = "Run Selector",
                  status = "primary", solidHeader = TRUE, width = 12, collapsible = TRUE
              ),
              
              box(
                h5("Note: you can use the generated text-boxes below to filter comments based on each column's text-box."),
                DT::dataTableOutput("commentAnalysisTable"),
                
                #download button for comments analysis data - as a csv file
                downloadButton('downloadCommentAnalysis', ' Download as CSV'),
                title = "Comments' Analysis", 
                
                id="commentTypeBox1",
                status = "primary", solidHeader = TRUE, width = 12 ,collapsible = TRUE, collapsed = TRUE
              ), height = 1010,
              
              box(showOutput("commentsTypeBarChart", "highcharts"),
                  title = "Number and Types of Comments by Step", 
                  id="commentTypeBox2",
                  status = "primary", solidHeader = TRUE, width = 12, collapsible = TRUE, collapsed = TRUE
              ),
              
              box(showOutput("commentsTypeLineChart", "highcharts"),
                  title = "Number and Types of Comments by Day", 
                  id="commentTypeBox3",
                  status = "primary", solidHeader = TRUE, width = 12 ,collapsible = TRUE, collapsed = TRUE
              ),
              
              box(plotlyOutput("commentsByCategory"),
                  tags$hr(),
                  h4("LEGEND:"),
                  h5("Initiating posts = Posts that receive replies"),
                  h5("Lone posts = Posts that receive no replies, also including the replies posted by the same learner in response to his/her own post, where no other learners reply to that post"),
                  h5("First replies = Replies to others’ initiating posts, i.e., the first time or the only time a learner replies to an initiating post created by another learner "),
                  h5("Further replies = Further replies are replies that a learner makes under an initiating post that he/she has already replied to, i.e., the learner replies more than one time under an initiating post  "),
                  h5("Initiator's replies = Replies to others’ replies to one’s own initiating post, i.e., initiator replies under his/her own initiating post.  "),
                  title = "Comments by Category",
                  id="commentTypeBox4",
                  status = "primary", solidHeader = TRUE, width = 12, collapsible = TRUE, collapsed = TRUE)
            )    
    ),
    tabItem(tabName = "commentsViewer",
            fluidRow(
              box(
                fluidRow(
                  tags$div(style = "display:inline-block; margin-left:15px", uiOutput("commentRunSelector", inline = TRUE)),
                  # tags$div(style = "display:inline-block; margin-left:15px", uiOutput("runSteps", inline = TRUE)),
                  # tags$div(style = "display:inline-block; margin-left:15px", uiOutput("commentDateRange")),
                  tags$div(style = "margin-left:15px", uiOutput("viewButton")),
                  tags$br(),
                  tags$div(style = "display:inline-block; margin-left:15px", sliderInput("commentCloudFreq", "Minimum Frequency of Words:",
                                                                                         min = 1, max = 100, value = 50, width = "550px")),
                  tags$div(style = "display:inline-block; margin-left:15px", sliderInput("commentCloudMax", "Maximum Number of Words:",
                                                                                         min = 1, max = 100, value = 50, width = "550px")),
                  tags$div(style = "margin-left:15px", uiOutput("loadCloud"))
                ),
                title = "Selector", 
                status = "primary", solidHeader = TRUE, width = 6 ,collapsible = TRUE	
              ), height = 460,
              box(
                plotOutput("stepWordCloud"),
                title = "Word Cloud",
                status = "primary", solidHeader = TRUE, width = 6, collapsible = TRUE
              ), height = 460
            ),
            fluidRow(
              box(
                h5("Note: you can use the generated text-boxes below to filter comments based on each column's text-box."),
                DT::dataTableOutput("commentViewer"),
                
                #download button for comment viewer data - as a csv file
                downloadButton('downloadCommentViewer', ' Download as CSV'),
                title = "Comments", 
                status = "primary", solidHeader = TRUE, width = 12, collapsible = TRUE
              ), height = 1010
            ),
            fluidRow(
              box(
                DT::dataTableOutput("threadViewer"),
                
                #download button for thread viewer data - as a csv file
                downloadButton('downloadThreadViewer', ' Download as CSV'),
                title = "Comment Thread Viewer", 
                status = "primary", solidHeader = TRUE, width = 12,collapsible = TRUE
              ), height = 1000 
            )
    ),
    tabItem(tabName = "learnersAnalysis",
            fluidRow(
              box(
                fluidRow(
                  tags$div(style = "display:inline-block; margin-left:15px", uiOutput("learnersRunSelector", inline = TRUE)),
                  tags$div(style = "margin-left:15px", uiOutput("viewLearnersButton"))
                ),
                title = "Selector", 
                status = "primary", solidHeader = TRUE, width = 12 ,collapsible = TRUE	
              )
            ),
            fluidRow(
              box(
                  plotlyOutput("learnersByCategory"),
                  tags$hr(),
                  h4("LEGEND:"),
                  h5("Loners = Never received replies"),
                  h5("Repliers = Only replied to others "),
                  h5("Initiators without replying = Never replied to others’ posts or underneath own initiating posts "),
                  h5("Initiators who respond under their own posts = Never replied to others’ posts or underneath own initiating posts "),
                  h5("Active social learners = Initiated posts, replied to others, and engaging in repeated turn-taking by replying under own initiating post or further replying "),
                  h5("Active social learners without repeated turn-taking = Created posts, replied to others but never replied under own initiating post or further replied "),
                  h5("Reluctant active social learners = Created lone posts, replied to others, further replied "),
                  #tags$hr(),
                   # tags$div(style = "display:inline-block; margin-left:15px", uiOutput("learnersTypeSelector", inline = TRUE)),
                 # tags$div(style = "margin-left:15px", uiOutput("viewLearnersActivityButton")),
                  title = "Learners by Category",
                  status = "primary", solidHeader = TRUE, width = 12, collapsible = TRUE)
            ),
            fluidRow(
              box(
                h5("Note: you can click on the learner id to see the comments by individual learners."),
                DT::dataTableOutput("learnerActivityViewer"),
                
                #download button for learners activity data - as a csv file
                downloadButton('downloadLearnersActivity', ' Download as CSV'),
                title = "Learners' Activity", 
                status = "primary", solidHeader = TRUE, width = 12, collapsible = TRUE
              ), height = 1010 
            ),
            fluidRow(
              box(
                DT::dataTableOutput("commentLearnersAnalysisViewer"),
                
                #download button for comments contributed data - as a csv file
                downloadButton('downloadCommentsContributed', ' Download as CSV'),
                title = "Comments Contributed Viewer", 
                status = "primary", solidHeader = TRUE, width = 12,collapsible = TRUE
              ), height = 1000 
            )
    ),
    tabItem(tabName = "totalMeasures",
            fluidRow(
              box(uiOutput("totalMeasuresRunSelector"),
                  title = "Run Selector",
                  status = "primary", solidHeader = TRUE, width = 12, collapsible = TRUE)
            ),
            fluidRow(
              box(showOutput("avgCommentsCompletionLine", "highcharts"),
                  title = "Average Number of Comments per Completion", 
                  status = "primary", solidHeader = TRUE, width = 12, height = 700, collapsible = TRUE)
            ), 
            fluidRow(
              valueBoxOutput("totalComments", width = 6),
              valueBoxOutput("avgComments", width = 6),
              valueBoxOutput("totalReplies", width = 6),
              valueBoxOutput("avgReplies", width = 6)
            )#fluidRow
    ),
    tabItem(tabName = "correlations",
            fluidRow(
              box(uiOutput("correlationsRunSelector"),
                  selectInput("scatterX", label = "Choose Series for y", 
                              choices = scatterChoices, selected = "comments",width = 550),
                  selectInput("scatterY", label = "Choose Series for x", 
                              choices = scatterChoices, selected = "steps", width = 550),
                  actionButton("plotScatterButton", label = "Plot"),
                  title = "Selector",
                  status = "primary", solidHeader = TRUE, width = 12, collapsible = TRUE)
            ),#fluidRow
            fluidRow(
              box(htmlOutput("scatterPlot"),
                  textInput("scatterSlopeValue", ""),
                  title = "Scatter plot", 
                  status = "primary", solidHeader = TRUE, width = 12, height = 700, collapsible = TRUE)
            ), 
            fluidRow(
              valueBoxOutput("scatterSlope", width = 6)
            )#fluidRow
    ),#tabItem
    
    tabItem(tabName = "teamMembers",
            fluidRow(
              box(
                fluidRow(
                  tags$div(style = "display:inline-block; margin-left:15px", uiOutput("memberSelector", inline = TRUE)),
                  tags$div(style = "margin-left:15px", uiOutput("viewTeamButton"))
                ),
                title = "Run Selector",
                status = "primary", solidHeader = TRUE, width = 12, collapsible = TRUE
              ), height = 200
            ),
            
            fluidRow(
              box(
                DT::dataTableOutput("teamMembersViewer"),
                
                #download button for team members data - as a csv file
                downloadButton('downloadTeamMembers', ' Download as CSV'),
                title = "Team Members Activity",
                status = "primary", solidHeader = TRUE, width = 12, collapsible = TRUE
              ), height = 1000
            )
    ),
    
    tabItem(tabName = "surveysAnalysis",
            fluidRow(
                     box(
                       fluidRow(
                         tags$div(style = "display:inline-block; margin-left:15px", uiOutput("surveyRunSelector", inline = TRUE))
                         
                         ),
                       fluidRow(
                         #this button allows the user to upload csv files for pre and post survey responses
                         tags$div(style = "display:inline-block; margin-left:15px",fileInput('fileChooserSurveyPre','Choose CSV File', accept=c('text/csv', 'text/comma-separated-values,text/plain', '.csv'), width = "450px")
                         ),
                         tags$div(style = "margin-left:15px", uiOutput("viewSurAnButton"))
                       ),
                       title = "Uploading Files and Run Selector",
                       status = "primary", solidHeader = TRUE, width = 12, collapsible = TRUE
                     ), height = 300 
                     ),
            
            fluidRow(
              box(
                DT::dataTableOutput("surveyAnalysisTable"),
                
                #download button for the survey analysis data - as a csv file
                downloadButton('downloadSurveyAnalysis', ' Download as CSV'),
                
                title = "Pre-Course survey and Comments in step 1.2",
                status = "primary", solidHeader = TRUE, width = 12, collapsible = TRUE
              ), height = 1300
            )
    ),
    
    tabItem(tabName = "learnerPaths",
            fluidRow(
              box(
                fluidRow(
                  tags$div(style = "display:inline-block; margin-left:15px", uiOutput("runPathSelector", inline = TRUE))
                ),
                fluidRow(
                  tags$div(style = "display:inline-block; margin-left:15px", uiOutput("weekPathSelector", inline = TRUE)),
                  tags$div(style = "margin-left:15px", uiOutput("viewWeekPathButton"))
                ),
                  title = "Course run and week selector",
                  status = "primary", solidHeader = TRUE, width = 12, collapsible = TRUE
            )), 
            fluidRow(
              box(
                tags$div(style = "margin-left:15px; font-size:15px ", textOutput("sankeyNotes")), 
                sankeyNetworkOutput("sankeyLearnerPaths", width = "100%", height = "500px"),
                title = "Learner paths by course week", 
                status = "primary", solidHeader = TRUE, width = 12 ,collapsible = TRUE
              )
            )

    )
  )
)

# 
# 	)
# )
# ,tabItem(tabName = "cumulative_measures", 
# 	fluidRow(
# 		box(dygraphOutput("dateTimeSeries"),
# 			title = "Course Evolution",
# 			status = "primary", solidHeader = TRUE, width = 12, collapsible = TRUE)
# 	)
# ),
# tabItem(tabName = "social_network_analysis",
# 	fluidRow(
# 		box(forceNetworkOutput("network", width = "100%", height = "900px"),
# 				title = "Learner Network",
# 				status = "primary", solidHeader = TRUE, width = 6, height = 950, collapsible = TRUE),
# 		column(width = 6,
# 		 box(dygraphOutput("densityAndReciprocity"),
# 				 title = "Density and Reciprocity",
# 				 status = "primary", solidHeader = TRUE, width = NULL, collapsible = TRUE),
# 		 box(dygraphOutput("degreeGraph"),
# 				 title = "Degree Centrality",
# 				 status = "primary", solidHeader = TRUE, width = NULL, collapsible = TRUE)
# 		)#column
# 	)#fluidRow
# )
# ,#tabItem
# tabItem(tabName = "debug",
# 	fluidRow(
# 		box(textOutput("debug"),
# 			width = 12)
# 	)
# )


tags$h5(textOutput("updatedTime"))

dashboardPage (header, sidebar, body, skin = "blue") # dashboardPage
