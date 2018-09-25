"""
Creates the necessary tables in the database for each of the csv data files types. requires createDatabase.py to be run first.
Could be combined with createDatabase.py.
"""


import datetime,mysql.connector,json

credential_data = open('config.json').read()
credentials = json.loads(credential_data)

# connect to sql
sql = mysql.connector.connect (host = 'localhost',user= 'root',password = credentials['mysqlpassword'],database = 'moocs')
cursor = sql.cursor()

createComment = "CREATE TABLE Comments (" \
		"id int(11) NOT NULL," \
		"author_id varchar(50) CHARACTER SET utf8 NOT NULL," \
		"parent_id int(11) DEFAULT NULL," \
		"step varchar(5) CHARACTER SET utf8 NOT NULL," \
		"week_number int(11) NOT NULL," \
		"step_number int(11) NOT NULL," \
		"text text CHARACTER SET utf8 NOT NULL," \
		"timestamp datetime NOT NULL," \
		"moderated datetime DEFAULT NULL," \
		"likes int(11) NOT NULL," \
		"university varchar(40) NOT NULL," \
		"course varchar(200) NOT NULL DEFAULT ''," \
		"course_run int(11) NOT NULL," \
		"PRIMARY KEY (university,course,course_run,id)," \
		"KEY course (course,course_run)" \
		");"

createEnroll = "CREATE TABLE Enrolments (" \
		"learner_id varchar(50) NOT NULL," \
		"enrolled_at datetime NOT NULL," \
		"unenrolled_at datetime DEFAULT NULL," \
		"role varchar(20) DEFAULT NULL," \
		"fully_participated_at datetime DEFAULT NULL," \
		"purchased_statement_at datetime DEFAULT NULL," \
		"gender varchar(50) DEFAULT NULL," \
		"country varchar(50) DEFAULT NULL," \
		"age_range varchar(50) DEFAULT NULL," \
		"highest_education_level varchar(50) DEFAULT NULL," \
		"employment_status varchar(50) DEFAULT NULL," \
		"employment_area varchar(50) DEFAULT NULL," \
		"university varchar(40) NOT NULL," \
		"course varchar(200) NOT NULL DEFAULT ''," \
		"course_run int(11) NOT NULL," \
		"detected_country varchar(100) DEFAULT NULL," \
		"PRIMARY KEY (university,course,course_run,learner_id)," \
		"KEY course (course,course_run)" \
		");"

createAssignments = "CREATE TABLE Assignments (" \
		"id int(11) NOT NULL," \
		"step varchar(5) NOT NULL," \
		"step_number int(11) NOT NULL," \
		"week_number int(11) NOT NULL," \
		"author_id varchar(50) NOT NULL," \
		"text text CHARACTER SET utf8 NOT NULL," \
		"first_viewed_at datetime NOT NULL," \
		"submitted_at datetime NOT NULL," \
		"moderated datetime DEFAULT NULL," \
		"review_count int(11) NOT NULL," \
		"university varchar(40) NOT NULL," \
		"course varchar(200) NOT NULL DEFAULT ''," \
		"course_run int(11) NOT NULL," \
		"PRIMARY KEY (university,course,course_run,id)," \
		"KEY course (course,course_run)" \
		");" 

createReviews = "CREATE TABLE Reviews (" \
		"id int(11) NOT NULL," \
		"step varchar(5) NOT NULL," \
		"week_number int(11) NOT NULL," \
		"step_number int(11) NOT NULL," \
		"reviewer_id varchar(50) NOT NULL," \
		"assignment_id int(11) NOT NULL," \
		"guideline_one_feedback text CHARACTER SET utf8 NOT NULL," \
		"guideline_two_feedback text CHARACTER SET utf8 NOT NULL," \
		"guideline_three_feedback text CHARACTER SET utf8 NOT NULL," \
		"created_at datetime NOT NULL," \
		"university varchar(40) NOT NULL," \
		"course varchar(200) NOT NULL DEFAULT ''," \
		"course_run int(11) NOT NULL," \
		"PRIMARY KEY (university,course,course_run,id)," \
		"KEY course (course,course_run)" \
		");"

