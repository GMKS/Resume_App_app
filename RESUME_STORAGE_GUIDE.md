# Resume Storage Locations Guide

## 📁 Where Your Resumes Are Saved

Your Resume Builder app stores saved documents in different locations depending on your device and premium status:

### 🔵 **Local Storage (All Users)**

#### **Android Devices:**

- **Primary Location:** `/storage/emulated/0/Android/data/com.example.resume_builder_app/files/Resumes/`
- **Backup Location:** App's internal documents directory
- **Exported Files:** `/storage/emulated/0/Android/data/com.example.resume_builder_app/files/Resumes/`

#### **iOS Devices:**

- **Primary Location:** App Documents Directory → `Resumes/` folder
- **Exported Files:** Same as primary location

#### **Windows/Desktop:**

- **Primary Location:** App Documents Directory → `Resumes/` folder

### ☁️ **Cloud Storage (Premium Users)**

#### **Node.js Backend (Cloud Sync):**

- **Remote Server:** `https://resume-builder-api-8kc0.onrender.com/api`
- **Database:** MongoDB/PostgreSQL (server-side)
- **Auto-Sync:** Real-time synchronization when authenticated

#### **Local Cache:**

- Premium users also maintain local copies for offline access
- Cached in the same local directories as above

### 📄 **File Formats & Storage Structure**

#### **Saved Resume Data:**

```
Resumes/
├── resume_data_[timestamp].json      # Resume content
├── [resume_name]_[timestamp].pdf     # Exported PDFs
├── [resume_name]_[timestamp].docx    # Exported Word docs (Premium)
└── [resume_name]_[timestamp].txt     # Exported text files
```

#### **Internal Storage Format:**

- **Resume Data:** JSON format in app's internal database
- **Remote ID Mapping:** Stored in SharedPreferences
- **Temporary Files:** System temp directory during export/share

### 🔍 **How to Access Your Files**

#### **Via App Interface:**

1. Open Resume Builder app
2. Navigate to "My Resumes" section
3. All saved resumes listed with options to:
   - Edit
   - Preview
   - Export (PDF/DOCX/TXT)
   - Share (Email/WhatsApp)
   - Delete

#### **Direct File Access:**

**Android:**

1. Open File Manager
2. Navigate to: `Internal Storage → Android → data → com.example.resume_builder_app → files → Resumes`
3. Find your exported PDF/DOCX/TXT files

**iOS:**

- Files are sandboxed - access only through the app interface
- Use "Share" feature to save to Photos, iCloud, or other apps

### 💾 **Storage Limits**

#### **Free Users:**

- **Resume Limit:** 3 saved resumes
- **Storage:** Local device only
- **Export Formats:** PDF only

#### **Premium Users:**

- **Resume Limit:** Unlimited
- **Storage:** Local + Cloud backup
- **Export Formats:** PDF, DOCX, TXT
- **Cloud Sync:** Automatic across devices

### 🔄 **Backup & Sync**

#### **Automatic Backup:**

- **Premium Users:** All resumes automatically synced to cloud
- **Free Users:** Manual export recommended for backup

#### **Manual Backup:**

1. Go to "My Resumes"
2. Select each resume
3. Choose "Export" → "PDF"
4. Save to your preferred location (Google Drive, Dropbox, etc.)

### 🛠️ **Recovery Options**

#### **If App is Uninstalled:**

- **Free Users:** Local data lost (export beforehand)
- **Premium Users:** Data recoverable from cloud after re-login

#### **Device Change:**

- **Free Users:** Export/transfer files manually
- **Premium Users:** Automatic sync after login on new device

### 📊 **Technical Details**

#### **Storage Technology:**

- **Local:** SQLite database + JSON files
- **Cloud:** RESTful API with MongoDB/PostgreSQL
- **Caching:** SharedPreferences for metadata

#### **File Paths (Code Level):**

```dart
// Android
await getExternalStorageDirectory()
// → /storage/emulated/0/Android/data/.../files/

// iOS/Others
await getApplicationDocumentsDirectory()
// → App Documents Directory

// Export folder
Directory(path.join(base.path, 'Resumes'))
```

### 🔐 **Privacy & Security**

#### **Local Storage:**

- Files stored in app-specific directories
- Protected by Android/iOS sandboxing
- Not accessible to other apps

#### **Cloud Storage:**

- Encrypted data transmission (HTTPS)
- User authentication required
- Data associated with user account only

### 📱 **Quick Access Tips**

1. **Bookmark Export Folder:** Add Android export folder to file manager bookmarks
2. **Use Share Feature:** Easier than direct file access on mobile
3. **Regular Exports:** Export important resumes as backup
4. **Cloud Sync:** Enable premium for automatic backup across devices

---

## 🎯 **Summary**

- **Saved Resumes:** Stored locally in app database + cloud (premium)
- **Exported Files:** `Resumes/` folder in app's file directory
- **Access:** Through app interface or file manager (Android)
- **Backup:** Cloud sync (premium) or manual export (free)

For the best experience and data security, consider upgrading to Premium for unlimited resumes and automatic cloud backup!
