#!/usr/bin/env python
# -*- coding: utf-8 -*- 
"""
This script fetches (meta)data about Massive Open Online Courses (MOOCs) from FutureLearn.com for further processing
and presentation by the R/Shiny based web application.

Collection is achieved by a combination of HTML scraping and assembling paths to CSV files. The script then inserts the CSV files into a MYSQL database.
Reliance on fixed URL paths and the naming of HTML elements makes this script fragile and liable to irreversible breakage without notice. As soon as
FutureLearn make an API available, this script should be replaced.

"""

import datetime, json, csv, os
from download import download, importData
from login import login
from courses_run import FLCourses
import subprocess

def update(email,password):

	"""Login to FutureLearn with the supplied credentials,
	Get a list of courses and their metadata, then attempt to download the associated CSV files

	:param:
	    	email (str): The facilitators email address
	    	password (str) The facilitators FutureLearn password

	"""
	# logging in to futureLearn website with the credentials taken from config.json 
	loginInfo, rep = login(email,password,'https://www.futurelearn.com/sign-in')

	if rep.status_code == 200:
		print "Login OK..."
		# check if user has admin privileges!
		cos  = FLCourses(loginInfo)
		# files with contains the list of csvs path on disk
		files = {}

		print "Retrieving courses..."

		enrolmentData = []

		# cos.getCourses().items() will return each course and their runs alongside various info such as: start_date, end_date ect,
		# Look into ./course_run.py for the full list. These info are scrapped from the website.

		# by the end of this for loop, there will be a csv file named "Courses Data/Data/Courses-Data.csv"
		# which contains the overall info about each run of each course, This file will be later inserted into mysql, alongside other csvs,
		# which are directly downloaded from the website (not individually scrapped)
		for course_name , runs in cos.getCourses().items():
			
			for run, info in runs.items():	
				start_date = info['start_date'].strftime('%Y-%m-%d')
				end_date = info['end_date'].strftime('%Y-%m-%d')
				dir_path = "../data/" + cos.getUniName() + "/" + course_name + "/" + run +" - "+ start_date + " - "+end_date
				run_enrol_data = info['enrolmentData']
				run_enrol_data['no_of_weeks'] = info['duration_weeks']
				enrolmentData.append(run_enrol_data)
				print len(info['datasets'])
				if(not len(info['datasets']) == 0):
					# download all csvs for each run within courses
					download(loginInfo, cos.getUniName(), course_name, run, info)
					
					for url,filename in info['datasets'].items():
						files[dir_path+"/"+filename] = run


		courses_path = "../data/" +cos.getUniName()+ "/Courses Data/Data"
		courses_filename = "/Courses-Data.csv"
		if not os.path.exists(courses_path):
			os.makedirs(courses_path)

		# multiple IFs below because some runs have nulls
		# In this step, the scrapped info are written in the csv file "Courses-Data.csv"
		with open(courses_path + courses_filename, 'w') as f:
			writer = csv.writer(f, lineterminator='\n')
			writer.writerow("run_id,start_date,no_of_weeks,joiners,leavers,learners,active_learners,returning_learners,social_learners,fully_participating_learners,statements_sold,certificates_sold,upgrades_sold,learners_with_at_least_50_percent_step_completion,learners_with_at_least_90_percent_step_completion,run_retention_index,course,course_run,run".split(','))
			for row in enrolmentData:
				print(row)
				if 'upgrades_sold' in row:
					line = '{0},{1},{2},{3},{4},{5},{6},N/A,{7},N/A,0,0,{8},{9},{10},{11},{12},{13},{14}'.format(row['run_id'],row['start_date'],row['no_of_weeks'],row['joiners'],row['leavers'],row['learners'],row['active_learners'],row['social_learners'],row['upgrades_sold'],row['learners_with_at_least_50_percent_step_completion'],row['learners_with_at_least_90_percent_step_completion'],row['run_retention_index'], row['course'],row['course_run'],row['course_run'])
				elif 'joiners' not in row:
					line = '{0},{1},{2},N/A,N/A,N/A,N/A,N/A,N/A,N/A,N/A,{3},{4},{5}'.format(row['run_id'],row['start_date'], row['no_of_weeks'], row['course'],row['course_run'],row['course_run']) 
				elif 'learners' not in row and 'fully_participating_learners' in row:
					line = '{0},{1},{2},{3},{4},N/A,N/A,N/A,N/A,{5},{6},{7},N/A,{8},{9},{10},{11},{12},{13}'.format(row['run_id'],row['start_date'], row['no_of_weeks'],row['joiners'], row['leavers'], row['fully_participating_learners'], row['statements_sold'], row['certificates_sold'],row['learners_with_at_least_50_percent_step_completion'],row['learners_with_at_least_90_percent_step_completion'],row['run_retention_index'], row['course'],row['course_run'],row['course_run']) 
				elif 'learners' not in row and 'fully_participating_learners' not in row:
					line = '{0},{1},{2},{3},{4},N/A,N/A,N/A,N/A,N/A,{5},{6},{7},{8}'.format(row['run_id'],row['start_date'], row['no_of_weeks'],row['joiners'], row['leavers'], row['statements_sold'], row['course'],row['course_run'],row['course_run']) 
				# elif 'certificates_sold' in row:
				# 	line = '{0},{1},{2},{3},{4},{5},{6},{7},{8},{9},{10},{11},{12}'.format(row['run_id'],row['start_date'],row['no_of_weeks'],row['joiners'],row['leavers'],row['learners'],row['active_learners'],row['returning_learners'],row['social_learners'],row['fully_participating_learners'],row['certificates_sold'], row['course'],row['course_run'])
				elif 'returning_learners' not in row:
					line = '{0},{1},{2},{3},{4},{5},{6},N/A,{7},N/A,N/A,{8},{9},{10}'.format(row['run_id'],row['start_date'],row['no_of_weeks'],row['joiners'],row['leavers'],row['learners'],row['active_learners'],row['social_learners'], row['course'],row['course_run'],row['course_run'])
				else:
					line = '{0},{1},{2},{3},{4},{5},{6},{7},{8},{9},{10},{11},N/A,{12},{13},{14},{15},{16},{17}'.format(row['run_id'],row['start_date'],row['no_of_weeks'],row['joiners'],row['leavers'],row['learners'],row['active_learners'],row['returning_learners'],row['social_learners'],row['fully_participating_learners'],row['statements_sold'],row['certificates_sold'],row['learners_with_at_least_50_percent_step_completion'],row['learners_with_at_least_90_percent_step_completion'],row['run_retention_index'], row['course'],row['course_run'],row['course_run'])
				writer.writerow(line.split(','))
			f.close()

		files[courses_path+courses_filename] = 1
		print "Number of csv files to be inserted into database: " + str(len(files))
		# JSR Disable import as unused
		print "Changing the csv hex to unix style"
		output = subprocess.call(['../data/removeCarrigeReturn.sh', '../data'])
		# Now that all csvs are in place and stored in "files" var, then the process of inserting these csvs into mysql
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
