from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required
from services.bourse_service import get_all_bourses, get_bourse_by_id, create_bourse, update_bourse, delete_bourse
from schemas.bourse_schema import bourse_schema, bourses_schema

bourse_bp = Blueprint("bourses", __name__)


@bourse_bp.get("/")
def list_bourses():
    pays = request.args.get("pays")
    niveau = request.args.get("niveau")
    type_ = request.args.get("type")
    bourses = get_all_bourses(pays=pays, niveau=niveau, type_=type_)
    return jsonify(bourses_schema.dump(bourses)), 200


@bourse_bp.get("/<string:bourse_id>")
def get_bourse(bourse_id):
    bourse = get_bourse_by_id(bourse_id)
    return jsonify(bourse_schema.dump(bourse)), 200


@bourse_bp.post("/")
@jwt_required()
def create():
    data = request.get_json()
    errors = bourse_schema.validate(data)
    if errors:
        return jsonify({"errors": errors}), 400
    bourse = create_bourse(data)
    return jsonify(bourse_schema.dump(bourse)), 201


@bourse_bp.put("/<string:bourse_id>")
@jwt_required()
def update(bourse_id):
    data = request.get_json()
    bourse = update_bourse(bourse_id, data)
    return jsonify(bourse_schema.dump(bourse)), 200


@bourse_bp.delete("/<string:bourse_id>")
@jwt_required()
def delete(bourse_id):
    delete_bourse(bourse_id)
    return jsonify({"message": "Bourse supprimée"}), 200