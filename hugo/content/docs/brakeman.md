---
title: "Brakeman"
date: 2020-12-22T12:12:25-05:00
draft: false
---

[Brakeman](https://brakemanscanner.org/) is our static code security analysis tool which provides a detailed output of security vulnerabilities. Run Brakeman with the following command:  

`brakeman --github-repo dchbx/enroll -o output.html -o output.txt  `

###[Mass Assignment](https://brakemanscanner.org/docs/warning_types/mass_assignment/)

Mass assignment brakeman vulnerabilities pose a threat because a user could potentially pass through anything into our controller. They’re typically characterized by the method permit! (With bang) being called on params. The best way to mitigate this is strong params:

# Strong Params

In the file _app/controllers/inboxes_controller.rb_, the following line contained all params permitted:

`@new_message = Message.new(params.require(:message).permit!)`

Since there are a specific set of keys we need to create a new message, we can create strong, safe params like the following:

`@new_message = Message.new(params.require(:message).permit(:subject, :body, :folder, :to, :from))`


# Strong Params with Dynamic Param Keys

Sometimes param key are dynamic, which can be a little tricker. Here are a few examples of Dynamic keys of how to safely permit dynamic params. You’ll have to research the source of the params to determine what the dynamic values are.

Here’s an example from the method transition_family_members_update in app/[Families Controller](controllers/insured/families_controller.rb):

Original method contained this line:  params_hash = params.permit!.to_h

The permit! Method means that any and all params passed through would be whitelisted. To see what params we actually need, let’s look to the next line:

`params_parser = ::Forms::BulkActionsForAdmin.new(params.permit(@permitted_param_keys).to_h)  `

The class BulkActionsForAdmin will expect some dynamic params (beginning with transition_ followed by id’s). We can use regexes to match the dynamic params:   

`dynamic_transition_params_keys = params.keys.map { |key| key.match(/transition_.*/) }.compact.map(&:to_s).map(&:to_sym)`

The class BulkActionsForAdmin will expect some dynamic params (beginning with transition_ followed by id’s). We can use regexes to match the dynamic params: 
```
dynamic_transition_params_keys = params.keys.map { |key| key.match(/transition_.*/) }.compact.map(&:to_s).map(&:to_sym)
>>>>>>> 50c509df61... brakeman fixes description
non_dynamic_params_keys = [:family, :family_actions_id, :qle_id, :action]
@permitted_param_keys = dynamic_transition_params_keys.push(non_dynamic_params_keys).flatten`
```
*Relevant Pull Request with Dynamic Param Key Fixes*:

- [Pull Request 4114](https://github.com/dchbx/enroll/pull/4114/)

_Dev Tip_: If you’re unsure about params, one tip is to look at cucumbers or walk through the actions directly on an environment and observe the params.

##[Denial of Service](https://brakemanscanner.org/docs/warning_types/denial_of_service/)

Denial of Service (DoS) is any attack which causes a service to become unavailable for legitimate clients. 
Denial of Service can be caused by consuming large amounts of network, memory, or CPU resources.

### DoS for Regex

If an attacker can control the content of a regular expression, they may be able to construct a regular expression that requires exponential time to run.

In the file app/controllers/broker_agencies/broker_roles_controller.rb, the following line had an Regex which would have caused Denial of service had the attacker framed or created Regex expression which could've led to malicious search in the database.

`Organization.has_broker_agency_profile.or({legal_name: /#{params[:broker_agency_search]}/i}, {"fein" => /#{params[:broker_agency_search]}/i})`

Since there's a Regex used for user entered params which could lead a potential attack, we're escaping the Regex which would prevent an attack from the end user.

`Organization.has_broker_agency_profile.or({legal_name: /#{Regexp.escape(params[:broker_agency_search])}/i}, {"fein" => /#{Regexp.escape(params[:broker_agency_search])}/i})`

*Relevant Pull request for Denial of Service fixes*:

- [Pull Request 4102](https://github.com/dchbx/enroll/pull/4102/)

Dev-tip: Always escape the Regex if it's controlled by end user. Examples to consider are params, DB values.

##[Dangerous Send](https://brakemanscanner.org/docs/warning_types/dangerous_send/)

Using unfiltered user data to select a Class or Method to be dynamically sent is dangerous.
It is much safer to whitelist the desired target or method.

### Malicious attack Dangerous Send

If an attacker tries to access the private or restricted methods in the application, he/she can get the data which they're not supposed to access or get hold of.

In the file app/controllers/exchanges/broker_applicants_controller.rb, the following line was using send method on people object.
Had the attacker passed a different status as params, he would've got the information that he wasn't supposed to/

```
@status = status_params[:status] || 'applicant'
@people = @people.send("broker_role_#{@status}") if @people.respond_to?("broker_role_#{@status}")
```
As part of the fix, we are white listing the status params so the attacker wouldn't get access of what he desires and it would always be applicant.
```
@status = status_params[:status] || 'applicant'
@status = BrokerRole::BROKER_ROLE_STATUS_TYPES.include?(status_params[:status]) ? status_params[:status] : 'applicant'
```

*Relevant pull request for Dangerous Send reference*:

- [Pull Request 4102](https://github.com/dchbx/enroll/pull/4102/)

Dev-tip: Never use a send method with params as it poses a threat.

##[Redirect](https://brakemanscanner.org/docs/warning_types/redirect/)

Redirects which rely on user-supplied values can be used to “spoof” websites or hide malicious links in otherwise harmless-looking URLs.
They can also allow access to restricted areas of a site if the destination is not validated.

### URI Parse

If an attacker wants to redirect the traffic from the application to his desired website or an malicious site, he can pass the redirect url as an param and make his attack a success.

In the file, components/benefit_sponsors/app/controllers/benefit_sponsors/profiles/employers/employer_profiles_controller.rb, we have a redirect which reads from roster_upload_form.
If the attacker adds his desired website to the redirect, all the traffic that hits that page would be redirected to his site.

`redirect_to @roster_upload_form.redirection_url`

The fix for this issue would be to parse the url or restrict redirect from user input params.

`redirect_to URI.parse(@roster_upload_form.redirection_url).to_s`

*Relevant pull request for redirect error reference*:

- [Pull Request 4102](https://github.com/dchbx/enroll/pull/4102/)

Dev-tip: Never use a redirect path without parsing the url or restricting the path.

##[Remote Code Execution](https://brakemanscanner.org/docs/warning_types/remote_code_execution/)

Brakeman reports on several cases of remote code execution, in which a user is able to control and execute code in ways unintended by application authors.

### Safe use of Constantize

When we use unsafe reflection method constantize,eval, attacker may be able to halt the execution of a thread/the attacker would be able to access restricted information that he isn't supposed to.

In the file app/models/census_employee.rb, we are using constantize which would result in granting restricted access of data.

`builder = notice_trigger.notice_builder.camelize.constantize.new(self`

As part of the fix, we're white listing the notice class names, which would put a lock on the access.

`['IvlNotices::VariableIvlRenewalNotice','ShopEmployerNotices::OutOfPocketNotice'].find { |notice| notice == notice_type.classify }.safe_constantize`

*Relevant pull request for Remote Code Execution reference*:

- [Pull Request 4126](https://github.com/dchbx/enroll/pull/4126/)

_Dev Tip_: Never use eval, constantize 