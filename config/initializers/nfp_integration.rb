# Be sure to restart your server when you modify this file.

NFP_USER_ID = "testuser" #TEST ONLY
NFP_PASS = "M0rph!us007" #TEST ONLY
NFP_URL = Rails.env.production? ? "http://10.0.3.51/cpbservices/PremiumBillingIntegrationServices.svc" : "http://localhost:9000/cpbservices/PremiumBillingIntegrationServices.svc"
