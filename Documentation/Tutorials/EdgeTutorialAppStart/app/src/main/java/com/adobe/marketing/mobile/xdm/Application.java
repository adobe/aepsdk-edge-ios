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
 * Class {@code Application}
 * This mixin is used to capture application information related to an ExperienceEvent, including the name of the application, app version, installs, launches, crashes, and closures. It could be either the application targeted by the event like the send of a push notification or the application originating the event such as a click, or a login.
 *
 * XDM Property Java Object Generated 2020-10-01 15:23:09.63072 -0700 PDT m=+1.827997338 by XDMTool
 */
@SuppressWarnings("unused")
public class Application implements com.adobe.marketing.mobile.xdm.Property {
	private ApplicationCloses applicationCloses;
	private Crashes crashes;
	private FeatureUsages featureUsages;
	private FirstLaunches firstLaunches;
	private String id;
	private Installs installs;
	private Launches launches;
	private String name;
	private Upgrades upgrades;
	private UserPerspectiveEnum userPerspective;
	private String version;

	public Application() {}

	@Override
	public Map<String, Object> serializeToXdm() {
		Map<String, Object> map = new HashMap<>();

		if (this.applicationCloses != null) {
			map.put("applicationCloses", this.applicationCloses.serializeToXdm());
		}

		if (this.crashes != null) {
			map.put("crashes", this.crashes.serializeToXdm());
		}

		if (this.featureUsages != null) {
			map.put("featureUsages", this.featureUsages.serializeToXdm());
		}

		if (this.firstLaunches != null) {
			map.put("firstLaunches", this.firstLaunches.serializeToXdm());
		}

		if (this.id != null) {
			map.put("id", this.id);
		}

		if (this.installs != null) {
			map.put("installs", this.installs.serializeToXdm());
		}

		if (this.launches != null) {
			map.put("launches", this.launches.serializeToXdm());
		}

		if (this.name != null) {
			map.put("name", this.name);
		}

		if (this.upgrades != null) {
			map.put("upgrades", this.upgrades.serializeToXdm());
		}

		if (this.userPerspective != null) {
			map.put("userPerspective", this.userPerspective.toString());
		}

		if (this.version != null) {
			map.put("version", this.version);
		}

		return map;
	}

	/**
	 * Returns the ApplicationCloses property
	 * Graceful termination of an application.
	 * @return {@link ApplicationCloses} value or null if the property is not set
	 */
	public ApplicationCloses getApplicationCloses() {
		return this.applicationCloses;
	}

	/**
	 * Sets the ApplicationCloses property
	 * Graceful termination of an application.
	 * @param newValue the new ApplicationCloses value
	 */
	public void setApplicationCloses(final ApplicationCloses newValue) {
		this.applicationCloses = newValue;
	}
	/**
	 * Returns the Crashes property
	 * Triggered when the application does not exit gracefully. Event is sent on application launch after a crash.
	 * @return {@link Crashes} value or null if the property is not set
	 */
	public Crashes getCrashes() {
		return this.crashes;
	}

	/**
	 * Sets the Crashes property
	 * Triggered when the application does not exit gracefully. Event is sent on application launch after a crash.
	 * @param newValue the new Crashes value
	 */
	public void setCrashes(final Crashes newValue) {
		this.crashes = newValue;
	}
	/**
	 * Returns the FeatureUsages property
	 * Activation of an application feature that is being measured.
	 * @return {@link FeatureUsages} value or null if the property is not set
	 */
	public FeatureUsages getFeatureUsages() {
		return this.featureUsages;
	}

	/**
	 * Sets the FeatureUsages property
	 * Activation of an application feature that is being measured.
	 * @param newValue the new FeatureUsages value
	 */
	public void setFeatureUsages(final FeatureUsages newValue) {
		this.featureUsages = newValue;
	}
	/**
	 * Returns the FirstLaunches property
	 * Triggered on first launch after install.
	 * @return {@link FirstLaunches} value or null if the property is not set
	 */
	public FirstLaunches getFirstLaunches() {
		return this.firstLaunches;
	}

