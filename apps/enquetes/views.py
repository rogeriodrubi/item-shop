from django.http import Http404, HttpResponse, HttpResponseRedirect
from django.shortcuts import get_object_or_404, render
from django.urls import reverse

from .models import Pergunta

def listar(request):
    ultimas = Pergunta.objects.order_by('-data_pub')[:5]
    context = {'perguntas_list': ultimas}
    return render(request, 'enquetes/index.html', context)

def detalhar(request, question_id):
    p = get_object_or_404(Pergunta, pk=question_id)
    return render(request, 'enquetes/detalhar.html', {'pergunta': p})

def resultados(request, question_id):
    p = get_object_or_404(Pergunta, pk=question_id)
    return render(request, 'enquetes/resultados.html', {'pergunta': p})

def votar(request, question_id):
    p = get_object_or_404(Pergunta, pk=question_id)
    try:
        selecionado = p.resposta_set.get(pk=request.POST['escolha'])
    except (KeyError, Pergunta.DoesNotExist):
        return render(request, 'enquetes/detalhar.html', {
            'pergunta': p,
            'erro': "Você não escolheu nenhuma opção.",
        })
    else:
        selecionado.votos += 1
        selecionado.save()
        return HttpResponseRedirect(reverse('enquetes:resultados', args=(p.id,)))





