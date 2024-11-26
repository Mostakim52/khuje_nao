from flask import Flask
from flask_pymongo import PyMongo
from flask_cors import CORS
import logging
from config import Config

# Initialize PyMongo
mongo = PyMongo()

def create_app():
    app = Flask(__name__)
    app.config.from_object(Config)  # Load configuration
    app.config['UPLOAD_FOLDER'] = 'uploads/'
    app.config['ALLOWED_EXTENSIONS'] = {'png', 'jpg', 'jpeg'}

    # Initialize PyMongo with the app configuration
    mongo.init_app(app)

    # Enable Cross-Origin Resource Sharing (CORS)
    CORS(app)

    # Configure logging
    logging.basicConfig(level=logging.INFO)
    logger = logging.getLogger(__name__)
    logger.info("Server is starting...")

    from .views import main_bp  # Import views only after app initialization
    app.register_blueprint(main_bp)

    return app
