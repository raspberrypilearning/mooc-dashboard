from django.db import models
from django.db.models import Count
from ..data.models import LearnerEnrolment
from .widgets.charts import ColumnChart,BarChart,LineChart,GeoChart

#Demographic Widgets
class AgeDistributionWidget(ColumnChart):
    title = 'Age Distribution'
    width = 8
    category = 'age_range'
    options = "'chartArea': {'width': '90%', 'height': '70%'}"

    uniqid = 0

class GenderWidget(ColumnChart):
	title = 'Gender'
	width = 4
	category = 'gender'
	options = "'chartArea': {'width': '75%', 'height': '70%'}"

	uniqid = 1

class EmploymentAreaWidget(BarChart):
	title = 'Area'
	width = 12
	category = 'employment_area'
	height = 600
	options = "'chartArea': {'width': '50%', 'height': '90%'}"

	uniqid = 2

class EmploymentStatusWidget(BarChart):
	title = 'Status'
	width = 12
	category = 'employment_status'
	height = 600
	options = "'chartArea': {'width': '50%', 'height': '90%'}"

	uniqid = 3

class EducationLevelWidget(BarChart):
	title = 'Degree'
	width = 12
	category = 'highest_education_level'
	height = 600
	options = "'chartArea': {'width': '50%', 'height': '90%'}"

	uniqid = 4

class GeoWidget(GeoChart):
	title = 'Country'
	width = 12
	height = 600
	category = 'country'

	uniqid = 5

class HumanDevelopmentIndexWidget(ColumnChart):
	title = 'Degree'
	width = 12
	category = 'highest_education_level'
	height = 300
	#options = "'chartArea': {'width': '50%', 'height': '90%'}"

	uniqid = 6


#Sign Ups and Statements Sold Widgets
class SignUpsPerDayWidget(LineChart):
	title = 'Sign Ups per day'
	width = 12
	category = 'enrolled_at'

	uniqid = 0

class StatementsSoldPerDayWidget(LineChart):
	title = 'Statements Sold per day'
	width = 12
	category = 'purchased_statement_at'


	uniqid = 1

#Step Completion Widgets
