from django.core.management.base import BaseCommand

from apps.enquetes.models import Estado


class Command(BaseCommand):

    def handle(self, *args, **options):

        lista_estados = (
            ('AC', 'ACRE'), 
            ('AL', 'ALAGOAS'), 
            ('AP', 'AMAPÁ'), 
            ('AM', 'AMAZONAS'), 
            ('BA', 'BAHIA'), 
            ('CE', 'CEARÁ'), 
            ('ES', 'ESPÍRITO SANTO'), 
            ('GO', 'GOIÁS'), 
            ('MA', 'MARANHÃO'), 
            ('MT', 'MATO GROSSO'), 
            ('MS', 'MATO GROSSO DO SUL'), 
            ('MG', 'MINAS GERAIS'), 
            ('PA', 'PARÁ'), 
            ('PB', 'PARAÍBA'), 
            ('PR', 'PARANÁ'), 
            ('PE', 'PERNAMBUCO'), 
            ('PI', 'PIAUÍ'), 
            ('RJ', 'RIO DE JANEIRO'), 
            ('RN', 'RIO GRANDE DO NORTE'), 
            ('RS', 'RIO GRANDE DO SUL'), 
            ('RO', 'RONDÔNIA'), 
            ('RR', 'RORAIMA'), 
            ('SC', 'SANTA CATARINA'), 
            ('SP', 'SÃO PAULO'), 
            ('SE', 'SERGIPE'), 
            ('TO', 'TOCANTINS'), 
            ('DF', 'DISTRITO FEDERAL'), 
        )

        for x in lista_estados:
            if not Estado.objects.filter(sigla=x[0]).exists():
                Estado(sigla=x[0], nome=x[1]).save()