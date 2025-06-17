
extension ChatNullableStringExtension on String? {
  String normalizeFaceUrl() {
    if (this == null || this!.isEmpty) return '';
    return this!.startsWith('http') ? this! : 'https://${this!}';
  }
}
