from django import forms

from ..data.models import AggregateCourse
#from .models import Course, Run, CourseRun

class CourseModelChoiceField(forms.ModelChoiceField):
	def label_from_instance(self,obj):
		return obj.course

class RunModelChoiceField(forms.ModelChoiceField):
	def label_from_instance(self,obj):
		return obj.run

class CourseRunForm(forms.Form):
	model = AggregateCourse

	courses_queryset = AggregateCourse.objects.all().values_list('course', flat=True).distinct().order_by('course')
	'''course_run_queryset = AggregateCourse.objects.all().values_list('course_run','course','run','start_date','no_of_weeks').order_by('course_run')

	#courses_queryset = Course.objects.all().distinct().order_by('course')
	runs_queryset = AggregateCourse.objects.all().values('course','run')

	courses1 = forms.ModelChoiceField(queryset=courses_queryset,label="Course")
	run1 = forms.ModelChoiceField(queryset=runs_queryset,label="Run")

	courses2 = forms.ModelChoiceField(queryset=courses_queryset,label="Course")
	run2 = forms.ModelChoiceField(queryset=runs_queryset,label="Run")

	courses3 = forms.ModelChoiceField(queryset=courses_queryset,label="Course")
	run3 = forms.ModelChoiceField(queryset=runs_queryset,label="Run")

	courses4 = forms.ModelChoiceField(queryset=courses_queryset,label="Course")
	run4 = forms.ModelChoiceField(queryset=runs_queryset,label="Run")'''

'''course = forms.ModelChoiceField(queryset=AggregateCourse.objects.all().values('course').annotate(courses=Count('course')))'''

def getCourses():
	return None

def getCourseRuns(course):
	course_run_queryset = AggregateCourse.objects.all().values_list('course_run','course','run','start_date','no_of_weeks').order_by('course_run')
	course_runs = list(courses_queryset)

	return course_runs
