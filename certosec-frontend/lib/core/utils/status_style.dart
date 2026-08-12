import 'package:flutter/material.dart';

import '../constants/app_enums.dart';
import '../theme/app_colors.dart';

/// StatusStyle maps domain enums to their semantic color so badges and icons
/// render consistently across every screen.
abstract final class StatusStyle {
  static Color certificate(CertificateStatus status) => switch (status) {
    CertificateStatus.pending => AppColors.warning,
    CertificateStatus.issued => AppColors.primary,
    CertificateStatus.verified => AppColors.success,
    CertificateStatus.revoked => AppColors.error,
  };

  static Color verification(VerificationStatus status) => switch (status) {
    VerificationStatus.valid => AppColors.success,
    VerificationStatus.invalid => AppColors.error,
    VerificationStatus.tampered => AppColors.warning,
  };
}
