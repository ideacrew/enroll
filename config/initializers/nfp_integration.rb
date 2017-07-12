# Be sure to restart your server when you modify this file.

NFP_USER_ID = "testuser" #TEST ONLY
NFP_PASS = "M0rph!us007" #TEST ONLY
NFP_URL = Rails.env.production? ? "http://nfp-wsdl.priv.dchbx.org/cpbservices/PremiumBillingIntegrationServices.svc" : "http://nfp-wsdl.priv.dchbx.org/cpbservices/PremiumBillingIntegrationServices.svc"
