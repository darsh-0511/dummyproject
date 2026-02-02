from fastapi.testclient import TestClient
from main import app

client = TestClient(app)

# API TESTING — Endpoint availability
def test_get_seats_api():
    response = client.get("/seats")
    assert response.status_code == 200
    assert len(response.json()) == 100


# FUNCTIONAL TESTING — Business rule
def test_successful_seat_booking():
    payload = {
        "seat_id": 1,
        "w3_id": "test.user@ibm.com",
        "name": "Test User",
        "date": "Today",
        "time_slot": "12:00 PM"
    }

    response = client.post("/book", json=payload)
    assert response.status_code == 200
    assert "Blu Dollars" in response.json()["message"]

#NEGATIVE TESTING — Double booking
def test_double_booking_not_allowed():
    payload = {
        "seat_id": 2,
        "w3_id": "user2@ibm.com",
        "name": "User Two",
        "date": "Today",
        "time_slot": "12:30 PM"
    }

    response1 = client.post("/book", json=payload)
    assert response1.status_code == 200

    response2 = client.post("/book", json=payload)
    assert response2.status_code == 400
    assert response2.json()["detail"] == "Seat taken"


# VALIDATION TESTING — Missing fields
def test_booking_missing_fields():
    payload = {
        "seat_id": 3,
        "w3_id": "invalid@ibm.com"
    }

    response = client.post("/book", json=payload)
    assert response.status_code == 422


#BOUNDARY TESTING — Invalid seat ID
def test_invalid_seat_id():
    payload = {
        "seat_id": 999,
        "w3_id": "ghost@ibm.com",
        "name": "Ghost",
        "date": "Tomorrow",
        "time_slot": "1:00 PM"
    }

    response = client.post("/book", json=payload)
    assert response.status_code == 404



#STATE TRANSITION TESTING — Release seat
def test_release_seat():
    payload = {
        "seat_id": 10,
        "w3_id": "release@ibm.com",
        "name": "Release User",
        "date": "Today",
        "time_slot": "2:00 PM"
    }

    client.post("/book", json=payload)

    response = client.post("/release/10")
    assert response.status_code == 200
    assert response.json()["seat"]["status"] == "available"
