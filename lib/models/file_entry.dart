class FileEntry {
  final String name;
  final String type;
  final int size;
  final String modified;

  FileEntry({
    required this.name,
    required this.type,
    this.size = 0,
    this.modified = '',
  });

  bool get isDirectory => type == 'directory';

  factory FileEntry.fromJson(Map<String, dynamic> json) {
    return FileEntry(
      name: json['name'] ?? '',
      type: json['type'] ?? 'file',
      size: json['size'] ?? 0,
      modified: json['modified'] ?? '',
    );
  }
}
