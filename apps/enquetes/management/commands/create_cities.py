from django.core.management.base import BaseCommand

from apps.enquetes.models import Cidade, Estado
from apps.enquetes.data import cities_dictionary


class Command(BaseCommand):

    def handle(self, *args, **options):
        for key in cities_dictionary:
            estado = Estado.objects.get(sigla=key)
            for value in cities_dictionary[key]:
                if not Cidade.objects.filter(nome=value):
                    Cidade(estado=estado, nome=value).save()