"""
models.py

This module defines the models for interacting with the Firestore database.
It replaces the MongoDB models with Firestore equivalents.
"""

from datetime import datetime
from firebase_admin import firestore

# Initialize Firestore client
db = firestore.client()


class UserModel:
    """
    Handles database operations related to users using Firestore.
    """

    @staticmethod
    def create_user(data):
        """
        Creates a new user in Firestore.

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

        # Add timestamp
        data["created_at"] = firestore.SERVER_TIMESTAMP
        
        # Create document reference and set data
        user_ref = db.collection('users').document()
        user_ref.set(data)
        return user_ref.id

    @staticmethod
    def get_user_by_email(email):
        """
        Retrieves a user by their email address.

        Args:
            email (str): The email of the user to find.

        Returns:
            dict: The user's details if found, otherwise None.
        """
        users_ref = db.collection('users')
        query = users_ref.where('email', '==', email).limit(1).stream()
        for doc in query:
            user_data = doc.to_dict()
            user_data['_id'] = doc.id
            return user_data
        return None

    @staticmethod
    def get_user_by_nsu_id(nsu_id):
        """
        Retrieves a user by their NSU ID.

        Args:
            nsu_id (str): The NSU ID of the user to find.

        Returns:
            dict: The user's details if found, otherwise None.
        """
        users_ref = db.collection('users')
        query = users_ref.where('nsu_id', '==', str(nsu_id)).limit(1).stream()
        for doc in query:
            user_data = doc.to_dict()
            user_data['_id'] = doc.id
            return user_data
        return None

    @staticmethod
    def get_user_by_firebase_uid(firebase_uid):
        """
        Retrieves a user by their Firebase UID.

        Args:
            firebase_uid (str): The Firebase UID of the user to find.

        Returns:
            dict: The user's details if found, otherwise None.
        """
        users_ref = db.collection('users')
        query = users_ref.where('firebase_uid', '==', firebase_uid).limit(1).stream()
        for doc in query:
            user_data = doc.to_dict()
            user_data['_id'] = doc.id
            return user_data
        return None

    @staticmethod
    def update_user(user_id, data):
        """
        Updates a user document in Firestore.

        Args:
            user_id (str): The document ID of the user.
            data (dict): The fields to update.

        Returns:
            bool: True if successful, False otherwise.
        """
        try:
            user_ref = db.collection('users').document(user_id)
            user_ref.update(data)
            return True
        except Exception:
            return False


class FoundItemModel:
    """
    Handles database operations related to found items using Firestore.
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
            "created_at": firestore.SERVER_TIMESTAMP
        }
        item_ref = db.collection('found_items').document()
        item_ref.set(data)
        return item_ref.id

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
        items_ref = db.collection('found_items')
        query = items_ref.order_by('created_at', direction=firestore.Query.DESCENDING)
        
        # Note: Firestore doesn't support skip efficiently, so we fetch skip+limit and slice
        if skip > 0:
            # Get skip items to determine offset
            offset_query = query.limit(skip).stream()
            last_doc = None
            for doc in offset_query:
                last_doc = doc
            if last_doc:
                query = query.start_after(last_doc)
        
        query = query.limit(limit)
        items = []
        for doc in query.stream():
            item_data = doc.to_dict()
            item_data['_id'] = doc.id
            # Convert Firestore Timestamp to datetime if needed
            if 'created_at' in item_data and hasattr(item_data['created_at'], 'timestamp'):
                item_data['created_at'] = item_data['created_at'].timestamp()
            items.append(item_data)
        return items


