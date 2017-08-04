CKEDITOR.editorConfig = function( config )
{
  // config.placeholder_select = {
  //   placeholders: ['employer_name', 'binder_payment_duedate', 'employer_contact_number', 'employer_address'],
  //   format: '<%=%placeholder%%>'
  // }

  alert('hello');

  // Configure available tokens
config.availableTokens = [
  ["Choose your token", ""],
  ["token1", "token1"],
  ["token2", "token2"],
  ["token3", "token3"],
];

// Configure token string
config.tokenStart = '<%=';
config.tokenEnd = '%>';

  config.extraPlugins = 'button,lineutils,widgetselection,notification,toolbar,widget,dialogui,dialog,clipboard,token';
  config.language = 'en';
};