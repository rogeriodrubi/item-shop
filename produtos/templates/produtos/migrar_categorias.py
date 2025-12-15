from django.core.management.base import BaseCommand
from django.utils.text import slugify
from produtos.models import Produto, Categoria

class Command(BaseCommand):
    help = 'Migra as categorias hardcoded (choices) para a tabela Categoria'

    def handle(self, *args, **kwargs):
        # Mapeamento dos ícones (copiado do get_icone_class)
        icones = {
            'machado': 'fa-hammer',
            'cajado': 'fa-magic',
            'armadura': 'fa-shield-alt',
            'variados': 'fa-box',
        }

        # Choices definidos no model Produto
        CATEGORIA_CHOICES = [
            ('machado', 'Machado'),
            ('cajado', 'Cajado'),
            ('armadura', 'Armadura'),
            ('variados', 'Variados'),
        ]

        self.stdout.write("Iniciando migração de categorias...")

        for codigo, nome in CATEGORIA_CHOICES:
            # 1. Cria a Categoria
            slug = slugify(nome)
            icone = icones.get(codigo, 'fa-tag')
            
            categoria, created = Categoria.objects.get_or_create(
                slug=slug,
                defaults={
                    'nome': nome,
                    'icone': icone,
                    'ativa': True,
                    'descricao': f'Itens do tipo {nome}'
                }
            )

            status = "CRIADA" if created else "JÁ EXISTIA"
            self.stdout.write(f"Categoria '{nome}': {status}")

            # 2. Atualiza os produtos
            # Busca produtos com o código antigo (charfield) e atualiza a FK
            qs = Produto.objects.filter(categoria=codigo)
            updated = qs.update(categoria_ref=categoria)
            
            self.stdout.write(f"  -> {updated} produtos atualizados.")

        self.stdout.write(self.style.SUCCESS("Migração concluída com sucesso!"))