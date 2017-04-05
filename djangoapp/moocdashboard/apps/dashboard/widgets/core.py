import os, json, operator
from django.utils import six
from django.utils.functional import cached_property

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
    value = None
    descriptor = 'total'

    icon = 'bag'
    color = 'red'