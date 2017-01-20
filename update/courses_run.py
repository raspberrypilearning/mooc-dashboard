import requests,os,datetime,unicodedata,sys,traceback
from bs4 import BeautifulSoup

class FLCourses:

	def __init__(self,login):
		"""Check we have Facilitator level privileges

			:param:
			    login: The BeautifulSoup Session
		"""
		self.__session  =  login
		self.__mainsite = 'https://www.futurelearn.com'
		self.__isAdmin = False
		self.__uni = ''
		admin_url = self.__mainsite + '/admin/courses'
		self.__rep = self.__session.get(admin_url, allow_redirects=True)
		

		if(self.__rep.status_code == 200):
			self.__isAdmin = True
			soup = BeautifulSoup(self.__rep.content,'html.parser')
			uni = soup.find_all(class_ = 'm-action-bar__title')[0]
			self.__uni = uni.text.strip()

	def getCourses(self):
		"""	Scrape the course metadata

			:return
			    courses (Dictionary) : A dictionary keyed on course name, values are themselves dictionaries of course metadata
			"""

		if(self.__isAdmin):
			webpage = self.__rep.content
			soup = BeautifulSoup(webpage,'html.parser')
			# get all courses info 
			# tables = soup.findAll("table",{'class': 'm-table m-table--manage-courses m-table--bookend'})
			tables = soup.findAll("table")
			
			courses = {}

			for table in tables:
				for course in table.find_all('tbody'):

					try:
						course_name = course.a['title']
						print "Found course: %s ..." %course_name
						#get courses run in different time
						course_runs = course.find_all('tr')
						run_count = len(course_runs)
						print "...with %d runs" %run_count
						course_info = {}

						for course_run in course_runs:
							l = course_run.find_all('span')
							
							_start_date = l[2].text
							print "...start date: %s " % _start_date
							_status = l[1].text.lower()
							print "...status: %s " % _status

							_run_details_path = course_run.find_all('a')[1].get('href')
							_stats_path = course_run.find_all('a')[2].get('href')


							# Fetch data of finished and in progress courses only.
							if( _status == 'finished' or _status == 'in progress' ):
								run_duration_weeks = self.getRunDuration(self.__mainsite + _run_details_path)

								# Convert to Date type and compute end date
								# Pad if needed. e.g. 9 May 2016 to 09 May 2016
								if(len(_start_date) == 10):
									_start_date = "0"+_start_date

								start_date = datetime.datetime.strptime(_start_date, "%d %b %Y")
								end_date = start_date + datetime.timedelta(weeks=int(run_duration_weeks))
								print "...end date: %s" %end_date

								run_data = {'start_date': start_date , 'end_date': end_date, 'duration_weeks' : run_duration_weeks, 'status' : _status, 'datasets' : self.getDatasets(self.__mainsite + _stats_path), 'enrolmentData' : self.getEnrolmentData(self.__mainsite + _stats_path + "/overview",course_name)}
								course_info[str(run_count)] = run_data
								
							run_count-=1

						courses[course_name] = course_info
					except:
						print "Course was in an invalid format."
						traceback.print_exc(file = sys.stdout)
		
			return courses
		
		else:
			return None
	

	def getDatasets(self, stats_dashboard_url):
		""" Assemble URL to datasets (CSV files)

		:param:
			stats_dashboard_url: Url for the stats dashboard for the run.
		:return:
			data (Dictionary) : A dictionary keyed on the link to the respective filename.
		"""

		data = {}
		
		if(self.__isAdmin):
			soup = BeautifulSoup(self.__session.get(stats_dashboard_url).content, 'html.parser')
			while soup.find_all('ul')[3] == None:
				soup = BeautifulSoup(self.__session.get(stats_dashboard_url).content, 'html.parser')
			
			datasets = soup.find_all('ul')[3]

			if(datasets):	
				links = datasets.find_all('li')

				for li in links:
					link = li.find('a')['href']
					split = str.split(str(link),'/')
					link = self.__mainsite + link
					filename = split[7].replace('_', '-')+'.csv'
					data[link] = filename
			return data

	def getEnrolmentData(self, stats_dashboard_url,courseName):
		""" Assemble URL to datasets (CSV files)

		:param:
			stats_dashboard_url: Url for the stats dashboard for the run.
		:return:
			enrolmentData (Dictionary) : A dictionary returning the FutureLearn enrolment learner data.
		"""
		print "Looking up enrolment data: %s" % stats_dashboard_url

		enrolmentData = {}
		monthToNum = {
			'Jan' : '01',
			'Feb' : '02',
			'Mar' : '03',
			'Apr' : '04',
			'May' : '05',
			'Jun' : '06',
			'Jul' : '07',
			'Aug' : '08',
			'Sep' : '09',
			'Oct' : '10',
			'Nov' : '11',
			'Dec' : '12',
		}


		if(self.__isAdmin):
			soup = BeautifulSoup(self.__session.get(stats_dashboard_url).content, 'html.parser')
			while soup.find("ul", class_ = 'm-breadcrumb-old-list breadcrumb') is None:
				print("Soup failed")
				soup = BeautifulSoup(self.__session.get(stats_dashboard_url).content, 'html.parser')

			table = soup.find('table', class_ = "m-table m-table--condensed")
			enrolmentData["run_id"] = " - ".join([stats_dashboard_url.split("/")[-4], stats_dashboard_url.split("/")[-3]]).encode('ascii','ignore')
			startDate = soup.find("ul", class_ = 'm-breadcrumb-old-list breadcrumb').find_all('li', class_ = 'm-breadcrumb-old-item')[1].find('a').get_text().split('-')[-1].encode('ascii','ignore').split(' ')
			enrolmentData["course"] = courseName
			enrolmentData["course_run"] = stats_dashboard_url.split("/")[-3].encode('ascii','ignore')
			if len(startDate[1]) == 1:
				day = ''.join(['0',startDate[1]])
			else:
				day = startDate[1]


			startDateFormatted = '-'.join([startDate[3],monthToNum[startDate[2]], day])
			enrolmentData["start_date"] =  startDateFormatted

			if(table):
				trs = table.find_all('tr')
				for tr in trs:
					rowName = tr.find('th').get_text().strip().encode('ascii','ignore').lower().replace(" ", "_")
					tds = tr.find_all('td')
					numeric = tds[0].get_text().strip().replace("," , "").encode('ascii','ignore')
					percent = tds[1].get_text().strip().encode('ascii','ignore')
					if rowName in ['statements_sold', 'joiners','certificates_sold']:
						enrolmentData[rowName] = numeric
					else:
						enrolmentData[rowName] = ' - '.join((numeric,percent))

			return enrolmentData

	def getRunDuration(self, _run_details_url):
		""" Find the duration of the course, in weeks

		:param _run_details_url:
		:return:
			duration
		"""
		print "Looking up duration: %s" % _run_details_url

		duration = 0
		if(self.__isAdmin):
			soup = BeautifulSoup(self.__session.get(_run_details_url).content, 'html.parser')
			run_data = soup.findAll('span',class_ = 'm-key-info__data')
			if(run_data):
				for run_datum in run_data:
					if("Duration" in run_datum.string):
						duration = run_datum.string[10:-6]
						print "Found duration: %s" % duration
		if(duration == 0):
			print("[ERROR] Unable to parse duration")
		return duration

		
	def getUniName(self):
		"""Return the institution name

		:return:
		"""
		return self.__uni
