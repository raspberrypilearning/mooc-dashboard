import json, gviz_api, operator, datetime
from .core import Widget
from ..models import Comment, LearnerEnrolment, LearnerActivity
from django.db.models import Count
from decimal import *
from datetime import timedelta

#Charts

__all__ = ['AnnotationChart','AreaChart','BarChart','BubbleChart','CalendarChart','CandlestickChart','ColumnChart',
            'ComboChart','DiffChart','DonutChart','GanttChart','GaugeChart','GeoChart','Histogram','LineChart','OrgChart',
            'PieChart','ScatterChart','SteppedAreaChart','TableChart','Timeline','TreeMapChart','WaterfallChart','WordTree']

# Chart types
PIE, BAR, LINE, GEO = 'Pie', 'Bar', 'Line', 'Geo'

demographics = ['age_range','gender','employment_area','employment_status','highest_education_level','country']
bydaynumber = ['enrolled_at','purchased_statement_at']
steps = ['last_completed_at','first_visited_at']
comments = ['comments_step','comments_step_date','comments_week','commentators_week']
total_measures = 'total_measures'

class Chart(Widget):
    template_name = 'chart.html'
    chart_type = None
    height = 300

    course1 = 'All'
    run1 = 'A'
    course2=None
    run2=None
    course3=None
    run3=None
    course4=None
    run4=None

    category = None
    columns = None
    order = None

    chartdata = None

    def formIndividualQuery(self,inputcourse,run,course_run,category):
        if inputcourse == None:
            return None
        if category in demographics:
            return self.formDemographicQuery(inputcourse,run,course_run,category)
        if category in bydaynumber:
            return self.formDayNumberQuery(inputcourse,run,course_run,category)
        if category in steps:
            return self.formStepQuery(inputcourse,run,course_run,category)
        if category in comments:
            return self.formCommentQuery(inputcourse,run,course_run,category)
        if category == total_measures:
            return self.formTotalMeasuresQuery(inputcourse,run,course_run)
        return None


    def formDemographicQuery(self,inputcourse,run,course_run,category):
        filter_args = {}
        exclude_args = {
            category: 'Unknown'
        }

        queryset = self.model.objects.values(category).annotate(**{course_run: Count(category)}).order_by(category)
        if inputcourse == 'All':
            queryset = self.model.objects.exclude(**{category:'Unknown'}).values(category).annotate(**{course_run: Count(category)}).order_by(category)
        else:
            if run == 'A':
                filter_args['course'] = inputcourse
                #queryset = self.model.objects.exclude(**{category:'Unknown'}).values(category).annotate(**{course_run: Count(category)}).order_by(category).filter(course=inputcourse)
            else:
                filter_args['course'] = inputcourse
                filter_args['course_run'] = run
                #queryset = self.model.objects.exclude(**{category:'Unknown'}).values(category).annotate(**{course_run: Count(category)}).order_by(category).filter(course=inputcourse).filter(course_run=run)

            if self.additional_filters:
                for item in self.additional_filters:
                    if item['type'] == 'filter':
                        filter_args[item['arg']] = item['val']
                    if item['type'] == 'exclude':
                        exclude_args[item['arg']] = item['val']

            if filter_args:
                queryset = queryset.filter(**filter_args)
            if exclude_args:
                queryset = queryset.exclude(**exclude_args)

        return list(queryset)

    def getSubCategories(self,category):
        subcategory = 'date'
        daycategory = 'day'

        if category == 'enrolled_at':
            subcategory = 'enrolled_date'
            daycategory = 'enrolled_day'
        if category == 'purchased_statement_at':
            subcategory = 'purchased_statement_date'
            daycategory = 'purchased_statement_day'

        return {'category': category, 'subcategory': subcategory, 'daycategory': daycategory}

    def formDayNumberQuery(self,inputcourse,run,course_run,category):
        filter_args = {
            category + '__isnull': False
        }

        if(inputcourse!='All'):
            filter_args['course'] = inputcourse
            if(run!='A'):
                filter_args['course_run'] = run

        categories = self.getSubCategories(category)
        subcategory = categories['subcategory']
        daycategory = categories['daycategory']

        datesearch = "DATE(" + category + ")"

        queryset = self.model.objects.filter(**filter_args).extra(select={subcategory: datesearch}).values(subcategory).annotate(**{course_run: Count(category)}).order_by(subcategory)

        q = list(queryset)

        day_zero = q[0][subcategory]
        for item in q:
            item[daycategory] = (item[subcategory]-day_zero).days

        return q

    def formStepQuery(self,inputcourse,run,course_run,category):
        filter_args = {}
        exclude_args = {}

        queryset = self.model.objects.values('step').annotate(**{course_run: Count(category)}).order_by('step')
        if inputcourse != 'All':
            if run == 'A':
                filter_args['course'] = inputcourse
                #queryset = self.model.objects.exclude(**{category:'Unknown'}).values(category).annotate(**{course_run: Count(category)}).order_by(category).filter(course=inputcourse)
            else:
                filter_args['course'] = inputcourse
                filter_args['course_run'] = run
                #queryset = self.model.objects.exclude(**{category:'Unknown'}).values(category).annotate(**{course_run: Count(category)}).order_by(category).filter(course=inputcourse).filter(course_run=run)

            if self.additional_filters:
                for item in self.additional_filters:
                    if item['type'] == 'filter':
                        filter_args[item['arg']] = item['val']
                    if item['type'] == 'exclude':
                        exclude_args[item['arg']] = item['val']

            if filter_args:
                queryset = queryset.filter(**filter_args)
            if exclude_args:
                queryset = queryset.exclude(**exclude_args)

        return list(queryset)

    def formCommentQuery(self,inputcourse,run,course_run,category):
        filter_args = {}

        queryset = self.model.objects.values('step').annotate(total = Count('id'),child = Count('parent_id')).order_by('step')
        if category == 'comments_step':
            queryset = self.model.objects.values('step').annotate(total = Count('id'),child = Count('parent_id')).order_by('step')
        if category == 'comments_week':
            queryset = self.model.objects.values('week_number').annotate(total = Count('id'),child = Count('parent_id')).order_by('week_number')
        if category == 'commentators_week':
            queryset = self.model.objects.values('week_number').annotate(commentators = Count('author_id', distinct=True)).order_by('week_number')
        if inputcourse != 'All':
            if run == 'A':
                filter_args['course'] = inputcourse
            else:
                filter_args['course'] = inputcourse
                filter_args['course_run'] = run

            queryset = queryset.filter(**filter_args)

        queryset = list(queryset)
        if category == 'comments_step' or category == 'comments_week':
            for item in queryset:
                item['parent'] = item['total'] - item['child']

        return queryset

    def formTotalMeasuresQuery(self,inputcourse,run,course_run):
        filter_args = {
        }

        if self.course1 != 'All':
            filter_args['course'] = self.course1
            if self.run1 != 'A':
                filter_args['course_run'] = self.run1


        comments_queryset = Comment.objects.extra(select={'learner_id' : 'author_id'}).values('learner_id').filter(**filter_args).annotate(**{'comments': Count(id)})

        number_of_steps = LearnerActivity.objects.filter(**filter_args).values('step').distinct().count()

        filter_args['last_completed_at__isnull'] = False

        steps_queryset = LearnerActivity.objects.values('learner_id').filter(**filter_args).annotate(**{'steps_completed': Count('step')})

        self.queryset = self.mergeQuerysetData(list(comments_queryset),list(steps_queryset),'learner_id')

        learner_categories = {}

        for learner in self.queryset:
            if 'comments' not in learner:
                learner['comments'] = 0

            if 'steps_completed' not in learner:
                learner['steps_completed'] = 0

            percentage_complete = float(learner['steps_completed'])/number_of_steps*100
            learner_category = int(5 * round(float(percentage_complete)/5))

            if learner_category in learner_categories:
                learner_categories[learner_category].append(learner['comments'])
            else:
                learner_categories[learner_category] = [learner['comments']]

        data = []

        for i in range(0,101,5):
            cat_dict = { 'category' : i}
            if i in learner_categories:
                total_comments = 0
                z = 0
                for j in learner_categories[i]:
                    total_comments += j
                    z += 1
                average = float(total_comments)/z
                cat_dict['average'] = average
            else:
                cat_dict['average'] = 0
            data.append(cat_dict)

        return data

    def mergeQuerysetData(self,list1,list2,category):
        merged = {}
        for item in list1+list2:
            if item[category] in merged:
                merged[item[category]].update(item)
            else:
                merged[item[category]] = item

        return merged.values()

    def getQueryset(self):
        queryset1 = self.formIndividualQuery(self.course1,self.run1,'course1',self.category)
        queryset2 = self.formIndividualQuery(self.course2,self.run2,'course2',self.category)
        queryset3 = self.formIndividualQuery(self.course3,self.run3,'course3',self.category)
        queryset4 = self.formIndividualQuery(self.course4,self.run4,'course4',self.category)

        data = queryset1

        mergecategory = self.category
        if self.category in bydaynumber:
            mergecategory = self.getSubCategories(self.category)['daycategory']
        if self.category in steps:
            mergecategory = 'step'

        multiplecourses = False

        if self.course2 != None:
            multiplecourses = True
            data = self.mergeQuerysetData(data,queryset2,mergecategory)
        if self.course3 != None:
            data = self.mergeQuerysetData(data,queryset3,mergecategory)
        if self.course4 != None:
            data = self.mergeQuerysetData(data,queryset4,mergecategory)



        return data

    def getChartData(self):
        #return self.columns
        data_table = gviz_api.DataTable(self.columns)

        data = self.queryset

        courseruns = []
        if self.course1 != None:
            courseruns.append('course1')
        if self.course2 != None:
            courseruns.append('course2')
        if self.course3 != None:
            courseruns.append('course3')
        if self.course4 != None:
            courseruns.append('course4')
        

        if self.category in demographics:
            data.sort(key=operator.itemgetter(self.order[0]))
        if self.category in bydaynumber:
            data.sort(key=operator.itemgetter(self.order[0]))

            myrange = range(0,data[len(data)-1][self.order[0]])
            for i in myrange:
                if data[i][self.order[0]] != i:
                    newdict = {self.order[0]:i}
                    for course in courseruns:
                        newdict[course] = 0
                    data.insert(i,newdict)
                else: 
                    for course in courseruns:
                        if course not in data[i]:
                            data[i][course] = 0

        if self.category in steps:
            data.sort(key=operator.itemgetter(self.order[0]))
        #data.sort(key=operator.itemgetter(self.order[0]))

        if self.category == 'comments_step':
            data.sort(key=operator.itemgetter('step'))

        data_table.LoadData(data)
        #return data_table.ToJSonResponse()
        return data_table.ToJSCode("data",columns_order=self.order)
        

    def update(self):
        #Update Columns
        self.columns = {}
        orderitem = None
        if self.category in demographics:
            self.columns[self.category] = ('string', self.title)
            orderitem = self.category
        if self.category in bydaynumber:
            orderitem = self.getSubCategories(self.category)['daycategory']
            self.columns[orderitem] = ('string', self.title)
        if self.category in steps:
            self.columns['step'] = ('string', self.title)
            orderitem = 'step'

        if self.category in comments:
            if self.category == 'comments_step':
                orderitem = 'step'
                self.columns['step'] = ('string', 'Step')
            elif self.category == 'comments_week':
                orderitem = 'week_number'
                self.columns['week_number'] = ('string', 'Week')
            if self.category == 'commentators_week':
                orderitem = 'week_number'
                self.columns ['week_number'] = ('string', 'Week')
                self.columns ['commentators'] = ('number', 'Number of Commentators')
                self.order = (orderitem,'commentators')
            else:
                self.columns['parent'] = ('number','Posts')
                self.columns['child'] = ('number','Replies')
                self.order = (orderitem,'parent','child')
        elif self.category == total_measures:
            self.columns['average'] = ('number','Average Number of Comments')
            self.columns['category'] = ('number','Steps Completed %')
            self.order = ('category','average')
        else:
            self.columns['course1'] = ('number', self.course1 + ' ' + self.run1)
            self.order = (orderitem,'course1')

            if self.course2 != None:
                self.columns['course2'] = ('number', self.course2 + ' ' + self.run2)
                self.order = (orderitem,'course1','course2')
            if self.course3 != None:
                self.columns['course3'] = ('number', self.course3 + ' ' + self.run3)
                self.order = (orderitem,'course1','course2','course3')
            if self.course4 != None:
                self.columns['course4'] = ('number', self.course4 + ' ' + self.run4)
                self.order = (orderitem,'course1','course2','course3','course4')

        self.queryset = self.getQueryset()
        self.chartdata = self.getChartData()

