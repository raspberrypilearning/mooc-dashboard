from __future__ import unicode_literals
from .models import AggregateCourse
from copy import deepcopy

import dashboardwidgets

# Create your models here.
class Dashboard():
    title = 'Dashboard'
    navid = 'home'

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

class CourseListDashboard(Dashboard):
    title = 'Aggregate Course List'
    navid = 'course-list'
    widgets = [dashboardwidgets.CourseListWidget()]

class DemographicsDashboard(Dashboard):
    title = 'Demographics'
    navid = 'demographics'
    widgets = [dashboardwidgets.AgeDistributionWidget(),dashboardwidgets.GenderWidget(),dashboardwidgets.EmploymentAreaWidget(),dashboardwidgets.EmploymentStatusWidget(),dashboardwidgets.EducationLevelWidget(),dashboardwidgets.GeoWidget()]

class StatementDemographicsDashboard(Dashboard):
    title = 'Statement Demographics'
    navid = 'statement-demographics'
    widgets = [dashboardwidgets.AgeDistributionWidget(),dashboardwidgets.GenderWidget(),dashboardwidgets.EmploymentAreaWidget(),dashboardwidgets.EmploymentStatusWidget(),dashboardwidgets.EducationLevelWidget(),dashboardwidgets.GeoWidget()]

    def __init__(self):
        for widget in self.widgets:
            widget.additional_filters = [{'type' : 'filter', 'arg' : 'purchased_statement_at__isnull', 'val' : False}]

class SignUpsStatementsSoldDashboard(Dashboard):
    title = 'Sign Ups and Statements Sold'
    navid = 'sign-ups-statements-sold'
    widgets = [dashboardwidgets.SignUpsPerDayWidget(),dashboardwidgets.StatementsSoldPerDayWidget()]

class SingleCourseDashboard():
    title = 'Dashboard';
    course1='All'
    run1='A'
    course2=None
    run2=None
    course3=None
    run3=None
    course4=None
    run4=None

    widgets1 = []
    widgets2 = []
    widgets3 = []
    widgets4 = []

    def updateCharts(self):
        self.widgets1 = deepcopy(self.widgets)
        self.widgets2 = deepcopy(self.widgets)
        self.widgets3 = deepcopy(self.widgets)
        self.widgets4 = deepcopy(self.widgets)

        for widget in self.widgets1:
            widget.course1 = self.course1
            widget.run1 = self.run1
            widget.update()

        if self.course2 != None:
            for widget in self.widgets2:
                widget.course1 = self.course2
                widget.run1 = self.run2
                widget.uniqid = str(widget.uniqid) + 'cr2'
                widget.update()

        if self.course3 != None:
            for widget in self.widgets3:
                widget.course1 = self.course3
                widget.run1 = self.run3
                widget.uniqid = str(widget.uniqid) + 'cr3'
                widget.update()

        if self.course4 != None:
            for widget in self.widgets4:
                widget.course1 = self.course4
                widget.run1 = self.run4
                widget.uniqid = str(widget.uniqid) + 'cr4'
                widget.update()

class StepCompletionDashboard(SingleCourseDashboard):
    title = 'Steps Completion'
    navid = 'step-completion'
    widgets = [dashboardwidgets.StepsMarkedAsComplete(),dashboardwidgets.StepsFirstVisitedByStepAndDate(),dashboardwidgets.StepsMarkedAsCompleteByStepAndDate()] #,dashboardwidgets.StepsCompleted()]

class CommentsOverviewDashboard(SingleCourseDashboard):
    title = 'Comments Overview'
    navid = 'comments-overview'
    widgets = [dashboardwidgets.NumberOfCommentsByStep(),dashboardwidgets.NumberOfCommentsByStepAndDate(),dashboardwidgets.CommentsAndRepliesByWeek(),dashboardwidgets.NumberOfCommentatorsByWeek()]

class DynamicSingleCourseDashboard():
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


class CommentsViewerDashboard(DynamicSingleCourseDashboard):
    title = 'Comments Viewer'
    navid = 'comments-viewer'
    widgets = [dashboardwidgets.CommentsWordCloudWidget(),dashboardwidgets.CommentsTableWidget()]

class TotalMeasuresDashboard(SingleCourseDashboard):
    title = 'Total Measures'
    navid = 'total-measures'
    widgets = [dashboardwidgets.AverageNumberOfCommentsPerCompletion(),dashboardwidgets.CommentsInTotal(),dashboardwidgets.CommentsPerLearner(),dashboardwidgets.RepliesInTotal(),dashboardwidgets.RepliesPerLearner()]#dashboardwidgets.AverageNumberOfCommentsPerCompletion(),dashboardwidgets.CommentsInTotal(),dashboardwidgets.AverageCommentsPerLearner(),dashboardwidgets.RepliesInTotal(),dashboardwidgets.RepliesPerLearner()]





