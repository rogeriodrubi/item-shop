import random, string, base64, datetime
from django.utils import timezone

def get_or_none(classmodel, **kwargs):
    try:
        return classmodel.objects.get(**kwargs)
    except classmodel.DoesNotExist:
        return None


def print_exception(excpt):
    import traceback
    trace_back = traceback.extract_tb(excpt.__traceback__)
    stack_trace = list()
    for trace in trace_back:
        stack_trace.append("File : %s , Line : %d, Func.Name : %s, Message : %s" % (trace[0], trace[1], trace[2], trace[3]))

    print(stack_trace)


def convert_to_localtime(utctime):
  utc = utctime.replace(tzinfo=pytz.UTC)
  localtz = utc.astimezone(timezone.get_current_timezone())
  return localtz