class ColumnChart(Chart):
    chart_type = 'Column'

class BarChart(Chart):
    chart_type = 'Bar'

class LineChart(Chart):
    chart_type = 'Line'

class GeoChart(Chart):
    chart_type = 'Geo'

class HeatMapChart(Widget):
    template_name = 'heatmapchart.html'
    chart_type = 'HeatMap'
    height = 400
    width = 12

    course1 = 'All'
    run1 = 'A'

    category = None
    columns = None
    order = None

    chartdata = []

    rows = None
    columns = None
    biggesttotal = 0

    def formQuery(self,inputcourse,run,category):
        if inputcourse == None:
            return None

        filter_args = {}

        if inputcourse != 'All':
            if run == 'A':
                filter_args['course'] = inputcourse
            else:
                filter_args['course'] = inputcourse
                filter_args['course_run'] = run

        datequery = "DATE( " + category + ")"
        date = category + '_date'

        if category in steps:
            count_item = 'learner_id'
        else:
            count_item = 'id'
        queryset = self.model.objects.exclude(**{category + '__isnull': True}).extra(select={date: datequery}).values('step',date).annotate(**{'total': Count(count_item)}).values('step',date,'total').order_by('step',date).filter(**filter_args)

        return list(queryset)

    def getQueryset(self):
        self.queryset = self.formQuery(self.course1,self.run1,self.category)

        dates = set()
        steps = set()
        steps_dict = {}

        for item in self.queryset:
            if item[self.category + '_date'] != None:
                dates.add(item[self.category + '_date'])

                if item['step'] in steps_dict:
                    steps_dict[item['step']][item[self.category + '_date']] = item['total']
                else:
                    steps_dict[item['step']] = {
                        self.category + '_date': item['total']
                    }
            steps.add(item['step'])

        self.rows = sorted(dates)
        self.columns = sorted(steps)

        result = []
        for date in self.rows:
            part_result = []
            for step in self.columns:
                if date in steps_dict[step]:
                    part_result.append(steps_dict[step][date])
                else:
                    part_result.append(0)
            result.append(part_result)

        strdates = []
        for date in self.rows: 
            strdates.append(date.strftime('%Y-%m-%d'))

        self.rows = strdates

        strsteps = []
        for step in self.columns:
            strsteps.append(str(step))

        self.columns = strsteps

        return result

    def update(self):
        self.queryset = self.getQueryset()
        self.chartdata = self.queryset
