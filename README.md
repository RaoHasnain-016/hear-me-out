# Hear Me Out

Hear Me Out is an accessibility project that helps bridge communication between
sign-language users and non-signers. The repository contains a Flutter
application, an American Sign Language (ASL) recognition API, and a Firebase
administration panel.

## Features

- Convert typed text into sign-language images and videos
- Recognize supported ASL alphabet gestures from the device camera
- Authenticate users with Firebase Authentication
- Save gesture-to-text results in Firestore
- View gesture history and mark entries as favorites
- Manage profiles, password resets, and notification settings
- Manage Firebase users and roles through an admin panel

## Repository Structure

```text
.
|-- fyp1/hearmeout/       Flutter mobile and desktop application
|-- new python model/     Flask and MediaPipe ASL recognition API
|-- admin-panel/          Firebase admin dashboard and Express API
`-- README.md
```

## Technology Stack

| Component | Technologies |
| --- | --- |
| Client application | Flutter, Dart, Camera, Firebase |
| Recognition API | Python, Flask, OpenCV, MediaPipe, NumPy |
| Admin panel | HTML, CSS, JavaScript, Express, Firebase Admin SDK |
| Data and authentication | Firebase Auth, Firestore, Storage, Messaging |

## Prerequisites

- Flutter SDK compatible with Dart `^3.8.1`
- Android Studio, an Android device, or another supported Flutter target
- Python 3.11 or later
- Node.js and npm
- A Firebase project with Authentication and Firestore enabled

## Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/RaoHasnain-016/hear-me-out.git
cd hear-me-out
```

### 2. Run the ASL Recognition API

From the `new python model` directory:

```bash
python -m venv .venv
```

Activate the environment:

```powershell
# Windows PowerShell
.\.venv\Scripts\Activate.ps1
```

```bash
# macOS or Linux
source .venv/bin/activate
```

Install dependencies and start the server:

```bash
pip install -r requirements.txt
python main.py
```

The API runs at `http://localhost:5000` by default.

### 3. Configure and Run the Flutter App

The Flutter project is located in `fyp1/hearmeout`.

1. Add the Firebase configuration files for each target platform.
2. Update the recognition API URL in
   `lib/screens/gesture_to_text_page.dart`. It currently uses the development
   address `http://192.168.100.227:5000/upload`.
3. Install packages and run the application:

```bash
cd fyp1/hearmeout
flutter pub get
flutter run
```

When testing on a physical device, use the computer's LAN IP address instead of
`localhost`. The phone and computer must be connected to the same network.

### 4. Configure and Run the Admin Panel

The admin panel requires a Firebase Admin service-account credential.

1. In Firebase Console, open **Project settings > Service accounts**.
2. Generate a private key.
3. Save it locally as `admin-panel/serviceAccountKey.json`.
4. Do not commit or share this file.

Install dependencies and start the Express API:

```bash
cd admin-panel
npm install
npm start
```

Serve the dashboard files using a local static server, then open `index.html`
through that server. The dashboard's Firebase web configuration is in
`admin-panel/app.js`.

> The recognition API and admin Express API both use port `5000` by default.
> To run them together, set a different `PORT` for one service and update the
> corresponding URLs in `admin-panel/app.js`.

## Recognition API

### Health Check

```http
GET /
```

### Recognize a Gesture

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

Successful response:

```json
{
  "success": true,
  "letter": "A",
  "message": "Gesture recognized successfully"
}
```

The current recognition logic supports static ASL letters implemented in
`new python model/main.py`. Motion-based letters such as `J` and `Z` are not
currently recognized.

## Docker Deployment

The recognition API includes a Dockerfile suitable for services such as Render.
Set the service root directory to `new python model` and deploy it as a Docker
web service. The container starts Gunicorn and reads the port from the `PORT`
environment variable.

## Security

- Never commit `admin-panel/serviceAccountKey.json`, private keys, or `.env`
  files.
- Keep third-party API keys outside source code.
- The optional Brevo key is read through the Flutter compile-time environment
  variable `BREVO_API_KEY`. Pass it only when that integration is enabled:

```bash
flutter run --dart-define=BREVO_API_KEY=your_key
```

- Restrict Firebase security rules and admin access before production use.
- Revoke and regenerate any credential that has previously been exposed.

## Current Limitations

- The Flutter recognition API URL is hardcoded and must be changed per
  environment.
- The admin API does not currently enforce authorization on its management
  endpoints; do not expose it publicly without adding access controls.
- Recognition is based on hand-landmark rules and may vary with lighting,
  camera angle, and hand position.
