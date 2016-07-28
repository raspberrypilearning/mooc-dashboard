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
		download_files = {}

		print "Retrieving courses..."

		enrolmentData = []

		for course_name , runs in cos.getCourses().items():
			
			for run, info in runs.items():
				run_enrol_data = info['enrolmentData']
				run_enrol_data['no_of_weeks'] = info['duration_weeks']
				enrolmentData.append(run_enrol_data)
				if(not len(info['datasets']) == 0):
					download(loginInfo, cos.getUniName(), course_name, run, info)


		# JSR Disable import as unused
		# importData(files,cos.getUniName())


		enrol_path = "../data/" +cos.getUniName()+ "/Enrolment Data"
		enrol_filename = "/Enrolment-Data.csv"
		if not os.path.exists(enrol_path):
			os.makedirs(enrol_path)

		with open(enrol_path + enrol_filename, 'w') as f:
			writer = csv.writer(f)
			writer.writerow("course,start_date,no_of_weeks,joiners,leavers,learners,active_learners,returning_learners,social_learners,fully_participating_learners,statements_sold".split(','))
			for row in enrolmentData:
				if 'learners' not in row:
					line = '{0},{1},{2},{3},{4},N/A,N/A,N/A,N/A,N/A,{5}'.format(row['course'],row['start_date'], row['no_of_weeks'],row['joiners'], row['leavers'], row['statements_sold']) 
				elif 'statements_sold' in row:
					line = '{0},{1},{2},{3},{4},{5},{6},{7},{8},{9},{10}'.format(row['course'],row['start_date'],row['no_of_weeks'],row['joiners'],row['leavers'],row['learners'],row['active_learners'],row['returning_learners'],row['social_learners'],row['fully_participating_learners'],row['statements_sold'])
				else:
					line = '{0},{1},{2},{3},{4},{5},{6},{7},{8},{9},{10}'.format(row['course'],row['start_date'],row['no_of_weeks'],row['joiners'],row['leavers'],row['learners'],row['active_learners'],row['returning_learners'],row['social_learners'],row['fully_participating_learners'],row['certificates_sold'])
				writer.writerow(line.split(','))
			f.close()

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
