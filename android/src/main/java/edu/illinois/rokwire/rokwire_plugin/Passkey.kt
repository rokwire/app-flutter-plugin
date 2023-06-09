package edu.illinois.rokwire.rokwire_plugin;

import android.app.Activity
import android.util.Log
import androidx.credentials.*
import androidx.credentials.exceptions.*
import io.flutter.plugins.firebase.messaging.ContextHolder.getApplicationContext
import kotlinx.coroutines.*

class PasskeyManager(private val activity: Activity?) {
    private val tag = "PasskeyManager"
    private val credentialManager: CredentialManager = CredentialManager.create(getApplicationContext())
    private val scope = CoroutineScope(Dispatchers.Default)

    fun login(requestJson: String?, preferImmediatelyAvailableCredentials: Boolean?) {
        if (requestJson == null) {
            notifyGetPasskeyFailed("MISSING_REQUEST")
            return
        }
        if (activity == null) {
            notifyGetPasskeyFailed("NULL_ACTIVITY")
            return
        }

        // Retrieves the user's saved password for your app from their
        // password provider.
        val getPasswordOption = GetPasswordOption()

        // Get passkeys from the user's public key credential provider.
        val getPublicKeyCredentialOption = GetPublicKeyCredentialOption(
            requestJson = requestJson,
            preferImmediatelyAvailableCredentials = preferImmediatelyAvailableCredentials ?: true
        )

        val getCredRequest = GetCredentialRequest(
            listOf(getPasswordOption, getPublicKeyCredentialOption)
        )

        scope.launch {
            try {
                val result = credentialManager.getCredential(
                    request = getCredRequest,
                    activity = activity,
                )
                handleSignIn(result)
            } catch (e : GetCredentialException) {
                Log.e(tag, e.toString())
                notifyGetPasskeyFailed(e.type)
            }
        }
    }

    private fun handleSignIn(result: GetCredentialResponse) {
        // Handle the successfully returned credential.
        when (val credential = result.credential) {
            is PublicKeyCredential -> {
                Log.e(tag, "Credential found: " + credential.authenticationResponseJson)
                RokwirePlugin.getInstance().notifyPasskeyResult("onGetPasskeySuccess", credential.authenticationResponseJson)
            }
//            is PasswordCredential -> {
//                val username = credential.id
//                val password = credential.password
//                passwordAuthenticateWithServer(username, password)
//            }
            else -> {
                // Catch any unrecognized credential type here.
                notifyGetPasskeyFailed("INVALID_CREDENTIAL_TYPE")
            }
        }
    }

    private fun notifyGetPasskeyFailed(error: String) {
        Log.e(tag, error)
        RokwirePlugin.getInstance().notifyPasskeyResult("onGetPasskeyFailed", error)
    }

    fun createPasskey(requestJson: String?, preferImmediatelyAvailableCredentials: Boolean?) {
        if (requestJson == null) {
            notifyCreatePasskeyFailed("MISSING_REQUEST")
            return
        }
        if (activity == null) {
            notifyGetPasskeyFailed("NULL_ACTIVITY")
            return
        }

        val createPublicKeyCredentialRequest = CreatePublicKeyCredentialRequest(
            // Contains the request in JSON format. Uses the standard WebAuthn
            // web JSON spec.
            requestJson = requestJson,
            // Defines whether you prefer to use only immediately available credentials,
            // not hybrid credentials, to fulfill this request. This value is false
            // by default.
            preferImmediatelyAvailableCredentials = preferImmediatelyAvailableCredentials ?: true,
        )

        // Execute CreateCredentialRequest asynchronously to register credentials
        // for a user account. Handle success and failure cases with the result and
        // exceptions, respectively.
        scope.launch {
            try {
                val result = credentialManager.createCredential(
                    request = createPublicKeyCredentialRequest,
                    activity = activity,
                )
                RokwirePlugin.getInstance().notifyPasskeyResult("onCreatePasskeySuccess", result.data.toString())
            } catch (e : CreateCredentialException) {
                Log.e(tag, e.toString())
                notifyCreatePasskeyFailed(e.type)
            }
        }
    }

    private fun notifyCreatePasskeyFailed(error: String) {
        Log.e(tag, error)
        RokwirePlugin.getInstance().notifyPasskeyResult("onCreatePasskeyFailed", error)
    }
}
