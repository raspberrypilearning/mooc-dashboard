Django MOOC Dashboard Instructions
===
Setup a virtual environment with virtualenv.

```shell
virtualenv venv
``` 

Open this environment. 

```shell
source venv/bin/activate
``` 

Install Django and all the other dependencies.
```shell
pip install django
pip install -U https://github.com/google/google-visualization-python/zipball/master
pip install wordcloud
sudo apt-get build-dep python-mysqldb
pip install mysql-python
pip install django-datatables-view
```

Then setup the new Django installation. You will create an account for the administrator panel during this.
```shell
django-admin startproject moocdashboard
python manage.py createsuperuser
python manage.py migrate
```

Copy the apps directory into the directory containing 'manage.py'.

Go into the moocdashboard directory and locate the settings file. Make sure you have the MySQL database available with data from the update script. In this example the database is called 'mooc_data' - if you change this then the models will also need updating. You will need to update this as follows:
```python
INSTALLED_APPS = [
	...
    'apps.dashboard',
    'django_datatables_view'
]

...

DATABASES = {
    ...
    'mooc_data': {
    	'ENGINE': 'django.db.backends.mysql',
    	'NAME': '',
    	'USER': '',
    	'PASSWORD': '',
    }
}

DATABASE_ROUTERS = ['apps.dashboard.router.DatabaseRouter']

...

...

LOGIN_URL = '/login/'
LOGIN_REDIRECT_URL = 'course_list'
LOGOUT_REDIRECT_URL = 'course_list'

```

Update the URLs in urls.py for the application to work.

```python
from apps.dashboard import views as views

urlpatterns = [
    ...
    url(r'^login/$', auth_views.login, name='login'),
    url(r'^logout/$', auth_views.logout, {'next_page': '/'}, name='logout'),
    url(r'^$', views.CompareView.as_view()),
    url(r'^course-list/$', views.CourseListDashboardView.as_view()),
    url(r'^dashboard/', views.DashboardView.as_view()),
    url(r'^demographics/', views.DemographicsView.as_view()),
    url(r'^statement-demographics/', views.StatementDemographicsView.as_view()),
    url(r'^sign-ups-statements-sold/', views.SignUpsStatementsSoldView.as_view()),
    url(r'^step-completion/', views.StepCompletionView.as_view()),
    url(r'^comments-overview/', views.CommentsOverviewView.as_view()),
    url(r'^comments-viewer/', views.CommentsViewerView.as_view()),
    url(r'^total-measures/', views.TotalMeasuresView.as_view()),
    url(r'^get_runs/', login_required(views.get_course_runs), name='get_runs'),
    url(r'^get_course_list/$', views.CourseListJson.as_view(), name='course_list_json'),
    url(r'^get_comments_cloud/$', views.WordCloud.as_view(), name='comments_cloud'),
    url(r'^get_comments/$', views.CommentsJson.as_view(), name='comments_json'),
]

```

To test this is all working you can run the tests included.

```shell
python manage.py test apps
```

Alternatively run the Django development server. This can be accessed at http://localhost:8000 - see the [Django documentation](https://docs.djangoproject.com/en/1.11/intro/tutorial01/#the-development-server) for more information.


```shell
python manage.py runserver
```
