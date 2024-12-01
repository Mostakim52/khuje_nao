"""
models.py

This module defines the models for interacting with the MongoDB database. It includes
models for managing users, lost items, found items, and messages.
"""

from datetime import datetime
from bson import ObjectId
from bson.objectid import ObjectId
from flask import url_for
from . import mongo


BASE_URL = "http://10.0.2.2:5000"

# UserModel
class UserModel:
    """
    Handles database operations related to users.
    """

    @staticmethod
    def create_user(data):
        """
        Creates a new user in the database.

        Args:
            data (dict): A dictionary containing user details. Required fields: 
                         "name", "email", "phone_number", "password", "nsu_id".

        Returns:
            str: The unique ID of the created user.

        Raises:
            ValueError: If any required field is missing.
        """
        required_fields = ["name", "email", "phone_number", "password", "nsu_id"]
        for field in required_fields:
            if field not in data or not data[field]:
                raise ValueError(f"Missing required field: {field}")

        user_id = mongo.db.users.insert_one(data).inserted_id
        return str(user_id)

    @staticmethod
    def get_user_by_email(email):
        """
        Retrieves a user by their email address.

        Args:
            email (str): The email of the user to find.

        Returns:
            dict: The user's details if found, otherwise None.
        """
        return mongo.db.users.find_one({"email": email})

    @staticmethod
    def get_user_by_nsu_id(nsu_id):
        """
        Retrieves a user by their NSU ID.

        Args:
            nsu_id (str): The NSU ID of the user to find.

        Returns:
            dict: The user's details if found, otherwise None.
        """
        return mongo.db.users.find_one({"nsu_id": nsu_id})

# FoundItemModel
class FoundItemModel:
    """
    Handles database operations related to found items.
    """

    @staticmethod
    def report_found_item(description, location, image_path):
        """
        Reports a found item.

        Args:
            description (str): A description of the found item.
            location (str): The location where the item was found.
            image_path (str): Path to the image of the found item.

        Returns:
            str: The unique ID of the reported item.
        """
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
        """
        Retrieves a list of found items.

        Args:
            limit (int): The maximum number of items to retrieve.
            skip (int): The number of items to skip.

        Returns:
            list: A list of found items with their details.
        """
        items = (
            mongo.db.found_items.find()
            .skip(skip)
            .limit(limit)
            .sort("created_at", -1)
        )
        return [{**item, "_id": str(item["_id"])} for item in items]

# LostItemModel
class LostItemModel:
    """
    Handles database operations related to lost items.
    """

    @staticmethod
    def report_lost_item(description, location, image_path, reported_by):
        """
        Reports a lost item.

        Args:
            description (str): A description of the lost item.
            location (str): The location where the item was lost.
            image_path (str): Path to the image of the lost item.
            reported_by (str): The user who reported the lost item.

        Returns:
            str: The unique ID of the reported lost item.
        """
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
        """
        Marks a lost item as found and moves it to the found items collection.

        Args:
            item_id (str): The unique ID of the lost item.

        Returns:
            str: The ID of the marked item if successful, otherwise None.
        """
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
        """
        Retrieves a list of lost items.

        Args:
            limit (int): The maximum number of items to retrieve.
            skip (int): The number of items to skip.

        Returns:
            list: A list of lost items with their details.
        """
        items = (
            mongo.db.lost_items.find({"is_found": False})
            .skip(skip)
            .limit(limit)
            .sort("created_at", -1)
        )
        return [{**item, "_id": str(item["_id"])} for item in items]

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

# MessageModel
class MessageModel:
    """
    Handles database operations related to user messages.
    """

    @staticmethod
    def send_message(data):
        """
        Sends a new message.

        Args:
            data (dict): The message data.

        Returns:
            str: The unique ID of the sent message.
        """
        message_id = mongo.db.messages.insert_one(data).inserted_id
        return str(message_id)

    @staticmethod
    def get_messages(author_id, receiver_id, limit=50, skip=0):
        """
        Retrieves messages between two users.

        Args:
            author_id (str): The ID of the author.
            receiver_id (str): The ID of the receiver.
            limit (int): The maximum number of messages to retrieve.
            skip (int): The number of messages to skip.

        Returns:
            list: A list of messages.
        """
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
            .sort("created_at", -1)
        )
        return list(messages)
    
    @staticmethod
    def get_message_by_id(message_id):
        return mongo.db.messages.find_one({"_id": ObjectId(message_id)})

    @staticmethod
    def delete_message(message_id):
        """
        Deletes a message by its ID.

        Args:
            message_id (str): The unique ID of the message.

        Returns:
            bool: True if the message was deleted, False otherwise.
        """
        result = mongo.db.messages.delete_one({"_id": ObjectId(message_id)})
        return result.deleted_count > 0
    
    @staticmethod
    def update_message(message_id, updated_data):
        result = mongo.db.messages.update_one(
            {"_id": ObjectId(message_id)}, {"$set": updated_data}
        )
        return result.modified_count > 0
