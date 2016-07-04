import requests
from bs4 import BeautifulSoup

def login(email,password,url):
	"""Login to FutureLearn with the supplied credentials, Get a list of courses and their metadata, then attempt to download the associated CSV files

		:param:
		    	email (str): The facilitators email address
		    	password (str): The facilitators FutureLearn password
		    	url (str): The target URL
		:returns
		    	s: The session
		    	rep: The response
		"""

	s = requests.session()
	web = s.get(url)
	html = web.content
	soup = BeautifulSoup(html,'html.parser')
	tags = soup.find_all(['input'])
	login_data = {};
	for tag in tags:
		if(tag.has_attr('value') and tag.has_attr('name')):
			login_data[tag['name']] = tag['value']
	login_data['email'] = email
	login_data['password'] = password
	rep = s.post(url,data = login_data)
	return (s,rep)

