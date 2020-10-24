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
import org.json.JSONObject;

import android.os.Handler;
import android.os.Looper;
import android.util.Log;

import java.nio.charset.Charset;
import java.nio.charset.StandardCharsets;
import java.util.Arrays;
import java.util.HashMap;
import java.util.Map;
import java.util.Objects;
import static org.web3j.crypto.Hash.sha3;

class SignStreamHandler implements EventChannel.StreamHandler {
    private static final String TAG = "InfoStreamHandler";
    private NFCCardManager cardManager;
    private NfcAdapter nfcAdapter;
    private FlutterActivity activity;
    String hash;

    public SignStreamHandler(NFCCardManager iCardManager, NfcAdapter iNfcAdapter, FlutterActivity iActivity, String iHash) {
        cardManager = iCardManager;
        nfcAdapter = iNfcAdapter;
        activity = iActivity;
        hash = iHash;
    }

    // String[] response = new String[4];
    JSONObject response = new JSONObject();
    private final Handler handler = new Handler(Looper.getMainLooper());
    private final Runnable runnable = new Runnable() {
        @Override
        public void run() {
            cardManager.setCardListener(new CardListener() {
                @Override
                public void onDisconnected() {
                    Log.i(TAG, "Card disconnected.");
                    /*activity.runOnUiThread(() -> {
                        Log.i(TAG, "Ending stream.");
                        eventSink.endOfStream();
                    });*/
                }
                @Override
                public void onConnected(CardChannel cardChannel) {

                    try {

                        // Applet-specific code we only use CashApplet
                        CashCommandSet cmdSet = new CashCommandSet(cardChannel);

                        Log.i(TAG, "Applet selection successful");

                        Log.i(TAG, "Got String To Sign: " + hash);

                        // attempt 1
                        // get byte[] of hash string
                        // Charset charset = StandardCharsets.UTF_8;
                        // byte[] byteHash = hash.getBytes(charset);

                        // attempt 2
                        // byte[] byteHash = hash.getBytes();

                        //attempt 3
                        byte[] byteHash = sha3(hash.getBytes());

                        Log.i(TAG, "UnSigned byte[]: " + Hex.toHexString(byteHash));

                        // First thing to do is selecting the applet on the card.
                        CashApplicationInfo info = new CashApplicationInfo(cmdSet.select().checkOK().getData());

                        Log.i(TAG, "Applet PubKey hex: " + Hex.toHexString(info.getPubKey()));

                        // hash is the hash to sign, for example the Keccak-256 hash of an Ethereum transaction
                        // the signature object contains r, s, recId and the public key associated to this signature
                        RecoverableSignature signature = new RecoverableSignature(byteHash, cmdSet.sign(byteHash).checkOK().getData());

                        Log.i(TAG, "Signed hash: " + Hex.toHexString(byteHash));
                        Log.i(TAG, "Recovery ID: " + signature.getRecId());
                        Log.i(TAG, "R: " + Hex.toHexString(signature.getR()));
                        Log.i(TAG, "S: " + Hex.toHexString(signature.getS()));

                        response.put("hash", Hex.toHexString(byteHash)); // Arrays.toString(byteHash);
                        response.put("v",String.valueOf(signature.getRecId())); // V ??
                        response.put("r",Hex.toHexString(signature.getR())); // R
                        response.put("s",Hex.toHexString(signature.getS())); // S


                        activity.runOnUiThread(() -> {
                            eventSink.success(
                                    response.toString()
                            );
                        });
                    } catch (Exception e) {
                        activity.runOnUiThread(() -> {
                            eventSink.error("exception happened: ", e.getMessage(), e.getCause());
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

class InfoStreamHandler implements EventChannel.StreamHandler {
    private static final String TAG = "InfoStreamHandler";
    private NFCCardManager cardManager;
    private NfcAdapter nfcAdapter;
    private FlutterActivity activity;

    public InfoStreamHandler(NFCCardManager iCardManager, NfcAdapter iNfcAdapter, FlutterActivity iActivity) {
        cardManager = iCardManager;
        nfcAdapter = iNfcAdapter;
        activity = iActivity;
    }

    byte[] response;
    private final Handler handler = new Handler(Looper.getMainLooper());
    private final Runnable runnable = new Runnable() {
        @Override
        public void run() {
            cardManager.setCardListener(new CardListener() {
                @Override
                public void onDisconnected() {
                    Log.i(TAG, "Card disconnected.");
                    /*activity.runOnUiThread(() -> {
                        Log.i(TAG, "Ending stream.");
                        eventSink.endOfStream();
                    });*/
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

                        response = info.getPubKey();

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

    private static final String METHODCHANNEL = "carChain.com/methodsChannel";
    private static final String EVENTCHANNEL = "carChain.com/getCardInfoEvent";
    private static final String SIGNCHANNEL = "carChain.com/signEvent";


    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine);
        nfcAdapter = NfcAdapter.getDefaultAdapter(this);
        cardManager = new NFCCardManager();
        new MethodChannel(flutterEngine.getDartExecutor(), METHODCHANNEL).setMethodCallHandler(
                new MethodCallHandler() {
                    @Override
                    public void onMethodCall(MethodCall call, Result result) {
                        switch(call.method) {
                            case "getNfcStatus":
                                if (nfcAdapter != null) {
                                    result.success(nfcAdapter.isEnabled());
                                } else {
                                    result.error("UNAVAILABLE", "NfcAdapter not available.", null);
                                }
                                break;
                            case "runCardInfoStream":
                                try {
                                    Log.i(TAG, "Creating event channel Stream...");
                                    new EventChannel(flutterEngine.getDartExecutor(), EVENTCHANNEL).setStreamHandler(
                                            new InfoStreamHandler(cardManager, nfcAdapter, activity)
                                    );
                                    result.success(true);
                                } catch (Exception e) {
                                    result.error("STREAMERROR", "Failed to launch a new stream for card info", e.toString());
                                }
                                break;
                            case "runSignStream":
                                try {
                                    Log.i(TAG, "Creating Sign event channel Stream...");
                                    Log.i(TAG, "method param: " + call.arguments.toString());
                                    new EventChannel(flutterEngine.getDartExecutor(), SIGNCHANNEL).setStreamHandler(
                                            new SignStreamHandler(cardManager, nfcAdapter, activity, call.argument("hash"))
                                    );
                                    result.success(true);
                                } catch (Exception e) {
                                    result.error("SIGNER", "Failed to launch a new stream for Signing", e.toString());
                                }
                                break;
                            default:
                                result.notImplemented();
                        }
                    }
                }
        );

    }
}

