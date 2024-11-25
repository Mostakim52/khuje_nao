from flask import Blueprint, request, jsonify
from .models import UserModel, LostItemModel, MessageModel, FoundItemModel
from .utils import hash_password, check_password, is_valid_phone_number, is_valid_nsu_id

main_bp = Blueprint("main", __name__)

@main_bp.route("/users", methods=["POST"])
def create_user():
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
    data = request.get_json()
    user = UserModel.get_user_by_email(data["email"])
    if not user or not check_password(data["password"], user["password"]):
        return jsonify({"error": "Invalid email or password"}), 400

    return jsonify({"message": "Login successful", "email": str(user["email"])}), 200

@main_bp.route("/signup", methods=["POST"])
def signup():
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

@main_bp.route("/lost-items", methods=["POST"])
def report_lost_item():
    data = request.get_json()
    if not data or "name" not in data or "description" not in data or "location" not in data:
        return jsonify({"error": "Invalid data"}), 400

    item_id = LostItemModel.report_lost_item({
        "name": data["name"],
        "description": data["description"],
        "location": data["location"],
        "is_found": data.get("is_found", False),
    })
    return jsonify({"message": "Lost item reported successfully", "id": item_id}), 201

@main_bp.route("/lost-items", methods=["GET"])
def get_lost_items():
    page = int(request.args.get("page", 1))
    per_page = int(request.args.get("per_page", 10))
    skip = (page - 1) * per_page

    items = LostItemModel.get_lost_items(query={}, limit=per_page, skip=skip)
    return jsonify(items), 200

@main_bp.route('/found-items', methods=['POST'])
def report_found_item():
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


@main_bp.route("/activity-feed", methods=["GET"])
def activity_feed():
    limit = int(request.args.get("limit", 10))
    feed = LostItemModel.get_recent_feed(limit=limit)
    return jsonify(feed), 200

##Added by Mostakim
@main_bp.route('/send_message', methods=['POST'])
def send_message():
    data = request.json
    if not data.get("text") or not data.get("author_id") or not data.get("created_at"):
        return jsonify({"error": "Missing required fields"}), 400

    message_id = MessageModel.send_message(data)
    return jsonify({"message_id": message_id}), 201

@main_bp.route('/get_messages', methods=['POST'])
def get_messages():
    data = request.json
    limit = int(request.args.get("limit", 50))
    skip = int(request.args.get("skip", 0))
    messages = MessageModel.get_messages(data.get("author_id"), data.get("receiver_id"), limit=limit, skip=skip)
    return jsonify(messages), 200
