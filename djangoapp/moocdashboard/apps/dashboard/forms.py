from django import forms

from .models import AggregateCourse

class CourseModelChoiceField(forms.ModelChoiceField):
	def label_from_instance(self,obj):
		return obj.course

class RunModelChoiceField(forms.ModelChoiceField):
	def label_from_instance(self,obj):
		return obj.run

class CourseRunForm(forms.Form):
	model = AggregateCourse

	courses_queryset = AggregateCourse.objects.all().values_list('course', flat=True).distinct().order_by('course')

def getCourses():
	return None

def getCourseRuns(course):
	course_run_queryset = AggregateCourse.objects.all().values_list('course_run','course','run','start_date','no_of_weeks').order_by('course_run')
	course_runs = list(courses_queryset)

	return course_runs
