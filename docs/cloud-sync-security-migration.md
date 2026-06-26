# Cloud Sync Security Migration

## New production model

Cloud data is now isolated per Firebase Auth user.

Firestore layout:
- `users/{userId}`
- `users/{userId}/resumes/{resumeId}`
- `users/{userId}/settings/{settingId}`
- `users/{userId}/backups/{backupId}`
- `users/{userId}/resume_versions/{resumeId}/versions/{versionId}`

This replaces the old shared sync-code design.

## Security guarantees

- Cloud reads and writes are scoped to `request.auth.uid`.
- Legacy top-level collections are denied in Firestore rules.
- Knowing an old sync code, document ID, or backup ID does not grant access.
- Logout clears local workspace data and signs the Firebase session out.
- Switching accounts on the same device clears the previous local workspace before the new account is used.

## Migration strategy

Legacy sync-code backups are not restored automatically.

Reason:
- The old sync-code namespace was effectively public to anyone who knew the code.
- Auto-importing those documents into a new authenticated account would risk attaching the wrong data to the wrong user.

Safe migration path:
1. Sign in on the original device that already has the correct local data.
2. Open Backup & Sync.
3. Run `Backup to Cloud` to upload local resumes and job tracker data into the signed-in user's private workspace.
4. On any second device, sign in with the same account.
5. Run `Restore from Cloud` to pull the private workspace data down.

## Existing local data

Local data remains available on the current device until an authenticated user change occurs.
When a different Firebase user signs in on the same device, the app clears the prior local workspace before the new user starts using the app.

## Operational notes

- Anonymous Firebase users still get isolated private workspaces, but they do not provide safe cross-device sync by themselves.
- For multi-device sync, users must sign in with the same upgraded account on each device.
- Resume auto-upload is restored through the secure user-scoped sync service; explicit backup and restore remain available for manual recovery flows.
