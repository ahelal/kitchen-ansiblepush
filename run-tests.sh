#!/bin/sh

echo "Run rspec"
bundle exec rspec --require spec_helper --format d

bundle exec kitchen test simple
bundle exec kitchen test notidempotent | tee /tmp/notidempotent

failed_nonotidempotent=$(cat /tmp/notidempotent | grep "idempotency test \[Failed\]" | wc -l)
if [ $failed_nonotidempotent -ne 2 ] ; then 
    echo "Non idempotent tasks $failed_nonotidempotent. :( fauled" 
    exit 1 
fi
