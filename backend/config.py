import os
from dotenv import load_dotenv

# Load variables from a .env file (only needed for local development)
load_dotenv()

class Config:
    """
    Configuration class for the application.

    This class contains the necessary configurations for the app, such as the secret key and MongoDB URI.

    Attributes:
        SECRET_KEY (str): Secret key used for securing sessions and cookies.
        MONGO_URI (str): URI for connecting to the MongoDB database.
    """

    SECRET_KEY = os.getenv("SECRET_KEY", "mysecretkey")
    """
    Secret key used for securing sessions and cookies.
    This key should be kept confidential to ensure the security of user sessions.
    """

    # Prefer cloud connection string; allow MONGO_URI alias; fallback to local MongoDB
    MONGO_URI = (
        os.getenv("MONGO_ONLINE_URL")
        or os.getenv("MONGO_URI")
        or "mongodb://localhost:27017/khuje_nao"
    )
    """
    URI for connecting to the MongoDB database.

    Tries to read MONGO_ONLINE_URL from environment variables first (ideal for production).
    Falls back to localhost MongoDB for local development if not set.
    """
