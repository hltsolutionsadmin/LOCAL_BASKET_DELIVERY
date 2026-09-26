//usermanagement
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

// final String baseUrl = _resolveBaseUrl();
final String baseUrl = 'https://gateway-service.orangeplant-f70408fb.centralindia.azurecontainerapps.io/';
// ;


String _resolveBaseUrl() {
  const defined = String.fromEnvironment('BASE_URL');
  if (defined.isNotEmpty) {
    return _ensureTrailingSlash(defined);
  }

  if (kReleaseMode) {
    return _ensureTrailingSlash(
      'https://gateway-service.orangeplant-f70408fb.centralindia.azurecontainerapps.io/',
    );
  }

  if (Platform.isAndroid) {
    return _ensureTrailingSlash('http://10.0.2.2:9443/api/');
  }
  return _ensureTrailingSlash('http://localhost:9443/api/');
}

String _ensureTrailingSlash(String url) {
  return url.endsWith('/') ? url : '$url/';
}

const TriggerOtp = 'auth/otp/send';
const SigninUrl = 'auth/otp/login';
const refreshTokenUrl = 'auth/refresh';
const SignupUrl = 'usermgmt/auth/jtuserotp/trigger/sign-up?triggerOtp=true';
const userDetails = 'api/users/me';
const updateFcmTokenUrl = 'api/users/me/fcm-token';
const updateCurrentCustomerUrl = 'usermgmt/user/userDetails';
const deleteAccountUrl = 'usermgmt/user/skillrat';
const rolePostUrl = 'usermgmt/user/user';

const kFulfillmentAgentRole = 'ROLE_FULFILLMENT_AGENT';

//partner
const registrationUrl = 'delivery/api/partners';
const availabilityUrl = 'delivery/api/partners/availability/';
//delivery/api/partners/availability/DP260313-U22KB?available=true

String fetchOrdersUrl(String id, int page, int size) {
  return 'api/fulfillment/orders/partner/$id?page=$page&size=$size&sort=createdDate%2Cdesc';
}

const partnerDetailsUrl = 'delivery/api/partners/getPartner';
String updateOrderStatusUrl(String orderId) {
  return 'api/fulfillment/$orderId/status';
}

String acceptOrderUrl(String orderId) {
  return 'api/fulfillment/$orderId/accept';
}

String deliverTriggerOtpUrl(String orderId) {
  return 'order/api/orders/trigger-delivery-otp?orderNumber=$orderId&type=DELIVERY';
}

String orderDetailsUrl(String orderId) {
  return 'api/orders/$orderId';
}

String deliverVerifyOtpUrl(String orderId, String otp) {
  return 'order/api/orders/validate-delivery-otp?orderNumber=$orderId&otp=$otp';
}
