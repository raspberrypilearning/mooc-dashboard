import json, gviz_api, operator, datetime
from .core import Widget
#from ...data.models import LearnerEnrolment, LearnerActivity
from django.db.models import Count

#Charts

__all__ = ['AnnotationChart','AreaChart','BarChart','BubbleChart','CalendarChart','CandlestickChart','ColumnChart',
            'ComboChart','DiffChart','DonutChart','GanttChart','GaugeChart','GeoChart','Histogram','LineChart','OrgChart',
            'PieChart','ScatterChart','SteppedAreaChart','TableChart','Timeline','TreeMapChart','WaterfallChart','WordTree']

# Chart types
PIE, BAR, LINE, GEO = 'Pie', 'Bar', 'Line', 'Geo'

demographics = ['age_range','gender','employment_area','employment_status','highest_education_level','country']
bydaynumber = ['enrolled_at','purchased_statement_at']
steps = ['last_completed_at']

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

        if self.course2 != None:
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
        #data.sort(key=operator.itemgetter(self.order[0]))

        data_table.LoadData(data)
        #return data_table.ToJSonResponse()
        return data_table.ToJSCode("data",columns_order=self.order)
        

    def update(self):
        #Update Columns
        self.columns = {}
        if self.category in demographics:
            self.columns[self.category] = ('string', self.title)
            orderitem = self.category
        if self.category in bydaynumber:
            orderitem = self.getSubCategories(self.category)['daycategory']
            self.columns[orderitem] = ('string', self.title)
        if self.category in steps:
            self.columns['step'] = ('string', self.title)
            orderitem = 'step'

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




def FormatKeys(key):
    return key.replace('_',' ')

def FormatData(data):
    new_data = []
    for item in data:
        first_key = item.keys()[0]
        first_value = item[first_key]
        second_key = item.keys()[1]
        second_value = item[second_key]

        new_item = {}
        new_item[FormatKeys(second_key)] = second_value
        new_item[FormatKeys(first_key)] = first_value

        new_data.append(new_item)

    return new_data

def OldChart(columns,queryset,order):
    data_table = gviz_api.DataTable(columns)

    data = list(queryset)
    data.sort(key=operator.itemgetter(order[0]))
    #data = list_of_dicts.sort(key=operator.itemgetter(order[0]))
    #new_data = FormatData(data)

    data_table.LoadData(data)
    #return data_table.ToJSonResponse()
    return data_table.ToJSCode("data",columns_order=order)
