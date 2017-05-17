from django.test import TestCase
from .models import *
from .dashboardwidgets import *
import datetime

# Create your tests here.
class AggregateCourseTestCase(TestCase):
	def setUp(self):
		AggregateCourse.objects.create(
			course_run = 'agincourt-1',
			course = 'Agincourt 1415: Myth and Reality',
			run = 1,
			start_date = datetime.datetime.strptime('2015-07-28 18:17:45', '%Y-%m-%d %H:%M:%S').date(),
			no_of_weeks = 2,
			joiners = 8613,
			leavers = '942 - 10.9%',
			learners = '5521 - 64.1%',
			active_learners = '4921 - 89.1%',
			returning_learners = '3342 - 60.5%',
			social_learners = '2369 - 42.9%',
			fully_participating_learners = '3373 - 61.1%',
			statements_sold = 110,
			university = 'University of Southampton'
			)	

		widget = CourseListWidget()
		print widget

	def test_aggregate_course_can_be_read(self):
		course = AggregateCourse.objects.get()
		self.assertTrue(course)



class LearnerEnrolmentTestCase(TestCase):
	def setUp(self):
		LearnerEnrolment.objects.create(
			learner_id = '00011111-1111-1110-a111-1111c1d1b1d1',
			enrolled_at = datetime.datetime.strptime('2015-07-28 18:17:45', '%Y-%m-%d %H:%M:%S'),
			unenrolled_at = None,
			role = 'learner',
			fully_participated_at = datetime.datetime.strptime('2015-10-30 20:16:59', '%Y-%m-%d %H:%M:%S'),
			purchased_statement_at = None,
			gender = 'other',
			country = 'GB',
			age_range = '46-55',
			highest_education_level = 'university_degree',
			employment_status = 'working_part_time',
			employment_area = 'retail_and_sales',
			university = 'University of Southampton',
			course = 'Agincourt 1415: Myth and Reality',
			course_run = 1
			)

	def test_learner_enrolment_can_be_read(self):
		learner = LearnerEnrolment.objects.get()
		self.assertTrue(learner)

class LearnerActivityTestCase(TestCase):
	def setUp(self):
		LearnerActivity.objects.create(
			learner_id = '00011111-1111-1110-a111-1111c1d1b1d1',
			step = '1.1',
			week_number = 1,
			step_number = 1,
			first_visited_at = datetime.datetime.strptime('2015-10-30 20:16:59', '%Y-%m-%d %H:%M:%S'),
			last_completed_at = datetime.datetime.strptime('2015-10-30 20:20:36', '%Y-%m-%d %H:%M:%S'),
			university = 'University of Southampton',
			course = 'Agincourt 1415: Myth and Reality',
			course_run = 1
			)

	def test_learner_activity_can_be_read(self):
		activity = LearnerActivity.objects.get()
		self.assertTrue(activity)

class CommentTestCase(TestCase):
	def setUp(self):
		Comment.objects.create(
		id = 10000,
		author_id = '00011111-1111-1110-a111-1111c1d1b1d1',
		parent_id = None,
		step = '1.1',
		week_number = 1,
		step_number = 1,
		text = 'I am interested in the myth and reality of the Battle of Agincourt.',
		timestamp = datetime.datetime.strptime('2015-10-19 00:21:22', '%Y-%m-%d %H:%M:%S'),
		moderated = None,
		likes = 7,
		university = 'University of Southampton',
		course = 'Agincourt 1415: Myth and Reality',
		course_run = 1
		)

	def test_comment_can_be_read(self):
		comment = Comment.objects.get()
		self.assertTrue(comment)