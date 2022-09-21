package com.adobe.marketing.mobile.tutorial;

import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;

import com.adobe.marketing.mobile.Assurance;
import com.adobe.marketing.mobile.Edge;
import com.adobe.marketing.mobile.EdgeCallback;
import com.adobe.marketing.mobile.EdgeEventHandle;
import com.adobe.marketing.mobile.ExperienceEvent;
import com.adobe.marketing.mobile.LoggingMode;
import com.adobe.marketing.mobile.MobileCore;
import com.adobe.marketing.mobile.R;
import com.adobe.marketing.mobile.xdm.Commerce;
import com.adobe.marketing.mobile.xdm.MobileSDKCommerceSchema;
import com.adobe.marketing.mobile.xdm.Order;
import com.adobe.marketing.mobile.xdm.ProductListAdds;
import com.adobe.marketing.mobile.xdm.Purchases;
import com.google.android.material.snackbar.Snackbar;

import androidx.appcompat.app.AppCompatActivity;

import android.util.Log;
import android.view.View;

import androidx.navigation.NavController;
import androidx.navigation.Navigation;
import androidx.navigation.ui.AppBarConfiguration;
import androidx.navigation.ui.NavigationUI;

import com.adobe.marketing.mobile.databinding.ActivityMainBinding;
import com.google.gson.Gson;
import com.google.gson.GsonBuilder;

import android.view.Menu;
import android.view.MenuItem;
import android.widget.TextView;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class MainActivity extends AppCompatActivity {
    private static final String LOG_TAG = "MainActivity";

    private AppBarConfiguration appBarConfiguration;
    private ActivityMainBinding binding;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        binding = ActivityMainBinding.inflate(getLayoutInflater());
        setContentView(binding.getRoot());

        // Handle deep linking, and connecting to Assurance
        final Intent intent = getIntent();
        final Uri data = intent.getData();

        if (data != null) {
            Assurance.startSession(data.toString());
            MobileCore.log(LoggingMode.VERBOSE, LOG_TAG, "Deep link received " + data.toString());
        }

        setSupportActionBar(binding.toolbar);

        NavController navController = Navigation.findNavController(this, R.id.nav_host_fragment_content_main);
        appBarConfiguration = new AppBarConfiguration.Builder(navController.getGraph()).build();
        NavigationUI.setupActionBarWithNavController(this, navController, appBarConfiguration);

        binding.fab.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                Snackbar.make(view, "Replace with your own action", Snackbar.LENGTH_LONG)
                        .setAction("Action", null).show();
            }
        });
    }

    @Override
    public void onPause() {
        super.onPause();
        MobileCore.lifecyclePause();
    }

    @Override
    public void onResume() {
        super.onResume();
        MobileCore.setApplication(getApplication());
        MobileCore.lifecycleStart(null);
    }

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        // Inflate the menu; this adds items to the action bar if it is present.
        getMenuInflater().inflate(R.menu.menu_main, menu);
        return true;
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        // Handle action bar item clicks here. The action bar will
        // automatically handle clicks on the Home/Up button, so long
        // as you specify a parent activity in AndroidManifest.xml.
        int id = item.getItemId();

        //noinspection SimplifiableIfStatement
        if (id == R.id.action_settings) {
            return true;
        }

        return super.onOptionsItemSelected(item);
    }

    @Override
    public boolean onSupportNavigateUp() {
        NavController navController = Navigation.findNavController(this, R.id.nav_host_fragment_content_main);
        return NavigationUI.navigateUp(navController, appBarConfiguration)
                || super.onSupportNavigateUp();
    }

    public void onSubmitSingleEvent(final View view) {
//        final TextView textViewGetData = findViewById(R.id.tvGetData);

        List<String> valuesList = new ArrayList<>();
        valuesList.add("val1");
        valuesList.add("val2");
        Map<String, Object> eventData = new HashMap<>();
        eventData.put("test", "request");
        eventData.put("customText", "mytext");
        eventData.put("listExample", valuesList);

        // Create XDM data with Commerce data for purchases action
        MobileSDKCommerceSchema xdmData = new MobileSDKCommerceSchema();
        Order order = new Order();
        order.setCurrencyCode("RON");
        order.setPriceTotal(20);
        Purchases purchases = new Purchases();
        purchases.setValue(1);
        ProductListAdds products = new ProductListAdds();
        products.setValue(21);
        Commerce commerce = new Commerce();
        commerce.setOrder(order);
        commerce.setProductListAdds(products);
        commerce.setPurchases(purchases);
        xdmData.setEventType("commerce.purchases");
        xdmData.setCommerce(commerce);

        ExperienceEvent event = new ExperienceEvent.Builder()
                .setXdmSchema(xdmData)
                .setData(eventData)
                .build();
        Edge.sendEvent(event, new EdgeCallback() {

            @Override
            public void onComplete(final List<EdgeEventHandle> handles) {
                MobileCore.log(LoggingMode.VERBOSE, LOG_TAG, "Data received in the callback, updating UI");

                if (handles == null) {
                    return;
                }

                view.post(new Runnable() {
                    @Override
                    public void run() {
//                        if (textViewGetData != null) {
//
//                            Gson gson = new GsonBuilder().setPrettyPrinting().create();
//                            String json = gson.toJson(handles);
//                            Log.d(LOG_TAG, String.format("Received Edge event handle are : %s", json));
//                            updateTextView(json, view);
//
//                        }
                    }
                });
            }
        });
    }

}