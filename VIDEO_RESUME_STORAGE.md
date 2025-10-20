# Video Resume Storage Information

## Storage Location

Video resumes in the Resume Builder app are currently handled as follows:

### Current Implementation (v1.0)

**Storage Method**: Temporary local storage during session

- **Location**: App's temporary directory (`/data/data/[app_package]/cache/` on Android)
- **Format**: MP4, MOV, AVI formats supported
- **Duration Limit**: 3 minutes maximum
- **Size Limit**: 50MB maximum
- **Lifecycle**: Videos are temporarily stored during the recording/editing session

### Recording Process

1. **Video Capture**: Uses device camera through `ImagePicker` plugin
2. **Temporary Storage**: Video file is stored in app's cache directory
3. **Processing**: Video can be previewed, retaked, or shared
4. **Session Management**: Video exists only during the current app session

### Storage Paths

```dart
// Video files are stored temporarily at:
// Android: /data/data/com.example.resume_app/cache/
// iOS: /var/mobile/Containers/Data/Application/[UUID]/Library/Caches/
// Windows: %LOCALAPPDATA%/[AppName]/cache/
```

### Important Notes

⚠️ **Current Limitations**:

- Videos are **NOT permanently saved** to device storage
- Videos are **NOT backed up** to cloud storage
- Videos are **lost** when app cache is cleared or app is uninstalled
- No gallery/collection of saved video resumes yet

### Accessing Videos

Currently, there is no persistent storage implementation. The `_saveVideo()` method in `VideoResumeScreen` only shows a confirmation message but doesn't actually save the video permanently.

### Future Enhancements (Planned)

🔮 **Planned Features**:

- Permanent local storage in Documents folder
- Cloud storage integration (Google Drive, OneDrive)
- Video resume gallery/library
- Export to external storage
- Compression and optimization options

### For Developers

To implement permanent video storage:

1. **Local Storage**: Use `path_provider` to get Documents directory
2. **Cloud Storage**: Integrate with cloud storage APIs
3. **Database**: Store video metadata in local database
4. **Gallery**: Create video resume collection screen

### File Naming Convention

Current temporary files follow this pattern:

```
video_resume_[timestamp].mp4
```

### Code References

- **Service**: `lib/services/video_resume_service.dart`
- **Screen**: `lib/screens/video_resume_screen.dart`
- **Max Duration**: `VideoResumeService.maxVideoDurationSeconds` (180 seconds)
- **Max Size**: `VideoResumeService.maxVideoSizeMB` (50MB)

---

**Note**: This is a premium feature. Video resume functionality requires Premium subscription.
