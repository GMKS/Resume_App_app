import groovy.json.JsonSlurper
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
val dotEnvProperties = Properties()
val dotEnvPropertiesFile = rootProject.file("../.env")

if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use(keystoreProperties::load)
}

if (localPropertiesFile.exists()) {
    localPropertiesFile.inputStream().use(localProperties::load)
}

if (dotEnvPropertiesFile.exists()) {
    dotEnvPropertiesFile.inputStream().use(dotEnvProperties::load)
}

fun signingValue(propertyKey: String, envKey: String): String? {
    val value = keystoreProperties.getProperty(propertyKey) ?: System.getenv(envKey)
    return value?.trim()?.takeIf { it.isNotEmpty() }
}

fun configValue(propertyKey: String, envKey: String = propertyKey): String? {
    val gradleValue = project.findProperty(propertyKey)?.toString()
    val localValue = localProperties.getProperty(propertyKey)
    val envValue = System.getenv(envKey)
    val dotEnvValue = dotEnvProperties.getProperty(propertyKey)
    return listOf(gradleValue, localValue, envValue, dotEnvValue)
        .firstOrNull { !it.isNullOrBlank() }
        ?.trim()
}

fun joinUrl(baseUrl: String, path: String): String {
    val trimmedBase = baseUrl.trim().trimEnd('/')
    val trimmedPath = path.trim().trimStart('/')
    if (trimmedBase.isEmpty()) {
        return trimmedPath
    }
    if (trimmedPath.isEmpty()) {
        return trimmedBase
    }
    return "$trimmedBase/$trimmedPath"
}

fun deriveOtpUrl(explicitValue: String?, otpBaseUrl: String, path: String): String {
    val normalizedExplicit = explicitValue?.trim().orEmpty()
    if (normalizedExplicit.isNotEmpty()) {
        return normalizedExplicit
    }

    if (otpBaseUrl.isEmpty()) {
        return ""
    }

    return joinUrl(otpBaseUrl, path)
}

fun parseBooleanFlag(value: String?): Boolean? {
    return when (value?.trim()?.lowercase()) {
        "1", "true", "yes", "on" -> true
        "0", "false", "no", "off" -> false
        else -> null
    }
}

fun normalizeCertificateHash(value: String?): String {
    return value
        ?.filter { it.isLetterOrDigit() }
        ?.lowercase()
        .orEmpty()
}

fun readFirebaseAndroidCertificateHashes(
    googleServicesFile: File,
    applicationId: String,
): Set<String> {
    if (!googleServicesFile.exists()) {
        return emptySet()
    }

    val parsed = JsonSlurper().parse(googleServicesFile) as? Map<*, *> ?: return emptySet()
    val clients = parsed["client"] as? List<*> ?: return emptySet()

    return clients
        .asSequence()
        .mapNotNull { it as? Map<*, *> }
        .filter { client ->
            val clientInfo = client["client_info"] as? Map<*, *> ?: return@filter false
            val androidClientInfo = clientInfo["android_client_info"] as? Map<*, *> ?: return@filter false
            androidClientInfo["package_name"]?.toString() == applicationId
        }
        .flatMap { client ->
            val oauthClients = client["oauth_client"] as? List<*> ?: emptyList<Any>()
            oauthClients.asSequence().mapNotNull { oauthClient ->
                val oauthMap = oauthClient as? Map<*, *> ?: return@mapNotNull null
                val androidInfo = oauthMap["android_info"] as? Map<*, *> ?: return@mapNotNull null
                normalizeCertificateHash(androidInfo["certificate_hash"]?.toString())
                    .takeIf { it.isNotEmpty() }
            }
        }
        .toSet()
}

