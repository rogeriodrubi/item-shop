from django.db import models
from django.contrib.auth.models import User
from django.core.exceptions import ValidationError
from django.db import transaction
from django.db.models.signals import post_save
from django.dispatch import receiver

# ==============================================================================
# MODELOS DE DOMÍNIO (CORE)
# ==============================================================================

class Categoria(models.Model):
    """Representa as categorias de itens do sistema (ex: Armas, Poções)."""
    nome = models.CharField(max_length=50)
    slug = models.SlugField(unique=True, help_text="URL amigável (ex: armas)")
    icone = models.CharField(max_length=50, blank=True, help_text="Classe do ícone (ex: fa-hammer)")
    ativa = models.BooleanField(default=True)
    descricao = models.TextField(blank=True)

    def __str__(self):
        return self.nome

class Produto(models.Model):
    """
    O item principal do jogo/loja.
    Pode estar no inventário de um usuário ou à venda no mercado.
    """
    dono = models.ForeignKey(User, on_delete=models.CASCADE, related_name='produtos')
    nome = models.CharField(max_length=100)
    descricao = models.TextField(blank=True, null=True)
    preco = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    
    CATEGORIA_CHOICES = [
        ('machado', 'Machado'),
        ('cajado', 'Cajado'),
        ('armadura', 'Armadura'),
        ('variados', 'Variados'),
    ]
    categoria = models.CharField(max_length=20, choices=CATEGORIA_CHOICES, default='variados')
    
    # Opcional: Link para a nova tabela Categoria (null=True para não quebrar dados existentes)
    categoria_ref = models.ForeignKey(Categoria, on_delete=models.SET_NULL, null=True, blank=True, related_name='produtos')

    RARIDADE_CHOICES = [
        ('common', 'Comum'),
        ('rare', 'Raro'),
        ('epic', 'Épico'),
        ('legendary', 'Lendário'),
    ]
    raridade = models.CharField(max_length=20, choices=RARIDADE_CHOICES, default='common')

    # False = No Inventário (Privado) | True = No Market (Público)
    esta_a_venda = models.BooleanField(default=False)
    
    publicado_em = models.DateTimeField(blank=True, null=True)
    visualizacoes = models.PositiveIntegerField(default=0)
    
    imagem = models.ImageField(upload_to='produtos/%Y/%m/', blank=True, null=True)
    criado_em = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.nome} ({'VENDA' if self.esta_a_venda else 'INV'})"
    
    def get_icone_class(self):
        """Retorna a classe CSS do FontAwesome baseada na categoria do item."""
        icones = {
            'machado': 'fa-hammer',
            'cajado': 'fa-magic',
            'armadura': 'fa-shield-alt',
            'variados': 'fa-box',
        }
        return icones.get(self.categoria, 'fa-box')
    
    def clean(self):
        """Validações de integridade do modelo antes de salvar."""
        if self.preco is not None and self.preco < 0:
            raise ValidationError("O preço do produto não pode ser negativo.")

    @transaction.atomic
    def realizar_compra(self, comprador_perfil):
        """
        Executa a lógica transacional de compra de um item.
        Garante atomicidade: ou tudo acontece (débito, crédito, transferência),
        ou nada acontece (rollback).
        """
        vendedor_perfil = self.dono.perfil

        # 1. Validações
        if self.dono == comprador_perfil.user:
            raise ValidationError("Você não pode comprar seu próprio item!")
        if not self.esta_a_venda:
            raise ValidationError("Este item não está mais à venda.")
        if comprador_perfil.saldo < self.preco:
            raise ValidationError("Saldo insuficiente para esta compra.")

        # 2. Movimentação Financeira
        comprador_perfil.saldo -= self.preco
        vendedor_perfil.saldo += self.preco
        
        comprador_perfil.save()
        vendedor_perfil.save()

        # 3. Registros de Histórico (Transações e Pedido)
        # Importação local para evitar dependência circular se houver refatoração futura
        from .models import Transacao, Pedido, ItemPedido 

        Transacao.objects.create(perfil=comprador_perfil, tipo='saida', valor=self.preco, descricao=f"Compra de {self.nome}")
        Transacao.objects.create(perfil=vendedor_perfil, tipo='entrada', valor=self.preco, descricao=f"Venda de {self.nome}")

        pedido = Pedido.objects.create(comprador=comprador_perfil.user, valor_total=self.preco)
        ItemPedido.objects.create(pedido=pedido, produto=self, preco_na_compra=self.preco)

        # 4. Transferência de Posse
        self.dono = comprador_perfil.user
        self.esta_a_venda = False
        self.publicado_em = None
        self.preco = None
        self.save()
    
    # ... (imports anteriores)

# ==============================================================================
# MODELOS DE USUÁRIO E PERFIL
# ==============================================================================

class Perfil(models.Model):
    """Extensão do usuário padrão do Django para armazenar o Saldo (Carteira)."""
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='perfil')
    saldo = models.DecimalField(max_digits=10, decimal_places=2, default=1000.00) # Começa com 1000 reais de bônus

    def __str__(self):
        return f"Perfil de {self.user.username} - R$ {self.saldo}"

# --- Signals: Automação de criação de Perfil ---

@receiver(post_save, sender=User)
def criar_perfil_usuario(sender, instance, created, **kwargs):
    """Cria um Perfil automaticamente sempre que um novo User é criado."""
    if created:
        Perfil.objects.create(user=instance)

@receiver(post_save, sender=User)
def salvar_perfil_usuario(sender, instance, **kwargs):
    # Verifica se o perfil existe antes de salvar (para evitar erros em usuários antigos)
    if hasattr(instance, 'perfil'):
        instance.perfil.save()

# ==============================================================================
# MODELOS DE HISTÓRICO E TRANSAÇÕES
# ==============================================================================

class Transacao(models.Model):
    TIPO_CHOICES = [
        ('entrada', 'Entrada'),
        ('saida', 'Saída'),
    ]
    perfil = models.ForeignKey(Perfil, on_delete=models.CASCADE, related_name='transacoes')
    tipo = models.CharField(max_length=10, choices=TIPO_CHOICES)
    valor = models.DecimalField(max_digits=10, decimal_places=2)
    descricao = models.CharField(max_length=255)
    data = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.tipo.upper()} - R$ {self.valor}"

class Pedido(models.Model):
    comprador = models.ForeignKey(User, on_delete=models.CASCADE, related_name='compras')
    data_pedido = models.DateTimeField(auto_now_add=True)
    valor_total = models.DecimalField(max_digits=10, decimal_places=2, default=0)

    def __str__(self):
        return f"Pedido #{self.id} - {self.comprador.username}"

class ItemPedido(models.Model):
    pedido = models.ForeignKey(Pedido, on_delete=models.CASCADE, related_name='itens')
    produto = models.ForeignKey(Produto, on_delete=models.SET_NULL, null=True) # Se o produto for deletado, mantém o histórico
    preco_na_compra = models.DecimalField(max_digits=10, decimal_places=2)

    def __str__(self):
        return f"Item do Pedido #{self.pedido.id}"

class Avaliacao(models.Model):
    produto = models.ForeignKey(Produto, on_delete=models.CASCADE, related_name='avaliacoes')
    autor = models.ForeignKey(User, on_delete=models.CASCADE)
    nota = models.PositiveIntegerField(choices=[(i, str(i)) for i in range(1, 6)]) # 1 a 5
    comentario = models.TextField(blank=True)
    data = models.DateTimeField(auto_now_add=True)