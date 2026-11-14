import 'dart:math';

class VideoPool {
  static const List<String> videoUrls = [
    'https://res.cloudinary.com/dm0r5dyik/video/upload/q_auto/f_auto/v1781783796/vid-6.mp4_wu7rkz.mp4',
    'https://res.cloudinary.com/dm0r5dyik/video/upload/q_auto/f_auto/v1781783779/vid-3.mp4_dfuhp4.mp4',
    'https://res.cloudinary.com/dm0r5dyik/video/upload/q_auto/f_auto/v1781783778/vid-4.mp4_ynu83d.mp4',
    'https://res.cloudinary.com/dm0r5dyik/video/upload/q_auto/f_auto/v1781783774/vid-5.mp4_cwjufn.mp4',
  ];

  // Get 2 videos for a card, consistent per card index
  static List<String> getVideosForCard(int cardIndex) {
    final shuffled = List<String>.from(videoUrls);
    shuffled.shuffle(Random(cardIndex));
    return shuffled.take(2).toList();
  }

  // Get all video URLs
  static List<String> getAllVideos() {
    return List<String>.from(videoUrls);
  }

  // Get specific number of videos
  static List<String> getVideos(int count) {
    return videoUrls.take(count.clamp(1, videoUrls.length)).toList();
  }
}
