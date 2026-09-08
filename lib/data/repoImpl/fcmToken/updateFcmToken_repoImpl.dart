import 'package:localbasket_delivery_partner/data/dataSource/fcmToken/updateFcmToken_dataSource.dart';
import 'package:localbasket_delivery_partner/data/model/fcmToken/updateFcmToken_model.dart';
import 'package:localbasket_delivery_partner/domain/repository/fcmToken/updateFcmToken_repository.dart';

class UpdateFcmTokenRepositoryImpl implements UpdateFcmTokenRepository {
  final UpdateFcmTokenRemoteDataSource remoteDataSource;

  UpdateFcmTokenRepositoryImpl({required this.remoteDataSource});

  @override
  Future<UpdateFcmTokenModel> updateFcmToken(
      String fcmToken, String deviceType) {
    return remoteDataSource.updateFcmToken(fcmToken, deviceType);
  }
}
