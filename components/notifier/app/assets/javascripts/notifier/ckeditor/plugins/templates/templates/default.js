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
		description: 'One main image with a title and text that surround the image.',
		html: "<p>&nbsp;</p>" +
"<p>#{employer_profile.notice_date}</p>" +
"<p><strong>SUBJECT: &lt;Change subject&gt;</strong></p>" +
"<p>Dear #{employer_profile.employer_name}:</p>" +
"<p>&lt;Paste Your Notice Body Here&gt;</p>" +
"<h3>For Questions or Assistance:</h3>"+
"<p>Please contact your broker for further assistance. You can also contact the Health Connector with any questions:</p>" +
"<ul>" +
	"<li>By calling #{Settings.contact_center.phone_number}. TTY: #{Settings.contact_center.tty_number}</li>" +
	"<li>By email: <a href='mailto:​#{Settings.contact_center.small_business_email}'>#{Settings.contact_center.small_business_email}</a></li>" +
"</ul>" +
"<p>You can also find more information on our website at <a href='http://​#{Settings.site.main_web_address}'>#{Settings.site.main_web_address}</a></p>" +
"<p>[[ if employer_profile.broker_present? ]]</p>" +
"<table border='0'cellpadding='0' cellspacing='0' style='height:81px; width:315px'>" +
	"<tbody>" +
		"<tr>" +
			"<td><strong>Broker:</strong></td>" +
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
"<p>If you do not currently have a broker, you can reach out to one of our many trained experts by clicking on the &ldquo;Find a Broker&rdquo; link in your employer account or calling 1-888-813-922<br />" +
"[[ end ]]</p>" +
"<p>___________________________________________________________________________________________________________________________________________________</p>" +
"<p><small>This notice is being provided in accordance with 45 C.F.R. 155.720.</small></p>"
	},
	{
		title: 'Employee Template',
		image: 'template2.gif',
		description: 'A template that defines two columns, each one with a title, and some text.',
		html: '<table cellspacing="0" cellpadding="0" style="width:100%" border="0">' +
			'<tr>' +
				'<td style="width:50%">' +
					'<h3>Title 1</h3>' +
				'</td>' +
				'<td></td>' +
				'<td style="width:50%">' +
					'<h3>Title 2</h3>' +
				'</td>' +
			'</tr>' +
			'<tr>' +
				'<td>' +
					'Text 1' +
				'</td>' +
				'<td></td>' +
				'<td>' +
					'Text 2' +
				'</td>' +
			'</tr>' +
			'</table>' +
			'<p>' +
			'More text goes here.' +
			'</p>'
	},
	{
		title: 'Broker Template',
		image: 'template3.gif',
		description: 'A title with some text and a table.',
		html: '<div style="width: 80%">' +
			'<h3>' +
				'Title goes here' +
			'</h3>' +
			'<table style="width:150px;float: right" cellspacing="0" cellpadding="0" border="1">' +
				'<caption style="border:solid 1px black">' +
					'<strong>Table title</strong>' +
				'</caption>' +
				'<tr>' +
					'<td>&nbsp;</td>' +
					'<td>&nbsp;</td>' +
					'<td>&nbsp;</td>' +
				'</tr>' +
				'<tr>' +
					'<td>&nbsp;</td>' +
					'<td>&nbsp;</td>' +
					'<td>&nbsp;</td>' +
				'</tr>' +
				'<tr>' +
					'<td>&nbsp;</td>' +
					'<td>&nbsp;</td>' +
					'<td>&nbsp;</td>' +
				'</tr>' +
			'</table>' +
			'<p>' +
				'Type the text here' +
			'</p>' +
			'</div>'
	} ]
} );
