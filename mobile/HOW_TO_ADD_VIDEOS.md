# How to Add/Change YouTube Videos

## Quick Guide: Adding New Workout Videos

### Step 1: Get YouTube Video ID

1. Go to the YouTube video you want to use
2. Copy the video ID from the URL:
   - Regular video: `https://youtube.com/watch?v=**VIDEO_ID**`
   - Shorts video: `https://youtube.com/shorts/**VIDEO_ID**`
   
**Example:**
- URL: `https://youtube.com/shorts/bKCH2jmJxgY`
- Video ID: `bKCH2jmJxgY`

### Step 2: Add to Video Pool

Open `lib/utils/youtube_video_pool.dart` and add your video ID:

```dart
class YoutubeVideoPool {
  static const List<String> videoIds = [
    'bKCH2jmJxgY', // Existing video 1
    '3Rrl9XWvJ1s', // Existing video 2
    'nLlH3jeAO18', // Existing video 3
    '8c2JOH_VEm0', // Existing video 4
    'YOUR_NEW_VIDEO_ID', // ← Add here
  ];
  // ... rest of code
}
```

### Step 3: Save and Test

1. Save the file
2. **Hot reload** (`r` in terminal) or **Hot restart** (`R`)
3. No need to rebuild the app!

---

## Advanced: Using Specific Videos for Specific Workouts

### Option 1: Create a Custom Playlist Method

In `youtube_video_pool.dart`, add:

```dart
// Warmup videos only
static List<String> getWarmupVideos() {
  return [
    'VIDEO_ID_1',
    'VIDEO_ID_2',
    'VIDEO_ID_3',
  ];
}

// Core workout videos
static List<String> getCoreWorkoutVideos() {
  return [
    'VIDEO_ID_4',
    'VIDEO_ID_5',
    'VIDEO_ID_6',
  ];
}

// Cooldown videos
static List<String> getCooldownVideos() {
  return [
    'VIDEO_ID_7',
    'VIDEO_ID_8',
  ];
}
```

### Option 2: Pass Videos Directly

In any file that navigates to `ActiveWorkoutPage`:

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => ActiveWorkoutPage(
      youtubeVideoIds: [
        'VIDEO_ID_1',
        'VIDEO_ID_2',
        'VIDEO_ID_3',
      ], // ← Direct list
      exerciseDetails: ...,
      workoutId: ...,
    ),
  ),
);
```

---

## Video Requirements

### Recommended Video Types
- ✅ YouTube Shorts (15-60 seconds)
- ✅ Short workout clips (under 1 minute)
- ✅ Exercise demonstrations
- ✅ Fitness tutorials

### Avoid
- ❌ Long videos (over 2 minutes)
- ❌ Age-restricted content
- ❌ Private/unlisted videos
- ❌ Videos with ads (may disrupt flow)

### Best Practices
1. Use videos from same channel for consistency
2. Similar video length (30-60 seconds recommended)
3. Clear audio and instructions (in Bahasa Indonesia if possible)
4. Good lighting and visible demonstrations
5. Portrait or square format works best on mobile

---

## Troubleshooting

### Video Won't Load
**Problem:** "Video gagal dimuat" error

**Solutions:**
1. Check internet connection
2. Verify video ID is correct (no typos)
3. Check if video is publicly available
4. Try video in browser first: `https://youtube.com/watch?v=VIDEO_ID`

### Video Opens in YouTube App
**Problem:** Video opens external app instead of playing in-app

**Solution:** This shouldn't happen with current implementation. If it does:
1. Check `YoutubePlayerFlags` in `youtube_workout_player.dart`
2. Ensure `autoPlay: true` is set
3. Verify widget is properly embedded

### Video Quality Issues
**Problem:** Video is blurry or low quality

**Solution:**
- YouTube automatically adjusts quality based on connection
- User can manually adjust quality in YouTube player controls (if shown)
- To force HD, change in `youtube_workout_player.dart`:
  ```dart
  flags: const YoutubePlayerFlags(
    forceHD: true, // ← Change to true
    ...
  )
  ```

---

## Examples

### Replace All Videos with New Set

```dart
// lib/utils/youtube_video_pool.dart

static const List<String> videoIds = [
  // Full Body Warm-up Series
  'NEW_ID_1', // Jumping jacks
  'NEW_ID_2', // Arm circles
  'NEW_ID_3', // Leg swings
  
  // Core Exercises
  'NEW_ID_4', // Plank
  'NEW_ID_5', // Sit-ups
  'NEW_ID_6', // Bicycle crunches
  
  // Lower Body
  'NEW_ID_7', // Squats
  'NEW_ID_8', // Lunges
  'NEW_ID_9', // Glute bridges
  
  // Cooldown
  'NEW_ID_10', // Stretching
];
```

### Different Videos Per Workout Type

```dart
// lib/utils/youtube_video_pool.dart

static List<String> getVideosForWorkoutType(String type) {
  switch (type) {
    case 'warmup':
      return ['ID1', 'ID2', 'ID3'];
    case 'core':
      return ['ID4', 'ID5', 'ID6'];
    case 'cooldown':
      return ['ID7', 'ID8', 'ID9'];
    default:
      return getAllVideos();
  }
}
```

Then use in navigation:

```dart
ActiveWorkoutPage(
  youtubeVideoIds: YoutubeVideoPool.getVideosForWorkoutType('warmup'),
  ...
)
```

---

## Testing New Videos

1. Add video ID to pool
2. Hot reload app (`r` in terminal)
3. Navigate to workout section
4. Start workout
5. Verify:
   - Video loads within 3-5 seconds
   - Audio is clear
   - Duration matches timer (30 seconds)
   - Auto-advances to next video
   - No external app opens

---

## Quick Reference

| Task | File to Edit | Line to Change |
|------|--------------|----------------|
| Add video to pool | `lib/utils/youtube_video_pool.dart` | `videoIds` array |
| Change warmup videos | `lib/pages/workout/widgets/recommended_section.dart` | Warmup card section |
| Change default preview videos | `lib/pages/workout/workout_preview_page.dart` | `YoutubeVideoPool.getVideos(3)` |
| Adjust player settings | `lib/widgets/youtube_workout_player.dart` | `YoutubePlayerFlags` |

---

## Need Help?

1. Check video plays on YouTube website first
2. Verify video ID has no spaces or special characters
3. Ensure app has internet permission (already configured)
4. Test with different videos to isolate issue
5. Check Flutter console for error messages

**Common Error Messages:**
- `Video unavailable` → Video is private/deleted
- `Connection failed` → Internet connection issue
- `Invalid video ID` → Typo in video ID

---

## Resource Links

- [YouTube Video ID Finder](https://www.youtube.com/)
- [Flutter YouTube Player Docs](https://pub.dev/packages/youtube_player_flutter)
- [Video Requirements Guide](./YOUTUBE_MIGRATION_SUMMARY.md)
