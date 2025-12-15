from django.shortcuts import render, redirect, get_object_or_404
from django.contrib.auth.decorators import login_required
from django.utils import timezone
from django.contrib import messages 
from django.core.exceptions import ValidationError

from .models import Produto, Categoria, Pedido, Transacao

def mercado(request, slug=None):
    """
    Exibe a lista de produtos disponíveis para venda (Mercado Global).
    Permite filtragem por categoria através do 'slug'.
    """
    produtos = Produto.objects.filter(esta_a_venda=True)
    
    if slug:
        categoria = get_object_or_404(Categoria, slug=slug)
        produtos = produtos.filter(categoria_ref=categoria)
        
    categorias = Categoria.objects.filter(ativa=True)
    return render(request, 'produtos/mercado.html', {'produtos': produtos, 'categorias': categorias})

@login_required
def inventario(request, slug=None):
    """
    Exibe os itens do usuário logado.
    Separa os itens em 'Privados' (Inventário) e 'À Venda' (Mercado).
    """
    itens_inventario = Produto.objects.filter(dono=request.user, esta_a_venda=False)
    itens_mercado = Produto.objects.filter(dono=request.user, esta_a_venda=True)
    
    if slug:
        categoria = get_object_or_404(Categoria, slug=slug)
        itens_inventario = itens_inventario.filter(categoria_ref=categoria)
        itens_mercado = itens_mercado.filter(categoria_ref=categoria)

    categorias = Categoria.objects.filter(ativa=True)
    return render(request, 'produtos/inventario.html', {'itens_inventario': itens_inventario, 'itens_mercado': itens_mercado, 'categorias': categorias})

@login_required
def historico(request):
    """
    Exibe o histórico financeiro (Transações) e de compras (Pedidos)
    do usuário logado.
    """
    transacoes = Transacao.objects.filter(perfil=request.user.perfil).order_by('-data')
    pedidos = Pedido.objects.filter(comprador=request.user).order_by('-data_pedido')
    return render(request, 'produtos/historico.html', {'transacoes': transacoes, 'pedidos': pedidos})


@login_required
def toggle_venda(request, id):
    """
    Alterna o status de um item entre 'À Venda' e 'No Inventário'.
    Se colocar à venda, define o preço e data de publicação.
    """
    # 1. Busca o produto pelo ID (ou dá erro 404 se não existir)
    produto = get_object_or_404(Produto, id=id)
    
    # 2. Segurança: Só o dono pode mexer!
    if produto.dono == request.user:
        # 3. Inverte o status (Se era True vira False, se era False vira True)
        produto.esta_a_venda = not produto.esta_a_venda 
        if produto.esta_a_venda:
            produto.publicado_em = timezone.now()
            novo_preco = request.POST.get('preco_venda')
            if novo_preco:
                produto.preco = novo_preco
        else:
            produto.preco = None
            produto.publicado_em = None
        produto.save()
        
    # 4. Manda o usuário de volta para a tela de inventário
    return redirect('inventario')

@login_required
def comprar_produto(request, id):
    """
    Processa a compra de um item.
    A lógica pesada (transação, validação) é delegada para o Model 'Produto'.
    """
    produto = get_object_or_404(Produto, id=id)
    
    try:
        # Delega a lógica complexa para o Model (Fat Model)
        produto.realizar_compra(request.user.perfil)
        messages.success(request, f"Parabéns! Você comprou {produto.nome}.")
        return redirect('inventario')
        
    except ValidationError as e:
        # Captura erros de validação do model e exibe para o usuário
        messages.error(request, e.message)
        return redirect('mercado')