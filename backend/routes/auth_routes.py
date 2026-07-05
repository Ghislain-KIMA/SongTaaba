from flask import Blueprint, request, jsonify
from flask_jwt_extended import create_access_token, jwt_required, get_jwt_identity
from services.user_service import get_user_by_email, get_user_by_id

auth_bp = Blueprint("auth", __name__)


@auth_bp.post("/login")
def login():
    data = request.get_json()
    email = data.get("email")
    password = data.get("password")

    user = get_user_by_email(email)
    if not user or not user.check_password(password):
        return jsonify({"error": "Email ou mot de passe incorrect"}), 401

    token = create_access_token(identity=user.id)
    return jsonify({"access_token": token, "user_id": user.id, "role": user.role}), 200


@auth_bp.get("/me")
@jwt_required()
def me():
    from schemas.user_schema import user_schema
    user_id = get_jwt_identity()
    user = get_user_by_id(user_id)
    return jsonify(user_schema.dump(user)), 200
