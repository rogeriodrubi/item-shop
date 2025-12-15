from django.db import models
from django.core.exceptions import ValidationError
from apps.inventario.models import Item, Personagem


class OfertaDeVenda(models.Model):
    """Modelo para ofertas de venda de itens no mercado."""
    
    STATUS_CHOICES = [
        ('ATIVA', 'Ativa'),
        ('VENDIDA', 'Vendida'),
        ('CANCELADA', 'Cancelada'),
    ]
    
    vendedor = models.ForeignKey(
        Personagem,
        on_delete=models.CASCADE,
        related_name='ofertas_venda',
        verbose_name="Vendedor"
    )
    item = models.ForeignKey(
        Item,
        on_delete=models.CASCADE,
        verbose_name="Item"
    )
    quantidade = models.PositiveIntegerField(
        verbose_name="Quantidade"
    )
    preco_unitario = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        verbose_name="Preço Unitário"
    )
    status = models.CharField(
        max_length=10,
        choices=STATUS_CHOICES,
        default='ATIVA',
        verbose_name="Status"
    )
    data_criacao = models.DateTimeField(
        auto_now_add=True,
        verbose_name="Data de Criação"
    )
    
    class Meta:
        verbose_name = "Oferta de Venda"
        verbose_name_plural = "Ofertas de Venda"
    
    def clean(self):
        """Valida a quantidade e o preço da oferta."""
        if self.quantidade <= 0:
            raise ValidationError({'quantidade': 'A quantidade deve ser maior que zero.'})
        if self.preco_unitario < 0:
            raise ValidationError({'preco_unitario': 'O preço não pode ser negativo.'})
    
    def valor_total(self):
        """Calcula o valor total da oferta."""
        return self.quantidade * self.preco_unitario
    
    def __str__(self):
        return f"{self.quantidade}x {self.item.nome} - {self.vendedor.nome} ({self.get_status_display()})"


class Transacao(models.Model):
    """Modelo para registrar transações do mercado."""
    
    oferta_origem = models.ForeignKey(
        OfertaDeVenda,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        verbose_name="Oferta de Origem",
        related_name='transacoes'
    )
    item_nome_snapshot = models.CharField(
        max_length=100,
        verbose_name="Nome do Item (Snapshot)",
        help_text="Nome do item no momento da compra"
    )
    quantidade = models.PositiveIntegerField(
        verbose_name="Quantidade"
    )
    preco_total = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        verbose_name="Preço Total"
    )
    vendedor_personagem = models.ForeignKey(
        Personagem,
        on_delete=models.PROTECT,
        related_name='transacoes_como_vendedor',
        verbose_name="Vendedor"
    )
    comprador_personagem = models.ForeignKey(
        Personagem,
        on_delete=models.PROTECT,
        related_name='transacoes_como_comprador',
        verbose_name="Comprador"
    )
    data_transacao = models.DateTimeField(
        auto_now_add=True,
        verbose_name="Data da Transação"
    )
    
    class Meta:
        verbose_name = "Transação"
        verbose_name_plural = "Transações"
    
    def __str__(self):
        return f"{self.comprador_personagem.nome} comprou {self.quantidade}x {self.item_nome_snapshot} de {self.vendedor_personagem.nome}"


class HistoricoDePrecos(models.Model):
    """Modelo para manter histórico de preços médios dos itens."""
    
    item = models.ForeignKey(
        Item,
        on_delete=models.CASCADE,
        related_name='historico_precos',
        verbose_name="Item"
    )
    preco_medio = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        verbose_name="Preço Médio"
    )
    data_registro = models.DateField(
        auto_now_add=True,
        verbose_name="Data do Registro"
    )
    
    class Meta:
        verbose_name = "Histórico de Preço"
        verbose_name_plural = "Histórico de Preços"
    
    def __str__(self):
        return f"{self.item.nome}: {self.preco_medio} Zeny em {self.data_registro}"