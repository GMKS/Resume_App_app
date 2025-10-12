# MongoDB Local Setup Guide for Resume Builder App

## Overview

This guide will help you set up local MongoDB for persistent data storage instead of in-memory arrays. Your app will retain user data and resumes between server restarts.

## Prerequisites

✅ **MongoDB Compass** (you already have this)  
✅ **Node.js and npm** (already installed for your Flutter app)  
✅ **Git** (for version control - optional but recommended)

## Step 1: Install MongoDB Community Server

### Download and Install MongoDB

1. Go to https://www.mongodb.com/try/download/community
2. Select:
   - Version: Latest (7.0 or higher)
   - Platform: Windows
   - Package: msi
3. Download and run the installer
4. During installation:
   - Choose "Complete" setup
   - Install MongoDB as a Service ✅
   - Install MongoDB Compass ✅ (you can skip if already installed)
   - Default data directory: `C:\Program Files\MongoDB\Server\7.0\data`
   - Default log directory: `C:\Program Files\MongoDB\Server\7.0\log`

### Verify MongoDB Installation

1. Open Command Prompt as Administrator
2. Run: `mongod --version`
3. You should see version information like:
   ```
   db version v7.0.x
   Build Info: {
       "version": "7.0.x",
       ...
   }
   ```

## Step 2: Start MongoDB Service

### Windows Service Method (Recommended)

1. Press `Win + R`, type `services.msc`, press Enter
2. Find "MongoDB Server (MongoDB)" in the list
3. Right-click and select "Start" (if not already running)
4. Set startup type to "Automatic" for auto-start

### Command Line Method (Alternative)

```cmd
# Start MongoDB manually
mongod --dbpath "C:\Program Files\MongoDB\Server\7.0\data"
```

## Step 3: Verify MongoDB is Running

### Using MongoDB Compass

1. Open MongoDB Compass
2. Connection string should be: `mongodb://localhost:27017`
3. Click "Connect"
4. You should see the MongoDB server connected successfully

### Using Command Line

```cmd
# Test connection
mongosh
# Should connect and show MongoDB prompt: >
```

## Step 4: Install Node.js Dependencies

Navigate to your resume app directory and install Mongoose:

```powershell
cd "C:\Users\SIS4\Resume_App_app"
npm install mongoose
```

## Step 5: Environment Variables (Optional but Recommended)

Create a `.env` file in your project root:

```env
# MongoDB Configuration
MONGODB_URI=mongodb://127.0.0.1:27017/resume_builder
PORT=3000

# JWT Secret (change this to a secure random string)
JWT_SECRET=your_super_secure_jwt_secret_here_change_this

# Email Configuration (optional)
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USER=your-email@gmail.com
EMAIL_PASS=your-app-password

# Development Settings
NODE_ENV=development
EXPOSE_OTP=true
```

**Important:** Add `.env` to your `.gitignore` file to keep secrets secure!

## Step 6: Update server.js (Already Done)

✅ **Models Created:**

- `models/User.js` - User authentication and profile data
- `models/Resume.js` - Resume storage with flexible template support

✅ **Database Connection:** MongoDB connection with error handling and retry logic

✅ **Routes Converted:** All API endpoints now use MongoDB instead of in-memory arrays:

- User registration, login, OTP verification
- Resume CRUD operations (Create, Read, Update, Delete)
- JWT middleware updated for MongoDB ObjectIds

## Step 7: Test the Setup

### Start Your Server

```powershell
cd "C:\Users\SIS4\Resume_App_app"
node server.js
```

You should see output like:

```
🚀 Connecting to MongoDB...
✅ MongoDB connected successfully to: resume_builder
🎯 Server running on port 3000
📱 API Base URL: http://localhost:3000
```

### Test with MongoDB Compass

1. Open MongoDB Compass
2. Connect to `mongodb://localhost:27017`
3. You should see a new database called `resume_builder`
4. It will have collections: `users` and `resumes`

### Test with Flutter App

Run your Flutter app and test:

1. **User Registration:** Create a new account
2. **Login:** Sign in with your credentials
3. **Create Resume:** Add a new resume
4. **Restart Server:** Stop and restart `node server.js`
5. **Verify Persistence:** Login again - your data should still be there!

## Step 8: Run Flutter App with Local Backend

### Start Backend Server

```powershell
cd "C:\Users\SIS4\Resume_App_app"
node server.js
```

### Start Flutter App (Two Options)

**Option 1: Using VS Code Task**

1. Open VS Code
2. Press `Ctrl+Shift+P`
3. Type "Tasks: Run Task"
4. Select "Flutter: Run (Cloud API)"

**Option 2: Command Line**

```powershell
flutter run --dart-define=API_BASE_URL=http://localhost:3000/api
```

### For Android Device Testing

If testing on Android device, replace `localhost` with your computer's IP:

```powershell
# Find your IP address
ipconfig

# Use your IP instead of localhost
flutter run --dart-define=API_BASE_URL=http://YOUR_IP_ADDRESS:3000/api
```

## Troubleshooting

### MongoDB Won't Start

```powershell
# Check if MongoDB is running
tasklist | findstr mongod

# Start MongoDB service
net start MongoDB

# If service doesn't exist, install it:
mongod --install --serviceName "MongoDB" --serviceDisplayName "MongoDB Server"
```

### Connection Refused Error

1. Verify MongoDB is running: `mongosh mongodb://localhost:27017`
2. Check Windows Firewall isn't blocking port 27017
3. Try restarting MongoDB service

### Database/Collection Not Appearing

1. Collections are created automatically when first document is inserted
2. Create a test user through your Flutter app
3. Check MongoDB Compass - collections should appear

### Server Crashes on Startup

1. Check MongoDB is running first
2. Verify `mongoose` is installed: `npm list mongoose`
3. Check server logs for specific error messages

## Data Migration (If You Have Existing Data)

If you had users/resumes in the old in-memory system, you can manually add them:

### Using MongoDB Compass

1. Open `resume_builder` database
2. Create collection `users` and add documents:
   ```json
   {
     "name": "John Doe",
     "email": "john@example.com",
     "phone": "+1234567890",
     "password": "hashed_password_here",
     "verified": true
   }
   ```

### Using MongoDB Shell

```javascript
// Connect to database
use resume_builder

// Insert test user
db.users.insertOne({
  name: "Test User",
  email: "test@example.com",
  phone: "+1234567890",
  verified: true,
  createdAt: new Date()
})
```

## Production Considerations

For production deployment:

1. **Security:** Use environment variables for sensitive data
2. **Indexes:** MongoDB models already include performance indexes
3. **Backup:** Set up regular database backups
4. **Monitoring:** Consider MongoDB Atlas for cloud hosting
5. **SSL/TLS:** Enable encryption for production connections

## Next Steps

1. ✅ **Local Development:** Your app now has persistent storage
2. **Testing:** Thoroughly test all features (register, login, resume CRUD)
3. **Backup:** Set up regular backups of your local MongoDB
4. **Cloud Migration:** When ready, consider MongoDB Atlas for production

## Support

If you encounter issues:

1. Check MongoDB service is running
2. Verify connection string in server.js
3. Look at server console for error messages
4. Use MongoDB Compass to inspect database state

Your Resume Builder app now has full database persistence! 🎉
