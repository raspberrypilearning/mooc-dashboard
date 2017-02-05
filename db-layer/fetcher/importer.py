import requests,mysql.connector,os,json,csv
from csvToSQL import CSV_TO_SQL

path = '../../data-layer/data'

def importer():
	files = {}

	unis = fetchUniversities()

	for uni in unis:
		fetchCoursesFromCSV(uni)
		courses = fetchCourses(uni)

		for course in courses:
			runs = fetchRuns(uni,course)
			#print uni, course, runs

	return 

def fetchUniversities():
	unis = [f for f in os.listdir(path) if os.path.isdir(os.path.join(path, f))]
	return unis

def fetchCoursesFromCSV(uni):
	items = {}
	coursesPath = path + '/' + uni + '/Courses Data/Deets/Courses-Data.csv'
	items[coursesPath] = 0
	#with open(coursesPath, 'rb') as csvfile:
		#reader = csv.reader(csvfile, delimiter=',', quotechar='|')
		#for row in reader:
			#print ', '.join(row)

	importData(items,uni)


def fetchCourses(uni):
	coursePath = path + '/' + uni
	courses = [f for f in os.listdir(coursePath) if os.path.isdir(os.path.join(coursePath, f))]
	courses.remove('Courses Data')
	return courses


def fetchRuns(uni,course):
	runPath = path + '/' + uni + '/' + course
	runs = [f for f in os.listdir(runPath) if os.path.isdir(os.path.join(runPath, f))]
	return runs


def importData(files,uni):

	credential_data = open('config.json').read()
	credentials = json.loads(credential_data)
	
	sql = mysql.connector.connect(host = 'localhost',user= 'root',password = credentials['mysqlpassword'],database = 'moocs')
	convert = CSV_TO_SQL(sql)
	
	for f,course_run in files.items():
		print f,course_run, uni
		print("Inserting " + f + " into database.")
		convert.insertIntoTable(f,course_run,uni)

		#print("Inserting " + f + " into database.")
		#convert.insertIntoTable(f,course_run,uni)
		# os.remove(f)
		# Lets not delete the csv files until the sql conversion is finished.d

importer()