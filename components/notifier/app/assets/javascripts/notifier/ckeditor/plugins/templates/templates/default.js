/**
 * @license Copyright (c) 2003-2017, CKSource - Frederico Knabben. All rights reserved.
 * For licensing, see LICENSE.md or http://ckeditor.com/license
 */

// Register a templates definition set named "default".
CKEDITOR.addTemplates( 'default', {
	// The name of sub folder which hold the shortcut preview images of the
	// templates.
	imagesPath: CKEDITOR.getUrl( CKEDITOR.plugins.getPath( 'templates' ) + 'templates/images/' ),

	// The templates definitions.
	templates: [ {
		title: 'Employer Template',
		image: 'template1.gif',
		description: 'Standard template for the notices received by Employers.',
		html: "<p>&nbsp;</p>" +
"<p>#{employer_profile.notice_date}</p>" +
"<p><strong>SUBJECT: &lt;Change subject&gt;</strong></p>" +
"<p>Dear #{employer_profile.employer_name}:</p>" +
"<p>&lt;Paste Your Notice Body Here&gt;</p>" +
"<h3>For Questions or Assistance:</h3>"+
"<p>Please contact your broker for further assistance. You can also contact the #{site_short_name} with any questions:</p>" +
"<ul>" +
	"<li>By calling #{Settings.contact_center.phone_number}. TTY: #{Settings.contact_center.tty_number}</li>" +
	"<li>By email: <a href='mailto:#{Settings.contact_center.small_business_email}'>#{Settings.contact_center.small_business_email}</a></li>" +
"</ul>" +
"<p>You can also find more information on our website at <a href='http://​#{Settings.site.main_web_address}'>#{Settings.site.main_web_address}</a></p>" +
"<p>[[ if employer_profile.broker_present? ]]</p>" +
"<table border='0'cellpadding='0' cellspacing='0' style='height:auto; width:auto'>" +
	"<tbody>" +
		"<tr>" +
			"<td><strong>Broker: &nbsp;&nbsp;</strong></td>" +
			"<td>#{employer_profile.broker.primary_fullname}</td>" +
		"</tr>" +
		"<tr>" +
			"<td>&nbsp;</td>" +
			"<td>#{employer_profile.broker.organization}</td>" +
		"</tr>" +
		"<tr>" +
			"<td>&nbsp;</td>" +
			"<td>#{employer_profile.broker.phone}</td>" +
		"</tr>" +
		"<tr>" +
			"<td>&nbsp;</td>" +
			"<td>#{employer_profile.broker.email}</td>" +
		"</tr>" +
	"</tbody>" +
"</table>" +
"<p>[[ else ]]</p>" +
"<p>If you do not currently have a broker, you can reach out to one of our many trained experts by clicking on the &ldquo;Find a Broker&rdquo; link in your employer account or calling #{Settings.contact_center.phone_number}<br />" +
"[[ end ]]</p>" +
"<p>___________________________________________________________________________________________________________________________________________________</p>" +
"<p><small>This notice is being provided in accordance with &lt;Insert Legal Compliance Code&gt;.</small></p>"
	},
	{
		title: 'Employee Template',
		image: 'template1.gif',
		description: 'Standard template for the notices received by Employees.',
		html: "<p>&nbsp;</p>" +
"<p>​#{employee_profile.notice_date}</p>" +
"<p><strong>SUBJECT: &lt;Change subject&gt;</strong></p>" +
"<p>Dear ​#{employee_profile.first_name} ​#{employee_profile.last_name}:</p>" +
"<p>&lt;Paste Your Notice Body Here&gt;</p>" +
"<h3>For Questions or Assistance:</h3>"+
"<p>[[ if employee_profile.broker_present? ]]</p>" +
"<p>Contact your employer or your broker for further assistance.</p>" +
"<p>[[ else ]]</p>" +
"<p>Contact your employer for further assistance.<br />" +
"[[ end ]]</p>" +
"<p>You can also contact the #{site_short_name} with any questions:</p>" +
"<ul>" +
	"<li>By calling #{Settings.contact_center.phone_number}. TTY: #{Settings.contact_center.tty_number}</li>" +
	"<li>By email: <a href='mailto:#{Settings.contact_center.small_business_email}'>#{Settings.contact_center.small_business_email}</a></li>" +
"</ul>" +
"<p>You can also find more information on our website at <a href='http://​#{Settings.site.main_web_address}'>#{Settings.site.main_web_address}</a></p>" +
"[[ if employee_profile.broker_present? ]]" +
"<table border='0'cellpadding='0' cellspacing='0' style='height:auto; width:auto'>" +
	"<tbody>" +
		"<tr>" +
			"<td><strong>Broker: &nbsp;&nbsp;</strong></td>" +
			"<td>#{employee_profile.broker.primary_fullname}</td>" +
		"</tr>" +
		"<tr>" +
			"<td>&nbsp;</td>" +
			"<td>#{employee_profile.broker.organization}</td>" +
		"</tr>" +
		"<tr>" +
			"<td>&nbsp;</td>" +
			"<td>#{employee_profile.broker.phone}</td>" +
		"</tr>" +
		"<tr>" +
			"<td>&nbsp;</td>" +
			"<td>#{employee_profile.broker.email}</td>" +
		"</tr>" +
	"</tbody>" +
"</table>" +
"[[ end ]]" +
"<p>___________________________________________________________________________________________________________________________________________________</p>" +
"<p><small>This notice is being provided in accordance with &lt;Insert Legal Compliance Code&gt;.</small></p>"
	},
{
		title: 'General Agency Template',
		image: 'template1.gif',
		description: 'Standard template for the notices received by General Agencies.',
		html: "<p>&nbsp;</p>" +
"<p>Email notification sent to: #{general_agency.email}</p>" +
"<p>#{general_agency.notice_date}</p>" +
"<p><strong>SUBJECT: &lt;Change subject&gt;</strong></p>" +
"<p>Dear #{general_agency.legal_name}:</p>" +
"<p>&lt;Paste Your Notice Body Here&gt;</p>" +
"<h3>For Questions or Assistance:</h3>"+
"<p>Please contact #{site_short_name} with any questions:</p>" +
"<ul>" +
	"<li>By calling #{contact_center_phone_number}</li>" +
	"<li>TTY: #{Settings.contact_center.tty_number}</li>" +
	"<li>Online at: <a href='#{Settings.site.home_url}'>#{Settings.site.website_name}</a></li>" +
"</ul>"
	},
	{
		title: 'Consumer Template',
		image: 'template1.gif',
		description: 'Standard template for the notices received by Consumers.',
		html:
			"<p>&nbsp;</p>" +
			"<p>#{consumer_role.notice_date}</p>" +
			"<p><strong>SUBJECT: &lt;Change subject&gt;</strong></p>" +
			"<p>Dear #{consumer_role.first_name}:</p>" +
			"<p>&lt;Paste Your Notice Body Here&gt;</p>" +
			"<br/>" +
			"<div style='display:block; page-break-inside: avoid;'>" +
				"<table border='0' class='total_table' style='margin-top: -20px;'>" +
					"<tbody>" +
						"<tr class='fssizeuser'>" +
							"<td>If you have questions or concerns, we&rsquo;re here to help.<br />" +
								"<br />" +
								"The #{Settings.site.short_name} Team<br />" +
								"<br />" +
							"_____________________________________________________________________________________________________________</td>" +
						"</tr>" +
					"</tbody>" +
				"</table>" +
			"</div>" +
			"<p>&nbsp;</p>" +
			"<div style='display:block; page-break-inside: avoid;'>" +
				"<table border='0' class='total_table reference' style='margin-top: -40px;'>" +
					"<tbody>" +
						"<tr>" +
							"<td style='padding-top: 2px;'><strong>Legal Reference: </strong> The following laws, regulations and rules apply to this letter:</td>" +
						"</tr>" +
					"</tbody>" +
				"</table>" +
			"</div>"
	}
	]
} );
