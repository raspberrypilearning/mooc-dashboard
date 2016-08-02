#!/usr/bin/env python

"""
This script fetches (meta)data about Massive Open Online Courses (MOOCs) from FutureLearn.com for further processing
and presentation by the R/Shiny based web application.

Collection is achieved by a combination of HTML scraping and assembling paths to CSV files.  Reliance on fixed URL paths
and the naming of HTML elements makes this script fragile and liable to irreversible breakage without notice. As soon as
FutureLearn make an API available, this script should be replaced.

The original author included the facility import outputs to a MySQL databases (createTable.py, csvToSQL.py).
This facility is currently unused."""

import datetime, json, csv, os
from download import download, importData
from login import login
from courses_run import FLCourses


def update(email,password):

	"""Login to FutureLearn with the supplied credentials,
	Get a list of courses and their metadata, then attempt to download the associated CSV files

	:param:
	    	email (str): The facilitators email address
	    	password (str) The facilitators FutureLearn password

	"""

	loginInfo, rep = login(email,password,'https://www.futurelearn.com/sign-in')
		
	if rep.status_code == 200:
		print "Login OK..."
		cos  = FLCourses(loginInfo)
		files = {}

		print "Retrieving courses..."

		enrolmentData = []

		for course_name , runs in cos.getCourses().items():
			
			for run, info in runs.items():	
				start_date = info['start_date'].strftime('%Y-%m-%d')
				end_date = info['end_date'].strftime('%Y-%m-%d')
				dir_path = "../data/" + cos.getUniName() + "/" + course_name + "/" + run +" - "+ start_date + " - "+end_date
				run_enrol_data = info['enrolmentData']
				run_enrol_data['no_of_weeks'] = info['duration_weeks']
				enrolmentData.append(run_enrol_data)
				if(not len(info['datasets']) == 0):
					download(loginInfo, cos.getUniName(), course_name, run, info)
					
					for url,filename in info['datasets'].items():
						files[dir_path+"/"+filename] = run


		courses_path = "../data/" +cos.getUniName()+ "/Courses Data"
		courses_filename = "/Courses-Data.csv"
		if not os.path.exists(courses_path):
			os.makedirs(courses_path)

		with open(courses_path + courses_filename, 'w') as f:
			writer = csv.writer(f)
			writer.writerow("run_id,start_date,no_of_weeks,joiners,leavers,learners,active_learners,returning_learners,social_learners,fully_participating_learners,statements_sold,course,course_run".split(','))
			for row in enrolmentData:
				if 'learners' not in row:
					line = '{0},{1},{2},{3},{4},N/A,N/A,N/A,N/A,N/A,{5},{6},{7}'.format(row['run_id'],row['start_date'], row['no_of_weeks'],row['joiners'], row['leavers'], row['statements_sold'], row['course'],row['course_run']) 
				elif 'statements_sold' in row:
					line = '{0},{1},{2},{3},{4},{5},{6},{7},{8},{9},{10},{11},{12}'.format(row['run_id'],row['start_date'],row['no_of_weeks'],row['joiners'],row['leavers'],row['learners'],row['active_learners'],row['returning_learners'],row['social_learners'],row['fully_participating_learners'],row['statements_sold'], row['course'],row['course_run'])
				else:
					line = '{0},{1},{2},{3},{4},{5},{6},{7},{8},{9},{10},{11},{12}'.format(row['run_id'],row['start_date'],row['no_of_weeks'],row['joiners'],row['leavers'],row['learners'],row['active_learners'],row['returning_learners'],row['social_learners'],row['fully_participating_learners'],row['certificates_sold'], row['course'],row['course_run'])
				writer.writerow(line.split(','))
			f.close()


		files[courses_path+"/"+courses_filename] = 1


		# JSR Disable import as unused
		importData(files,cos.getUniName())

		f_update_time = open("../data/"+cos.getUniName()+"/updated.txt",'w')
		f_update_time.write(datetime.datetime.now().strftime("%Y-%m-%d %H:%M"))
		f_update_time.close()

	else:
		print "Fail"
		f = open('fail','a')
		f.write('update fail ' + datetime.datetime.now().strftime('%Y-%m-%d') +'\n')
		f.close()


# Entry point
credential_data = open('config.json').read()
credentials = json.loads(credential_data)
update(credentials['username'], credentials['password'])
