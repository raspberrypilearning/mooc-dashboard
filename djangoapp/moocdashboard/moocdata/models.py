from __future__ import unicode_literals

from django.db import models

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
	university = models.CharField(max_length=40)

	class Meta:
		db_table = 'Courses'

	def __str__(self):
		return self.course_run

class LearnerEnrolment(models.Model):
	_DATABASE = "mooc_data"
	learner_id = models.CharField(max_length=50, primary_key=True)
	enrolled_at = models.DateTimeField()
	unenrolled_at = models.DateTimeField()
	role = models.CharField(max_length=20)
	fully_participated_at = models.DateTimeField()
	purchased_statement_at = models.DateTimeField()
	gender = models.CharField(max_length=50)
	country = models.CharField(max_length=50)
	age_range = models.CharField(max_length=50)
	highest_education_level = models.CharField(max_length=50)
	employment_status = models.CharField(max_length=50)
	employment_area = models.CharField(max_length=50)
	university = models.CharField(max_length=40, primary_key=True)
	course = models.CharField(max_length=70, primary_key=True)
	course_run = models.CharField(max_length=11, primary_key=True)

	class Meta:
		db_table = 'Enrolments'

	def __str__(self):
		return self.course_run
