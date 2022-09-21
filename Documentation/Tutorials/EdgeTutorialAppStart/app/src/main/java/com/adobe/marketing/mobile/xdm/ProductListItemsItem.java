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
 * Class {@code ProductListItemsItem}
 *
 *
 * XDM Property Java Object Generated 2020-10-01 15:22:47.69768 -0700 PDT m=+1.799553095 by XDMTool
 */
@SuppressWarnings("unused")
public class ProductListItemsItem implements com.adobe.marketing.mobile.xdm.Property {
	private String currencyCode;
	private String name;
	private double priceTotal;
	private String product;
	private String productAddMethod;
	private int quantity;
	private String sKU;

	public ProductListItemsItem() {}

	@Override
	public Map<String, Object> serializeToXdm() {
		Map<String, Object> map = new HashMap<>();

		if (this.currencyCode != null) {
			map.put("currencyCode", this.currencyCode);
		}

		if (this.name != null) {
			map.put("name", this.name);
		}

		map.put("priceTotal", this.priceTotal);

		if (this.product != null) {
			map.put("product", this.product);
		}

		if (this.productAddMethod != null) {
			map.put("productAddMethod", this.productAddMethod);
		}

		map.put("quantity", this.quantity);

		if (this.sKU != null) {
			map.put("SKU", this.sKU);
		}

		return map;
	}

	/**
	 * Returns the Currency code property
	 * The ISO 4217 alphabetic currency code used for pricing the product.
	 * @return {@link String} value or null if the property is not set
	 */
	public String getCurrencyCode() {
		return this.currencyCode;
	}

	/**
	 * Sets the Currency code property
	 * The ISO 4217 alphabetic currency code used for pricing the product.
	 * @param newValue the new Currency code value
	 */
	public void setCurrencyCode(final String newValue) {
		this.currencyCode = newValue;
	}
	/**
	 * Returns the Name property
	 * The display name for the product as presented to the user for this product view.
	 * @return {@link String} value or null if the property is not set
	 */
	public String getName() {
		return this.name;
	}

	/**
	 * Sets the Name property
	 * The display name for the product as presented to the user for this product view.
	 * @param newValue the new Name value
	 */
	public void setName(final String newValue) {
		this.name = newValue;
	}
	/**
	 * Returns the Price total property
	 * The total price for the product line item.
	 * @return double value
	 */
	public double getPriceTotal() {
		return this.priceTotal;
	}

	/**
	 * Sets the Price total property
	 * The total price for the product line item.
	 * @param newValue the new Price total value
	 */
	public void setPriceTotal(final double newValue) {
		this.priceTotal = newValue;
	}
	/**
	 * Returns the Product property
	 * The XDM identifier of the product itself.
	 * @return {@link String} value or null if the property is not set
	 */
	public String getProduct() {
		return this.product;
	}

	/**
	 * Sets the Product property
	 * The XDM identifier of the product itself.
	 * @param newValue the new Product value
	 */
	public void setProduct(final String newValue) {
		this.product = newValue;
	}
	/**
	 * Returns the Product add method property
	 * The method that was used to add a product item to the list by the visitor. Set with product list add metrics.
	 * @return {@link String} value or null if the property is not set
	 */
	public String getProductAddMethod() {
		return this.productAddMethod;
	}

	/**
	 * Sets the Product add method property
	 * The method that was used to add a product item to the list by the visitor. Set with product list add metrics.
	 * @param newValue the new Product add method value
	 */
	public void setProductAddMethod(final String newValue) {
		this.productAddMethod = newValue;
	}
	/**
	 * Returns the Quantity property
	 * The number of units the customer has indicated they require of the product.
	 * @return int value
	 */
	public int getQuantity() {
		return this.quantity;
	}

	/**
	 * Sets the Quantity property
	 * The number of units the customer has indicated they require of the product.
	 * @param newValue the new Quantity value
	 */
	public void setQuantity(final int newValue) {
		this.quantity = newValue;
	}
	/**
	 * Returns the SKU property
	 * Stock keeping unit (SKU), the unique identifier for a product defined by the vendor.
	 * @return {@link String} value or null if the property is not set
	 */
	public String getSKU() {
		return this.sKU;
	}

	/**
	 * Sets the SKU property
	 * Stock keeping unit (SKU), the unique identifier for a product defined by the vendor.
	 * @param newValue the new SKU value
	 */
	public void setSKU(final String newValue) {
		this.sKU = newValue;
	}
}
