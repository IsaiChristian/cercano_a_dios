import 'package:dartz/dartz.dart';
import '../../domain/failures/failure.dart';
import '../error/logger_service.dart';

Future<Either<Failure, T>> safeLocalCall<T>(
  Future<T> Function() operation,
) async {
  try {
    return Right(await operation());
  } on Failure catch (failure) {
    LoggerService.logError(failure);
    return Left(failure);
  } catch (e) {
    LoggerService.logError(e);
    return const Left(
      Failure('Could not save your changes. Please try again.'),
    );
  }
}
