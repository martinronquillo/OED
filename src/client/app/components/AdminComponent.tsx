/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import * as React from 'react';
import FooterComponent from '../components/FooterComponent';

/**
 * React component that controls the Admin panel
 * @returns JSX to create the AdminComponent
 */
export default function AdminComponent() {
	return (
		<div>
			<p>Admin panel</p>
			<FooterComponent/>
		</div>
	);
}