createQuiz = "CREATE TABLE Quiz (" \
		"learner_id varchar(40) NOT NULL," \
		"quiz_question varchar(10) NOT NULL," \
		"question_type varchar(60) DEFAULT NULL," \
		"week_number int(11) NOT NULL," \
		"step_number int(11) NOT NULL," \
		"question_number int(11) NOT NULL," \
		"response varchar(100) NOT NULL DEFAULT ''," \
		"cloze_response varchar(100) DEFAULT NULL," \
		"submitted_at datetime NOT NULL," \
		"correct int(11) DEFAULT NULL," \
		"university varchar(40) NOT NULL," \
		"course varchar(200) NOT NULL DEFAULT ''," \
		"course_run int(11) NOT NULL," \
		"PRIMARY KEY (university,course,course_run,learner_id,quiz_question,response,submitted_at)," \
		"KEY course (course,course_run)" \
		");"

createActivity = "CREATE TABLE Activity (" \
		  "learner_id varchar(50) NOT NULL," \
		  "step varchar(5) NOT NULL," \
		  "week_number int(11) NOT NULL," \
		  "step_number int(11) NOT NULL," \
		  "first_visited_at datetime DEFAULT NULL," \
		  "last_completed_at datetime DEFAULT NULL," \
		  "university varchar(40) NOT NULL," \
		  "course varchar(200) NOT NULL DEFAULT ''," \
		  "course_run int(11) NOT NULL," \
		  "PRIMARY KEY (university,course,course_run,learner_id,week_number,step_number)," \
		  "KEY course (course,course_run)" \
		  ");"

createCourses = "CREATE TABLE Courses (" \
		"run_id varchar(40) NOT NULL," \
		"course_run varchar(70) NOT NULL," \
		"course varchar(200) NOT NULL DEFAULT ''," \
		"run int(11) NOT NULL," \
		"start_date date NOT NULL," \
		"no_of_weeks int(11) NOT NULL," \
		"joiners int(11) NOT NULL," \
		"leavers varchar(20) NOT NULL," \
		"leavers_percent varchar(20) NOT NULL," \
		"learners varchar(20) NOT NULL," \
		"learners_percent varchar(20) NOT NULL," \
		"active_learners varchar(20) NOT NULL," \
		"active_learners_percent varchar(20) NOT NULL," \
		"returning_learners varchar(20) NOT NULL," \
		"returning_learners_percent varchar(20) NOT NULL," \
		"social_learners varchar(20) NOT NULL," \
		"social_learners_percent varchar(20) NOT NULL," \
		"fully_participating_learners varchar(20) NOT NULL," \
		"fully_participating_learners_percent varchar(20) NOT NULL," \
		"statements_sold int(11) NOT NULL," \
		"certificates_sold int(11) NOT NULL," \
		"upgrades_sold varchar(20) NOT NULL," \
		"upgrades_sold_percent varchar(20) NOT NULL," \
		"learners_with_at_least_50_percent_step_completion varchar(20) NOT NULL," \
		"learners_with_at_least_50_percent_step_completion_percent varchar(20) NOT NULL," \
		"learners_with_at_least_90_percent_step_completion varchar(20) NOT NULL," \
		"learners_with_at_least_90_percent_step_completion_percent varchar(20) NOT NULL," \
		"run_retention_index varchar(20) NOT NULL," \
		"run_retention_index_percent varchar(20) NOT NULL," \
		"gross_revenue_in_gbp varchar(20) NOT NULL," \
		"university varchar(40) NOT NULL," \
		"PRIMARY KEY (university,course,course_run)," \
		"KEY course (course,course_run)" \
		");"

createTeamMembers= "CREATE TABLE TeamMembers (" \
		"id varchar(40) NOT NULL," \
		"first_name varchar(100) CHARACTER SET utf8 NOT NULL DEFAULT ''," \
		"last_name varchar(100) CHARACTER SET utf8 NOT NULL DEFAULT ''," \
		"team_role varchar(20) NOT NULL," \
		"user_role varchar(20) NOT NULL," \
		"PRIMARY KEY (id)" \
		");"

