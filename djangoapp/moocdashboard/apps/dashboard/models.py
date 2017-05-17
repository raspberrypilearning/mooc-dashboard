from __future__ import unicode_literals

from django.db import models
import django_tables2 as tables

# Create your models here.

class AggregateCourse(models.Model):
	_DATABASE = "mooc_data"
	course_run = models.CharField(max_length=70, unique=True, primary_key=True)
	course = models.CharField(max_length=70)
	run = models.CharField(max_length=70)
	start_date = models.DateField()
	no_of_weeks = models.IntegerField()
	joiners = models.IntegerField()
	leavers = models.CharField(max_length=20)
	learners = models.CharField(max_length=20)
	active_learners  = models.CharField(max_length=20)
	returning_learners = models.CharField(max_length=20)
	social_learners = models.CharField(max_length=20)
	fully_participating_learners = models.CharField(max_length=20)
	statements_sold = models.IntegerField()
	university = models.CharField(max_length=40)#, primary_key=True)

	class Meta:
		db_table = 'Courses'

	def __str__(self):
		return self.course_run

	def get_course(self):
		return self.course

class LearnerEnrolment(models.Model):
	_DATABASE = "mooc_data"
	learner_id = models.CharField(max_length=50, primary_key=True)
	enrolled_at = models.DateTimeField()
	unenrolled_at = models.DateTimeField(null=True,blank=True)
	role = models.CharField(max_length=20)
	fully_participated_at = models.DateTimeField(null=True,blank=True)
	purchased_statement_at = models.DateTimeField(null=True,blank=True)
	gender = models.CharField(max_length=50)
	country = models.CharField(max_length=50)
	age_range = models.CharField(max_length=50)
	highest_education_level = models.CharField(max_length=50)
	employment_status = models.CharField(max_length=50)
	employment_area = models.CharField(max_length=50)
	university = models.CharField(max_length=40) #, primary_key=True)
	course = models.CharField(max_length=70) #, primary_key=True)
	course_run = models.IntegerField() #primary_key=True)

	class Meta:
		db_table = 'Enrolments'

	def __str__(self):
		return self.course_run

class LearnerActivity(models.Model):
	_DATABASE = "mooc_data"
	learner_id = models.CharField(max_length=50, primary_key=True)
	step = models.CharField(max_length=5)
	week_number = models.IntegerField() #primary_key=True)
	step_number = models.IntegerField() #primary_key=True)
	first_visited_at = models.DateTimeField()
	last_completed_at = models.DateTimeField(null=True,blank=True)
	university = models.CharField(max_length=40) #, primary_key=True)
	course = models.CharField(max_length=70) #, primary_key=True)
	course_run = models.IntegerField() #primary_key=True)

	class Meta:
		db_table = 'Activity'

	def __str__(self):
		return self.step

class Comment(models.Model):
	_DATABASE = "mooc_data"
	id = models.IntegerField(primary_key=True)
	author_id = models.CharField(max_length=50)
	parent_id = models.IntegerField(null=True,blank=True)
	step = models.CharField(max_length=5)
	week_number = models.IntegerField() #primary_key=True)
	step_number = models.IntegerField() #primary_key=True)
	text = models.CharField(max_length=1200)
	timestamp = models.DateTimeField()
	moderated = models.DateTimeField(null=True,blank=True)
	likes = models.IntegerField()
	university = models.CharField(max_length=40) #, primary_key=True)
	course = models.CharField(max_length=70) #, primary_key=True)
	course_run = models.IntegerField() #primary_key=True)

	class Meta:
		db_table = 'Comments'

	def __str__(self):
		return self.id

