from . import mongo
from bson import ObjectId

# User model for MongoDB operations
class UserModel:
    @staticmethod
    def create_user(data):
        # Ensure all required fields are provided
        required_fields = ["name", "email", "phone_number", "password", "nsu_id"]
        for field in required_fields:
            if field not in data or not data[field]:
                raise ValueError(f"Missing required field: {field}")

        # Insert user into the database
        user_id = mongo.db.users.insert_one(data).inserted_id
        return str(user_id)

    @staticmethod
    def get_user_by_email(email):
        return mongo.db.users.find_one({"email": email})

    @staticmethod
    def get_user_by_nsu_id(nsu_id):
        return mongo.db.users.find_one({"nsu_id": nsu_id})


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
    def get_messages(author_id, receiver_id, limit=50, skip=0):
        messages = (
            mongo.db.messages.find(
            {"$or": [
                {"author_id": author_id, "receiver_id": receiver_id},
                {"author_id": receiver_id, "receiver_id": author_id}
            ]}
        )
            .skip(skip)
            .limit(limit)
            .sort("created_at", -1)  # Sort by most recent first
        )
        return [
            {**message, "_id": str(message["_id"])}  # Replace ObjectId with its string representation
            for message in messages
        ]