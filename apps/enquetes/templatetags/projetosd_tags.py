import locale
from django.utils import timezone
from django.template import Library
from django.template.defaultfilters import stringfilter
from django.template.defaultfilters import floatformat
from django.contrib.humanize.templatetags.humanize import intcomma
from django.utils.encoding import force_str as force_text
from django.db.models import Sum

register = Library()

# Receives a Decimal instance and returns a string formatted 
# as brazilian Real currency: R$ 12.234,00.  
@register.filter(is_safe=True)
@stringfilter
@register.simple_tag
def brl(valor, precisao=2):
 
    try:
        valor = floatformat(valor, precisao)
        valor, decimal = force_text(valor).split('.')
        valor = intcomma(valor)
        valor = valor.replace(',', '.') + ',' + decimal
        
    except ValueError:
        pass

    return "R$ " + valor

@register.simple_tag
def divide(a, b, precision=2):
    return round(a / b, precision)

@register.simple_tag
def minus(a, b):
    return a - b

@register.simple_tag
def minimum(a, b):
    a_i = int(a)
    b_i = int(b)
    return min(a_i,b_i)