class LostItemModel:
    """
    Handles database operations related to lost items using Firestore.
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
            "created_at": firestore.SERVER_TIMESTAMP,
        }
        item_ref = db.collection('lost_items').document()
        item_ref.set(data)
        return item_ref.id

    @staticmethod
    def mark_item_as_found(item_id):
        """
        Marks a lost item as found and moves it to the found items collection.

        Args:
            item_id (str): The unique ID of the lost item.

        Returns:
            str: The ID of the marked item if successful, otherwise None.
        """
        item_ref = db.collection('lost_items').document(item_id)
        item_doc = item_ref.get()
        
        if not item_doc.exists:
            return None
        
        item_data = item_doc.to_dict()
        if item_data.get('is_found', False):
            return None  # Already found

        # Create found item
        found_item_data = {
            "description": item_data.get("description"),
            "location": item_data.get("location"),
            "image_path": item_data.get("image_path"),
            "reported_by": item_data.get("reported_by"),
            "found_at": firestore.SERVER_TIMESTAMP,
        }
        found_item_ref = db.collection('found_items').document()
        found_item_ref.set(found_item_data)

        # Delete from lost_items
        item_ref.delete()

        return item_id

    @staticmethod
    def get_lost_items(limit=10, skip=0):
        """
        Retrieves a list of lost items (approved and not found).

        Args:
            limit (int): The maximum number of items to retrieve.
            skip (int): The number of items to skip.

        Returns:
            list: A list of lost items with their details.
        """
        items_ref = db.collection('lost_items')
        query = items_ref.where('is_found', '==', False).where('is_approved', '==', True)
        query = query.order_by('created_at', direction=firestore.Query.DESCENDING)
        
        # Handle skip
        if skip > 0:
            offset_query = query.limit(skip).stream()
            last_doc = None
            for doc in offset_query:
                last_doc = doc
            if last_doc:
                query = query.start_after(last_doc)
        
        query = query.limit(limit)
        items = []
        for doc in query.stream():
            item_data = doc.to_dict()
            item_data['_id'] = doc.id
            if 'created_at' in item_data and hasattr(item_data['created_at'], 'timestamp'):
                item_data['created_at'] = item_data['created_at'].timestamp()
            items.append(item_data)
        return items

    @staticmethod
    def get_lost_items_admin(limit=10, skip=0):
        """
        Retrieves a list of lost items pending approval.

        Args:
            limit (int): The maximum number of items to retrieve.
            skip (int): The number of items to skip.

        Returns:
            list: A list of lost items with their details.
        """
        items_ref = db.collection('lost_items')
        query = items_ref.where('is_approved', '==', False)
        query = query.order_by('created_at', direction=firestore.Query.DESCENDING)
        
        # Handle skip
        if skip > 0:
            offset_query = query.limit(skip).stream()
            last_doc = None
            for doc in offset_query:
                last_doc = doc
            if last_doc:
                query = query.start_after(last_doc)
        
        query = query.limit(limit)
        items = []
        for doc in query.stream():
            item_data = doc.to_dict()
            item_data['_id'] = doc.id
            if 'created_at' in item_data and hasattr(item_data['created_at'], 'timestamp'):
                item_data['created_at'] = item_data['created_at'].timestamp()
            items.append(item_data)
        return items

    @staticmethod
    def get_recent_feed(limit=10):
        """
        Retrieves a feed of recent lost items (approved and not found).

        Args:
            limit (int): The maximum number of items to retrieve.

        Returns:
            list: A list of recent lost items.
        """
        return LostItemModel.get_lost_items(limit=limit, skip=0)

    @staticmethod
    def approve_item(item_id):
        """
        Approves a lost item.

        Args:
            item_id (str): The ID of the lost item to approve.

        Returns:
            bool: True if successful, False otherwise.
        """
        try:
            item_ref = db.collection('lost_items').document(item_id)
            item_doc = item_ref.get()
            if not item_doc.exists:
                return False
            item_ref.update({'is_approved': True})
            return True
        except Exception:
            return False


class MessageModel:
    """
    Handles database operations related to user messages using Firestore.
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
        # Ensure created_at is a Firestore timestamp if not already set
        if 'created_at' not in data:
            data['created_at'] = firestore.SERVER_TIMESTAMP
        elif isinstance(data.get('created_at'), str):
            # Convert string datetime to Firestore timestamp if needed
            try:
                from datetime import datetime
                dt = datetime.fromisoformat(data['created_at'].replace('Z', '+00:00'))
                data['created_at'] = dt
            except:
                data['created_at'] = firestore.SERVER_TIMESTAMP

        message_ref = db.collection('messages').document()
        message_ref.set(data)
        return message_ref.id

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
        messages_ref = db.collection('messages')
        
        # Firestore doesn't support OR queries directly, so we need two queries
        query1 = messages_ref.where('author_id', '==', author_id).where('receiver_id', '==', receiver_id)
        query2 = messages_ref.where('author_id', '==', receiver_id).where('receiver_id', '==', author_id)
        
        # Combine results
        messages = []
        for query in [query1, query2]:
            q = query.order_by('created_at', direction=firestore.Query.DESCENDING)
            
            # Handle skip (simplified - might not be perfectly accurate for combined queries)
            if skip > 0:
                offset_query = q.limit(skip).stream()
                last_doc = None
                for doc in offset_query:
                    last_doc = doc
                if last_doc:
                    q = q.start_after(last_doc)
            
            q = q.limit(limit)
            for doc in q.stream():
                msg_data = doc.to_dict()
                msg_data['_id'] = doc.id
                if 'created_at' in msg_data and hasattr(msg_data['created_at'], 'timestamp'):
                    msg_data['created_at'] = msg_data['created_at'].timestamp()
                messages.append(msg_data)
        
        # Sort combined results by created_at descending and limit
        messages.sort(key=lambda x: x.get('created_at', 0), reverse=True)
        return messages[:limit]

    @staticmethod
    def get_message_by_id(message_id):
        """
        Retrieves a message by its ID.

        Args:
            message_id (str): The ID of the message.

        Returns:
            dict: The message data if found, None otherwise.
        """
        message_ref = db.collection('messages').document(message_id)
        message_doc = message_ref.get()
        if message_doc.exists:
            msg_data = message_doc.to_dict()
            msg_data['_id'] = message_doc.id
            return msg_data
        return None

    @staticmethod
    def delete_message(message_id):
        """
        Deletes a message by its ID.

        Args:
            message_id (str): The unique ID of the message.

        Returns:
            bool: True if the message was deleted, False otherwise.
        """
        try:
            message_ref = db.collection('messages').document(message_id)
            message_ref.delete()
            return True
        except Exception:
            return False

    @staticmethod
    def update_message(message_id, updated_data):
        """
        Updates a message by its ID.

        Args:
            message_id (str): The unique ID of the message.
            updated_data (dict): The fields to update.

        Returns:
            bool: True if the message was updated, False otherwise.
        """
        try:
            message_ref = db.collection('messages').document(message_id)
            message_ref.update(updated_data)
            return True
        except Exception:
            return False

    @staticmethod
    def get_chats_for_user(user_id):
        """
        Retrieves all chats for a user.

        Args:
            user_id (str): The user ID/email.

        Returns:
            list: A list of chats with latest message info.
        """
        messages_ref = db.collection('messages')
        
        # Get messages where user is author
        author_query = messages_ref.where('author_id', '==', user_id).order_by('created_at', direction=firestore.Query.DESCENDING).stream()
        
        # Get messages where user is receiver
        receiver_query = messages_ref.where('receiver_id', '==', user_id).order_by('created_at', direction=firestore.Query.DESCENDING).stream()
        
        # Build a dict of chat_id -> latest message
        chats_dict = {}
        
        for doc in author_query:
            msg_data = doc.to_dict()
            receiver_id = msg_data.get('receiver_id')
            if receiver_id:
                if receiver_id not in chats_dict:
                    chats_dict[receiver_id] = {
                        'chat_id': receiver_id,
                        'latest_message': msg_data.get('text', ''),
                        'latest_message_time': msg_data.get('created_at')
                    }
                elif chats_dict[receiver_id]['latest_message_time'] < msg_data.get('created_at'):
                    chats_dict[receiver_id] = {
                        'chat_id': receiver_id,
                        'latest_message': msg_data.get('text', ''),
                        'latest_message_time': msg_data.get('created_at')
                    }
        
        for doc in receiver_query:
            msg_data = doc.to_dict()
            author_id = msg_data.get('author_id')
            if author_id:
                if author_id not in chats_dict:
                    chats_dict[author_id] = {
                        'chat_id': author_id,
                        'latest_message': msg_data.get('text', ''),
                        'latest_message_time': msg_data.get('created_at')
                    }
                elif chats_dict[author_id]['latest_message_time'] < msg_data.get('created_at'):
                    chats_dict[author_id] = {
                        'chat_id': author_id,
                        'latest_message': msg_data.get('text', ''),
                        'latest_message_time': msg_data.get('created_at')
                    }
        
        # Convert to list and sort by latest_message_time
        chat_list = list(chats_dict.values())
        chat_list.sort(key=lambda x: x.get('latest_message_time', datetime.min), reverse=True)
        
        # Convert Firestore timestamps to timestamps for JSON serialization
        for chat in chat_list:
            if hasattr(chat.get('latest_message_time'), 'timestamp'):
                chat['latest_message_time'] = chat['latest_message_time'].timestamp()
        
        return chat_list
