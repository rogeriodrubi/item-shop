from django.contrib import admin

from .models import (
	CategoriaDeItem,
	Item,
	Personagem,
	Inventario,
)


class InventarioInline(admin.TabularInline):
	model = Inventario
	extra = 1
	fields = ('item', 'quantidade')
	raw_id_fields = ('item',)


@admin.register(Personagem)
class PersonagemAdmin(admin.ModelAdmin):
	inlines = [InventarioInline]
	list_display = ('nome', 'classe', 'nivel', 'zeny')
	list_filter = ('classe',)
	search_fields = ('nome', 'usuario__username')
	fieldsets = (
		('Dados Básicos', {
			'fields': ('nome', 'usuario', 'classe')
		}),
		('Dados Financeiros', {
			'fields': ('zeny', 'nivel')
		}),
	)


@admin.register(CategoriaDeItem)
class CategoriaDeItemAdmin(admin.ModelAdmin):
	search_fields = ('nome',)
	list_display = ('nome',)


@admin.register(Item)
class ItemAdmin(admin.ModelAdmin):
	search_fields = ('nome',)
	list_display = ('nome', 'categoria', 'tipo', 'raridade', 'preco_base')
	list_filter = ('categoria', 'tipo', 'raridade')
	raw_id_fields = ('categoria',)


# Optional: register Inventario for direct management
@admin.register(Inventario)
class InventarioAdmin(admin.ModelAdmin):
	list_display = ('personagem', 'item', 'quantidade')
	search_fields = ('personagem__nome', 'item__nome')
	raw_id_fields = ('personagem', 'item')

