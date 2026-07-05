# from flask import request
# from flask_restful import Resource
# from models import Bourse, db
# from schemas.bourse_schema import BourseSchema
# from marshmallow import ValidationError

# class BourseResource(Resource):
#     bourse_schema = BourseSchema()
#     bourse_list_schema = BourseSchema(many=True)

#     def get(self, bourse_id=None):
#         if bourse_id:
#             bourse = Bourse.query.get_or_404(bourse_id)
#             return self.bourse_schema.dump(bourse)
#         bourses = Bourse.query.all()
#         return self.bourse_list_schema.dump(bourses)

#     def post(self):
#         try:
#             new_bourse = self.bourse_schema.load(request.json)
#             db.session.add(new_bourse)
#             db.session.commit()
#             return self.bourse_schema.dump(new_bourse), 201
#         except ValidationError as err:
#             return {"message": "Validation error", "errors": err.messages}, 400

#     def put(self, bourse_id):
#         bourse = Bourse.query.get_or_404(bourse_id)
#         data = request.json
#         for key, value in data.items():
#             setattr(bourse, key, value)
#         db.session.commit()
#         return self.bourse_schema.dump(bourse)

#     def delete(self, bourse_id):
#         bourse = Bourse.query.get_or_404(bourse_id)
#         db.session.delete(bourse)
#         db.session.commit()
#         return {"message": "Bourse deleted"}, 200


from config import db
from models.bourse import Bourse

def create_bourse(data):
    bourse = Bourse(**data)
    db.session.add(bourse)
    db.session.commit()
    return bourse

def get_all_bourses():
    return Bourse.query.all()
