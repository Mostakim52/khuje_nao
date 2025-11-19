from flask import Blueprint, request, jsonify, current_app, url_for, send_from_directory
from .models import UserModel, LostItemModel, MessageModel, FoundItemModel
from .utils import hash_password, check_password, is_valid_phone_number, is_valid_nsu_id
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

@main_bp.route('/uploads/<filename>', endpoint='uploaded_file')
def uploaded_file(filename):
    """
    Endpoint to serve uploaded files.

    This endpoint returns the file from the upload directory.

    @param filename: The name of the file to retrieve.
    @return: The requested file.
    """
    return send_from_directory(current_app.config['UPLOAD_FOLDER'], filename)

@main_bp.route('/lost-items', methods=['POST'])
def report_lost_item():
    """
    Endpoint to report a lost item.

    This endpoint accepts form data to report a lost item. It handles image uploads, 
    validates required fields, and saves the lost item in the database.

    @return: JSON response with success message or error.
    """
    image_path = None
    # Handling image upload
    if 'image' in request.files:
        file = request.files['image']

        if file.filename == '':
            return jsonify({"error": "No selected file"}), 400

        if file and allowed_file(file.filename):
            filename = secure_filename(file.filename)
            upload_folder = current_app.config['UPLOAD_FOLDER']
            if not os.path.exists(upload_folder):
                os.makedirs(upload_folder)
            file.save(os.path.join(upload_folder, filename))
            image_path = f"uploads/{filename}"
            print(f"Image saved at: {os.path.join(upload_folder, filename)}")
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
        image_path=image_path,  # Use the uploaded image path
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

    for item in items:
        if "image_path" in item and item["image_path"]:
            item["image"] = url_for('main.uploaded_file', filename=item["image_path"].split('/')[-1], _external=True)
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

    for item in items:
        if "image_path" in item and item["image_path"]:
            item["image"] = url_for('main.uploaded_file', filename=item["image_path"].split('/')[-1], _external=True)
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
    
    # Convert ObjectId to string for JSON serialization
    for message in messages:
        message["_id"] = str(message["_id"])

    return jsonify(messages), 200

from . import mongo

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

    # Find all chats where the current user is either the author or the receiver
    chats = mongo.db.messages.aggregate([
        {"$match": {"$or": [{"author_id": user_id}, {"receiver_id": user_id}]}},
        {"$group": {
            "_id": {"$cond": [{"$eq": ["$author_id", user_id]}, "$receiver_id", "$author_id"]},
            "latest_message": {"$last": "$$ROOT"}  # Get the latest message for each chat
        }},
        {"$project": {
            "chat_id": "$_id",
            "latest_message": 1
        }}
    ])

    chat_list = []
    for chat in chats:
        chat_list.append({
            "chat_id": chat["chat_id"],
            "latest_message": chat["latest_message"]["text"],
            "latest_message_time": chat["latest_message"]["created_at"],
        })

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

    # Perform MongoDB text search on the 'description' and 'name' fields
    items = mongo.db.lost_items.find(
        {"description": query}  # MongoDB text search
    ).limit(20)

    result = []
    for item in items:
        result.append({
            "_id": str(item["_id"]),
            "description": item.get("description"),
            "location": item.get("location"),
            "image": url_for('main.uploaded_file', filename=item["image_path"].split('/')[-1], _external=True),  # Return the image path
            "reported_by": item.get("reported_by")
        })

    return jsonify(result), 200

## Removed email OTP and SendGrid email features



from bson import ObjectId
@main_bp.route('/lost-items/<item_id>/approve', methods=['POST'])
def approve_item(item_id):
    """
    Endpoint to approve a lost item.

    This endpoint accepts an `item_id` and updates the item to mark it as approved.

    @param item_id: The ID of the lost item to approve.

    @return: JSON response indicating the result of the approval operation.
    """
    try:
        # Find the lost item by ID
        lost_item = mongo.db.lost_items.find_one({"_id": ObjectId(item_id)})

        if not lost_item:
            return jsonify({"error": "Lost item not found"}), 404

        # Update the item to mark it as approved
        result = mongo.db.lost_items.update_one(
            {"_id": ObjectId(item_id)},
            {"$set": {"is_approved": True}}
        )

        # Check if update was successful
        if result.modified_count > 0:
            return jsonify({"message": "Item approved successfully"}), 200
        else:
            return jsonify({"error": "Failed to approve item"}), 500

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

    for item in items:
        if "image_path" in item and item["image_path"]:
            item["image"] = url_for('main.uploaded_file', filename=item["image_path"].split('/')[-1], _external=True)
        else:
            item["image"] = None

    return jsonify(items), 200
