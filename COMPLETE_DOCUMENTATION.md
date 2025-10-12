# Resume Builder App - Complete Documentation

## Table of Contents

1. [Technology Stack](#technology-stack)
2. [Architecture Overview](#architecture-overview)
3. [Project Structure](#project-structure)
4. [Core Features](#core-features)
5. [API Documentation](#api-documentation)
6. [Database Schema](#database-schema)
7. [UI/UX Components](#uiux-components)
8. [Build & Deployment](#build--deployment)
9. [Configuration](#configuration)
10. [Development Guidelines](#development-guidelines)

---

## Technology Stack

### Frontend (Flutter/Dart)

- **Framework**: Flutter 3.9.2+
- **Language**: Dart 3.9.2+
- **UI Components**: Material Design
- **State Management**: Provider Pattern
- **Local Storage**: SharedPreferences
- **File Management**: path_provider
- **HTTP Client**: http package
- **PDF Generation**: pdf package
- **Sharing**: share_plus
- **Image Handling**: image_picker
- **URL Launching**: url_launcher
- **File Operations**: archive, path packages

### Backend (Node.js)

- **Runtime**: Node.js
- **Framework**: Express.js
- **Database**: MongoDB (with Mongoose ODM)
- **Authentication**: JWT (JSON Web Tokens)
- **Password Hashing**: bcryptjs
- **Email Service**: nodemailer
- **CORS**: cors middleware
- **Environment Variables**: dotenv

### Build Tools & Development

- **Code Quality**: flutter_lints
- **Testing**: flutter_test
- **Version Control**: Git
- **CI/CD**: GitHub Actions (configured)
- **Package Manager**: pub (Flutter), npm (Node.js)

---

## Architecture Overview

### Frontend Architecture

```
┌─────────────────┐
│   Presentation  │ ← Screens & Widgets
├─────────────────┤
│    Services     │ ← Business Logic & API calls
├─────────────────┤
│     Models      │ ← Data Models & DTOs
├─────────────────┤
│   Utilities     │ ← Helper functions & Constants
└─────────────────┘
```

### Backend Architecture

```
┌─────────────────┐
│   Controllers   │ ← Route handlers
├─────────────────┤
│   Middleware    │ ← Auth, CORS, Validation
├─────────────────┤
│     Models      │ ← MongoDB schemas
├─────────────────┤
│   Database      │ ← MongoDB connection
└─────────────────┘
```

---

## Project Structure

### Frontend Structure

```
lib/
├── main.dart                    # App entry point
├── config/                      # Configuration files
├── models/                      # Data models
│   ├── custom_resume_data.dart  # Main resume data model
│   ├── saved_resume.dart        # Saved resume metadata
│   ├── work_experience.dart     # Work experience model
│   ├── education.dart           # Education model
│   ├── branding.dart           # Brand customization
│   └── customize_settings.dart  # UI customization settings
├── screens/                     # UI screens
│   ├── enhanced_login_screen.dart
│   ├── home_screen.dart
│   ├── resume_template_selection_screen.dart
│   ├── saved_resumes_screen.dart
│   ├── customize_screen.dart
│   ├── custom_resume_preview.dart
│   └── [template]_resume_form_screen.dart
├── services/                    # Business logic services
│   ├── node_api_service.dart    # API communication
│   ├── resume_storage_service.dart # Local storage
│   ├── share_export_service.dart   # Export functionality
│   ├── premium_service.dart     # Premium features
│   ├── ai_service.dart         # AI assistance
│   └── one_page_pdf_exporter.dart # PDF generation
└── widgets/                     # Reusable UI components
    ├── personal_info_section.dart
    ├── experience_section.dart
    ├── education_section.dart
    ├── skills_section.dart
    └── content_sections_tab.dart
```

### Backend Structure

```
server.js                       # Main server file
package.json                    # Dependencies
.env                           # Environment variables
```

---

## Core Features

### 1. Resume Templates

- **Modern Resume**: Clean, professional design
- **Classic Resume**: Traditional format
- **Creative Resume**: Colorful, artistic layout
- **One Page Resume**: Compact single-page format
- **Professional Resume**: Corporate-style design
- **Minimal Resume**: Minimalist design approach

### 2. Content Management

- **Personal Information**: Name, contact details, summary
- **Work Experience**: Job history with descriptions
- **Education**: Academic background
- **Skills**: Technical and soft skills with categories
- **Projects**: Portfolio projects with descriptions
- **Languages**: Language proficiency levels
- **Certifications**: Professional certifications
- **References**: Professional references (optional)

### 3. Customization Features

- **Layout Options**: Single Column, Two Column, Grid layouts
- **Font Selection**: Multiple font families
- **Color Schemes**: Customizable color palettes
- **Branding**: Company logo and colors
- **Export Options**: PDF, DOCX, TXT formats

### 4. Premium Features

- **AI Assistance**: Smart content suggestions
- **Advanced Templates**: Exclusive premium designs
- **Cloud Sync**: Cross-device synchronization
- **Export Options**: Additional format support
- **Analytics**: Resume performance tracking

### 5. User Management

- **Authentication**: Email/password and OTP-based login
- **User Profiles**: Personal settings and preferences
- **Resume Storage**: Local and cloud storage options
- **Sharing**: Email, WhatsApp, direct link sharing

---

## API Documentation

### Base URL

- **Local Development**: `http://localhost:3000/api`
- **Production**: `https://resume-builder-api-8kc0.onrender.com/api`

### Authentication Endpoints

#### Register User

```http
POST /auth/register
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "securePassword123"
}
```

#### Login User

```http
POST /auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "securePassword123"
}
```

#### Send OTP

```http
POST /auth/send-otp
Content-Type: application/json

{
  "email": "user@example.com"
}
```

#### Verify OTP

```http
POST /auth/verify-otp
Content-Type: application/json

{
  "email": "user@example.com",
  "otp": "123456"
}
```

### Resume Management Endpoints

#### Get User Resumes

```http
GET /resumes
Authorization: Bearer <jwt_token>
```

#### Save Resume

```http
POST /resumes
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
  "title": "Software Developer Resume",
  "template": "modern",
  "data": { /* resume data object */ },
  "lastModified": "2024-01-01T00:00:00Z"
}
```

#### Update Resume

```http
PUT /resumes/:id
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
  "title": "Updated Resume Title",
  "data": { /* updated resume data */ }
}
```

#### Delete Resume

```http
DELETE /resumes/:id
Authorization: Bearer <jwt_token>
```

---

## Database Schema

### User Collection

```javascript
{
  _id: ObjectId,
  email: String (unique, required),
  password: String (hashed, required),
  createdAt: Date,
  lastLogin: Date,
  isPremium: Boolean,
  preferences: {
    theme: String,
    defaultTemplate: String,
    autoSave: Boolean
  }
}
```

### Resume Collection

```javascript
{
  _id: ObjectId,
  userId: ObjectId (ref: User),
  title: String (required),
  template: String (required),
  data: {
    fullName: String,
    jobTitle: String,
    contactInfo: {
      email: String,
      phone: String,
      location: String,
      linkedin: String,
      website: String
    },
    summary: String,
    skills: [Object],
    experience: [Object],
    education: [Object],
    // ... other sections
  },
  createdAt: Date,
  lastModified: Date,
  isPublic: Boolean,
  shareToken: String
}
```

---

## UI/UX Components

### Screen Components

1. **Enhanced Login Screen**: Modern authentication UI
2. **Template Selection**: Grid-based template picker
3. **Resume Builder**: Multi-tab content editor
4. **Preview Screen**: Real-time resume preview
5. **Settings Screen**: User preferences and customization

### Widget Components

1. **Personal Info Section**: Contact details form
2. **Experience Section**: Work history with date pickers
3. **Education Section**: Academic background form
4. **Skills Section**: Categorized skills with proficiency
5. **Export Options**: Format selection and sharing

### Design System

- **Primary Colors**: Indigo-based palette
- **Typography**: Material Design typography
- **Spacing**: Consistent 8px grid system
- **Icons**: Material Design icons
- **Components**: Material Design 3 components

---

## Build & Deployment

### Flutter App Build

#### Debug Build

```bash
flutter run --dart-define=API_BASE_URL=http://localhost:3000/api
```

#### Production Build (Android)

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://resume-builder-api-8kc0.onrender.com/api
```

#### Production Build (iOS)

```bash
flutter build ios --release --dart-define=API_BASE_URL=https://resume-builder-api-8kc0.onrender.com/api
```

### Backend Deployment

#### Local Development

```bash
npm install
npm start
```

#### Production (Render.com)

1. Connect GitHub repository
2. Set build command: `npm install`
3. Set start command: `npm start`
4. Configure environment variables

### Environment Variables

```env
# Backend (.env)
PORT=3000
JWT_SECRET=your_strong_secret_key
MONGODB_URI=mongodb://localhost:27017/resume_builder
EMAIL_SERVICE=gmail
EMAIL_USER=your-email@gmail.com
EMAIL_PASS=your-app-password
EMAIL_FROM="Resume Builder <your-email@gmail.com>"

# Flutter (--dart-define)
API_BASE_URL=https://your-api-url.com/api
```

---

## Configuration

### Flutter Configuration

- **Target SDK**: Android 21+, iOS 12+
- **Permissions**: Internet, storage, camera (for profile pictures)
- **Dependencies**: See pubspec.yaml for complete list

### Node.js Configuration

- **Node Version**: 18+ recommended
- **MongoDB**: 4.4+ required
- **SSL**: Required for production
- **CORS**: Configured for Flutter app domains

---

## Development Guidelines

### Code Style

- Follow Dart style guide
- Use meaningful variable names
- Document public APIs
- Implement error handling
- Write unit tests for business logic

### Git Workflow

- Feature branch workflow
- Conventional commit messages
- Pull request reviews
- Automated testing on CI/CD

### Testing Strategy

- Unit tests for services
- Widget tests for UI components
- Integration tests for critical flows
- API testing for backend endpoints

### Performance Optimization

- Lazy loading for large lists
- Image optimization
- Bundle size optimization
- Database query optimization
- Caching strategies

---

## Security Considerations

### Frontend Security

- API key protection
- Secure storage for sensitive data
- Input validation
- XSS prevention

### Backend Security

- JWT token validation
- Password hashing (bcrypt)
- Rate limiting
- CORS configuration
- Environment variable protection

---

## Monitoring & Analytics

### Application Monitoring

- Crash reporting
- Performance monitoring
- User analytics
- Error tracking

### Backend Monitoring

- Server health checks
- API response times
- Database performance
- Error logs

---

## Support & Maintenance

### Version Control

- Semantic versioning
- Release notes
- Breaking change documentation
- Migration guides

### Bug Reporting

- Issue templates
- Reproduction steps
- Environment details
- Priority classification

This documentation provides a comprehensive overview of the Resume Builder App's architecture, features, and development processes. Regular updates should be made as the application evolves.
