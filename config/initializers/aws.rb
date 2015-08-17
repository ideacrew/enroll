akid="AKIAICBWTIIX4MLU4WEA"
secret="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"
region='us-east-1'
ENV['AWS_ACCESS_KEY_ID']=akid
ENV['AWS_SECRET_ACCESS_KEY']=secret
ENV['AWS_REGION']=region
Aws.config.update({region: 'us-east-1',
                   credentials: Aws::Credentials.new(akid, secret)})