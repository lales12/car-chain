package com.example.vehicle_chain_app;

import androidx.annotation.NonNull;

import android.app.Activity;
import android.content.ContextWrapper;
import android.content.Intent;
import android.content.IntentFilter;
import android.nfc.NfcAdapter;
import android.os.Bundle;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.EventChannel.EventSink;
import io.flutter.plugin.common.EventChannel.StreamHandler;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugins.GeneratedPluginRegistrant;
import im.status.keycard.io.CardChannel;
import im.status.keycard.io.CardListener;
import im.status.keycard.android.NFCCardManager;
import im.status.keycard.applet.*;
import org.bouncycastle.util.encoders.Hex;

import android.os.Handler;
import android.util.Log;

import java.nio.charset.StandardCharsets;

public class MainActivity extends FlutterActivity {
    FlutterActivity activity = this;
    private static final String TAG = "MainActivity";
    private EventChannel eventChannel;

    private NfcAdapter nfcAdapter;
    private NFCCardManager cardManager;

    private static final String METHODCHANNEL = "samples.flutter.dev/keycard";
    private static final String EVENTCHANNEL = "samples.flutter.dev/keycardEevent";

    // functions
    String[] response = new String[4];

    private void getKeycardApplicationInfo(final EventSink events) {

        cardManager.setCardListener(new CardListener() {
            @Override
            public void onDisconnected() {
                Log.i(TAG, "Card disconnected.");
                events.endOfStream();
            }
            @Override
            public void onConnected(CardChannel cardChannel) {
                try {
                    // Applet-specific code we only use CashApplet
                    CashCommandSet cmdSet = new CashCommandSet(cardChannel);

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
                    response[0] = new String("Instance UID: " + Hex.toHexString(info.getInstanceUID()));
                    Log.i(TAG, "Secure channel public key: " + Hex.toHexString(info.getSecureChannelPubKey()));
                    response[1] = Hex.toHexString(info.getSecureChannelPubKey());
                    Log.i(TAG, "Application version: " + info.getAppVersionString());
                    response[2] = info.getAppVersionString();

                    // if (info.hasMasterKey()) {
                    //     Log.i(TAG, "Key UID: " + Hex.toHexString(info.getKeyUID()));
                    //     response[4] = Hex.toHexString(info.getKeyUID());
                    // } else {
                    //     Log.i(TAG, "The card has no master key");
                    //     response[4] = "The card has no master key";
                    // }
                    response[3] = "all read success";
                    events.success(response);
                } catch (Exception e) {
                    events.error("failed to listen", e.getMessage(), e.getCause());
                }
            }
        });

        cardManager.start();

    }


    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine);
        nfcAdapter = NfcAdapter.getDefaultAdapter(this);
        cardManager = new NFCCardManager();
        new MethodChannel(flutterEngine.getDartExecutor(), METHODCHANNEL).setMethodCallHandler(
                new MethodCallHandler() {
                    @Override
                    public void onMethodCall(MethodCall call, Result result) {
                        if (call.method.equals("getNfcStatus")) {
                            if (nfcAdapter != null) {
                                result.success(nfcAdapter.isEnabled());
                            } else {
                                result.error("UNAVAILABLE", "NfcAdapter not available.", null);
                            }
                        } else {
                            result.notImplemented();
                        }
                    }
                }
        );
        Handler uiThreadHandler = new Handler(activity.getMainLooper());
        uiThreadHandler.post(new Runnable() {
            @Override
            public void run() {
                new EventChannel(flutterEngine.getDartExecutor(), EVENTCHANNEL).setStreamHandler(
                        new StreamHandler() {
                            @Override
                            public void onListen(Object arguments, EventSink events) {
                                getKeycardApplicationInfo(events);
                                nfcAdapter.enableReaderMode(activity, cardManager, NfcAdapter.FLAG_READER_NFC_A | NfcAdapter.FLAG_READER_SKIP_NDEF_CHECK, null);

                            }

                            @Override
                            public void onCancel(Object arguments) {
                                if (nfcAdapter != null) {
                                    nfcAdapter.disableReaderMode(activity);
                                }
                            }
                        }
                );
            }});


    }
}
