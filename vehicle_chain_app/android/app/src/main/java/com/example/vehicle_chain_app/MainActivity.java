package com.example.vehicle_chain_app;

import android.nfc.NfcAdapter;
import android.os.Bundle;
import io.flutter.embedding.android.FlutterActivity;
import im.status.keycard.android.LedgerBLEManager;
// import im.status.keycard.demo.R;
import im.status.keycard.io.CardChannel;
import im.status.keycard.io.CardListener;
import im.status.keycard.android.NFCCardManager;
import im.status.keycard.applet.*;
import org.bouncycastle.util.encoders.Hex;

public class MainActivity extends FlutterActivity {

    private static final String TAG = "MainActivity";

    private NfcAdapter nfcAdapter;
    private NFCCardManager cardManager;
}
