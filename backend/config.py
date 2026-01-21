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

    # Firebase configuration
    GOOGLE_APPLICATION_CREDENTIALS = os.getenv("GOOGLE_APPLICATION_CREDENTIALS")
    """
    Path to Firebase service account credentials JSON file.
    Required for Firebase Admin SDK to access Firestore.
    """
    
    # AppWrite Storage configuration
    APPWRITE_ENDPOINT = os.getenv("APPWRITE_ENDPOINT", "")
    """
    AppWrite server endpoint URL.
    Example: https://cloud.appwrite.io/v1 (for cloud) or http://localhost/v1 (for self-hosted)
    """
    
    APPWRITE_PROJECT_ID = os.getenv("APPWRITE_PROJECT_ID", "")
    """
    AppWrite project ID.
    Found in AppWrite Console → Settings → General.
    """
    
    APPWRITE_API_KEY = os.getenv("APPWRITE_API_KEY", "")
    """
    AppWrite API Key (Server/Admin key).
    Found in AppWrite Console → Settings → API Keys.
    Use a key with 'files.write' permission.
    """
    
    APPWRITE_STORAGE_BUCKET_ID = os.getenv("APPWRITE_STORAGE_BUCKET_ID", "")
    """
    AppWrite Storage Bucket ID.
    Create a bucket in AppWrite Console → Storage and use its ID.
    """