	/**
	 * Sets the FirstLaunches property
	 * Triggered on first launch after install.
	 * @param newValue the new FirstLaunches value
	 */
	public void setFirstLaunches(final FirstLaunches newValue) {
		this.firstLaunches = newValue;
	}
	/**
	 * Returns the Application identifier property
	 * Identifier of the application.
	 * @return {@link String} value or null if the property is not set
	 */
	public String getId() {
		return this.id;
	}

	/**
	 * Sets the Application identifier property
	 * Identifier of the application.
	 * @param newValue the new Application identifier value
	 */
	public void setId(final String newValue) {
		this.id = newValue;
	}
	/**
	 * Returns the Installs property
	 * Install of an application on a device where the specific install event is available.
	 * @return {@link Installs} value or null if the property is not set
	 */
	public Installs getInstalls() {
		return this.installs;
	}

	/**
	 * Sets the Installs property
	 * Install of an application on a device where the specific install event is available.
	 * @param newValue the new Installs value
	 */
	public void setInstalls(final Installs newValue) {
		this.installs = newValue;
	}
	/**
	 * Returns the Launches property
	 * Launch of an application. Triggered on every run, including crashes and installs. Also triggered on a resume from background when the session timeout has been exceeded.
	 * @return {@link Launches} value or null if the property is not set
	 */
	public Launches getLaunches() {
		return this.launches;
	}

	/**
	 * Sets the Launches property
	 * Launch of an application. Triggered on every run, including crashes and installs. Also triggered on a resume from background when the session timeout has been exceeded.
	 * @param newValue the new Launches value
	 */
	public void setLaunches(final Launches newValue) {
		this.launches = newValue;
	}
	/**
	 * Returns the Name property
	 * Name of the application.
	 * @return {@link String} value or null if the property is not set
	 */
	public String getName() {
		return this.name;
	}

	/**
	 * Sets the Name property
	 * Name of the application.
	 * @param newValue the new Name value
	 */
	public void setName(final String newValue) {
		this.name = newValue;
	}
	/**
	 * Returns the Upgrades property
	 * Upgrade of an application that has previously been installed. Triggered on first launch after upgrade.
	 * @return {@link Upgrades} value or null if the property is not set
	 */
	public Upgrades getUpgrades() {
		return this.upgrades;
	}

	/**
	 * Sets the Upgrades property
	 * Upgrade of an application that has previously been installed. Triggered on first launch after upgrade.
	 * @param newValue the new Upgrades value
	 */
	public void setUpgrades(final Upgrades newValue) {
		this.upgrades = newValue;
	}
	/**
	 * Returns the UserPerspective property
	 * The perspective/physical relationship between the user and the app/brand at the time the event happened.  The most common are the app being in the foreground with the user directly interacting with it vs the app being in the background and still generating events.  Detached means the event was related to the app but didn't come directly from the app like the sending of an email or push notification from an external system.  Understanding the perspective of the user in relation to the app helps with accurately generating sessions as the majority of the time you will not want to include background and detached events as part of an active session.
	 * @return {@link UserPerspectiveEnum} value or null if the property is not set
	 */
	public UserPerspectiveEnum getUserPerspective() {
		return this.userPerspective;
	}

	/**
	 * Sets the UserPerspective property
	 * The perspective/physical relationship between the user and the app/brand at the time the event happened.  The most common are the app being in the foreground with the user directly interacting with it vs the app being in the background and still generating events.  Detached means the event was related to the app but didn't come directly from the app like the sending of an email or push notification from an external system.  Understanding the perspective of the user in relation to the app helps with accurately generating sessions as the majority of the time you will not want to include background and detached events as part of an active session.
	 * @param newValue the new UserPerspective value
	 */
	public void setUserPerspective(final UserPerspectiveEnum newValue) {
		this.userPerspective = newValue;
	}
	/**
	 * Returns the Version property
	 * Version of the application.
	 * @return {@link String} value or null if the property is not set
	 */
	public String getVersion() {
		return this.version;
	}

	/**
	 * Sets the Version property
	 * Version of the application.
	 * @param newValue the new Version value
	 */
	public void setVersion(final String newValue) {
		this.version = newValue;
	}
}
