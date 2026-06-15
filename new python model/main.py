import base64
import binascii
import os

import cv2
import numpy as np
from flask import Flask, jsonify, request

import HandTrackingModule as htm


app = Flask(__name__)
detector = htm.handDetector(maxHands=1, detectionCon=0.7, trackCon=0.7)


@app.route("/", methods=["GET"])
def home():
    return jsonify({
        "success": True,
        "message": "ASL Detection API is running"
    })


@app.route("/upload", methods=["POST"])
def upload():
    data = request.get_json(silent=True) or {}
    image_data = data.get("image")

    if not image_data:
        return jsonify({
            "success": False,
            "letter": None,
            "message": "No image data received"
        }), 400

    img = decode_base64_image(image_data)

    if img is None:
        return jsonify({
            "success": False,
            "letter": None,
            "message": "Invalid base64 image data"
        }), 400

    try:
        detector.findHands(img, draw=False)
        posList = detector.findPosition(img, draw=False)
    except Exception:
        posList = []

    if len(posList) < 21:
        return jsonify({
            "success": False,
            "letter": None,
            "message": "No hand detected or insufficient landmarks"
        }), 200

    letter = recognize_gesture(posList)

    if letter:
        return jsonify({
            "success": True,
            "letter": letter,
            "message": "Gesture recognized successfully"
        }), 200

    return jsonify({
        "success": False,
        "letter": None,
        "message": "Gesture not recognized"
    }), 200


def decode_base64_image(image_data):
    if not isinstance(image_data, str):
        return None

    if "," in image_data and image_data.lower().startswith("data:image"):
        image_data = image_data.split(",", 1)[1]

    image_data = "".join(image_data.split())

    try:
        img_bytes = base64.b64decode(image_data, validate=True)
        np_arr = np.frombuffer(img_bytes, np.uint8)
        return cv2.imdecode(np_arr, cv2.IMREAD_COLOR)
    except (binascii.Error, ValueError, cv2.error):
        return None


def recognize_gesture(posList):
    try:
        if len(posList) < 21:
            return None

        fingers = []
        finger_tip = [8, 12, 16, 20]
        finger_dip = [6, 10, 14, 18]
        finger_pip = [7, 11, 15, 19]

        for idx in range(4):
            tip = posList[finger_tip[idx]]
            dip = posList[finger_dip[idx]]
            pip = posList[finger_pip[idx]]

            if tip[1] + 25 < dip[1] and posList[16][2] < posList[20][2]:
                fingers.append(0.25)
            elif tip[2] > dip[2]:
                fingers.append(0)
            elif tip[2] < pip[2]:
                fingers.append(1)
            elif tip[1] > pip[1] and tip[1] > dip[1]:
                fingers.append(0.5)
            else:
                fingers.append(None)

        if len(fingers) != 4 or None in fingers:
            return None

        if (posList[3][2] > posList[4][2]) and (posList[3][1] > posList[6][1]) and (posList[4][2] < posList[6][2]) and fingers.count(0) == 4:
            return "A"
        if (posList[3][1] > posList[4][1]) and fingers.count(1) == 4:
            return "B"
        if (posList[3][1] > posList[6][1]) and fingers.count(0.5) >= 1 and (posList[4][2] > posList[8][2]):
            return "C"
        if fingers[0] == 1 and fingers.count(0) == 3 and (posList[3][1] > posList[4][1]):
            return "D"
        if (posList[3][1] < posList[6][1]) and fingers.count(0) == 4 and posList[12][2] < posList[4][2]:
            return "E"
        if fingers.count(1) == 3 and fingers[0] == 0 and (posList[3][2] > posList[4][2]):
            return "F"
        if fingers[0] == 0.25 and fingers.count(0) == 3:
            return "G"
        if fingers[0] == 0.25 and fingers[1] == 0.25 and fingers.count(0) == 2:
            return "H"
        if (posList[4][1] < posList[6][1]) and fingers.count(0) == 3 and fingers[3] == 1:
            return "I"
        if (posList[4][1] < posList[6][1] and posList[4][1] > posList[10][1] and fingers.count(1) == 2):
            return "K"
        if fingers[0] == 1 and fingers.count(0) == 3 and (posList[3][1] < posList[4][1]):
            return "L"
        if (posList[4][1] < posList[16][1]) and fingers.count(0) == 4:
            return "M"
        if (posList[4][1] < posList[12][1]) and fingers.count(0) == 4:
            return "N"
        if (posList[4][1] > posList[12][1]) and posList[4][2] < posList[6][2] and fingers.count(0) == 4:
            return "T"
        if (posList[4][1] > posList[12][1]) and posList[4][2] < posList[12][2] and fingers.count(0) == 4:
            return "S"
        if (posList[4][2] < posList[8][2]) and (posList[4][2] < posList[12][2]) and (posList[4][2] < posList[16][2]) and (posList[4][2] < posList[20][2]):
            return "O"
        if fingers[2] == 0 and (posList[4][2] < posList[12][2]) and (posList[4][2] > posList[6][2]) and fingers[3] == 0:
            return "P"
        if fingers[1] == 0 and fingers[2] == 0 and fingers[3] == 0 and (posList[8][2] > posList[5][2]) and (posList[4][2] < posList[1][2]):
            return "Q"
        if (posList[8][1] < posList[12][1]) and (fingers.count(1) == 2) and (posList[9][1] > posList[4][1]):
            return "R"
        if (posList[4][1] < posList[6][1] and posList[4][1] < posList[10][1] and fingers.count(1) == 2 and posList[3][2] > posList[4][2] and (posList[8][1] - posList[11][1]) <= 50):
            return "U"
        if (posList[4][1] < posList[6][1] and posList[4][1] < posList[10][1] and fingers.count(1) == 2 and posList[3][2] > posList[4][2]):
            return "V"
        if (posList[4][1] < posList[6][1] and posList[4][1] < posList[10][1] and fingers.count(1) == 3):
            return "W"
        if fingers[0] == 0.5 and fingers.count(0) == 3 and posList[4][1] > posList[6][1]:
            return "X"
        if fingers.count(0) == 3 and (posList[3][1] < posList[4][1]) and fingers[3] == 1:
            return "Y"

        return None
    except Exception:
        return None


if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5000))
    app.run(host="0.0.0.0", port=port, debug=False)
