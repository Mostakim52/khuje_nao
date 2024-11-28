from . import mongo
from flask import url_for
from bson import ObjectId
from datetime import datetime
from bson.objectid import ObjectId
BASE_URL = "http://10.0.2.2:5000"

# User model for MongoDB operations
class UserModel:
    @staticmethod
    def create_user(data):
        # Ensuring all required fields are provided
        required_fields = ["name", "email", "phone_number", "password", "nsu_id"]
        for field in required_fields:
            if field not in data or not data[field]:
                raise ValueError(f"Missing required field: {field}")

        # Inserting user into the database
        user_id = mongo.db.users.insert_one(data).inserted_id
        return str(user_id)

    @staticmethod
    def get_user_by_email(email):
        return mongo.db.users.find_one({"email": email})

    @staticmethod
    def get_user_by_nsu_id(nsu_id):
        return mongo.db.users.find_one({"nsu_id": nsu_id})
    
class FoundItemModel:
    @staticmethod
    def report_found_item(description, location, image_path):
        data = {
            "description": description,
            "location": location,
            "image_path": image_path,
            "created_at": datetime.utcnow()
        }
        found_item_id = mongo.db.found_items.insert_one(data).inserted_id
        return str(found_item_id)

    @staticmethod
    def get_found_items(limit=10, skip=0):
        items = (
            mongo.db.found_items.find()
            .skip(skip)
            .limit(limit)
            .sort("created_at", -1)
        )
        return [
            {**item, 
            "_id": str(item["_id"])
            }
            for item in items
        ]

class LostItemModel:
    @staticmethod
    def report_lost_item(description, location, image_path, reported_by):
        data = {
            "description": description,
            "location": location,
            "image_path": image_path,
            "reported_by": reported_by,
            "is_found": False,
            "is_approved": False,
            "created_at": datetime.utcnow(),
        }
        lost_item_id = mongo.db.lost_items.insert_one(data).inserted_id
        return str(lost_item_id)

    @staticmethod
    def mark_item_as_found(item_id):
        item = mongo.db.lost_items.find_one({"_id": ObjectId(item_id), "is_found": False})
        if not item:
            return None

        found_item_data = {
            "description": item["description"],
            "location": item["location"],
            "image_path": item["image_path"],
            "reported_by": item["reported_by"],
            "found_at": datetime.utcnow(),
        }
        mongo.db.found_items.insert_one(found_item_data)

        mongo.db.lost_items.delete_one({"_id": ObjectId(item_id)})

        return str(item_id)

    @staticmethod
    def get_lost_items(limit=10, skip=0):
        items = (
            mongo.db.lost_items.find({"is_found": False})
            .skip(skip)
            .limit(limit)
            .sort("created_at", -1)
        )
        return [
            {**item, 
            "_id": str(item["_id"])
            }
            for item in items
        ]
    
    @staticmethod
    def get_lost_items_admin(limit=10, skip=0):
        items = (
            mongo.db.lost_items.find({"is_approved": False})
            .skip(skip)
            .limit(limit)
            .sort("created_at", -1)
        )
        return [
            {**item, 
            "_id": str(item["_id"])
            }
            for item in items
        ]

from bson.objectid import ObjectId

class MessageModel:
    @staticmethod
    def send_message(data):
        message_id = mongo.db.messages.insert_one(data).inserted_id
        return str(message_id)

    @staticmethod
    def get_messages(author_id, receiver_id, limit=50, skip=0):
        # Fetch messages where either:
        # 1. The author sent a message to the receiver
        # 2. The receiver sent a message to the author (bi-directional chat)
        messages = (
            mongo.db.messages.find(
                {
                    "$or": [
                        {"author_id": author_id, "receiver_id": receiver_id},
                        {"author_id": receiver_id, "receiver_id": author_id},
                    ]
                }
            )
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
