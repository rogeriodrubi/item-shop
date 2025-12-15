from django.db import models
from django.contrib.auth.models import User


class CategoriaDeItem(models.Model):
    """Modelo para categorias de itens do jogo."""
    
    nome = models.CharField(
        max_length=50,
        unique=True,
        verbose_name="Nome"
    )
    descricao = models.TextField(
        blank=True,
        verbose_name="Descrição"
    )
    
    class Meta:
        verbose_name = "Categoria de Item"
        verbose_name_plural = "Categorias de Itens"
    
    def __str__(self):
        return self.nome


class Item(models.Model):
    """Modelo para itens disponíveis no jogo."""
    
    TIPO_CHOICES = [
        ('Arma', 'Arma'),
        ('Armadura', 'Armadura'),
        ('Acessório', 'Acessório'),
        ('Consumível', 'Consumível'),
        ('Outros', 'Outros'),
    ]
    
    nome = models.CharField(
        max_length=100,
        verbose_name="Nome"
    )
    categoria = models.ForeignKey(
        CategoriaDeItem,
        on_delete=models.CASCADE,
        verbose_name="Categoria"
    )
    tipo = models.CharField(
        max_length=20,
        choices=TIPO_CHOICES,
        default='Outros',
        verbose_name="Tipo"
    )
    raridade = models.CharField(
        max_length=20,
        default='Comum',
        verbose_name="Raridade"
    )
    preco_base = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        verbose_name="Preço Base"
    )
    imagem_url = models.URLField(
        blank=True,
        null=True,
        verbose_name="URL da Imagem"
    )
    
    class Meta:
        verbose_name = "Item"
        verbose_name_plural = "Itens"
    
    def __str__(self):
        return f"{self.nome} ({self.get_tipo_display()})"


class Personagem(models.Model):
    """Modelo para personagens do jogador."""
    
    CLASSE_CHOICES = [
        ('Espadachim', 'Espadachim'),
        ('Mago', 'Mago'),
        ('Arqueiro', 'Arqueiro'),
        ('Mercador', 'Mercador'),
        ('Acólito', 'Acólito'),
        ('Gatuno', 'Gatuno'),
    ]
    
    usuario = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='personagens',
        verbose_name="Usuário"
    )
    nome = models.CharField(
        max_length=50,
        unique=True,
        verbose_name="Nome"
    )
    nivel = models.PositiveIntegerField(
        default=1,
        verbose_name="Nível"
    )
    classe = models.CharField(
        max_length=20,
        choices=CLASSE_CHOICES,
        verbose_name="Classe"
    )
    zeny = models.BigIntegerField(
        default=0,
        verbose_name="Zeny"
    )
    
    class Meta:
        verbose_name = "Personagem"
        verbose_name_plural = "Personagens"
    
    def __str__(self):
        return f"{self.nome} (Nível {self.nivel}) - {self.get_classe_display()}"


class Inventario(models.Model):
    """Modelo para gerenciar o inventário dos personagens (Many-to-Many manual)."""
    
    personagem = models.ForeignKey(
        Personagem,
        on_delete=models.CASCADE,
        related_name='itens_inventario',
        verbose_name="Personagem"
    )
    item = models.ForeignKey(
        Item,
        on_delete=models.CASCADE,
        verbose_name="Item"
    )
    quantidade = models.PositiveIntegerField(
        default=1,
        verbose_name="Quantidade"
    )
    
    class Meta:
        verbose_name = "Item no Inventário"
        verbose_name_plural = "Itens no Inventário"
        unique_together = ('personagem', 'item')
    
    def __str__(self):
        return f"{self.personagem.nome} - {self.item.nome} (x{self.quantidade})"
        return f"{self.quantidade}x {self.item.nome} - {self.personagem.nome}"