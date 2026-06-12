import scraper

if __name__ == '__main__':
    items = scraper.atualizar_noticias(3)
    print('type:', type(items))
    try:
        print('count:', len(items))
        for i, it in enumerate(items, 1):
            print(i, it.get('title')[:80], it.get('url'))
    except Exception as e:
        print('result:', items)
