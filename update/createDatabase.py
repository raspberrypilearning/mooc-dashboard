import mysql.connector

sql = mysql.connector.connect (host = 'localhost',user= 'root',password = 'moocDashboard1')
cursor = sql.cursor()

dropDB = "DROP DATABASE IF EXISTS moocs"
createDB = "CREATE DATABASE IF NOT EXISTS moocs"

cursor.execute(dropDB)
cursor.execute(createDB)
cursor.close()
sql.close()