from flask import Blueprint, request, jsonify
from .models import UserModel, LostItemModel

main_bp = Blueprint("main", __name__)

@main_bp.route("/users", methods=["POST"])
def create_user():
    data = request.get_json()
    if not data or "username" not in data or "email" not in data:
        return jsonify({"error": "Invalid data"}), 400

    if UserModel.get_user_by_email(data["email"]):
        return jsonify({"error": "User already exists"}), 400

    user_id = UserModel.create_user({"username": data["username"], "email": data["email"]})
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

@main_bp.route("/activity-feed", methods=["GET"])
def activity_feed():
    limit = int(request.args.get("limit", 10))
    feed = LostItemModel.get_recent_feed(limit=limit)
    return jsonify(feed), 200
