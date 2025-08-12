class UserUtils {
  String getFirstName(String? fullName, String defaultName) {
    return fullName?.isNotEmpty == true
        ? fullName!.split(' ').first
        : defaultName;
  }

  String getTimeBasedGreeting({
    required String goodMorning,
    required String goodAfternoon,
    required String goodEvening,
    required String goodNight,
  }) {
    final hour = DateTime.now().hour;
    if (hour >= 20 || hour < 6) return goodNight;
    if (hour < 12) return goodMorning;
    if (hour < 17) return goodAfternoon;
    return goodEvening;
  }
}