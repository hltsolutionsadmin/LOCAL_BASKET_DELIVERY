import 'package:localbasket_delivery_partner/data/model/authentication/rolesPost_model.dart';

abstract class RolePostRepository {
  Future<RolePostModel> rolePost(String? role);
}
