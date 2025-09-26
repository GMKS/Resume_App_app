# resume_builder_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Backend (Node.js API)

Local server is provided in `server.js`. Start it with `npm start`.

### Configure environment

1. Copy `.env.example` to `.env` and edit values:

```
PORT=3000
JWT_SECRET=<strong-secret>
# Optional email settings (for OTP emails)
EMAIL_SERVICE=gmail
EMAIL_USER=your-email@gmail.com
EMAIL_PASS=your-app-password
EMAIL_FROM="Resume Builder <your-email@gmail.com>"
```

2. Install deps and run locally:

```
npm install
npm start
```

### Deploy to cloud

You can deploy this API easily to a cloud service and get a single public URL.

- Render.com (free tier):

  - New Web Service → Connect repo or manual → Build Command: `npm install` → Start Command: `npm start`
  - Add Environment Variables from `.env`
  - After deploy, copy the public URL, e.g. `https://resume-api.onrender.com`

- Railway.app:

  - New Project → Deploy from repo → Add variables from `.env`
  - Service will expose a public domain, e.g. `https://resume-api.up.railway.app`

- Azure Container Apps (Docker):
  - Build container locally or in cloud using provided `Dockerfile`
  - Push image to ACR/Docker Hub
  - Create Container App with port 3000, set env vars, enable ingress

### Point Flutter app to cloud URL

In Flutter `lib/services/node_api_service.dart`, set a single base URL via the runtime define (recommended):

```
flutter run --dart-define=API_BASE_URL=https://<your-cloud-host>/api
```

Or hardcode `_defaultBaseUrl` if you prefer. The API prefix `/api` is already used by the server.
