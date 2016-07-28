import datetime,mysql.connector


# connect to sql
sql = mysql.connector.connect (host = 'localhost',user= 'root',password = 'moocDashboard1',database = 'moocs')
cursor = sql.cursor()

createComment = "CREATE TABLE Comments(" \
 		"id INT NOT NULL," \
 		"author_id VARCHAR(50) NOT NULL," \
 		"parent_id INT," \
 		"step VARCHAR(5) NOT NULL," \
 		"week INT NOT NULL," \
 		"stepNumber INT NOT NULL," \
 		"text VARCHAR(1200) NOT NULL," \
 		"timestamp DATETIME NOT NULL," \
 		"moderated DATETIME," \
 		"likes INT NOT NULL," \
 		"university VARCHAR(40) NOT NULL," \
	    "course VARCHAR(30) NOT NULL," \
	    "course_run INT NOT NULL," \
	    "INDEX(course,course_run)," \
 		"PRIMARY KEY(university,course,course_run,id)" \
	    ");"

createEnroll = "CREATE TABLE Enrolments(" \
		"learner_id VARCHAR(50) NOT NULL," \
		"enrolled_at DATETIME NOT NULL," \
		"unenrolled_at DATETIME," \
		"role VARCHAR(20)," \
		"fully_participated_at DATETIME," \
		"purchased_statement_at DATETIME," \
		"gender VARCHAR(50)," \
		"country VARCHAR(50)," \
		"age_range VARCHAR(50)," \
		"highest_education_level VARCHAR(50)," \
		"employment_status VARCHAR(50)," \
		"employment_area VARCHAR(50)," \
		"university VARCHAR(40) NOT NULL,"\
		"course VARCHAR(30) NOT NULL," \
		"course_run INT NOT NULL," \
		"INDEX(course,course_run)," \
		"PRIMARY KEY (university,course,course_run,learner_id)" \
		");"

createAssignments = "CREATE TABLE Assignments(" \
		"id INT NOT NULL," \
		"step VARCHAR(5) NOT NULL," \
		"step_number INT NOT NULL," \
		"week_number INT NOT NULL," \
		"author_id VARCHAR(50) NOT NULL," \
		"text VARCHAR(2000) NOT NULL," \
		"first_viewed_at DATETIME NOT NULL," \
		"submitted_at DATETIME NOT NULL," \
		"moderated DATETIME," \
		"review_count INT NOT NULL," \
		"university VARCHAR(40) NOT NULL," \
		"course VARCHAR(30) NOT NULL," \
		"course_run INT NOT NULL," \
		"INDEX(course,course_run)," \
		"PRIMARY KEY (university,course,course_run,id)" \
		");" 

createReviews = "CREATE TABLE Reviews(" \
		"id INT NOT NULL," \
		"step VARCHAR(5) NOT NULL,"\
		"week_number INT NOT NULL," \
		"step_number INT NOT NULL," \
		"reviewer_id VARCHAR(50) NOT NULL," \
		"assignment_id INT NOT NULL," \
		"guideline_one_feedback VARCHAR(1200) NOT NULL," \
		"guideline_two_feedback VARCHAR(1200) NOT NULL," \
		"guideline_three_feedback VARCHAR(1200) NOT NULL," \
		"created_at DATETIME NOT NULL," \
		"university VARCHAR(40) NOT NULL," \
		"course VARCHAR(30) NOT NULL," \
		"course_run INT NOT NULL," \
		"INDEX(course,course_run)," \
		"PRIMARY KEY (university,course,course_run, id)" \
		");"

createQuiz = "CREATE TABLE Quiz(" \
		"learner_id VARCHAR(40) NOT NULL," \
		"quiz_question VARCHAR(10) NOT NULL,"\
		"week_number INT NOT NULL," \
		"step_number INT NOT NULL," \
		"question_number INT NOT NULL," \
		"response VARCHAR(10) NOT NULL,"\
		"submitted_at DATETIME NOT NULL," \
		"correct INT NOT NULL," \
		"university VARCHAR(40) NOT NULL," \
		"course VARCHAR(30) NOT NULL," \
		"course_run INT NOT NULL," \
		"INDEX(course,course_run)," \
		"PRIMARY KEY(university,course,course_run,learner_id,quiz_question,response,submitted_at)" \
		");"

createActivity = "CREATE TABLE Activity(" \
		"learner_id VARCHAR(50) NOT NULL," \
		"step VARCHAR(5) NOT NULL," \
		"week INT NOT NULL," \
		"stepNumber INT NOT NULL," \
		"first_visited_at DATETIME NOT NULL," \
		"last_completed_at DATETIME," \
		"university VARCHAR(40) NOT NULL," \
		"course VARCHAR(30) NOT NULL," \
		"course_run INT NOT NULL," \
		"INDEX(course,course_run)," \
		"PRIMARY KEY (university,course,course_run,learner_id,week,stepNumber)" \
		");"

createLearners = "CREATE TABLE Learners(" \
		"course VARCHAR(50) NOT NULL," \
		"start_date DATE NOT NULL," \
		"no_of_weeks INT NOT NULL," \
		"joiners INT NOT NULL," \
		"leavers VARCHAR(20)," \
		"learners VARCHAR(20)," \
		"active_learners VARCHAR(20)," \
		"returning_learners VARCHAR(20)," \
		"social_learners VARCHAR(20)," \
		"fully_participating_learners VARCHAR(20)," \
		"statements_sold INT NOT NULL" \
		"university VARCHAR(40) NOT NULL," \
		"INDEX(course)," \
		"PRIMARY KEY (university, course)" \
		");"

#create all tables, if tables exist, will be deleted
drops = ['DROP TABLE IF EXISTS Comments','DROP TABLE IF EXISTS Enrolments','DROP TABLE IF EXISTS Assignments', \
		'DROP TABLE IF EXISTS Reviews','DROP TABLE IF EXISTS Quiz','DROP TABLE IF EXISTS Activity', 'DROP TABLE IF EXISTS Learners']

creates = [createComment,createEnroll,createAssignments,createReviews,createQuiz,createActivity, createLearners]

for d in drops:
	cursor.execute(d)

for c in creates:
	cursor.execute(c)
	

cursor.close()
#closeServer(server,sql)