Overview
=========

The MOOC-Dashbaord has three components:  A data retrieval (update) script written in Python that downloads (meta)data about Massive Open Online Courses (MOOCs) from Futurelearn.com, a mysql database which stores the data and a web application, written in R, that performs analysis and renders charts based on that data.


Data retrieval
--------------

This script (update/update.py) fetches (meta)data about Massive Open Online Courses (MOOCs) from FutureLearn.com for further processing and presentation by the R/Shiny based web application.

Data scraped by beautiful soup for each course where available:

csv files from futurelearn:
comments.csv
enrolments.csv
question-response.csv
step-activity.csv
team-members.csv

Specifically web scraped data:
run_id (eg: 1)
start_date 
no_of_weeks
joiners
leavers
learners
active_learners
returning_learners
social_learners
fully_participating_learners
statements_sold
course (eg: Course full name)
course_run (eg: agincourt - 1)

Web Application
--------------

Based on the [Shiny Dashboard](https://rstudio.github.io/shinydashboard/) Framework and running in [Shiny Server](https://www.rstudio.com/products/shiny/shiny-server/) this application analyses and plots the data fetched by the Data Retrieval script.

