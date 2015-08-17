#This assumes you have stored the parameters in environment variables
akid=ENV['AWS_ACCESS_KEY_ID']
secret=ENV['AWS_SECRET_ACCESS_KEY']
region=ENV['AWS_REGION']

#ENV['AWS_ACCESS_KEY_ID']=akid
#ENV['AWS_SECRET_ACCESS_KEY']=secret
#ENV['AWS_REGION']=region

Aws.config.update({region: region,
                   credentials: Aws::Credentials.new(akid, secret)})
