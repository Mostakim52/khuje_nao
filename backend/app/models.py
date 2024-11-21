from . import mongo

# User model for MongoDB operations
class UserModel:
    @staticmethod
    def create_user(data):
        user_id = mongo.db.users.insert_one(data).inserted_id
        return str(user_id)

    @staticmethod
    def get_user_by_email(email):
        return mongo.db.users.find_one({"email": email})

# Lost Item model for MongoDB operations
class LostItemModel:
    @staticmethod
    def report_lost_item(data):
        item_id = mongo.db.lost_items.insert_one(data).inserted_id
        return str(item_id)

    @staticmethod
    def get_lost_items(query=None, limit=10, skip=0):
        items = mongo.db.lost_items.find(query).skip(skip).limit(limit).sort("_id", -1)
        return list(items)

    @staticmethod
    def get_recent_feed(limit=10):
        return LostItemModel.get_lost_items(limit=limit)
