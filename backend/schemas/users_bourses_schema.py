from extensions import ma
from models.users_bourses import UsersBourses
from marshmallow import fields, validate


class UsersBourseSchema(ma.SQLAlchemyAutoSchema):
    class Meta:
        model = UsersBourses
        load_instance = True

    user_id = fields.String(required=True)
    bourse_id = fields.String(required=True)
    statut = fields.String(validate=validate.OneOf(["interessé", "candidat", "accepté", "refusé"]))
    datetime_interet = fields.DateTime(dump_only=True)


users_bourse_schema = UsersBourseSchema()
users_bourses_schema = UsersBourseSchema(many=True)