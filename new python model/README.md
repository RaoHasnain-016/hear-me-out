# ASL Detection API

Flask API for American Sign Language detection using MediaPipe hand landmarks, OpenCV image decoding, and custom gesture recognition logic.

## Files

- `main.py` - Flask app and API routes
- `HandTrackingModule.py` - MediaPipe Hands wrapper
- `requirements.txt` - Python dependencies
- `Dockerfile` - Render Docker deployment image
- `.dockerignore` - Docker build exclusions
- `.gitignore` - Git exclusions

## API Usage

### Health Check

```http
GET /
```

Response:

```json
{
  "success": true,
  "message": "ASL Detection API is running"
}
```

### Prediction

```http
POST /upload
Content-Type: application/json
```

Request body:

```json
{
  "image": "BASE64_IMAGE_STRING"
}
```

The `image` value may be a plain base64 string or a data URL such as:

```text
data:image/jpeg;base64,BASE64_IMAGE_STRING
```

Recognized response:

```json
{
  "success": true,
  "letter": "A",
  "message": "Gesture recognized successfully"
}
```

No image response:

```json
{
  "success": false,
  "letter": null,
  "message": "No image data received"
}
```

No hand response:

```json
{
  "success": false,
  "letter": null,
  "message": "No hand detected or insufficient landmarks"
}
```

Unrecognized gesture response:

```json
{
  "success": false,
  "letter": null,
  "message": "Gesture not recognized"
}
```

## Test Locally

Run these commands from inside the `new python model` folder:

```bash
pip install -r requirements.txt
python main.py
```

Or run with Gunicorn:

```bash
gunicorn main:app --bind 0.0.0.0:5000
```

Test the health endpoint:

```bash
curl http://localhost:5000/
```

Test prediction:

```bash
curl -X POST http://localhost:5000/upload \
  -H "Content-Type: application/json" \
  -d "{\"image\":\"BASE64_IMAGE_STRING\"}"
```

## Render Deployment

1. Push the `new python model` folder contents to a GitHub repository, or make sure this folder is the service root in your existing repository.
2. Open Render and choose **New +** > **Web Service**.
3. Connect the GitHub repository.
4. Set the service root directory to `new python model` if this is inside a larger repository.
5. Set **Environment** to **Docker**.
6. Leave build and start commands empty so Render uses the `Dockerfile` and its `CMD`.
7. Choose a plan and region.
8. Click **Create Web Service**.
9. After deployment, test:

```bash
curl https://YOUR-SERVICE-NAME.onrender.com/
```

Then test `/upload` with a base64 encoded image.
