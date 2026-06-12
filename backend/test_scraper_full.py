#!/usr/bin/env python3
import sys
sys.path.insert(0, '.')

from scraper import atualizar_noticias

print("Testando scraper...")
result = atualizar_noticias(10)

print(f"Tipo retornado: {type(result)}")
print(f"Quantidade de notícias: {len(result) if isinstance(result, list) else result}")

if isinstance(result, list) and len(result) > 0:
    print("\nPrimeiras 5 notícias:")
    for i, item in enumerate(result[:5]):
        title = item.get('title', 'SEM TÍTULO')[:70]
        portal = item.get('portal', {}).get('name', 'DESCONHECIDO')
        print(f"{i+1}. [{portal}] {title}")
        print(f"   URL: {item.get('url', 'SEM URL')[:60]}...")
        print()
else:
    print("Nenhuma notícia encontrada ou tipo inesperado")
