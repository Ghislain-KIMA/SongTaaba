from extensions import ma
from models.site import Site
from marshmallow import fields, validate


class SiteSchema(ma.SQLAlchemyAutoSchema):
    class Meta:
        model = Site
        load_instance = True

    nom = fields.String(required=True, validate=validate.Length(min=1, max=255))
    url = fields.Url(required=True)
    actif = fields.Boolean()
    frequence_scraping = fields.Integer()
    derniere_execution = fields.DateTime(dump_only=True)


site_schema = SiteSchema()
sites_schema = SiteSchema(many=True)