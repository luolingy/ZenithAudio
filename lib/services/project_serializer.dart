// Export platform-specific implementation.
// Desktop: uses dart:io + archive package
// Web: uses browser Blob/Download APIs + archive package
export 'project_serializer_io.dart'
    if (dart.library.html) 'project_serializer_web.dart';
