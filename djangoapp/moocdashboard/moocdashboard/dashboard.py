from django.db.models import Count
from controlcenter import Dashboard, widgets
from moocdata.models import AggregateCourse, LearnerEnrolment

#Aggregate Enrolment Widgets
class AggregateEnrolmentWidget(widgets.ItemList):
    title = 'Aggregate Enrolment'
#    model = Pizza
    model = AggregateCourse
    width = widgets.LARGEST
    height = 300
#    list_display = ['name', 'price']
    list_display = ['course_run', 'start_date', 'no_of_weeks', 'joiners', 'leavers', 'learners', 'active_learners', 'returning_learners', 'social_learners', 'fully_participating_learners', 'statements_sold']


#Demographics Widgets
class AgeDistributionWidget(widgets.SingleBarChart):
    title = 'Age Distribution'
    model = LearnerEnrolment
    width = widgets.LARGE
    queryset = LearnerEnrolment.objects.exclude(age_range='Unknown').values('age_range').annotate(total=Count('age_range')).order_by('age_range')
    values_list = ('age_range', 'total')

class GenderWidget(widgets.SingleBarChart):
    title = 'Gender'
    model = LearnerEnrolment
    width = widgets.LARGE
    queryset = LearnerEnrolment.objects.exclude(gender='Unknown').values('gender').annotate(total=Count('gender')).order_by('gender')
    values_list = ('gender', 'total')

class EmploymentAreaWidget(widgets.SingleBarChart):
    title = 'Employment Area'
    model = LearnerEnrolment
    width = widgets.LARGEST
    queryset = LearnerEnrolment.objects.exclude(employment_area='Unknown').values('employment_area').annotate(total=Count('employment_area'))
    values_list = ('employment_area', 'total')

class EmploymentStatusWidget(widgets.SingleBarChart):
    title = 'Employment Status'
    model = LearnerEnrolment
    width = widgets.LARGEST
    queryset = LearnerEnrolment.objects.exclude(employment_status='Unknown').values('employment_status').annotate(total=Count('employment_status'))
    values_list = ('employment_status', 'total')

class DegreeLevelWidget(widgets.SingleBarChart):
    title = 'Study Level'
    model = LearnerEnrolment
    width = widgets.LARGEST
    queryset = LearnerEnrolment.objects.exclude(highest_education_level='Unknown').values('highest_education_level').annotate(total=Count('highest_education_level'))
    values_list = ('highest_education_level', 'total')    

#############################


class AggregateEnrolmentDashboard(Dashboard):
    title = 'Aggregate Enrolment'
    widgets = (
        widgets.Group([AggregateEnrolmentWidget]),
    )

class DemographicsDashboard(Dashboard):
    title = 'Demographics'
    widgets = (
        widgets.Group([AgeDistributionWidget]),
        widgets.Group([GenderWidget]),
        widgets.Group([EmploymentAreaWidget]),
        widgets.Group([EmploymentStatusWidget]),
        widgets.Group([DegreeLevelWidget]),
    )





