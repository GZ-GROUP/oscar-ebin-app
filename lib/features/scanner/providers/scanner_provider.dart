import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/scanner_service.dart';

final scannerServiceProvider = Provider((ref) => ScannerService());
