import 'student_base.dart';
import 'student_results_mixin.dart';
import 'student_attendance_mixin.dart';
import 'student_cbt_mixin.dart';
import 'student_fees_mixin.dart';

class StudentProvider extends StudentBase
    with StudentResultsMixin, StudentAttendanceMixin, StudentCbtMixin, StudentFeesMixin {}
