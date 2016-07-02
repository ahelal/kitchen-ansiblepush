#!/bin/sh

echo "Run rspec"
bundle exec rspec --require spec_helper --format d

bundle exec kitchen test simple
bundle exec kitchen test notidempotent | tee /tmp/notidempotent

failed_nonotidempotent=$(cat /tmp/notidempotent | grep "idempotency test \[Failed\]" | wc -l |  tr -d '[[:space:]]')
if [ ! "${failed_nonotidempotent}" == "2" ] ; then 
    echo "Non idempotent tasks $failed_nonotidempotent. :( failed" 
    exit 1 
fi
