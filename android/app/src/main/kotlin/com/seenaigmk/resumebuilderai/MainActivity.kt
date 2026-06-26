package com.seenaigmk.resumebuilderai

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		MethodChannel(
			flutterEngine.dartExecutor.binaryMessenger,
			"resume_builder/app_config",
		).setMethodCallHandler { call, result ->
			when (call.method) {
				"getConfig" -> {
					result.success(
						mapOf(
							"FACEBOOK_APP_ID" to readStringResource("facebook_app_id"),
							"FACEBOOK_CLIENT_TOKEN" to readStringResource("facebook_client_token"),
							"ENABLE_FACEBOOK_AUTH" to readStringResource("facebook_auth_enabled"),
							"LINKEDIN_PROVIDER_ID" to readStringResource("linkedin_provider_id"),
							"OTP_BASE_URL" to readStringResource("otp_base_url"),
							"OTP_SEND_URL" to readStringResource("otp_send_url"),
							"OTP_VERIFY_URL" to readStringResource("otp_verify_url"),
							"OTP_DEBUG_CODE" to readStringResource("otp_debug_code"),
							"PLAY_WEEKLY_PRODUCT_ID" to readStringResource("play_weekly_product_id"),
							"PLAY_MONTHLY_PRODUCT_ID" to readStringResource("play_monthly_product_id"),
							"PLAY_QUARTERLY_PRODUCT_ID" to readStringResource("play_quarterly_product_id"),
							"PLAY_YEARLY_PRODUCT_ID" to readStringResource("play_yearly_product_id"),
							"AI_BASE_URL" to readStringResource("ai_base_url"),
							"AI_ENV" to readStringResource("ai_environment"),
							"RAZORPAY_KEY_ID" to readStringResource("razorpay_key_id"),
							"ENABLE_DUMMY_PAYMENTS" to readStringResource("enable_dummy_payments"),
							"DISABLE_GOOGLE_PLAY_BILLING" to readStringResource("disable_google_play_billing"),
						),
					)
				}

				else -> result.notImplemented()
			}
		}
	}

	private fun readStringResource(name: String): String {
		val resourceId = resources.getIdentifier(name, "string", packageName)
		if (resourceId == 0) {
			return ""
		}

		return getString(resourceId)
	}
}