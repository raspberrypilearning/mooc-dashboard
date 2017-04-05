from __future__ import unicode_literals
from ..data.models import AggregateCourse

import dashboardwidgets
import django_tables2 as tables

# Create your models here.
class AggregateCourseTable(tables.Table):
    class Meta:
        model = AggregateCourse
        fields = ('course_run', 'start_date', 'no_of_weeks', 'joiners', 'leavers', 'learners', 'active_learners', 'returning_learners', 'social_learners', 'fully_participating_learners', 'statements_sold')


class Dashboard():
	title = 'Dashboard';
	course1='All'
	run1='A'
	course2=None
	run2=None
	course3=None
	run3=None
	course4=None
	run4=None

	widgets = []

	def updateCharts(self):

		for widget in self.widgets:
			widget.course1 = self.course1
			widget.run1 = self.run1
			widget.course2 = self.course2
			widget.run2 = self.run2
			widget.course3 = self.course3
			widget.run3 = self.run3
			widget.course4 = self.course4
			widget.run4 = self.run4

			widget.update()

		#data = self.formDataSet('age_range')
		
			#q_objects = Q(course='Agincourt 1415: Myth and Reality') | Q(course='Archaeology of Portus: Exploring the Lost Harbour of Ancient Rome')
			#queryset = LearnerEnrolment.objects.exclude(age_range='Unknown').filter(q_objects).values('age_range','course').annotate(total = Count('age_range')).order_by('age_range')				
		#self.ageRangeChart = OldChart(columns,data,order)

class DemographicsDashboard(Dashboard):
	title = 'Demographics'
	widgets = [dashboardwidgets.AgeDistributionWidget(),dashboardwidgets.GenderWidget(),dashboardwidgets.EmploymentAreaWidget(),dashboardwidgets.EmploymentStatusWidget(),dashboardwidgets.EducationLevelWidget(),dashboardwidgets.GeoWidget()]

class StatementDemographicsDashboard(Dashboard):
	title = 'Statement Demographics'
	widgets = [dashboardwidgets.AgeDistributionWidget(),dashboardwidgets.GenderWidget(),dashboardwidgets.EmploymentAreaWidget(),dashboardwidgets.EmploymentStatusWidget(),dashboardwidgets.EducationLevelWidget(),dashboardwidgets.GeoWidget()]

	def __init__(self):
		for widget in self.widgets:
			widget.additional_filters = [{'type' : 'filter', 'arg' : 'purchased_statement_at__isnull', 'val' : False}]

class SignUpsStatementsSoldDashboard(Dashboard):
	title = 'Sign Ups and Statements Sold'
	widgets = [dashboardwidgets.SignUpsPerDayWidget(),dashboardwidgets.StatementsSoldPerDayWidget()]

class StepCompletionDashboard(Dashboard):
	title = 'Steps Completion'
	widgets = [dashboardwidgets.StepsMarkedAsComplete(),dashboardwidgets.StepsCompleted(),dashboardwidgets.StepsCompleted()]