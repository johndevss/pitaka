// lib/features/account/data/institutions.dart

export 'package:pitaka/features/account/models/institution.dart';

import 'package:pitaka/features/account/models/institution.dart';

List<Institution> get supportedInstitutions => InstitutionRegistry.all;
