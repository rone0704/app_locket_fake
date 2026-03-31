class NotificationPayload {
  static const int schemaVersion = 1;

  static String deepLinkForPost(String postId) => 'locketfake://post/$postId';

  static Map<String, dynamic> forNewPost({
    required String postId,
    required String senderUid,
  }) {
    return {
      'schemaVersion': schemaVersion,
      'event': 'newPost',
      'postId': postId,
      'relatedPostId': postId,
      'relatedUserId': senderUid,
      'deepLink': deepLinkForPost(postId),
    };
  }

  static String? extractPostId(Map<String, dynamic> data) {
    final rawPostId = (data['postId'] ?? data['relatedPostId'])?.toString();
    if (rawPostId != null && rawPostId.isNotEmpty) {
      return rawPostId;
    }

    final deepLink = data['deepLink']?.toString();
    if (deepLink == null || deepLink.isEmpty) return null;

    final uri = Uri.tryParse(deepLink);
    if (uri == null) return null;

    if (uri.scheme == 'locketfake' &&
        uri.host == 'post' &&
        uri.pathSegments.isNotEmpty) {
      return uri.pathSegments.first;
    }

    return null;
  }
}
