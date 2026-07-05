import json
from app import app, db

def setup_module(module):
    db.create_all()

def teardown_module(module):
    db.session.remove()
    db.drop_all()

def test_create_user():
    client = app.test_client()
    response = client.post("/users", json={
        "nom": "Dupont",
        "prenom": "Jean",
        "email": "jean@example.com",
        "password": "secret123"
    })
    assert response.status_code == 201
    data = json.loads(response.data)
    assert data["email"] == "jean@example.com"
