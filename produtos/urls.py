from django.urls import path
from . import views

urlpatterns = [
    # --- Mercado (Loja Pública) ---
    path('', views.mercado, name='mercado'),
    path('categoria/<slug:slug>/', views.mercado, name='mercado_por_categoria'),
    
    # --- Área do Usuário (Privada) ---
    path('inventario/', views.inventario, name='inventario'),
    path('inventario/categoria/<slug:slug>/', views.inventario, name='inventario_por_categoria'),
    path('historico/', views.historico, name='historico'),
    
    # --- Ações (Processamento) ---
    path('produto/<int:id>/comprar/', views.comprar_produto, name='comprar_produto'),
    path('produto/<int:id>/toggle/', views.toggle_venda, name='toggle_venda'),
]