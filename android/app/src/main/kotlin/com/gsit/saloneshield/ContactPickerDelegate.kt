package com.gsit.saloneshield

import android.app.Activity
import android.content.Intent
import android.provider.ContactsContract
import io.flutter.plugin.common.MethodChannel

/**
 * Lets the user pick one contact using the system contact picker.
 *
 * This deliberately uses [Intent.ACTION_PICK] rather than the READ_CONTACTS
 * permission. The picker runs in the system's own UI, the user chooses exactly
 * one person, and only that person's row is handed back — so Salone Shield can
 * never read, enumerate or upload the address book, and the app declares no
 * contacts permission at all.
 *
 * A returned contact is passed straight to Dart. Nothing is cached here.
 */
class ContactPickerDelegate(private val activity: Activity) {

    private var pendingResult: MethodChannel.Result? = null

    /** Opens the system picker. Fails fast if one is already open. */
    fun pick(result: MethodChannel.Result) {
        if (pendingResult != null) {
            result.error(ERROR_IN_PROGRESS, "A contact picker is already open.", null)
            return
        }

        val intent = Intent(Intent.ACTION_PICK).apply {
            type = ContactsContract.CommonDataKinds.Phone.CONTENT_TYPE
        }
        if (intent.resolveActivity(activity.packageManager) == null) {
            result.error(ERROR_UNAVAILABLE, "No contact picker on this device.", null)
            return
        }

        pendingResult = result
        try {
            activity.startActivityForResult(intent, REQUEST_CODE)
        } catch (error: android.content.ActivityNotFoundException) {
            pendingResult = null
            result.error(ERROR_UNAVAILABLE, "No contact picker on this device.", null)
        }
    }

    /** Returns true when the result belonged to this delegate. */
    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST_CODE) return false

        val result = pendingResult ?: return true
        pendingResult = null

        // The user backing out is a normal outcome, not an error.
        if (resultCode != Activity.RESULT_OK || data?.data == null) {
            result.success(null)
            return true
        }

        result.success(readPickedContact(data))
        return true
    }

    /**
     * Reads the single row the picker granted access to. No permission is
     * required: the picker passes a URI permission grant along with the result.
     */
    private fun readPickedContact(data: Intent): Map<String, String?>? {
        val uri = data.data ?: return null
        val projection = arrayOf(
            ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME,
            ContactsContract.CommonDataKinds.Phone.NUMBER,
        )
        return try {
            activity.contentResolver.query(uri, projection, null, null, null)?.use { cursor ->
                if (!cursor.moveToFirst()) return null
                val name = cursor.getString(0)
                val number = cursor.getString(1)
                if (number.isNullOrBlank()) null else mapOf(NAME to name, NUMBER to number)
            }
        } catch (error: SecurityException) {
            // Some devices decline the grant. Treated as "nothing picked"
            // rather than surfaced, so the user can still type the number.
            null
        }
    }

    fun dispose() {
        pendingResult = null
    }

    companion object {
        const val REQUEST_CODE = 5081
        const val NAME = "name"
        const val NUMBER = "number"
        const val ERROR_IN_PROGRESS = "picker_in_progress"
        const val ERROR_UNAVAILABLE = "picker_unavailable"
    }
}
