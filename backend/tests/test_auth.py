import pytest
from app import create_app, db


@pytest.fixture
def client():
    app = create_app("testing")
    with app.app_context():
        db.create_all()
        yield app.test_client()
        db.drop_all()


def test_register(client):
    response = client.post("/api/users/register", json={
        "nom": "Dupont",
        "prenom": "Jean",
        "email": "jean@example.com",
        "password": "secret123"
    })
    assert response.status_code == 201
    data = response.get_json()
    assert data["email"] == "jean@example.com"
    assert "password" not in data


def test_login(client):
    client.post("/api/users/register", json={
        "nom": "Dupont",
        "prenom": "Jean",
        "email": "jean@example.com",
        "password": "secret123"
    })
    response = client.post("/api/auth/login", json={
        "email": "jean@example.com",
        "password": "secret123"
    })
    assert response.status_code == 200
    assert "access_token" in response.get_json()


def test_login_mauvais_mdp(client):
    client.post("/api/users/register", json={
        "nom": "Dupont",
        "prenom": "Jean",
        "email": "jean@example.com",
        "password": "secret123"
    })
    response = client.post("/api/auth/login", json={
        "email": "jean@example.com",
        "password": "mauvais"
    })
    assert response.status_code == 401