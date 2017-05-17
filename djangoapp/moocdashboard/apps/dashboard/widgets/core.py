from django.utils import six
from django.utils.functional import cached_property

from ..models import AggregateCourse

import os, json, operator

import wordcloud
import matplotlib

#Fix for Mac OS
matplotlib.use('TkAgg')
import matplotlib.pyplot as plt

__all__ = ['Widget','ItemList']

class WidgetCore():
    title = 'Untitled Widget'
    queryset = None
    additional_filters = None
    model = None
    template_name = None
    template_name_prefix = None
    cache_timeout = None
    limit_to = None
    width = None
    height = None
    options = None

    def get_template_name(self):
        assert self.template_name, (
            '{}.template_name is not defined.'.format(self))
        return os.path.join(self.template_name_prefix.rstrip(os.sep),
                            self.template_name.lstrip(os.sep))

    def get_queryset(self):
        # Copied from django.views.generic.detail
        # Boolean check will run queryset
        if self.queryset is not None:
            return self.queryset.all()
        elif self.model:
            return self.model._default_manager.all()
        raise ImproperlyConfigured(
            '{name} is missing a QuerySet. Define '
            '{name}.model, {name}.queryset or override '
            '{name}.get_queryset().'.format(name=self.__class__.__name__))

    def values(self):
        # If you put limit_to in get_queryset method
        # using of super().get_queryset() will not make any sense
        # because the queryset will be sliced
        queryset = self.get_queryset()
        if self.limit_to:
            return queryset[:self.limit_to]
        return queryset

    def update(self):
        self.values()

class Widget(WidgetCore):
    width = 12 #100% width default for widgets
    template_name_prefix = 'widgets'

class ItemList(Widget):
    list_display = None
    list_display_links = None
    template_name = 'itemlist.html'
    empty_message = 'No items to display'
    sortable = False

class ValueBox(Widget):
    template_name = 'valuebox.html'
    empty_message = 'This value is not available'
    width = 6
    descriptor = 'total'

    icon = 'bag'
    color = 'red'

    def update(self):
        filter_args = {}

        if self.course1 != 'All':
            filter_args['course'] = self.course1
            if self.run1 != 'A':
                filter_args['course_run'] = self.run1

        if self.title == 'Replies':
            filter_args['parent_id__isnull'] = False

        self.queryset = self.model.objects.count()

        if filter_args:
            self.queryset = self.model.objects.filter(**filter_args).count()

        if self.descriptor == 'average per learner':
            newfilters = {}
            if 'course' in filter_args:
                newfilters['course'] = filter_args['course']
            if 'course_run' in filter_args:
                newfilters['run'] = filter_args['course_run']

            number_of_learners_queryset = list(AggregateCourse.objects.filter(**newfilters).values('learners'))
            #print list(number_of_learners_queryset)[0]['learners']

            number_of_learners = 0
            for course in number_of_learners_queryset:
                try:
                    number_of_learners += int(str(course['learners']).split()[0])
                except ValueError:
                    number_of_learners = number_of_learners

            self.queryset = self.queryset / number_of_learners

class Table(Widget):
    template_name = 'table.html'
    empty_message = 'Table is empty'

    model = None
    ajax_url = None

    footer = False

    columns = []
    column_labels = []

    def setColumnLabelsWithDict(self):
        if isinstance(self.column_labels,dict):
            labels = []
            for column in self.columns:
                labels.append(self.column_labels[column])

            self.column_labels = labels

    def __init__(self):
        self.setColumnLabelsWithDict()

    def update(self):
        self.setColumnLabelsWithDict()
        self.updated = True

class DynamicTable(Table):
    template_name = 'dynamictable.html'

    course1 = 'All'
    run1 = 'A'
    course2=None
    run2=None
    course3=None
    run3=None
    course4=None
    run4=None

    default_ajax_url = None

    def __init__(self):
        self.default_ajax_url = self.ajax_url

    def update(self):
        self.setColumnLabelsWithDict()
        self.ajax_url = self.default_ajax_url + '?course1=' + self.course1 + '&' + 'run1=' + self.run1
        self.updated = True

class WordCloud(Widget):
    template_name = 'wordcloud.html'

    #width = 400
    height = 400
    prefer_horizontal = 0.90
    scale = 1.0
    min_font_size = 4
    font_step = 1
    max_words = 200
    stopwords = wordcloud.STOPWORDS
    background_color = "black"
    max_font_size = None

    course1 = 'All'
    run1 = 'A'
    course2 = None
    run2 = None
    course3 = None
    run3 = None
    course4 = None
    run4 = None

    queryset = None


    


