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
 * Class {@code PaymentsItem}
 *
 *
 * XDM Property Java Object Generated 2020-10-01 15:22:47.696948 -0700 PDT m=+1.798820487 by XDMTool
 */
@SuppressWarnings("unused")
public class PaymentsItem implements com.adobe.marketing.mobile.xdm.Property {
	private String currencyCode;
	private double paymentAmount;
	private String paymentType;
	private String transactionID;

	public PaymentsItem() {}

	@Override
	public Map<String, Object> serializeToXdm() {
		Map<String, Object> map = new HashMap<>();

		if (this.currencyCode != null) {
			map.put("currencyCode", this.currencyCode);
		}

		map.put("paymentAmount", this.paymentAmount);

		if (this.paymentType != null) {
			map.put("paymentType", this.paymentType);
		}

		if (this.transactionID != null) {
			map.put("transactionID", this.transactionID);
		}

		return map;
	}

	/**
	 * Returns the Currency Code property
	 * The ISO 4217 currency code used for this payment item.
	 * @return {@link String} value or null if the property is not set
	 */
	public String getCurrencyCode() {
		return this.currencyCode;
	}

	/**
	 * Sets the Currency Code property
	 * The ISO 4217 currency code used for this payment item.
	 * @param newValue the new Currency Code value
	 */
	public void setCurrencyCode(final String newValue) {
		this.currencyCode = newValue;
	}
	/**
	 * Returns the Payment Amount property
	 * The value of the payment.
	 * @return double value
	 */
	public double getPaymentAmount() {
		return this.paymentAmount;
	}

	/**
	 * Sets the Payment Amount property
	 * The value of the payment.
	 * @param newValue the new Payment Amount value
	 */
	public void setPaymentAmount(final double newValue) {
		this.paymentAmount = newValue;
	}
	/**
	 * Returns the Payment Type property
	 * The method of payment for this order. Enumerated, custom values allowed.
	 * @return {@link String} value or null if the property is not set
	 */
	public String getPaymentType() {
		return this.paymentType;
	}

	/**
	 * Sets the Payment Type property
	 * The method of payment for this order. Enumerated, custom values allowed.
	 * @param newValue the new Payment Type value
	 */
	public void setPaymentType(final String newValue) {
		this.paymentType = newValue;
	}
	/**
	 * Returns the Transaction ID property
	 * The unique transaction identifier for this payment item.
	 * @return {@link String} value or null if the property is not set
	 */
	public String getTransactionID() {
		return this.transactionID;
	}

	/**
	 * Sets the Transaction ID property
	 * The unique transaction identifier for this payment item.
	 * @param newValue the new Transaction ID value
	 */
	public void setTransactionID(final String newValue) {
		this.transactionID = newValue;
	}
}
