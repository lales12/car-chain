package com.example.vehicle_chain_app;

import androidx.annotation.NonNull;
import android.content.ContextWrapper;
import android.content.Intent;
import android.content.IntentFilter;
import android.nfc.NfcAdapter;
import android.os.Bundle;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
import im.status.keycard.android.LedgerBLEManager;
// import im.status.keycard.demo.R;
import im.status.keycard.io.CardChannel;
import im.status.keycard.io.CardListener;
import im.status.keycard.android.NFCCardManager;
import im.status.keycard.applet.*;
import org.bouncycastle.util.encoders.Hex;
import android.util.Log;

public class MainActivity extends FlutterActivity {

    private static final String TAG = "MainActivity";

    private NfcAdapter nfcAdapter;
    private NFCCardManager cardManager;

    private static final String CHANNEL = "samples.flutter.dev/keycard";

    // functions
    private String response;
    private String getKeycardApplicationInfo() {
        // String[] response = new String[6];
         

        cardManager.setCardListener(new CardListener() {
            @Override
            public void onDisconnected() {
                Log.i(TAG, "Card disconnected.");
            }
            @Override
            public void onConnected(CardChannel cardChannel) {
                try {
                    // Applet-specific code
                    KeycardCommandSet cmdSet = new KeycardCommandSet(cardChannel);

                    Log.i(TAG, "Applet selection successful");

                    // First thing to do is selecting the applet on the card.
                    ApplicationInfo info = new ApplicationInfo(cmdSet.select().checkOK().getData());

                    // If the card is not initialized, the INIT apdu must be sent. The actual PIN, PUK and pairing password values
                    // can be either generated or chosen by the user. Using fixed values is highly discouraged.
                    // if (!info.isInitializedCard()) {
                    //     Log.i(TAG, "Initializing card with test secrets");
                    //     cmdSet.init("000000", "123456789012", "KeycardTest").checkOK();
                    //     info = new ApplicationInfo(cmdSet.select().checkOK().getData());
                    // }

                    Log.i(TAG, "Instance UID: " + Hex.toHexString(info.getInstanceUID()));
                    response = new String("Instance UID: " + Hex.toHexString(info.getInstanceUID()));
                    Log.i(TAG, "Secure channel public key: " + Hex.toHexString(info.getSecureChannelPubKey()));
                    // response[1] = Hex.toHexString(info.getSecureChannelPubKey());
                    Log.i(TAG, "Application version: " + info.getAppVersionString());
                    // response[2] = info.getAppVersionString();
                    Log.i(TAG, "Free pairing slots: " + info.getFreePairingSlots());
                    // response[3] = info.getFreePairingSlots();
                    // if (info.hasMasterKey()) {
                    //     Log.i(TAG, "Key UID: " + Hex.toHexString(info.getKeyUID()));
                    //     response[4] = Hex.toHexString(info.getKeyUID());
                    // } else {
                    //     Log.i(TAG, "The card has no master key");
                    //     response[4] = "The card has no master key";
                    // }
                    // response[5] = "all read succes";
                } catch (Exception e) {
                    response =  new String(e.getMessage());
                }
            }
        });
        cardManager.start();
        if (response == null) {
            response = new String("nothing...");
        }
        return response;
    }


    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        nfcAdapter = NfcAdapter.getDefaultAdapter(this);
        cardManager = new NFCCardManager();

    super.configureFlutterEngine(flutterEngine);
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
            .setMethodCallHandler(
            (call, result) -> {
                // Note: this method is invoked on the main thread.
                // TODO
                if (call.method.equals("getNfcStatus")) {
                    if (nfcAdapter != null) {
                        result.success(nfcAdapter.isEnabled());
                    } else {
                        result.error("UNAVAILABLE", "NfcAdapter not available.", null);
                    }
                } else if (call.method.equals("getKeycardApplicationInfo")) {
                    result.success(getKeycardApplicationInfo());
                } else {
                    result.notImplemented();
                }
            }
            );
    }
}
