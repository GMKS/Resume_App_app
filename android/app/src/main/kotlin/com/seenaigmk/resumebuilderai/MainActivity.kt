package com.seenaigmk.resumebuilderai

import android.content.pm.PackageManager
import android.os.Build
import android.util.Base64
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.security.MessageDigest

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
							"PLAY_WEEKLY_PRODUCT_ID" to readStringResource("play_weekly_product_id"),
							"PLAY_MONTHLY_PRODUCT_ID" to readStringResource("play_monthly_product_id"),
							"PLAY_QUARTERLY_PRODUCT_ID" to readStringResource("play_quarterly_product_id"),
							"PLAY_YEARLY_PRODUCT_ID" to readStringResource("play_yearly_product_id"),
							"GROQ_API_KEY" to readStringResource("groq_api_key"),
							"ENABLE_DUMMY_PAYMENTS" to readStringResource("enable_dummy_payments"),
							"DISABLE_GOOGLE_PLAY_BILLING" to readStringResource("disable_google_play_billing"),
							"FACEBOOK_APP_ID" to readStringResource("facebook_app_id"),
							"FACEBOOK_CLIENT_TOKEN" to readStringResource("facebook_client_token"),
							"ENABLE_FACEBOOK_AUTH" to readStringResource("facebook_auth_enabled"),
							"LINKEDIN_PROVIDER_ID" to readStringResource("linkedin_provider_id"),
							"FIREBASE_ANDROID_CERTIFICATE_HASHES" to readStringResource("firebase_android_certificate_hashes"),
							"PACKAGE_SHA1" to readPackageDigest("SHA-1"),
							"PACKAGE_SHA256" to readPackageDigest("SHA-256"),
							"FACEBOOK_KEY_HASH" to readFacebookKeyHashes(),
							"OTP_BASE_URL" to readStringResource("otp_base_url"),
							"OTP_SEND_URL" to readStringResource("otp_send_url"),
							"OTP_VERIFY_URL" to readStringResource("otp_verify_url"),
							"OTP_DEBUG_CODE" to readStringResource("otp_debug_code"),
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

	private fun readPackageDigest(algorithm: String): String {
		return readSigningCertificates()
			.map { certificateBytes ->
				MessageDigest.getInstance(algorithm)
					.digest(certificateBytes)
					.joinToString(":") { byte -> "%02X".format(byte) }
			}
			.distinct()
			.joinToString(",")
	}

	private fun readFacebookKeyHashes(): String {
		return readSigningCertificates()
			.map { certificateBytes ->
				Base64.encodeToString(
					MessageDigest.getInstance("SHA-1").digest(certificateBytes),
					Base64.NO_WRAP,
				)
			}
			.distinct()
			.joinToString(",")
	}

	private fun readSigningCertificates(): List<ByteArray> {
		return try {
			val packageInfo = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
				packageManager.getPackageInfo(packageName, PackageManager.GET_SIGNING_CERTIFICATES)
			} else {
				@Suppress("DEPRECATION")
				packageManager.getPackageInfo(packageName, PackageManager.GET_SIGNATURES)
			}

			val signatures = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
				packageInfo.signingInfo?.apkContentsSigners
			} else {
				@Suppress("DEPRECATION")
				packageInfo.signatures
			}

			signatures
				?.map { signature -> signature.toByteArray() }
				?.distinctBy { bytes -> bytes.contentHashCode() }
				.orEmpty()
		} catch (_: Exception) {
			emptyList()
		}
	}
}