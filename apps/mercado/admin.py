from django.contrib import admin

from .models import OfertaDeVenda, Transacao, HistoricoDePrecos


@admin.register(OfertaDeVenda)
class OfertaDeVendaAdmin(admin.ModelAdmin):
    list_display = ('item', 'vendedor', 'preco_unitario', 'status', 'data_criacao')
    list_filter = ('status', 'data_criacao')
    list_editable = ('status',)
    search_fields = ('item__nome', 'vendedor__nome')


@admin.register(Transacao)
class TransacaoAdmin(admin.ModelAdmin):
    readonly_fields = [f.name for f in Transacao._meta.fields]
    list_display = ('data_transacao', 'item_nome_snapshot', 'valor_total')

    def valor_total(self, obj):
        return obj.preco_total
    valor_total.short_description = 'Valor Total'
    valor_total.admin_order_field = 'preco_total'


# Optional: register HistoricoDePrecos for convenience
@admin.register(HistoricoDePrecos)
class HistoricoDePrecosAdmin(admin.ModelAdmin):
    list_display = ('item', 'preco_medio', 'data_registro')
    list_filter = ('data_registro',)
    search_fields = ('item__nome',)
