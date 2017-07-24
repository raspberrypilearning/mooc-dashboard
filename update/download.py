import requests,datetime,mysql.connector,os,errno,json,re
from login import login
from csvToSQL import CSV_TO_SQL
from bs4 import BeautifulSoup

# Download() is responsible for downloading csvs into "data" directory, most of the csvs are directly downloaded from the website
# except "metadata.csv", which is constructed by scrapping info from the website

# importData() is the method to pass all csvs into mysql using "CSV_TO_SQL" class

def download(s, uni_name, course_name, run, info):
	""" Fetch all the datasets (CSV) for a given iteration (run) of a course

	:param s: BeautifulSoup Session
	:param uni_name: (string) The Institution name
	:param course_name: (string) The name of the course
	:param run: (integer) The iteration of the course
	:param info: (dictionary) Metadata about the course / run
	:return:
	"""

	
	
	start_date = info['start_date'].strftime('%Y-%m-%d')
	end_date = info['end_date'].strftime('%Y-%m-%d')

	dir_path = "../data/" + uni_name + "/" + course_name + "/" + run +" - "+ start_date + " - "+end_date

	

	print "Considering: %s (%s, %s - %s) status: [%s] ..." % (course_name, run, start_date, end_date,  info['status'])

	if info['status'] == 'in progress' or not os.path.isdir(dir_path):
		#We only fetch data for course runs that are currently in progress, or about which we know nothing.
		print "Creating output directory: %s" % dir_path
		try:
			os.makedirs(dir_path)
		except OSError as exc:
			if exc.errno == errno.EEXIST:
				pass
			else:
				raise

		#Create course metadata file "metadata.csv" for each run
		f_metadata_csv = open(dir_path+"/metadata.csv",'w')
		f_metadata_csv.write("uni_name,course_name,run,start_date,end_date,duration_weeks"+'\n')
		f_metadata_csv.write(uni_name+","+course_name+","+run+","+start_date+","+end_date+","+info['duration_weeks']+'\n')
		f_metadata_csv.close()

		#Download the CSVs
		myList = []
		for url,filename in info['datasets'].items():
			print filename
			print "Downloading %s to %s ..." % (url, dir_path)
			# scrap links
			if (url.endswith("overview")):
				scrapeStepLinks(s, url, dir_path)
				continue
			dow = s.get(url)
			f = open(dir_path+"/"+filename,'wb')
			f.write(dow.content)
			print "...done"
			f.close()
			s.close()
			
	else:
			print "output directory: %s exists and course is finished - skipping download " % dir_path


def importData(files,uni):

	credential_data = open('config.json').read()
	credentials = json.loads(credential_data)
	
	sql = mysql.connector.connect(host = 'localhost',user= 'root',password = credentials['mysqlpassword'],database = 'moocs')
	convert = CSV_TO_SQL(sql)
	
	for f,course_run in files.items():
		print("Inserting " + f + " into database.")
		# Insert each csv file into mysql 
		convert.insertIntoTable(f,course_run,uni)
		# os.remove(f)
		# Lets not delete the csv files until the sql conversion is finished.d

def scrapeStepLinks(s, url, dir_path):
	web = s.get(url)
	html = web.content
	soup = BeautifulSoup(html,'html.parser')
	rows = soup.find_all('div', class_ = 'm-overview__step-row')
	#Create course metadata file "metadata.csv" for each run
	f_metadata_csv = open(dir_path+"/scraped-links.csv",'w')
	f_metadata_csv.write("step_number,step_title,step_type,step_edit_url,step_url"+'\n')
	
	
	for row in rows:
		step_numberSec = row.find('span', class_ = 'm-overview__step-number')
		step_number = step_numberSec.getText().strip()
		# print('step_number: ' + step_number)
		step_titleSec = row.find('span', class_ = 'm-overview__step-title')
		step_title = re.match("(.*)\n", step_titleSec.getText().strip().encode('ascii','ignore')).group(1)
		# print('step_title: ' + step_title)
		step_typeSec = row.find('span', class_ = 'm-overview__step-type')
		step_type = step_typeSec.getText().strip()
		# print('step_type: ' + step_type)
		step_edit_urlSec = row.find('a', class_ = 'm-overview__step-edit js-action-edit')['href']
		step_edit_url = step_edit_urlSec
		# print('step_edit: ' + step_edit_url)
		web = s.get("https://www.futurelearn.com" + step_edit_url)
		html2 = web.content
		soup2 = BeautifulSoup(html2,'html.parser')
		step_url = soup2.find('div', class_ = 'offset2 span8').find_all('section')[0].find_all('a')[1]['href']
		# print('step_url: ' + step_url)
		f_metadata_csv.write(step_number+","+ "\"" + step_title+ "\"" + ","+step_type+","+step_edit_url+","+step_url+'\n')
	f_metadata_csv.close()












