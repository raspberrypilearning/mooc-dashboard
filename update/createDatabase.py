import mysql.connector,json

credential_data = open('config.json').read()
credentials = json.loads(credential_data)

sql = mysql.connector.connect (host = 'localhost',user= 'root',password = credentials['mysqlpassword'])
cursor = sql.cursor()

dropDB = "DROP DATABASE IF EXISTS moocs"
createDB = "CREATE DATABASE IF NOT EXISTS moocs"

cursor.execute(dropDB)
cursor.execute(createDB)
cursor.close()
sql.close()