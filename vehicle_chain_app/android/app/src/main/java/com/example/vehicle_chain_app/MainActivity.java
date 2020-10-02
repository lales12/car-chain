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
import android.os.Looper;
import android.util.Log;

import java.nio.charset.StandardCharsets;
import java.util.Arrays;
import java.util.HashMap;
import java.util.Map;
import java.util.Objects;

class MyStreamHandler implements EventChannel.StreamHandler {
    private static final String TAG = "MyStreamHandler";
    private NFCCardManager cardManager;
    private NfcAdapter nfcAdapter;
    private FlutterActivity activity;

    public MyStreamHandler(NFCCardManager iCardManager, NfcAdapter iNfcAdapter, FlutterActivity iActivity) {
        cardManager = iCardManager;
        nfcAdapter = iNfcAdapter;
        activity = iActivity;
    }

    String response;
    private final Handler handler = new Handler(Looper.getMainLooper());
    private final Runnable runnable = new Runnable() {
        @Override
        public void run() {
            cardManager.setCardListener(new CardListener() {
                @Override
                public void onDisconnected() {
                    Log.i(TAG, "Card disconnected.");
                    activity.runOnUiThread(() -> {
                        eventSink.endOfStream();
                    });
                }
                @Override
                public void onConnected(CardChannel cardChannel) {
                    try {
                        // Applet-specific code we only use CashApplet
                        CashCommandSet cmdSet = new CashCommandSet(cardChannel);

                        Log.i(TAG, "Applet selection successful");

                        // First thing to do is selecting the applet on the card.
                        CashApplicationInfo info = new CashApplicationInfo(cmdSet.select().checkOK().getData());

                        Log.i(TAG, "Applet PubKey: " + Arrays.toString(info.getPubKey()));
                        Log.i(TAG, "Applet PubKey hex: " + Hex.toHexString(info.getPubKey()));
                        Log.i(TAG, "Applet Version: " + info.getAppVersionString());
                        Log.i(TAG, "Applet GetPubData: " + Hex.toHexString(info.getPubData()));

                        response = Hex.toHexString(info.getPubKey());

                        activity.runOnUiThread(() -> {
                            eventSink.success(response);
                        });
                    } catch (Exception e) {
                        activity.runOnUiThread(() -> {
                            eventSink.error("exception happened", e.getMessage(), e.getCause());
                        });
                    }
                }
            });

            handler.post(this);

        }
    };

    private EventChannel.EventSink eventSink;

    @Override
    public void onListen(Object o, final EventChannel.EventSink eventSink) {
        Log.i(TAG, "Listening...");
        this.eventSink = eventSink;
        runnable.run();
        cardManager.start();
        nfcAdapter.enableReaderMode(activity, cardManager, NfcAdapter.FLAG_READER_NFC_A | NfcAdapter.FLAG_READER_SKIP_NDEF_CHECK, null);
    }

    @Override
    public void onCancel(Object o) {
        Log.i(TAG, "Cancelling...");
        if (nfcAdapter != null) {
            nfcAdapter.disableReaderMode(activity);
        }
        handler.removeCallbacks(runnable);
    }
}

public class MainActivity extends FlutterActivity {
    FlutterActivity activity = this;
    private static final String TAG = "MainActivity";
    private EventChannel eventChannel;

    private NfcAdapter nfcAdapter;
    private NFCCardManager cardManager;

    private static final String METHODCHANNEL = "samples.flutter.dev/keycard";
    private static final String EVENTCHANNEL = "samples.flutter.dev/getCardPubKeyEevent";


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

        Log.i(TAG, "Creating event channel...");
        new EventChannel(flutterEngine.getDartExecutor(), EVENTCHANNEL).setStreamHandler(
                new MyStreamHandler(cardManager, nfcAdapter, activity)
        );

    }
}

