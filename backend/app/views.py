from flask import Blueprint, request, jsonify, current_app
from .models import UserModel, LostItemModel, MessageModel, FoundItemModel
from .utils import hash_password, check_password, is_valid_phone_number, is_valid_nsu_id
import os
from werkzeug.utils import secure_filename

main_bp = Blueprint("main", __name__)

UPLOAD_FOLDER = 'uploads/'
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg'}

def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

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

@main_bp.route('/lost-items', methods=['POST'])
def report_lost_item():
    image_path = None

    # Handling image upload
    if 'image' in request.files:
        file = request.files['image']

        if file.filename == '':
            return jsonify({"error": "No selected file"}), 400

        if file and allowed_file(file.filename):
            filename = secure_filename(file.filename)
            image_path = os.path.join(current_app.config['UPLOAD_FOLDER'], filename)
            file.save(image_path)
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
    limit = int(request.args.get("limit", 10))
    skip = int(request.args.get("skip", 0))

    items = LostItemModel.get_lost_items(limit=limit, skip=skip)
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

@main_bp.route('/lost-items/<item_id>/found', methods=['POST'])
def mark_item_as_found(item_id):
    # Mark the item as found and move it to the found_items collection
    result = LostItemModel.mark_item_as_found(item_id)
    if not result:
        return jsonify({"error": "Lost item not found or already marked as found"}), 404

    return jsonify({"message": "Item marked as found and moved to found items", "id": result}), 200

@main_bp.route('/found-items', methods=['GET'])
def get_found_items():
    limit = int(request.args.get("limit", 100))
    skip = int(request.args.get("skip", 0))
    
    items = FoundItemModel.get_found_items(limit=limit, skip=skip)
    return jsonify(items), 200

@main_bp.route("/activity-feed", methods=["GET"])
def activity_feed():
    limit = int(request.args.get("limit", 10))
    feed = LostItemModel.get_recent_feed(limit=limit)
    return jsonify(feed), 200





##Added by Mostakim

import random
import time
import sendgrid
from dotenv import load_dotenv
from sendgrid.helpers.mail import Mail, Email, To, Content
import os
load_dotenv()
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

# SendGrid API Client
sg = sendgrid.SendGridAPIClient(api_key=os.getenv("SENDGRID_API_KEY"))  # Ensure the API key is set

# Temporary storage for OTP (Use a better storage like Redis or a database in production)
otp_storage = {}

# Generate OTP (6-digit)
def generate_otp():
    return random.randint(100000, 999999)

# Send OTP to user's email
def send_otp_email(to_email, otp):
    from_email = Email("smartfreelancehub@gmail.com")  # Your email
    to_email = To(to_email)  # Recipient's email
    subject = "Your OTP Code"
    content = Content("text/plain", f"Your OTP code is: {otp}")

    mail = Mail(from_email, to_email, subject, content)

    try:
        response = sg.send(mail)
        print(f"Email sent with status code {response.status_code}")
    except Exception as e:
        print(str(e))

# Route to send OTP to email
@main_bp.route('/send_otp', methods=['POST'])
def send_otp():
    data = request.json
    email = data.get('email')

    if not email:
        return jsonify({"error": "Email is required"}), 400

    otp = generate_otp()

    # Store OTP and expiration time (expires after 5 minutes)
    otp_storage[email] = {'otp': otp, 'timestamp': time.time()}

    # Send OTP to email
    send_otp_email(email, otp)

    return jsonify({"message": "OTP sent successfully to email"}), 200


# Route to verify OTP
@main_bp.route('/verify_otp', methods=['POST'])
def verify_otp():
    data = request.json
    email = data.get('email')
    otp = data.get('otp')

    if not email or not otp:
        return jsonify({"error": "Email and OTP are required"}), 400

    # Check if OTP exists for the given email
    if email not in otp_storage:
        return jsonify({"error": "No OTP sent for this email"}), 400

    stored_otp = otp_storage[email]['otp']
    timestamp = otp_storage[email]['timestamp']

    # Check if OTP has expired (5 minutes)
    if time.time() - timestamp > 300:
        del otp_storage[email]  # Remove expired OTP
        return jsonify({"error": "OTP has expired"}), 400

    # Check if the entered OTP is correct
    if int(otp) == stored_otp:
        del otp_storage[email]  # OTP successfully verified, remove it
        return jsonify({"message": "OTP verified successfully"}), 200
    else:
        return jsonify({"error": "Invalid OTP"}), 400