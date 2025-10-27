import 'package:flutter/material.dart';
import 'package:wellness_app/features/tips/data/models/tips_model.dart';
import 'package:wellness_app/core/config/routes/route_name.dart';

class VideoRouter {
  static void navigateToVideoPlayer(
      BuildContext context,
      TipModel video,
      String categoryName,
      List<TipModel> relatedVideos, {
        bool showAllVideos = false,
        bool isFromCardClick = true, // Add this parameter with default true
      }) {
    // Check if this is a short video (under 60 seconds)
    if (video.isShort || video.durationInSeconds < 60) {
      // Navigate to shorts player
      Navigator.pushNamed(
        context,
        RoutesName.shortVideoPlayerScreen,
        arguments: {
          'tip': video,
          'categoryName': categoryName,
          'featuredTips': relatedVideos,
          'showAllVideos': showAllVideos,
          'isFromCardClick': isFromCardClick, // Add this parameter
        },
      );
    } else {
      // Navigate to standard video player
      Navigator.pushNamed(
        context,
        RoutesName.videoPlayerScreen,
        arguments: {
          'tip': video,
          'categoryName': categoryName,
          'featuredTips': relatedVideos,
        },
      );
    }
  }

  // Helper to determine if a list of videos should go to shorts or regular
  static bool shouldShowAsShorts(List<TipModel> videos) {
    if (videos.isEmpty) return false;

    // If more than half are shorts, recommend shorts view
    int shortCount = videos
        .where((v) => v.isShort || v.durationInSeconds < 60)
        .length;
    return shortCount > videos.length / 2;
  }

  // Navigate directly to shorts with a specific starting index
  static void navigateToShortsAtIndex(
      BuildContext context,
      List<TipModel> shorts,
      int startIndex,
      String categoryName, {
        bool showAllVideos = false,
        bool isFromCardClick = true, // Add this parameter with default true
      }) {
    if (startIndex < 0 || startIndex >= shorts.length) {
      return;
    }

    Navigator.pushNamed(
      context,
      RoutesName.shortVideoPlayerScreen,
      arguments: {
        'tip': shorts[startIndex],
        'categoryName': categoryName,
        'featuredTips': shorts,
        'showAllVideos': showAllVideos,
        'isFromCardClick': isFromCardClick, // Add this parameter
      },
    );
  }
}