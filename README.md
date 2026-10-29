# JamList — Flutter Music Organizer

A beginner-friendly Flutter Android app with a dark music-themed interface.

## Features
- Register and sign in with a username and password
- Add song titles and artists
- Create custom playlist labels
- Mark songs as favorites
- Delete songs
- Save accounts, songs, and playlist names locally on the device
- Log out

## Requirements
- Flutter SDK
- Android Studio with Android SDK and an emulator, or an Android phone with USB debugging
- VS Code with the Flutter and Dart extensions

## Open and run in VS Code
1. Extract `JamList_Flutter.zip`.
2. Open the extracted `JamList_Flutter` folder in VS Code.
3. Open the terminal in VS Code.
4. Run:

   ```bash
   flutter doctor
   flutter pub get
   flutter run
   ```

5. Choose your Android emulator or connected Android phone when prompted.

## Run from Android Studio
1. Open Android Studio.
2. Choose **Open** and select the extracted `JamList_Flutter` folder.
3. Wait for Flutter dependencies to finish resolving.
4. Start an Android emulator from Device Manager, or connect a phone with USB debugging enabled.
5. Click **Run**.

## How to use
1. Select **New to JamList? Create an account**.
2. Register a username and password (minimum 6 characters).
3. Sign in.
4. Tap **Add song** to enter a title and artist.
5. Use **New playlist** to create playlist labels.
6. Tap the heart/menu on a song to favorite or delete it.
7. Tap the logout icon to return to login.

## Notes
- This is a local school-project/demo app. Data is stored on the same device using `shared_preferences`; it does not sync between devices.
- Passwords are hashed before being saved, but this is not a production authentication system. For a real public app, use a secure backend and a proper password-hashing/authentication service.
- Playlist names are currently custom collection labels; songs are not individually assigned to playlists yet.
