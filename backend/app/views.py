from flask import Blueprint, request, jsonify
from .models import UserModel, LostItemModel, MessageModel, FoundItemModel
from .utils import hash_password, check_password, is_valid_phone_number, is_valid_nsu_id
from .storage import upload_image_to_storage
import os
from werkzeug.utils import secure_filename

main_bp = Blueprint("main", __name__)

ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg'}

def allowed_file(filename):
    """
    Checks if the file extension is allowed.
    
    @param filename: The name of the file to check.
    @return: True if the file extension is allowed, otherwise False.
    """
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

@main_bp.route("/users", methods=["POST"])
def create_user():
    """
    Endpoint to create a new user.
    
    This endpoint expects a JSON body with `username`, `email`, and `password`. 
    It checks if the user already exists by email. If not, it hashes the password 
    and creates the user in the database.

    @return: JSON response with success message or error.
    """
    data = request.get_json()
    if not data or "username" not in data or "email" not in data or "password" not in data:
        return jsonify({"error": "Invalid data"}), 400

    if UserModel.get_user_by_email(data["email"]):
        return jsonify({"error": "User already exists"}), 400

    # Password hashing
    data["password"] = hash_password(data["password"])
    user_id = UserModel.create_user({"username": data["username"], "email": data["email"], "password": data["password"]})
    return jsonify({"message": "User created successfully", "id": user_id}), 201

@main_bp.route("/login", methods=["POST"])
def login():
    """
    Endpoint for user login.

    This endpoint expects a JSON body with `email` and `password`. It checks if the user exists 
    and if the provided password matches. If successful, it returns a success message.

    @return: JSON response with login success message or error.
    """
    data = request.get_json()
    user = UserModel.get_user_by_email(data["email"])
    if not user or not check_password(data["password"], user["password"]):
        return jsonify({"error": "Invalid email or password"}), 400

    return jsonify({"message": "Login successful", "email": str(user["email"])}), 200

@main_bp.route("/signup", methods=["POST"])
def signup():
    """
    Endpoint to sign up a new user.

    This endpoint expects a JSON body with `name`, `email`, `phone_number`, `password`, and `nsu_id`.
    It validates the input and checks for the existence of the email and NSU ID. If valid, it hashes
    the password and creates the user.

    @return: JSON response with success message or error.
    """
    data = request.get_json()

    # Validate input
    required_fields = ["name", "email", "phone_number", "password", "nsu_id"]
    if not all(field in data and data[field] for field in required_fields):
        return jsonify({"error": "Missing required fields"}), 400

    if not is_valid_phone_number(data["phone_number"]):
        return jsonify({"error": "Invalid phone number"}), 400

    if not is_valid_nsu_id(data["nsu_id"]):
        return jsonify({"error": "Invalid NSU ID"}), 400

    if UserModel.get_user_by_email(data["email"]):
        return jsonify({"error": "Email already exists"}), 400

    if UserModel.get_user_by_nsu_id(data["nsu_id"]):
        return jsonify({"error": "NSU ID already exists"}), 400

    data["password"] = hash_password(data["password"])

    user_id = UserModel.create_user(data)
    return jsonify({"message": "User created successfully", "id": user_id}), 201

# Removed local filesystem upload endpoint - images are now served directly from AppWrite Storage URLs

@main_bp.route('/lost-items', methods=['POST'])
def report_lost_item():
    """
    Endpoint to report a lost item.

    This endpoint accepts form data to report a lost item. It handles image uploads, 
    validates required fields, and saves the lost item in the database.

    @return: JSON response with success message or error.
    """
    image_url = None
    # Handling image upload to AppWrite Storage
    if 'image' in request.files:
        file = request.files['image']

        if file.filename == '':
            return jsonify({"error": "No selected file"}), 400

        if file and allowed_file(file.filename):
            try:
                filename = secure_filename(file.filename)
                # Read file data
                file_data = file.read()
                # Upload to AppWrite Storage
                image_url = upload_image_to_storage(file_data, filename, folder='lost-items')
            except Exception as e:
                return jsonify({"error": f"Failed to upload image: {str(e)}"}), 500
        else:
            return jsonify({"error": "Invalid file type"}), 400

    # Parse form data after file handling
    data = request.form

    description = data.get("description")
    location = data.get("location")
    reported_by = data.get("reported_by")

    # Validation for required fields
    if not description or not location or not reported_by:
        return jsonify({"error": "Missing required fields"}), 400

    # Report lost item in the database
    lost_item_id = LostItemModel.report_lost_item(
        description=description,
        location=location,
        image_path=image_url,  # Store AppWrite Storage URL
        reported_by=reported_by,
    )
    return jsonify({"message": "Lost item reported successfully", "id": lost_item_id}), 201

