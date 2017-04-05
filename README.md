Overview
=========

The MOOC-Dashboard has been separated into 3 components. A data retrieval (update) script written in Python and contained in the data-layer, that downloads (meta)data about Massive Open Online Courses (MOOCs) from Futurelearn.com; a db-layer that stores the data retrieved in the data-layer in a MySQL database and manages the database; and an Shiny web application, written in R, that performs analysis and renders charts based on that data.

Data Layer
--------------

This layer performs the data retrieval. It uses the update script (update/update.py) and fetches (meta)data about Massive Open Online Courses (MOOCs) from FutureLearn.com. This data is then taken by the DB layer and stored in a database.


DB Layer
--------

This layer stores the data retrieved from FutureLearn in a MySQL database and manages that database. This data is then used for further processing and presentation by the R/Shiny based web application.

Django Application
------------------

A Django application with a dashboard and data component. The data component links the MySQL database from the DB layer with the application and contains the appropriate models.

This application uses Django models to make SQL queries that are much faster than the R processing in the legacy application. 

Legacy Web Application
----------------------

Based on the [Shiny Dashboard](https://rstudio.github.io/shinydashboard/) Framework and running in [Shiny Server](https://www.rstudio.com/products/shiny/shiny-server/) this application analyses and plots the data stored in the database of the db-layer.

