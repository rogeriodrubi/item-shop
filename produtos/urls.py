from django.urls import path
from . import views

urlpatterns = [
    path('', views.mercado, name='mercado'),
    path('categoria/<slug:slug>/', views.mercado, name='mercado_por_categoria'),
    path('inventario/', views.inventario, name='inventario'),
    path('historico/', views.historico, name='historico'),
    path('inventario/categoria/<slug:slug>/', views.inventario, name='inventario_por_categoria'),
    path('produto/<int:id>/comprar/', views.comprar_produto, name='comprar_produto'),
    path('produto/<int:id>/toggle/', views.toggle_venda, name='toggle_venda'),
]