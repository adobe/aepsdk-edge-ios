/*
 Copyright 2022 Adobe. All rights reserved.

 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0
 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
*/
package com.adobe.marketing.mobile.xdm;

import java.util.Map;
import java.util.HashMap;

/**
 * Class {@code Commerce}
 * Commerce specific data related to this event.
 *
 * XDM Property Java Object Generated 2020-10-01 15:22:47.69594 -0700 PDT m=+1.797812492 by XDMTool
 */
@SuppressWarnings("unused")
public class Commerce implements com.adobe.marketing.mobile.xdm.Property {
	private CartAbandons cartAbandons;
	private Checkouts checkouts;
	private InStorePurchase inStorePurchase;
	private Order order;
	private ProductListAdds productListAdds;
	private ProductListOpens productListOpens;
	private ProductListRemovals productListRemovals;
	private ProductListReopens productListReopens;
	private ProductListViews productListViews;
	private ProductViews productViews;
	private Purchases purchases;
	private SaveForLaters saveForLaters;

	public Commerce() {}

	@Override
	public Map<String, Object> serializeToXdm() {
		Map<String, Object> map = new HashMap<>();

		if (this.cartAbandons != null) {
			map.put("cartAbandons", this.cartAbandons.serializeToXdm());
		}

		if (this.checkouts != null) {
			map.put("checkouts", this.checkouts.serializeToXdm());
		}

		if (this.inStorePurchase != null) {
			map.put("inStorePurchase", this.inStorePurchase.serializeToXdm());
		}

		if (this.order != null) {
			map.put("order", this.order.serializeToXdm());
		}

		if (this.productListAdds != null) {
			map.put("productListAdds", this.productListAdds.serializeToXdm());
		}

		if (this.productListOpens != null) {
			map.put("productListOpens", this.productListOpens.serializeToXdm());
		}

		if (this.productListRemovals != null) {
			map.put("productListRemovals", this.productListRemovals.serializeToXdm());
		}

		if (this.productListReopens != null) {
			map.put("productListReopens", this.productListReopens.serializeToXdm());
		}

		if (this.productListViews != null) {
			map.put("productListViews", this.productListViews.serializeToXdm());
		}

		if (this.productViews != null) {
			map.put("productViews", this.productViews.serializeToXdm());
		}

		if (this.purchases != null) {
			map.put("purchases", this.purchases.serializeToXdm());
		}

		if (this.saveForLaters != null) {
			map.put("saveForLaters", this.saveForLaters.serializeToXdm());
		}

		return map;
	}

	/**
	 * Returns the CartAbandons property
	 * A product list has been identified as no longer accessible or purchasable by the user.
	 * @return {@link CartAbandons} value or null if the property is not set
	 */
	public CartAbandons getCartAbandons() {
		return this.cartAbandons;
	}

	/**
	 * Sets the CartAbandons property
	 * A product list has been identified as no longer accessible or purchasable by the user.
	 * @param newValue the new CartAbandons value
	 */
	public void setCartAbandons(final CartAbandons newValue) {
		this.cartAbandons = newValue;
	}
	/**
	 * Returns the Checkouts property
	 * An action during a checkout process of a product list, there can be more than one checkout event if there are multiple steps in a checkout process. If there are multiple steps the event time information and referenced page or experience is used to identify the step individual events represent in order.
	 * @return {@link Checkouts} value or null if the property is not set
	 */
	public Checkouts getCheckouts() {
		return this.checkouts;
	}

	/**
	 * Sets the Checkouts property
	 * An action during a checkout process of a product list, there can be more than one checkout event if there are multiple steps in a checkout process. If there are multiple steps the event time information and referenced page or experience is used to identify the step individual events represent in order.
	 * @param newValue the new Checkouts value
	 */
	public void setCheckouts(final Checkouts newValue) {
		this.checkouts = newValue;
	}
	/**
	 * Returns the InStorePurchase property
	 * 'inStore' purchase is saved for analytics use.
	 * @return {@link InStorePurchase} value or null if the property is not set
	 */
	public InStorePurchase getInStorePurchase() {
		return this.inStorePurchase;
	}

	/**
	 * Sets the InStorePurchase property
	 * 'inStore' purchase is saved for analytics use.
	 * @param newValue the new InStorePurchase value
	 */
	public void setInStorePurchase(final InStorePurchase newValue) {
		this.inStorePurchase = newValue;
	}
	/**
	 * Returns the Order property
	 * The placed order for one or more products.
	 * @return {@link Order} value or null if the property is not set
	 */
	public Order getOrder() {
		return this.order;
	}