createVideoStats= "CREATE TABLE VideoStats (" \
		"title varchar(200) NOT NULL DEFAULT ''," \
		"total_views int(11) NOT NULL," \
		"total_downloads int(11) NOT NULL," \
		"total_caption_views int(11) NOT NULL," \
		"total_transcript_views int(11) NOT NULL," \
		"viewed_hd int(11) NOT NULL," \
		"viewed_five_percent double DEFAULT NULL," \
		"viewed_ten_percent double DEFAULT NULL," \
		"viewed_twentyfive_percent double DEFAULT NULL," \
		"viewed_fifty_percent double DEFAULT NULL," \
		"viewed_seventyfive_percent double DEFAULT NULL," \
		"viewed_ninetyfive_percent double DEFAULT NULL," \
		"viewed_onehundred_percent double DEFAULT NULL," \
		"console_device_percentage double NOT NULL," \
		"desktop_device_percentage double NOT NULL," \
		"mobile_device_percentage double NOT NULL," \
		"tv_device_percentage double NOT NULL," \
		"tablet_device_percentage double NOT NULL," \
		"unknown_device_percentage double NOT NULL," \
		"europe_views_percentage double NOT NULL," \
		"oceania_views_percentage double NOT NULL," \
		"asia_views_percentage double NOT NULL," \
		"north_america_views_percentage double NOT NULL," \
		"south_america_views_percentage double NOT NULL," \
		"africa_views_percentage double NOT NULL," \
		"antarctica_views_percentage double NOT NULL," \
		"university varchar(200) NOT NULL DEFAULT ''," \
		"course varchar(200) NOT NULL DEFAULT ''," \
		"course_run int(11) NOT NULL," \
		"PRIMARY KEY (university,course,course_run,title)," \
		"KEY course (course,course_run)" \
		");"

createExtractlinks= "CREATE TABLE ExtractLinks (" \
		"`Week Number` int(11) NOT NULL," \
		"`Step Number` int(11) NOT NULL," \
		"`Step Title` varchar(200) NOT NULL DEFAULT ''," \
		"`Step URL` varchar(200) NOT NULL DEFAULT ''," \
		"`Part` varchar(100) DEFAULT NULL," \
		"`Field` varchar(100) DEFAULT NULL," \
		"`Link Target` varchar(200) NOT NULL DEFAULT ''," \
		"`Link Caption` varchar(100) NOT NULL DEFAULT ''," \
		"university varchar(200) NOT NULL DEFAULT ''," \
		"course varchar(200) NOT NULL DEFAULT ''," \
		"course_run int(11) NOT NULL," \
		"PRIMARY KEY (university,course,course_run,`Step URL`,`Link Target`)," \
		"KEY course (course,course_run)" \
		");"

createScrapedLinks= "CREATE TABLE ScrapedLinks (" \
		"step_number int(11) NOT NULL," \
		"step_title varchar(200) NOT NULL DEFAULT ''," \
		"step_type varchar(200) NOT NULL DEFAULT ''," \
		"step_edit_url varchar(200) NOT NULL DEFAULT ''," \
		"step_url varchar(200) NOT NULL DEFAULT ''," \
		"university varchar(200) NOT NULL DEFAULT ''," \
		"course varchar(200) NOT NULL DEFAULT ''," \
		"course_run int(11) NOT NULL," \
		"PRIMARY KEY (university,course,course_run,step_url)," \
		"KEY course (course,course_run)" \
		");"

#create all tables, if tables exist, will be deleted
drops = ['DROP TABLE IF EXISTS Comments','DROP TABLE IF EXISTS Enrolments','DROP TABLE IF EXISTS Assignments', \
		'DROP TABLE IF EXISTS Reviews','DROP TABLE IF EXISTS Quiz','DROP TABLE IF EXISTS Activity', 'DROP TABLE IF EXISTS Courses', \
		'DROP TABLE IF EXISTS TeamMembers', 'DROP TABLE IF EXISTS VideoStats', 'DROP TABLE IF EXISTS ExtractLinks', 'DROP TABLE IF EXISTS ScrapedLinks']

creates = [createComment,createEnroll,createAssignments,createReviews,createQuiz,createActivity, createCourses, createTeamMembers,createVideoStats, createExtractlinks, createScrapedLinks]

for d in drops:
	cursor.execute(d)

for c in creates:
	cursor.execute(c)
	

cursor.close()
#closeServer(server,sql)