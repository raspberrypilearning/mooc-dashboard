import csv,mysql.connector

# This class is responsible for inserting a csv file into mysql, based on the name which is either: comments, enrolments etc. 
# Each name has a specific schema.
# Warning, we use IGNORE to insert csv's rows into mysql, which means that if a given row is not parsed, it will not be inserted, and because "LOAD DATA LOCAL INFILE"
# is a bulk command to mysql, it may not be reported that a particular row is not inserted.

class CSV_TO_SQL:

    def __init__(self,database):
        self.__database = database

    def insertIntoTable(self,f,course_run,uni):
        """
        Inserts a csv file into the corresponding mysql table.
        :param:
            f: The file to be inserted.
            course_run: The run number.
            uni: The University the course belongs to.
        """
        _file = open(f)
        _reader = csv.reader(_file)
        head  = next(_reader)
        blank1,blank2,_filename, _extend = f.split('.')
        dots,data,uni,course, otherDeets, datatype = _filename.split("/")
        cursor = self.__database.cursor()
        delete = ''
        load = ''



        if 'comments' in datatype:
            col = ''
            setting = ''

            if(len(head) == 8):
                col = 	"(id,author_id,@parent_id,@step,@text,@timestamp,@likes,@moderated) "
                setting = "step = @step,week_number = SUBSTRING_INDEX(@step,'.',1),step_number = SUBSTRING_INDEX(@step,'.',-1),"\
                "text = @text,timestamp = @timestamp,Likes = @Likes, "''

            elif(len(head) == 10):
                col = "(id,author_id,@parent_id,step,week_number,step_number,text,@timestamp,@moderated,@likes) "
            else:
                col = "(id,author_id,@parent_id,step,week_number,step_number,text,@timestamp,@likes,@first_reported_at,@first_reported_reason,@moderation_state,@moderated) "

            load = 'LOAD DATA LOCAL INFILE '"'" + f + "'"' REPLACE INTO TABLE Comments CHARACTER SET UTF8 ' \
            "FIELDS TERMINATED BY ',' ENCLOSED BY "+  '\'"\'' + " LINES TERMINATED BY '\n' " \
            'IGNORE 1 LINES ' + col +\
            "Set parent_id = nullif(@parent_id,' '), "+ setting +" timestamp = REPLACE(@timestamp, ' UTC', ''), moderated = nullif(REPLACE(@moderated, ' UTC', ''),' '), likes = nullif(@likes,' '), university = " + "'" + uni + "'," + "course = " + "'" + course + "'," + "course_run = " \
            + str(course_run) + ";"


        elif 'enrolments' in datatype:


            load = 'LOAD DATA LOCAL INFILE '"'" + f + "'"' REPLACE INTO TABLE Enrolments ' \
            "FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n' "  +  \
            'IGNORE 1 LINES ' \
            "(learner_id,@enrolled_at,@unenrolled_at,role,@fully_participated_at,@purchased_statement_at,gender,country,age_range,highest_education_level,employment_status,employment_area,detected_country) "\
            "Set unenrolled_at = nullif(REPLACE(@unenrolled_at, ' UTC', ''),' '),fully_participated_at = nullif(REPLACE(@fully_participated_at, ' UTC', ''),' '),purchased_statement_at = nullif(REPLACE(@purchased_statement_at, ' UTC', ''),' '), enrolled_at=REPLACE(@enrolled_at, ' UTC', ''),university = " + "'" + uni + "'," + "course = " + "'" + course + "'," + "course_run = " \
            + str(course_run)  + ";"



        elif 'assignments' in datatype:

            col = 	"(id,step,step_number,week_number,author_id,text,@first_viewed_at,@submitted_at,@moderated,review_count) "


            load = 'LOAD DATA LOCAL INFILE '"'" + f + "'"' REPLACE INTO TABLE Assignments ' \
            "FIELDS TERMINATED BY ',' ENCLOSED BY "+  '\'"\'' + " LINES TERMINATED BY '\n' "  \
            'IGNORE 1 LINES '  + col + \
            "Set first_viewed_at=REPLACE(@first_viewed_at, ' UTC', ''), submitted_at=REPLACE(@submitted_at, ' UTC', ''), moderated = nullif(REPLACE(@moderated, ' UTC', ''),' '), university = " + "'" + uni + "'," + "course = " + "'" + course + "'," + "course_run = " \
            + str(course_run) + ";"


        elif 'reviews' in datatype:

            col = '(id,step,week_number,step_number,reviewer_id,assignment_id,guideline_one_feedback,guideline_two_feedback,guideline_three_feedback,@created_at)'


            load = 	'LOAD DATA LOCAL INFILE '"'" + f + "'"' REPLACE INTO TABLE Reviews ' \
            "FIELDS TERMINATED BY ',' ENCLOSED BY "+  '\'"\'' + " LINES TERMINATED BY '\n' "  \
            'IGNORE 1 LINES '  + col  + \
            "Set university = " + "'" + uni + "'," + "created_at = REPLACE (@created_at,' UTC', '')," + "course = " + "'" + course + "'," + "course_run = " \
            + str(course_run) + ";"


        elif 'question' in datatype:

            if(len(head) == 8):
                load = 	'LOAD DATA LOCAL INFILE '"'" + f + "'"' REPLACE INTO TABLE Quiz ' \
            "FIELDS TERMINATED BY ',' ENCLOSED BY "+  '\'"\''  \
            'IGNORE 1 LINES ' + "(learner_id,quiz_question,week_number,step_number,question_number,response,@submitted_at,@correct)" +\
            "Set correct = STRCMP(UPPER(@correct),'TRUE') + 1, submitted_at=REPLACE(@submitted_at, ' UTC', ''), university = " + "'" + uni + "'," + "course = " + "'" + course + "'," + "course_run = " \
            + str(course_run) + ";"

            else:
                load = 	'LOAD DATA LOCAL INFILE '"'" + f + "'"' REPLACE INTO TABLE Quiz ' \
            "FIELDS TERMINATED BY ',' ENCLOSED BY "+  '\'"\''  \
            'IGNORE 1 LINES ' + "(learner_id,quiz_question,question_type,week_number,step_number,question_number,response,@cloze_response,@submitted_at,@correct)" +\
            "Set correct = STRCMP(UPPER(@correct),'TRUE') + 1, cloze_response = @cloze_response, submitted_at=REPLACE(@submitted_at, ' UTC', ''), university = " + "'" + uni + "'," + "course = " + "'" + course + "'," + "course_run = " \
            + str(course_run) + ";"






        elif 'activity' in datatype:

            col = ''
            setting = ''
            if(len(head) == 4):
                col = '(learner_id,@step,@first_visited_at,@last_completed_at)'
                setting = "step = @step, week_number = SUBSTRING_INDEX(@step,'.',1),step_number = SUBSTRING_INDEX(@step,'.',-1)," \

            else:
                col = '(learner_id,step,week_number,step_number,@first_visited_at,@last_completed_at)'


            load = 'LOAD DATA LOCAL INFILE '"'" + f + "'"' REPLACE INTO TABLE Activity ' \
            "FIELDS TERMINATED BY ',' "  \
            "IGNORE 1 LINES " + col +\
            "Set " + setting + "last_completed_at = nullif(REPLACE (@last_completed_at, ' UTC', ''),' '),  first_visited_at = nullif(REPLACE(@first_visited_at,' UTC', ''), ' '), university = " + "'" + uni + "'," + "course = " + "'" + course + "'," + "course_run = " \
            + str(course_run) + ";"

        elif 'Courses' in datatype:

            col = '(run_id,start_date,no_of_weeks,joiners,leavers,leavers_percent,learners,learners_percent,active_learners,active_learners_percent,returning_learners,returning_learners_percent,social_learners,social_learners_percent,fully_participating_learners,fully_participating_learners_percent,statements_sold,certificates_sold,upgrades_sold,upgrades_sold_percent,learners_with_at_least_50_percent_step_completion,learners_with_at_least_50_percent_step_completion_percent,learners_with_at_least_90_percent_step_completion,learners_with_at_least_90_percent_step_completion_percent,run_retention_index,run_retention_index_percent,course,course_run,run)'
            load = 'LOAD DATA LOCAL INFILE '"'" + f + "'"' REPLACE INTO TABLE Courses ' \
            "FIELDS TERMINATED BY ',' " \
            "IGNORE 1 LINES " + col + \
            "Set university = " + "'" + uni + "';"

        elif 'team-members' in datatype:
            col = '(id,first_name,last_name,team_role,user_role)'

            load = 	'LOAD DATA LOCAL INFILE '"'" + f + "'"' REPLACE INTO TABLE TeamMembers ' \
            "FIELDS TERMINATED BY ',' ENCLOSED BY "+  '\'"\''  \
            'IGNORE 1 LINES '  + col +";"

        elif 'video-stats' in datatype:
            col = '(title,total_views,total_downloads,total_caption_views,total_transcript_views,viewed_hd,viewed_five_percent,viewed_ten_percent,viewed_twentyfive_percent,viewed_fifty_percent,viewed_seventyfive_percent,viewed_ninetyfive_percent,viewed_onehundred_percent,console_device_percentage,desktop_device_percentage,mobile_device_percentage,tv_device_percentage,tablet_device_percentage,unknown_device_percentage,europe_views_percentage,oceania_views_percentage,asia_views_percentage,north_america_views_percentage,south_america_views_percentage,africa_views_percentage,antarctica_views_percentage)'
            load =  'LOAD DATA LOCAL INFILE '"'" + f + "'"' REPLACE INTO TABLE VideoStats ' \
            "FIELDS TERMINATED BY ',' ENCLOSED BY "+  '\'"\''  \
            'IGNORE 1 LINES '  + col +\
            "Set university = " + "'" + uni + "'," + "course = " + "'" + course + "'," + "course_run = " \
            + str(course_run) + ";"
        
        elif 'extract-links' in datatype:
            col = '(`Week Number`,`Step Number`,`Step Title`,`Step URL`,`Part`,`Field`,`Link Target`,`Link Caption`)'
            load =  'LOAD DATA LOCAL INFILE '"'" + f + "'"' REPLACE INTO TABLE ExtractLinks ' \
            "FIELDS TERMINATED BY ',' ENCLOSED BY "+  '\'"\''  \
            'IGNORE 1 LINES '  + col +\
            "Set university = " + "'" + uni + "'," + "course = " + "'" + course + "'," + "course_run = " \
            + str(course_run) + ";"

        elif 'scraped-links' in datatype:
            col = '(step_number,step_title,step_type,step_edit_url,step_url)'
            load =  'LOAD DATA LOCAL INFILE '"'" + f + "'"' REPLACE INTO TABLE ScrapedLinks ' \
            "FIELDS TERMINATED BY ',' ENCLOSED BY "+  '\'"\''  \
            'IGNORE 1 LINES '  + col +\
            "Set university = " + "'" + uni + "'," + "course = " + "'" + course + "'," + "course_run = " \
            + str(course_run) + ";"

        cursor.execute(load)
        self.__database.commit()
        cursor.close()
        _file.close()