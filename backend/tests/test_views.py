import pytest
from werkzeug.datastructures import FileStorage
import io
from app import create_app
from flask_pymongo import PyMongo

@pytest.fixture
def client():
    app = create_app()
    app.config['TESTING'] = True
    app.config['MONGO_URI'] = "mongodb://localhost:27017/test_khuje_nao"
    with app.test_client() as client:
        with app.app_context():
            mongo = PyMongo(app)
            # Clear test database
            mongo.db.users.drop()
            mongo.db.lost_items.drop()
        yield client

def test_report_lost_item(client):
    # Prepare the test data
    data = {
        "description": "Lost phone",
        "location": "Library",
        "reported_by": "test_user_id"
    }
    file = FileStorage(
        stream=io.BytesIO(b"fake image content"),
        filename="test.jpg",
        content_type="image/jpeg",
    )

    # Send a POST request with form data and an image
    response = client.post(
        '/lost-items',
        data={**data, 'image': file},
        content_type='multipart/form-data'
    )

    # Validate the response
    assert response.status_code == 201, f"Expected 201, got {response.status_code}"
    json_data = response.get_json()
    assert json_data["message"] == "Lost item reported successfully"
    assert "id" in json_data, "Lost item ID not returned in response"
