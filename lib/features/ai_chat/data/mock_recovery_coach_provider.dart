import '../domain/chat_message.dart';
import '../domain/chat_provider.dart';

class MockRecoveryCoachProvider implements ChatProvider {
  String _replyText(String input) {
    final text = input.toLowerCase();

    if (text.contains('suicide') ||
        text.contains('kill myself') ||
        text.contains('hurt myself') ||
        text.contains('self harm')) {
      return 'Prototype response: if you may be in immediate danger or might harm yourself, stop using chat and contact emergency help now. In the U.S., call or text 988 right away, or call emergency services if you are in immediate danger.';
    }

    if (text.contains('night') ||
        text.contains('late') ||
        text.contains('alone')) {
      return 'Prototype response: late-night isolation is a common setup pattern. Your next best move is to reduce privacy fast: change rooms, put the phone farther away, and switch to one simple grounding action.';
    }

    if (text.contains('stress') ||
        text.contains('overwhelmed') ||
        text.contains('anxious')) {
      return 'Prototype response: this sounds more like pressure than desire. Try naming the stressor directly, do one body-level reset, and avoid negotiating with the urge while your stress is high.';
    }

    if (text.contains('lonely') ||
        text.contains('isolated') ||
        text.contains('empty')) {
      return 'Prototype response: loneliness can make the ritual feel like relief. Your strongest move may be contact, not willpower. Consider texting someone, leaving the room, or doing something that breaks isolation quickly.';
    }

    if (text.contains('urge') ||
        text.contains('trigger') ||
        text.contains('slip')) {
      return 'Prototype response: catch the sequence early. Name where you are in the cycle, shorten the decision window, and make your next action physical and specific.';
    }

    return 'Prototype response: pause, name the pattern, and choose one small next step. The goal is not solving everything right now. The goal is interrupting the cycle earlier than usual.';
  }

  @override
  Future<ChatMessage> generateReply({
    required List<ChatMessage> messages,
    required String userInput,
  }) async {
    return ChatMessage(
      role: ChatRole.assistant,
      text: _replyText(userInput),
      timestamp: DateTime.now(),
    );
  }
}