	/**
	 * Sets the Order property
	 * The placed order for one or more products.
	 * @param newValue the new Order value
	 */
	public void setOrder(final Order newValue) {
		this.order = newValue;
	}
	/**
	 * Returns the ProductListAdds property
	 * Addition of a product to the product list, for example a product is added to a shopping cart.
	 * @return {@link ProductListAdds} value or null if the property is not set
	 */
	public ProductListAdds getProductListAdds() {
		return this.productListAdds;
	}

	/**
	 * Sets the ProductListAdds property
	 * Addition of a product to the product list, for example a product is added to a shopping cart.
	 * @param newValue the new ProductListAdds value
	 */
	public void setProductListAdds(final ProductListAdds newValue) {
		this.productListAdds = newValue;
	}
	/**
	 * Returns the ProductListOpens property
	 * Initializations of a new product list, for example a shopping cart is created.
	 * @return {@link ProductListOpens} value or null if the property is not set
	 */
	public ProductListOpens getProductListOpens() {
		return this.productListOpens;
	}

	/**
	 * Sets the ProductListOpens property
	 * Initializations of a new product list, for example a shopping cart is created.
	 * @param newValue the new ProductListOpens value
	 */
	public void setProductListOpens(final ProductListOpens newValue) {
		this.productListOpens = newValue;
	}
	/**
	 * Returns the ProductListRemovals property
	 * Removal or removals of a product entry from a product list, for example a product is removed from a shopping cart.
	 * @return {@link ProductListRemovals} value or null if the property is not set
	 */
	public ProductListRemovals getProductListRemovals() {
		return this.productListRemovals;
	}

	/**
	 * Sets the ProductListRemovals property
	 * Removal or removals of a product entry from a product list, for example a product is removed from a shopping cart.
	 * @param newValue the new ProductListRemovals value
	 */
	public void setProductListRemovals(final ProductListRemovals newValue) {
		this.productListRemovals = newValue;
	}
	/**
	 * Returns the ProductListReopens property
	 * A product list that was no longer accessible (abandoned) has been re-activated by the user. Example via a re-marketing activity.
	 * @return {@link ProductListReopens} value or null if the property is not set
	 */
	public ProductListReopens getProductListReopens() {
		return this.productListReopens;
	}

	/**
	 * Sets the ProductListReopens property
	 * A product list that was no longer accessible (abandoned) has been re-activated by the user. Example via a re-marketing activity.
	 * @param newValue the new ProductListReopens value
	 */
	public void setProductListReopens(final ProductListReopens newValue) {
		this.productListReopens = newValue;
	}
	/**
	 * Returns the ProductListViews property
	 * View or views of a product-list has occurred.
	 * @return {@link ProductListViews} value or null if the property is not set
	 */
	public ProductListViews getProductListViews() {
		return this.productListViews;
	}

	/**
	 * Sets the ProductListViews property
	 * View or views of a product-list has occurred.
	 * @param newValue the new ProductListViews value
	 */
	public void setProductListViews(final ProductListViews newValue) {
		this.productListViews = newValue;
	}
	/**
	 * Returns the ProductViews property
	 * View or views of a product have occurred.
	 * @return {@link ProductViews} value or null if the property is not set
	 */
	public ProductViews getProductViews() {
		return this.productViews;
	}

	/**
	 * Sets the ProductViews property
	 * View or views of a product have occurred.
	 * @param newValue the new ProductViews value
	 */
	public void setProductViews(final ProductViews newValue) {
		this.productViews = newValue;
	}
	/**
	 * Returns the Purchases property
	 * An order has been accepted. Purchase is the only required action in a commerce conversion. Purchase must have a product list referenced.
	 * @return {@link Purchases} value or null if the property is not set
	 */
	public Purchases getPurchases() {
		return this.purchases;
	}

	/**
	 * Sets the Purchases property
	 * An order has been accepted. Purchase is the only required action in a commerce conversion. Purchase must have a product list referenced.
	 * @param newValue the new Purchases value
	 */
	public void setPurchases(final Purchases newValue) {
		this.purchases = newValue;
	}
	/**
	 * Returns the SaveForLaters property
	 * Product list is saved for future use, for example a product wish list.
	 * @return {@link SaveForLaters} value or null if the property is not set
	 */
	public SaveForLaters getSaveForLaters() {
		return this.saveForLaters;
	}

	/**
	 * Sets the SaveForLaters property
	 * Product list is saved for future use, for example a product wish list.
	 * @param newValue the new SaveForLaters value
	 */
	public void setSaveForLaters(final SaveForLaters newValue) {
		this.saveForLaters = newValue;
	}
}
