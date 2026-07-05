from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required
from services.site_service import get_all_sites, get_site_by_id, create_site, update_site, delete_site
from schemas.site_schema import site_schema, sites_schema

from services.scraping import scraper_tous_les_sites, scraper_site
from services.site_service import get_site_by_id

site_bp = Blueprint("sites", __name__)


@site_bp.get("/")
@jwt_required()
def list_sites():
    actif = request.args.get("actif")
    if actif is not None:
        actif = actif.lower() == "true"
    sites = get_all_sites(actif=actif)
    return jsonify(sites_schema.dump(sites)), 200


@site_bp.get("/<string:site_id>")
@jwt_required()
def get_site(site_id):
    site = get_site_by_id(site_id)
    return jsonify(site_schema.dump(site)), 200


@site_bp.post("/")
@jwt_required()
def create():
    data = request.get_json()
    errors = site_schema.validate(data)
    if errors:
        return jsonify({"errors": errors}), 400
    site = create_site(data)
    return jsonify(site_schema.dump(site)), 201


@site_bp.put("/<string:site_id>")
@jwt_required()
def update(site_id):
    data = request.get_json()
    site = update_site(site_id, data)
    return jsonify(site_schema.dump(site)), 200


@site_bp.delete("/<string:site_id>")
@jwt_required()
def delete(site_id):
    delete_site(site_id)
    return jsonify({"message": "Site supprimé"}), 200



@site_bp.post("/scrape")
@jwt_required()
def scrape_tous():
    """Lance le scraping de tous les sites actifs."""
    resultats = scraper_tous_les_sites()
    return jsonify(resultats), 200

@site_bp.post("/<string:site_id>/scrape")
@jwt_required()
def scrape_un_site(site_id):
    """Lance le scraping d'un site spécifique."""
    site = get_site_by_id(site_id)
    n = scraper_site(site)
    return jsonify({"nouvelles_bourses": n}), 200