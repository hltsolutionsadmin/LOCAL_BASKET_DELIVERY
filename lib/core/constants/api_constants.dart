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
const SignupUrl = 'usermgmt/auth/jtuserotp/trigger/sign-up?triggerOtp=true';
const userDetails = 'api/users/me';
const updateCurrentCustomerUrl = 'usermgmt/user/userDetails';
const deleteAccountUrl = 'usermgmt/user/skillrat';
const rolePostUrl = 'usermgmt/user/user';

const kFulfillmentAgentRole = 'ROLE_FULFILLMENT_AGENT';

//partner
const registrationUrl = 'delivery/api/partners';
const availabilityUrl = 'delivery/api/partners/availability/';
//delivery/api/partners/availability/DP260313-U22KB?available=true

String fetchOrdersUrl(String id, int page, int size) {
  return 'fulfillment/delivery-partner/$id?status=ASSIGNED_TO_PARTNER&page=$page&size=$size';
}

const partnerDetailsUrl = 'delivery/api/partners/getPartner';
String updateOrderStatusUrl(String orderId, String status) {
  return 'order/api/orders/status/$orderId?status=$status&notes=0&updatedBy';
}

String deliverTriggerOtpUrl(String orderId) {
  return 'order/api/orders/trigger-delivery-otp?orderNumber=$orderId&type=DELIVERY';
}

String deliverVerifyOtpUrl(String orderId, String otp) {
  return 'order/api/orders/validate-delivery-otp?orderNumber=$orderId&otp=$otp';
}

String reportsUrl(String frequency, String from, String to, String format) {
  return 'delivery/api/partners/reports?frequency=$frequency&from=$from&to=$to&format=$format';
}
