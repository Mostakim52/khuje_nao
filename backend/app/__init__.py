from flask import Flask
from flask_pymongo import PyMongo
from flask_cors import CORS
import logging
from config import Config
import os

# Initialize PyMongo
mongo = PyMongo()

basedir = os.path.abspath(os.path.dirname(__file__))

def create_app():
    app = Flask(__name__, static_url_path='', static_folder='static')
    app.config.from_object(Config)  # Load configuration
    app.config['UPLOAD_FOLDER'] = os.path.join(os.getcwd(), 'static', 'uploads')
    app.config['ALLOWED_EXTENSIONS'] = {'png', 'jpg', 'jpeg'}

    if not os.path.exists(app.config['UPLOAD_FOLDER']):
        os.makedirs(app.config['UPLOAD_FOLDER'])

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
