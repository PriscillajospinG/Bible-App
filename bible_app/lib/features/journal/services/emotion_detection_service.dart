/// Detects emotional themes in a journal entry using keyword matching.
///
/// Returns a deduplicated list of emotion labels. Falls back to
/// `['reflection']` when no keywords match.
class EmotionDetectionService {
  static const Map<String, String> _keywords = {
    // Anxiety / stress
    'anxious': 'anxiety',
    'anxiety': 'anxiety',
    'worried': 'anxiety',
    'worry': 'anxiety',
    'stressed': 'anxiety',
    'stress': 'anxiety',
    'nervous': 'anxiety',
    'overwhelmed': 'anxiety',
    'restless': 'anxiety',

    // Fear
    'afraid': 'fear',
    'fear': 'fear',
    'fearful': 'fear',
    'scared': 'fear',
    'terror': 'fear',
    'terrified': 'fear',
    'panic': 'fear',

    // Sadness / grief
    'sad': 'sadness',
    'sadness': 'sadness',
    'depressed': 'sadness',
    'depression': 'sadness',
    'unhappy': 'sadness',
    'grief': 'sadness',
    'grieving': 'sadness',
    'crying': 'sadness',
    'cry': 'sadness',
    'weeping': 'sadness',
    'heartbroken': 'sadness',
    'hurt': 'sadness',

    // Loneliness
    'lonely': 'loneliness',
    'loneliness': 'loneliness',
    'alone': 'loneliness',
    'abandoned': 'loneliness',
    'isolated': 'loneliness',
    'forsaken': 'loneliness',

    // Anger / frustration
    'angry': 'anger',
    'anger': 'anger',
    'frustrated': 'anger',
    'frustration': 'anger',
    'furious': 'anger',
    'irritated': 'anger',
    'mad': 'anger',
    'bitter': 'anger',

    // Temptation / sin
    'tempted': 'temptation',
    'temptation': 'temptation',
    'tempting': 'temptation',
    'sin': 'temptation',
    'sinful': 'temptation',
    'lust': 'temptation',
    'addicted': 'temptation',
    'addiction': 'temptation',

    // Guilt / shame
    'guilty': 'guilt',
    'guilt': 'guilt',
    'shame': 'guilt',
    'ashamed': 'guilt',
    'shameful': 'guilt',
    'regret': 'guilt',
    'regretful': 'guilt',

    // Hopelessness
    'hopeless': 'hopelessness',
    'hopelessness': 'hopelessness',
    'helpless': 'hopelessness',
    'worthless': 'hopelessness',
    'meaningless': 'hopelessness',
    'pointless': 'hopelessness',
    'despair': 'hopelessness',

    // Confusion
    'confused': 'confusion',
    'confusion': 'confusion',
    'unsure': 'confusion',
    'uncertain': 'confusion',
    'lost': 'confusion',
    'unclear': 'confusion',

    // Doubt / unbelief
    'doubt': 'doubt',
    'doubting': 'doubt',
    'doubts': 'doubt',
    'unbelief': 'doubt',

    // Exhaustion / weariness
    'tired': 'exhaustion',
    'exhausted': 'exhaustion',
    'exhaustion': 'exhaustion',
    'weary': 'exhaustion',
    'burnt out': 'exhaustion',
    'drained': 'exhaustion',
    'burnout': 'exhaustion',

    // Gratitude / thankfulness
    'grateful': 'gratitude',
    'gratitude': 'gratitude',
    'thankful': 'gratitude',
    'thankfulness': 'gratitude',
    'blessed': 'gratitude',
    'blessing': 'gratitude',
    'thank': 'gratitude',

    // Joy / happiness
    'joy': 'joy',
    'joyful': 'joy',
    'happy': 'joy',
    'happiness': 'joy',
    'excited': 'joy',
    'cheerful': 'joy',
    'rejoice': 'joy',
    'celebrate': 'joy',
  };

  /// Analyses [text] and returns a list of detected emotion labels.
  ///
  /// The list is deduplicated and ordered by first occurrence.
  /// Returns `['reflection']` when no keywords match.
  List<String> detectEmotions(String text) {
    final lower = text.toLowerCase();
    final found = <String>[];

    for (final entry in _keywords.entries) {
      if (lower.contains(entry.key)) {
        final emotion = entry.value;
        if (!found.contains(emotion)) {
          found.add(emotion);
        }
      }
    }

    return found.isEmpty ? ['reflection'] : found;
  }
}
