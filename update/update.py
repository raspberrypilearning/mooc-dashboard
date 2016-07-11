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
				run_enrol_data['No Of Weeks'] = info['duration_weeks']
				enrolmentData.append(run_enrol_data)
				if(not len(info['datasets']) == 0):
					download(loginInfo, cos.getUniName(), course_name, run, info)


		# JSR Disable import as unused
		#importData(files,cos.getUniName())
		enrol_path = "../data/" +cos.getUniName()+ "/Enrolment Data"
		enrol_filename = "/enrolmentData.csv"
		if not os.path.exists(enrol_path):
			os.makedirs(enrol_path)

		with open(enrol_path + enrol_filename, 'w') as f:
			writer = csv.writer(f)
			writer.writerow("Course,Start Date,No Of Weeks,Joiners,Leavers,Learners,Active Learners,Returning Learners,Social Learners,Fully Participating Learners,Statements Sold".split(','))
			for row in enrolmentData:
				if 'Learners' not in row:
					line = '{0},{1},{2},{3},{4},N/A,N/A,N/A,N/A,N/A,{5}'.format(row['Course'],row['Start Date'], row['No Of Weeks'], row['Joiners'], row['Leavers'], row['Statements Sold']) 
				elif 'Statements Sold' in row:
					line = '{0},{1},{2},{3},{4},{5},{6},{7},{8},{9},{10}'.format(row['Course'],row['Start Date'],row['No Of Weeks'],row['Joiners'],row['Leavers'],row['Learners'],row['Active Learners'],row['Returning Learners'],row['Social Learners'],row['Fully Participating Learners'],row['Statements Sold'])
				else:
					line = '{0},{1},{2},{3},{4},{5},{6},{7},{8},{9},{10}'.format(row['Course'],row['Start Date'],row['No Of Weeks'],row['Joiners'],row['Leavers'],row['Learners'],row['Active Learners'],row['Returning Learners'],row['Social Learners'],row['Fully Participating Learners'],row['Certificates Sold'])
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
