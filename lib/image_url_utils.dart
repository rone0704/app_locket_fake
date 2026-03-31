import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

bool isRenderableImageUrl(String imageUrl) {
  final normalized = imageUrl.trim();
  return normalized.startsWith('http://') ||
      normalized.startsWith('https://') ||
      normalized.startsWith('data:image/');
}

Uint8List? decodeDataImageUrl(String imageUrl) {
  final normalized = imageUrl.trim();
  if (!normalized.startsWith('data:image/')) {
    return null;
  }

  final commaIndex = normalized.indexOf(',');
  if (commaIndex < 0 || commaIndex + 1 >= normalized.length) {
    return null;
  }

  final payload = normalized.substring(commaIndex + 1);
  try {
    return base64Decode(payload);
  } catch (_) {
    return null;
  }
}

ImageProvider<Object>? resolveImageProvider(String imageUrl) {
  final bytes = decodeDataImageUrl(imageUrl);
  if (bytes != null) {
    return MemoryImage(bytes);
  }

  final normalized = imageUrl.trim();
  if (normalized.startsWith('http://') || normalized.startsWith('https://')) {
    return NetworkImage(normalized);
  }

  return null;
}
