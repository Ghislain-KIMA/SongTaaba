from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from services.users_bourses_service import (
    get_bourses_by_user, get_users_by_bourse,
    add_interet, update_statut, remove_interet
)
from schemas.users_bourses_schema import users_bourse_schema, users_bourses_schema

users_bourses_bp = Blueprint("users_bourses", __name__)


@users_bourses_bp.get("/user/<string:user_id>")
@jwt_required()
def bourses_du_user(user_id):
    entries = get_bourses_by_user(user_id)
    return jsonify(users_bourses_schema.dump(entries)), 200


@users_bourses_bp.get("/bourse/<string:bourse_id>")
@jwt_required()
def users_de_la_bourse(bourse_id):
    entries = get_users_by_bourse(bourse_id)
    return jsonify(users_bourses_schema.dump(entries)), 200


@users_bourses_bp.post("/")
@jwt_required()
def marquer_interet():
    data = request.get_json()
    user_id = data.get("user_id") or get_jwt_identity()
    bourse_id = data.get("bourse_id")
    statut = data.get("statut", "interessé")

    entry, err = add_interet(user_id, bourse_id, statut)
    if err:
        return jsonify({"error": err}), 409

    return jsonify(users_bourse_schema.dump(entry)), 201


@users_bourses_bp.patch("/<string:user_id>/<string:bourse_id>")
@jwt_required()
def changer_statut(user_id, bourse_id):
    data = request.get_json()
    statut = data.get("statut")
    if not statut:
        return jsonify({"error": "statut requis"}), 400
    entry = update_statut(user_id, bourse_id, statut)
    return jsonify(users_bourse_schema.dump(entry)), 200


@users_bourses_bp.delete("/<string:user_id>/<string:bourse_id>")
@jwt_required()
def supprimer_interet(user_id, bourse_id):
    remove_interet(user_id, bourse_id)
    return jsonify({"message": "Intérêt supprimé"}), 200