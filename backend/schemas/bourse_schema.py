from extensions import ma
from models.bourse import Bourse
from marshmallow import fields, validate


class BourseSchema(ma.SQLAlchemyAutoSchema):
    class Meta:
        model = Bourse
        load_instance = True

    nom = fields.String(required=True, validate=validate.Length(min=1, max=255))
    site_id = fields.String(required=True)
    montant = fields.Decimal(as_string=True)
    deadline = fields.Date()
    lien_officiel = fields.Url(allow_none=True)


bourse_schema = BourseSchema()
bourses_schema = BourseSchema(many=True)