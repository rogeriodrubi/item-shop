from django.urls import path

from . import views

app_name = 'enquetes'

urlpatterns = [
	    
    path('', views.listar, name='listar'),
    path('<int:question_id>/', views.detalhar, name='detalhar'),
    path('<int:question_id>/resultados/', views.resultados, name='resultados'),
    path('<int:question_id>/votar/', views.votar, name='votar'),
]
