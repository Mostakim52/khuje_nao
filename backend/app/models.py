from . import mongo
from bson import ObjectId

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

# Message model for MongoDB operations
class MessageModel:
    @staticmethod
    def send_message(data):
        message_id = mongo.db.messages.insert_one(data).inserted_id
        return str(message_id)

    @staticmethod
    def get_messages(chat_id, limit=50, skip=0):
        messages = (
            mongo.db.messages.find({"chat_id": chat_id})
            .skip(skip)
            .limit(limit)
            .sort("created_at", -1)  # Sort by most recent first
        )
        return list(messages)

    @staticmethod
    def get_message_by_id(message_id):
        return mongo.db.messages.find_one({"_id": ObjectId(message_id)})

    @staticmethod
    def delete_message(message_id):
        result = mongo.db.messages.delete_one({"_id": ObjectId(message_id)})
        return result.deleted_count > 0

    @staticmethod
    def update_message(message_id, updated_data):
        result = mongo.db.messages.update_one(
            {"_id": ObjectId(message_id)}, {"$set": updated_data}
        )
        return result.modified_count > 0