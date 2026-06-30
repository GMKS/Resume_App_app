package com.seenaigmk.resumebuilderai

import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.security.MessageDigest

class MainActivity : FlutterActivity() {
	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		val signingInfo = loadSigningInfo()

		MethodChannel(
			flutterEngine.dartExecutor.binaryMessenger,
			"resume_builder/app_config",
		).setMethodCallHandler { call, result ->
			when (call.method) {
				"getConfig" -> {
					result.success(
						mapOf(
							"PACKAGE_NAME" to packageName,
							"PACKAGE_SHA1" to signingInfo.sha1,
							"PACKAGE_SHA256" to signingInfo.sha256,
							"FACEBOOK_APP_ID" to readStringResource("facebook_app_id"),
							"FACEBOOK_CLIENT_TOKEN" to readStringResource("facebook_client_token"),
							"ENABLE_FACEBOOK_AUTH" to readStringResource("facebook_auth_enabled"),
							"LINKEDIN_PROVIDER_ID" to readStringResource("linkedin_provider_id"),
							"FIREBASE_ANDROID_CERTIFICATE_HASHES" to readStringResource("firebase_android_certificate_hashes"),
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

	private fun loadSigningInfo(): SigningInfo {
		return try {
			val packageInfo = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
				packageManager.getPackageInfo(packageName, PackageManager.GET_SIGNING_CERTIFICATES)
			} else {
				@Suppress("DEPRECATION")
				packageManager.getPackageInfo(packageName, PackageManager.GET_SIGNATURES)
			}

			val signatureBytes = extractSignatureBytes(packageInfo) ?: return SigningInfo()
			SigningInfo(
				sha1 = digest(signatureBytes, "SHA-1"),
				sha256 = digest(signatureBytes, "SHA-256"),
			)
		} catch (_: Throwable) {
			SigningInfo()
		}
	}

	private fun extractSignatureBytes(packageInfo: PackageInfo): ByteArray? {
		return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
			val signingInfo = packageInfo.signingInfo ?: return null
			val signatures = if (signingInfo.hasMultipleSigners()) {
				signingInfo.apkContentsSigners
			} else {
				signingInfo.signingCertificateHistory
			}
			signatures.firstOrNull()?.toByteArray()
		} else {
			@Suppress("DEPRECATION")
			packageInfo.signatures?.firstOrNull()?.toByteArray()
		}
	}

	private fun digest(bytes: ByteArray, algorithm: String): String {
		return MessageDigest
			.getInstance(algorithm)
			.digest(bytes)
			.joinToString(separator = "") { byte -> "%02x".format(byte) }
	}

	private fun readStringResource(name: String): String {
		val resourceId = resources.getIdentifier(name, "string", packageName)
		if (resourceId == 0) {
			return ""
		}

		return getString(resourceId)
	}

	private data class SigningInfo(
		val sha1: String = "",
		val sha256: String = "",
	)
}