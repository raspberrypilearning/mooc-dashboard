import mysql.connector

sql = mysql.connector.connect (host = 'localhost',user= 'root',password = 'moocDashboard1',database = 'moocs')
cursor = sql.cursor()

dropDB = "DROP DATABASE IF EXISTS moocs"
createDB = "CREATEDATABASE IF NOT EXISTS moocs"

cursor.execute(dropDB)
cursor.execute(createDB)
cursor.close()
sql.close()