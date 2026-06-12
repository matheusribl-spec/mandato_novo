"""
Scraper de notícias do portal G1 para o backend.
Retorna uma lista de notícias políticas em tempo real.
"""

import hashlib
from datetime import datetime
from typing import Dict, List
from urllib.parse import urljoin

import requests
from bs4 import BeautifulSoup

BASE_URL_G1 = "https://g1.globo.com"
G1_POLITICA_URL = f"{BASE_URL_G1}/politica/"


def _unique_id_from_url(url: str) -> str:
    return hashlib.sha1(url.encode("utf-8")).hexdigest()[:16]


def _clean_text(value: str, max_length: int = 280) -> str:
    if not value:
        return ""
    return " ".join(value.strip().split())[:max_length]


def _normalize_url(href: str, base_url: str) -> str:
    if not href:
        return ""
    return href if href.startswith("http") else urljoin(base_url, href)


def _get_g1_article_links(max_items: int = 10) -> List[str]:
    try:
        resp = requests.get(
            G1_POLITICA_URL,
            timeout=15,
            headers={"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"},
        )
        resp.raise_for_status()
    except requests.RequestException:
        return []

    soup = BeautifulSoup(resp.text, "html.parser")
    urls = []
    seen = set()

    for anchor in soup.find_all("a", href=True):
        href = anchor["href"].strip()
        if "/politica/" in href and "/noticia/" in href:
            url = _normalize_url(href, BASE_URL_G1)
            if url and url not in seen:
                seen.add(url)
                urls.append(url)
            if len(urls) >= max_items:
                break

    return urls


def _scrape_g1_article(url: str) -> Dict:
    try:
        resp = requests.get(
            url,
            timeout=12,
            headers={"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"},
        )
        resp.raise_for_status()
    except requests.RequestException:
        return {}

    soup = BeautifulSoup(resp.text, "html.parser")

    title = None
    title_tag = soup.find("meta", property="og:title") or soup.find("title") or soup.find("h1")
    if title_tag:
        if title_tag.name == "meta":
            title = title_tag.get("content", "")
        else:
            title = title_tag.get_text()

    summary = None
    summary_tag = soup.find("meta", property="og:description") or soup.find("meta", attrs={"name": "description"})
    if summary_tag:
        summary = summary_tag.get("content", "")

    if not summary:
        excerpt = soup.select_one("div.content-text__container p") or soup.select_one("p")
        if excerpt:
            summary = excerpt.get_text()

    published = None
    published_tag = soup.find("meta", property="article:published_time") or soup.find("time")
    if published_tag:
        if published_tag.name == "meta":
            published = published_tag.get("content", "")
        else:
            published = published_tag.get("datetime", "") or published_tag.get_text()

    if not title:
        return {}

    if not published:
        published = datetime.utcnow().isoformat() + "Z"

    return {
        "id": _unique_id_from_url(url),
        "title": _clean_text(title, 250),
        "summary": _clean_text(summary or title, 320),
        "url": url,
        "portal": {
            "id": "g1",
            "name": "G1",
            "url": BASE_URL_G1,
            "category": "Notícias",
        },
        "theme": {
            "id": "politics",
            "title": "Política",
            "description": "Notícias políticas",
        },
        "publicationDate": published,
    }


def atualizar_noticias(max_items: int = 5) -> list:
    links = _get_g1_article_links(max_items * 2)
    news_items = []

    for link in links[:max_items]:
        item = _scrape_g1_article(link)
        if item:
            news_items.append(item)

    return news_items