val releaseStoreFile = signingValue("storeFile", "ANDROID_KEYSTORE_FILE")
val releaseStorePassword = signingValue("storePassword", "ANDROID_KEYSTORE_PASSWORD")
val releaseKeyAlias = signingValue("keyAlias", "ANDROID_KEY_ALIAS")
val releaseKeyPassword = signingValue("keyPassword", "ANDROID_KEY_PASSWORD")
val androidApplicationId = "com.seenaigmk.resumebuilderai"
val facebookAppId = configValue("FACEBOOK_APP_ID") ?: "YOUR_FACEBOOK_APP_ID"
val facebookClientToken = configValue("FACEBOOK_CLIENT_TOKEN") ?: "YOUR_FACEBOOK_CLIENT_TOKEN"
val linkedInProviderId = configValue("LINKEDIN_PROVIDER_ID") ?: "oidc.linkedin"
val defaultOtpBaseUrl = "https://bnxdoumofrzfzubsivgs.supabase.co/functions/v1"
val configuredOtpBaseUrl = configValue("OTP_BASE_URL")
val configuredOtpSendUrl = configValue("OTP_SEND_URL")
val configuredOtpVerifyUrl = configValue("OTP_VERIFY_URL")
val playWeeklyProductId = configValue("PLAY_WEEKLY_PRODUCT_ID") ?: "resumix_ai_weekly"
val playMonthlyProductId = configValue("PLAY_MONTHLY_PRODUCT_ID") ?: "resumix_ai_monthly"
val playQuarterlyProductId = configValue("PLAY_QUARTERLY_PRODUCT_ID") ?: "resumix_ai_quarterly"
val playYearlyProductId = configValue("PLAY_YEARLY_PRODUCT_ID") ?: "resumix_ai_yearly"
val dummyPaymentsEnabled = configValue("ENABLE_DUMMY_PAYMENTS") ?: ""
val googlePlayBillingDisabled = configValue("DISABLE_GOOGLE_PLAY_BILLING") ?: ""
val otpBaseUrl = when {
    !configuredOtpBaseUrl.isNullOrBlank() -> configuredOtpBaseUrl.trim()
    configuredOtpSendUrl.isNullOrBlank() && configuredOtpVerifyUrl.isNullOrBlank() -> defaultOtpBaseUrl
    else -> ""
}
val otpSendUrl = deriveOtpUrl(configuredOtpSendUrl, otpBaseUrl, "send-otp")
val otpVerifyUrl = deriveOtpUrl(configuredOtpVerifyUrl, otpBaseUrl, "verify-otp")
val otpDebugCode = configValue("OTP_DEBUG_CODE") ?: ""
val firebaseAndroidCertificateHashes = readFirebaseAndroidCertificateHashes(
    file("google-services.json"),
    androidApplicationId,
).joinToString(",")
val facebookAuthEnabled = parseBooleanFlag(configValue("ENABLE_FACEBOOK_AUTH"))
    ?: (facebookAppId != "YOUR_FACEBOOK_APP_ID" &&
        facebookClientToken != "YOUR_FACEBOOK_CLIENT_TOKEN")
val hasReleaseSigning = listOf(
    releaseStoreFile,
    releaseStorePassword,
    releaseKeyAlias,
    releaseKeyPassword,
).all { !it.isNullOrBlank() }

val isReleaseTaskRequested = gradle.startParameter.taskNames.any {
    it.contains("release", ignoreCase = true) || it.contains("bundle", ignoreCase = true)
}

if (isReleaseTaskRequested && !hasReleaseSigning) {
    error(
        "Release signing is not configured. Add android/key.properties or set ANDROID_KEYSTORE_FILE, ANDROID_KEYSTORE_PASSWORD, ANDROID_KEY_ALIAS, and ANDROID_KEY_PASSWORD.",
    )
}

android {
    namespace = "com.seenaigmk.resumebuilderai"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = androidApplicationId
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        resValue("string", "facebook_app_id", facebookAppId)
        resValue("string", "facebook_client_token", facebookClientToken)
        resValue("string", "facebook_auth_enabled", facebookAuthEnabled.toString())
        resValue("string", "fb_login_protocol_scheme", "fb$facebookAppId")
        resValue("string", "linkedin_provider_id", linkedInProviderId)
        resValue("string", "firebase_android_certificate_hashes", firebaseAndroidCertificateHashes)
        resValue("string", "otp_base_url", otpBaseUrl)
        resValue("string", "otp_send_url", otpSendUrl)
        resValue("string", "otp_verify_url", otpVerifyUrl)
        resValue("string", "otp_debug_code", otpDebugCode)
        resValue("string", "play_weekly_product_id", playWeeklyProductId)
        resValue("string", "play_monthly_product_id", playMonthlyProductId)
        resValue("string", "play_quarterly_product_id", playQuarterlyProductId)
        resValue("string", "play_yearly_product_id", playYearlyProductId)
        resValue("string", "enable_dummy_payments", dummyPaymentsEnabled)
        resValue("string", "disable_google_play_billing", googlePlayBillingDisabled)

        ndk {
            abiFilters += setOf("armeabi-v7a", "arm64-v8a")
        }
    }

    signingConfigs {
        create("release") {
            if (hasReleaseSigning) {
                storeFile = rootProject.file(releaseStoreFile!!)
                storePassword = releaseStorePassword
                keyAlias = releaseKeyAlias
                keyPassword = releaseKeyPassword
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

flutter {
    source = "../.."
}
