# Short Video Feed App

Flutter and GetX based short video feed app with vertical scrolling, bounded video player windowing, pagination, and local state saving (`GetStorage`).

## Features

- Vertical `PageView` feed with tap to play/pause, pull to refresh, and infinite scroll pagination
- `VideoPlayerManager` maintaining only `activeIndex - 1`, `activeIndex`, and `activeIndex + 1` controllers to avoid heavy memory/decoder usage
- Priority init for the current video and a short debounce on rapid scroll to reduce unnecessary controller churn
- Fallback error state with a retry button when a stream or page load fails
- Like, comment (bottom sheet), and share interactions with local persistence via `GetStorage`

## Project Structure

- `lib/main.dart` — Entry point and `GetStorage` setup
- `lib/models/video_item.dart` — Video item model
- `lib/services/video_repository.dart` — Paginated mock data source with simulated delay and occasional load error
- `lib/controllers/video_feed_controller.dart` — GetX controller for feed state, pagination, engagement actions, and lifecycle hooks
- `lib/controllers/video_player_manager.dart` — Handles `VideoPlayerController` creation, `User-Agent` headers, active window updates, retry, and disposal
- `lib/views/widgets/video_card.dart` — Full-screen video item UI, controls, and loading/error states

## Run Locally

1. Open the project folder:
   `cd Short_Video_Feed_Application`
2. Make sure internet permission is added in `android/app/src/main/AndroidManifest.xml`:
   `<uses-permission android:name="android.permission.INTERNET"/>`
3. Fetch packages:
   `flutter pub get`
4. Run on a connected device or emulator:
   `flutter run`

## Notes & Trade-offs

- **Mock repository**: Uses local mock pagination and sample `.mp4` URLs rather than a live backend API.
- **±1 controller window**: Keeps active resource usage low on mid-range Android devices, though fast swipes across multiple items may briefly wait on initialization.
- **Stream reliability**: External sample video URLs can occasionally fail or stall depending on network or host response; failed items expose a retry action instead of staying stuck on loading.
- **Local storage**: Likes and last viewed index are stored locally on the device using `GetStorage`.