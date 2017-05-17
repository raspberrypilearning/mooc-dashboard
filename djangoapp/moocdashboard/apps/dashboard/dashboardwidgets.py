from django.db import models
from django.db.models import Count

from .models import AggregateCourse,LearnerEnrolment, LearnerActivity, Comment
from .widgets.charts import ColumnChart,BarChart,LineChart,GeoChart,HeatMapChart
from .widgets.core import Table,DynamicTable,ValueBox, WordCloud

#Course List Widgets
class CourseListWidget(Table):
	title = 'Aggregate Enrolment Data'
	model = AggregateCourse

	ajax_url = '/get_course_list/'

	columns = ['course_run','start_date','no_of_weeks','joiners','leavers','learners','active_learners','returning_learners','social_learners','fully_participating_learners','statements_sold']

	uniqid = 0

	column_labels = {
        'course_run': 'Course Run',
        'start_date': 'Start Date',
        'no_of_weeks': 'Weeks',
        'joiners': 'Joiners',
        'leavers': 'Leavers (Joiners who leave the course)',
        'learners': 'Learners (Joiners who view a step)',
        'active_learners': 'Active Learners (Learners who mark as complete)',
        'returning_learners': 'Returning Learners (Learners who mark as complete in two weeks)',
        'social_learners': 'Social Learners (Learners who make comments)',
        'fully_participating_learners': 'Fully Participating Learners (Learners who complete 50% of steps + assessments)',
        'statements_sold': 'Statements Sold'
    }

#Demographic Widgets
class AgeDistributionWidget(ColumnChart):
    title = 'Age Distribution'
    model = LearnerEnrolment
    width = 8
    category = 'age_range'
    options = "'chartArea': {'width': '90%', 'height': '70%'}"

    uniqid = 0

class GenderWidget(ColumnChart):
	title = 'Gender'
	model = LearnerEnrolment
	width = 4
	category = 'gender'
	options = "'chartArea': {'width': '75%', 'height': '70%'}"

	uniqid = 1

class EmploymentAreaWidget(BarChart):
	title = 'Area'
	model = LearnerEnrolment
	category = 'employment_area'
	height = 600
	options = "'chartArea': {'width': '50%', 'height': '90%'}"

	uniqid = 2

class EmploymentStatusWidget(BarChart):
	title = 'Status'
	model = LearnerEnrolment
	category = 'employment_status'
	height = 600
	options = "'chartArea': {'width': '50%', 'height': '90%'}"

	uniqid = 3

class EducationLevelWidget(BarChart):
	title = 'Degree'
	model = LearnerEnrolment
	category = 'highest_education_level'
	height = 600
	options = "'chartArea': {'width': '50%', 'height': '90%'}"

	uniqid = 4

class GeoWidget(GeoChart):
	title = 'Country'
	model = LearnerEnrolment
	height = 600
	category = 'country'

	uniqid = 5

class HumanDevelopmentIndexWidget(ColumnChart):
	title = 'Degree'
	model = LearnerEnrolment
	category = 'highest_education_level'
	#options = "'chartArea': {'width': '50%', 'height': '90%'}"

	uniqid = 6


#Sign Ups and Statements Sold Widgets
class SignUpsPerDayWidget(LineChart):
	title = 'Sign Ups per day'
	model = LearnerEnrolment
	height = 400
	category = 'enrolled_at'
	options = "'chartArea': {'width': '90%'}"
	#options = "'chartArea': {'width': '90%', 'height': '80%'}, 'hAxis': {'title':'Day'}"

	uniqid = 0

class StatementsSoldPerDayWidget(LineChart):
	title = 'Statements Sold per day'
	model = LearnerEnrolment
	category = 'purchased_statement_at'
	options = "'chartArea': {'width': '90%'}"


	uniqid = 1

#Step Completion Widgets
class StepsMarkedAsComplete(ColumnChart):
	title = 'Steps Marked As Complete'
	model = LearnerActivity
	height = 400
	category = 'last_completed_at'
	options = "'chartArea': {'width': '90%'}"

	uniqid = 0

class StepsFirstVisitedByStepAndDate(HeatMapChart):
	title = 'Steps First Visited by Step and Date'
	model = LearnerActivity
	height = 400
	category = 'first_visited_at'

	uniqid = 1

class StepsMarkedAsCompleteByStepAndDate(HeatMapChart):
	title = 'Steps Marked as Completed by Step and Date'
	model = LearnerActivity
	height = 400
	category = 'last_completed_at'

	uniqid = 2

class StepsCompleted(ValueBox):
	title = 'Steps Completed'
	model = LearnerActivity

	value = 10

#Comments Overview Widgets
class NumberOfCommentsByStep(ColumnChart):
	title = 'Number of Comments by Step'
	model = Comment
	height = 400
	category = 'comments_step'

	uniqid = 0
	options = "isStacked: true, 'chartArea': {'width': '90%'}"

class NumberOfCommentsByStepAndDate(HeatMapChart):
	title = 'Number of Comments by Step and Date'
	model = Comment
	height = 400
	category = 'timestamp'

	uniqid = 1

class CommentsAndRepliesByWeek(ColumnChart):
	title = 'Comments and Replies by Week'
	model = Comment
	width = 6
	height = 400
	category = 'comments_week'

	uniqid = 2
	options = "isStacked: true, 'chartArea': {'width': '80%'}"

class NumberOfCommentatorsByWeek(ColumnChart):
	title = 'Comments and Replies by Week'
	model = Comment
	width = 6
	height = 400
	category = 'commentators_week'

	uniqid = 3
	options = "'chartArea': {'width': '80%'}"

#Comments Viewer Widgets
class CommentsWordCloudWidget(WordCloud):
	title = 'Word Cloud'
	model = Comment
	queryset = model.objects.values('text')

	uniqid = 0

class CommentsTableWidget(DynamicTable):
	title = 'Comments'
	model = Comment

	ajax_url = '/get_comments/'

	columns = ['timestamp','step','text','parent_id','likes','id']

	uniqid = 1

	column_labels = {
		'timestamp': 'Date',
		'step': 'Step',
		'text': 'Comment',
		'parent_id': 'Reply',
		'likes': 'Likes',
		'id': 'Link'
    }


#Total Measures Widgets
class AverageNumberOfCommentsPerCompletion(LineChart):
	title = 'Average Number of Comments per Completion'
	model = Comment
	height = 600
	category = 'total_measures'
	options = "'chartArea': {'width': '90%', height: '80%'}, 'hAxis': { title: 'Completed %'}, 'vAxis': { title: 'Comments'}"

	uniqid = 0

class CommentsInTotal(ValueBox):
	title = 'Comments'
	descriptor = 'in total'

	model = Comment

	uniqid = 1

class CommentsPerLearner(ValueBox):
	title = 'Comments'
	descriptor = 'average per learner'

	model = Comment

	color = 'green'
	uniqid = 2

class RepliesInTotal(ValueBox):
	title = 'Replies'
	descriptor = 'in total'

	model = Comment

	color = 'yellow'
	uniqid = 3

class RepliesPerLearner(ValueBox):
	title = 'Replies'
	descriptor = 'average per learner'

	model = Comment

	color = 'olive'
	uniqid = 4