import requests
from bs4 import BeautifulSoup
from datetime import datetime, timezone
from extensions import db
from models.bourse import Bourse
from models.site import Site


# ─── Scraper de base ──────────────────────────────────────────────────────────

def get_soup(url, methode='requests'):
    """Récupère le contenu HTML d'une page."""
    headers = {
        'User-Agent': (
            'Mozilla/5.0 (X11; Linux x86_64) '
            'AppleWebKit/537.36 (KHTML, like Gecko) '
            'Chrome/120.0.0.0 Safari/537.36'
        )
    }
    try:
        response = requests.get(url, headers=headers, timeout=15)
        response.raise_for_status()
        return BeautifulSoup(response.text, 'lxml')
    except requests.exceptions.RequestException as e:
        print(f"[ERREUR] Impossible d'accéder à {url} : {e}")
        return None


# ─── Scraper générique (basé sur les sélecteurs du modèle Site) ───────────────

def scraper_site(site: Site) -> int:
    """
    Scrape un site en utilisant les sélecteurs CSS configurés dans le modèle Site.
    Retourne le nombre de bourses ajoutées.
    """
    print(f"[SCRAPING] {site.nom} → {site.url}")
    soup = get_soup(site.url, site.methode_scraping or 'requests')

    if soup is None:
        return 0

    # Récupérer tous les éléments (titres = liste des bourses)
    titres = soup.select(site.title_selector) if site.title_selector else []
    descriptions = soup.select(site.description_selector) if site.description_selector else []
    deadlines = soup.select(site.deadline_selector) if site.deadline_selector else []
    liens = soup.select(site.link_selector) if site.link_selector else []

    count = 0
    for i, titre_el in enumerate(titres):
        nom = titre_el.get_text(strip=True)
        if not nom:
            continue

        # Éviter les doublons
        existant = Bourse.query.filter_by(nom=nom, site_id=site.id).first()
        if existant:
            continue

        description = descriptions[i].get_text(strip=True) if i < len(descriptions) else None
        deadline_str = deadlines[i].get_text(strip=True) if i < len(deadlines) else None
        lien = None
        if i < len(liens):
            lien = liens[i].get('href') or liens[i].get_text(strip=True)
            # Compléter les liens relatifs
            if lien and lien.startswith('/'):
                from urllib.parse import urlparse
                parsed = urlparse(site.url)
                lien = f"{parsed.scheme}://{parsed.netloc}{lien}"

        bourse = Bourse(
            nom=nom,
            organisme=site.nom,
            description=description,
            lien_officiel=lien,
            site_id=site.id,
            type=site.type_site or 'bourse',
        )
        db.session.add(bourse)
        count += 1

    # Mettre à jour la date de dernière exécution
    site.derniere_execution = datetime.now(timezone.utc)
    db.session.commit()

    print(f"[OK] {count} nouvelles bourses ajoutées depuis {site.nom}")
    return count


# ─── Scraper tous les sites actifs ───────────────────────────────────────────

def scraper_tous_les_sites() -> dict:
    """Lance le scraping de tous les sites actifs en base."""
    sites = Site.query.filter_by(actif=True).all()
    resultats = {}

    for site in sites:
        try:
            n = scraper_site(site)
            resultats[site.nom] = {'status': 'ok', 'nouvelles': n}
        except Exception as e:
            resultats[site.nom] = {'status': 'erreur', 'message': str(e)}
            db.session.rollback()

    return resultats


# ─── Scrapers spécifiques (exemples) ─────────────────────────────────────────

def scraper_campusen():
    """
    Exemple de scraper spécifique pour campusen.fr
    À adapter selon la structure réelle du site.
    """
    url = 'https://www.campusen.fr/bourses-etudiants'
    soup = get_soup(url)
    if not soup:
        return []

    bourses = []
    # Adapter les sélecteurs selon la vraie structure HTML du site
    articles = soup.select('.bourse-item')  # à adapter
    for article in articles:
        nom = article.select_one('.titre')
        organisme = article.select_one('.organisme')
        deadline = article.select_one('.deadline')
        lien = article.select_one('a')

        if nom:
            bourses.append({
                'nom': nom.get_text(strip=True),
                'organisme': organisme.get_text(strip=True) if organisme else '',
                'deadline': deadline.get_text(strip=True) if deadline else None,
                'lien_officiel': lien['href'] if lien else None,
                'type': 'bourse',
            })
    return bourses


def scraper_afd():
    """
    Exemple pour le site de l'AFD (Agence Française de Développement)
    """
    url = 'https://www.afd.fr/fr/bourses'
    soup = get_soup(url)
    if not soup:
        return []

    bourses = []
    items = soup.select('.card-bourse')  # à adapter
    for item in items:
        nom = item.select_one('h3, h2, .title')
        lien_el = item.select_one('a')
        lien = lien_el['href'] if lien_el else None
        if lien and lien.startswith('/'):
            lien = f'https://www.afd.fr{lien}'

        if nom:
            bourses.append({
                'nom': nom.get_text(strip=True),
                'organisme': 'AFD',
                'lien_officiel': lien,
                'type': 'bourse',
                'pays': 'France',
            })
    return bourses


# ─── Scraper Campus France Burkina ───────────────────────────────────────────

def scraper_campusfrance_burkina():
    """
    Scrape les actualités/bourses de Campus France Burkina.
    Sélecteurs vérifiés sur la vraie structure HTML Drupal.
    """
    url = 'https://www.burkina.campusfrance.org/recherche/type/actualite'
    soup = get_soup(url)
    if not soup:
        return []

    bourses = []
    articles = soup.select('article.node--type-actualite')
    print(f"[CAMPUSFRANCE] {len(articles)} articles trouvés")

    for article in articles:
        lien_el = article.select_one('a[rel="bookmark"]')
        if not lien_el:
            continue

        nom = lien_el.get('title', '').strip()
        lien = lien_el.get('href', '')

        if not nom:
            continue

        # Compléter l'URL relative
        if lien.startswith('/'):
            lien = f'https://www.burkina.campusfrance.org{lien}'

        # Filtrer uniquement les bourses
        mots_cles = ['bourse', 'eiffel', 'excellence', 'financement',
                     'candidature', 'allocation', 'master', 'doctorat', 'appel']
        if not any(mot in nom.lower() for mot in mots_cles):
            print(f"  [IGNORE] {nom}")
            continue

        print(f"  [OK] {nom}")
        bourses.append({
            'nom': nom,
            'organisme': 'Campus France Burkina',
            'pays': 'France',
            'description': 'Opportunité publiée par Campus France Burkina.',
            'lien_officiel': lien,
            'type': 'bourse',
            'niveau': 'Master / Doctorat',
        })

    return bourses


# ─── Sauvegarder les résultats en base ───────────────────────────────────────


# ─── Sauvegarder les résultats en base ───────────────────────────────────────

def sauvegarder_bourses(bourses: list, site_id: str) -> int:
    """Sauvegarde une liste de bourses scrapées en base, sans doublons."""
    count = 0
    for data in bourses:
        existant = Bourse.query.filter_by(nom=data['nom'], site_id=site_id).first()
        if existant:
            continue
        bourse = Bourse(site_id=site_id, **data)
        db.session.add(bourse)
        count += 1
    db.session.commit()
    return count