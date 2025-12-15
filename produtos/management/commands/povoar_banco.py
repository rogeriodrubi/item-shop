import os
import random
from django.conf import settings
from django.core.files import File
from django.core.management.base import BaseCommand
from django.contrib.auth.models import User
from django.utils import timezone
from produtos.models import Produto

class Command(BaseCommand):
    help = 'Povoa o banco de dados com itens específicos e imagens da pasta assets'

    def handle(self, *args, **kwargs):
        self.stdout.write(self.style.WARNING('Iniciando processo de povoamento...'))

        # 1. Limpeza: Remove usuários antigos exceto o admin
        # Isso garante que não tenhamos dados duplicados ou sujos ao rodar o script várias vezes.
        # O usuário 'admin' é preservado para não perder o acesso ao painel administrativo.
        count_deleted = User.objects.exclude(username='admin').delete()[0]
        self.stdout.write(self.style.SUCCESS(f'{count_deleted} usuários antigos removidos (admin preservado).'))

        # Dados para geração
        # Lista de nomes de personagens de RPG para criar os usuários fictícios.
        nomes_rpg = ["Aragorn", "Legolas", "Gimli", "Gandalf", "Frodo", "Sauron", "Bilbo"]
        
        # Itens definidos com suas categorias e preços
        # Dicionário contendo os metadados dos itens que serão criados.
        itens_definidos = [
            {"nome": "Poção de Vida Menor", "categoria": "variados", "raridade": "Common", "preco": 10.00},
            {"nome": "Espada Enferrujada", "categoria": "variados", "raridade": "Common", "preco": 50.00},
            {"nome": "Botas de Couro", "categoria": "armadura", "raridade": "Common", "preco": 30.00},
            {"nome": "Arco Élfico", "categoria": "variados", "raridade": "Rare", "preco": 200.00},
            {"nome": "Escudo de Mithril", "categoria": "armadura", "raridade": "Rare", "preco": 250.00},
            {"nome": "Anel do Feiticeiro", "categoria": "variados", "raridade": "Rare", "preco": 300.00},
            {"nome": "Machado de Lava", "categoria": "machado", "raridade": "Epic", "preco": 800.00},
            {"nome": "Capa das Sombras", "categoria": "armadura", "raridade": "Epic", "preco": 900.00},
            {"nome": "Excalibur", "categoria": "variados", "raridade": "Legendary", "preco": 2500.00},
            {"nome": "Pedra Filosofal", "categoria": "variados", "raridade": "Legendary", "preco": 5000.00},
        ]

        # Caminho absoluto para a pasta 'assets' na raiz do projeto, onde estão as imagens.
        assets_dir = os.path.join(settings.BASE_DIR, 'assets')

        for nome in nomes_rpg:
            # 2. Criação de Usuário
            # Verifica se o usuário já existe para evitar erros de integridade.
            if User.objects.filter(username=nome).exists():
                self.stdout.write(f"Usuário {nome} já existe, pulando...")
                continue

            # Cria o usuário com uma senha padrão.
            user = User.objects.create_user(username=nome, password='senha123')
            
            # Atualiza o saldo do Perfil
            # O perfil é criado automaticamente via Signals (post_save no models.py),
            # então aqui apenas acessamos e atualizamos o saldo inicial.
            if hasattr(user, 'perfil'):
                # Gera um saldo aleatório entre 5000 e 9000 para dar poder de compra aos bots.
                user.perfil.saldo = round(random.uniform(5000.00, 9000.00), 2)
                user.perfil.save()
            
            self.stdout.write(f"Usuário '{nome}' criado. Saldo: R$ {user.perfil.saldo}")

            # 3. Criação de Itens (3 a 6 por usuário)
            # Cada usuário receberá uma quantidade aleatória de itens do jogo.
            qtd_itens = random.randint(3, 6)
            # Escolhe itens aleatórios da lista definida sem repetição imediata na amostragem.
            itens_escolhidos = random.sample(itens_definidos, k=qtd_itens)
            
            for item_data in itens_escolhidos:
                # Define status de venda (40% chance de estar à venda no mercado)
                esta_a_venda = random.random() < 0.4
                # Se estiver à venda, define a data de publicação como agora.
                publicado_em = timezone.now() if esta_a_venda else None
                
                produto = Produto.objects.create(
                    dono=user,
                    nome=item_data['nome'],
                    descricao=item_data['raridade'],
                    preco=item_data['preco'],
                    categoria=item_data['categoria'],
                    raridade=item_data['raridade'],
                    esta_a_venda=esta_a_venda,
                    publicado_em=publicado_em,
                    visualizacoes=random.randint(0, 150) # Já inicia com views
                )
                
                # Tenta carregar a imagem da pasta assets correspondente ao nome do item.
                nome_arquivo = f"{item_data['nome']}.jpg"
                caminho_imagem = os.path.join(assets_dir, nome_arquivo)
                
                if os.path.exists(caminho_imagem):
                    # Abre o arquivo de imagem em modo binário de leitura e salva no campo ImageField.
                    # O parâmetro save=True garante que o modelo seja atualizado no banco.
                    with open(caminho_imagem, 'rb') as f:
                        produto.imagem.save(nome_arquivo, File(f), save=True)
                else:
                    self.stdout.write(self.style.WARNING(f"Imagem não encontrada: {caminho_imagem}"))
            
            self.stdout.write(self.style.SUCCESS(f"  -> {qtd_itens} itens gerados para {nome}."))

        self.stdout.write(self.style.SUCCESS('--------------------------------------------------'))
        self.stdout.write(self.style.SUCCESS('CONCLUÍDO! Banco de dados povoado com sucesso.'))