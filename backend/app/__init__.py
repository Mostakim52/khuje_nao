"""
__init__.py

This module initializes the Flask application, configures the app settings, 
and sets up integrations like MongoDB and CORS.
"""

import os
import logging
from flask import Flask
from flask_pymongo import PyMongo
from flask_cors import CORS
from config import Config

# Initialize PyMongo
mongo = PyMongo()

# Get the base directory of the application
basedir = os.path.abspath(os.path.dirname(__file__))


def create_app():
    """
    Creates and configures the Flask application.

    The application is configured with:
        - Flask-PyMongo for MongoDB integration.
        - Flask-CORS for Cross-Origin Resource Sharing.
        - Logging for debugging and monitoring.

    Returns:
        Flask: The initialized Flask application instance.
    """
    # Create the Flask app instance
    app = Flask(__name__, static_url_path='', static_folder='static')

    # Load configuration from the Config object
    app.config.from_object(Config)

    # Set the upload folder for file uploads
    app.config['UPLOAD_FOLDER'] = os.path.join(os.getcwd(), 'static', 'uploads')

    # Define allowed file extensions for uploads
    app.config['ALLOWED_EXTENSIONS'] = {'png', 'jpg', 'jpeg'}

    # Initialize PyMongo with the app configuration
    mongo.init_app(app)

    # Enable Cross-Origin Resource Sharing (CORS)
    CORS(app)

    # Configure logging
    logging.basicConfig(level=logging.INFO)
    logger = logging.getLogger(__name__)
    logger.info("Server is starting...")

    # Import and register the main blueprint for views
    from .views import main_bp
    app.register_blueprint(main_bp)

    return app
