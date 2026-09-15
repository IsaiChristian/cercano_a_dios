import 'package:dartz/dartz.dart';
import '../../domain/failures/failure.dart';

export '../../domain/failures/failure.dart';

Future<Either<Failure, T>> safeLocalCall<T>(Future<T> Function() operation) async {
  try { return Right(await operation()); }
  catch (_) { return const Left(Failure('Could not save your changes. Please try again.')); }
}
