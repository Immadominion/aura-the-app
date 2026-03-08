import 'package:flutter/material.dart';

/// Lightweight inline-markdown parser for chat messages.
///
/// Handles:
///   **bold**  →  FontWeight.bold
///   *italic*  →  FontStyle.italic
///
/// Returns a list of [TextSpan] that can be used with [RichText] or
/// [Text.rich]. Nesting (**_..._**) is intentionally unsupported — the
/// AI prompt discourages heavy markdown, so we only need the basics.
List<TextSpan> parseSimpleMarkdown(String text, TextStyle baseStyle) {
  final spans = <TextSpan>[];

  // Match **bold** or *italic* (bold first so ** isn't split into two *).
  final regex = RegExp(r'\*\*(.+?)\*\*|\*(.+?)\*');

  int lastEnd = 0;

  for (final match in regex.allMatches(text)) {
    // Plain text before this match
    if (match.start > lastEnd) {
      spans.add(
        TextSpan(text: text.substring(lastEnd, match.start), style: baseStyle),
      );
    }

    if (match.group(1) != null) {
      // **bold**
      spans.add(
        TextSpan(
          text: match.group(1),
          style: baseStyle.copyWith(fontWeight: FontWeight.w800),
        ),
      );
    } else if (match.group(2) != null) {
      // *italic*
      spans.add(
        TextSpan(
          text: match.group(2),
          style: baseStyle.copyWith(fontStyle: FontStyle.italic),
        ),
      );
    }

    lastEnd = match.end;
  }

  // Remaining plain text
  if (lastEnd < text.length) {
    spans.add(TextSpan(text: text.substring(lastEnd), style: baseStyle));
  }

  // If no markdown was found, return the original text as-is.
  if (spans.isEmpty) {
    spans.add(TextSpan(text: text, style: baseStyle));
  }

  return spans;
}
