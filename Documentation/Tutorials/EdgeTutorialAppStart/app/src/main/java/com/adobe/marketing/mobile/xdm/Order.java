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
import java.util.List;

/**
 * Class {@code Order}
 * The placed order for one or more products.
 *
 * XDM Property Java Object Generated 2020-10-01 15:22:47.693686 -0700 PDT m=+1.795558486 by XDMTool
 */
@SuppressWarnings("unused")
public class Order implements com.adobe.marketing.mobile.xdm.Property {
	private String currencyCode;
	private List<PaymentsItem> payments;
	private double priceTotal;
	private String purchaseID;
	private String purchaseOrderNumber;

	public Order() {}

	@Override
	public Map<String, Object> serializeToXdm() {
		Map<String, Object> map = new HashMap<>();

		if (this.currencyCode != null) {
			map.put("currencyCode", this.currencyCode);
		}

		if (this.payments != null) {
			map.put("payments", com.adobe.marketing.mobile.xdm.Formatters.serializeFromList(this.payments));
		}

		map.put("priceTotal", this.priceTotal);

		if (this.purchaseID != null) {
			map.put("purchaseID", this.purchaseID);
		}

		if (this.purchaseOrderNumber != null) {
			map.put("purchaseOrderNumber", this.purchaseOrderNumber);
		}

		return map;
	}

	/**
	 * Returns the Currency property
	 * The ISO 4217 currency code used for the order totals.
	 * @return {@link String} value or null if the property is not set
	 */
	public String getCurrencyCode() {
		return this.currencyCode;
	}

	/**
	 * Sets the Currency property
	 * The ISO 4217 currency code used for the order totals.
	 * @param newValue the new Currency value
	 */
	public void setCurrencyCode(final String newValue) {
		this.currencyCode = newValue;
	}
	/**
	 * Returns the Payment List property
	 * The list of payments for this order.
	 * @return list of {@link PaymentsItem} values or null if the list is not set
	 */
	public List<PaymentsItem> getPayments() {
		return this.payments;
	}

	/**
	 * Sets the Payment List property
	 * The list of payments for this order.
	 * @param newValue the new Payment List value
	 */
	public void setPayments(final List<PaymentsItem> newValue) {
		this.payments = newValue;
	}
	/**
	 * Returns the Price Total property
	 * The total price of this order after all discounts and taxes have been applied.
	 * @return double value
	 */
	public double getPriceTotal() {
		return this.priceTotal;
	}

	/**
	 * Sets the Price Total property
	 * The total price of this order after all discounts and taxes have been applied.
	 * @param newValue the new Price Total value
	 */
	public void setPriceTotal(final double newValue) {
		this.priceTotal = newValue;
	}
	/**
	 * Returns the Purchase ID property
	 * Unique identifier assigned by the seller for this purchase or contract. There is no guarantee that the ID is unique.
	 * @return {@link String} value or null if the property is not set
	 */
	public String getPurchaseID() {
		return this.purchaseID;
	}

	/**
	 * Sets the Purchase ID property
	 * Unique identifier assigned by the seller for this purchase or contract. There is no guarantee that the ID is unique.
	 * @param newValue the new Purchase ID value
	 */
	public void setPurchaseID(final String newValue) {
		this.purchaseID = newValue;
	}
	/**
	 * Returns the Purchase Order Number property
	 * Unique identifier assigned by the purchaser for this purchase or contract.
	 * @return {@link String} value or null if the property is not set
	 */
	public String getPurchaseOrderNumber() {
		return this.purchaseOrderNumber;
	}

	/**
	 * Sets the Purchase Order Number property
	 * Unique identifier assigned by the purchaser for this purchase or contract.
	 * @param newValue the new Purchase Order Number value
	 */
	public void setPurchaseOrderNumber(final String newValue) {
		this.purchaseOrderNumber = newValue;
	}
}
