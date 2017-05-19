import requests,datetime,mysql.connector,os,errno,json
from login import login
from csvToSQL import CSV_TO_SQL

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
		for url,filename in info['datasets'].items():
			print filename
			print "Downloading %s to %s ..." % (url, dir_path)
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
