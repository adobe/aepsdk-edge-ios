package com.adobe.marketing.mobile.tutorial;

import android.os.Bundle;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

import androidx.annotation.NonNull;
import androidx.fragment.app.Fragment;
import androidx.navigation.fragment.NavHostFragment;

import com.adobe.marketing.mobile.Edge;
import com.adobe.marketing.mobile.EdgeCallback;
import com.adobe.marketing.mobile.EdgeEventHandle;
import com.adobe.marketing.mobile.ExperienceEvent;
import com.adobe.marketing.mobile.R;
import com.adobe.marketing.mobile.databinding.FragmentFirstBinding;
import com.adobe.marketing.mobile.xdm.Commerce;
import com.adobe.marketing.mobile.xdm.MobileSDKCommerceSchema;
import com.adobe.marketing.mobile.xdm.Order;
import com.adobe.marketing.mobile.xdm.ProductListAdds;
import com.adobe.marketing.mobile.xdm.Purchases;
import com.google.gson.Gson;
import com.google.gson.GsonBuilder;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class FirstFragment extends Fragment {
    private static final String LOG_TAG = "FirstFragment";

    private FragmentFirstBinding binding;

    @Override
    public View onCreateView(
            LayoutInflater inflater, ViewGroup container,
            Bundle savedInstanceState
    ) {

        binding = FragmentFirstBinding.inflate(inflater, container, false);
        return binding.getRoot();

    }

    public void onViewCreated(@NonNull View view, Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);

        binding.buttonFirst.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                NavHostFragment.findNavController(FirstFragment.this)
                        .navigate(R.id.action_FirstFragment_to_SecondFragment);
            }
        });

        binding.productAddEventButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
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
                Log.d(LOG_TAG, "Sending event");
                Edge.sendEvent(event, new EdgeCallback() {

                    @Override
                    public void onComplete(final List<EdgeEventHandle> handles) {
//                        MobileCore.log(LoggingMode.VERBOSE, LOG_TAG, "Data received in the callback, updating UI");
                        Log.d(LOG_TAG, "Edge event callback called");
                        if (handles == null) {
                            return;
                        }

                        view.post(new Runnable() {
                            @Override
                            public void run() {
//                                if (textViewGetData != null) {
//
//                                    Gson gson = new GsonBuilder().setPrettyPrinting().create();
//                                    String json = gson.toJson(handles);
//                                    Log.d(LOG_TAG, String.format("Received Edge event handle are : %s", json));
///
//                                }
                            }
                        });
                    }
                });
            }
        });
    }

    @Override
    public void onDestroyView() {
        super.onDestroyView();
        binding = null;
    }

}