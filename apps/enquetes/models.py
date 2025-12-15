import datetime

from django.db import models
from django.utils import timezone

class Pergunta(models.Model):
    texto_da_pergunta = models.CharField(max_length=200)
    data_pub = models.DateTimeField('Data da Publicação')

    def __str__(self):
        return self.texto_da_pergunta

    def recente(self):
        return self.data_pub >= timezone.now() - datetime.timedelta(days=1)


class Resposta(models.Model):
    pergunta = models.ForeignKey(Pergunta, on_delete=models.CASCADE)
    texto_da_resposta = models.CharField(max_length=200)
    votos = models.IntegerField(default=0)

    def __str__(self):
        return self.texto_da_resposta