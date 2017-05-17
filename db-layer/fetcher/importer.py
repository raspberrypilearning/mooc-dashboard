import datetime,mysql.connector,os
from csvToSQL import CSV_TO_SQL

class Course:
    university = ''
    course = ''
    run = ''
    
    def __init__(self,university,course,run):
        self.university = university
        self.course = course
        self.run = run

    def __str__(self):
        return self.university + ' - ' + self.course + ' - ' + self.run

dir = '../../data-layer/data/'

universities = []
for uni in os.listdir(dir):
    universities.append(uni)

courses = []
for uni in universities:
    for course in os.listdir(dir + uni):
        for course_run in os.listdir(dir + uni + '/' + course):
            courses.append(Course(uni,course,course_run))

sql = mysql.connector.connect(host = 'localhost',user= 'root',password = 'marmite',database = 'moocs')
convert = CSV_TO_SQL(sql)

for course in courses:
    for file in os.listdir(dir + course.university + '/' + course.course + '/' + course.run):
        filename = dir + course.university + '/' + course.course + '/' + course.run + '/' + file
        convert.insertIntoTable(filename,course.run.split()[0],course.university)