@main_bp.route('/lost-items', methods=['GET'])
def get_lost_items():
    """
    Endpoint to retrieve lost items.

    This endpoint returns a paginated list of lost items. It includes optional `limit` and `skip` 
    query parameters for pagination. If an item has an image, the image URL is also included.

    @return: JSON response with list of lost items.
    """
    limit = int(request.args.get("limit", 10))
    skip = int(request.args.get("skip", 0))

    items = LostItemModel.get_lost_items(limit=limit, skip=skip)

    # Image URLs are already stored in image_path field (Firebase Storage URLs)
    for item in items:
        if "image_path" in item and item["image_path"]:
            item["image"] = item["image_path"]  # Use Firebase Storage URL directly
        else:
            item["image"] = None
    
    return jsonify(items), 200

@main_bp.route('/found-items', methods=['POST'])
def report_found_item():
    """
    Endpoint to report a found item.

    This endpoint accepts a JSON body with the description, location, and image path of the found item.
    It saves the found item in the database.

    @return: JSON response with success message or error.
    """
    data = request.get_json()
    
    # Validate required fields
    if not data.get("description") or not data.get("location") or not data.get("image_path"):
        return jsonify({"error": "Missing required fields"}), 400

    # Call the model to save the found item
    found_item_id = FoundItemModel.report_found_item(
        description=data["description"],
        location=data["location"],
        image_path=data["image_path"]
    )

    return jsonify({"message": "Found item reported successfully", "id": found_item_id}), 201

@main_bp.route('/lost-items/<item_id>/found', methods=['POST'])
def mark_item_as_found(item_id):
    """
    Endpoint to mark a lost item as found.

    This endpoint moves the item from the `lost_items` collection to the `found_items` collection.

    @param item_id: The ID of the lost item to mark as found.
    @return: JSON response with success message or error.
    """
    # Mark the item as found and move it to the found_items collection
    result = LostItemModel.mark_item_as_found(item_id)
    if not result:
        return jsonify({"error": "Lost item not found or already marked as found"}), 404

    return jsonify({"message": "Item marked as found and moved to found items", "id": result}), 200

@main_bp.route('/found-items', methods=['GET'])
def get_found_items():
    """
    Endpoint to retrieve found items.

    This endpoint returns a paginated list of found items. It includes optional `limit` and `skip` 
    query parameters for pagination. If an item has an image, the image URL is also included.

    @return: JSON response with list of found items.
    """
    limit = int(request.args.get("limit", 100))
    skip = int(request.args.get("skip", 0))
    
    items = FoundItemModel.get_found_items(limit=limit, skip=skip)

    # Image URLs are already stored in image_path field (Firebase Storage URLs)
    for item in items:
        if "image_path" in item and item["image_path"]:
            item["image"] = item["image_path"]  # Use Firebase Storage URL directly
        else:
            item["image"] = None
            
    return jsonify(items), 200

@main_bp.route("/activity-feed", methods=["GET"])
def activity_feed():
    """
    Endpoint to retrieve a feed of recent lost items.

    This endpoint returns a paginated list of recent lost items. It includes an optional `limit` 
    query parameter for pagination.

    @return: JSON response with activity feed.
    """
    limit = int(request.args.get("limit", 10))
    feed = LostItemModel.get_recent_feed(limit=limit)
    return jsonify(feed), 200





## Messaging and chat endpoints

@main_bp.route('/send_message', methods=['POST'])
def send_message():
    """
    Endpoint to send a message.
    
    This endpoint expects a JSON body with `text`, `author_id`, and `created_at`. 
    It validates the input and stores the message in the database.

    @return: JSON response with the `message_id` of the created message.
    """
    data = request.json
    if not data.get("text") or not data.get("author_id") or not data.get("created_at"):
        return jsonify({"error": "Missing required fields"}), 400

    message_id = MessageModel.send_message(data)
    return jsonify({"message_id": message_id}), 201

