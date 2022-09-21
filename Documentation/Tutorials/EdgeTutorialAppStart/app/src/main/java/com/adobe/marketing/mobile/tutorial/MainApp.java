package com.adobe.marketing.mobile.tutorial;

import android.app.Application;
import android.util.Log;

//import androidx.lifecycle.Lifecycle;

import com.adobe.marketing.mobile.AdobeCallback;
import com.adobe.marketing.mobile.Assurance;
import com.adobe.marketing.mobile.Edge;
//import com.adobe.marketing.mobile.Lifecycle;
import com.adobe.marketing.mobile.InvalidInitException;
import com.adobe.marketing.mobile.LoggingMode;
import com.adobe.marketing.mobile.MobileCore;
import com.adobe.marketing.mobile.edge.consent.Consent;
import com.adobe.marketing.mobile.edge.identity.Identity;

public class MainApp extends Application {
    private static final String LOG_TAG = "Test Application";

    // TODO: fill in your Launch environment ID here
    private final String LAUNCH_ENVIRONMENT_ID = "94f571f308d5/289dd3df9e05/launch-93c518afa62d-development";

    @Override
    public void onCreate() {
        super.onCreate();
//        MainApp.context = getApplicationContext();
        Log.d(LOG_TAG, "Setting up mobilecore and extensions");
        MobileCore.setApplication(this);

        MobileCore.setLogLevel(LoggingMode.VERBOSE);

		/* Launch generates a unique environment ID that the SDK uses to retrieve your
		configuration. This ID is generated when an app configuration is created and published to
		a given environment. It is strongly recommended to configure the SDK with the Launch
		environment ID.
		*/
        MobileCore.configureWithAppID(LAUNCH_ENVIRONMENT_ID);

        try {
            // Register AEP extensions
            Assurance.registerExtension();
            Consent.registerExtension();
            Edge.registerExtension();
            Identity.registerExtension();
            com.adobe.marketing.mobile.Lifecycle.registerExtension();

            // Once all the extensions are registered, call MobileCore.start(...) to start processing the events
            MobileCore.start(new AdobeCallback() {

                @Override
                public void call(Object o) {
                    Log.d(LOG_TAG, "AEP Mobile SDK is initialized");

                }
            });
        } catch (InvalidInitException e) {
            e.printStackTrace();
        }



    }
}
