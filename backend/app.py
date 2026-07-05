# from flask import Flask
# from flask_sqlalchemy import SQLAlchemy
# from flask_migrate import Migrate
# from flask_marshmallow import Marshmallow
# from flask_jwt_extended import JWTManager
# from config import config_map
# import os

# db = SQLAlchemy()
# ma = Marshmallow()
# migrate = Migrate()
# jwt = JWTManager()


# def create_app(env=None):
#     app = Flask(__name__, instance_relative_config=True)

#     env = env or os.getenv("FLASK_ENV", "development")
#     app.config.from_object(config_map[env])

#     # Extensions
#     db.init_app(app)
#     ma.init_app(app)
#     migrate.init_app(app, db)
#     jwt.init_app(app)

#     # Register blueprints
#     from routes.auth_routes import auth_bp
#     from routes.user_routes import user_bp
#     from routes.bourse_routes import bourse_bp
#     from routes.site_routes import site_bp
#     from routes.users_bourses_routes import users_bourses_bp

#     app.register_blueprint(auth_bp, url_prefix="/api/auth")
#     app.register_blueprint(user_bp, url_prefix="/api/users")
#     app.register_blueprint(bourse_bp, url_prefix="/api/bourses")
#     app.register_blueprint(site_bp, url_prefix="/api/sites")
#     app.register_blueprint(users_bourses_bp, url_prefix="/api/users-bourses")

#     return app


# if __name__ == "__main__":
#     app = create_app()
#     app.run()



# from flask import Flask
# from extensions import db, ma, migrate, jwt
# from config import config_map
# import os


# def create_app(env=None):
#     app = Flask(__name__, instance_relative_config=True)

#     env = env or os.getenv("FLASK_ENV", "development")
#     app.config.from_object(config_map[env])

#     db.init_app(app)
#     ma.init_app(app)
#     migrate.init_app(app, db)
#     jwt.init_app(app)

#     from routes.auth_routes import auth_bp
#     from routes.user_routes import user_bp
#     from routes.bourse_routes import bourse_bp
#     from routes.site_routes import site_bp
#     from routes.users_bourses_routes import users_bourses_bp

#     app.register_blueprint(auth_bp, url_prefix="/api/auth")
#     app.register_blueprint(user_bp, url_prefix="/api/users")
#     app.register_blueprint(bourse_bp, url_prefix="/api/bourses")
#     app.register_blueprint(site_bp, url_prefix="/api/sites")
#     app.register_blueprint(users_bourses_bp, url_prefix="/api/users-bourses")

#     return app


# if __name__ == "__main__":
#     app = create_app()
#     app.run(debug=True)



from flask import Flask
from flask_migrate import Migrate
from flask_jwt_extended import JWTManager
from flask_cors import CORS
from apscheduler.schedulers.background import BackgroundScheduler
from apscheduler.triggers.cron import CronTrigger
from extensions import db, ma
from config import config_map
import os
import atexit

migrate = Migrate()
jwt = JWTManager()
scheduler = BackgroundScheduler()


def scraping_job():
    """Tâche planifiée : scrape tous les sites actifs."""
    from app import create_app
    app = create_app()
    with app.app_context():
        from services.scraping import scraper_tous_les_sites
        print("[SCHEDULER] Lancement du scraping automatique...")
        resultats = scraper_tous_les_sites()
        for site, info in resultats.items():
            print(f"  → {site} : {info}")
        print("[SCHEDULER] Scraping terminé.")


def create_app(env=None):
    app = Flask(__name__, instance_relative_config=True)

    env = env or os.getenv("FLASK_ENV", "development")
    app.config.from_object(config_map[env])

    # Extensions
    db.init_app(app)
    ma.init_app(app)
    migrate.init_app(app, db)
    jwt.init_app(app)
    CORS(app)

    # Blueprints
    from routes.auth_routes import auth_bp
    from routes.user_routes import user_bp
    from routes.bourse_routes import bourse_bp
    from routes.site_routes import site_bp
    from routes.users_bourses_routes import users_bourses_bp

    app.register_blueprint(auth_bp, url_prefix="/api/auth")
    app.register_blueprint(user_bp, url_prefix="/api/users")
    app.register_blueprint(bourse_bp, url_prefix="/api/bourses")
    app.register_blueprint(site_bp, url_prefix="/api/sites")
    app.register_blueprint(users_bourses_bp, url_prefix="/api/users-bourses")

    return app


def start_scheduler(app):
    """Démarre le scheduler avec le contexte Flask."""
    def job_avec_contexte():
        with app.app_context():
            from services.scraping import scraper_tous_les_sites
            print("[SCHEDULER] Lancement du scraping automatique...")
            resultats = scraper_tous_les_sites()
            for site, info in resultats.items():
                print(f"  → {site} : {info}")
            print("[SCHEDULER] Scraping terminé.")

    # Toutes les nuits à 02h00
    scheduler.add_job(
        func=job_avec_contexte,
        trigger=CronTrigger(hour=2, minute=0),
        id='scraping_nuit',
        name='Scraping automatique nuit',
        replace_existing=True,
    )

    scheduler.start()
    print("[SCHEDULER] Démarré — scraping planifié chaque nuit à 02h00")

    # Arrêter proprement le scheduler à la fermeture de l'app
    atexit.register(lambda: scheduler.shutdown())


if __name__ == "__main__":
    app = create_app()
    start_scheduler(app)
    app.run(debug=False)  # debug=False obligatoire avec APScheduler