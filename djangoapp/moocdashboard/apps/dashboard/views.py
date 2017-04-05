from django import forms
from django.http import HttpResponse, HttpResponseRedirect
from django.shortcuts import render
#from django.views.generic import ListView
from django.views.generic import TemplateView, FormView
from django.views.decorators.csrf import csrf_exempt
from django.db.models import Count
from sortable_listview import SortableListView
from django.contrib.auth.mixins import LoginRequiredMixin

import json, datetime

from ..data.models import AggregateCourse
from .models import AggregateCourseTable, Dashboard, DemographicsDashboard, StatementDemographicsDashboard, SignUpsStatementsSoldDashboard, StepCompletionDashboard
from .forms import CourseRunForm

# Create your views here.

class CourseList(LoginRequiredMixin,SortableListView):
    allowed_sort_fields = {'course_run': {'default_direction': '',
                      'verbose_name': 'Course Run'},
              'start_date': {'default_direction': '',
                                    'verbose_name': 'Start Date'},
                           'no_of_weeks': {'default_direction': '',
                                              'verbose_name': 'Weeks'},
                           'joiners': {'default_direction': '',
                                              'verbose_name': 'Joiners'},
                           'leavers': {'default_direction': '',
                                              'verbose_name': 'Leavers'},
                           'learners': {'default_direction': '',
                                              'verbose_name': 'Learners'},
                           'active_learners': {'default_direction': '',
                                              'verbose_name': 'Active Learners'},
                           'returning_learners': {'default_direction': '',
                                              'verbose_name': 'Returning Learners'}
                                              }
    default_sort_field = 'course_run'
    model = AggregateCourse
    title = 'Course List'
    paginate_by = 50

# views.py
def course_list(request):
    table = AggregateCourseTable(AggregateCourse.objects.all())

    return render(request, 'course_list.html', {
        'table': table
    })

def get_course_runs_method(course_name):
    courses = AggregateCourse.objects.all().values_list('course_run','course','run','start_date','no_of_weeks').filter(course=course_name).order_by('course_run')
    course_dict = {}
    for course in courses:
        end_date = course[3] + datetime.timedelta(weeks=course[4])
        course_dict[course[2]] = str(course[2]) + ' - ' + str(course[3]) + ' - ' + str(end_date)
    return HttpResponse(json.dumps(course_dict))

class CompareView(LoginRequiredMixin,FormView):
    template_name = 'compare.html'
    #course = forms.ModelChoiceField(queryset=AggregateCourse.objects.all().values('course').annotate(courses=Count('course')))
    form_class = CourseRunForm

    def validateCourseRun(self,request,course,run):
        if request.POST[course] and request.POST[run]:
            return (request.POST[course],request.POST[run])
        else:
            return None

    def post(self, request, *args, **kwargs):
        form = self.form_class(request.POST)

        if form.is_valid():
            # <process form cleaned data>
            courserun1 = self.validateCourseRun(request,'course1','run1')
            courserun2 = self.validateCourseRun(request,'course2','run2')
            courserun3 = self.validateCourseRun(request,'course3','run3')
            courserun4 = self.validateCourseRun(request,'course4','run4')

            #course3 = request.POST['course3']
            #run3 = request.POST['run3']
            #course4 = request.POST['course4']
            #run4 = request.POST['run4']

            url = '/demographics/?'

            if courserun1:
                url += 'course1=' + courserun1[0] + '&run1=' + courserun1[1]
            if courserun2:
                url += '&course2=' + courserun2[0] + '&run2=' + courserun2[1]
            if courserun3:
                url += '&course3=' + courserun3[0] + '&run3=' + courserun3[1]
            if courserun4:
                url += '&course4=' + courserun4[0] + '&run4=' + courserun4[1]

            return HttpResponseRedirect(url)

        return render(request, self.template_name, {'form': form})


@csrf_exempt
def get_course_runs(request):
    course_name = request.POST['course']
    courses = AggregateCourse.objects.all().values_list('course_run','course','run','start_date','no_of_weeks').filter(course=course_name).order_by('course_run')
    course_dict = {}
    for course in courses:
        end_date = course[3] + datetime.timedelta(weeks=course[4])
        course_dict[course[2]] = str(course[2]) + ' - ' + str(course[3]) + ' - ' + str(end_date)
    return HttpResponse(json.dumps(course_dict))

class DashboardView(LoginRequiredMixin,TemplateView):
    template_name = 'dashboard.html'

    dashboard = DemographicsDashboard()

    def resetCourseRuns(self):
        self.dashboard.course1 = 'All'
        self.dashboard.run1 = 'A'
        self.dashboard.course2 = None
        self.dashboard.run2 = None
        self.dashboard.course3 = None
        self.dashboard.run3 = None
        self.dashboard.course4 = None
        self.dashboard.run4 = None

    def retrieveCourseRuns(self):
        if 'course1' in self.request.GET:
          self.dashboard.course1 = self.request.GET['course1']
        if 'run1' in self.request.GET:
          self.dashboard.run1 = self.request.GET['run1']
        if 'course2' in self.request.GET:
          self.dashboard.course2 = self.request.GET['course2']
        if 'run2' in self.request.GET:
          self.dashboard.run2 = self.request.GET['run2']
        if 'course3' in self.request.GET:
          self.dashboard.course3 = self.request.GET['course3']
        if 'run3' in self.request.GET:
          self.dashboard.run3 = self.request.GET['run3']
        if 'course4' in self.request.GET:
          self.dashboard.course4 = self.request.GET['course4']
        if 'run4' in self.request.GET:
          self.dashboard.run4 = self.request.GET['run4']

        if self.dashboard.course1 == 'All':
          self.dashboard.run1 = ''

    def update(dashboard):
        dashboard.updateCharts()

    def get_context_data(self, **kwargs):
        context = super(DashboardView, self).get_context_data(**kwargs)
        self.resetCourseRuns()
        self.retrieveCourseRuns()
        self.dashboard.updateCharts()
        return context

class DemographicsView(DashboardView):
    dashboard = DemographicsDashboard()

class StatementDemographicsView(DashboardView):
    dashboard = StatementDemographicsDashboard()

class SignUpsStatementsSoldView(DashboardView):
    dashboard = SignUpsStatementsSoldDashboard()

class StepCompletionView(DashboardView):
    dashboard = StepCompletionDashboard()