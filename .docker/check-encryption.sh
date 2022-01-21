if echo 'input = {value: "Hello world"}; AcaEntities::Operations::Encryption::Encrypt.new.call(input)' | bundle exec rails c | grep -q 'Success("'; then
    echo "Encryption works"
    exit 0
else
    echo "Encryption does not work"
    exit 1
fi
