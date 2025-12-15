from django.contrib import admin
from .models import Produto, Perfil, Categoria, Pedido, ItemPedido

@admin.register(Categoria)
class CategoriaAdmin(admin.ModelAdmin):
    list_display = ('nome', 'slug', 'ativa')
    prepopulated_fields = {'slug': ('nome',)}

@admin.register(Produto)
class ProdutoAdmin(admin.ModelAdmin):
    # Colunas que aparecem na lista de produtos
    list_display = ('nome', 'preco', 'dono', 'esta_a_venda', 'categoria')
    list_filter = ('esta_a_venda', 'categoria', 'raridade')
    search_fields = ('nome', 'descricao')
    
    # Organização do formulário de edição em seções
    fieldsets = (
        ('Dados Básicos', {
            'fields': ('nome', 'descricao', 'imagem', 'dono')
        }),
        ('Detalhes do Jogo', {
            'fields': ('categoria', 'categoria_ref', 'raridade')
        }),
        ('Comércio', {
            'fields': ('preco', 'esta_a_venda', 'publicado_em', 'visualizacoes'),
            'classes': ('collapse',),
        }),
    )

class ItemPedidoInline(admin.TabularInline):
    """Permite editar itens do pedido dentro da tela do Pedido."""
    model = ItemPedido
    extra = 1

@admin.register(Pedido)
class PedidoAdmin(admin.ModelAdmin):
    list_display = ('id', 'comprador', 'data_pedido', 'valor_total')
    # Adiciona a tabela de itens dentro do pedido
    inlines = [ItemPedidoInline]

admin.site.register(Perfil)