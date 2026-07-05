from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required
from services.user_service import get_all_users, get_user_by_id, create_user, update_user, delete_user
from schemas.user_schema import user_schema, users_schema

user_bp = Blueprint("users", __name__)


@user_bp.post("/register")
def register():
    data = request.get_json()
    errors = user_schema.validate(data)
    if errors:
        return jsonify({"errors": errors}), 400

    user, err = create_user(data)
    if err:
        return jsonify({"error": err}), 409

    return jsonify(user_schema.dump(user)), 201


@user_bp.get("/")
@jwt_required()
def list_users():
    users = get_all_users()
    return jsonify(users_schema.dump(users)), 200


@user_bp.get("/<string:user_id>")
@jwt_required()
def get_user(user_id):
    user = get_user_by_id(user_id)
    return jsonify(user_schema.dump(user)), 200


@user_bp.put("/<string:user_id>")
@jwt_required()
def update(user_id):
    data = request.get_json()
    user = update_user(user_id, data)
    return jsonify(user_schema.dump(user)), 200


@user_bp.delete("/<string:user_id>")
@jwt_required()
def delete(user_id):
    delete_user(user_id)
    return jsonify({"message": "Utilisateur supprimé"}), 200