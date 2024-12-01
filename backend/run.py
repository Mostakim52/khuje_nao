from app import create_app

# Create an instance of the Flask application
app = create_app()
"""
Creates and configures the Flask application.

The `create_app` function initializes the application by setting up configuration, 
registering blueprints, and setting up necessary extensions.
"""

if __name__ == "__main__":
    # Run the Flask application in debug mode
    app.run(debug=True)
    """
    Starts the Flask application server.

    This block ensures that the application runs only when the script is executed directly.
    The `debug=True` argument enables Flask's debug mode for development purposes, 
    providing detailed error messages and live reloading.
    """