@main_bp.route('/get_messages', methods=['POST'])
def get_messages():
    """
    Endpoint to retrieve messages between two users.

    This endpoint expects a JSON body with `author_id` and `receiver_id`. 
    It returns a paginated list of messages with optional `limit` and `skip` query parameters.

    @return: JSON response with the list of messages.
    """
    data = request.json
    author_id = data.get("author_id")
    receiver_id = data.get("receiver_id")
    limit = int(request.args.get("limit", 50))
    skip = int(request.args.get("skip", 0))

    messages = MessageModel.get_messages(author_id, receiver_id, limit=limit, skip=skip)
    
    # Convert _id to string if it exists (Firestore already returns string IDs)
    for message in messages:
        if "_id" in message:
            message["_id"] = str(message["_id"])

    return jsonify(messages), 200

@main_bp.route('/get_chats', methods=['POST'])
def get_chats():
    """
    Endpoint to retrieve all chats for a user.

    This endpoint expects a JSON body with `user_id`, representing the current user. 
    It returns a list of chats where the user is either the author or receiver of messages.

    @return: JSON response with the list of chats.
    """
    data = request.json
    user_id = data.get("user_id")  # Current user ID/email

    if not user_id:
        return jsonify({"error": "user_id is required"}), 400

    # Use MessageModel method to get chats
    chat_list = MessageModel.get_chats_for_user(user_id)

    return jsonify(chat_list), 200

@main_bp.route('/search-lost-items', methods=['GET'])
def search_lost_items():
    """
    Endpoint to search for lost items.

    This endpoint performs a text search on the `description` field of lost items and returns 
    the matching items. It accepts a `query` parameter.

    @return: JSON response with the list of lost items that match the search query.
    """
    query = request.args.get('query', '')
    if not query:
        return jsonify({"error": "No search query provided"}), 400

    # Firestore doesn't support full-text search natively, so we do a simple contains check
    # For production, consider using Algolia or similar for full-text search
    from firebase_admin import firestore
    db = firestore.client()
    items_ref = db.collection('lost_items')
    
    # Query for approved and not found items where description contains query (case-insensitive)
    # Note: Firestore doesn't support case-insensitive contains, so we'll filter in Python
    query_result = items_ref.where('is_approved', '==', True).where('is_found', '==', False).limit(100).stream()

    result = []
    query_lower = query.lower()
    for doc in query_result:
        item = doc.to_dict()
        description = item.get("description", "").lower()
        if query_lower in description:
            result.append({
                "_id": doc.id,
                "description": item.get("description"),
                "location": item.get("location"),
                "image": item.get("image_path") if item.get("image_path") else None,  # Use AppWrite Storage URL directly
                "reported_by": item.get("reported_by")
            })
            if len(result) >= 20:
                break

    return jsonify(result), 200

## Removed email OTP and SendGrid email features



from firebase_admin import firestore

@main_bp.route('/lost-items/<item_id>/approve', methods=['POST'])
def approve_item(item_id):
    """
    Endpoint to approve a lost item.

    This endpoint accepts an `item_id` and updates the item to mark it as approved.

    @param item_id: The ID of the lost item to approve.

    @return: JSON response indicating the result of the approval operation.
    """
    try:
        # Use LostItemModel method to approve item
        success = LostItemModel.approve_item(item_id)
        if success:
            return jsonify({"message": "Item approved successfully"}), 200
        else:
            return jsonify({"error": "Lost item not found or already approved"}), 404
    except Exception as e:
        # Handle any exceptions that occur during the process
        return jsonify({"error": f"Error: {str(e)}"}), 500
    
@main_bp.route('/lost-items-admin', methods=['GET'])
def get_lost_items_admin():
    """
    Endpoint to retrieve a list of lost items for the admin.

    This endpoint returns a paginated list of lost items, with optional `limit` and `skip` query parameters.

    @return: JSON response with the list of lost items for the admin.
    """
    limit = int(request.args.get("limit", 10))
    skip = int(request.args.get("skip", 0))

    items = LostItemModel.get_lost_items_admin(limit=limit, skip=skip)

    # Image URLs are already stored in image_path field (Firebase Storage URLs)
    for item in items:
        if "image_path" in item and item["image_path"]:
            item["image"] = item["image_path"]  # Use Firebase Storage URL directly
        else:
            item["image"] = None

    return jsonify(items), 200
