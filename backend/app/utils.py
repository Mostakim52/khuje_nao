import bcrypt
import re

def validate_input(data, required_fields):
    return all(field in data and data[field] for field in required_fields)

def hash_password(password):
    return bcrypt.hashpw(password.encode("utf-8"), bcrypt.gensalt()).decode("utf-8")

def check_password(password, hashed_password):
    return bcrypt.checkpw(password.encode("utf-8"), hashed_password.encode("utf-8"))

def is_valid_phone_number(phone_number):
    return re.fullmatch(r"01\d{9}", phone_number) is not None

def is_valid_nsu_id(nsu_id):
    return re.fullmatch(r"\d{7}", nsu_id) is not None

def allowed_file(filename):
    ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'gif'}
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS