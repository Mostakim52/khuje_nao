import os

class Config:
    """
    Configuration class for the application.

    This class contains the necessary configurations for the app, such as the secret key and MongoDB URI.

    Attributes:
        SECRET_KEY (str): Secret key used for securing sessions and cookies.
        MONGO_URI (str): URI for connecting to the MongoDB database.
    """
    SECRET_KEY = "mysecretkey"
    """
    Secret key used for securing sessions and cookies.
    
    This key should be kept confidential to ensure the security of user sessions.
    """
    
    MONGO_URI = os.getenv("MONGO_ONLINE_URL")
    """
    URI for connecting to the MongoDB database.

    This URI defines the location and database name for the app's MongoDB instance. 
    It uses the default MongoDB port 27017 and connects to the `khuje_nao` database.
    """
