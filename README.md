Overview
=========

The MOOC-Dashbaord has two components:  A data retrieval (update) script written in Python that downloads (meta)data about Massive Open Online Courses (MOOCs) from Futurelearn.com and a web application, written in R, that performs analysis and renders charts based on that data.


Data retrieval
--------------

This script (update/update.py) fetches (meta)data about Massive Open Online Courses (MOOCs) from FutureLearn.com for further processing and presentation by the R/Shiny based web application.


Web Application
--------------

Based on the [Shiny Dashboard](https://rstudio.github.io/shinydashboard/) Framework and running in [Shiny Server](https://www.rstudio.com/products/shiny/shiny-server/) this application analyses and plots the data fetched by the Data Retrieval script.

