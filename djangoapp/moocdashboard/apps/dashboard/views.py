from django import forms
from django.http import HttpResponse, HttpResponseRedirect
from django.shortcuts import render
from django.views import View
from django.views.generic import TemplateView, FormView
from django.views.decorators.csrf import csrf_exempt
from django.db.models import Count
from django.contrib.auth.mixins import LoginRequiredMixin

from django_datatables_view.base_datatable_view import BaseDatatableView

import json, datetime, wordcloud

from .models import AggregateCourse, Comment
from .dashboard import *
from .forms import CourseRunForm

# Create your views here.
class CourseListJson(BaseDatatableView):
    model = AggregateCourse
    columns = ['course_run','start_date','no_of_weeks','joiners','leavers','learners','active_learners','returning_learners','social_learners','fully_participating_learners','statements_sold']
    #if column not sortable then leave blank ''
    order_columns = ['course_run','start_date','no_of_weeks','joiners','leavers','learners','active_learners','returning_learners','social_learners','fully_participating_learners','statements_sold']

    #anti-DDoS
    max_display_length = 500

    def render_column(self, row, column):
        if column == 'course_run':
            return row.course_run.title().replace("-"," ")
        else:
            return super(CourseListJson, self).render_column(row,column)

class CommentsJson(BaseDatatableView):
    model = Comment
    columns = ['timestamp','step','text','parent_id','likes','id']
    order_columns = ['timestamp','step','text','parent_id','likes','id']

    max_display_length = 500

    def get_initial_queryset(self):
        filter_args = {}
        if 'course1' in self.request.GET:
            filter_args['course'] = self.request.GET['course1']
            if self.request.GET['run1'] != 'A':
                filter_args['course_run'] = self.request.GET['run1']

        return self.model.objects.filter(**filter_args)

    def render_column(self,row,column):
        if column == 'timestamp':
            time_val = row.timestamp
            if time_val:
                time_val = row.timestamp.strftime('%Y-%m-%d')
            return time_val
        if column == 'parent_id':
            if row.parent_id == None:
                return 'No'
            else:
                return 'Yes'
            return row.parent_id
        else:
            return super(CommentsJson, self).render_column(row,column)

class WordCloud(View):
    model = Comment
    width = 700
    height = 400
    max_words = 100
    colour_scheme = 'Blues'

    course1 = 'All'
    run1 = 'A'

    def get_initial_queryset(self):
        filter_args = {}
        if 'course1' in self.request.GET:
            self.course1 = self.request.GET['course1']
            if self.request.GET['run1'] != 'A':
                self.run1 = self.request.GET['run1']

        if 'width' in self.request.GET:
            self.width = int(round(float(self.request.GET['width'])))
        if 'height' in self.request.GET:
            self.height = self.request.GET['height']

        if 'max_words' in self.request.GET:
            self.max_words = int(round(float(self.request.GET['max_words'])))

        if 'colour_scheme' in self.request.GET:
            self.colour_scheme = self.request.GET['colour_scheme']

        from django.db import connections
        cursor = connections['mooc_data'].cursor()
        cursor.execute("SET @@session.group_concat_max_len = 15000")

        query = "SELECT GROUP_CONCAT(text SEPARATOR ' ') FROM Comments"
        if self.course1 != 'All':
            query += " WHERE course='" + self.course1 + "'"
            if self.run1 != 'A' and isinstance(self.run1, (int, long)):
                query += " AND course_run=" + self.run1


        cursor.execute(query)
        row = cursor.fetchone()

        return row[0]

    def get(self,request):
        words = self.get_initial_queryset()

        import matplotlib

        #Fix for Mac OS
        matplotlib.use('TkAgg')
        import matplotlib.pyplot as plt
        wc = wordcloud.WordCloud(width=self.width,height=self.height,background_color="white",colormap=self.colour_scheme,max_words=self.max_words).generate(words)
        img = wc.to_image()

        response = HttpResponse(content_type="image/png")
        img.save(response,"PNG")
        return response


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

    def update(dashboard):
        dashboard.updateCharts()

    def get_context_data(self, **kwargs):
        context = super(DashboardView, self).get_context_data(**kwargs)
        self.resetCourseRuns()
        self.retrieveCourseRuns()
        self.dashboard.updateCharts()
        return context

class CourseListDashboardView(DashboardView):
    dashboard = CourseListDashboard()

class DemographicsView(DashboardView):
    dashboard = DemographicsDashboard()

class StatementDemographicsView(DashboardView):
    dashboard = StatementDemographicsDashboard()

class SignUpsStatementsSoldView(DashboardView):
    dashboard = SignUpsStatementsSoldDashboard()

class SingleCourseDashboardView(DashboardView):
    template_name = 'singlecoursedashboard.html'
    dashboard = StepCompletionDashboard()

class StepCompletionView(SingleCourseDashboardView):
    dashboard = StepCompletionDashboard()

class CommentsOverviewView(SingleCourseDashboardView):
    dashboard = CommentsOverviewDashboard()

class DynamicSingleCourseDashboardView(DashboardView):
    template_name = 'dynamicsinglecoursedashboard.html'
    dashboard = CommentsViewerDashboard()

class CommentsViewerView(DynamicSingleCourseDashboardView):
    dashboard = CommentsViewerDashboard()

class TotalMeasuresView(SingleCourseDashboardView):
    dashboard = TotalMeasuresDashboard()