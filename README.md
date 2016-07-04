Overview
=========

The MOOC-Dashbaord has two components:  A data retrieval (update) script written in Python that downloads (meta)data about Massive Open Online Courses (MOOCs) from Futurelearn.com and a web application, written in R, that performs analysis and renders charts based on that data.


Data retrieval
--------------

This script (update/update.py) fetches (meta)data about Massive Open Online Courses (MOOCs) from FutureLearn.com for further processing and presentation by the R/Shiny based web application.
Collection is achieved by a combination of HTML scraping and assembling paths to CSV files.  Reliance on fixed URL paths and the naming of HTML elements makes this script fragile and liable to irreversible breakage without notice. As soon as FutureLearn make an API available, this script should be replaced.

The original author included the facility to export data to a MySQL databases (createTable.py, csvToSQL.py).  This facility is currently unused.


Web Application
--------------

Based on the [Shiny Dashboard](https://rstudio.github.io/shinydashboard/) Framework and running in [Shiny Server](https://www.rstudio.com/products/shiny/shiny-server/) this application analyses and plots the data fetched by the Data Retrieval script.

